// catch_game.v
// Hand-controlled catch game.
//
// A 16x16 object falls from the top of the screen at increasing speed.
// The player moves their hand horizontally to control a 64x8 paddle at
// the bottom and catch the object.  Three lives; score increments on each
// catch.  Hold-to-start: hold hand in the yellow centre box for 2 seconds.
// Game over when all lives are lost; banner is shown for 3 seconds, then
// the start screen reappears.
//
// Inputs
//   clk       : VGA pixel clock (25 MHz)
//   rst_n     : active-low reset
//   vsync     : VGA vertical sync (active-low pulse = frame boundary)
//   detected  : high when color_detect has a valid hand centroid
//   overlay_x : hand centroid X in pixels
//   overlay_y : hand centroid Y in pixels
//   vga_x     : current VGA scan X (from VGA_Controller)
//   vga_y     : current VGA scan Y (from VGA_Controller)
//
// Outputs
//   R_out / G_out / B_out : 10-bit RGB to VGA mux

module catch_game (
    input             clk,
    input             rst_n,
    input             vsync,
    input             detected,
    input      [9:0]  overlay_x,
    input      [9:0]  overlay_y,
    input      [9:0]  vga_x,
    input      [9:0]  vga_y,
    output reg [9:0]  R_out,
    output reg [9:0]  G_out,
    output reg [9:0]  B_out
);

    // -----------------------------------------------------------------------
    // Game parameters
    // -----------------------------------------------------------------------
    localparam [9:0] OBJ_W             = 10'd16;
    localparam [9:0] OBJ_H             = 10'd16;
    localparam [9:0] PADDLE_HALF       = 10'd32;   // paddle half-width (total 64px)
    localparam [9:0] PADDLE_H          = 10'd8;
    localparam [9:0] PADDLE_Y          = 10'd440;
    localparam [2:0] LIVES_MAX         = 3'd3;
    localparam [6:0] START_HOLD_FRAMES = 7'd120;   // ~2 sec at 60 Hz
    localparam [7:0] GAME_OVER_FRAMES  = 8'd180;   // ~3 sec at 60 Hz

    // State encoding
    localparam [1:0] STATE_IDLE     = 2'd0;
    localparam [1:0] STATE_PLAYING  = 2'd1;
    localparam [1:0] STATE_GAMEOVER = 2'd2;

    // -----------------------------------------------------------------------
    // Character codes for glyph ROM
    // -----------------------------------------------------------------------
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
    localparam [4:0] CH_A     = 5'd11;
    localparam [4:0] CH_C     = 5'd12;
    localparam [4:0] CH_D     = 5'd13;
    localparam [4:0] CH_E     = 5'd14;
    localparam [4:0] CH_G     = 5'd15;
    localparam [4:0] CH_H     = 5'd16;
    localparam [4:0] CH_L     = 5'd17;
    localparam [4:0] CH_M     = 5'd18;
    localparam [4:0] CH_O     = 5'd19;
    localparam [4:0] CH_R     = 5'd20;
    localparam [4:0] CH_S     = 5'd21;
    localparam [4:0] CH_T     = 5'd22;
    localparam [4:0] CH_V     = 5'd23;
    localparam [4:0] CH_COLON = 5'd24;

    // -----------------------------------------------------------------------
    // State and game registers
    // -----------------------------------------------------------------------
    reg [1:0]  state;
    reg [9:0]  obj_x;
    reg [9:0]  obj_y;
    reg        obj_type;         // 0 = coin, 1 = bomb
    reg [6:0]  score;
    reg [2:0]  lives;
    reg [9:0]  paddle_center;
    reg [6:0]  start_hold_count;
    reg        start_armed;
    reg [7:0]  game_over_count;
    reg [15:0] lfsr;
    reg        vsync_prev;

    // -----------------------------------------------------------------------
    // vsync falling-edge detect
    // -----------------------------------------------------------------------
    wire vsync_fall = vsync_prev && !vsync;

    // -----------------------------------------------------------------------
    // Hold-to-start: hand centroid within 96x96 centre region
    // -----------------------------------------------------------------------
    wire [10:0] hand_box_dx = (overlay_x >= 10'd320) ?
                               {1'b0, overlay_x - 10'd320} :
                               {1'b0, 10'd320 - overlay_x};
    wire [10:0] hand_box_dy = (overlay_y >= 10'd240) ?
                               {1'b0, overlay_y - 10'd240} :
                               {1'b0, 10'd240 - overlay_y};
    wire in_start_box = detected && (hand_box_dx <= 11'd48) && (hand_box_dy <= 11'd48);

    // -----------------------------------------------------------------------
    // Drop speed (pixels per vsync frame) increases with score
    // -----------------------------------------------------------------------
    wire [3:0] drop_speed = (score >= 7'd20) ? 4'd5 :
                            (score >= 7'd10) ? 4'd4 :
                            (score >= 7'd5)  ? 4'd3 :
                            (score >= 7'd2)  ? 4'd2 : 4'd1;

    // -----------------------------------------------------------------------
    // Collision helpers
    //   Catch zone: generous Y window so fast-dropping objects don't slip through
    // -----------------------------------------------------------------------
    wire x_overlap  = (obj_x + OBJ_W - 10'd1 >= paddle_center - PADDLE_HALF) &&
                      (obj_x                  <= paddle_center + PADDLE_HALF - 10'd1);
    wire y_in_zone  = (obj_y + OBJ_H - 10'd1 >= PADDLE_Y - 10'd10) &&
                      (obj_y                  <= PADDLE_Y + PADDLE_H + 10'd5);
    wire obj_caught = x_overlap && y_in_zone;
    wire obj_missed = (obj_y > 10'd480);

    // -----------------------------------------------------------------------
    // LFSR — free-running 16-bit shift register for pseudo-random spawn X
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr <= 16'hACE1;
        else
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3]};
    end

    // -----------------------------------------------------------------------
    // Paddle tracking — latches hand X when detected, clamped to screen edge
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            paddle_center <= 10'd320;
        end else if (detected && (state == STATE_PLAYING)) begin
            if (overlay_x < PADDLE_HALF)
                paddle_center <= PADDLE_HALF;
            else if (overlay_x > 10'd639 - PADDLE_HALF)
                paddle_center <= 10'd639 - PADDLE_HALF;
            else
                paddle_center <= overlay_x;
        end
    end

    // -----------------------------------------------------------------------
    // Main state machine — driven by vsync falling edge
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vsync_prev       <= 1'b0;
            state            <= STATE_IDLE;
            obj_x            <= 10'd312;
            obj_y            <= 10'd0;
            obj_type         <= 1'b0;
            score            <= 7'd0;
            lives            <= LIVES_MAX;
            start_hold_count <= 7'd0;
            start_armed      <= 1'b0;
            game_over_count  <= 8'd0;
        end else begin
            vsync_prev <= vsync;

            if (vsync_fall) begin
                case (state)

                    // ------------------------------------------------
                    // IDLE: show start screen, wait for hold-to-start
                    // ------------------------------------------------
                    STATE_IDLE: begin
                        if (!detected || !in_start_box) begin
                            start_armed      <= 1'b1;
                            start_hold_count <= 7'd0;
                        end else if (start_armed && in_start_box) begin
                            if (start_hold_count < START_HOLD_FRAMES)
                                start_hold_count <= start_hold_count + 7'd1;
                        end else begin
                            start_hold_count <= 7'd0;
                        end

                        if (start_hold_count >= START_HOLD_FRAMES - 7'd1) begin
                            state            <= STATE_PLAYING;
                            score            <= 7'd0;
                            lives            <= LIVES_MAX;
                            start_hold_count <= 7'd0;
                            obj_y            <= 10'd0;
                            obj_x            <= {1'b0, lfsr[8:0]};
                            obj_type         <= lfsr[9];
                        end
                    end

                    // ------------------------------------------------
                    // PLAYING: object falls, catch or miss each frame
                    // ------------------------------------------------
                    STATE_PLAYING: begin
                        if (obj_caught) begin
                            if (obj_type == 1'b1) begin
                                // Bomb caught — instant game over
                                lives           <= 3'd0;
                                state           <= STATE_GAMEOVER;
                                game_over_count <= 8'd0;
                            end else begin
                                // Coin caught — score and respawn
                                if (score < 7'd99) score <= score + 7'd1;
                                obj_y    <= 10'd0;
                                obj_x    <= {1'b0, lfsr[8:0]};
                                obj_type <= lfsr[9];
                            end
                        end else if (obj_missed) begin
                            if (obj_type == 1'b1) begin
                                // Bomb missed — respawn with no penalty
                                obj_y    <= 10'd0;
                                obj_x    <= {1'b0, lfsr[8:0]};
                                obj_type <= lfsr[9];
                            end else if (lives > 3'd1) begin
                                lives    <= lives - 3'd1;
                                obj_y    <= 10'd0;
                                obj_x    <= {1'b0, lfsr[8:0]};
                                obj_type <= lfsr[9];
                            end else begin
                                lives           <= 3'd0;
                                state           <= STATE_GAMEOVER;
                                game_over_count <= 8'd0;
                            end
                        end else begin
                            obj_y <= obj_y + {6'd0, drop_speed};
                        end
                    end

                    // ------------------------------------------------
                    // GAMEOVER: show banner, auto-return to IDLE
                    // ------------------------------------------------
                    STATE_GAMEOVER: begin
                        if (game_over_count < GAME_OVER_FRAMES - 8'd1)
                            game_over_count <= game_over_count + 8'd1;
                        else begin
                            state            <= STATE_IDLE;
                            game_over_count  <= 8'd0;
                            start_hold_count <= 7'd0;
                            start_armed      <= 1'b0;
                        end
                    end

                    default: state <= STATE_IDLE;
                endcase
            end
        end
    end

    // -----------------------------------------------------------------------
    // 5x7 glyph ROM — returns one 5-bit row for a character code.
    // Bit 4 is leftmost pixel, bit 0 is rightmost.
    // -----------------------------------------------------------------------
    function [4:0] get_glyph_row;
        input [4:0] code;
        input [2:0] row;
        begin
            case (code)
                CH_0: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b10001;
                        3'd2: get_glyph_row = 5'b10011;
                        3'd3: get_glyph_row = 5'b10101;
                        3'd4: get_glyph_row = 5'b11001;
                        3'd5: get_glyph_row = 5'b10001;
                        3'd6: get_glyph_row = 5'b11111;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_1: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b00100;
                        3'd1: get_glyph_row = 5'b01100;
                        3'd2: get_glyph_row = 5'b00100;
                        3'd3: get_glyph_row = 5'b00100;
                        3'd4: get_glyph_row = 5'b00100;
                        3'd5: get_glyph_row = 5'b00100;
                        3'd6: get_glyph_row = 5'b01110;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_2: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b00001;
                        3'd2: get_glyph_row = 5'b00001;
                        3'd3: get_glyph_row = 5'b11111;
                        3'd4: get_glyph_row = 5'b10000;
                        3'd5: get_glyph_row = 5'b10000;
                        3'd6: get_glyph_row = 5'b11111;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_3: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b00001;
                        3'd2: get_glyph_row = 5'b00001;
                        3'd3: get_glyph_row = 5'b01111;
                        3'd4: get_glyph_row = 5'b00001;
                        3'd5: get_glyph_row = 5'b00001;
                        3'd6: get_glyph_row = 5'b11111;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_4: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b10001;
                        3'd1: get_glyph_row = 5'b10001;
                        3'd2: get_glyph_row = 5'b10001;
                        3'd3: get_glyph_row = 5'b11111;
                        3'd4: get_glyph_row = 5'b00001;
                        3'd5: get_glyph_row = 5'b00001;
                        3'd6: get_glyph_row = 5'b00001;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_5: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b10000;
                        3'd2: get_glyph_row = 5'b10000;
                        3'd3: get_glyph_row = 5'b11111;
                        3'd4: get_glyph_row = 5'b00001;
                        3'd5: get_glyph_row = 5'b00001;
                        3'd6: get_glyph_row = 5'b11111;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_6: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b10000;
                        3'd2: get_glyph_row = 5'b10000;
                        3'd3: get_glyph_row = 5'b11111;
                        3'd4: get_glyph_row = 5'b10001;
                        3'd5: get_glyph_row = 5'b10001;
                        3'd6: get_glyph_row = 5'b11111;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_7: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b00001;
                        3'd2: get_glyph_row = 5'b00010;
                        3'd3: get_glyph_row = 5'b00100;
                        3'd4: get_glyph_row = 5'b01000;
                        3'd5: get_glyph_row = 5'b01000;
                        3'd6: get_glyph_row = 5'b01000;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_8: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b10001;
                        3'd2: get_glyph_row = 5'b10001;
                        3'd3: get_glyph_row = 5'b11111;
                        3'd4: get_glyph_row = 5'b10001;
                        3'd5: get_glyph_row = 5'b10001;
                        3'd6: get_glyph_row = 5'b11111;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_9: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b10001;
                        3'd2: get_glyph_row = 5'b10001;
                        3'd3: get_glyph_row = 5'b11111;
                        3'd4: get_glyph_row = 5'b00001;
                        3'd5: get_glyph_row = 5'b00001;
                        3'd6: get_glyph_row = 5'b11111;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_A: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b01110;
                        3'd1: get_glyph_row = 5'b10001;
                        3'd2: get_glyph_row = 5'b10001;
                        3'd3: get_glyph_row = 5'b11111;
                        3'd4: get_glyph_row = 5'b10001;
                        3'd5: get_glyph_row = 5'b10001;
                        3'd6: get_glyph_row = 5'b10001;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_C: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b10000;
                        3'd2: get_glyph_row = 5'b10000;
                        3'd3: get_glyph_row = 5'b10000;
                        3'd4: get_glyph_row = 5'b10000;
                        3'd5: get_glyph_row = 5'b10000;
                        3'd6: get_glyph_row = 5'b11111;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_D: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11110;
                        3'd1: get_glyph_row = 5'b10001;
                        3'd2: get_glyph_row = 5'b10001;
                        3'd3: get_glyph_row = 5'b10001;
                        3'd4: get_glyph_row = 5'b10001;
                        3'd5: get_glyph_row = 5'b10001;
                        3'd6: get_glyph_row = 5'b11110;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_E: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b10000;
                        3'd2: get_glyph_row = 5'b10000;
                        3'd3: get_glyph_row = 5'b11110;
                        3'd4: get_glyph_row = 5'b10000;
                        3'd5: get_glyph_row = 5'b10000;
                        3'd6: get_glyph_row = 5'b11111;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_G: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b10000;
                        3'd2: get_glyph_row = 5'b10000;
                        3'd3: get_glyph_row = 5'b10111;
                        3'd4: get_glyph_row = 5'b10001;
                        3'd5: get_glyph_row = 5'b10001;
                        3'd6: get_glyph_row = 5'b11111;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_H: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b10001;
                        3'd1: get_glyph_row = 5'b10001;
                        3'd2: get_glyph_row = 5'b10001;
                        3'd3: get_glyph_row = 5'b11111;
                        3'd4: get_glyph_row = 5'b10001;
                        3'd5: get_glyph_row = 5'b10001;
                        3'd6: get_glyph_row = 5'b10001;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_L: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b10000;
                        3'd1: get_glyph_row = 5'b10000;
                        3'd2: get_glyph_row = 5'b10000;
                        3'd3: get_glyph_row = 5'b10000;
                        3'd4: get_glyph_row = 5'b10000;
                        3'd5: get_glyph_row = 5'b10000;
                        3'd6: get_glyph_row = 5'b11111;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_M: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b10001;
                        3'd1: get_glyph_row = 5'b11011;
                        3'd2: get_glyph_row = 5'b10101;
                        3'd3: get_glyph_row = 5'b10101;
                        3'd4: get_glyph_row = 5'b10001;
                        3'd5: get_glyph_row = 5'b10001;
                        3'd6: get_glyph_row = 5'b10001;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_O: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b10001;
                        3'd2: get_glyph_row = 5'b10001;
                        3'd3: get_glyph_row = 5'b10001;
                        3'd4: get_glyph_row = 5'b10001;
                        3'd5: get_glyph_row = 5'b10001;
                        3'd6: get_glyph_row = 5'b11111;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_R: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11110;
                        3'd1: get_glyph_row = 5'b10001;
                        3'd2: get_glyph_row = 5'b10001;
                        3'd3: get_glyph_row = 5'b11110;
                        3'd4: get_glyph_row = 5'b10100;
                        3'd5: get_glyph_row = 5'b10010;
                        3'd6: get_glyph_row = 5'b10001;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_S: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b10000;
                        3'd2: get_glyph_row = 5'b10000;
                        3'd3: get_glyph_row = 5'b11111;
                        3'd4: get_glyph_row = 5'b00001;
                        3'd5: get_glyph_row = 5'b00001;
                        3'd6: get_glyph_row = 5'b11111;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_T: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b00100;
                        3'd2: get_glyph_row = 5'b00100;
                        3'd3: get_glyph_row = 5'b00100;
                        3'd4: get_glyph_row = 5'b00100;
                        3'd5: get_glyph_row = 5'b00100;
                        3'd6: get_glyph_row = 5'b00100;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_V: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b10001;
                        3'd1: get_glyph_row = 5'b10001;
                        3'd2: get_glyph_row = 5'b10001;
                        3'd3: get_glyph_row = 5'b10001;
                        3'd4: get_glyph_row = 5'b10001;
                        3'd5: get_glyph_row = 5'b01010;
                        3'd6: get_glyph_row = 5'b00100;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                CH_COLON: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b00000;
                        3'd1: get_glyph_row = 5'b00100;
                        3'd2: get_glyph_row = 5'b00100;
                        3'd3: get_glyph_row = 5'b00000;
                        3'd4: get_glyph_row = 5'b00100;
                        3'd5: get_glyph_row = 5'b00100;
                        3'd6: get_glyph_row = 5'b00000;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end
                default: get_glyph_row = 5'b00000;
            endcase
        end
    endfunction

    // -----------------------------------------------------------------------
    // Helper: map a digit value 0..9 to a character code
    // -----------------------------------------------------------------------
    function [4:0] digit_to_char;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: digit_to_char = CH_0; 4'd1: digit_to_char = CH_1;
                4'd2: digit_to_char = CH_2; 4'd3: digit_to_char = CH_3;
                4'd4: digit_to_char = CH_4; 4'd5: digit_to_char = CH_5;
                4'd6: digit_to_char = CH_6; 4'd7: digit_to_char = CH_7;
                4'd8: digit_to_char = CH_8; 4'd9: digit_to_char = CH_9;
                default: digit_to_char = CH_0;
            endcase
        end
    endfunction

    // -----------------------------------------------------------------------
    // Coin sprite ROM — 16x16, two layers.
    // Bit 15 = leftmost pixel (x=0), bit 0 = rightmost (x=15).
    // Outer circle (gold ring) minus inner is the ring; inner is yellow fill.
    // -----------------------------------------------------------------------
    function [15:0] get_coin_outer_row;
        input [3:0] py;
        case (py)
            4'd0:  get_coin_outer_row = 16'h0000;
            4'd1:  get_coin_outer_row = 16'h07E0;
            4'd2:  get_coin_outer_row = 16'h0FF0;
            4'd3:  get_coin_outer_row = 16'h1FF8;
            4'd4:  get_coin_outer_row = 16'h3FFC;
            4'd5:  get_coin_outer_row = 16'h7FFE;
            4'd6:  get_coin_outer_row = 16'h7FFE;
            4'd7:  get_coin_outer_row = 16'h7FFE;
            4'd8:  get_coin_outer_row = 16'h7FFE;
            4'd9:  get_coin_outer_row = 16'h7FFE;
            4'd10: get_coin_outer_row = 16'h7FFE;
            4'd11: get_coin_outer_row = 16'h3FFC;
            4'd12: get_coin_outer_row = 16'h1FF8;
            4'd13: get_coin_outer_row = 16'h0FF0;
            4'd14: get_coin_outer_row = 16'h07E0;
            4'd15: get_coin_outer_row = 16'h0000;
            default: get_coin_outer_row = 16'h0000;
        endcase
    endfunction

    function [15:0] get_coin_inner_row;
        input [3:0] py;
        case (py)
            4'd0:  get_coin_inner_row = 16'h0000;
            4'd1:  get_coin_inner_row = 16'h0000;
            4'd2:  get_coin_inner_row = 16'h0000;
            4'd3:  get_coin_inner_row = 16'h03C0;
            4'd4:  get_coin_inner_row = 16'h0FF0;
            4'd5:  get_coin_inner_row = 16'h0FF0;
            4'd6:  get_coin_inner_row = 16'h1FF8;
            4'd7:  get_coin_inner_row = 16'h1FF8;
            4'd8:  get_coin_inner_row = 16'h1FF8;
            4'd9:  get_coin_inner_row = 16'h1FF8;
            4'd10: get_coin_inner_row = 16'h0FF0;
            4'd11: get_coin_inner_row = 16'h0FF0;
            4'd12: get_coin_inner_row = 16'h03C0;
            4'd13: get_coin_inner_row = 16'h0000;
            4'd14: get_coin_inner_row = 16'h0000;
            4'd15: get_coin_inner_row = 16'h0000;
            default: get_coin_inner_row = 16'h0000;
        endcase
    endfunction

    // White highlight — small cluster top-left of coin centre
    function [15:0] get_coin_highlight_row;
        input [3:0] py;
        case (py)
            4'd3:  get_coin_highlight_row = 16'h0200; // x=6
            4'd4:  get_coin_highlight_row = 16'h0600; // x=5,6
            4'd5:  get_coin_highlight_row = 16'h0400; // x=5
            default: get_coin_highlight_row = 16'h0000;
        endcase
    endfunction

    // -----------------------------------------------------------------------
    // Bomb sprite ROM — 16x16, three layers.
    // Body: dark charcoal circle.  Shine: gray highlight top-left.
    // Fuse: two orange pixels above the body at top-right.
    // -----------------------------------------------------------------------
    function [15:0] get_bomb_body_row;
        input [3:0] py;
        case (py)
            4'd0:  get_bomb_body_row = 16'h0000;
            4'd1:  get_bomb_body_row = 16'h07E0;
            4'd2:  get_bomb_body_row = 16'h0FF0;
            4'd3:  get_bomb_body_row = 16'h1FF8;
            4'd4:  get_bomb_body_row = 16'h3FFC;
            4'd5:  get_bomb_body_row = 16'h7FFE;
            4'd6:  get_bomb_body_row = 16'h7FFE;
            4'd7:  get_bomb_body_row = 16'h7FFE;
            4'd8:  get_bomb_body_row = 16'h7FFE;
            4'd9:  get_bomb_body_row = 16'h7FFE;
            4'd10: get_bomb_body_row = 16'h7FFE;
            4'd11: get_bomb_body_row = 16'h3FFC;
            4'd12: get_bomb_body_row = 16'h1FF8;
            4'd13: get_bomb_body_row = 16'h0FF0;
            4'd14: get_bomb_body_row = 16'h07E0;
            4'd15: get_bomb_body_row = 16'h0000;
            default: get_bomb_body_row = 16'h0000;
        endcase
    endfunction

    function [15:0] get_bomb_shine_row;
        input [3:0] py;
        case (py)
            4'd3: get_bomb_shine_row = 16'h0C00; // x=4,5
            4'd4: get_bomb_shine_row = 16'h0800; // x=4
            default: get_bomb_shine_row = 16'h0000;
        endcase
    endfunction

    // Fuse: two orange pixels at (x=10,11, y=0) — above the body top-right
    function [15:0] get_bomb_fuse_row;
        input [3:0] py;
        case (py)
            4'd0: get_bomb_fuse_row = 16'h0030; // x=10,11
            default: get_bomb_fuse_row = 16'h0000;
        endcase
    endfunction

    // -----------------------------------------------------------------------
    // Pixel renderer — combinational
    // -----------------------------------------------------------------------

    // Score text signals (shared between PLAYING and GAMEOVER)
    reg        score_on;
    reg [9:0]  sc_x, sc_y;
    reg [3:0]  sc_char_index;
    reg [2:0]  sc_char_px, sc_char_py;
    reg [4:0]  sc_char_code, sc_glyph_bits;

    // Start-screen signals
    reg        start_box_on;
    reg        big_title_on;
    reg        subtitle_on;
    reg [10:0] vga_box_dx, vga_box_dy;
    reg [9:0]  bt_x, bt_y;
    reg [4:0]  bt_char_index;
    reg [2:0]  bt_char_px, bt_char_py;
    reg [4:0]  bt_char_code, bt_glyph_bits;
    reg [9:0]  st_x, st_y;
    reg [4:0]  st_char_index;
    reg [2:0]  st_char_px, st_char_py;
    reg [4:0]  st_char_code, st_glyph_bits;

    // Game-over banner signals
    reg        go_banner_fill_on, go_banner_border_on;
    reg        go_big_text_on, go_small_text_on;
    reg [9:0]  go_x, go_y;
    reg [4:0]  go_big_char_index;
    reg [2:0]  go_big_char_px, go_big_char_py;
    reg [4:0]  go_small_char_index;
    reg [2:0]  go_small_char_px, go_small_char_py;
    reg [4:0]  go_char_code, go_glyph_bits;

    // Gameplay pixel signals
    reg [3:0]  obj_px_r, obj_py_r;
    reg [15:0] spr_row_a, spr_row_b, spr_row_c;
    reg        coin_outer_on, coin_inner_on, coin_hi_on;
    reg        bomb_body_on, bomb_shine_on, bomb_fuse_on;
    reg        paddle_on, cursor_on;
    reg        life1_on, life2_on, life3_on;

    always @(*) begin
        // -------------------------------------------------------------------
        // Defaults (prevents Quartus from inferring latches)
        // -------------------------------------------------------------------
        score_on            = 1'b0;
        sc_x                = 10'd0; sc_y          = 10'd0;
        sc_char_index       = 4'd0;  sc_char_px    = 3'd0;
        sc_char_py          = 3'd0;  sc_char_code  = CH_BLANK;
        sc_glyph_bits       = 5'b00000;

        start_box_on        = 1'b0;
        big_title_on        = 1'b0;
        subtitle_on         = 1'b0;
        vga_box_dx          = 11'd0; vga_box_dy    = 11'd0;
        bt_x                = 10'd0; bt_y          = 10'd0;
        bt_char_index       = 5'd0;  bt_char_px    = 3'd0;
        bt_char_py          = 3'd0;  bt_char_code  = CH_BLANK;
        bt_glyph_bits       = 5'b00000;
        st_x                = 10'd0; st_y          = 10'd0;
        st_char_index       = 5'd0;  st_char_px    = 3'd0;
        st_char_py          = 3'd0;  st_char_code  = CH_BLANK;
        st_glyph_bits       = 5'b00000;

        go_banner_fill_on   = 1'b0;
        go_banner_border_on = 1'b0;
        go_big_text_on      = 1'b0;
        go_small_text_on    = 1'b0;
        go_x                = 10'd0; go_y          = 10'd0;
        go_big_char_index   = 5'd0;  go_big_char_px  = 3'd0;
        go_big_char_py      = 3'd0;  go_small_char_index = 5'd0;
        go_small_char_px    = 3'd0;  go_small_char_py = 3'd0;
        go_char_code        = CH_BLANK; go_glyph_bits = 5'b00000;

        obj_px_r        = 4'd0;
        obj_py_r        = 4'd0;
        spr_row_a       = 16'h0000;
        spr_row_b       = 16'h0000;
        spr_row_c       = 16'h0000;
        coin_outer_on   = 1'b0;
        coin_inner_on   = 1'b0;
        coin_hi_on      = 1'b0;
        bomb_body_on    = 1'b0;
        bomb_shine_on   = 1'b0;
        bomb_fuse_on    = 1'b0;
        paddle_on       = 1'b0;
        cursor_on       = 1'b0;
        life1_on        = 1'b0;
        life2_on        = 1'b0;
        life3_on        = 1'b0;

        R_out               = 10'h000;
        G_out               = 10'h000;
        B_out               = 10'h000;

        // -------------------------------------------------------------------
        // Cursor (5x5 dot at hand centroid, shown in all states)
        // -------------------------------------------------------------------
        cursor_on = detected &&
                    (vga_x + 10'd2 >= overlay_x) && (overlay_x + 10'd2 >= vga_x) &&
                    (vga_y + 10'd2 >= overlay_y) && (overlay_y + 10'd2 >= vga_y);

        // -------------------------------------------------------------------
        // State-specific rendering
        // -------------------------------------------------------------------
        case (state)

            // ----------------------------------------------------------------
            // IDLE: title "CATCH", yellow box, "HOLD TO START"
            // ----------------------------------------------------------------
            STATE_IDLE: begin

                // Yellow box border (2px) at screen centre ±48px
                vga_box_dx = (vga_x >= 10'd320) ?
                              {1'b0, vga_x - 10'd320} : {1'b0, 10'd320 - vga_x};
                vga_box_dy = (vga_y >= 10'd240) ?
                              {1'b0, vga_y - 10'd240} : {1'b0, 10'd240 - vga_y};
                start_box_on = (vga_box_dx <= 11'd48) && (vga_box_dy <= 11'd48) &&
                               ((vga_box_dx >= 11'd46) || (vga_box_dy >= 11'd46));

                // Big title "CATCH" — 5x scaled, x=[245,395), y=[138,173)
                // 5 chars × 30px = 150px, centred at x=320
                if ((vga_x >= 10'd245) && (vga_x < 10'd395) &&
                    (vga_y >= 10'd138) && (vga_y < 10'd173)) begin
                    bt_x          = vga_x - 10'd245;
                    bt_y          = vga_y - 10'd138;
                    bt_char_index = bt_x / 10'd30;
                    bt_char_px    = (bt_x % 10'd30) / 10'd5;
                    bt_char_py    = bt_y / 10'd5;
                    case (bt_char_index)
                        5'd0: bt_char_code = CH_C;
                        5'd1: bt_char_code = CH_A;
                        5'd2: bt_char_code = CH_T;
                        5'd3: bt_char_code = CH_C;
                        5'd4: bt_char_code = CH_H;
                        default: bt_char_code = CH_BLANK;
                    endcase
                    if ((bt_char_px < 3'd5) && (bt_char_py < 3'd7)) begin
                        bt_glyph_bits = get_glyph_row(bt_char_code, bt_char_py);
                        case (bt_char_px)
                            3'd0: big_title_on = bt_glyph_bits[4];
                            3'd1: big_title_on = bt_glyph_bits[3];
                            3'd2: big_title_on = bt_glyph_bits[2];
                            3'd3: big_title_on = bt_glyph_bits[1];
                            3'd4: big_title_on = bt_glyph_bits[0];
                            default: big_title_on = 1'b0;
                        endcase
                    end
                end

                // Subtitle "HOLD TO START" — 1x, x=[281,359), y=[296,304)
                if ((vga_x >= 10'd281) && (vga_x < 10'd359) &&
                    (vga_y >= 10'd296) && (vga_y < 10'd304)) begin
                    st_x          = vga_x - 10'd281;
                    st_y          = vga_y - 10'd296;
                    st_char_index = st_x / 10'd6;
                    st_char_px    = st_x % 10'd6;
                    st_char_py    = st_y[2:0];
                    case (st_char_index)
                        5'd0:  st_char_code = CH_H;
                        5'd1:  st_char_code = CH_O;
                        5'd2:  st_char_code = CH_L;
                        5'd3:  st_char_code = CH_D;
                        5'd4:  st_char_code = CH_BLANK;
                        5'd5:  st_char_code = CH_T;
                        5'd6:  st_char_code = CH_O;
                        5'd7:  st_char_code = CH_BLANK;
                        5'd8:  st_char_code = CH_S;
                        5'd9:  st_char_code = CH_T;
                        5'd10: st_char_code = CH_A;
                        5'd11: st_char_code = CH_R;
                        5'd12: st_char_code = CH_T;
                        default: st_char_code = CH_BLANK;
                    endcase
                    if ((st_char_px < 3'd5) && (st_char_py < 3'd7)) begin
                        st_glyph_bits = get_glyph_row(st_char_code, st_char_py);
                        case (st_char_px)
                            3'd0: subtitle_on = st_glyph_bits[4];
                            3'd1: subtitle_on = st_glyph_bits[3];
                            3'd2: subtitle_on = st_glyph_bits[2];
                            3'd3: subtitle_on = st_glyph_bits[1];
                            3'd4: subtitle_on = st_glyph_bits[0];
                            default: subtitle_on = 1'b0;
                        endcase
                    end
                end

                // Colour priority for start screen
                if (big_title_on) begin
                    R_out = 10'h000; G_out = 10'h3FF; B_out = 10'h3FF; // Cyan
                end else if (subtitle_on) begin
                    R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h3FF; // White
                end else if (start_box_on) begin
                    R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h000; // Yellow
                end else if (cursor_on) begin
                    R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h3FF; // White
                end
            end

            // ----------------------------------------------------------------
            // PLAYING: object, paddle, score, lives
            // ----------------------------------------------------------------
            STATE_PLAYING: begin

                // Falling object (16x16 sprite — coin or bomb)
                if ((vga_x >= obj_x) && (vga_x < obj_x + OBJ_W) &&
                    (vga_y >= obj_y) && (vga_y < obj_y + OBJ_H)) begin
                    obj_px_r = vga_x[3:0] - obj_x[3:0];
                    obj_py_r = vga_y[3:0] - obj_y[3:0];
                    if (obj_type == 1'b0) begin
                        spr_row_a    = get_coin_outer_row(obj_py_r);
                        spr_row_b    = get_coin_inner_row(obj_py_r);
                        spr_row_c    = get_coin_highlight_row(obj_py_r);
                        coin_outer_on = spr_row_a[15 - obj_px_r];
                        coin_inner_on = spr_row_b[15 - obj_px_r];
                        coin_hi_on    = spr_row_c[15 - obj_px_r];
                    end else begin
                        spr_row_a    = get_bomb_body_row(obj_py_r);
                        spr_row_b    = get_bomb_shine_row(obj_py_r);
                        spr_row_c    = get_bomb_fuse_row(obj_py_r);
                        bomb_body_on  = spr_row_a[15 - obj_px_r];
                        bomb_shine_on = spr_row_b[15 - obj_px_r];
                        bomb_fuse_on  = spr_row_c[15 - obj_px_r];
                    end
                end

                // Paddle (white bar)
                paddle_on = (vga_x >= paddle_center - PADDLE_HALF) &&
                            (vga_x <  paddle_center + PADDLE_HALF) &&
                            (vga_y >= PADDLE_Y) &&
                            (vga_y <  PADDLE_Y + PADDLE_H);

                // Lives indicator: three 10x10 squares, top-right
                // Life 3 (x=[618,627]), Life 2 (x=[606,615]), Life 1 (x=[594,603])
                life3_on = (vga_x >= 10'd618) && (vga_x < 10'd628) &&
                           (vga_y >= 10'd8)   && (vga_y < 10'd18);
                life2_on = (vga_x >= 10'd606) && (vga_x < 10'd616) &&
                           (vga_y >= 10'd8)   && (vga_y < 10'd18);
                life1_on = (vga_x >= 10'd594) && (vga_x < 10'd604) &&
                           (vga_y >= 10'd8)   && (vga_y < 10'd18);

                // Score text "SCORE: XX" — top-left, x=[8,62), y=[8,16)
                if ((vga_x >= 10'd8) && (vga_x < 10'd62) &&
                    (vga_y >= 10'd8) && (vga_y < 10'd16)) begin
                    sc_x          = vga_x - 10'd8;
                    sc_y          = vga_y - 10'd8;
                    sc_char_index = sc_x / 10'd6;
                    sc_char_px    = sc_x % 10'd6;
                    sc_char_py    = sc_y[2:0];
                    case (sc_char_index)
                        4'd0: sc_char_code = CH_S;
                        4'd1: sc_char_code = CH_C;
                        4'd2: sc_char_code = CH_O;
                        4'd3: sc_char_code = CH_R;
                        4'd4: sc_char_code = CH_E;
                        4'd5: sc_char_code = CH_COLON;
                        4'd6: sc_char_code = CH_BLANK;
                        4'd7: sc_char_code = (score >= 7'd10) ?
                                              digit_to_char(score / 7'd10) : CH_BLANK;
                        4'd8: sc_char_code = digit_to_char(score % 7'd10);
                        default: sc_char_code = CH_BLANK;
                    endcase
                    if ((sc_char_px < 3'd5) && (sc_char_py < 3'd7)) begin
                        sc_glyph_bits = get_glyph_row(sc_char_code, sc_char_py);
                        case (sc_char_px)
                            3'd0: score_on = sc_glyph_bits[4];
                            3'd1: score_on = sc_glyph_bits[3];
                            3'd2: score_on = sc_glyph_bits[2];
                            3'd3: score_on = sc_glyph_bits[1];
                            3'd4: score_on = sc_glyph_bits[0];
                            default: score_on = 1'b0;
                        endcase
                    end
                end

                // Colour priority for gameplay
                if (score_on) begin
                    R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h3FF; // White text
                end else if (life3_on) begin
                    R_out = (lives >= 3'd3) ? 10'h000 : 10'h100;
                    G_out = (lives >= 3'd3) ? 10'h3FF : 10'h100;
                    B_out = 10'h000;  // Green if alive, dark if lost
                end else if (life2_on) begin
                    R_out = (lives >= 3'd2) ? 10'h000 : 10'h100;
                    G_out = (lives >= 3'd2) ? 10'h3FF : 10'h100;
                    B_out = 10'h000;
                end else if (life1_on) begin
                    R_out = (lives >= 3'd1) ? 10'h000 : 10'h100;
                    G_out = (lives >= 3'd1) ? 10'h3FF : 10'h100;
                    B_out = 10'h000;
                end else if (coin_hi_on) begin
                    R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h3FF; // White highlight
                end else if (coin_inner_on) begin
                    R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h000; // Bright yellow fill
                end else if (coin_outer_on) begin
                    R_out = 10'h3FF; G_out = 10'h200; B_out = 10'h000; // Gold ring
                end else if (bomb_fuse_on) begin
                    R_out = 10'h3FF; G_out = 10'h180; B_out = 10'h000; // Orange fuse
                end else if (bomb_shine_on) begin
                    R_out = 10'h280; G_out = 10'h280; B_out = 10'h280; // Gray shine
                end else if (bomb_body_on) begin
                    R_out = 10'h0C0; G_out = 10'h0C0; B_out = 10'h0C0; // Dark charcoal body
                end else if (paddle_on) begin
                    R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h3FF; // White paddle
                end else if (cursor_on) begin
                    R_out = 10'h3FF; G_out = 10'h200; B_out = 10'h000; // Orange cursor
                end
            end

            // ----------------------------------------------------------------
            // GAMEOVER: banner with "GAME OVER" + score
            // ----------------------------------------------------------------
            STATE_GAMEOVER: begin

                // Banner background x=[100,540), y=[160,300)
                if ((vga_x >= 10'd100) && (vga_x < 10'd540) &&
                    (vga_y >= 10'd160) && (vga_y < 10'd300)) begin
                    go_banner_fill_on = 1'b1;
                    if ((vga_x < 10'd104) || (vga_x >= 10'd536) ||
                        (vga_y < 10'd164) || (vga_y >= 10'd296))
                        go_banner_border_on = 1'b1;
                end

                // Big text "GAME OVER" — 5x scaled, x=[185,455), y=[178,213)
                if ((vga_x >= 10'd185) && (vga_x < 10'd455) &&
                    (vga_y >= 10'd178) && (vga_y < 10'd213)) begin
                    go_x              = vga_x - 10'd185;
                    go_y              = vga_y - 10'd178;
                    go_big_char_index = go_x / 10'd30;
                    go_big_char_px    = (go_x % 10'd30) / 10'd5;
                    go_big_char_py    = go_y / 10'd5;
                    case (go_big_char_index)
                        5'd0: go_char_code = CH_G;
                        5'd1: go_char_code = CH_A;
                        5'd2: go_char_code = CH_M;
                        5'd3: go_char_code = CH_E;
                        5'd4: go_char_code = CH_BLANK;
                        5'd5: go_char_code = CH_O;
                        5'd6: go_char_code = CH_V;
                        5'd7: go_char_code = CH_E;
                        5'd8: go_char_code = CH_R;
                        default: go_char_code = CH_BLANK;
                    endcase
                    if ((go_big_char_px < 3'd5) && (go_big_char_py < 3'd7)) begin
                        go_glyph_bits = get_glyph_row(go_char_code, go_big_char_py);
                        case (go_big_char_px)
                            3'd0: go_big_text_on = go_glyph_bits[4];
                            3'd1: go_big_text_on = go_glyph_bits[3];
                            3'd2: go_big_text_on = go_glyph_bits[2];
                            3'd3: go_big_text_on = go_glyph_bits[1];
                            3'd4: go_big_text_on = go_glyph_bits[0];
                            default: go_big_text_on = 1'b0;
                        endcase
                    end
                end

                // Small score "SCORE: XX" — centred, x=[293,347), y=[245,253)
                if ((vga_x >= 10'd293) && (vga_x < 10'd347) &&
                    (vga_y >= 10'd245) && (vga_y < 10'd253)) begin
                    sc_x          = vga_x - 10'd293;
                    sc_y          = vga_y - 10'd245;
                    sc_char_index = sc_x / 10'd6;
                    sc_char_px    = sc_x % 10'd6;
                    sc_char_py    = sc_y[2:0];
                    case (sc_char_index)
                        4'd0: sc_char_code = CH_S;
                        4'd1: sc_char_code = CH_C;
                        4'd2: sc_char_code = CH_O;
                        4'd3: sc_char_code = CH_R;
                        4'd4: sc_char_code = CH_E;
                        4'd5: sc_char_code = CH_COLON;
                        4'd6: sc_char_code = CH_BLANK;
                        4'd7: sc_char_code = (score >= 7'd10) ?
                                              digit_to_char(score / 7'd10) : CH_BLANK;
                        4'd8: sc_char_code = digit_to_char(score % 7'd10);
                        default: sc_char_code = CH_BLANK;
                    endcase
                    if ((sc_char_px < 3'd5) && (sc_char_py < 3'd7)) begin
                        sc_glyph_bits = get_glyph_row(sc_char_code, sc_char_py);
                        case (sc_char_px)
                            3'd0: go_small_text_on = sc_glyph_bits[4];
                            3'd1: go_small_text_on = sc_glyph_bits[3];
                            3'd2: go_small_text_on = sc_glyph_bits[2];
                            3'd3: go_small_text_on = sc_glyph_bits[1];
                            3'd4: go_small_text_on = sc_glyph_bits[0];
                            default: go_small_text_on = 1'b0;
                        endcase
                    end
                end

                // Colour priority for game-over screen
                if (go_big_text_on) begin
                    R_out = 10'd1023; G_out = 10'd80;   B_out = 10'd80;   // Red title
                end else if (go_small_text_on) begin
                    R_out = 10'h3FF;  G_out = 10'h3FF;  B_out = 10'h3FF;  // White score
                end else if (go_banner_border_on) begin
                    R_out = 10'd900;  G_out = 10'd0;    B_out = 10'd0;    // Red border
                end else if (go_banner_fill_on) begin
                    R_out = 10'd260;  G_out = 10'd0;    B_out = 10'd0;    // Dark fill
                end
            end

            default: begin end
        endcase
    end

endmodule
