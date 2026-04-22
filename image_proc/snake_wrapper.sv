module snake_wrapper (
    input  logic clk,
    input  logic rst_n,

    input  logic [9:0] coord_x,
    input  logic [9:0] coord_y,
    input  logic       detected,

    input  logic [9:0] vga_x,
    input  logic [9:0] vga_y,
    input  logic       vsync,
    
    input logic game_mode,

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

    localparam logic [5:0] GAME_OVER_FLASH_FRAMES = 6'd30;
    localparam logic [3:0] GAME_OVER_TOTAL_PHASES = 4'd10;

    // First-to-5 win target
    localparam logic [6:0] SCORE_GOAL = 7'd5;

    // AI moves every AI_SPEED_DIV player-ticks (2x slower than player)
    localparam int AI_SPEED_DIV = 2;

    // ----------------------------------------------------------------
    // Player snake registers
    // ----------------------------------------------------------------
    logic [4:0] snake_head_col;
    logic [3:0] snake_head_row;

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

    // ----------------------------------------------------------------
    // AI snake registers
    // ----------------------------------------------------------------
    logic [4:0] ai_head_col;
    logic [3:0] ai_head_row;

    logic [4:0] ai_body1_col;   logic [3:0] ai_body1_row;
    logic [4:0] ai_body2_col;   logic [3:0] ai_body2_row;
    logic [4:0] ai_body3_col;   logic [3:0] ai_body3_row;
    logic [4:0] ai_body4_col;   logic [3:0] ai_body4_row;
    logic [4:0] ai_body5_col;   logic [3:0] ai_body5_row;
    logic [4:0] ai_body6_col;   logic [3:0] ai_body6_row;
    logic [4:0] ai_body7_col;   logic [3:0] ai_body7_row;
    logic [4:0] ai_body8_col;   logic [3:0] ai_body8_row;
    logic [4:0] ai_body9_col;   logic [3:0] ai_body9_row;
    logic [4:0] ai_body10_col;  logic [3:0] ai_body10_row;
    logic [4:0] ai_body11_col;  logic [3:0] ai_body11_row;
    logic [4:0] ai_body12_col;  logic [3:0] ai_body12_row;
    logic [4:0] ai_body13_col;  logic [3:0] ai_body13_row;
    logic [4:0] ai_body14_col;  logic [3:0] ai_body14_row;
    logic [4:0] ai_body15_col;  logic [3:0] ai_body15_row;
    logic [4:0] ai_body16_col;  logic [3:0] ai_body16_row;
    logic [4:0] ai_body17_col;  logic [3:0] ai_body17_row;
    logic [4:0] ai_body18_col;  logic [3:0] ai_body18_row;
    logic [4:0] ai_body19_col;  logic [3:0] ai_body19_row;
    logic [4:0] ai_body20_col;  logic [3:0] ai_body20_row;
    logic [4:0] ai_body21_col;  logic [3:0] ai_body21_row;
    logic [4:0] ai_body22_col;  logic [3:0] ai_body22_row;
    logic [4:0] ai_body23_col;  logic [3:0] ai_body23_row;
    logic [4:0] ai_body24_col;  logic [3:0] ai_body24_row;
    logic [4:0] ai_body25_col;  logic [3:0] ai_body25_row;
    logic [4:0] ai_body26_col;  logic [3:0] ai_body26_row;
    logic [4:0] ai_body27_col;  logic [3:0] ai_body27_row;

    logic [4:0] ai_len;
    logic [1:0] ai_direction;
    logic [6:0] ai_score;
    logic       ai_alive;
    logic [6:0] ai_respawn_count;
    logic [6:0] game_over_ai_score;

    // AI throttle counter (counts player-ticks; AI steps every AI_SPEED_DIV ticks)
    logic [3:0] ai_frame_count;

    // Set when the player (not AI) reached SCORE_GOAL first
    logic       player_won;

    // Top-5 leaderboard (persists across games; Quartus infers M10K)
    reg [6:0] leaderboard [0:4];

    // ----------------------------------------------------------------
    // Food
    // ----------------------------------------------------------------
    logic [4:0] food_col;
    logic [3:0] food_row;
    logic [3:0] food_step;

    // ----------------------------------------------------------------
    // Game state
    // ----------------------------------------------------------------
    logic       game_running;
    logic [1:0] direction;
    logic [3:0] frame_count;

    // Mode select registers
    logic ai_mode;
    logic hold_mode;

    // Start screen state
    logic [6:0] start_hold_count;
    logic       start_armed;

    // Game-over state
    logic       game_over_active;
    logic       game_over_flash_on;
    logic [6:0] game_over_score;
    logic [6:0] score;
    logic [3:0] game_over_flash_phase;
    logic [5:0] game_over_flash_count;

    // Vsync edge detect
    logic vsync_prev;
    logic vsync_fall;

    // Hand helpers
    logic [9:0] head_center_x;
    logic [9:0] head_center_y;
    logic [10:0] dx_mag;
    logic [10:0] dy_mag;
    logic        hand_left;
    logic        hand_up;
    logic        in_dead_zone;

    // Mode-select box helpers
    logic in_1p_box;
    logic in_cpu_box;

    // Next head positions
    logic [4:0] next_head_col;
    logic [3:0] next_head_row;

    logic [4:0] ai_next_head_col;
    logic [3:0] ai_next_head_row;

    // Collision signals
    logic self_collision;
    logic grow_this_step;

    logic ai_grow_this_step;
    logic ai_self_collision;
    logic player_hits_ai;
    logic ai_hits_player;
    logic head_on_collision;

    assign vsync_fall = (vsync_prev == 1'b1) && (vsync == 1'b0);
    assign grow_this_step = (next_head_col == food_col) && (next_head_row == food_row);
    assign game_over_flash_on = ~game_over_flash_phase[0];

    // ----------------------------------------------------------------
    // Hand / box combinational block
    // ----------------------------------------------------------------
    always_comb begin
        head_center_x = {snake_head_col, 5'b00000} + 10'd16;
        head_center_y = {snake_head_row, 5'b00000} + 10'd16;

        if (coord_x < head_center_x) begin
            dx_mag    = {1'b0, (head_center_x - coord_x)};
            hand_left = 1'b1;
        end
        else begin
            dx_mag    = {1'b0, (coord_x - head_center_x)};
            hand_left = 1'b0;
        end

        if (coord_y < head_center_y) begin
            dy_mag  = {1'b0, (head_center_y - coord_y)};
            hand_up = 1'b1;
        end
        else begin
            dy_mag  = {1'b0, (coord_y - head_center_y)};
            hand_up = 1'b0;
        end

        in_dead_zone = game_mode && detected &&
                       (dx_mag <= DEAD_ZONE_X) &&
                       (dy_mag <= DEAD_ZONE_Y);

        in_1p_box  = game_mode && detected &&
                     (coord_x >= 10'd130) && (coord_x < 10'd270) &&
                     (coord_y >= 10'd192) && (coord_y < 10'd288);

        in_cpu_box = game_mode && detected &&
                     (coord_x >= 10'd370) && (coord_x < 10'd510) &&
                     (coord_y >= 10'd192) && (coord_y < 10'd288);
    end

    // ----------------------------------------------------------------
    // Player next-head position
    // ----------------------------------------------------------------
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

    // ----------------------------------------------------------------
    // Player self-collision
    // ----------------------------------------------------------------
    always_comb begin
        self_collision = 1'b0;

        if ((snake_len >= 5'd2)  && ((snake_len != 5'd2)  || grow_this_step) && (next_head_col == snake_body1_col)  && (next_head_row == snake_body1_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd3)  && ((snake_len != 5'd3)  || grow_this_step) && (next_head_col == snake_body2_col)  && (next_head_row == snake_body2_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd4)  && ((snake_len != 5'd4)  || grow_this_step) && (next_head_col == snake_body3_col)  && (next_head_row == snake_body3_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd5)  && ((snake_len != 5'd5)  || grow_this_step) && (next_head_col == snake_body4_col)  && (next_head_row == snake_body4_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd6)  && ((snake_len != 5'd6)  || grow_this_step) && (next_head_col == snake_body5_col)  && (next_head_row == snake_body5_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd7)  && ((snake_len != 5'd7)  || grow_this_step) && (next_head_col == snake_body6_col)  && (next_head_row == snake_body6_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd8)  && ((snake_len != 5'd8)  || grow_this_step) && (next_head_col == snake_body7_col)  && (next_head_row == snake_body7_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd9)  && ((snake_len != 5'd9)  || grow_this_step) && (next_head_col == snake_body8_col)  && (next_head_row == snake_body8_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd10) && ((snake_len != 5'd10) || grow_this_step) && (next_head_col == snake_body9_col)  && (next_head_row == snake_body9_row))  self_collision = 1'b1;
        if ((snake_len >= 5'd11) && ((snake_len != 5'd11) || grow_this_step) && (next_head_col == snake_body10_col) && (next_head_row == snake_body10_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd12) && ((snake_len != 5'd12) || grow_this_step) && (next_head_col == snake_body11_col) && (next_head_row == snake_body11_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd13) && ((snake_len != 5'd13) || grow_this_step) && (next_head_col == snake_body12_col) && (next_head_row == snake_body12_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd14) && ((snake_len != 5'd14) || grow_this_step) && (next_head_col == snake_body13_col) && (next_head_row == snake_body13_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd15) && ((snake_len != 5'd15) || grow_this_step) && (next_head_col == snake_body14_col) && (next_head_row == snake_body14_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd16) && ((snake_len != 5'd16) || grow_this_step) && (next_head_col == snake_body15_col) && (next_head_row == snake_body15_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd17) && ((snake_len != 5'd17) || grow_this_step) && (next_head_col == snake_body16_col) && (next_head_row == snake_body16_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd18) && ((snake_len != 5'd18) || grow_this_step) && (next_head_col == snake_body17_col) && (next_head_row == snake_body17_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd19) && ((snake_len != 5'd19) || grow_this_step) && (next_head_col == snake_body18_col) && (next_head_row == snake_body18_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd20) && ((snake_len != 5'd20) || grow_this_step) && (next_head_col == snake_body19_col) && (next_head_row == snake_body19_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd21) && ((snake_len != 5'd21) || grow_this_step) && (next_head_col == snake_body20_col) && (next_head_row == snake_body20_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd22) && ((snake_len != 5'd22) || grow_this_step) && (next_head_col == snake_body21_col) && (next_head_row == snake_body21_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd23) && ((snake_len != 5'd23) || grow_this_step) && (next_head_col == snake_body22_col) && (next_head_row == snake_body22_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd24) && ((snake_len != 5'd24) || grow_this_step) && (next_head_col == snake_body23_col) && (next_head_row == snake_body23_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd25) && ((snake_len != 5'd25) || grow_this_step) && (next_head_col == snake_body24_col) && (next_head_row == snake_body24_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd26) && ((snake_len != 5'd26) || grow_this_step) && (next_head_col == snake_body25_col) && (next_head_row == snake_body25_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd27) && ((snake_len != 5'd27) || grow_this_step) && (next_head_col == snake_body26_col) && (next_head_row == snake_body26_row)) self_collision = 1'b1;
        if ((snake_len >= 5'd28) && ((snake_len != 5'd28) || grow_this_step) && (next_head_col == snake_body27_col) && (next_head_row == snake_body27_row)) self_collision = 1'b1;
    end

    // ----------------------------------------------------------------
    // AI next-head position
    // ----------------------------------------------------------------
    always_comb begin
        ai_next_head_col = ai_head_col;
        ai_next_head_row = ai_head_row;

        case (ai_direction)
            DIR_UP: begin
                if (ai_head_row == 4'd0)
                    ai_next_head_row = 4'd14;
                else
                    ai_next_head_row = ai_head_row - 4'd1;
            end
            DIR_DOWN: begin
                if (ai_head_row == 4'd14)
                    ai_next_head_row = 4'd0;
                else
                    ai_next_head_row = ai_head_row + 4'd1;
            end
            DIR_LEFT: begin
                if (ai_head_col == 5'd0)
                    ai_next_head_col = 5'd19;
                else
                    ai_next_head_col = ai_head_col - 5'd1;
            end
            default: begin
                if (ai_head_col == 5'd19)
                    ai_next_head_col = 5'd0;
                else
                    ai_next_head_col = ai_head_col + 5'd1;
            end
        endcase
    end

    // ----------------------------------------------------------------
    // AI grow / self-collision
    // ----------------------------------------------------------------
    always_comb begin
        ai_grow_this_step = (ai_next_head_col == food_col) && (ai_next_head_row == food_row);

        ai_self_collision = 1'b0;

        if ((ai_len >= 5'd2)  && ((ai_len != 5'd2)  || ai_grow_this_step) && (ai_next_head_col == ai_body1_col)  && (ai_next_head_row == ai_body1_row))  ai_self_collision = 1'b1;
        if ((ai_len >= 5'd3)  && ((ai_len != 5'd3)  || ai_grow_this_step) && (ai_next_head_col == ai_body2_col)  && (ai_next_head_row == ai_body2_row))  ai_self_collision = 1'b1;
        if ((ai_len >= 5'd4)  && ((ai_len != 5'd4)  || ai_grow_this_step) && (ai_next_head_col == ai_body3_col)  && (ai_next_head_row == ai_body3_row))  ai_self_collision = 1'b1;
        if ((ai_len >= 5'd5)  && ((ai_len != 5'd5)  || ai_grow_this_step) && (ai_next_head_col == ai_body4_col)  && (ai_next_head_row == ai_body4_row))  ai_self_collision = 1'b1;
        if ((ai_len >= 5'd6)  && ((ai_len != 5'd6)  || ai_grow_this_step) && (ai_next_head_col == ai_body5_col)  && (ai_next_head_row == ai_body5_row))  ai_self_collision = 1'b1;
        if ((ai_len >= 5'd7)  && ((ai_len != 5'd7)  || ai_grow_this_step) && (ai_next_head_col == ai_body6_col)  && (ai_next_head_row == ai_body6_row))  ai_self_collision = 1'b1;
        if ((ai_len >= 5'd8)  && ((ai_len != 5'd8)  || ai_grow_this_step) && (ai_next_head_col == ai_body7_col)  && (ai_next_head_row == ai_body7_row))  ai_self_collision = 1'b1;
        if ((ai_len >= 5'd9)  && ((ai_len != 5'd9)  || ai_grow_this_step) && (ai_next_head_col == ai_body8_col)  && (ai_next_head_row == ai_body8_row))  ai_self_collision = 1'b1;
        if ((ai_len >= 5'd10) && ((ai_len != 5'd10) || ai_grow_this_step) && (ai_next_head_col == ai_body9_col)  && (ai_next_head_row == ai_body9_row))  ai_self_collision = 1'b1;
        if ((ai_len >= 5'd11) && ((ai_len != 5'd11) || ai_grow_this_step) && (ai_next_head_col == ai_body10_col) && (ai_next_head_row == ai_body10_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd12) && ((ai_len != 5'd12) || ai_grow_this_step) && (ai_next_head_col == ai_body11_col) && (ai_next_head_row == ai_body11_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd13) && ((ai_len != 5'd13) || ai_grow_this_step) && (ai_next_head_col == ai_body12_col) && (ai_next_head_row == ai_body12_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd14) && ((ai_len != 5'd14) || ai_grow_this_step) && (ai_next_head_col == ai_body13_col) && (ai_next_head_row == ai_body13_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd15) && ((ai_len != 5'd15) || ai_grow_this_step) && (ai_next_head_col == ai_body14_col) && (ai_next_head_row == ai_body14_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd16) && ((ai_len != 5'd16) || ai_grow_this_step) && (ai_next_head_col == ai_body15_col) && (ai_next_head_row == ai_body15_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd17) && ((ai_len != 5'd17) || ai_grow_this_step) && (ai_next_head_col == ai_body16_col) && (ai_next_head_row == ai_body16_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd18) && ((ai_len != 5'd18) || ai_grow_this_step) && (ai_next_head_col == ai_body17_col) && (ai_next_head_row == ai_body17_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd19) && ((ai_len != 5'd19) || ai_grow_this_step) && (ai_next_head_col == ai_body18_col) && (ai_next_head_row == ai_body18_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd20) && ((ai_len != 5'd20) || ai_grow_this_step) && (ai_next_head_col == ai_body19_col) && (ai_next_head_row == ai_body19_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd21) && ((ai_len != 5'd21) || ai_grow_this_step) && (ai_next_head_col == ai_body20_col) && (ai_next_head_row == ai_body20_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd22) && ((ai_len != 5'd22) || ai_grow_this_step) && (ai_next_head_col == ai_body21_col) && (ai_next_head_row == ai_body21_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd23) && ((ai_len != 5'd23) || ai_grow_this_step) && (ai_next_head_col == ai_body22_col) && (ai_next_head_row == ai_body22_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd24) && ((ai_len != 5'd24) || ai_grow_this_step) && (ai_next_head_col == ai_body23_col) && (ai_next_head_row == ai_body23_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd25) && ((ai_len != 5'd25) || ai_grow_this_step) && (ai_next_head_col == ai_body24_col) && (ai_next_head_row == ai_body24_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd26) && ((ai_len != 5'd26) || ai_grow_this_step) && (ai_next_head_col == ai_body25_col) && (ai_next_head_row == ai_body25_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd27) && ((ai_len != 5'd27) || ai_grow_this_step) && (ai_next_head_col == ai_body26_col) && (ai_next_head_row == ai_body26_row)) ai_self_collision = 1'b1;
        if ((ai_len >= 5'd28) && ((ai_len != 5'd28) || ai_grow_this_step) && (ai_next_head_col == ai_body27_col) && (ai_next_head_row == ai_body27_row)) ai_self_collision = 1'b1;
    end

    // ----------------------------------------------------------------
    // player_hits_ai: player next head vs AI body/head
    // ----------------------------------------------------------------
    always_comb begin
        player_hits_ai = 1'b0;

        if (ai_alive) begin
            if ((next_head_col == ai_head_col) && (next_head_row == ai_head_row))
                player_hits_ai = 1'b1;
            if ((ai_len >= 5'd2)  && (next_head_col == ai_body1_col)  && (next_head_row == ai_body1_row))  player_hits_ai = 1'b1;
            if ((ai_len >= 5'd3)  && (next_head_col == ai_body2_col)  && (next_head_row == ai_body2_row))  player_hits_ai = 1'b1;
            if ((ai_len >= 5'd4)  && (next_head_col == ai_body3_col)  && (next_head_row == ai_body3_row))  player_hits_ai = 1'b1;
            if ((ai_len >= 5'd5)  && (next_head_col == ai_body4_col)  && (next_head_row == ai_body4_row))  player_hits_ai = 1'b1;
            if ((ai_len >= 5'd6)  && (next_head_col == ai_body5_col)  && (next_head_row == ai_body5_row))  player_hits_ai = 1'b1;
            if ((ai_len >= 5'd7)  && (next_head_col == ai_body6_col)  && (next_head_row == ai_body6_row))  player_hits_ai = 1'b1;
            if ((ai_len >= 5'd8)  && (next_head_col == ai_body7_col)  && (next_head_row == ai_body7_row))  player_hits_ai = 1'b1;
            if ((ai_len >= 5'd9)  && (next_head_col == ai_body8_col)  && (next_head_row == ai_body8_row))  player_hits_ai = 1'b1;
            if ((ai_len >= 5'd10) && (next_head_col == ai_body9_col)  && (next_head_row == ai_body9_row))  player_hits_ai = 1'b1;
            if ((ai_len >= 5'd11) && (next_head_col == ai_body10_col) && (next_head_row == ai_body10_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd12) && (next_head_col == ai_body11_col) && (next_head_row == ai_body11_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd13) && (next_head_col == ai_body12_col) && (next_head_row == ai_body12_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd14) && (next_head_col == ai_body13_col) && (next_head_row == ai_body13_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd15) && (next_head_col == ai_body14_col) && (next_head_row == ai_body14_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd16) && (next_head_col == ai_body15_col) && (next_head_row == ai_body15_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd17) && (next_head_col == ai_body16_col) && (next_head_row == ai_body16_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd18) && (next_head_col == ai_body17_col) && (next_head_row == ai_body17_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd19) && (next_head_col == ai_body18_col) && (next_head_row == ai_body18_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd20) && (next_head_col == ai_body19_col) && (next_head_row == ai_body19_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd21) && (next_head_col == ai_body20_col) && (next_head_row == ai_body20_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd22) && (next_head_col == ai_body21_col) && (next_head_row == ai_body21_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd23) && (next_head_col == ai_body22_col) && (next_head_row == ai_body22_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd24) && (next_head_col == ai_body23_col) && (next_head_row == ai_body23_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd25) && (next_head_col == ai_body24_col) && (next_head_row == ai_body24_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd26) && (next_head_col == ai_body25_col) && (next_head_row == ai_body25_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd27) && (next_head_col == ai_body26_col) && (next_head_row == ai_body26_row)) player_hits_ai = 1'b1;
            if ((ai_len >= 5'd28) && (next_head_col == ai_body27_col) && (next_head_row == ai_body27_row)) player_hits_ai = 1'b1;
        end

        head_on_collision = ai_alive &&
                            (next_head_col == ai_next_head_col) &&
                            (next_head_row == ai_next_head_row);
    end

    // ----------------------------------------------------------------
    // ai_hits_player: AI next head vs player snake
    // ----------------------------------------------------------------
    always_comb begin
        ai_hits_player = 1'b0;

        if ((ai_next_head_col == snake_head_col) && (ai_next_head_row == snake_head_row))
            ai_hits_player = 1'b1;
        if ((snake_len >= 5'd2)  && (ai_next_head_col == snake_body1_col)  && (ai_next_head_row == snake_body1_row))  ai_hits_player = 1'b1;
        if ((snake_len >= 5'd3)  && (ai_next_head_col == snake_body2_col)  && (ai_next_head_row == snake_body2_row))  ai_hits_player = 1'b1;
        if ((snake_len >= 5'd4)  && (ai_next_head_col == snake_body3_col)  && (ai_next_head_row == snake_body3_row))  ai_hits_player = 1'b1;
        if ((snake_len >= 5'd5)  && (ai_next_head_col == snake_body4_col)  && (ai_next_head_row == snake_body4_row))  ai_hits_player = 1'b1;
        if ((snake_len >= 5'd6)  && (ai_next_head_col == snake_body5_col)  && (ai_next_head_row == snake_body5_row))  ai_hits_player = 1'b1;
        if ((snake_len >= 5'd7)  && (ai_next_head_col == snake_body6_col)  && (ai_next_head_row == snake_body6_row))  ai_hits_player = 1'b1;
        if ((snake_len >= 5'd8)  && (ai_next_head_col == snake_body7_col)  && (ai_next_head_row == snake_body7_row))  ai_hits_player = 1'b1;
        if ((snake_len >= 5'd9)  && (ai_next_head_col == snake_body8_col)  && (ai_next_head_row == snake_body8_row))  ai_hits_player = 1'b1;
        if ((snake_len >= 5'd10) && (ai_next_head_col == snake_body9_col)  && (ai_next_head_row == snake_body9_row))  ai_hits_player = 1'b1;
        if ((snake_len >= 5'd11) && (ai_next_head_col == snake_body10_col) && (ai_next_head_row == snake_body10_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd12) && (ai_next_head_col == snake_body11_col) && (ai_next_head_row == snake_body11_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd13) && (ai_next_head_col == snake_body12_col) && (ai_next_head_row == snake_body12_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd14) && (ai_next_head_col == snake_body13_col) && (ai_next_head_row == snake_body13_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd15) && (ai_next_head_col == snake_body14_col) && (ai_next_head_row == snake_body14_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd16) && (ai_next_head_col == snake_body15_col) && (ai_next_head_row == snake_body15_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd17) && (ai_next_head_col == snake_body16_col) && (ai_next_head_row == snake_body16_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd18) && (ai_next_head_col == snake_body17_col) && (ai_next_head_row == snake_body17_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd19) && (ai_next_head_col == snake_body18_col) && (ai_next_head_row == snake_body18_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd20) && (ai_next_head_col == snake_body19_col) && (ai_next_head_row == snake_body19_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd21) && (ai_next_head_col == snake_body20_col) && (ai_next_head_row == snake_body20_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd22) && (ai_next_head_col == snake_body21_col) && (ai_next_head_row == snake_body21_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd23) && (ai_next_head_col == snake_body22_col) && (ai_next_head_row == snake_body22_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd24) && (ai_next_head_col == snake_body23_col) && (ai_next_head_row == snake_body23_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd25) && (ai_next_head_col == snake_body24_col) && (ai_next_head_row == snake_body24_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd26) && (ai_next_head_col == snake_body25_col) && (ai_next_head_row == snake_body25_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd27) && (ai_next_head_col == snake_body26_col) && (ai_next_head_row == snake_body26_row)) ai_hits_player = 1'b1;
        if ((snake_len >= 5'd28) && (ai_next_head_col == snake_body27_col) && (ai_next_head_row == snake_body27_row)) ai_hits_player = 1'b1;
    end

    // ----------------------------------------------------------------
    // Sequential logic
    // ----------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Player snake
            snake_head_col <= 5'd10; snake_head_row <= 4'd7;
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

            // AI snake
            ai_head_col <= 5'd9;  ai_head_row <= 4'd3;
            ai_body1_col  <= 5'd10; ai_body1_row  <= 4'd3;
            ai_body2_col  <= 5'd11; ai_body2_row  <= 4'd3;
            ai_body3_col  <= 5'd0;  ai_body3_row  <= 4'd0;
            ai_body4_col  <= 5'd0;  ai_body4_row  <= 4'd0;
            ai_body5_col  <= 5'd0;  ai_body5_row  <= 4'd0;
            ai_body6_col  <= 5'd0;  ai_body6_row  <= 4'd0;
            ai_body7_col  <= 5'd0;  ai_body7_row  <= 4'd0;
            ai_body8_col  <= 5'd0;  ai_body8_row  <= 4'd0;
            ai_body9_col  <= 5'd0;  ai_body9_row  <= 4'd0;
            ai_body10_col <= 5'd0;  ai_body10_row <= 4'd0;
            ai_body11_col <= 5'd0;  ai_body11_row <= 4'd0;
            ai_body12_col <= 5'd0;  ai_body12_row <= 4'd0;
            ai_body13_col <= 5'd0;  ai_body13_row <= 4'd0;
            ai_body14_col <= 5'd0;  ai_body14_row <= 4'd0;
            ai_body15_col <= 5'd0;  ai_body15_row <= 4'd0;
            ai_body16_col <= 5'd0;  ai_body16_row <= 4'd0;
            ai_body17_col <= 5'd0;  ai_body17_row <= 4'd0;
            ai_body18_col <= 5'd0;  ai_body18_row <= 4'd0;
            ai_body19_col <= 5'd0;  ai_body19_row <= 4'd0;
            ai_body20_col <= 5'd0;  ai_body20_row <= 4'd0;
            ai_body21_col <= 5'd0;  ai_body21_row <= 4'd0;
            ai_body22_col <= 5'd0;  ai_body22_row <= 4'd0;
            ai_body23_col <= 5'd0;  ai_body23_row <= 4'd0;
            ai_body24_col <= 5'd0;  ai_body24_row <= 4'd0;
            ai_body25_col <= 5'd0;  ai_body25_row <= 4'd0;
            ai_body26_col <= 5'd0;  ai_body26_row <= 4'd0;
            ai_body27_col <= 5'd0;  ai_body27_row <= 4'd0;
            ai_len          <= 5'd3;
            ai_direction    <= DIR_LEFT;
            ai_score        <= 7'd0;
            ai_alive        <= 1'b0;
            ai_respawn_count <= 7'd0;
            game_over_ai_score <= 7'd0;
            ai_frame_count  <= 4'd0;
            player_won      <= 1'b0;

            leaderboard[0] <= 7'd0;
            leaderboard[1] <= 7'd0;
            leaderboard[2] <= 7'd0;
            leaderboard[3] <= 7'd0;
            leaderboard[4] <= 7'd0;

            // Food
            food_col  <= 5'd5;
            food_row  <= 4'd5;
            food_step <= 4'd0;

            // Game state
            game_running     <= 1'b0;
            start_hold_count <= 7'd0;
            start_armed      <= 1'b0;
            ai_mode          <= 1'b0;
            hold_mode        <= 1'b0;

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

            if (!game_mode) begin
                // Reset player
                snake_head_col <= 5'd10; snake_head_row <= 4'd7;
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

                // Reset AI
                ai_head_col <= 5'd9;  ai_head_row <= 4'd3;
                ai_body1_col  <= 5'd10; ai_body1_row  <= 4'd3;
                ai_body2_col  <= 5'd11; ai_body2_row  <= 4'd3;
                ai_body3_col  <= 5'd0;  ai_body3_row  <= 4'd0;
                ai_body4_col  <= 5'd0;  ai_body4_row  <= 4'd0;
                ai_body5_col  <= 5'd0;  ai_body5_row  <= 4'd0;
                ai_body6_col  <= 5'd0;  ai_body6_row  <= 4'd0;
                ai_body7_col  <= 5'd0;  ai_body7_row  <= 4'd0;
                ai_body8_col  <= 5'd0;  ai_body8_row  <= 4'd0;
                ai_body9_col  <= 5'd0;  ai_body9_row  <= 4'd0;
                ai_body10_col <= 5'd0;  ai_body10_row <= 4'd0;
                ai_body11_col <= 5'd0;  ai_body11_row <= 4'd0;
                ai_body12_col <= 5'd0;  ai_body12_row <= 4'd0;
                ai_body13_col <= 5'd0;  ai_body13_row <= 4'd0;
                ai_body14_col <= 5'd0;  ai_body14_row <= 4'd0;
                ai_body15_col <= 5'd0;  ai_body15_row <= 4'd0;
                ai_body16_col <= 5'd0;  ai_body16_row <= 4'd0;
                ai_body17_col <= 5'd0;  ai_body17_row <= 4'd0;
                ai_body18_col <= 5'd0;  ai_body18_row <= 4'd0;
                ai_body19_col <= 5'd0;  ai_body19_row <= 4'd0;
                ai_body20_col <= 5'd0;  ai_body20_row <= 4'd0;
                ai_body21_col <= 5'd0;  ai_body21_row <= 4'd0;
                ai_body22_col <= 5'd0;  ai_body22_row <= 4'd0;
                ai_body23_col <= 5'd0;  ai_body23_row <= 4'd0;
                ai_body24_col <= 5'd0;  ai_body24_row <= 4'd0;
                ai_body25_col <= 5'd0;  ai_body25_row <= 4'd0;
                ai_body26_col <= 5'd0;  ai_body26_row <= 4'd0;
                ai_body27_col <= 5'd0;  ai_body27_row <= 4'd0;
                ai_len          <= 5'd3;
                ai_direction    <= DIR_LEFT;
                ai_score        <= 7'd0;
                ai_alive        <= 1'b0;
                ai_respawn_count <= 7'd0;
                game_over_ai_score <= 7'd0;

                food_col  <= 5'd5;
                food_row  <= 4'd5;
                food_step <= 4'd0;

                game_running     <= 1'b0;
                start_hold_count <= 7'd0;
                start_armed      <= 1'b0;
                ai_mode          <= 1'b0;
                hold_mode        <= 1'b0;

                game_over_active      <= 1'b0;
                game_over_score       <= 7'd0;
                game_over_flash_phase <= 4'd0;
                game_over_flash_count <= 6'd0;

                direction   <= DIR_RIGHT;
                frame_count <= 4'd0;
            end

            else if (vsync_fall) begin
                // ------------------------------------------------
                // Game-over flash sequence
                // ------------------------------------------------
                if (game_over_active) begin
                    if (game_over_flash_count == GAME_OVER_FLASH_FRAMES - 1) begin
                        game_over_flash_count <= 6'd0;

                        if (game_over_flash_phase == GAME_OVER_TOTAL_PHASES - 1) begin
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

                // ------------------------------------------------
                // Start / mode-select screen
                // ------------------------------------------------
                else if (!game_running) begin
                    if (!detected || (!in_1p_box && !in_cpu_box)) begin
                        // Hand not in either box — arm and reset count
                        start_armed      <= 1'b1;
                        start_hold_count <= 7'd0;
                    end
                    else if (start_armed) begin
                        // Hand is in one of the two boxes
                        if (in_1p_box && !in_cpu_box) begin
                            if (hold_mode != 1'b0) begin
                                // Switched to 1P box — reset count
                                hold_mode        <= 1'b0;
                                start_hold_count <= 7'd0;
                            end
                            else if (start_hold_count == START_HOLD_FRAMES - 1) begin
                                // Held long enough — start game in solo mode
                                ai_mode      <= 1'b0;
                                game_running <= 1'b1;
                                frame_count  <= 4'd0;

                                game_over_active      <= 1'b0;
                                game_over_flash_phase <= 4'd0;
                                game_over_flash_count <= 6'd0;

                                // Reset player snake
                                snake_head_col <= 5'd10; snake_head_row <= 4'd7;
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

                                // Reset AI snake (not alive in solo mode)
                                ai_head_col <= 5'd9;  ai_head_row <= 4'd3;
                                ai_body1_col  <= 5'd10; ai_body1_row  <= 4'd3;
                                ai_body2_col  <= 5'd11; ai_body2_row  <= 4'd3;
                                ai_body3_col  <= 5'd0;  ai_body3_row  <= 4'd0;
                                ai_body4_col  <= 5'd0;  ai_body4_row  <= 4'd0;
                                ai_body5_col  <= 5'd0;  ai_body5_row  <= 4'd0;
                                ai_body6_col  <= 5'd0;  ai_body6_row  <= 4'd0;
                                ai_body7_col  <= 5'd0;  ai_body7_row  <= 4'd0;
                                ai_body8_col  <= 5'd0;  ai_body8_row  <= 4'd0;
                                ai_body9_col  <= 5'd0;  ai_body9_row  <= 4'd0;
                                ai_body10_col <= 5'd0;  ai_body10_row <= 4'd0;
                                ai_body11_col <= 5'd0;  ai_body11_row <= 4'd0;
                                ai_body12_col <= 5'd0;  ai_body12_row <= 4'd0;
                                ai_body13_col <= 5'd0;  ai_body13_row <= 4'd0;
                                ai_body14_col <= 5'd0;  ai_body14_row <= 4'd0;
                                ai_body15_col <= 5'd0;  ai_body15_row <= 4'd0;
                                ai_body16_col <= 5'd0;  ai_body16_row <= 4'd0;
                                ai_body17_col <= 5'd0;  ai_body17_row <= 4'd0;
                                ai_body18_col <= 5'd0;  ai_body18_row <= 4'd0;
                                ai_body19_col <= 5'd0;  ai_body19_row <= 4'd0;
                                ai_body20_col <= 5'd0;  ai_body20_row <= 4'd0;
                                ai_body21_col <= 5'd0;  ai_body21_row <= 4'd0;
                                ai_body22_col <= 5'd0;  ai_body22_row <= 4'd0;
                                ai_body23_col <= 5'd0;  ai_body23_row <= 4'd0;
                                ai_body24_col <= 5'd0;  ai_body24_row <= 4'd0;
                                ai_body25_col <= 5'd0;  ai_body25_row <= 4'd0;
                                ai_body26_col <= 5'd0;  ai_body26_row <= 4'd0;
                                ai_body27_col <= 5'd0;  ai_body27_row <= 4'd0;
                                ai_len          <= 5'd3;
                                ai_direction    <= DIR_LEFT;
                                ai_score        <= 7'd0;
                                ai_alive        <= 1'b0;  // solo mode
                                ai_respawn_count <= 7'd0;
                                game_over_ai_score <= 7'd0;
                                ai_frame_count  <= 4'd0;
                                player_won      <= 1'b0;

                                food_col  <= 5'd5;
                                food_row  <= 4'd5;
                                food_step <= 4'd0;

                                direction        <= DIR_RIGHT;
                                start_hold_count <= 7'd0;
                            end
                            else begin
                                start_hold_count <= start_hold_count + 7'd1;
                            end
                        end
                        else if (in_cpu_box && !in_1p_box) begin
                            if (hold_mode != 1'b1) begin
                                // Switched to CPU box — reset count
                                hold_mode        <= 1'b1;
                                start_hold_count <= 7'd0;
                            end
                            else if (start_hold_count == START_HOLD_FRAMES - 1) begin
                                // Held long enough — start game in AI mode
                                ai_mode      <= 1'b1;
                                game_running <= 1'b1;
                                frame_count  <= 4'd0;

                                game_over_active      <= 1'b0;
                                game_over_flash_phase <= 4'd0;
                                game_over_flash_count <= 6'd0;

                                // Reset player snake
                                snake_head_col <= 5'd10; snake_head_row <= 4'd7;
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

                                // Reset AI snake (alive in AI mode)
                                ai_head_col <= 5'd9;  ai_head_row <= 4'd3;
                                ai_body1_col  <= 5'd10; ai_body1_row  <= 4'd3;
                                ai_body2_col  <= 5'd11; ai_body2_row  <= 4'd3;
                                ai_body3_col  <= 5'd0;  ai_body3_row  <= 4'd0;
                                ai_body4_col  <= 5'd0;  ai_body4_row  <= 4'd0;
                                ai_body5_col  <= 5'd0;  ai_body5_row  <= 4'd0;
                                ai_body6_col  <= 5'd0;  ai_body6_row  <= 4'd0;
                                ai_body7_col  <= 5'd0;  ai_body7_row  <= 4'd0;
                                ai_body8_col  <= 5'd0;  ai_body8_row  <= 4'd0;
                                ai_body9_col  <= 5'd0;  ai_body9_row  <= 4'd0;
                                ai_body10_col <= 5'd0;  ai_body10_row <= 4'd0;
                                ai_body11_col <= 5'd0;  ai_body11_row <= 4'd0;
                                ai_body12_col <= 5'd0;  ai_body12_row <= 4'd0;
                                ai_body13_col <= 5'd0;  ai_body13_row <= 4'd0;
                                ai_body14_col <= 5'd0;  ai_body14_row <= 4'd0;
                                ai_body15_col <= 5'd0;  ai_body15_row <= 4'd0;
                                ai_body16_col <= 5'd0;  ai_body16_row <= 4'd0;
                                ai_body17_col <= 5'd0;  ai_body17_row <= 4'd0;
                                ai_body18_col <= 5'd0;  ai_body18_row <= 4'd0;
                                ai_body19_col <= 5'd0;  ai_body19_row <= 4'd0;
                                ai_body20_col <= 5'd0;  ai_body20_row <= 4'd0;
                                ai_body21_col <= 5'd0;  ai_body21_row <= 4'd0;
                                ai_body22_col <= 5'd0;  ai_body22_row <= 4'd0;
                                ai_body23_col <= 5'd0;  ai_body23_row <= 4'd0;
                                ai_body24_col <= 5'd0;  ai_body24_row <= 4'd0;
                                ai_body25_col <= 5'd0;  ai_body25_row <= 4'd0;
                                ai_body26_col <= 5'd0;  ai_body26_row <= 4'd0;
                                ai_body27_col <= 5'd0;  ai_body27_row <= 4'd0;
                                ai_len          <= 5'd3;
                                ai_direction    <= DIR_LEFT;
                                ai_score        <= 7'd0;
                                ai_alive        <= 1'b1;  // AI mode — AI starts alive
                                ai_respawn_count <= 7'd0;
                                game_over_ai_score <= 7'd0;
                                ai_frame_count  <= 4'd0;
                                player_won      <= 1'b0;

                                food_col  <= 5'd5;
                                food_row  <= 4'd5;
                                food_step <= 4'd0;

                                direction        <= DIR_RIGHT;
                                start_hold_count <= 7'd0;
                            end
                            else begin
                                start_hold_count <= start_hold_count + 7'd1;
                            end
                        end
                        else begin
                            // In both boxes simultaneously — reset count
                            start_hold_count <= 7'd0;
                        end
                    end
                    else begin
                        start_hold_count <= 7'd0;
                    end
                end

                // ------------------------------------------------
                // Running game
                // ------------------------------------------------
                else begin
                    // Player direction update
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

                    // AI greedy direction update — only on the AI's own slower tick
                    if (ai_mode && ai_alive && (ai_frame_count == AI_SPEED_DIV - 1)) begin
                        // Compute signed distances
                        // Prefer the axis with larger distance; move toward food;
                        // never reverse. Fall back to other axis if needed.
                        begin : ai_dir_block
                            logic [4:0] ax, ay;
                            logic       food_left, food_up;

                            if (food_col >= ai_head_col) begin
                                ax        = food_col - ai_head_col;
                                food_left = 1'b0;
                            end
                            else begin
                                ax        = ai_head_col - food_col;
                                food_left = 1'b1;
                            end

                            if (food_row >= ai_head_row) begin
                                ay       = food_row - ai_head_row;
                                food_up  = 1'b0;
                            end
                            else begin
                                ay       = ai_head_row - food_row;
                                food_up  = 1'b1;
                            end

                            if (ax >= ay) begin
                                // Prefer horizontal
                                if (food_left) begin
                                    if (ai_direction != DIR_RIGHT)
                                        ai_direction <= DIR_LEFT;
                                    else if (food_up) begin
                                        if (ai_direction != DIR_DOWN)
                                            ai_direction <= DIR_UP;
                                    end
                                    else begin
                                        if (ai_direction != DIR_UP)
                                            ai_direction <= DIR_DOWN;
                                    end
                                end
                                else begin
                                    if (ai_direction != DIR_LEFT)
                                        ai_direction <= DIR_RIGHT;
                                    else if (food_up) begin
                                        if (ai_direction != DIR_DOWN)
                                            ai_direction <= DIR_UP;
                                    end
                                    else begin
                                        if (ai_direction != DIR_UP)
                                            ai_direction <= DIR_DOWN;
                                    end
                                end
                            end
                            else begin
                                // Prefer vertical
                                if (food_up) begin
                                    if (ai_direction != DIR_DOWN)
                                        ai_direction <= DIR_UP;
                                    else if (food_left) begin
                                        if (ai_direction != DIR_RIGHT)
                                            ai_direction <= DIR_LEFT;
                                    end
                                    else begin
                                        if (ai_direction != DIR_LEFT)
                                            ai_direction <= DIR_RIGHT;
                                    end
                                end
                                else begin
                                    if (ai_direction != DIR_UP)
                                        ai_direction <= DIR_DOWN;
                                    else if (food_left) begin
                                        if (ai_direction != DIR_RIGHT)
                                            ai_direction <= DIR_LEFT;
                                    end
                                    else begin
                                        if (ai_direction != DIR_LEFT)
                                            ai_direction <= DIR_RIGHT;
                                    end
                                end
                            end
                        end
                    end

                    // --------------------------------------------------
                    // Per-move tick
                    // --------------------------------------------------
                    if (frame_count == SPEED_DIV - 1) begin
                        frame_count <= 4'd0;

                        // Advance the AI throttle counter
                        if (ai_frame_count == AI_SPEED_DIV - 1)
                            ai_frame_count <= 4'd0;
                        else
                            ai_frame_count <= ai_frame_count + 4'd1;

                        // ------ Score-goal win check ------
                        if (ai_mode && (score == SCORE_GOAL || ai_score == SCORE_GOAL)) begin
                            game_running          <= 1'b0;
                            game_over_active      <= 1'b1;
                            game_over_flash_phase <= 4'd0;
                            game_over_flash_count <= 6'd0;
                            start_hold_count      <= 7'd0;
                            start_armed           <= 1'b0;
                            frame_count           <= 4'd0;
                            game_over_score       <= score;
                            game_over_ai_score    <= ai_score;
                            player_won            <= (score == SCORE_GOAL) ? 1'b1 : 1'b0;
                            // Sorted leaderboard insert
                            if      (score >= leaderboard[0]) begin leaderboard[4]<=leaderboard[3]; leaderboard[3]<=leaderboard[2]; leaderboard[2]<=leaderboard[1]; leaderboard[1]<=leaderboard[0]; leaderboard[0]<=score; end
                            else if (score >= leaderboard[1]) begin leaderboard[4]<=leaderboard[3]; leaderboard[3]<=leaderboard[2]; leaderboard[2]<=leaderboard[1]; leaderboard[1]<=score; end
                            else if (score >= leaderboard[2]) begin leaderboard[4]<=leaderboard[3]; leaderboard[3]<=leaderboard[2]; leaderboard[2]<=score; end
                            else if (score >= leaderboard[3]) begin leaderboard[4]<=leaderboard[3]; leaderboard[3]<=score; end
                            else if (score >= leaderboard[4]) begin leaderboard[4]<=score; end
                        end
                        // ------ Player collision check ------
                        else if (self_collision || (player_hits_ai && ai_alive) || head_on_collision) begin
                            game_running          <= 1'b0;
                            game_over_active      <= 1'b1;
                            game_over_flash_phase <= 4'd0;
                            game_over_flash_count <= 6'd0;
                            start_hold_count      <= 7'd0;
                            start_armed           <= 1'b0;
                            frame_count           <= 4'd0;
                            game_over_score       <= score;
                            game_over_ai_score    <= ai_score;
                            player_won            <= 1'b0;
                            // Sorted leaderboard insert
                            if      (score >= leaderboard[0]) begin leaderboard[4]<=leaderboard[3]; leaderboard[3]<=leaderboard[2]; leaderboard[2]<=leaderboard[1]; leaderboard[1]<=leaderboard[0]; leaderboard[0]<=score; end
                            else if (score >= leaderboard[1]) begin leaderboard[4]<=leaderboard[3]; leaderboard[3]<=leaderboard[2]; leaderboard[2]<=leaderboard[1]; leaderboard[1]<=score; end
                            else if (score >= leaderboard[2]) begin leaderboard[4]<=leaderboard[3]; leaderboard[3]<=leaderboard[2]; leaderboard[2]<=score; end
                            else if (score >= leaderboard[3]) begin leaderboard[4]<=leaderboard[3]; leaderboard[3]<=score; end
                            else if (score >= leaderboard[4]) begin leaderboard[4]<=score; end
                        end
                        else begin
                            // ------ Player body shift ------
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

                            // ------ Player food-eat: grow only (food advancement handled below) ------
                            if (grow_this_step) begin
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

                                if (snake_len < MAX_LEN)
                                    snake_len <= snake_len + 5'd1;

                                if (score < 7'd99)
                                    score <= score + 7'd1;
                            end

                            // ------ AI movement (half-speed: every AI_SPEED_DIV player ticks) ------
                            if (ai_mode && (ai_frame_count == 4'd0)) begin
                                if (ai_alive) begin
                                    if (ai_self_collision || ai_hits_player || head_on_collision) begin
                                        ai_alive         <= 1'b0;
                                        ai_respawn_count <= 7'd0;
                                    end
                                    else begin
                                        // AI body shift
                                        if (ai_len >= 5'd28) begin ai_body27_col <= ai_body26_col; ai_body27_row <= ai_body26_row; end
                                        if (ai_len >= 5'd27) begin ai_body26_col <= ai_body25_col; ai_body26_row <= ai_body25_row; end
                                        if (ai_len >= 5'd26) begin ai_body25_col <= ai_body24_col; ai_body25_row <= ai_body24_row; end
                                        if (ai_len >= 5'd25) begin ai_body24_col <= ai_body23_col; ai_body24_row <= ai_body23_row; end
                                        if (ai_len >= 5'd24) begin ai_body23_col <= ai_body22_col; ai_body23_row <= ai_body22_row; end
                                        if (ai_len >= 5'd23) begin ai_body22_col <= ai_body21_col; ai_body22_row <= ai_body21_row; end
                                        if (ai_len >= 5'd22) begin ai_body21_col <= ai_body20_col; ai_body21_row <= ai_body20_row; end
                                        if (ai_len >= 5'd21) begin ai_body20_col <= ai_body19_col; ai_body20_row <= ai_body19_row; end
                                        if (ai_len >= 5'd20) begin ai_body19_col <= ai_body18_col; ai_body19_row <= ai_body18_row; end
                                        if (ai_len >= 5'd19) begin ai_body18_col <= ai_body17_col; ai_body18_row <= ai_body17_row; end
                                        if (ai_len >= 5'd18) begin ai_body17_col <= ai_body16_col; ai_body17_row <= ai_body16_row; end
                                        if (ai_len >= 5'd17) begin ai_body16_col <= ai_body15_col; ai_body16_row <= ai_body15_row; end
                                        if (ai_len >= 5'd16) begin ai_body15_col <= ai_body14_col; ai_body15_row <= ai_body14_row; end
                                        if (ai_len >= 5'd15) begin ai_body14_col <= ai_body13_col; ai_body14_row <= ai_body13_row; end
                                        if (ai_len >= 5'd14) begin ai_body13_col <= ai_body12_col; ai_body13_row <= ai_body12_row; end
                                        if (ai_len >= 5'd13) begin ai_body12_col <= ai_body11_col; ai_body12_row <= ai_body11_row; end
                                        if (ai_len >= 5'd12) begin ai_body11_col <= ai_body10_col; ai_body11_row <= ai_body10_row; end
                                        if (ai_len >= 5'd11) begin ai_body10_col <= ai_body9_col;  ai_body10_row <= ai_body9_row;  end
                                        if (ai_len >= 5'd10) begin ai_body9_col  <= ai_body8_col;  ai_body9_row  <= ai_body8_row;  end
                                        if (ai_len >= 5'd9)  begin ai_body8_col  <= ai_body7_col;  ai_body8_row  <= ai_body7_row;  end
                                        if (ai_len >= 5'd8)  begin ai_body7_col  <= ai_body6_col;  ai_body7_row  <= ai_body6_row;  end
                                        if (ai_len >= 5'd7)  begin ai_body6_col  <= ai_body5_col;  ai_body6_row  <= ai_body5_row;  end
                                        if (ai_len >= 5'd6)  begin ai_body5_col  <= ai_body4_col;  ai_body5_row  <= ai_body4_row;  end
                                        if (ai_len >= 5'd5)  begin ai_body4_col  <= ai_body3_col;  ai_body4_row  <= ai_body3_row;  end
                                        if (ai_len >= 5'd4)  begin ai_body3_col  <= ai_body2_col;  ai_body3_row  <= ai_body2_row;  end
                                        if (ai_len >= 5'd3)  begin ai_body2_col  <= ai_body1_col;  ai_body2_row  <= ai_body1_row;  end
                                        if (ai_len >= 5'd2)  begin ai_body1_col  <= ai_head_col;   ai_body1_row  <= ai_head_row;   end

                                        ai_head_col <= ai_next_head_col;
                                        ai_head_row <= ai_next_head_row;

                                        if (ai_grow_this_step) begin
                                            case (ai_len)
                                                5'd1:  begin ai_body1_col  <= ai_head_col;   ai_body1_row  <= ai_head_row;  end
                                                5'd2:  begin ai_body2_col  <= ai_body1_col;  ai_body2_row  <= ai_body1_row;  end
                                                5'd3:  begin ai_body3_col  <= ai_body2_col;  ai_body3_row  <= ai_body2_row;  end
                                                5'd4:  begin ai_body4_col  <= ai_body3_col;  ai_body4_row  <= ai_body3_row;  end
                                                5'd5:  begin ai_body5_col  <= ai_body4_col;  ai_body5_row  <= ai_body4_row;  end
                                                5'd6:  begin ai_body6_col  <= ai_body5_col;  ai_body6_row  <= ai_body5_row;  end
                                                5'd7:  begin ai_body7_col  <= ai_body6_col;  ai_body7_row  <= ai_body6_row;  end
                                                5'd8:  begin ai_body8_col  <= ai_body7_col;  ai_body8_row  <= ai_body7_row;  end
                                                5'd9:  begin ai_body9_col  <= ai_body8_col;  ai_body9_row  <= ai_body8_row;  end
                                                5'd10: begin ai_body10_col <= ai_body9_col;  ai_body10_row <= ai_body9_row;  end
                                                5'd11: begin ai_body11_col <= ai_body10_col; ai_body11_row <= ai_body10_row; end
                                                5'd12: begin ai_body12_col <= ai_body11_col; ai_body12_row <= ai_body11_row; end
                                                5'd13: begin ai_body13_col <= ai_body12_col; ai_body13_row <= ai_body12_row; end
                                                5'd14: begin ai_body14_col <= ai_body13_col; ai_body14_row <= ai_body13_row; end
                                                5'd15: begin ai_body15_col <= ai_body14_col; ai_body15_row <= ai_body14_row; end
                                                5'd16: begin ai_body16_col <= ai_body15_col; ai_body16_row <= ai_body15_row; end
                                                5'd17: begin ai_body17_col <= ai_body16_col; ai_body17_row <= ai_body16_row; end
                                                5'd18: begin ai_body18_col <= ai_body17_col; ai_body18_row <= ai_body17_row; end
                                                5'd19: begin ai_body19_col <= ai_body18_col; ai_body19_row <= ai_body18_row; end
                                                5'd20: begin ai_body20_col <= ai_body19_col; ai_body20_row <= ai_body19_row; end
                                                5'd21: begin ai_body21_col <= ai_body20_col; ai_body21_row <= ai_body20_row; end
                                                5'd22: begin ai_body22_col <= ai_body21_col; ai_body22_row <= ai_body21_row; end
                                                5'd23: begin ai_body23_col <= ai_body22_col; ai_body23_row <= ai_body22_row; end
                                                5'd24: begin ai_body24_col <= ai_body23_col; ai_body24_row <= ai_body23_row; end
                                                5'd25: begin ai_body25_col <= ai_body24_col; ai_body25_row <= ai_body24_row; end
                                                5'd26: begin ai_body26_col <= ai_body25_col; ai_body26_row <= ai_body25_row; end
                                                5'd27: begin ai_body27_col <= ai_body26_col; ai_body27_row <= ai_body26_row; end
                                                default: begin end
                                            endcase

                                            if (ai_len < MAX_LEN)
                                                ai_len <= ai_len + 5'd1;

                                            if (ai_score < 7'd99)
                                                ai_score <= ai_score + 7'd1;
                                        end
                                    end
                                end
                                else begin
                                    // AI is dead — count respawn frames
                                    if (ai_respawn_count == 7'd59) begin
                                        // Respawn AI
                                        ai_head_col <= 5'd9;  ai_head_row <= 4'd3;
                                        ai_body1_col  <= 5'd10; ai_body1_row  <= 4'd3;
                                        ai_body2_col  <= 5'd11; ai_body2_row  <= 4'd3;
                                        ai_body3_col  <= 5'd0;  ai_body3_row  <= 4'd0;
                                        ai_body4_col  <= 5'd0;  ai_body4_row  <= 4'd0;
                                        ai_body5_col  <= 5'd0;  ai_body5_row  <= 4'd0;
                                        ai_body6_col  <= 5'd0;  ai_body6_row  <= 4'd0;
                                        ai_body7_col  <= 5'd0;  ai_body7_row  <= 4'd0;
                                        ai_body8_col  <= 5'd0;  ai_body8_row  <= 4'd0;
                                        ai_body9_col  <= 5'd0;  ai_body9_row  <= 4'd0;
                                        ai_body10_col <= 5'd0;  ai_body10_row <= 4'd0;
                                        ai_body11_col <= 5'd0;  ai_body11_row <= 4'd0;
                                        ai_body12_col <= 5'd0;  ai_body12_row <= 4'd0;
                                        ai_body13_col <= 5'd0;  ai_body13_row <= 4'd0;
                                        ai_body14_col <= 5'd0;  ai_body14_row <= 4'd0;
                                        ai_body15_col <= 5'd0;  ai_body15_row <= 4'd0;
                                        ai_body16_col <= 5'd0;  ai_body16_row <= 4'd0;
                                        ai_body17_col <= 5'd0;  ai_body17_row <= 4'd0;
                                        ai_body18_col <= 5'd0;  ai_body18_row <= 4'd0;
                                        ai_body19_col <= 5'd0;  ai_body19_row <= 4'd0;
                                        ai_body20_col <= 5'd0;  ai_body20_row <= 4'd0;
                                        ai_body21_col <= 5'd0;  ai_body21_row <= 4'd0;
                                        ai_body22_col <= 5'd0;  ai_body22_row <= 4'd0;
                                        ai_body23_col <= 5'd0;  ai_body23_row <= 4'd0;
                                        ai_body24_col <= 5'd0;  ai_body24_row <= 4'd0;
                                        ai_body25_col <= 5'd0;  ai_body25_row <= 4'd0;
                                        ai_body26_col <= 5'd0;  ai_body26_row <= 4'd0;
                                        ai_body27_col <= 5'd0;  ai_body27_row <= 4'd0;
                                        ai_len        <= 5'd3;
                                        ai_direction  <= DIR_LEFT;
                                        ai_alive      <= 1'b1;
                                    end
                                    else begin
                                        ai_respawn_count <= ai_respawn_count + 7'd1;
                                    end
                                end
                            end

                            // ------ Food advancement ------
                            if (grow_this_step || (ai_grow_this_step && ai_mode)) begin
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

                        end // else (no player collision)
                    end // frame_count == SPEED_DIV-1
                    else begin
                        frame_count <= frame_count + 4'd1;
                    end
                end // game_running
            end // vsync_fall
        end // !rst_n else
    end

    // ----------------------------------------------------------------
    // Renderer instantiation
    // ----------------------------------------------------------------
    snake_renderer u_renderer (
        .vga_x(vga_x),
        .vga_y(vga_y),
        .coord_x(coord_x),
        .coord_y(coord_y),
        .detected(detected),

        .snake_head_col(snake_head_col),
        .snake_head_row(snake_head_row),

        .snake_body1_col(snake_body1_col),   .snake_body1_row(snake_body1_row),
        .snake_body2_col(snake_body2_col),   .snake_body2_row(snake_body2_row),
        .snake_body3_col(snake_body3_col),   .snake_body3_row(snake_body3_row),
        .snake_body4_col(snake_body4_col),   .snake_body4_row(snake_body4_row),
        .snake_body5_col(snake_body5_col),   .snake_body5_row(snake_body5_row),
        .snake_body6_col(snake_body6_col),   .snake_body6_row(snake_body6_row),
        .snake_body7_col(snake_body7_col),   .snake_body7_row(snake_body7_row),
        .snake_body8_col(snake_body8_col),   .snake_body8_row(snake_body8_row),
        .snake_body9_col(snake_body9_col),   .snake_body9_row(snake_body9_row),
        .snake_body10_col(snake_body10_col), .snake_body10_row(snake_body10_row),
        .snake_body11_col(snake_body11_col), .snake_body11_row(snake_body11_row),
        .snake_body12_col(snake_body12_col), .snake_body12_row(snake_body12_row),
        .snake_body13_col(snake_body13_col), .snake_body13_row(snake_body13_row),
        .snake_body14_col(snake_body14_col), .snake_body14_row(snake_body14_row),
        .snake_body15_col(snake_body15_col), .snake_body15_row(snake_body15_row),
        .snake_body16_col(snake_body16_col), .snake_body16_row(snake_body16_row),
        .snake_body17_col(snake_body17_col), .snake_body17_row(snake_body17_row),
        .snake_body18_col(snake_body18_col), .snake_body18_row(snake_body18_row),
        .snake_body19_col(snake_body19_col), .snake_body19_row(snake_body19_row),
        .snake_body20_col(snake_body20_col), .snake_body20_row(snake_body20_row),
        .snake_body21_col(snake_body21_col), .snake_body21_row(snake_body21_row),
        .snake_body22_col(snake_body22_col), .snake_body22_row(snake_body22_row),
        .snake_body23_col(snake_body23_col), .snake_body23_row(snake_body23_row),
        .snake_body24_col(snake_body24_col), .snake_body24_row(snake_body24_row),
        .snake_body25_col(snake_body25_col), .snake_body25_row(snake_body25_row),
        .snake_body26_col(snake_body26_col), .snake_body26_row(snake_body26_row),
        .snake_body27_col(snake_body27_col), .snake_body27_row(snake_body27_row),

        .snake_len(snake_len),
        .score(score),

        .food_col(food_col),
        .food_row(food_row),

        .game_running(game_running),
        .start_hold_count(start_hold_count),
        .hold_mode(hold_mode),

        .game_over_active(game_over_active),
        .game_over_flash_on(game_over_flash_on),
        .game_over_score(game_over_score),
        .player_won(player_won),
        .lb0(leaderboard[0]), .lb1(leaderboard[1]), .lb2(leaderboard[2]),
        .lb3(leaderboard[3]), .lb4(leaderboard[4]),

        // AI ports
        .ai_head_col(ai_head_col),
        .ai_head_row(ai_head_row),
        .ai_body1_col(ai_body1_col),   .ai_body1_row(ai_body1_row),
        .ai_body2_col(ai_body2_col),   .ai_body2_row(ai_body2_row),
        .ai_body3_col(ai_body3_col),   .ai_body3_row(ai_body3_row),
        .ai_body4_col(ai_body4_col),   .ai_body4_row(ai_body4_row),
        .ai_body5_col(ai_body5_col),   .ai_body5_row(ai_body5_row),
        .ai_body6_col(ai_body6_col),   .ai_body6_row(ai_body6_row),
        .ai_body7_col(ai_body7_col),   .ai_body7_row(ai_body7_row),
        .ai_body8_col(ai_body8_col),   .ai_body8_row(ai_body8_row),
        .ai_body9_col(ai_body9_col),   .ai_body9_row(ai_body9_row),
        .ai_body10_col(ai_body10_col), .ai_body10_row(ai_body10_row),
        .ai_body11_col(ai_body11_col), .ai_body11_row(ai_body11_row),
        .ai_body12_col(ai_body12_col), .ai_body12_row(ai_body12_row),
        .ai_body13_col(ai_body13_col), .ai_body13_row(ai_body13_row),
        .ai_body14_col(ai_body14_col), .ai_body14_row(ai_body14_row),
        .ai_body15_col(ai_body15_col), .ai_body15_row(ai_body15_row),
        .ai_body16_col(ai_body16_col), .ai_body16_row(ai_body16_row),
        .ai_body17_col(ai_body17_col), .ai_body17_row(ai_body17_row),
        .ai_body18_col(ai_body18_col), .ai_body18_row(ai_body18_row),
        .ai_body19_col(ai_body19_col), .ai_body19_row(ai_body19_row),
        .ai_body20_col(ai_body20_col), .ai_body20_row(ai_body20_row),
        .ai_body21_col(ai_body21_col), .ai_body21_row(ai_body21_row),
        .ai_body22_col(ai_body22_col), .ai_body22_row(ai_body22_row),
        .ai_body23_col(ai_body23_col), .ai_body23_row(ai_body23_row),
        .ai_body24_col(ai_body24_col), .ai_body24_row(ai_body24_row),
        .ai_body25_col(ai_body25_col), .ai_body25_row(ai_body25_row),
        .ai_body26_col(ai_body26_col), .ai_body26_row(ai_body26_row),
        .ai_body27_col(ai_body27_col), .ai_body27_row(ai_body27_row),
        .ai_len(ai_len),
        .ai_score(ai_score),
        .ai_alive(ai_alive),
        .ai_mode(ai_mode),
        .game_over_ai_score(game_over_ai_score),

        .R_out(R_out),
        .G_out(G_out),
        .B_out(B_out)
    );

endmodule