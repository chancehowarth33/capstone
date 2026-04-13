module snake_renderer (
    input  logic [9:0] vga_x,
    input  logic [9:0] vga_y,

    input  logic [9:0] coord_x,
    input  logic [9:0] coord_y,
    input  logic       detected,

    // Head
    input  logic [4:0] snake_head_col,
    input  logic [3:0] snake_head_row,

    // Body segments 1..11
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

    // Total snake length including head
    input  logic [3:0] snake_len,

    // Food
    input  logic [4:0] food_col,
    input  logic [3:0] food_row,

    // Start screen support
    input  logic       game_running,

    // Game-over screen support
    input  logic       game_over_active,
    input  logic       game_over_flash_on,
    input  logic [3:0] game_over_score,

    output logic [9:0] R_out,
    output logic [9:0] G_out,
    output logic [9:0] B_out
);

    logic [4:0] cell_col;
    logic [3:0] cell_row;

    logic head_on;
    logic body_on;
    logic food_on;
    logic hand_on;
    logic start_box_on;

    logic [10:0] hand_dx_mag;
    logic [10:0] hand_dy_mag;
    logic [10:0] box_dx_mag;
    logic [10:0] box_dy_mag;

    logic body1_on, body2_on, body3_on, body4_on, body5_on, body6_on;
    logic body7_on, body8_on, body9_on, body10_on, body11_on;

    // ------------------------------------------------------------
    // Score / text overlay signals
    // ------------------------------------------------------------

    // Score is body length, not total length.
    logic [3:0] score_value;
    logic [3:0] score_tens;
    logic [3:0] score_ones;

    // Score text enable for the current pixel
    logic score_on;

    // Pixel position within the score area
    logic [9:0] score_x;
    logic [9:0] score_y;

    // Which character cell and which pixel inside the character
    logic [3:0] char_index;
    logic [2:0] char_px;
    logic [2:0] char_py;

    // Simple 5x7 font bitmap for current character row
    logic [4:0] glyph_row_bits;

    // Current character code
    logic [4:0] char_code;

    // ------------------------------------------------------------
    // Game-over banner signals
    // ------------------------------------------------------------
    logic game_over_banner_fill_on;
    logic game_over_banner_border_on;
    logic game_over_big_text_on;
    logic game_over_small_text_on;

    logic [9:0] go_x;
    logic [9:0] go_y;

    logic [4:0] go_big_char_index;
    logic [2:0] go_big_char_px;
    logic [2:0] go_big_char_py;

    logic [4:0] go_small_char_index;
    logic [2:0] go_small_char_px;
    logic [2:0] go_small_char_py;

    logic [4:0] go_char_code;

    // Character codes used by the score display and game-over text
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

    // ------------------------------------------------------------
    // Helper function: map a digit value 0..9 to a character code
    // ------------------------------------------------------------
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

    // ------------------------------------------------------------
    // Helper function: return one 5-bit row of a 5x7 glyph.
    // Bit 4 is leftmost pixel, bit 0 is rightmost pixel.
    // ------------------------------------------------------------
    function automatic logic [4:0] get_glyph_row(
        input logic [4:0] code,
        input logic [2:0] row
    );
        begin
            case (code)

                // S
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

                // C
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

                // O
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

                // R
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

                // E
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

                // :
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

                // 0
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

                // 1
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

                // 2
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

                // 3
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

                // 4
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

                // 5
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

                // 6
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

                // 7
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

                // 8
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

                // 9
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

                // A
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

                // G
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

                // M
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

                // U
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

                // V
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

                // W
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

                // Y
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

                default: begin
                    get_glyph_row = 5'b00000;
                end
            endcase
        end
    endfunction

    always_comb begin
        // --------------------------------------------------------
        // Default assignments for combinational safety
        // This prevents Quartus from inferring latches.
        // --------------------------------------------------------
        cell_col       = 5'd0;
        cell_row       = 4'd0;

        head_on        = 1'b0;
        body_on        = 1'b0;
        food_on        = 1'b0;
        hand_on        = 1'b0;
        start_box_on   = 1'b0;

        hand_dx_mag    = 11'd0;
        hand_dy_mag    = 11'd0;
        box_dx_mag     = 11'd0;
        box_dy_mag     = 11'd0;

        body1_on       = 1'b0;
        body2_on       = 1'b0;
        body3_on       = 1'b0;
        body4_on       = 1'b0;
        body5_on       = 1'b0;
        body6_on       = 1'b0;
        body7_on       = 1'b0;
        body8_on       = 1'b0;
        body9_on       = 1'b0;
        body10_on      = 1'b0;
        body11_on      = 1'b0;

        score_value    = 4'd0;
        score_tens     = 4'd0;
        score_ones     = 4'd0;
        score_on       = 1'b0;

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

        go_x                = 10'd0;
        go_y                = 10'd0;
        go_big_char_index   = 5'd0;
        go_big_char_px      = 3'd0;
        go_big_char_py      = 3'd0;
        go_small_char_index = 5'd0;
        go_small_char_px    = 3'd0;
        go_small_char_py    = 3'd0;
        go_char_code        = CH_BLANK;

        // Default output color = black
        R_out          = 10'd0;
        G_out          = 10'd0;
        B_out          = 10'd0;

        // --------------------------------------------------------
        // Convert VGA pixel to snake grid cell
        // --------------------------------------------------------
        cell_col = vga_x[9:5];
        cell_row = vga_y[8:5];

        // --------------------------------------------------------
        // Snake / food checks
        // --------------------------------------------------------
        head_on = (cell_col == snake_head_col) && (cell_row == snake_head_row);

        body1_on  = (snake_len >= 4'd2)  && (cell_col == snake_body1_col)  && (cell_row == snake_body1_row);
        body2_on  = (snake_len >= 4'd3)  && (cell_col == snake_body2_col)  && (cell_row == snake_body2_row);
        body3_on  = (snake_len >= 4'd4)  && (cell_col == snake_body3_col)  && (cell_row == snake_body3_row);
        body4_on  = (snake_len >= 4'd5)  && (cell_col == snake_body4_col)  && (cell_row == snake_body4_row);
        body5_on  = (snake_len >= 4'd6)  && (cell_col == snake_body5_col)  && (cell_row == snake_body5_row);
        body6_on  = (snake_len >= 4'd7)  && (cell_col == snake_body6_col)  && (cell_row == snake_body6_row);
        body7_on  = (snake_len >= 4'd8)  && (cell_col == snake_body7_col)  && (cell_row == snake_body7_row);
        body8_on  = (snake_len >= 4'd9)  && (cell_col == snake_body8_col)  && (cell_row == snake_body8_row);
        body9_on  = (snake_len >= 4'd10) && (cell_col == snake_body9_col)  && (cell_row == snake_body9_row);
        body10_on = (snake_len >= 4'd11) && (cell_col == snake_body10_col) && (cell_row == snake_body10_row);
        body11_on = (snake_len >= 4'd12) && (cell_col == snake_body11_col) && (cell_row == snake_body11_row);

        body_on = body1_on || body2_on || body3_on || body4_on || body5_on ||
                  body6_on || body7_on || body8_on || body9_on || body10_on || body11_on;

        food_on = (cell_col == food_col) && (cell_row == food_row);

        // --------------------------------------------------------
        // Small cursor at detected hand position
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
        // Yellow start box in center when game is not running
        // --------------------------------------------------------
        if (vga_x >= 10'd320)
            box_dx_mag = {1'b0, (vga_x - 10'd320)};
        else
            box_dx_mag = {1'b0, (10'd320 - vga_x)};

        if (vga_y >= 10'd240)
            box_dy_mag = {1'b0, (vga_y - 10'd240)};
        else
            box_dy_mag = {1'b0, (10'd240 - vga_y)};

        start_box_on = (!game_running) &&
                       (box_dx_mag <= 11'd48) &&
                       (box_dy_mag <= 11'd48);

        // --------------------------------------------------------
        // Score display setup
        // Score = snake_len - 1
        // Hide normal score while game-over banner is active
        // --------------------------------------------------------
        if (snake_len > 4'd0)
            score_value = snake_len - 4'd1;
        else
            score_value = 4'd0;

        score_tens = score_value / 4'd10;
        score_ones = score_value % 4'd10;

        if (!game_over_active) begin
            // Score area: top-left corner
            // Characters:
            // 0:S 1:C 2:O 3:R 4:E 5:: 6:blank 7:tens 8:ones
            if ((vga_x >= 10'd8) && (vga_x < 10'd62) &&
                (vga_y >= 10'd8) && (vga_y < 10'd16)) begin

                score_x = vga_x - 10'd8;
                score_y = vga_y - 10'd8;

                char_index = score_x / 10'd6;
                char_px    = score_x % 10'd6;
                char_py    = score_y[2:0];

                case (char_index)
                    4'd0: char_code = CH_S;
                    4'd1: char_code = CH_C;
                    4'd2: char_code = CH_O;
                    4'd3: char_code = CH_R;
                    4'd4: char_code = CH_E;
                    4'd5: char_code = CH_COLON;
                    4'd6: char_code = CH_BLANK;
                    4'd7: begin
                        if (score_tens == 4'd0)
                            char_code = CH_BLANK;
                        else
                            char_code = digit_to_char(score_tens);
                    end
                    4'd8: char_code = digit_to_char(score_ones);
                    default: char_code = CH_BLANK;
                endcase

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
        end

        // --------------------------------------------------------
        // Game-over banner in the middle of the screen
        // Big flashing red "GAME OVER"
        // Smaller white line: "YOUR SCORE WAS: X"
        // --------------------------------------------------------
        if (game_over_active && game_over_flash_on) begin
            // Banner background and border
            if ((vga_x >= 10'd100) && (vga_x < 10'd540) &&
                (vga_y >= 10'd160) && (vga_y < 10'd300)) begin
                game_over_banner_fill_on = 1'b1;

                if ((vga_x < 10'd104) || (vga_x >= 10'd536) ||
                    (vga_y < 10'd164) || (vga_y >= 10'd296))
                    game_over_banner_border_on = 1'b1;
            end

            // ----------------------------------------------------
            // Big text: GAME OVER
            // Large letters are made by scaling 5x7 glyphs by 5x.
            // 9 slots including the space.
            // ----------------------------------------------------
            if ((vga_x >= 10'd185) && (vga_x < 10'd455) &&
                (vga_y >= 10'd178) && (vga_y < 10'd213)) begin

                go_x = vga_x - 10'd185;
                go_y = vga_y - 10'd178;

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

            // ----------------------------------------------------
            // Small text: YOUR SCORE WAS: X
            // 18 slots total
            // ----------------------------------------------------
            if ((vga_x >= 10'd206) && (vga_x < 10'd314) &&
                (vga_y >= 10'd245) && (vga_y < 10'd253)) begin

                go_x = vga_x - 10'd206;
                go_y = vga_y - 10'd245;

                go_small_char_index = go_x / 10'd6;
                go_small_char_px    = go_x % 10'd6;
                go_small_char_py    = go_y[2:0];

                case (go_small_char_index)
                    5'd0:  go_char_code = CH_Y;
                    5'd1:  go_char_code = CH_O;
                    5'd2:  go_char_code = CH_U;
                    5'd3:  go_char_code = CH_R;
                    5'd4:  go_char_code = CH_BLANK;
                    5'd5:  go_char_code = CH_S;
                    5'd6:  go_char_code = CH_C;
                    5'd7:  go_char_code = CH_O;
                    5'd8:  go_char_code = CH_R;
                    5'd9:  go_char_code = CH_E;
                    5'd10: go_char_code = CH_BLANK;
                    5'd11: go_char_code = CH_W;
                    5'd12: go_char_code = CH_A;
                    5'd13: go_char_code = CH_S;
                    5'd14: go_char_code = CH_COLON;
                    5'd15: go_char_code = CH_BLANK;
                    5'd16: begin
                        if (game_over_score >= 4'd10)
                            go_char_code = digit_to_char(4'd1);
                        else
                            go_char_code = CH_BLANK;
                    end
                    5'd17: begin
                        if (game_over_score >= 4'd10)
                            go_char_code = digit_to_char(game_over_score - 4'd10);
                        else
                            go_char_code = digit_to_char(game_over_score);
                    end
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
        end

        // --------------------------------------------------------
        // Final color priority
        // --------------------------------------------------------
        if (game_over_big_text_on) begin
            // Bright red game-over text
            R_out = 10'd1023;
            G_out = 10'd80;
            B_out = 10'd80;
        end
        else if (game_over_small_text_on) begin
            // White score line
            R_out = 10'd1023;
            G_out = 10'd1023;
            B_out = 10'd1023;
        end
        else if (game_over_banner_border_on) begin
            // Bright red border
            R_out = 10'd900;
            G_out = 10'd0;
            B_out = 10'd0;
        end
        else if (game_over_banner_fill_on) begin
            // Dark red fill
            R_out = 10'd260;
            G_out = 10'd0;
            B_out = 10'd0;
        end
        else if (score_on) begin
            // White score text
            R_out = 10'd1023;
            G_out = 10'd1023;
            B_out = 10'd1023;
        end
        else if (head_on && game_running) begin
            // Green snake head
            R_out = 10'd0;
            G_out = 10'd1023;
            B_out = 10'd0;
        end
        else if (body_on && game_running) begin
            // White snake body
            R_out = 10'd1023;
            G_out = 10'd1023;
            B_out = 10'd1023;
        end
        else if (food_on && game_running) begin
            // Red food
            R_out = 10'd1023;
            G_out = 10'd0;
            B_out = 10'd0;
        end
        else if (hand_on) begin
            // Light blue hand cursor
            R_out = 10'd0;
            G_out = 10'd700;
            B_out = 10'd1023;
        end
        else if (start_box_on) begin
            // Yellow start box
            R_out = 10'd1023;
            G_out = 10'd1023;
            B_out = 10'd0;
        end
        else begin
            // Black background
            R_out = 10'd0;
            G_out = 10'd0;
            B_out = 10'd0;
        end
    end

endmodule