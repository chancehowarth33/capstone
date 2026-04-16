// draw_game.v
// Sketchpad-style drawing game.
//
// On reset the module shows a start screen ("DRAW MODE") until the user
// holds their hand in the centre yellow box for ~2 seconds (120 vsync frames).
// Once active, the screen is divided into an 80x60 grid of 8x8 cells.
// When detected and pen_down are high, cells under the hand centroid are
// marked on every vsync falling edge.
// Painted cells render white; the live cursor renders yellow when pen_down
// is high (drawing) and red when pen_down is low (pen lifted); everything else is black.
//
// Inputs
//   clk        : VGA pixel clock (25 MHz)
//   rst_n      : active-low reset
//   vsync      : VGA vertical sync (active-low pulse = frame boundary)
//   detected   : high when color_detect has a valid hand centroid
//   overlay_x  : hand centroid X in pixels (from color_detect)
//   overlay_y  : hand centroid Y in pixels (from color_detect)
//   vga_x      : current VGA scan X (from VGA_Controller)
//   vga_y      : current VGA scan Y (from VGA_Controller)
//   clear_n    : active-low canvas clear (connect to a KEY button)
//   pen_down   : high = drawing enabled, low = pen lifted (no paint)
//   brush_size : 0 = small (1x1 cell / 8px),
//                1 = medium (2x2 cells / 16px),
//                2 = large  (4x4 cells / 32px)
//
// Outputs
//   R_out / G_out / B_out : 10-bit RGB to VGA mux

