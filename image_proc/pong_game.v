// pong_game.v
// Two-player Pong controlled by hand colour tracking.
//
// Player 1 (left  paddle) — tracked by u_detect  in DE1_SoC_CAMERA, coord_y
// Player 2 (right paddle) — tracked by u_detect2 in DE1_SoC_CAMERA, p2_coord_y
//
// Calibrate colours with SW[8]=1:
//   SW[1]=0 → KEY[1] sets Player 1 colour
//   SW[1]=1 → KEY[1] sets Player 2 colour
//
// P1 holds their hand in the centre box to start.
// Ball speed increases every 5 points.  First to 9 wins.
//
// SW[3]=1 activates this module in the VGA mux.

module pong_game (
    input             clk,
    input             rst_n,
    input             vsync,

    input      [9:0]  p1_x,          // P1 hand centroid X (VGA domain, CDC'd)
    input      [9:0]  p1_y,          // P1 hand centroid Y
    input      [9:0]  p2_x,          // P2 hand centroid X
    input      [9:0]  p2_y,          // P2 hand centroid Y
    input             p1_detected,
    input             p2_detected,

    input      [9:0]  vga_x,
    input      [9:0]  vga_y,

    output reg [9:0]  R_out,
    output reg [9:0]  G_out,
    output reg [9:0]  B_out
);

    // -----------------------------------------------------------------------
    // Parameters
    // -----------------------------------------------------------------------
    localparam [9:0]  SCREEN_W      = 10'd640;
    localparam [9:0]  SCREEN_H      = 10'd480;

    localparam [9:0]  PADDLE_H      = 10'd60;   // paddle height in pixels
    localparam [9:0]  PADDLE_W      = 10'd8;
    localparam [9:0]  PADDLE_HALF   = 10'd30;   // PADDLE_H / 2
    localparam [9:0]  PADDLE_X1     = 10'd16;   // P1 paddle left edge
    localparam [9:0]  PADDLE_X2     = 10'd616;  // P2 paddle left edge (640-16-8)

    localparam [9:0]  BALL_W        = 10'd8;
    localparam [9:0]  BALL_H        = 10'd8;

    localparam [3:0]  WIN_SCORE     = 4'd9;
    localparam [6:0]  START_HOLD    = 7'd120;   // ~2 sec at 60 Hz
    localparam [7:0]  WIN_HOLD      = 8'd240;   // ~4 sec win screen

    // States
    localparam [1:0]  S_IDLE    = 2'd0;
    localparam [1:0]  S_PLAY    = 2'd1;
    localparam [1:0]  S_WIN     = 2'd2;

    // Character codes
    localparam [4:0] CH_BLANK = 5'd0;
    localparam [4:0] CH_0     = 5'd1;
    localparam [4:0] CH_1     = 5'd2;
    localparam [4:0] CH_2     = 5'd3;
    localparam [4:0] CH_3     = 5'd4;
    localparam [4:0] CH_4     = 5'd5;
    localparam [4:0] CH_5     = 5'd6;
    localparam [4:0] CH_6     = 5'd7;
    localparam [4:0] CH_7     = 5'd8;
    localparam [4:0] CH_8     = 5'd9;
    localparam [4:0] CH_9     = 5'd10;
    localparam [4:0] CH_P     = 5'd11;
    localparam [4:0] CH_O     = 5'd12;
    localparam [4:0] CH_N     = 5'd13;
    localparam [4:0] CH_G     = 5'd14;
    localparam [4:0] CH_W     = 5'd15;
    localparam [4:0] CH_I     = 5'd16;
    localparam [4:0] CH_S     = 5'd17;
    localparam [4:0] CH_H     = 5'd18;
    localparam [4:0] CH_L     = 5'd19;
    localparam [4:0] CH_D     = 5'd20;
    localparam [4:0] CH_T     = 5'd21;
    localparam [4:0] CH_A     = 5'd22;
    localparam [4:0] CH_R     = 5'd23;
    localparam [4:0] CH_E     = 5'd24;
    localparam [4:0] CH_COLON = 5'd25;

    // -----------------------------------------------------------------------
    // State and game registers
    // -----------------------------------------------------------------------
    reg [1:0]  state;
    reg [9:0]  ball_x, ball_y;        // ball top-left corner
    reg signed [4:0] ball_vx;         // signed velocity (pixels/frame)
    reg signed [4:0] ball_vy;
    reg [9:0]  paddle1_y;             // P1 paddle top edge
    reg [9:0]  paddle2_y;
    reg [3:0]  score1, score2;
    reg [6:0]  start_hold_count;
    reg        start_armed;
    reg [7:0]  win_count;
    reg        winner;                // 0 = P1, 1 = P2
    reg        vy_flip;               // toggles each serve to alternate up/down spawn
    reg [2:0]  cur_speed;             // ball speed, resets to 3 each serve, +1 per paddle hit

    reg vsync_prev;
    wire vsync_fall = vsync_prev && !vsync;

    // P1 must hold their hand in the centre box to start
    wire [10:0] p1_box_dx = (p1_x >= 10'd320) ? {1'b0, p1_x - 10'd320} : {1'b0, 10'd320 - p1_x};
    wire [10:0] p1_box_dy = (p1_y >= 10'd240) ? {1'b0, p1_y - 10'd240} : {1'b0, 10'd240 - p1_y};
    wire in_start_box = p1_detected && (p1_box_dx <= 11'd48) && (p1_box_dy <= 11'd48);

    // -----------------------------------------------------------------------
    // Paddle tracking — remap camera y range to full screen height
    //
    // The camera often doesn't track reliably at the very top/bottom of the
    // frame.  Remapping [CAM_Y_MIN..CAM_Y_MAX] → [0..SCREEN_H-1] makes the
    // full paddle travel reachable with normal hand movement.
    // Scale = 480 / 320 = 3/2  (multiply by 3, shift right 1 — no divider).
    // Tune CAM_Y_MIN / CAM_Y_MAX if the extremes are still hard to reach.
    // -----------------------------------------------------------------------
    localparam [9:0] CAM_Y_MIN = 10'd60;
    localparam [9:0] CAM_Y_MAX = 10'd420;

    wire [9:0]  p1_yc = (p1_y < CAM_Y_MIN) ? CAM_Y_MIN :
                        (p1_y > CAM_Y_MAX) ? CAM_Y_MAX : p1_y;
    wire [10:0] p1_ym = (({1'b0, p1_yc} - {1'b0, CAM_Y_MIN}) * 11'd3) >> 1;
    wire [9:0]  p1_yf = (p1_ym >= 11'd480) ? 10'd479 : p1_ym[9:0];

    wire [9:0]  p2_yc = (p2_y < CAM_Y_MIN) ? CAM_Y_MIN :
                        (p2_y > CAM_Y_MAX) ? CAM_Y_MAX : p2_y;
    wire [10:0] p2_ym = (({1'b0, p2_yc} - {1'b0, CAM_Y_MIN}) * 11'd3) >> 1;
    wire [9:0]  p2_yf = (p2_ym >= 11'd480) ? 10'd479 : p2_ym[9:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            paddle1_y <= (SCREEN_H - PADDLE_H) >> 1;
            paddle2_y <= (SCREEN_H - PADDLE_H) >> 1;
        end else if (state == S_PLAY) begin
            if (p1_detected) begin
                if (p1_yf < PADDLE_HALF)
                    paddle1_y <= 10'd0;
                else if (p1_yf > SCREEN_H - PADDLE_HALF)
                    paddle1_y <= SCREEN_H - PADDLE_H;
                else
                    paddle1_y <= p1_yf - PADDLE_HALF;
            end
            if (p2_detected) begin
                if (p2_yf < PADDLE_HALF)
                    paddle2_y <= 10'd0;
                else if (p2_yf > SCREEN_H - PADDLE_HALF)
                    paddle2_y <= SCREEN_H - PADDLE_H;
                else
                    paddle2_y <= p2_yf - PADDLE_HALF;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Main state machine
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vsync_prev       <= 1'b0;
            state            <= S_IDLE;
            ball_x           <= (SCREEN_W - BALL_W) >> 1;
            ball_y           <= (SCREEN_H - BALL_H) >> 1;
            ball_vx          <= 5'sd3;
            ball_vy          <= 5'sd2;
            score1           <= 4'd0;
            score2           <= 4'd0;
            start_hold_count <= 7'd0;
            start_armed      <= 1'b0;
            win_count        <= 8'd0;
            winner           <= 1'b0;
            vy_flip          <= 1'b0;
            cur_speed        <= 3'd3;
        end else begin
            vsync_prev <= vsync;

            if (vsync_fall) begin
                case (state)

                    // --------------------------------------------------------
                    // IDLE: wait for both players to hold in centre box
                    // --------------------------------------------------------
                    S_IDLE: begin
                        if (!in_start_box) begin
                            start_armed      <= 1'b1;
                            start_hold_count <= 7'd0;
                        end else if (start_armed) begin
                            if (start_hold_count < START_HOLD)
                                start_hold_count <= start_hold_count + 7'd1;
                        end

                        if (start_hold_count >= START_HOLD - 7'd1) begin
                            state            <= S_PLAY;
                            start_hold_count <= 7'd0;
                            start_armed      <= 1'b0;
                            score1           <= 4'd0;
                            score2           <= 4'd0;
                            ball_x           <= (SCREEN_W - BALL_W) >> 1;
                            ball_y           <= (SCREEN_H - BALL_H) >> 1;
                            ball_vx          <= 5'sd3;
                            ball_vy          <= 5'sd2;
                            vy_flip          <= 1'b1;
                            cur_speed        <= 3'd3;
                        end
                    end

                    // --------------------------------------------------------
                    // PLAY
                    // --------------------------------------------------------
                    S_PLAY: begin
                        // Move ball
                        ball_x <= ball_x + {{5{ball_vx[4]}}, ball_vx};
                        ball_y <= ball_y + {{5{ball_vy[4]}}, ball_vy};

                        // Top / bottom wall bounce — direction guard prevents
                        // double-negation if ball overshoots the boundary zone
                        if (ball_y <= 10'd4 && ball_vy < 5'sd0)
                            ball_vy <= -ball_vy;
                        if (ball_y + BALL_H >= SCREEN_H - 10'd4 && ball_vy > 5'sd0)
                            ball_vy <= -ball_vy;

                        // P1 paddle (left) collision
                        if (ball_x <= PADDLE_X1 + PADDLE_W &&
                            ball_x + BALL_W >= PADDLE_X1 &&
                            ball_y + BALL_H >= paddle1_y &&
                            ball_y <= paddle1_y + PADDLE_H &&
                            ball_vx < 0) begin
                            ball_vx   <= $signed({1'b0, cur_speed});
                            cur_speed <= (cur_speed < 3'd7) ? cur_speed + 3'd1 : 3'd7;
                        end

                        // P2 paddle (right) collision
                        if (ball_x + BALL_W >= PADDLE_X2 &&
                            ball_x <= PADDLE_X2 + PADDLE_W &&
                            ball_y + BALL_H >= paddle2_y &&
                            ball_y <= paddle2_y + PADDLE_H &&
                            ball_vx > 0) begin
                            ball_vx   <= -$signed({1'b0, cur_speed});
                            cur_speed <= (cur_speed < 3'd7) ? cur_speed + 3'd1 : 3'd7;
                        end

                        // P2 scores (ball exits left)
                        if (ball_x <= 10'd2) begin
                            score2    <= score2 + 4'd1;
                            ball_x    <= (SCREEN_W - BALL_W) >> 1;
                            ball_y    <= (SCREEN_H - BALL_H) >> 1;
                            ball_vx   <= 5'sd3;
                            ball_vy   <= vy_flip ? -5'sd2 : 5'sd2;
                            vy_flip   <= !vy_flip;
                            cur_speed <= 3'd3;
                            if (score2 + 4'd1 >= WIN_SCORE) begin
                                state     <= S_WIN;
                                winner    <= 1'b1;
                                win_count <= 8'd0;
                            end
                        end

                        // P1 scores (ball exits right)
                        if (ball_x + BALL_W >= SCREEN_W - 10'd2) begin
                            score1    <= score1 + 4'd1;
                            ball_x    <= (SCREEN_W - BALL_W) >> 1;
                            ball_y    <= (SCREEN_H - BALL_H) >> 1;
                            ball_vx   <= -5'sd3;
                            ball_vy   <= vy_flip ? -5'sd2 : 5'sd2;
                            vy_flip   <= !vy_flip;
                            cur_speed <= 3'd3;
                            if (score1 + 4'd1 >= WIN_SCORE) begin
                                state     <= S_WIN;
                                winner    <= 1'b0;
                                win_count <= 8'd0;
                            end
                        end
                    end

                    // --------------------------------------------------------
                    // WIN: show banner then return to idle
                    // --------------------------------------------------------
                    S_WIN: begin
                        if (win_count < WIN_HOLD - 8'd1)
                            win_count <= win_count + 8'd1;
                        else begin
                            state            <= S_IDLE;
                            win_count        <= 8'd0;
                            start_hold_count <= 7'd0;
                            start_armed      <= 1'b0;
                            score1           <= 4'd0;
                            score2           <= 4'd0;
                        end
                    end

                    default: state <= S_IDLE;
                endcase
            end
        end
    end

    // -----------------------------------------------------------------------
    // 5x7 glyph ROM
    // -----------------------------------------------------------------------
    function [4:0] get_glyph_row;
        input [4:0] code;
        input [2:0] row;
        begin
            case (code)
                CH_0: case(row) 3'd0:get_glyph_row=5'b11111; 3'd1:get_glyph_row=5'b10001; 3'd2:get_glyph_row=5'b10011; 3'd3:get_glyph_row=5'b10101; 3'd4:get_glyph_row=5'b11001; 3'd5:get_glyph_row=5'b10001; 3'd6:get_glyph_row=5'b11111; default:get_glyph_row=5'b00000; endcase
                CH_1: case(row) 3'd0:get_glyph_row=5'b00100; 3'd1:get_glyph_row=5'b01100; 3'd2:get_glyph_row=5'b00100; 3'd3:get_glyph_row=5'b00100; 3'd4:get_glyph_row=5'b00100; 3'd5:get_glyph_row=5'b00100; 3'd6:get_glyph_row=5'b01110; default:get_glyph_row=5'b00000; endcase
                CH_2: case(row) 3'd0:get_glyph_row=5'b11111; 3'd1:get_glyph_row=5'b00001; 3'd2:get_glyph_row=5'b00001; 3'd3:get_glyph_row=5'b11111; 3'd4:get_glyph_row=5'b10000; 3'd5:get_glyph_row=5'b10000; 3'd6:get_glyph_row=5'b11111; default:get_glyph_row=5'b00000; endcase
                CH_3: case(row) 3'd0:get_glyph_row=5'b11111; 3'd1:get_glyph_row=5'b00001; 3'd2:get_glyph_row=5'b00001; 3'd3:get_glyph_row=5'b01111; 3'd4:get_glyph_row=5'b00001; 3'd5:get_glyph_row=5'b00001; 3'd6:get_glyph_row=5'b11111; default:get_glyph_row=5'b00000; endcase
                CH_4: case(row) 3'd0:get_glyph_row=5'b10001; 3'd1:get_glyph_row=5'b10001; 3'd2:get_glyph_row=5'b10001; 3'd3:get_glyph_row=5'b11111; 3'd4:get_glyph_row=5'b00001; 3'd5:get_glyph_row=5'b00001; 3'd6:get_glyph_row=5'b00001; default:get_glyph_row=5'b00000; endcase
                CH_5: case(row) 3'd0:get_glyph_row=5'b11111; 3'd1:get_glyph_row=5'b10000; 3'd2:get_glyph_row=5'b10000; 3'd3:get_glyph_row=5'b11111; 3'd4:get_glyph_row=5'b00001; 3'd5:get_glyph_row=5'b00001; 3'd6:get_glyph_row=5'b11111; default:get_glyph_row=5'b00000; endcase
                CH_6: case(row) 3'd0:get_glyph_row=5'b11111; 3'd1:get_glyph_row=5'b10000; 3'd2:get_glyph_row=5'b10000; 3'd3:get_glyph_row=5'b11111; 3'd4:get_glyph_row=5'b10001; 3'd5:get_glyph_row=5'b10001; 3'd6:get_glyph_row=5'b11111; default:get_glyph_row=5'b00000; endcase
                CH_7: case(row) 3'd0:get_glyph_row=5'b11111; 3'd1:get_glyph_row=5'b00001; 3'd2:get_glyph_row=5'b00010; 3'd3:get_glyph_row=5'b00100; 3'd4:get_glyph_row=5'b01000; 3'd5:get_glyph_row=5'b01000; 3'd6:get_glyph_row=5'b01000; default:get_glyph_row=5'b00000; endcase
                CH_8: case(row) 3'd0:get_glyph_row=5'b11111; 3'd1:get_glyph_row=5'b10001; 3'd2:get_glyph_row=5'b10001; 3'd3:get_glyph_row=5'b11111; 3'd4:get_glyph_row=5'b10001; 3'd5:get_glyph_row=5'b10001; 3'd6:get_glyph_row=5'b11111; default:get_glyph_row=5'b00000; endcase
                CH_9: case(row) 3'd0:get_glyph_row=5'b11111; 3'd1:get_glyph_row=5'b10001; 3'd2:get_glyph_row=5'b10001; 3'd3:get_glyph_row=5'b11111; 3'd4:get_glyph_row=5'b00001; 3'd5:get_glyph_row=5'b00001; 3'd6:get_glyph_row=5'b11111; default:get_glyph_row=5'b00000; endcase
                CH_P: case(row) 3'd0:get_glyph_row=5'b11110; 3'd1:get_glyph_row=5'b10001; 3'd2:get_glyph_row=5'b10001; 3'd3:get_glyph_row=5'b11110; 3'd4:get_glyph_row=5'b10000; 3'd5:get_glyph_row=5'b10000; 3'd6:get_glyph_row=5'b10000; default:get_glyph_row=5'b00000; endcase
                CH_O: case(row) 3'd0:get_glyph_row=5'b11111; 3'd1:get_glyph_row=5'b10001; 3'd2:get_glyph_row=5'b10001; 3'd3:get_glyph_row=5'b10001; 3'd4:get_glyph_row=5'b10001; 3'd5:get_glyph_row=5'b10001; 3'd6:get_glyph_row=5'b11111; default:get_glyph_row=5'b00000; endcase
                CH_N: case(row) 3'd0:get_glyph_row=5'b10001; 3'd1:get_glyph_row=5'b11001; 3'd2:get_glyph_row=5'b10101; 3'd3:get_glyph_row=5'b10011; 3'd4:get_glyph_row=5'b10001; 3'd5:get_glyph_row=5'b10001; 3'd6:get_glyph_row=5'b10001; default:get_glyph_row=5'b00000; endcase
                CH_G: case(row) 3'd0:get_glyph_row=5'b11111; 3'd1:get_glyph_row=5'b10000; 3'd2:get_glyph_row=5'b10000; 3'd3:get_glyph_row=5'b10111; 3'd4:get_glyph_row=5'b10001; 3'd5:get_glyph_row=5'b10001; 3'd6:get_glyph_row=5'b11111; default:get_glyph_row=5'b00000; endcase
                CH_W: case(row) 3'd0:get_glyph_row=5'b10001; 3'd1:get_glyph_row=5'b10001; 3'd2:get_glyph_row=5'b10001; 3'd3:get_glyph_row=5'b10101; 3'd4:get_glyph_row=5'b10101; 3'd5:get_glyph_row=5'b10101; 3'd6:get_glyph_row=5'b01010; default:get_glyph_row=5'b00000; endcase
                CH_I: case(row) 3'd0:get_glyph_row=5'b01110; 3'd1:get_glyph_row=5'b00100; 3'd2:get_glyph_row=5'b00100; 3'd3:get_glyph_row=5'b00100; 3'd4:get_glyph_row=5'b00100; 3'd5:get_glyph_row=5'b00100; 3'd6:get_glyph_row=5'b01110; default:get_glyph_row=5'b00000; endcase
                CH_S: case(row) 3'd0:get_glyph_row=5'b11111; 3'd1:get_glyph_row=5'b10000; 3'd2:get_glyph_row=5'b10000; 3'd3:get_glyph_row=5'b11111; 3'd4:get_glyph_row=5'b00001; 3'd5:get_glyph_row=5'b00001; 3'd6:get_glyph_row=5'b11111; default:get_glyph_row=5'b00000; endcase
                CH_H: case(row) 3'd0:get_glyph_row=5'b10001; 3'd1:get_glyph_row=5'b10001; 3'd2:get_glyph_row=5'b10001; 3'd3:get_glyph_row=5'b11111; 3'd4:get_glyph_row=5'b10001; 3'd5:get_glyph_row=5'b10001; 3'd6:get_glyph_row=5'b10001; default:get_glyph_row=5'b00000; endcase
                CH_L: case(row) 3'd0:get_glyph_row=5'b10000; 3'd1:get_glyph_row=5'b10000; 3'd2:get_glyph_row=5'b10000; 3'd3:get_glyph_row=5'b10000; 3'd4:get_glyph_row=5'b10000; 3'd5:get_glyph_row=5'b10000; 3'd6:get_glyph_row=5'b11111; default:get_glyph_row=5'b00000; endcase
                CH_D: case(row) 3'd0:get_glyph_row=5'b11110; 3'd1:get_glyph_row=5'b10001; 3'd2:get_glyph_row=5'b10001; 3'd3:get_glyph_row=5'b10001; 3'd4:get_glyph_row=5'b10001; 3'd5:get_glyph_row=5'b10001; 3'd6:get_glyph_row=5'b11110; default:get_glyph_row=5'b00000; endcase
                CH_T: case(row) 3'd0:get_glyph_row=5'b11111; 3'd1:get_glyph_row=5'b00100; 3'd2:get_glyph_row=5'b00100; 3'd3:get_glyph_row=5'b00100; 3'd4:get_glyph_row=5'b00100; 3'd5:get_glyph_row=5'b00100; 3'd6:get_glyph_row=5'b00100; default:get_glyph_row=5'b00000; endcase
                CH_A: case(row) 3'd0:get_glyph_row=5'b01110; 3'd1:get_glyph_row=5'b10001; 3'd2:get_glyph_row=5'b10001; 3'd3:get_glyph_row=5'b11111; 3'd4:get_glyph_row=5'b10001; 3'd5:get_glyph_row=5'b10001; 3'd6:get_glyph_row=5'b10001; default:get_glyph_row=5'b00000; endcase
                CH_R: case(row) 3'd0:get_glyph_row=5'b11110; 3'd1:get_glyph_row=5'b10001; 3'd2:get_glyph_row=5'b10001; 3'd3:get_glyph_row=5'b11110; 3'd4:get_glyph_row=5'b10100; 3'd5:get_glyph_row=5'b10010; 3'd6:get_glyph_row=5'b10001; default:get_glyph_row=5'b00000; endcase
                CH_E: case(row) 3'd0:get_glyph_row=5'b11111; 3'd1:get_glyph_row=5'b10000; 3'd2:get_glyph_row=5'b10000; 3'd3:get_glyph_row=5'b11110; 3'd4:get_glyph_row=5'b10000; 3'd5:get_glyph_row=5'b10000; 3'd6:get_glyph_row=5'b11111; default:get_glyph_row=5'b00000; endcase
                CH_COLON: case(row) 3'd0:get_glyph_row=5'b00000; 3'd1:get_glyph_row=5'b00100; 3'd2:get_glyph_row=5'b00100; 3'd3:get_glyph_row=5'b00000; 3'd4:get_glyph_row=5'b00100; 3'd5:get_glyph_row=5'b00100; 3'd6:get_glyph_row=5'b00000; default:get_glyph_row=5'b00000; endcase
                default: get_glyph_row = 5'b00000;
            endcase
        end
    endfunction

    function [4:0] digit_char;
        input [3:0] d;
        case (d)
            4'd0: digit_char = CH_0; 4'd1: digit_char = CH_1;
            4'd2: digit_char = CH_2; 4'd3: digit_char = CH_3;
            4'd4: digit_char = CH_4; 4'd5: digit_char = CH_5;
            4'd6: digit_char = CH_6; 4'd7: digit_char = CH_7;
            4'd8: digit_char = CH_8; 4'd9: digit_char = CH_9;
            default: digit_char = CH_0;
        endcase
    endfunction

    // -----------------------------------------------------------------------
    // Rendering helpers (computed per pixel)
    // -----------------------------------------------------------------------

    // -----------------------------------------------------------------------
    // Pixel renderer (combinational)
    // -----------------------------------------------------------------------

    // Pixel membership signals
    wire ball_on    = (vga_x >= ball_x) && (vga_x < ball_x + BALL_W) &&
                      (vga_y >= ball_y) && (vga_y < ball_y + BALL_H);

    wire paddle1_on = (vga_x >= PADDLE_X1) && (vga_x < PADDLE_X1 + PADDLE_W) &&
                      (vga_y >= paddle1_y) && (vga_y < paddle1_y + PADDLE_H);

    wire paddle2_on = (vga_x >= PADDLE_X2) && (vga_x < PADDLE_X2 + PADDLE_W) &&
                      (vga_y >= paddle2_y) && (vga_y < paddle2_y + PADDLE_H);

    // Centre dashed line: every 16 rows, 8 on 8 off
    wire centre_line = (vga_x >= 10'd318) && (vga_x < 10'd322) && (vga_y[3] == 1'b0);

    // Hand cursor indicators — 8x8 dot at each player's actual hand position
    // Addition-safe bounds check avoids unsigned underflow
    wire p1_cur_on = p1_detected &&
                     (vga_x + 10'd4 >= p1_x) && (vga_x < p1_x + 10'd4) &&
                     (vga_y + 10'd4 >= p1_y) && (vga_y < p1_y + 10'd4);
    wire p2_cur_on = p2_detected &&
                     (vga_x + 10'd4 >= p2_x) && (vga_x < p2_x + 10'd4) &&
                     (vga_y + 10'd4 >= p2_y) && (vga_y < p2_y + 10'd4);

    // Start-screen box border (2px) at screen centre ±48px
    wire [10:0] box_dx = (vga_x >= 10'd320) ? {1'b0, vga_x - 10'd320} : {1'b0, 10'd320 - vga_x};
    wire [10:0] box_dy = (vga_y >= 10'd240) ? {1'b0, vga_y - 10'd240} : {1'b0, 10'd240 - vga_y};
    wire start_box_on  = (box_dx <= 11'd48) && (box_dy <= 11'd48) &&
                         ((box_dx >= 11'd46) || (box_dy >= 11'd46));

    // Intermediate text signals (reg to avoid latch warnings)
    reg big_text_on, small_text_on;
    reg score_on;
    reg win_text_on;
    reg [9:0] tx, ty;
    reg [9:0] tx_in_char;
    reg [4:0] ti;
    reg [2:0] tpx, tpy;
    reg [4:0] tcode;
    reg [4:0] tbits;

    always @(*) begin
        R_out       = 10'h000;
        G_out       = 10'h000;
        B_out       = 10'h000;
        big_text_on  = 1'b0;
        small_text_on= 1'b0;
        score_on     = 1'b0;
        win_text_on  = 1'b0;
        tx = 10'd0; ty = 10'd0; tx_in_char = 10'd0; ti = 5'd0;
        tpx = 3'd0; tpy = 3'd0; tcode = CH_BLANK; tbits = 5'd0;

        case (state)

            // ----------------------------------------------------------------
            // IDLE: "PONG" title + yellow box + "HOLD TO START"
            // ----------------------------------------------------------------
            S_IDLE: begin
                // Big title "PONG" — 5x scaled, 4 chars × 30px = 120px, centred x=320
                // x=[260,380), y=[138,173)
                if ((vga_x >= 10'd260) && (vga_x < 10'd380) &&
                    (vga_y >= 10'd138) && (vga_y < 10'd173)) begin
                    tx  = vga_x - 10'd260;
                    ty  = vga_y - 10'd138;
                    if      (tx < 10'd30) begin ti = 5'd0; tx_in_char = tx; end
                    else if (tx < 10'd60) begin ti = 5'd1; tx_in_char = tx - 10'd30; end
                    else if (tx < 10'd90) begin ti = 5'd2; tx_in_char = tx - 10'd60; end
                    else                  begin ti = 5'd3; tx_in_char = tx - 10'd90; end
                    tpx = (tx_in_char < 10'd5)  ? 3'd0 :
                          (tx_in_char < 10'd10) ? 3'd1 :
                          (tx_in_char < 10'd15) ? 3'd2 :
                          (tx_in_char < 10'd20) ? 3'd3 :
                          (tx_in_char < 10'd25) ? 3'd4 : 3'd5;
                    tpy = (ty < 10'd5)  ? 3'd0 :
                          (ty < 10'd10) ? 3'd1 :
                          (ty < 10'd15) ? 3'd2 :
                          (ty < 10'd20) ? 3'd3 :
                          (ty < 10'd25) ? 3'd4 :
                          (ty < 10'd30) ? 3'd5 : 3'd6;
                    case (ti)
                        5'd0: tcode = CH_P;
                        5'd1: tcode = CH_O;
                        5'd2: tcode = CH_N;
                        5'd3: tcode = CH_G;
                        default: tcode = CH_BLANK;
                    endcase
                    if (tpx < 3'd5 && tpy < 3'd7) begin
                        tbits = get_glyph_row(tcode, tpy[2:0]);
                        case (tpx)
                            3'd0: big_text_on = tbits[4];
                            3'd1: big_text_on = tbits[3];
                            3'd2: big_text_on = tbits[2];
                            3'd3: big_text_on = tbits[1];
                            3'd4: big_text_on = tbits[0];
                            default: big_text_on = 1'b0;
                        endcase
                    end
                end

                // Small text "HOLD TO START" — x=[281,359), y=[296,304)
                if ((vga_x >= 10'd281) && (vga_x < 10'd359) &&
                    (vga_y >= 10'd296) && (vga_y < 10'd304)) begin
                    tx  = vga_x - 10'd281;
                    ty  = vga_y - 10'd296;
                    if      (tx < 10'd6)  begin ti = 5'd0;  tx_in_char = tx; end
                    else if (tx < 10'd12) begin ti = 5'd1;  tx_in_char = tx - 10'd6; end
                    else if (tx < 10'd18) begin ti = 5'd2;  tx_in_char = tx - 10'd12; end
                    else if (tx < 10'd24) begin ti = 5'd3;  tx_in_char = tx - 10'd18; end
                    else if (tx < 10'd30) begin ti = 5'd4;  tx_in_char = tx - 10'd24; end
                    else if (tx < 10'd36) begin ti = 5'd5;  tx_in_char = tx - 10'd30; end
                    else if (tx < 10'd42) begin ti = 5'd6;  tx_in_char = tx - 10'd36; end
                    else if (tx < 10'd48) begin ti = 5'd7;  tx_in_char = tx - 10'd42; end
                    else if (tx < 10'd54) begin ti = 5'd8;  tx_in_char = tx - 10'd48; end
                    else if (tx < 10'd60) begin ti = 5'd9;  tx_in_char = tx - 10'd54; end
                    else if (tx < 10'd66) begin ti = 5'd10; tx_in_char = tx - 10'd60; end
                    else if (tx < 10'd72) begin ti = 5'd11; tx_in_char = tx - 10'd66; end
                    else                  begin ti = 5'd12; tx_in_char = tx - 10'd72; end
                    tpx = tx_in_char[2:0];
                    tpy = ty[2:0];
                    case (ti)
                        5'd0:  tcode = CH_H; 5'd1:  tcode = CH_O;
                        5'd2:  tcode = CH_L; 5'd3:  tcode = CH_D;
                        5'd4:  tcode = CH_BLANK;
                        5'd5:  tcode = CH_T; 5'd6:  tcode = CH_O;
                        5'd7:  tcode = CH_BLANK;
                        5'd8:  tcode = CH_S; 5'd9:  tcode = CH_T;
                        5'd10: tcode = CH_A; 5'd11: tcode = CH_R;
                        5'd12: tcode = CH_T;
                        default: tcode = CH_BLANK;
                    endcase
                    if (tpx < 3'd5 && tpy < 3'd7) begin
                        tbits = get_glyph_row(tcode, tpy[2:0]);
                        case (tpx)
                            3'd0: small_text_on = tbits[4];
                            3'd1: small_text_on = tbits[3];
                            3'd2: small_text_on = tbits[2];
                            3'd3: small_text_on = tbits[1];
                            3'd4: small_text_on = tbits[0];
                            default: small_text_on = 1'b0;
                        endcase
                    end
                end

                if (big_text_on) begin
                    R_out = 10'h000; G_out = 10'h3FF; B_out = 10'h3FF; // Cyan
                end else if (small_text_on) begin
                    R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h3FF; // White
                end else if (start_box_on) begin
                    R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h000; // Yellow
                end else if (p1_cur_on) begin
                    R_out = 10'h000; G_out = 10'h3FF; B_out = 10'h080; // Green P1 cursor
                end else if (p2_cur_on) begin
                    R_out = 10'h3FF; G_out = 10'h080; B_out = 10'h000; // Red P2 cursor
                end
            end

            // ----------------------------------------------------------------
            // PLAY: paddles, ball, centre line, score
            // ----------------------------------------------------------------
            S_PLAY: begin
                // Score "P1: X  P2: X" — top centre, 1x glyphs, y=[8,16)
                // "P1: X" at x=[256,286), "P2: X" at x=[354,384)
                if ((vga_y >= 10'd8) && (vga_y < 10'd16)) begin
                    // P1 score block
                    if ((vga_x >= 10'd256) && (vga_x < 10'd292)) begin
                        tx  = vga_x - 10'd256;
                        ty  = vga_y - 10'd8;
                        if      (tx < 10'd6)  begin ti = 5'd0; tx_in_char = tx; end
                        else if (tx < 10'd12) begin ti = 5'd1; tx_in_char = tx - 10'd6; end
                        else if (tx < 10'd18) begin ti = 5'd2; tx_in_char = tx - 10'd12; end
                        else if (tx < 10'd24) begin ti = 5'd3; tx_in_char = tx - 10'd18; end
                        else if (tx < 10'd30) begin ti = 5'd4; tx_in_char = tx - 10'd24; end
                        else                  begin ti = 5'd5; tx_in_char = tx - 10'd30; end
                        tpx = tx_in_char[2:0];
                        tpy = ty[2:0];
                        case (ti)
                            5'd0: tcode = CH_P;
                            5'd1: tcode = CH_1;
                            5'd2: tcode = CH_COLON;
                            5'd3: tcode = CH_BLANK;
                            5'd4: tcode = digit_char(score1);
                            default: tcode = CH_BLANK;
                        endcase
                        if (tpx < 3'd5 && tpy < 3'd7) begin
                            tbits = get_glyph_row(tcode, tpy[2:0]);
                            case (tpx)
                                3'd0: score_on = tbits[4]; 3'd1: score_on = tbits[3];
                                3'd2: score_on = tbits[2]; 3'd3: score_on = tbits[1];
                                3'd4: score_on = tbits[0]; default: score_on = 1'b0;
                            endcase
                        end
                    end
                    // P2 score block
                    if ((vga_x >= 10'd348) && (vga_x < 10'd384)) begin
                        tx  = vga_x - 10'd348;
                        ty  = vga_y - 10'd8;
                        if      (tx < 10'd6)  begin ti = 5'd0; tx_in_char = tx; end
                        else if (tx < 10'd12) begin ti = 5'd1; tx_in_char = tx - 10'd6; end
                        else if (tx < 10'd18) begin ti = 5'd2; tx_in_char = tx - 10'd12; end
                        else if (tx < 10'd24) begin ti = 5'd3; tx_in_char = tx - 10'd18; end
                        else if (tx < 10'd30) begin ti = 5'd4; tx_in_char = tx - 10'd24; end
                        else                  begin ti = 5'd5; tx_in_char = tx - 10'd30; end
                        tpx = tx_in_char[2:0];
                        tpy = ty[2:0];
                        case (ti)
                            5'd0: tcode = CH_P;
                            5'd1: tcode = CH_2;
                            5'd2: tcode = CH_COLON;
                            5'd3: tcode = CH_BLANK;
                            5'd4: tcode = digit_char(score2);
                            default: tcode = CH_BLANK;
                        endcase
                        if (tpx < 3'd5 && tpy < 3'd7) begin
                            tbits = get_glyph_row(tcode, tpy[2:0]);
                            case (tpx)
                                3'd0: score_on = tbits[4]; 3'd1: score_on = tbits[3];
                                3'd2: score_on = tbits[2]; 3'd3: score_on = tbits[1];
                                3'd4: score_on = tbits[0]; default: score_on = 1'b0;
                            endcase
                        end
                    end
                end

                if (score_on) begin
                    R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h3FF;
                end else if (ball_on) begin
                    R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h3FF; // White ball
                end else if (paddle1_on) begin
                    R_out = 10'h000; G_out = 10'h3FF; B_out = 10'h080; // Green P1
                end else if (paddle2_on) begin
                    R_out = 10'h3FF; G_out = 10'h080; B_out = 10'h000; // Red P2
                end else if (p1_cur_on) begin
                    R_out = 10'h000; G_out = 10'h3FF; B_out = 10'h080; // Green P1 cursor
                end else if (p2_cur_on) begin
                    R_out = 10'h3FF; G_out = 10'h080; B_out = 10'h000; // Red P2 cursor
                end else if (centre_line) begin
                    R_out = 10'h180; G_out = 10'h180; B_out = 10'h180; // Gray dashes
                end
            end

            // ----------------------------------------------------------------
            // WIN: "P1 WINS!" or "P2 WINS!" banner
            // ----------------------------------------------------------------
            S_WIN: begin
                // Banner fill x=[140,500), y=[180,300)
                if ((vga_x >= 10'd140) && (vga_x < 10'd500) &&
                    (vga_y >= 10'd180) && (vga_y < 10'd300)) begin
                    // Border (4px)
                    if ((vga_x < 10'd144) || (vga_x >= 10'd496) ||
                        (vga_y < 10'd184) || (vga_y >= 10'd296))
                        begin R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h000; end // Yellow border
                    else
                        begin R_out = 10'h040; G_out = 10'h040; B_out = 10'h040; end // Dark fill
                end

                // "P1 WINS!" or "P2 WINS!" — 5x scaled, 8 chars × 30px = 240px
                // centred: x=[200,440), y=[208,243)
                if ((vga_x >= 10'd200) && (vga_x < 10'd440) &&
                    (vga_y >= 10'd208) && (vga_y < 10'd243)) begin
                    tx  = vga_x - 10'd200;
                    ty  = vga_y - 10'd208;
                    if      (tx < 10'd30)  begin ti = 5'd0; tx_in_char = tx; end
                    else if (tx < 10'd60)  begin ti = 5'd1; tx_in_char = tx - 10'd30; end
                    else if (tx < 10'd90)  begin ti = 5'd2; tx_in_char = tx - 10'd60; end
                    else if (tx < 10'd120) begin ti = 5'd3; tx_in_char = tx - 10'd90; end
                    else if (tx < 10'd150) begin ti = 5'd4; tx_in_char = tx - 10'd120; end
                    else if (tx < 10'd180) begin ti = 5'd5; tx_in_char = tx - 10'd150; end
                    else if (tx < 10'd210) begin ti = 5'd6; tx_in_char = tx - 10'd180; end
                    else                   begin ti = 5'd7; tx_in_char = tx - 10'd210; end
                    tpx = (tx_in_char < 10'd5)  ? 3'd0 :
                          (tx_in_char < 10'd10) ? 3'd1 :
                          (tx_in_char < 10'd15) ? 3'd2 :
                          (tx_in_char < 10'd20) ? 3'd3 :
                          (tx_in_char < 10'd25) ? 3'd4 : 3'd5;
                    tpy = (ty < 10'd5)  ? 3'd0 :
                          (ty < 10'd10) ? 3'd1 :
                          (ty < 10'd15) ? 3'd2 :
                          (ty < 10'd20) ? 3'd3 :
                          (ty < 10'd25) ? 3'd4 :
                          (ty < 10'd30) ? 3'd5 : 3'd6;
                    case (ti)
                        5'd0: tcode = CH_P;
                        5'd1: tcode = winner ? CH_2 : CH_1;
                        5'd2: tcode = CH_BLANK;
                        5'd3: tcode = CH_W;
                        5'd4: tcode = CH_I;
                        5'd5: tcode = CH_N;
                        5'd6: tcode = CH_S;
                        5'd7: tcode = CH_BLANK;
                        default: tcode = CH_BLANK;
                    endcase
                    if (tpx < 3'd5 && tpy < 3'd7) begin
                        tbits = get_glyph_row(tcode, tpy[2:0]);
                        case (tpx)
                            3'd0: win_text_on = tbits[4];
                            3'd1: win_text_on = tbits[3];
                            3'd2: win_text_on = tbits[2];
                            3'd3: win_text_on = tbits[1];
                            3'd4: win_text_on = tbits[0];
                            default: win_text_on = 1'b0;
                        endcase
                    end
                end

                if (win_text_on) begin
                    R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h3FF;
                end else if (p1_cur_on) begin
                    R_out = 10'h000; G_out = 10'h3FF; B_out = 10'h080;
                end else if (p2_cur_on) begin
                    R_out = 10'h3FF; G_out = 10'h080; B_out = 10'h000;
                end
            end

            default: begin end
        endcase
    end

endmodule
