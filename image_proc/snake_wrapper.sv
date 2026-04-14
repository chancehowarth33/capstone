module snake_wrapper (
    input  logic clk,
    input  logic rst_n,

    input  logic [9:0] coord_x,
    input  logic [9:0] coord_y,
    input  logic       detected,

    input  logic [9:0] vga_x,
    input  logic [9:0] vga_y,
    input  logic       vsync,

    output logic [9:0] R_out,
    output logic [9:0] G_out,
    output logic [9:0] B_out
);

    localparam int GRID_COLS = 20;
    localparam int GRID_ROWS = 15;
    localparam int SPEED_DIV = 15;

    localparam logic [1:0] DIR_UP    = 2'd0;
    localparam logic [1:0] DIR_RIGHT = 2'd1;
    localparam logic [1:0] DIR_LEFT  = 2'd2;
    localparam logic [1:0] DIR_DOWN  = 2'd3;

    localparam logic [9:0] DEAD_ZONE_X = 10'd48;
    localparam logic [9:0] DEAD_ZONE_Y = 10'd48;

    localparam logic [6:0] START_HOLD_FRAMES = 7'd120;
    localparam logic [4:0] MAX_LEN = 5'd28;

    // Game-over flash timing
    // We show 5 visible flashes by alternating ON/OFF phases.
    // 10 total phases = 5 ON + 5 OFF.
    localparam logic [5:0] GAME_OVER_FLASH_FRAMES = 6'd30; // 30 frames/phase x 10 phases = 300 frames = ~5 seconds @ 60Hz
    localparam logic [3:0] GAME_OVER_TOTAL_PHASES = 4'd10;

    // Head
    logic [4:0] snake_head_col;
    logic [3:0] snake_head_row;

    // Body segments 1..27
    logic [4:0] snake_body1_col;   logic [3:0] snake_body1_row;
    logic [4:0] snake_body2_col;   logic [3:0] snake_body2_row;
    logic [4:0] snake_body3_col;   logic [3:0] snake_body3_row;
    logic [4:0] snake_body4_col;   logic [3:0] snake_body4_row;
    logic [4:0] snake_body5_col;   logic [3:0] snake_body5_row;
    logic [4:0] snake_body6_col;   logic [3:0] snake_body6_row;
    logic [4:0] snake_body7_col;   logic [3:0] snake_body7_row;
    logic [4:0] snake_body8_col;   logic [3:0] snake_body8_row;
    logic [4:0] snake_body9_col;   logic [3:0] snake_body9_row;
    logic [4:0] snake_body10_col;  logic [3:0] snake_body10_row;
    logic [4:0] snake_body11_col;  logic [3:0] snake_body11_row;
    logic [4:0] snake_body12_col;  logic [3:0] snake_body12_row;
    logic [4:0] snake_body13_col;  logic [3:0] snake_body13_row;
    logic [4:0] snake_body14_col;  logic [3:0] snake_body14_row;
    logic [4:0] snake_body15_col;  logic [3:0] snake_body15_row;
    logic [4:0] snake_body16_col;  logic [3:0] snake_body16_row;
    logic [4:0] snake_body17_col;  logic [3:0] snake_body17_row;
    logic [4:0] snake_body18_col;  logic [3:0] snake_body18_row;
    logic [4:0] snake_body19_col;  logic [3:0] snake_body19_row;
    logic [4:0] snake_body20_col;  logic [3:0] snake_body20_row;
    logic [4:0] snake_body21_col;  logic [3:0] snake_body21_row;
    logic [4:0] snake_body22_col;  logic [3:0] snake_body22_row;
    logic [4:0] snake_body23_col;  logic [3:0] snake_body23_row;
    logic [4:0] snake_body24_col;  logic [3:0] snake_body24_row;
    logic [4:0] snake_body25_col;  logic [3:0] snake_body25_row;
    logic [4:0] snake_body26_col;  logic [3:0] snake_body26_row;
    logic [4:0] snake_body27_col;  logic [3:0] snake_body27_row;

    logic [4:0] snake_len;

    // Food
    logic [4:0] food_col;
    logic [3:0] food_row;
    logic [3:0] food_step;

    // Game state
    logic       game_running;
    logic [1:0] direction;
    logic [3:0] frame_count;

    // Start screen state
    logic [6:0] start_hold_count;
    logic       start_armed;

    // Game-over state
    logic       game_over_active;
    logic       game_over_flash_on;
    logic [6:0] game_over_score;
    logic [6:0] score;            // running score, independent of snake length
    logic [3:0] game_over_flash_phase;
    logic [5:0] game_over_flash_count;

    // Vsync edge detect
    logic vsync_prev;
    logic vsync_fall;

    // Hand helpers
    logic [10:0] dx_mag;
    logic [10:0] dy_mag;
    logic        hand_left;
    logic        hand_up;
    logic        in_dead_zone;

    // Start box helper
    logic in_start_box;

    // Next head position
    logic [4:0] next_head_col;
    logic [3:0] next_head_row;

    // Collision
    logic self_collision;

    assign vsync_fall = (vsync_prev == 1'b1) && (vsync == 1'b0);

    // Even flash phases are visible, odd phases are hidden
    assign game_over_flash_on = ~game_over_flash_phase[0];

    always_comb begin
        if (coord_x < 10'd320) begin
            dx_mag    = {1'b0, (10'd320 - coord_x)};
            hand_left = 1'b1;
        end
        else begin
            dx_mag    = {1'b0, (coord_x - 10'd320)};
            hand_left = 1'b0;
        end

        if (coord_y < 10'd240) begin
            dy_mag  = {1'b0, (10'd240 - coord_y)};
            hand_up = 1'b1;
        end
        else begin
            dy_mag  = {1'b0, (coord_y - 10'd240)};
            hand_up = 1'b0;
        end

        in_dead_zone = (dx_mag <= DEAD_ZONE_X) && (dy_mag <= DEAD_ZONE_Y);

        in_start_box = detected &&
                       (dx_mag <= DEAD_ZONE_X) &&
                       (dy_mag <= DEAD_ZONE_Y);
    end

    always_comb begin
        next_head_col = snake_head_col;
        next_head_row = snake_head_row;

        case (direction)
            DIR_UP: begin
                if (snake_head_row == 4'd0)
                    next_head_row = 4'd14;
                else
                    next_head_row = snake_head_row - 4'd1;
            end
            DIR_DOWN: begin
                if (snake_head_row == 4'd14)
                    next_head_row = 4'd0;
                else
                    next_head_row = snake_head_row + 4'd1;
            end
            DIR_LEFT: begin
                if (snake_head_col == 5'd0)
                    next_head_col = 5'd19;
                else
                    next_head_col = snake_head_col - 5'd1;
            end
            default: begin
                if (snake_head_col == 5'd19)
                    next_head_col = 5'd0;
                else
                    next_head_col = snake_head_col + 5'd1;
            end
        endcase
    end

    always_comb begin
        self_collision = 1'b0;

        if ((snake_len >= 5'd2)  && (next_head_col == snake_body1_col)  && (next_head_row == snake_body1_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd3)  && (next_head_col == snake_body2_col)  && (next_head_row == snake_body2_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd4)  && (next_head_col == snake_body3_col)  && (next_head_row == snake_body3_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd5)  && (next_head_col == snake_body4_col)  && (next_head_row == snake_body4_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd6)  && (next_head_col == snake_body5_col)  && (next_head_row == snake_body5_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd7)  && (next_head_col == snake_body6_col)  && (next_head_row == snake_body6_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd8)  && (next_head_col == snake_body7_col)  && (next_head_row == snake_body7_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd9)  && (next_head_col == snake_body8_col)  && (next_head_row == snake_body8_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd10) && (next_head_col == snake_body9_col)  && (next_head_row == snake_body9_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd11) && (next_head_col == snake_body10_col) && (next_head_row == snake_body10_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd12) && (next_head_col == snake_body11_col) && (next_head_row == snake_body11_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd13) && (next_head_col == snake_body12_col) && (next_head_row == snake_body12_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd14) && (next_head_col == snake_body13_col) && (next_head_row == snake_body13_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd15) && (next_head_col == snake_body14_col) && (next_head_row == snake_body14_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd16) && (next_head_col == snake_body15_col) && (next_head_row == snake_body15_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd17) && (next_head_col == snake_body16_col) && (next_head_row == snake_body16_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd18) && (next_head_col == snake_body17_col) && (next_head_row == snake_body17_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd19) && (next_head_col == snake_body18_col) && (next_head_row == snake_body18_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd20) && (next_head_col == snake_body19_col) && (next_head_row == snake_body19_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd21) && (next_head_col == snake_body20_col) && (next_head_row == snake_body20_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd22) && (next_head_col == snake_body21_col) && (next_head_row == snake_body21_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd23) && (next_head_col == snake_body22_col) && (next_head_row == snake_body22_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd24) && (next_head_col == snake_body23_col) && (next_head_row == snake_body23_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd25) && (next_head_col == snake_body24_col) && (next_head_row == snake_body24_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd26) && (next_head_col == snake_body25_col) && (next_head_row == snake_body25_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd27) && (next_head_col == snake_body26_col) && (next_head_row == snake_body26_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd28) && (next_head_col == snake_body27_col) && (next_head_row == snake_body27_row)) self_collision = 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            snake_head_col <= 5'd10;
            snake_head_row <= 4'd7;

            snake_body1_col  <= 5'd9;  snake_body1_row  <= 4'd7;
            snake_body2_col  <= 5'd8;  snake_body2_row  <= 4'd7;
            snake_body3_col  <= 5'd7;  snake_body3_row  <= 4'd7;
            snake_body4_col  <= 5'd6;  snake_body4_row  <= 4'd7;
            snake_body5_col  <= 5'd5;  snake_body5_row  <= 4'd7;
            snake_body6_col  <= 5'd4;  snake_body6_row  <= 4'd7;
            snake_body7_col  <= 5'd3;  snake_body7_row  <= 4'd7;
            snake_body8_col  <= 5'd2;  snake_body8_row  <= 4'd7;
            snake_body9_col  <= 5'd1;  snake_body9_row  <= 4'd7;
            snake_body10_col <= 5'd0;  snake_body10_row <= 4'd7;
            snake_body11_col <= 5'd0;  snake_body11_row <= 4'd7;
            snake_body12_col <= 5'd0;  snake_body12_row <= 4'd7;
            snake_body13_col <= 5'd0;  snake_body13_row <= 4'd7;
            snake_body14_col <= 5'd0;  snake_body14_row <= 4'd7;
            snake_body15_col <= 5'd0;  snake_body15_row <= 4'd7;
            snake_body16_col <= 5'd0;  snake_body16_row <= 4'd7;
            snake_body17_col <= 5'd0;  snake_body17_row <= 4'd7;
            snake_body18_col <= 5'd0;  snake_body18_row <= 4'd7;
            snake_body19_col <= 5'd0;  snake_body19_row <= 4'd7;
            snake_body20_col <= 5'd0;  snake_body20_row <= 4'd7;
            snake_body21_col <= 5'd0;  snake_body21_row <= 4'd7;
            snake_body22_col <= 5'd0;  snake_body22_row <= 4'd7;
            snake_body23_col <= 5'd0;  snake_body23_row <= 4'd7;
            snake_body24_col <= 5'd0;  snake_body24_row <= 4'd7;
            snake_body25_col <= 5'd0;  snake_body25_row <= 4'd7;
            snake_body26_col <= 5'd0;  snake_body26_row <= 4'd7;
            snake_body27_col <= 5'd0;  snake_body27_row <= 4'd7;

            snake_len <= 5'd2;
            score     <= 7'd0;

            food_col  <= 5'd5;
            food_row  <= 4'd5;
            food_step <= 4'd0;

            game_running     <= 1'b0;
            start_hold_count <= 7'd0;
            start_armed      <= 1'b0;

            // Game-over state reset
            game_over_active      <= 1'b0;
            game_over_score       <= 7'd0;
            game_over_flash_phase <= 4'd0;
            game_over_flash_count <= 6'd0;

            direction   <= DIR_RIGHT;
            frame_count <= 4'd0;
            vsync_prev  <= vsync;
        end
        else begin
            vsync_prev <= vsync;

            if (vsync_fall) begin
                // ------------------------------------------------
                // If game over is active, flash the game-over screen
                // 5 times, then return to the normal yellow start box
                // ------------------------------------------------
                if (game_over_active) begin
                    if (game_over_flash_count == GAME_OVER_FLASH_FRAMES - 1) begin
                        game_over_flash_count <= 6'd0;

                        if (game_over_flash_phase == GAME_OVER_TOTAL_PHASES - 1) begin
                            // Done flashing, go back to waiting-to-start state
                            game_over_active      <= 1'b0;
                            game_over_flash_phase <= 4'd0;
                            start_hold_count      <= 7'd0;
                            start_armed           <= 1'b0;
                        end
                        else begin
                            game_over_flash_phase <= game_over_flash_phase + 4'd1;
                        end
                    end
                    else begin
                        game_over_flash_count <= game_over_flash_count + 6'd1;
                    end
                end
                else if (!game_running) begin
                    if (!detected || !in_start_box) begin
                        start_armed      <= 1'b1;
                        start_hold_count <= 7'd0;
                    end
                    else if (start_armed && in_start_box) begin
                        if (start_hold_count < START_HOLD_FRAMES)
                            start_hold_count <= start_hold_count + 7'd1;
                    end
                    else begin
                        start_hold_count <= 7'd0;
                    end

                    if (start_hold_count >= START_HOLD_FRAMES - 1) begin
                        game_running <= 1'b1;
                        frame_count  <= 4'd0;

                        // Clear any game-over state when a new game starts
                        game_over_active      <= 1'b0;
                        game_over_flash_phase <= 4'd0;
                        game_over_flash_count <= 6'd0;

                        snake_head_col <= 5'd10;
                        snake_head_row <= 4'd7;

                        snake_body1_col  <= 5'd9;  snake_body1_row  <= 4'd7;
                        snake_body2_col  <= 5'd8;  snake_body2_row  <= 4'd7;
                        snake_body3_col  <= 5'd7;  snake_body3_row  <= 4'd7;
                        snake_body4_col  <= 5'd6;  snake_body4_row  <= 4'd7;
                        snake_body5_col  <= 5'd5;  snake_body5_row  <= 4'd7;
                        snake_body6_col  <= 5'd4;  snake_body6_row  <= 4'd7;
                        snake_body7_col  <= 5'd3;  snake_body7_row  <= 4'd7;
                        snake_body8_col  <= 5'd2;  snake_body8_row  <= 4'd7;
                        snake_body9_col  <= 5'd1;  snake_body9_row  <= 4'd7;
                        snake_body10_col <= 5'd0;  snake_body10_row <= 4'd7;
                        snake_body11_col <= 5'd0;  snake_body11_row <= 4'd7;
                        snake_body12_col <= 5'd0;  snake_body12_row <= 4'd7;
                        snake_body13_col <= 5'd0;  snake_body13_row <= 4'd7;
                        snake_body14_col <= 5'd0;  snake_body14_row <= 4'd7;
                        snake_body15_col <= 5'd0;  snake_body15_row <= 4'd7;
                        snake_body16_col <= 5'd0;  snake_body16_row <= 4'd7;
                        snake_body17_col <= 5'd0;  snake_body17_row <= 4'd7;
                        snake_body18_col <= 5'd0;  snake_body18_row <= 4'd7;
                        snake_body19_col <= 5'd0;  snake_body19_row <= 4'd7;
                        snake_body20_col <= 5'd0;  snake_body20_row <= 4'd7;
                        snake_body21_col <= 5'd0;  snake_body21_row <= 4'd7;
                        snake_body22_col <= 5'd0;  snake_body22_row <= 4'd7;
                        snake_body23_col <= 5'd0;  snake_body23_row <= 4'd7;
                        snake_body24_col <= 5'd0;  snake_body24_row <= 4'd7;
                        snake_body25_col <= 5'd0;  snake_body25_row <= 4'd7;
                        snake_body26_col <= 5'd0;  snake_body26_row <= 4'd7;
                        snake_body27_col <= 5'd0;  snake_body27_row <= 4'd7;

                        snake_len <= 5'd2;
                        score     <= 7'd0;

                        food_col  <= 5'd5;
                        food_row  <= 4'd5;
                        food_step <= 4'd0;

                        direction        <= DIR_RIGHT;
                        start_hold_count <= 7'd0;
                    end
                end
                else begin
                    if (detected && !in_dead_zone) begin
                        if (dy_mag > dx_mag) begin
                            if (hand_up) begin
                                if (direction != DIR_DOWN)
                                    direction <= DIR_UP;
                            end
                            else begin
                                if (direction != DIR_UP)
                                    direction <= DIR_DOWN;
                            end
                        end
                        else begin
                            if (hand_left) begin
                                if (direction != DIR_RIGHT)
                                    direction <= DIR_LEFT;
                            end
                            else begin
                                if (direction != DIR_LEFT)
                                    direction <= DIR_RIGHT;
                            end
                        end
                    end

                    if (frame_count == SPEED_DIV - 1) begin
                        frame_count <= 4'd0;

                        if (self_collision) begin
                            // Enter game-over state instead of immediately
                            // going back to the start screen.
                            game_running          <= 1'b0;
                            game_over_active      <= 1'b1;
                            game_over_flash_phase <= 4'd0;
                            game_over_flash_count <= 6'd0;
                            start_hold_count      <= 7'd0;
                            start_armed           <= 1'b0;
                            frame_count           <= 4'd0;

                            // Capture running score at time of death
                            game_over_score <= score;
                        end
                        else begin
                            if (snake_len >= 5'd28) begin snake_body27_col <= snake_body26_col; snake_body27_row <= snake_body26_row; end
                            if (snake_len >= 5'd27) begin snake_body26_col <= snake_body25_col; snake_body26_row <= snake_body25_row; end
                            if (snake_len >= 5'd26) begin snake_body25_col <= snake_body24_col; snake_body25_row <= snake_body24_row; end
                            if (snake_len >= 5'd25) begin snake_body24_col <= snake_body23_col; snake_body24_row <= snake_body23_row; end
                            if (snake_len >= 5'd24) begin snake_body23_col <= snake_body22_col; snake_body23_row <= snake_body22_row; end
                            if (snake_len >= 5'd23) begin snake_body22_col <= snake_body21_col; snake_body22_row <= snake_body21_row; end
                            if (snake_len >= 5'd22) begin snake_body21_col <= snake_body20_col; snake_body21_row <= snake_body20_row; end
                            if (snake_len >= 5'd21) begin snake_body20_col <= snake_body19_col; snake_body20_row <= snake_body19_row; end
                            if (snake_len >= 5'd20) begin snake_body19_col <= snake_body18_col; snake_body19_row <= snake_body18_row; end
                            if (snake_len >= 5'd19) begin snake_body18_col <= snake_body17_col; snake_body18_row <= snake_body17_row; end
                            if (snake_len >= 5'd18) begin snake_body17_col <= snake_body16_col; snake_body17_row <= snake_body16_row; end
                            if (snake_len >= 5'd17) begin snake_body16_col <= snake_body15_col; snake_body16_row <= snake_body15_row; end
                            if (snake_len >= 5'd16) begin snake_body15_col <= snake_body14_col; snake_body15_row <= snake_body14_row; end
                            if (snake_len >= 5'd15) begin snake_body14_col <= snake_body13_col; snake_body14_row <= snake_body13_row; end
                            if (snake_len >= 5'd14) begin snake_body13_col <= snake_body12_col; snake_body13_row <= snake_body12_row; end
                            if (snake_len >= 5'd13) begin snake_body12_col <= snake_body11_col; snake_body12_row <= snake_body11_row; end
                            if (snake_len >= 5'd12) begin snake_body11_col <= snake_body10_col; snake_body11_row <= snake_body10_row; end
                            if (snake_len >= 5'd11) begin snake_body10_col <= snake_body9_col;  snake_body10_row <= snake_body9_row;  end
                            if (snake_len >= 5'd10) begin snake_body9_col  <= snake_body8_col;  snake_body9_row  <= snake_body8_row;  end
                            if (snake_len >= 5'd9)  begin snake_body8_col  <= snake_body7_col;  snake_body8_row  <= snake_body7_row;  end
                            if (snake_len >= 5'd8)  begin snake_body7_col  <= snake_body6_col;  snake_body7_row  <= snake_body6_row;  end
                            if (snake_len >= 5'd7)  begin snake_body6_col  <= snake_body5_col;  snake_body6_row  <= snake_body5_row;  end
                            if (snake_len >= 5'd6)  begin snake_body5_col  <= snake_body4_col;  snake_body5_row  <= snake_body4_row;  end
                            if (snake_len >= 5'd5)  begin snake_body4_col  <= snake_body3_col;  snake_body4_row  <= snake_body3_row;  end
                            if (snake_len >= 5'd4)  begin snake_body3_col  <= snake_body2_col;  snake_body3_row  <= snake_body2_row;  end
                            if (snake_len >= 5'd3)  begin snake_body2_col  <= snake_body1_col;  snake_body2_row  <= snake_body1_row;  end
                            if (snake_len >= 5'd2)  begin snake_body1_col  <= snake_head_col;   snake_body1_row  <= snake_head_row;   end

                            snake_head_col <= next_head_col;
                            snake_head_row <= next_head_row;

                            if ((next_head_col == food_col) && (next_head_row == food_row)) begin
                                case (snake_len)
                                    5'd1:  begin snake_body1_col  <= snake_head_col;   snake_body1_row  <= snake_head_row;  end
                                    5'd2:  begin snake_body2_col  <= snake_body1_col;  snake_body2_row  <= snake_body1_row;  end
                                    5'd3:  begin snake_body3_col  <= snake_body2_col;  snake_body3_row  <= snake_body2_row;  end
                                    5'd4:  begin snake_body4_col  <= snake_body3_col;  snake_body4_row  <= snake_body3_row;  end
                                    5'd5:  begin snake_body5_col  <= snake_body4_col;  snake_body5_row  <= snake_body4_row;  end
                                    5'd6:  begin snake_body6_col  <= snake_body5_col;  snake_body6_row  <= snake_body5_row;  end
                                    5'd7:  begin snake_body7_col  <= snake_body6_col;  snake_body7_row  <= snake_body6_row;  end
                                    5'd8:  begin snake_body8_col  <= snake_body7_col;  snake_body8_row  <= snake_body7_row;  end
                                    5'd9:  begin snake_body9_col  <= snake_body8_col;  snake_body9_row  <= snake_body8_row;  end
                                    5'd10: begin snake_body10_col <= snake_body9_col;  snake_body10_row <= snake_body9_row;  end
                                    5'd11: begin snake_body11_col <= snake_body10_col; snake_body11_row <= snake_body10_row; end
                                    5'd12: begin snake_body12_col <= snake_body11_col; snake_body12_row <= snake_body11_row; end
                                    5'd13: begin snake_body13_col <= snake_body12_col; snake_body13_row <= snake_body12_row; end
                                    5'd14: begin snake_body14_col <= snake_body13_col; snake_body14_row <= snake_body13_row; end
                                    5'd15: begin snake_body15_col <= snake_body14_col; snake_body15_row <= snake_body14_row; end
                                    5'd16: begin snake_body16_col <= snake_body15_col; snake_body16_row <= snake_body15_row; end
                                    5'd17: begin snake_body17_col <= snake_body16_col; snake_body17_row <= snake_body16_row; end
                                    5'd18: begin snake_body18_col <= snake_body17_col; snake_body18_row <= snake_body17_row; end
                                    5'd19: begin snake_body19_col <= snake_body18_col; snake_body19_row <= snake_body18_row; end
                                    5'd20: begin snake_body20_col <= snake_body19_col; snake_body20_row <= snake_body19_row; end
                                    5'd21: begin snake_body21_col <= snake_body20_col; snake_body21_row <= snake_body20_row; end
                                    5'd22: begin snake_body22_col <= snake_body21_col; snake_body22_row <= snake_body21_row; end
                                    5'd23: begin snake_body23_col <= snake_body22_col; snake_body23_row <= snake_body22_row; end
                                    5'd24: begin snake_body24_col <= snake_body23_col; snake_body24_row <= snake_body23_row; end
                                    5'd25: begin snake_body25_col <= snake_body24_col; snake_body25_row <= snake_body24_row; end
                                    5'd26: begin snake_body26_col <= snake_body25_col; snake_body26_row <= snake_body25_row; end
                                    5'd27: begin snake_body27_col <= snake_body26_col; snake_body27_row <= snake_body26_row; end
                                    default: begin end
                                endcase

                                // Grow body up to max length
                                if (snake_len < MAX_LEN)
                                    snake_len <= snake_len + 5'd1;

                                // Score always increments on food eaten, capped at 99
                                if (score < 7'd99)
                                    score <= score + 7'd1;

                                case (food_step)
                                    4'd0:  begin food_col <= 5'd14; food_row <= 4'd5;  food_step <= 4'd1;  end
                                    4'd1:  begin food_col <= 5'd14; food_row <= 4'd10; food_step <= 4'd2;  end
                                    4'd2:  begin food_col <= 5'd5;  food_row <= 4'd10; food_step <= 4'd3;  end
                                    4'd3:  begin food_col <= 5'd10; food_row <= 4'd3;  food_step <= 4'd4;  end
                                    4'd4:  begin food_col <= 5'd2;  food_row <= 4'd2;  food_step <= 4'd5;  end
                                    4'd5:  begin food_col <= 5'd17; food_row <= 4'd12; food_step <= 4'd6;  end
                                    4'd6:  begin food_col <= 5'd8;  food_row <= 4'd11; food_step <= 4'd7;  end
                                    4'd7:  begin food_col <= 5'd3;  food_row <= 4'd6;  food_step <= 4'd8;  end
                                    4'd8:  begin food_col <= 5'd18; food_row <= 4'd4;  food_step <= 4'd9;  end
                                    4'd9:  begin food_col <= 5'd11; food_row <= 4'd13; food_step <= 4'd10; end
                                    default: begin food_col <= 5'd5; food_row <= 4'd5; food_step <= 4'd0; end
                                endcase
                            end
                        end
                    end
                    else begin
                        frame_count <= frame_count + 4'd1;
                    end
                end
            end
        end
    end

    snake_renderer u_renderer (
        .vga_x(vga_x),
        .vga_y(vga_y),
        .coord_x(coord_x),
        .coord_y(coord_y),
        .detected(detected),

        .snake_head_col(snake_head_col),
        .snake_head_row(snake_head_row),

        .snake_body1_col(snake_body1_col),
        .snake_body1_row(snake_body1_row),
        .snake_body2_col(snake_body2_col),
        .snake_body2_row(snake_body2_row),
        .snake_body3_col(snake_body3_col),
        .snake_body3_row(snake_body3_row),
        .snake_body4_col(snake_body4_col),
        .snake_body4_row(snake_body4_row),
        .snake_body5_col(snake_body5_col),
        .snake_body5_row(snake_body5_row),
        .snake_body6_col(snake_body6_col),
        .snake_body6_row(snake_body6_row),
        .snake_body7_col(snake_body7_col),
        .snake_body7_row(snake_body7_row),
        .snake_body8_col(snake_body8_col),
        .snake_body8_row(snake_body8_row),
        .snake_body9_col(snake_body9_col),
        .snake_body9_row(snake_body9_row),
        .snake_body10_col(snake_body10_col),
        .snake_body10_row(snake_body10_row),
        .snake_body11_col(snake_body11_col),
        .snake_body11_row(snake_body11_row),
        .snake_body12_col(snake_body12_col),
        .snake_body12_row(snake_body12_row),
        .snake_body13_col(snake_body13_col),
        .snake_body13_row(snake_body13_row),
        .snake_body14_col(snake_body14_col),
        .snake_body14_row(snake_body14_row),
        .snake_body15_col(snake_body15_col),
        .snake_body15_row(snake_body15_row),
        .snake_body16_col(snake_body16_col),
        .snake_body16_row(snake_body16_row),
        .snake_body17_col(snake_body17_col),
        .snake_body17_row(snake_body17_row),
        .snake_body18_col(snake_body18_col),
        .snake_body18_row(snake_body18_row),
        .snake_body19_col(snake_body19_col),
        .snake_body19_row(snake_body19_row),
        .snake_body20_col(snake_body20_col),
        .snake_body20_row(snake_body20_row),
        .snake_body21_col(snake_body21_col),
        .snake_body21_row(snake_body21_row),
        .snake_body22_col(snake_body22_col),
        .snake_body22_row(snake_body22_row),
        .snake_body23_col(snake_body23_col),
        .snake_body23_row(snake_body23_row),
        .snake_body24_col(snake_body24_col),
        .snake_body24_row(snake_body24_row),
        .snake_body25_col(snake_body25_col),
        .snake_body25_row(snake_body25_row),
        .snake_body26_col(snake_body26_col),
        .snake_body26_row(snake_body26_row),
        .snake_body27_col(snake_body27_col),
        .snake_body27_row(snake_body27_row),

        .snake_len(snake_len),
        .score(score),

        .food_col(food_col),
        .food_row(food_row),

        .game_running(game_running),

        .game_over_active(game_over_active),
        .game_over_flash_on(game_over_flash_on),
        .game_over_score(game_over_score),

        .R_out(R_out),
        .G_out(G_out),
        .B_out(B_out)
    );

endmodule