module draw_game (
    input             clk,
    input             rst_n,
    input             vsync,
    input             detected,
    input      [9:0]  overlay_x,
    input      [9:0]  overlay_y,
    input      [9:0]  vga_x,
    input      [9:0]  vga_y,
    input             clear_n,
    input             pen_down,
    input      [1:0]  brush_size,
    output reg [9:0]  R_out,
    output reg [9:0]  G_out,
    output reg [9:0]  B_out
);

    localparam GRID_COLS = 80;
    localparam GRID_ROWS = 60;
    localparam [6:0] START_HOLD_FRAMES = 7'd120;

    // Character codes for start-screen glyphs
    localparam [4:0] CH_BLANK = 5'd0;
    localparam [4:0] CH_D     = 5'd1;
    localparam [4:0] CH_R     = 5'd2;
    localparam [4:0] CH_A     = 5'd3;
    localparam [4:0] CH_W     = 5'd4;
    localparam [4:0] CH_M     = 5'd5;
    localparam [4:0] CH_O     = 5'd6;
    localparam [4:0] CH_E     = 5'd7;
    localparam [4:0] CH_H     = 5'd8;
    localparam [4:0] CH_L     = 5'd9;
    localparam [4:0] CH_T     = 5'd10;
    localparam [4:0] CH_S     = 5'd11;

    // -----------------------------------------------------------------------
    // Canvas — one bit per 8x8 grid cell
    // -----------------------------------------------------------------------
    reg canvas [0:GRID_COLS-1][0:GRID_ROWS-1];

    // Grid cell of the hand centroid (divide pixel coords by 8)
    wire [6:0] hand_col = overlay_x[9:3];
    wire [6:0] hand_row = overlay_y[9:3];

    // Grid cell of the current VGA scan pixel
    wire [6:0] pixel_col = vga_x[9:3];
    wire [6:0] pixel_row = vga_y[9:3];

    // -----------------------------------------------------------------------
    // Brush span: number of cells to paint per axis
    //   brush_size 0 -> 1x1, 1 -> 2x2, 2 -> 4x4
    // -----------------------------------------------------------------------
    wire [2:0] span = (brush_size == 2'd2) ? 3'd4 :
                      (brush_size == 2'd1) ? 3'd2 : 3'd1;

    // -----------------------------------------------------------------------
    // vsync falling-edge detect (matches color_detect convention)
    // -----------------------------------------------------------------------
    reg vsync_prev;
    wire vsync_fall = vsync_prev && !vsync;

    // -----------------------------------------------------------------------
    // Start screen state
    // -----------------------------------------------------------------------
    reg         game_active;
    reg  [6:0]  start_hold_count;
    reg         start_armed;

    // Hand-centroid distance from screen centre for hold-to-start detection
    wire [10:0] hand_box_dx = (overlay_x >= 10'd320) ?
                               {1'b0, overlay_x - 10'd320} :
                               {1'b0, 10'd320 - overlay_x};
    wire [10:0] hand_box_dy = (overlay_y >= 10'd240) ?
                               {1'b0, overlay_y - 10'd240} :
                               {1'b0, 10'd240 - overlay_y};
    wire in_start_box = detected && (hand_box_dx <= 11'd48) && (hand_box_dy <= 11'd48);

    integer i, j, di, dj;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vsync_prev       <= 1'b0;
            game_active      <= 1'b0;
            start_hold_count <= 7'd0;
            start_armed      <= 1'b0;
            for (i = 0; i < GRID_COLS; i = i + 1)
                for (j = 0; j < GRID_ROWS; j = j + 1)
                    canvas[i][j] <= 1'b0;
        end else begin
            vsync_prev <= vsync;

            if (!clear_n) begin
                // Hold clear_n low to wipe the canvas and return to start screen
                game_active      <= 1'b0;
                start_hold_count <= 7'd0;
                start_armed      <= 1'b0;
                for (i = 0; i < GRID_COLS; i = i + 1)
                    for (j = 0; j < GRID_ROWS; j = j + 1)
                        canvas[i][j] <= 1'b0;
            end else if (vsync_fall) begin
                if (!game_active) begin
                    // ------------------------------------------------
                    // Hold-to-start: user moves hand OUT of the box
                    // first (arms the trigger), then holds it IN the
                    // box for START_HOLD_FRAMES consecutive frames.
                    // ------------------------------------------------
                    if (!detected || !in_start_box) begin
                        start_armed      <= 1'b1;
                        start_hold_count <= 7'd0;
                    end else if (start_armed && in_start_box) begin
                        if (start_hold_count < START_HOLD_FRAMES)
                            start_hold_count <= start_hold_count + 7'd1;
                    end else begin
                        start_hold_count <= 7'd0;
                    end

                    if (start_hold_count >= START_HOLD_FRAMES - 1) begin
                        game_active      <= 1'b1;
                        start_hold_count <= 7'd0;
                    end
                end else if (detected && pen_down) begin
                    // Paint a span x span block of cells around the hand centroid
                    for (di = 0; di < 4; di = di + 1)
                        for (dj = 0; dj < 4; dj = dj + 1)
                            if (di < span && dj < span)
                                if ((hand_col + di) < GRID_COLS && (hand_row + dj) < GRID_ROWS)
                                    canvas[hand_col + di][hand_row + dj] <= 1'b1;
                end
            end
        end
    end

    // -----------------------------------------------------------------------
    // Live cursor — 5x5 pixel dot centred on hand centroid
    // Written using addition to avoid unsigned underflow on subtraction
    // -----------------------------------------------------------------------
    wire cursor_on = detected &&
                     (vga_x + 10'd2 >= overlay_x) && (overlay_x + 10'd2 >= vga_x) &&
                     (vga_y + 10'd2 >= overlay_y) && (overlay_y + 10'd2 >= vga_y);

    // -----------------------------------------------------------------------
    // 5x7 glyph ROM — returns one 5-bit row for a given character code.
    // Bit 4 is the leftmost pixel, bit 0 is the rightmost.
    // -----------------------------------------------------------------------
    function [4:0] get_glyph_row;
        input [4:0] code;
        input [2:0] row;
        begin
            case (code)
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
                default: get_glyph_row = 5'b00000;
            endcase
        end
    endfunction

    // -----------------------------------------------------------------------
    // Start-screen pixel signals (combinational regs)
    // -----------------------------------------------------------------------
    reg        start_box_on;
    reg        big_text_on;
    reg        small_text_on;

    reg [10:0] vga_box_dx;
    reg [10:0] vga_box_dy;

    // Big text rendering intermediates
    reg [9:0]  bt_x;
    reg [9:0]  bt_y;
    reg [4:0]  bt_char_index;
    reg [2:0]  bt_char_px;
    reg [2:0]  bt_char_py;
    reg [4:0]  bt_char_code;
    reg [4:0]  bt_glyph_bits;

    // Small text rendering intermediates
    reg [9:0]  st_x;
    reg [9:0]  st_y;
    reg [4:0]  st_char_index;
    reg [2:0]  st_char_px;
    reg [2:0]  st_char_py;
    reg [4:0]  st_char_code;
    reg [4:0]  st_glyph_bits;

    // -----------------------------------------------------------------------
    // Pixel renderer (combinational)
    //
    // Start screen layout (all centred on 640x480):
    //   "DRAW MODE"    — 5x-scaled cyan glyphs, y=[138,173)
    //   Yellow box     — 2px border outline, centre±48px, y=[192,288)
    //   "HOLD TO START"— 1x white glyphs, y=[296,304)
    //
    // Game active priority: painted trail > cursor > background
    // -----------------------------------------------------------------------
    always @(*) begin
        // Defaults to suppress latches
        start_box_on  = 1'b0;
        big_text_on   = 1'b0;
        small_text_on = 1'b0;

        vga_box_dx    = 11'd0;
        vga_box_dy    = 11'd0;

        bt_x          = 10'd0;
        bt_y          = 10'd0;
        bt_char_index = 5'd0;
        bt_char_px    = 3'd0;
        bt_char_py    = 3'd0;
        bt_char_code  = CH_BLANK;
        bt_glyph_bits = 5'b00000;

        st_x          = 10'd0;
        st_y          = 10'd0;
        st_char_index = 5'd0;
        st_char_px    = 3'd0;
        st_char_py    = 3'd0;
        st_char_code  = CH_BLANK;
        st_glyph_bits = 5'b00000;

        R_out = 10'h000;
        G_out = 10'h000;
        B_out = 10'h000;

        if (!game_active) begin
            // ----------------------------------------------------------
            // Start screen rendering
            // ----------------------------------------------------------

            // Yellow box: 2px border outline at screen centre ±48px
            vga_box_dx = (vga_x >= 10'd320) ?
                          {1'b0, vga_x - 10'd320} :
                          {1'b0, 10'd320 - vga_x};
            vga_box_dy = (vga_y >= 10'd240) ?
                          {1'b0, vga_y - 10'd240} :
                          {1'b0, 10'd240 - vga_y};

            start_box_on = (vga_box_dx <= 11'd48) && (vga_box_dy <= 11'd48) &&
                           ((vga_box_dx >= 11'd46) || (vga_box_dy >= 11'd46));

            // Big text "DRAW MODE" — 5x scaled, x=[185,455), y=[138,173)
            // Layout: 9 chars × 30px (25px glyph + 5px gap) = 270px total
            if ((vga_x >= 10'd185) && (vga_x < 10'd455) &&
                (vga_y >= 10'd138) && (vga_y < 10'd173)) begin

                bt_x          = vga_x - 10'd185;
                bt_y          = vga_y - 10'd138;
                bt_char_index = bt_x / 10'd30;
                bt_char_px    = (bt_x % 10'd30) / 10'd5;
                bt_char_py    = bt_y / 10'd5;

                case (bt_char_index)
                    5'd0: bt_char_code = CH_D;
                    5'd1: bt_char_code = CH_R;
                    5'd2: bt_char_code = CH_A;
                    5'd3: bt_char_code = CH_W;
                    5'd4: bt_char_code = CH_BLANK;
                    5'd5: bt_char_code = CH_M;
                    5'd6: bt_char_code = CH_O;
                    5'd7: bt_char_code = CH_D;
                    5'd8: bt_char_code = CH_E;
                    default: bt_char_code = CH_BLANK;
                endcase

                if ((bt_char_px < 3'd5) && (bt_char_py < 3'd7)) begin
                    bt_glyph_bits = get_glyph_row(bt_char_code, bt_char_py);
                    case (bt_char_px)
                        3'd0: big_text_on = bt_glyph_bits[4];
                        3'd1: big_text_on = bt_glyph_bits[3];
                        3'd2: big_text_on = bt_glyph_bits[2];
                        3'd3: big_text_on = bt_glyph_bits[1];
                        3'd4: big_text_on = bt_glyph_bits[0];
                        default: big_text_on = 1'b0;
                    endcase
                end
            end

            // Small text "HOLD TO START" — 1x, x=[281,359), y=[296,304)
            // Layout: 13 chars × 6px (5px glyph + 1px gap) = 78px total
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
                        3'd0: small_text_on = st_glyph_bits[4];
                        3'd1: small_text_on = st_glyph_bits[3];
                        3'd2: small_text_on = st_glyph_bits[2];
                        3'd3: small_text_on = st_glyph_bits[1];
                        3'd4: small_text_on = st_glyph_bits[0];
                        default: small_text_on = 1'b0;
                    endcase
                end
            end

            // Start-screen colour priority
            if (big_text_on) begin
                R_out = 10'h000;
                G_out = 10'h3FF;
                B_out = 10'h3FF;  // Cyan title
            end else if (small_text_on) begin
                R_out = 10'h3FF;
                G_out = 10'h3FF;
                B_out = 10'h3FF;  // White subtitle
            end else if (start_box_on) begin
                R_out = 10'h3FF;
                G_out = 10'h3FF;
                B_out = 10'h000;  // Yellow target box
            end else if (cursor_on) begin
                R_out = 10'h3FF;
                G_out = 10'h3FF;
                B_out = 10'h3FF;  // White cursor on start screen
            end else begin
                R_out = 10'h000;
                G_out = 10'h000;
                B_out = 10'h000;
            end

        end else begin
            // ----------------------------------------------------------
            // Game active: normal canvas rendering
            // ----------------------------------------------------------
            if (canvas[pixel_col][pixel_row]) begin
                // Painted cell — white
                R_out = 10'h3FF;
                G_out = 10'h3FF;
                B_out = 10'h3FF;
            end else if (cursor_on) begin
                // Live cursor — yellow when pen down, red when pen up
                R_out = 10'h3FF;
                G_out = pen_down ? 10'h3FF : 10'h000;
                B_out = 10'h000;
            end else begin
                // Background — black
                R_out = 10'h000;
                G_out = 10'h000;
                B_out = 10'h000;
            end
        end
    end

endmodule
