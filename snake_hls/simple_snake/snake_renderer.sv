module snake_renderer (
    input  logic [9:0] vga_x,
    input  logic [9:0] vga_y,

    input  logic [9:0] coord_x,
    input  logic [9:0] coord_y,
    input  logic       detected,

    // Player head
    input  logic [4:0] snake_head_col,
    input  logic [3:0] snake_head_row,

    // Player body segments 1..27
    input  logic [4:0] snake_body1_col,
    input  logic [3:0] snake_body1_row,
    input  logic [4:0] snake_body2_col,
    input  logic [3:0] snake_body2_row,
    input  logic [4:0] snake_body3_col,
    input  logic [3:0] snake_body3_row,
    input  logic [4:0] snake_body4_col,
    input  logic [3:0] snake_body4_row,
    input  logic [4:0] snake_body5_col,
    input  logic [3:0] snake_body5_row,
    input  logic [4:0] snake_body6_col,
    input  logic [3:0] snake_body6_row,
    input  logic [4:0] snake_body7_col,
    input  logic [3:0] snake_body7_row,
    input  logic [4:0] snake_body8_col,
    input  logic [3:0] snake_body8_row,
    input  logic [4:0] snake_body9_col,
    input  logic [3:0] snake_body9_row,
    input  logic [4:0] snake_body10_col,
    input  logic [3:0] snake_body10_row,
    input  logic [4:0] snake_body11_col,
    input  logic [3:0] snake_body11_row,
    input  logic [4:0] snake_body12_col,
    input  logic [3:0] snake_body12_row,
    input  logic [4:0] snake_body13_col,
    input  logic [3:0] snake_body13_row,
    input  logic [4:0] snake_body14_col,
    input  logic [3:0] snake_body14_row,
    input  logic [4:0] snake_body15_col,
    input  logic [3:0] snake_body15_row,
    input  logic [4:0] snake_body16_col,
    input  logic [3:0] snake_body16_row,
    input  logic [4:0] snake_body17_col,
    input  logic [3:0] snake_body17_row,
    input  logic [4:0] snake_body18_col,
    input  logic [3:0] snake_body18_row,
    input  logic [4:0] snake_body19_col,
    input  logic [3:0] snake_body19_row,
    input  logic [4:0] snake_body20_col,
    input  logic [3:0] snake_body20_row,
    input  logic [4:0] snake_body21_col,
    input  logic [3:0] snake_body21_row,
    input  logic [4:0] snake_body22_col,
    input  logic [3:0] snake_body22_row,
    input  logic [4:0] snake_body23_col,
    input  logic [3:0] snake_body23_row,
    input  logic [4:0] snake_body24_col,
    input  logic [3:0] snake_body24_row,
    input  logic [4:0] snake_body25_col,
    input  logic [3:0] snake_body25_row,
    input  logic [4:0] snake_body26_col,
    input  logic [3:0] snake_body26_row,
    input  logic [4:0] snake_body27_col,
    input  logic [3:0] snake_body27_row,

    input  logic [4:0] snake_len,
    input  logic [6:0] score,

    // Food
    input  logic [4:0] food_col,
    input  logic [3:0] food_row,

    // Start / game state
    input  logic       game_running,
    input  logic [6:0] start_hold_count,
    input  logic       hold_mode,

    // Game-over
    input  logic       game_over_active,
    input  logic       game_over_flash_on,
    input  logic [6:0] game_over_score,
    input  logic       player_won,
    input  logic [6:0] lb0, lb1, lb2, lb3, lb4,

    // AI snake head
    input  logic [4:0] ai_head_col,
    input  logic [3:0] ai_head_row,

    // AI body segments 1..27
    input  logic [4:0] ai_body1_col,
    input  logic [3:0] ai_body1_row,
    input  logic [4:0] ai_body2_col,
    input  logic [3:0] ai_body2_row,
    input  logic [4:0] ai_body3_col,
    input  logic [3:0] ai_body3_row,
    input  logic [4:0] ai_body4_col,
    input  logic [3:0] ai_body4_row,
    input  logic [4:0] ai_body5_col,
    input  logic [3:0] ai_body5_row,
    input  logic [4:0] ai_body6_col,
    input  logic [3:0] ai_body6_row,
    input  logic [4:0] ai_body7_col,
    input  logic [3:0] ai_body7_row,
    input  logic [4:0] ai_body8_col,
    input  logic [3:0] ai_body8_row,
    input  logic [4:0] ai_body9_col,
    input  logic [3:0] ai_body9_row,
    input  logic [4:0] ai_body10_col,
    input  logic [3:0] ai_body10_row,
    input  logic [4:0] ai_body11_col,
    input  logic [3:0] ai_body11_row,
    input  logic [4:0] ai_body12_col,
    input  logic [3:0] ai_body12_row,
    input  logic [4:0] ai_body13_col,
    input  logic [3:0] ai_body13_row,
    input  logic [4:0] ai_body14_col,
    input  logic [3:0] ai_body14_row,
    input  logic [4:0] ai_body15_col,
    input  logic [3:0] ai_body15_row,
    input  logic [4:0] ai_body16_col,
    input  logic [3:0] ai_body16_row,
    input  logic [4:0] ai_body17_col,
    input  logic [3:0] ai_body17_row,
    input  logic [4:0] ai_body18_col,
    input  logic [3:0] ai_body18_row,
    input  logic [4:0] ai_body19_col,
    input  logic [3:0] ai_body19_row,
    input  logic [4:0] ai_body20_col,
    input  logic [3:0] ai_body20_row,
    input  logic [4:0] ai_body21_col,
    input  logic [3:0] ai_body21_row,
    input  logic [4:0] ai_body22_col,
    input  logic [3:0] ai_body22_row,
    input  logic [4:0] ai_body23_col,
    input  logic [3:0] ai_body23_row,
    input  logic [4:0] ai_body24_col,
    input  logic [3:0] ai_body24_row,
    input  logic [4:0] ai_body25_col,
    input  logic [3:0] ai_body25_row,
    input  logic [4:0] ai_body26_col,
    input  logic [3:0] ai_body26_row,
    input  logic [4:0] ai_body27_col,
    input  logic [3:0] ai_body27_row,

    input  logic [4:0] ai_len,
    input  logic [6:0] ai_score,
    input  logic       ai_alive,
    input  logic       ai_mode,
    input  logic [6:0] game_over_ai_score,

    output logic [9:0] R_out,
    output logic [9:0] G_out,
    output logic [9:0] B_out
);

    localparam logic [6:0] START_HOLD_FRAMES = 7'd120;

    logic [4:0] cell_col;
    logic [3:0] cell_row;

    logic head_on;
    logic body_on;
    logic food_on;
    logic hand_on;

    logic [10:0] hand_dx_mag;
    logic [10:0] hand_dy_mag;

    // Player body hit signals
    logic body1_on,  body2_on,  body3_on,  body4_on,  body5_on,  body6_on;
    logic body7_on,  body8_on,  body9_on,  body10_on, body11_on;
    logic body12_on, body13_on, body14_on, body15_on, body16_on, body17_on;
    logic body18_on, body19_on, body20_on, body21_on, body22_on, body23_on;
    logic body24_on, body25_on, body26_on, body27_on;

    // AI hit signals
    logic ai_head_on;
    logic ai_body1_on,  ai_body2_on,  ai_body3_on,  ai_body4_on,  ai_body5_on,  ai_body6_on;
    logic ai_body7_on,  ai_body8_on,  ai_body9_on,  ai_body10_on, ai_body11_on;
    logic ai_body12_on, ai_body13_on, ai_body14_on, ai_body15_on, ai_body16_on, ai_body17_on;
    logic ai_body18_on, ai_body19_on, ai_body20_on, ai_body21_on, ai_body22_on, ai_body23_on;
    logic ai_body24_on, ai_body25_on, ai_body26_on, ai_body27_on;
    logic ai_body_on;

    // Background / apple sprite helpers
    logic bg_dark_cell;
    logic [4:0] cell_px;
    logic [4:0] cell_py;

    logic apple_body_on;
    logic apple_leaf_on;
    logic apple_stem_on;

    // Start button signals (two boxes)
    logic start_shadow_1p_on,    start_outer_1p_on,    start_inner_1p_on;
    logic start_highlight_1p_on, start_progress_bg_1p_on, start_progress_fill_1p_on;
    logic start_text_1p_on;

    logic start_shadow_cpu_on,    start_outer_cpu_on,    start_inner_cpu_on;
    logic start_highlight_cpu_on, start_progress_bg_cpu_on, start_progress_fill_cpu_on;
    logic start_text_cpu_on;

    logic [9:0] start_x;
    logic [9:0] start_y;
    logic [4:0] start_char_index;
    logic [2:0] start_char_px;
    logic [2:0] start_char_py;
    logic [9:0] progress_fill_width;

    // Score / text overlay signals
    logic [6:0] score_value;
    logic [6:0] score_tens;
    logic [6:0] score_ones;
    logic [6:0] ai_score_tens;
    logic [6:0] ai_score_ones;

    logic score_on;
    logic cpu_score_on;

    logic [9:0] score_x;
    logic [9:0] score_y;

    logic [3:0] char_index;
    logic [2:0] char_px;
    logic [2:0] char_py;

    logic [4:0] glyph_row_bits;
    logic [4:0] char_code;

    // Game-over banner signals
    logic game_over_banner_fill_on;
    logic game_over_banner_border_on;
    logic game_over_big_text_on;
    logic game_over_small_text_on;
    logic game_over_small2_text_on;
    logic lb_title_on;
    logic lb_row_on;

    logic [9:0] go_x;
    logic [9:0] go_y;

    logic [4:0] go_big_char_index;
    logic [2:0] go_big_char_px;
    logic [2:0] go_big_char_py;

    logic [4:0] go_small_char_index;
    logic [2:0] go_small_char_px;
    logic [2:0] go_small_char_py;

    logic [4:0] go_char_code;

    // Character codes
    localparam logic [4:0] CH_BLANK = 5'd0;
    localparam logic [4:0] CH_S     = 5'd1;
    localparam logic [4:0] CH_C     = 5'd2;
    localparam logic [4:0] CH_O     = 5'd3;
    localparam logic [4:0] CH_R     = 5'd4;
    localparam logic [4:0] CH_E     = 5'd5;
    localparam logic [4:0] CH_COLON = 5'd6;
    localparam logic [4:0] CH_0     = 5'd7;
    localparam logic [4:0] CH_1     = 5'd8;
    localparam logic [4:0] CH_2     = 5'd9;
    localparam logic [4:0] CH_3     = 5'd10;
    localparam logic [4:0] CH_4     = 5'd11;
    localparam logic [4:0] CH_5     = 5'd12;
    localparam logic [4:0] CH_6     = 5'd13;
    localparam logic [4:0] CH_7     = 5'd14;
    localparam logic [4:0] CH_8     = 5'd15;
    localparam logic [4:0] CH_9     = 5'd16;
    localparam logic [4:0] CH_A     = 5'd17;
    localparam logic [4:0] CH_G     = 5'd18;
    localparam logic [4:0] CH_M     = 5'd19;
    localparam logic [4:0] CH_U     = 5'd20;
    localparam logic [4:0] CH_V     = 5'd21;
    localparam logic [4:0] CH_W     = 5'd22;
    localparam logic [4:0] CH_Y     = 5'd23;
    localparam logic [4:0] CH_T     = 5'd24;
    localparam logic [4:0] CH_P     = 5'd25;
    localparam logic [4:0] CH_I     = 5'd26;
    localparam logic [4:0] CH_N     = 5'd27;
    localparam logic [4:0] CH_L     = 5'd28;
    localparam logic [4:0] CH_SLASH = 5'd29;
    localparam logic [4:0] CH_H     = 5'd30;

    function automatic logic [4:0] digit_to_char(input logic [3:0] digit);
        begin
            case (digit)
                4'd0: digit_to_char = CH_0;
                4'd1: digit_to_char = CH_1;
                4'd2: digit_to_char = CH_2;
                4'd3: digit_to_char = CH_3;
                4'd4: digit_to_char = CH_4;
                4'd5: digit_to_char = CH_5;
                4'd6: digit_to_char = CH_6;
                4'd7: digit_to_char = CH_7;
                4'd8: digit_to_char = CH_8;
                4'd9: digit_to_char = CH_9;
                default: digit_to_char = CH_0;
            endcase
        end
    endfunction

    function automatic logic [4:0] get_glyph_row(
        input logic [4:0] code,
        input logic [2:0] row
    );
        begin
            case (code)

                CH_S: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b10000;
                        3'd2: get_glyph_row = 5'b11111;
                        3'd3: get_glyph_row = 5'b00001;
                        3'd4: get_glyph_row = 5'b00001;
                        3'd5: get_glyph_row = 5'b10001;
                        3'd6: get_glyph_row = 5'b11111;
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

                CH_U: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b10001;
                        3'd1: get_glyph_row = 5'b10001;
                        3'd2: get_glyph_row = 5'b10001;
                        3'd3: get_glyph_row = 5'b10001;
                        3'd4: get_glyph_row = 5'b10001;
                        3'd5: get_glyph_row = 5'b10001;
                        3'd6: get_glyph_row = 5'b11111;
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

                CH_W: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b10001;
                        3'd1: get_glyph_row = 5'b10001;
                        3'd2: get_glyph_row = 5'b10001;
                        3'd3: get_glyph_row = 5'b10101;
                        3'd4: get_glyph_row = 5'b10101;
                        3'd5: get_glyph_row = 5'b10101;
                        3'd6: get_glyph_row = 5'b01010;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end

                CH_Y: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b10001;
                        3'd1: get_glyph_row = 5'b10001;
                        3'd2: get_glyph_row = 5'b01010;
                        3'd3: get_glyph_row = 5'b00100;
                        3'd4: get_glyph_row = 5'b00100;
                        3'd5: get_glyph_row = 5'b00100;
                        3'd6: get_glyph_row = 5'b00100;
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

                CH_P: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11110;
                        3'd1: get_glyph_row = 5'b10001;
                        3'd2: get_glyph_row = 5'b10001;
                        3'd3: get_glyph_row = 5'b11110;
                        3'd4: get_glyph_row = 5'b10000;
                        3'd5: get_glyph_row = 5'b10000;
                        3'd6: get_glyph_row = 5'b10000;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end

                CH_I: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b11111;
                        3'd1: get_glyph_row = 5'b00100;
                        3'd2: get_glyph_row = 5'b00100;
                        3'd3: get_glyph_row = 5'b00100;
                        3'd4: get_glyph_row = 5'b00100;
                        3'd5: get_glyph_row = 5'b00100;
                        3'd6: get_glyph_row = 5'b11111;
                        default: get_glyph_row = 5'b00000;
                    endcase
                end

                CH_N: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b10001;
                        3'd1: get_glyph_row = 5'b11001;
                        3'd2: get_glyph_row = 5'b10101;
                        3'd3: get_glyph_row = 5'b10011;
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

                CH_SLASH: begin
                    case (row)
                        3'd0: get_glyph_row = 5'b00001;
                        3'd1: get_glyph_row = 5'b00010;
                        3'd2: get_glyph_row = 5'b00100;
                        3'd3: get_glyph_row = 5'b00100;
                        3'd4: get_glyph_row = 5'b01000;
                        3'd5: get_glyph_row = 5'b10000;
                        3'd6: get_glyph_row = 5'b00000;
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

                default: begin
                    get_glyph_row = 5'b00000;
                end
            endcase
        end
    endfunction

    always_comb begin
        // --------------------------------------------------------
        // Default / initialise all signals
        // --------------------------------------------------------
        cell_col       = 5'd0;
        cell_row       = 4'd0;

        head_on        = 1'b0;
        body_on        = 1'b0;
        food_on        = 1'b0;
        hand_on        = 1'b0;

        hand_dx_mag    = 11'd0;
        hand_dy_mag    = 11'd0;

        body1_on       = 1'b0; body2_on       = 1'b0; body3_on       = 1'b0;
        body4_on       = 1'b0; body5_on       = 1'b0; body6_on       = 1'b0;
        body7_on       = 1'b0; body8_on       = 1'b0; body9_on       = 1'b0;
        body10_on      = 1'b0; body11_on      = 1'b0; body12_on      = 1'b0;
        body13_on      = 1'b0; body14_on      = 1'b0; body15_on      = 1'b0;
        body16_on      = 1'b0; body17_on      = 1'b0; body18_on      = 1'b0;
        body19_on      = 1'b0; body20_on      = 1'b0; body21_on      = 1'b0;
        body22_on      = 1'b0; body23_on      = 1'b0; body24_on      = 1'b0;
        body25_on      = 1'b0; body26_on      = 1'b0; body27_on      = 1'b0;

        ai_head_on     = 1'b0;
        ai_body1_on    = 1'b0; ai_body2_on    = 1'b0; ai_body3_on    = 1'b0;
        ai_body4_on    = 1'b0; ai_body5_on    = 1'b0; ai_body6_on    = 1'b0;
        ai_body7_on    = 1'b0; ai_body8_on    = 1'b0; ai_body9_on    = 1'b0;
        ai_body10_on   = 1'b0; ai_body11_on   = 1'b0; ai_body12_on   = 1'b0;
        ai_body13_on   = 1'b0; ai_body14_on   = 1'b0; ai_body15_on   = 1'b0;
        ai_body16_on   = 1'b0; ai_body17_on   = 1'b0; ai_body18_on   = 1'b0;
        ai_body19_on   = 1'b0; ai_body20_on   = 1'b0; ai_body21_on   = 1'b0;
        ai_body22_on   = 1'b0; ai_body23_on   = 1'b0; ai_body24_on   = 1'b0;
        ai_body25_on   = 1'b0; ai_body26_on   = 1'b0; ai_body27_on   = 1'b0;
        ai_body_on     = 1'b0;

        start_shadow_1p_on       = 1'b0; start_outer_1p_on        = 1'b0;
        start_inner_1p_on        = 1'b0; start_highlight_1p_on    = 1'b0;
        start_progress_bg_1p_on  = 1'b0; start_progress_fill_1p_on = 1'b0;
        start_text_1p_on         = 1'b0;

        start_shadow_cpu_on      = 1'b0; start_outer_cpu_on       = 1'b0;
        start_inner_cpu_on       = 1'b0; start_highlight_cpu_on   = 1'b0;
        start_progress_bg_cpu_on = 1'b0; start_progress_fill_cpu_on = 1'b0;
        start_text_cpu_on        = 1'b0;

        start_x              = 10'd0;
        start_y              = 10'd0;
        start_char_index     = 5'd0;
        start_char_px        = 3'd0;
        start_char_py        = 3'd0;
        progress_fill_width  = 10'd0;

        bg_dark_cell   = 1'b0;
        cell_px        = 5'd0;
        cell_py        = 5'd0;

        apple_body_on  = 1'b0;
        apple_leaf_on  = 1'b0;
        apple_stem_on  = 1'b0;

        score_value    = 7'd0;
        score_tens     = 7'd0;
        score_ones     = 7'd0;
        ai_score_tens  = 7'd0;
        ai_score_ones  = 7'd0;
        score_on       = 1'b0;
        cpu_score_on   = 1'b0;

        score_x        = 10'd0;
        score_y        = 10'd0;

        char_index     = 4'd0;
        char_px        = 3'd0;
        char_py        = 3'd0;

        glyph_row_bits = 5'b00000;
        char_code      = CH_BLANK;

        game_over_banner_fill_on    = 1'b0;
        game_over_banner_border_on  = 1'b0;
        game_over_big_text_on       = 1'b0;
        game_over_small_text_on     = 1'b0;
        game_over_small2_text_on    = 1'b0;
        lb_title_on                 = 1'b0;
        lb_row_on                   = 1'b0;

        go_x                = 10'd0;
        go_y                = 10'd0;
        go_big_char_index   = 5'd0;
        go_big_char_px      = 3'd0;
        go_big_char_py      = 3'd0;
        go_small_char_index = 5'd0;
        go_small_char_px    = 3'd0;
        go_small_char_py    = 3'd0;
        go_char_code        = CH_BLANK;

        R_out          = 10'd0;
        G_out          = 10'd0;
        B_out          = 10'd0;

        // --------------------------------------------------------
        // Cell coordinates and pixel offsets
        // --------------------------------------------------------
        cell_col = vga_x[9:5];
        cell_row = vga_y[8:5];
        cell_px  = vga_x[4:0];
        cell_py  = vga_y[4:0];

        bg_dark_cell = cell_col[0] ^ cell_row[0];

        // --------------------------------------------------------
        // Player snake hit detection
        // --------------------------------------------------------
        head_on = (cell_col == snake_head_col) && (cell_row == snake_head_row);

        body1_on  = (snake_len >= 5'd2)  && (cell_col == snake_body1_col)  && (cell_row == snake_body1_row);
        body2_on  = (snake_len >= 5'd3)  && (cell_col == snake_body2_col)  && (cell_row == snake_body2_row);
        body3_on  = (snake_len >= 5'd4)  && (cell_col == snake_body3_col)  && (cell_row == snake_body3_row);
        body4_on  = (snake_len >= 5'd5)  && (cell_col == snake_body4_col)  && (cell_row == snake_body4_row);
        body5_on  = (snake_len >= 5'd6)  && (cell_col == snake_body5_col)  && (cell_row == snake_body5_row);
        body6_on  = (snake_len >= 5'd7)  && (cell_col == snake_body6_col)  && (cell_row == snake_body6_row);
        body7_on  = (snake_len >= 5'd8)  && (cell_col == snake_body7_col)  && (cell_row == snake_body7_row);
        body8_on  = (snake_len >= 5'd9)  && (cell_col == snake_body8_col)  && (cell_row == snake_body8_row);
        body9_on  = (snake_len >= 5'd10) && (cell_col == snake_body9_col)  && (cell_row == snake_body9_row);
        body10_on = (snake_len >= 5'd11) && (cell_col == snake_body10_col) && (cell_row == snake_body10_row);
        body11_on = (snake_len >= 5'd12) && (cell_col == snake_body11_col) && (cell_row == snake_body11_row);
        body12_on = (snake_len >= 5'd13) && (cell_col == snake_body12_col) && (cell_row == snake_body12_row);
        body13_on = (snake_len >= 5'd14) && (cell_col == snake_body13_col) && (cell_row == snake_body13_row);
        body14_on = (snake_len >= 5'd15) && (cell_col == snake_body14_col) && (cell_row == snake_body14_row);
        body15_on = (snake_len >= 5'd16) && (cell_col == snake_body15_col) && (cell_row == snake_body15_row);
        body16_on = (snake_len >= 5'd17) && (cell_col == snake_body16_col) && (cell_row == snake_body16_row);
        body17_on = (snake_len >= 5'd18) && (cell_col == snake_body17_col) && (cell_row == snake_body17_row);
        body18_on = (snake_len >= 5'd19) && (cell_col == snake_body18_col) && (cell_row == snake_body18_row);
        body19_on = (snake_len >= 5'd20) && (cell_col == snake_body19_col) && (cell_row == snake_body19_row);
        body20_on = (snake_len >= 5'd21) && (cell_col == snake_body20_col) && (cell_row == snake_body20_row);
        body21_on = (snake_len >= 5'd22) && (cell_col == snake_body21_col) && (cell_row == snake_body21_row);
        body22_on = (snake_len >= 5'd23) && (cell_col == snake_body22_col) && (cell_row == snake_body22_row);
        body23_on = (snake_len >= 5'd24) && (cell_col == snake_body23_col) && (cell_row == snake_body23_row);
        body24_on = (snake_len >= 5'd25) && (cell_col == snake_body24_col) && (cell_row == snake_body24_row);
        body25_on = (snake_len >= 5'd26) && (cell_col == snake_body25_col) && (cell_row == snake_body25_row);
        body26_on = (snake_len >= 5'd27) && (cell_col == snake_body26_col) && (cell_row == snake_body26_row);
        body27_on = (snake_len >= 5'd28) && (cell_col == snake_body27_col) && (cell_row == snake_body27_row);

        body_on = body1_on  || body2_on  || body3_on  || body4_on  || body5_on  ||
                  body6_on  || body7_on  || body8_on  || body9_on  || body10_on ||
                  body11_on || body12_on || body13_on || body14_on || body15_on ||
                  body16_on || body17_on || body18_on || body19_on || body20_on ||
                  body21_on || body22_on || body23_on || body24_on || body25_on ||
                  body26_on || body27_on;

        // --------------------------------------------------------
        // AI snake hit detection
        // --------------------------------------------------------
        ai_head_on    = (cell_col == ai_head_col) && (cell_row == ai_head_row);

        ai_body1_on   = (ai_len >= 5'd2)  && (cell_col == ai_body1_col)  && (cell_row == ai_body1_row);
        ai_body2_on   = (ai_len >= 5'd3)  && (cell_col == ai_body2_col)  && (cell_row == ai_body2_row);
        ai_body3_on   = (ai_len >= 5'd4)  && (cell_col == ai_body3_col)  && (cell_row == ai_body3_row);
        ai_body4_on   = (ai_len >= 5'd5)  && (cell_col == ai_body4_col)  && (cell_row == ai_body4_row);
        ai_body5_on   = (ai_len >= 5'd6)  && (cell_col == ai_body5_col)  && (cell_row == ai_body5_row);
        ai_body6_on   = (ai_len >= 5'd7)  && (cell_col == ai_body6_col)  && (cell_row == ai_body6_row);
        ai_body7_on   = (ai_len >= 5'd8)  && (cell_col == ai_body7_col)  && (cell_row == ai_body7_row);
        ai_body8_on   = (ai_len >= 5'd9)  && (cell_col == ai_body8_col)  && (cell_row == ai_body8_row);
        ai_body9_on   = (ai_len >= 5'd10) && (cell_col == ai_body9_col)  && (cell_row == ai_body9_row);
        ai_body10_on  = (ai_len >= 5'd11) && (cell_col == ai_body10_col) && (cell_row == ai_body10_row);
        ai_body11_on  = (ai_len >= 5'd12) && (cell_col == ai_body11_col) && (cell_row == ai_body11_row);
        ai_body12_on  = (ai_len >= 5'd13) && (cell_col == ai_body12_col) && (cell_row == ai_body12_row);
        ai_body13_on  = (ai_len >= 5'd14) && (cell_col == ai_body13_col) && (cell_row == ai_body13_row);
        ai_body14_on  = (ai_len >= 5'd15) && (cell_col == ai_body14_col) && (cell_row == ai_body14_row);
        ai_body15_on  = (ai_len >= 5'd16) && (cell_col == ai_body15_col) && (cell_row == ai_body15_row);
        ai_body16_on  = (ai_len >= 5'd17) && (cell_col == ai_body16_col) && (cell_row == ai_body16_row);
        ai_body17_on  = (ai_len >= 5'd18) && (cell_col == ai_body17_col) && (cell_row == ai_body17_row);
        ai_body18_on  = (ai_len >= 5'd19) && (cell_col == ai_body18_col) && (cell_row == ai_body18_row);
        ai_body19_on  = (ai_len >= 5'd20) && (cell_col == ai_body19_col) && (cell_row == ai_body19_row);
        ai_body20_on  = (ai_len >= 5'd21) && (cell_col == ai_body20_col) && (cell_row == ai_body20_row);
        ai_body21_on  = (ai_len >= 5'd22) && (cell_col == ai_body21_col) && (cell_row == ai_body21_row);
        ai_body22_on  = (ai_len >= 5'd23) && (cell_col == ai_body22_col) && (cell_row == ai_body22_row);
        ai_body23_on  = (ai_len >= 5'd24) && (cell_col == ai_body23_col) && (cell_row == ai_body23_row);
        ai_body24_on  = (ai_len >= 5'd25) && (cell_col == ai_body24_col) && (cell_row == ai_body24_row);
        ai_body25_on  = (ai_len >= 5'd26) && (cell_col == ai_body25_col) && (cell_row == ai_body25_row);
        ai_body26_on  = (ai_len >= 5'd27) && (cell_col == ai_body26_col) && (cell_row == ai_body26_row);
        ai_body27_on  = (ai_len >= 5'd28) && (cell_col == ai_body27_col) && (cell_row == ai_body27_row);

        ai_body_on = ai_body1_on  || ai_body2_on  || ai_body3_on  || ai_body4_on  || ai_body5_on  ||
                     ai_body6_on  || ai_body7_on  || ai_body8_on  || ai_body9_on  || ai_body10_on ||
                     ai_body11_on || ai_body12_on || ai_body13_on || ai_body14_on || ai_body15_on ||
                     ai_body16_on || ai_body17_on || ai_body18_on || ai_body19_on || ai_body20_on ||
                     ai_body21_on || ai_body22_on || ai_body23_on || ai_body24_on || ai_body25_on ||
                     ai_body26_on || ai_body27_on;

        // --------------------------------------------------------
        // Food hit
        // --------------------------------------------------------
        food_on = (cell_col == food_col) && (cell_row == food_row);

        // --------------------------------------------------------
        // Apple sprite
        // --------------------------------------------------------
        if (food_on) begin
            if ((cell_px >= 5'd14) && (cell_px <= 5'd16) &&
                (cell_py >= 5'd5)  && (cell_py <= 5'd9))
                apple_stem_on = 1'b1;

            if ((cell_px >= 5'd17) && (cell_px <= 5'd22) &&
                (cell_py >= 5'd6)  && (cell_py <= 5'd10) &&
                ((cell_px - 5'd17) + (cell_py - 5'd6) <= 5'd7))
                apple_leaf_on = 1'b1;

            case (cell_py)
                5'd9:  if ((cell_px >= 5'd13) && (cell_px <= 5'd18)) apple_body_on = 1'b1;
                5'd10: if ((cell_px >= 5'd10) && (cell_px <= 5'd21)) apple_body_on = 1'b1;
                5'd11: if ((cell_px >= 5'd8)  && (cell_px <= 5'd23)) apple_body_on = 1'b1;
                5'd12: if ((cell_px >= 5'd7)  && (cell_px <= 5'd24)) apple_body_on = 1'b1;
                5'd13: if ((cell_px >= 5'd6)  && (cell_px <= 5'd25)) apple_body_on = 1'b1;
                5'd14: if ((cell_px >= 5'd6)  && (cell_px <= 5'd25)) apple_body_on = 1'b1;
                5'd15: if ((cell_px >= 5'd6)  && (cell_px <= 5'd25)) apple_body_on = 1'b1;
                5'd16: if ((cell_px >= 5'd6)  && (cell_px <= 5'd25)) apple_body_on = 1'b1;
                5'd17: if ((cell_px >= 5'd7)  && (cell_px <= 5'd24)) apple_body_on = 1'b1;
                5'd18: if ((cell_px >= 5'd8)  && (cell_px <= 5'd23)) apple_body_on = 1'b1;
                5'd19: if ((cell_px >= 5'd9)  && (cell_px <= 5'd22)) apple_body_on = 1'b1;
                5'd20: if ((cell_px >= 5'd11) && (cell_px <= 5'd20)) apple_body_on = 1'b1;
                5'd21: if ((cell_px >= 5'd13) && (cell_px <= 5'd18)) apple_body_on = 1'b1;
                default: apple_body_on = 1'b0;
            endcase

            if ((cell_px >= 5'd14) && (cell_px <= 5'd17) &&
                (cell_py >= 5'd9)  && (cell_py <= 5'd11))
                apple_body_on = 1'b0;
        end

        // --------------------------------------------------------
        // Hand cursor
        // --------------------------------------------------------
        if (vga_x >= coord_x)
            hand_dx_mag = {1'b0, (vga_x - coord_x)};
        else
            hand_dx_mag = {1'b0, (coord_x - vga_x)};

        if (vga_y >= coord_y)
            hand_dy_mag = {1'b0, (vga_y - coord_y)};
        else
            hand_dy_mag = {1'b0, (coord_y - vga_y)};

        hand_on = detected &&
                  (hand_dx_mag <= 11'd4) &&
                  (hand_dy_mag <= 11'd4);

        // --------------------------------------------------------
        // Mode-select start screen (two boxes)
        // --------------------------------------------------------
        if (!game_running && !game_over_active) begin

            // ---- LEFT BOX: 1P ----
            // Shadow
            if ((vga_x >= 10'd134) && (vga_x < 10'd274) &&
                (vga_y >= 10'd196) && (vga_y < 10'd260))
                start_shadow_1p_on = 1'b1;
            // Outer border
            if ((vga_x >= 10'd130) && (vga_x < 10'd270) &&
                (vga_y >= 10'd192) && (vga_y < 10'd256))
                start_outer_1p_on = 1'b1;
            // Inner fill
            if ((vga_x >= 10'd134) && (vga_x < 10'd266) &&
                (vga_y >= 10'd196) && (vga_y < 10'd252))
                start_inner_1p_on = 1'b1;
            // Highlight strip
            if ((vga_x >= 10'd138) && (vga_x < 10'd262) &&
                (vga_y >= 10'd200) && (vga_y < 10'd214))
                start_highlight_1p_on = 1'b1;
            // Progress bar background
            if ((vga_x >= 10'd138) && (vga_x < 10'd262) &&
                (vga_y >= 10'd236) && (vga_y < 10'd246))
                start_progress_bg_1p_on = 1'b1;

            if (hold_mode == 1'b0) begin
                progress_fill_width = (start_hold_count * 10'd124) / START_HOLD_FRAMES;
                if ((vga_x >= 10'd138) && (vga_x < (10'd138 + progress_fill_width)) &&
                    (vga_y >= 10'd236) && (vga_y < 10'd246))
                    start_progress_fill_1p_on = 1'b1;
            end

            // "1P" text centered in left box (x 190-202, y 218-226)
            if ((vga_x >= 10'd190) && (vga_x < 10'd202) &&
                (vga_y >= 10'd218) && (vga_y < 10'd226)) begin
                start_x          = vga_x - 10'd190;
                start_y          = vga_y - 10'd218;
                start_char_index = start_x / 10'd6;
                start_char_px    = start_x % 10'd6;
                start_char_py    = start_y[2:0];

                case (start_char_index)
                    5'd0: char_code = CH_1;
                    5'd1: char_code = CH_P;
                    default: char_code = CH_BLANK;
                endcase

                if ((start_char_px < 3'd5) && (start_char_py < 3'd7)) begin
                    glyph_row_bits = get_glyph_row(char_code, start_char_py);
                    case (start_char_px)
                        3'd0: start_text_1p_on = glyph_row_bits[4];
                        3'd1: start_text_1p_on = glyph_row_bits[3];
                        3'd2: start_text_1p_on = glyph_row_bits[2];
                        3'd3: start_text_1p_on = glyph_row_bits[1];
                        3'd4: start_text_1p_on = glyph_row_bits[0];
                        default: start_text_1p_on = 1'b0;
                    endcase
                end
            end

            // ---- RIGHT BOX: CPU ----
            // Shadow
            if ((vga_x >= 10'd374) && (vga_x < 10'd514) &&
                (vga_y >= 10'd196) && (vga_y < 10'd260))
                start_shadow_cpu_on = 1'b1;
            // Outer border
            if ((vga_x >= 10'd370) && (vga_x < 10'd510) &&
                (vga_y >= 10'd192) && (vga_y < 10'd256))
                start_outer_cpu_on = 1'b1;
            // Inner fill
            if ((vga_x >= 10'd374) && (vga_x < 10'd506) &&
                (vga_y >= 10'd196) && (vga_y < 10'd252))
                start_inner_cpu_on = 1'b1;
            // Highlight strip
            if ((vga_x >= 10'd378) && (vga_x < 10'd502) &&
                (vga_y >= 10'd200) && (vga_y < 10'd214))
                start_highlight_cpu_on = 1'b1;
            // Progress bar background
            if ((vga_x >= 10'd378) && (vga_x < 10'd502) &&
                (vga_y >= 10'd236) && (vga_y < 10'd246))
                start_progress_bg_cpu_on = 1'b1;

            if (hold_mode == 1'b1) begin
                progress_fill_width = (start_hold_count * 10'd124) / START_HOLD_FRAMES;
                if ((vga_x >= 10'd378) && (vga_x < (10'd378 + progress_fill_width)) &&
                    (vga_y >= 10'd236) && (vga_y < 10'd246))
                    start_progress_fill_cpu_on = 1'b1;
            end

            // "CPU" text centered in right box (x 408-426, y 218-226)
            if ((vga_x >= 10'd408) && (vga_x < 10'd426) &&
                (vga_y >= 10'd218) && (vga_y < 10'd226)) begin
                start_x          = vga_x - 10'd408;
                start_y          = vga_y - 10'd218;
                start_char_index = start_x / 10'd6;
                start_char_px    = start_x % 10'd6;
                start_char_py    = start_y[2:0];

                case (start_char_index)
                    5'd0: char_code = CH_C;
                    5'd1: char_code = CH_P;
                    5'd2: char_code = CH_U;
                    default: char_code = CH_BLANK;
                endcase

                if ((start_char_px < 3'd5) && (start_char_py < 3'd7)) begin
                    glyph_row_bits = get_glyph_row(char_code, start_char_py);
                    case (start_char_px)
                        3'd0: start_text_cpu_on = glyph_row_bits[4];
                        3'd1: start_text_cpu_on = glyph_row_bits[3];
                        3'd2: start_text_cpu_on = glyph_row_bits[2];
                        3'd3: start_text_cpu_on = glyph_row_bits[1];
                        3'd4: start_text_cpu_on = glyph_row_bits[0];
                        default: start_text_cpu_on = 1'b0;
                    endcase
                end
            end
        end

        // --------------------------------------------------------
        // Score overlay line 1: "SCORE: XX"  (vga_y 8-16)
        // --------------------------------------------------------
        score_value   = score;
        score_tens    = score_value / 7'd10;
        score_ones    = score_value % 7'd10;
        ai_score_tens = ai_score / 7'd10;
        ai_score_ones = ai_score % 7'd10;

        if (!game_over_active) begin
            if ((vga_x >= 10'd8) && (vga_x < 10'd62) &&
                (vga_y >= 10'd8) && (vga_y < 10'd16)) begin

                score_x    = vga_x - 10'd8;
                score_y    = vga_y - 10'd8;
                char_index = score_x / 10'd6;
                char_px    = score_x % 10'd6;
                char_py    = score_y[2:0];

                if (ai_mode) begin
                    // "YOU: X/5"
                    case (char_index)
                        4'd0: char_code = CH_Y;
                        4'd1: char_code = CH_O;
                        4'd2: char_code = CH_U;
                        4'd3: char_code = CH_COLON;
                        4'd4: char_code = CH_BLANK;
                        4'd5: char_code = digit_to_char(score_ones[3:0]);
                        4'd6: char_code = CH_SLASH;
                        4'd7: char_code = CH_5;
                        default: char_code = CH_BLANK;
                    endcase
                end
                else begin
                    // "SCORE: XX"
                    case (char_index)
                        4'd0: char_code = CH_S;
                        4'd1: char_code = CH_C;
                        4'd2: char_code = CH_O;
                        4'd3: char_code = CH_R;
                        4'd4: char_code = CH_E;
                        4'd5: char_code = CH_COLON;
                        4'd6: char_code = CH_BLANK;
                        4'd7: begin
                            if (score_tens == 7'd0)
                                char_code = CH_BLANK;
                            else
                                char_code = digit_to_char(score_tens[3:0]);
                        end
                        4'd8: char_code = digit_to_char(score_ones[3:0]);
                        default: char_code = CH_BLANK;
                    endcase
                end

                if ((char_px < 3'd5) && (char_py < 3'd7)) begin
                    glyph_row_bits = get_glyph_row(char_code, char_py);
                    case (char_px)
                        3'd0: score_on = glyph_row_bits[4];
                        3'd1: score_on = glyph_row_bits[3];
                        3'd2: score_on = glyph_row_bits[2];
                        3'd3: score_on = glyph_row_bits[1];
                        3'd4: score_on = glyph_row_bits[0];
                        default: score_on = 1'b0;
                    endcase
                end
            end

            // Score overlay line 2: "CPU: XX"  (vga_y 20-28, only in ai_mode)
            if (ai_mode) begin
                if ((vga_x >= 10'd8) && (vga_x < 10'd50) &&
                    (vga_y >= 10'd20) && (vga_y < 10'd28)) begin

                    score_x    = vga_x - 10'd8;
                    score_y    = vga_y - 10'd20;
                    char_index = score_x / 10'd6;
                    char_px    = score_x % 10'd6;
                    char_py    = score_y[2:0];

                    case (char_index)
                        4'd0: char_code = CH_C;
                        4'd1: char_code = CH_P;
                        4'd2: char_code = CH_U;
                        4'd3: char_code = CH_COLON;
                        4'd4: char_code = CH_BLANK;
                        4'd5: char_code = digit_to_char(ai_score_ones[3:0]);
                        4'd6: char_code = CH_SLASH;
                        4'd7: char_code = CH_5;
                        default: char_code = CH_BLANK;
                    endcase

                    if ((char_px < 3'd5) && (char_py < 3'd7)) begin
                        glyph_row_bits = get_glyph_row(char_code, char_py);
                        case (char_px)
                            3'd0: cpu_score_on = glyph_row_bits[4];
                            3'd1: cpu_score_on = glyph_row_bits[3];
                            3'd2: cpu_score_on = glyph_row_bits[2];
                            3'd3: cpu_score_on = glyph_row_bits[1];
                            3'd4: cpu_score_on = glyph_row_bits[0];
                            default: cpu_score_on = 1'b0;
                        endcase
                    end
                end
            end
        end

        // --------------------------------------------------------
        // Game-over banner
        // --------------------------------------------------------
        if (game_over_active && game_over_flash_on) begin
            if ((vga_x >= 10'd100) && (vga_x < 10'd540) &&
                (vga_y >= 10'd160) && (vga_y < 10'd395)) begin
                game_over_banner_fill_on = 1'b1;

                if ((vga_x < 10'd104) || (vga_x >= 10'd536) ||
                    (vga_y < 10'd164) || (vga_y >= 10'd391))
                    game_over_banner_border_on = 1'b1;
            end

            // Big text: "YOU WIN" / "YOU LOSE" (ai_mode) or "GAME OVER" (solo)
            if ((vga_x >= 10'd185) && (vga_x < 10'd455) &&
                (vga_y >= 10'd178) && (vga_y < 10'd213)) begin

                go_x = vga_x - 10'd185;
                go_y = vga_y - 10'd178;

                go_big_char_index = go_x / 10'd30;
                go_big_char_px    = (go_x % 10'd30) / 10'd5;
                go_big_char_py    = go_y / 10'd5;

                if (ai_mode) begin
                    if (player_won) begin
                        // "YOU WIN" — 7 chars, padded with blanks
                        case (go_big_char_index)
                            5'd0: go_char_code = CH_Y;
                            5'd1: go_char_code = CH_O;
                            5'd2: go_char_code = CH_U;
                            5'd3: go_char_code = CH_BLANK;
                            5'd4: go_char_code = CH_W;
                            5'd5: go_char_code = CH_I;
                            5'd6: go_char_code = CH_N;
                            default: go_char_code = CH_BLANK;
                        endcase
                    end
                    else begin
                        // "YOU LOSE" — 8 chars
                        case (go_big_char_index)
                            5'd0: go_char_code = CH_Y;
                            5'd1: go_char_code = CH_O;
                            5'd2: go_char_code = CH_U;
                            5'd3: go_char_code = CH_BLANK;
                            5'd4: go_char_code = CH_L;
                            5'd5: go_char_code = CH_O;
                            5'd6: go_char_code = CH_S;
                            5'd7: go_char_code = CH_E;
                            default: go_char_code = CH_BLANK;
                        endcase
                    end
                end
                else begin
                    // Solo mode: "GAME OVER"
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
                end

                if ((go_big_char_px < 3'd5) && (go_big_char_py < 3'd7)) begin
                    glyph_row_bits = get_glyph_row(go_char_code, go_big_char_py);
                    case (go_big_char_px)
                        3'd0: game_over_big_text_on = glyph_row_bits[4];
                        3'd1: game_over_big_text_on = glyph_row_bits[3];
                        3'd2: game_over_big_text_on = glyph_row_bits[2];
                        3'd3: game_over_big_text_on = glyph_row_bits[1];
                        3'd4: game_over_big_text_on = glyph_row_bits[0];
                        default: game_over_big_text_on = 1'b0;
                    endcase
                end
            end

            // Small text line 1: "YOU: XX"  (vga_y 245-253)
            if ((vga_x >= 10'd206) && (vga_x < 10'd248) &&
                (vga_y >= 10'd245) && (vga_y < 10'd253)) begin

                go_x = vga_x - 10'd206;
                go_y = vga_y - 10'd245;

                go_small_char_index = go_x / 10'd6;
                go_small_char_px    = go_x % 10'd6;
                go_small_char_py    = go_y[2:0];

                case (go_small_char_index)
                    5'd0: go_char_code = CH_Y;
                    5'd1: go_char_code = CH_O;
                    5'd2: go_char_code = CH_U;
                    5'd3: go_char_code = CH_COLON;
                    5'd4: go_char_code = CH_BLANK;
                    5'd5: begin
                        if (game_over_score >= 7'd10)
                            go_char_code = digit_to_char(game_over_score / 7'd10);
                        else
                            go_char_code = CH_BLANK;
                    end
                    5'd6: go_char_code = digit_to_char(game_over_score % 7'd10);
                    default: go_char_code = CH_BLANK;
                endcase

                if ((go_small_char_px < 3'd5) && (go_small_char_py < 3'd7)) begin
                    glyph_row_bits = get_glyph_row(go_char_code, go_small_char_py);
                    case (go_small_char_px)
                        3'd0: game_over_small_text_on = glyph_row_bits[4];
                        3'd1: game_over_small_text_on = glyph_row_bits[3];
                        3'd2: game_over_small_text_on = glyph_row_bits[2];
                        3'd3: game_over_small_text_on = glyph_row_bits[1];
                        3'd4: game_over_small_text_on = glyph_row_bits[0];
                        default: game_over_small_text_on = 1'b0;
                    endcase
                end
            end

            // Small text line 2: "CPU: XX"  (vga_y 260-268, only when ai_mode)
            if (ai_mode) begin
                if ((vga_x >= 10'd206) && (vga_x < 10'd248) &&
                    (vga_y >= 10'd260) && (vga_y < 10'd268)) begin

                    go_x = vga_x - 10'd206;
                    go_y = vga_y - 10'd260;

                    go_small_char_index = go_x / 10'd6;
                    go_small_char_px    = go_x % 10'd6;
                    go_small_char_py    = go_y[2:0];

                    case (go_small_char_index)
                        5'd0: go_char_code = CH_C;
                        5'd1: go_char_code = CH_P;
                        5'd2: go_char_code = CH_U;
                        5'd3: go_char_code = CH_COLON;
                        5'd4: go_char_code = CH_BLANK;
                        5'd5: begin
                            if (game_over_ai_score >= 7'd10)
                                go_char_code = digit_to_char(game_over_ai_score / 7'd10);
                            else
                                go_char_code = CH_BLANK;
                        end
                        5'd6: go_char_code = digit_to_char(game_over_ai_score % 7'd10);
                        default: go_char_code = CH_BLANK;
                    endcase

                    if ((go_small_char_px < 3'd5) && (go_small_char_py < 3'd7)) begin
                        glyph_row_bits = get_glyph_row(go_char_code, go_small_char_py);
                        case (go_small_char_px)
                            3'd0: game_over_small2_text_on = glyph_row_bits[4];
                            3'd1: game_over_small2_text_on = glyph_row_bits[3];
                            3'd2: game_over_small2_text_on = glyph_row_bits[2];
                            3'd3: game_over_small2_text_on = glyph_row_bits[1];
                            3'd4: game_over_small2_text_on = glyph_row_bits[0];
                            default: game_over_small2_text_on = 1'b0;
                        endcase
                    end
                end
            end
        end


        // --------------------------------------------------------
        // Leaderboard (shown during game-over flash)
        // --------------------------------------------------------
        if (game_over_active && game_over_flash_on) begin

            // "HIGH SCORES" title — 11 chars x 6px = 66px, centered at x=320 => x 287-353
            // vga_y 278-286
            if ((vga_x >= 10'd287) && (vga_x < 10'd353) &&
                (vga_y >= 10'd278) && (vga_y < 10'd286)) begin

                go_x = vga_x - 10'd287;
                go_y = vga_y - 10'd278;
                go_small_char_index = go_x / 10'd6;
                go_small_char_px    = go_x % 10'd6;
                go_small_char_py    = go_y[2:0];

                case (go_small_char_index)
                    5'd0:  go_char_code = CH_H;
                    5'd1:  go_char_code = CH_I;
                    5'd2:  go_char_code = CH_G;
                    5'd3:  go_char_code = CH_H;
                    5'd4:  go_char_code = CH_BLANK;
                    5'd5:  go_char_code = CH_S;
                    5'd6:  go_char_code = CH_C;
                    5'd7:  go_char_code = CH_O;
                    5'd8:  go_char_code = CH_R;
                    5'd9:  go_char_code = CH_E;
                    5'd10: go_char_code = CH_S;
                    default: go_char_code = CH_BLANK;
                endcase

                if ((go_small_char_px < 3'd5) && (go_small_char_py < 3'd7)) begin
                    glyph_row_bits = get_glyph_row(go_char_code, go_small_char_py);
                    case (go_small_char_px)
                        3'd0: lb_title_on = glyph_row_bits[4];
                        3'd1: lb_title_on = glyph_row_bits[3];
                        3'd2: lb_title_on = glyph_row_bits[2];
                        3'd3: lb_title_on = glyph_row_bits[1];
                        3'd4: lb_title_on = glyph_row_bits[0];
                        default: lb_title_on = 1'b0;
                    endcase
                end
            end

            // Rows 1-5 — "N: XX", 5 chars x 6px = 30px, centered => x 305-335
            // vga_y 292-381, 18px per row (8px glyph + 10px gap)
            if ((vga_x >= 10'd305) && (vga_x < 10'd335) &&
                (vga_y >= 10'd292) && (vga_y < 10'd382)) begin

                go_x = vga_x - 10'd305;
                go_y = vga_y - 10'd292;

                go_big_char_index   = go_y / 10'd18;     // row 0-4
                go_small_char_index = go_x / 10'd6;      // char col 0-4
                go_small_char_px    = go_x % 10'd6;
                go_small_char_py    = (go_y % 10'd18)[2:0];

                if ((go_y % 10'd18) < 10'd8) begin
                    case (go_big_char_index)
                        5'd0: case (go_small_char_index)
                                  5'd0: go_char_code = CH_1;
                                  5'd1: go_char_code = CH_COLON;
                                  5'd2: go_char_code = CH_BLANK;
                                  5'd3: go_char_code = (lb0 >= 7'd10) ? digit_to_char(lb0 / 7'd10) : CH_BLANK;
                                  5'd4: go_char_code = digit_to_char(lb0 % 7'd10);
                                  default: go_char_code = CH_BLANK;
                              endcase
                        5'd1: case (go_small_char_index)
                                  5'd0: go_char_code = CH_2;
                                  5'd1: go_char_code = CH_COLON;
                                  5'd2: go_char_code = CH_BLANK;
                                  5'd3: go_char_code = (lb1 >= 7'd10) ? digit_to_char(lb1 / 7'd10) : CH_BLANK;
                                  5'd4: go_char_code = digit_to_char(lb1 % 7'd10);
                                  default: go_char_code = CH_BLANK;
                              endcase
                        5'd2: case (go_small_char_index)
                                  5'd0: go_char_code = CH_3;
                                  5'd1: go_char_code = CH_COLON;
                                  5'd2: go_char_code = CH_BLANK;
                                  5'd3: go_char_code = (lb2 >= 7'd10) ? digit_to_char(lb2 / 7'd10) : CH_BLANK;
                                  5'd4: go_char_code = digit_to_char(lb2 % 7'd10);
                                  default: go_char_code = CH_BLANK;
                              endcase
                        5'd3: case (go_small_char_index)
                                  5'd0: go_char_code = CH_4;
                                  5'd1: go_char_code = CH_COLON;
                                  5'd2: go_char_code = CH_BLANK;
                                  5'd3: go_char_code = (lb3 >= 7'd10) ? digit_to_char(lb3 / 7'd10) : CH_BLANK;
                                  5'd4: go_char_code = digit_to_char(lb3 % 7'd10);
                                  default: go_char_code = CH_BLANK;
                              endcase
                        5'd4: case (go_small_char_index)
                                  5'd0: go_char_code = CH_5;
                                  5'd1: go_char_code = CH_COLON;
                                  5'd2: go_char_code = CH_BLANK;
                                  5'd3: go_char_code = (lb4 >= 7'd10) ? digit_to_char(lb4 / 7'd10) : CH_BLANK;
                                  5'd4: go_char_code = digit_to_char(lb4 % 7'd10);
                                  default: go_char_code = CH_BLANK;
                              endcase
                        default: go_char_code = CH_BLANK;
                    endcase

                    if ((go_small_char_px < 3'd5) && (go_small_char_py < 3'd7)) begin
                        glyph_row_bits = get_glyph_row(go_char_code, go_small_char_py);
                        case (go_small_char_px)
                            3'd0: lb_row_on = glyph_row_bits[4];
                            3'd1: lb_row_on = glyph_row_bits[3];
                            3'd2: lb_row_on = glyph_row_bits[2];
                            3'd3: lb_row_on = glyph_row_bits[1];
                            3'd4: lb_row_on = glyph_row_bits[0];
                            default: lb_row_on = 1'b0;
                        endcase
                    end
                end
            end
        end

        // --------------------------------------------------------
        // Color priority chain
        // --------------------------------------------------------
        if (game_over_big_text_on) begin
            R_out = 10'd1023; G_out = 10'd80;   B_out = 10'd80;
        end
        else if (game_over_small_text_on || game_over_small2_text_on || lb_title_on || lb_row_on) begin
            R_out = 10'd1023; G_out = 10'd1023; B_out = 10'd1023;
        end
        else if (game_over_banner_border_on) begin
            R_out = 10'd900;  G_out = 10'd0;    B_out = 10'd0;
        end
        else if (game_over_banner_fill_on) begin
            R_out = 10'd260;  G_out = 10'd0;    B_out = 10'd0;
        end
        else if (score_on || cpu_score_on) begin
            R_out = 10'd1023; G_out = 10'd1023; B_out = 10'd1023;
        end
        else if (hand_on) begin
            R_out = 10'd0;    G_out = 10'd700;  B_out = 10'd1023;
        end
        else if (start_text_1p_on || start_text_cpu_on) begin
            R_out = 10'd80;   G_out = 10'd40;   B_out = 10'd0;
        end
        else if (start_progress_fill_1p_on || start_progress_fill_cpu_on) begin
            R_out = 10'd0;    G_out = 10'd900;  B_out = 10'd220;
        end
        else if (start_progress_bg_1p_on || start_progress_bg_cpu_on) begin
            R_out = 10'd180;  G_out = 10'd140;  B_out = 10'd0;
        end
        else if (start_highlight_1p_on || start_highlight_cpu_on) begin
            R_out = 10'd1023; G_out = 10'd1023; B_out = 10'd520;
        end
        else if (start_inner_1p_on || start_inner_cpu_on) begin
            R_out = 10'd1023; G_out = 10'd900;  B_out = 10'd140;
        end
        else if (start_outer_1p_on || start_outer_cpu_on) begin
            R_out = 10'd1023; G_out = 10'd760;  B_out = 10'd0;
        end
        else if (start_shadow_1p_on || start_shadow_cpu_on) begin
            R_out = 10'd140;  G_out = 10'd90;   B_out = 10'd0;
        end
        else if (head_on && game_running) begin
            R_out = 10'd0;    G_out = 10'd1023; B_out = 10'd0;
        end
        else if (body_on && game_running) begin
            R_out = 10'd1023; G_out = 10'd1023; B_out = 10'd1023;
        end
        else if (ai_head_on && game_running && ai_alive) begin
            R_out = 10'd1023; G_out = 10'd500;  B_out = 10'd0;
        end
        else if (ai_body_on && game_running && ai_alive) begin
            R_out = 10'd800;  G_out = 10'd350;  B_out = 10'd0;
        end
        else if (apple_stem_on && game_running) begin
            R_out = 10'd420;  G_out = 10'd220;  B_out = 10'd60;
        end
        else if (apple_leaf_on && game_running) begin
            R_out = 10'd80;   G_out = 10'd760;  B_out = 10'd120;
        end
        else if (apple_body_on && game_running) begin
            if ((cell_px >= 5'd10) && (cell_px <= 5'd13) &&
                (cell_py >= 5'd12) && (cell_py <= 5'd15)) begin
                R_out = 10'd1023; G_out = 10'd260; B_out = 10'd260;
            end
            else begin
                R_out = 10'd920;  G_out = 10'd0;   B_out = 10'd0;
            end
        end
        else begin
            if (bg_dark_cell) begin
                R_out = 10'd70;  G_out = 10'd360; B_out = 10'd70;
            end
            else begin
                R_out = 10'd110; G_out = 10'd470; B_out = 10'd110;
            end
        end
    end

endmodule