// draw_game.v
// Sketchpad-style drawing game.
//
// On reset the module shows a start screen ("DRAW MODE") until the user
// holds their hand in the centre yellow box for ~2 seconds (120 vsync frames).
// Once active, the screen is divided into an 80x60 grid of 8x8 cells.
// When detected and pen_down are high, a Bresenham line is drawn each frame
// from the previous hand position to the current one, filling gaps when the
// hand moves quickly.  Painted cells render white.  The cursor is a 16x16
// diagonal pencil sprite (yellow body when pen down, red body when pen up).
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

    localparam GRID_COLS        = 80;
    localparam GRID_ROWS        = 60;
    localparam [6:0] START_HOLD_FRAMES = 7'd120;
    localparam LINE_IDLE        = 1'b0;
    localparam LINE_DRAW        = 1'b1;
    localparam [6:0] MIN_MOVE   = 7'd2;  // grid cells (~16px) hand must move before drawing

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

    wire [6:0] hand_col  = overlay_x[9:3];
    wire [6:0] hand_row  = overlay_y[9:3];
    wire [6:0] pixel_col = vga_x[9:3];
    wire [6:0] pixel_row = vga_y[9:3];

    wire [2:0] span = (brush_size == 2'd2) ? 3'd4 :
                      (brush_size == 2'd1) ? 3'd2 : 3'd1;

    // -----------------------------------------------------------------------
    // vsync falling-edge detect
    // -----------------------------------------------------------------------
    reg vsync_prev;
    wire vsync_fall = vsync_prev && !vsync;

    // -----------------------------------------------------------------------
    // Start screen state
    // -----------------------------------------------------------------------
    reg        game_active;
    reg [6:0]  start_hold_count;
    reg        start_armed;

    wire [10:0] hand_box_dx = (overlay_x >= 10'd320) ?
                               {1'b0, overlay_x - 10'd320} :
                               {1'b0, 10'd320 - overlay_x};
    wire [10:0] hand_box_dy = (overlay_y >= 10'd240) ?
                               {1'b0, overlay_y - 10'd240} :
                               {1'b0, 10'd240 - overlay_y};
    wire in_start_box = detected && (hand_box_dx <= 11'd48) && (hand_box_dy <= 11'd48);

    // -----------------------------------------------------------------------
    // Bresenham line-drawing state machine
    // Runs at pixel-clock speed between vsync edges.  On each vsync_fall the
    // previous hand grid cell is connected to the current one; the machine
    // finishes (max ~100 steps) long before the next frame arrives.
    // -----------------------------------------------------------------------
    reg        line_state;
    reg [6:0]  bx, by;          // current cell being painted
    reg [6:0]  tx, ty;          // target cell
    reg [7:0]  b_dx, b_dy;      // |delta| per axis
    reg        b_sx, b_sy;      // step direction: 1 = positive
    reg signed [8:0] b_err;     // Bresenham error accumulator

    // Combinational Bresenham helpers
    wire signed [9:0] b_e2      = {b_err, 1'b0};                   // 2 * err
    wire signed [9:0] b_neg_dy  = -$signed({2'b00, b_dy});
    wire signed [9:0] b_dx_s    =  $signed({2'b00, b_dx});
    wire              b_step_x  = (b_e2 > b_neg_dy);
    wire              b_step_y  = (b_e2 < b_dx_s);
    // Compute updated error without scheduling conflicts
    wire signed [8:0] b_err_ax  = b_step_x ? (b_err - $signed({1'b0, b_dy})) : b_err;
    wire signed [8:0] b_err_nxt = b_step_y ? (b_err_ax + $signed({1'b0, b_dx})) : b_err_ax;

    // Previous pen position (for line interpolation)
    reg [6:0] prev_col, prev_row;
    reg       prev_pen_valid;   // set while pen was down last frame

    // Precomputed setup values for starting a new line segment
    wire [7:0] line_dx   = (hand_col >= prev_col) ? (hand_col - prev_col) : (prev_col - hand_col);
    wire [7:0] line_dy   = (hand_row >= prev_row) ? (hand_row - prev_row) : (prev_row - hand_row);
    wire signed [8:0] line_err0 = $signed({1'b0, line_dx}) - $signed({1'b0, line_dy});

    integer i, j, di, dj;

    // -----------------------------------------------------------------------
    // Sequential logic
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vsync_prev       <= 1'b0;
            game_active      <= 1'b0;
            start_hold_count <= 7'd0;
            start_armed      <= 1'b0;
            prev_pen_valid   <= 1'b0;
            prev_col         <= 7'd0;
            prev_row         <= 7'd0;
            line_state       <= LINE_IDLE;
            bx <= 0; by <= 0; tx <= 0; ty <= 0;
            b_dx <= 0; b_dy <= 0; b_sx <= 0; b_sy <= 0; b_err <= 0;
            for (i = 0; i < GRID_COLS; i = i + 1)
                for (j = 0; j < GRID_ROWS; j = j + 1)
                    canvas[i][j] <= 1'b0;
        end else begin
            vsync_prev <= vsync;

            if (!clear_n) begin
                game_active      <= 1'b0;
                start_hold_count <= 7'd0;
                start_armed      <= 1'b0;
                prev_pen_valid   <= 1'b0;
                line_state       <= LINE_IDLE;
                for (i = 0; i < GRID_COLS; i = i + 1)
                    for (j = 0; j < GRID_ROWS; j = j + 1)
                        canvas[i][j] <= 1'b0;
            end else begin

                // ------------------------------------------------------------
                // Bresenham step — one grid cell per clock cycle
                // vsync_fall assignments below override these if both fire
                // ------------------------------------------------------------
                if (line_state == LINE_DRAW) begin
                    for (di = 0; di < 4; di = di + 1)
                        for (dj = 0; dj < 4; dj = dj + 1)
                            if (di < span && dj < span)
                                if ((bx + di) < GRID_COLS && (by + dj) < GRID_ROWS)
                                    canvas[bx + di][by + dj] <= 1'b1;

                    if (bx == tx && by == ty) begin
                        line_state <= LINE_IDLE;
                    end else begin
                        b_err <= b_err_nxt;
                        if (b_step_x) bx <= b_sx ? bx + 7'd1 : bx - 7'd1;
                        if (b_step_y) by <= b_sy ? by + 7'd1 : by - 7'd1;
                    end
                end

                // ------------------------------------------------------------
                // Frame boundary logic
                // ------------------------------------------------------------
                if (vsync_fall) begin
                    if (!game_active) begin
                        // Hold-to-start
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

                    end else begin
                        if (detected && pen_down) begin
                            // Stamp brush at current position
                            for (di = 0; di < 4; di = di + 1)
                                for (dj = 0; dj < 4; dj = dj + 1)
                                    if (di < span && dj < span)
                                        if ((hand_col + di) < GRID_COLS && (hand_row + dj) < GRID_ROWS)
                                            canvas[hand_col + di][hand_row + dj] <= 1'b1;

                            // Connect to previous position with a Bresenham line,
                            // but only if the hand moved at least MIN_MOVE grid cells
                            // to suppress jitter from small centroid oscillations.
                            if (prev_pen_valid && (line_dx >= MIN_MOVE || line_dy >= MIN_MOVE)) begin
                                bx         <= prev_col;
                                by         <= prev_row;
                                tx         <= hand_col;
                                ty         <= hand_row;
                                b_dx       <= line_dx;
                                b_dy       <= line_dy;
                                b_sx       <= (hand_col >= prev_col);
                                b_sy       <= (hand_row >= prev_row);
                                b_err      <= line_err0;
                                line_state <= LINE_DRAW;
                            end

                            prev_col       <= hand_col;
                            prev_row       <= hand_row;
                            prev_pen_valid <= 1'b1;
                        end else begin
                            // Pen lifted — reset prev so next pen-down starts fresh
                            prev_pen_valid <= 1'b0;
                            line_state     <= LINE_IDLE;
                        end
                    end
                end

            end
        end
    end

    // -----------------------------------------------------------------------
    // Pencil sprite — 16x16, diagonal (eraser top-left → tip bottom-right)
    //
    //   Layer A  eraser  (pink)   rows  0-2
    //   Layer B  band    (gold)   row   3
    //   Layer C  body    (yellow) rows  4-11
    //   Layer D  tip     (gray)   rows 12-15
    //
    // Bit 15 of each mask = column 0; bit 0 = column 15.
    // The diagonal band shifts one column right per row.
    // -----------------------------------------------------------------------
    function [15:0] pencil_eraser_row;
        input [3:0] py;
        case (py)
            4'd0:    pencil_eraser_row = 16'hE000; // cols 0-2
            4'd1:    pencil_eraser_row = 16'h7000; // cols 1-3
            4'd2:    pencil_eraser_row = 16'h3800; // cols 2-4
            default: pencil_eraser_row = 16'h0000;
        endcase
    endfunction

    function [15:0] pencil_band_row;
        input [3:0] py;
        case (py)
            4'd3:    pencil_band_row = 16'h1C00;   // cols 3-5
            default: pencil_band_row = 16'h0000;
        endcase
    endfunction

    function [15:0] pencil_body_row;
        input [3:0] py;
        case (py)
            4'd4:    pencil_body_row = 16'h0E00;   // cols  4-6
            4'd5:    pencil_body_row = 16'h0700;   // cols  5-7
            4'd6:    pencil_body_row = 16'h0380;   // cols  6-8
            4'd7:    pencil_body_row = 16'h01C0;   // cols  7-9
            4'd8:    pencil_body_row = 16'h00E0;   // cols  8-10
            4'd9:    pencil_body_row = 16'h0070;   // cols  9-11
            4'd10:   pencil_body_row = 16'h0038;   // cols 10-12
            4'd11:   pencil_body_row = 16'h001C;   // cols 11-13
            default: pencil_body_row = 16'h0000;
        endcase
    endfunction

    function [15:0] pencil_tip_row;
        input [3:0] py;
        case (py)
            4'd12:   pencil_tip_row = 16'h000C;    // cols 12-13 (2 px)
            4'd13:   pencil_tip_row = 16'h0004;    // col  13
            4'd14:   pencil_tip_row = 16'h0002;    // col  14
            4'd15:   pencil_tip_row = 16'h0001;    // col  15 (sharp tip)
            default: pencil_tip_row = 16'h0000;
        endcase
    endfunction

    // Sprite screen-space bounds (addition-safe, avoids unsigned underflow)
    wire in_spr = detected &&
                  (vga_x + 10'd8 >= overlay_x) && (vga_x < overlay_x + 10'd8) &&
                  (vga_y + 10'd8 >= overlay_y) && (vga_y < overlay_y + 10'd8);
    wire [3:0] spr_px = (vga_x + 10'd8 - overlay_x);
    wire [3:0] spr_py = (vga_y + 10'd8 - overlay_y);

    // -----------------------------------------------------------------------
    // 5x7 glyph ROM
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
    // Start-screen rendering intermediates
    // -----------------------------------------------------------------------
    reg        start_box_on;
    reg        big_text_on;
    reg        small_text_on;

    reg [10:0] vga_box_dx;
    reg [10:0] vga_box_dy;

    reg [9:0]  bt_x;
    reg [9:0]  bt_y;
    reg [4:0]  bt_char_index;
    reg [9:0]  bt_x_in_char;
    reg [2:0]  bt_char_px;
    reg [2:0]  bt_char_py;
    reg [4:0]  bt_char_code;
    reg [4:0]  bt_glyph_bits;

    reg [9:0]  st_x;
    reg [9:0]  st_y;
    reg [4:0]  st_char_index;
    reg [9:0]  st_x_in_char;
    reg [2:0]  st_char_px;
    reg [2:0]  st_char_py;
    reg [4:0]  st_char_code;
    reg [4:0]  st_glyph_bits;

    // Pencil sprite pixel signals (computed each pixel clock)
    reg [15:0] spr_row_e, spr_row_ba, spr_row_bo, spr_row_t;
    reg        spr_eraser_on, spr_band_on, spr_body_on, spr_tip_on;

    // -----------------------------------------------------------------------
    // Pixel renderer (combinational)
    // -----------------------------------------------------------------------
    always @(*) begin
        // Defaults
        start_box_on  = 1'b0;
        big_text_on   = 1'b0;
        small_text_on = 1'b0;
        vga_box_dx    = 11'd0;
        vga_box_dy    = 11'd0;
        bt_x          = 10'd0; bt_y          = 10'd0;
        bt_char_index = 5'd0;  bt_x_in_char  = 10'd0;
        bt_char_px    = 3'd0;  bt_char_py    = 3'd0;
        bt_char_code  = CH_BLANK; bt_glyph_bits = 5'b00000;
        st_x          = 10'd0; st_y          = 10'd0;
        st_char_index = 5'd0;  st_x_in_char  = 10'd0;
        st_char_px    = 3'd0;  st_char_py    = 3'd0;
        st_char_code  = CH_BLANK; st_glyph_bits = 5'b00000;
        R_out         = 10'h000;
        G_out         = 10'h000;
        B_out         = 10'h000;

        // Pencil sprite pixel lookup
        spr_row_e     = pencil_eraser_row(spr_py);
        spr_row_ba    = pencil_band_row(spr_py);
        spr_row_bo    = pencil_body_row(spr_py);
        spr_row_t     = pencil_tip_row(spr_py);
        spr_eraser_on = in_spr && spr_row_e [15 - spr_px];
        spr_band_on   = in_spr && spr_row_ba[15 - spr_px];
        spr_body_on   = in_spr && spr_row_bo[15 - spr_px];
        spr_tip_on    = in_spr && spr_row_t [15 - spr_px];

        if (!game_active) begin
            // ------------------------------------------------------------------
            // Start screen
            // ------------------------------------------------------------------

            // Yellow box border (2px) at screen centre ±48px
            vga_box_dx = (vga_x >= 10'd320) ?
                          {1'b0, vga_x - 10'd320} : {1'b0, 10'd320 - vga_x};
            vga_box_dy = (vga_y >= 10'd240) ?
                          {1'b0, vga_y - 10'd240} : {1'b0, 10'd240 - vga_y};
            start_box_on = (vga_box_dx <= 11'd48) && (vga_box_dy <= 11'd48) &&
                           ((vga_box_dx >= 11'd46) || (vga_box_dy >= 11'd46));

            // Big text "DRAW MODE" — 5x scaled, x=[185,455), y=[138,173)
            if ((vga_x >= 10'd185) && (vga_x < 10'd455) &&
                (vga_y >= 10'd138) && (vga_y < 10'd173)) begin
                bt_x          = vga_x - 10'd185;
                bt_y          = vga_y - 10'd138;
                if      (bt_x < 10'd30)  begin bt_char_index = 5'd0; bt_x_in_char = bt_x; end
                else if (bt_x < 10'd60)  begin bt_char_index = 5'd1; bt_x_in_char = bt_x - 10'd30; end
                else if (bt_x < 10'd90)  begin bt_char_index = 5'd2; bt_x_in_char = bt_x - 10'd60; end
                else if (bt_x < 10'd120) begin bt_char_index = 5'd3; bt_x_in_char = bt_x - 10'd90; end
                else if (bt_x < 10'd150) begin bt_char_index = 5'd4; bt_x_in_char = bt_x - 10'd120; end
                else if (bt_x < 10'd180) begin bt_char_index = 5'd5; bt_x_in_char = bt_x - 10'd150; end
                else if (bt_x < 10'd210) begin bt_char_index = 5'd6; bt_x_in_char = bt_x - 10'd180; end
                else if (bt_x < 10'd240) begin bt_char_index = 5'd7; bt_x_in_char = bt_x - 10'd210; end
                else                     begin bt_char_index = 5'd8; bt_x_in_char = bt_x - 10'd240; end
                bt_char_px = (bt_x_in_char < 10'd5)  ? 3'd0 :
                             (bt_x_in_char < 10'd10) ? 3'd1 :
                             (bt_x_in_char < 10'd15) ? 3'd2 :
                             (bt_x_in_char < 10'd20) ? 3'd3 :
                             (bt_x_in_char < 10'd25) ? 3'd4 : 3'd5;
                bt_char_py = (bt_y < 10'd5)  ? 3'd0 :
                             (bt_y < 10'd10) ? 3'd1 :
                             (bt_y < 10'd15) ? 3'd2 :
                             (bt_y < 10'd20) ? 3'd3 :
                             (bt_y < 10'd25) ? 3'd4 :
                             (bt_y < 10'd30) ? 3'd5 : 3'd6;
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
            if ((vga_x >= 10'd281) && (vga_x < 10'd359) &&
                (vga_y >= 10'd296) && (vga_y < 10'd304)) begin
                st_x          = vga_x - 10'd281;
                st_y          = vga_y - 10'd296;
                if      (st_x < 10'd6)  begin st_char_index = 5'd0;  st_x_in_char = st_x; end
                else if (st_x < 10'd12) begin st_char_index = 5'd1;  st_x_in_char = st_x - 10'd6; end
                else if (st_x < 10'd18) begin st_char_index = 5'd2;  st_x_in_char = st_x - 10'd12; end
                else if (st_x < 10'd24) begin st_char_index = 5'd3;  st_x_in_char = st_x - 10'd18; end
                else if (st_x < 10'd30) begin st_char_index = 5'd4;  st_x_in_char = st_x - 10'd24; end
                else if (st_x < 10'd36) begin st_char_index = 5'd5;  st_x_in_char = st_x - 10'd30; end
                else if (st_x < 10'd42) begin st_char_index = 5'd6;  st_x_in_char = st_x - 10'd36; end
                else if (st_x < 10'd48) begin st_char_index = 5'd7;  st_x_in_char = st_x - 10'd42; end
                else if (st_x < 10'd54) begin st_char_index = 5'd8;  st_x_in_char = st_x - 10'd48; end
                else if (st_x < 10'd60) begin st_char_index = 5'd9;  st_x_in_char = st_x - 10'd54; end
                else if (st_x < 10'd66) begin st_char_index = 5'd10; st_x_in_char = st_x - 10'd60; end
                else if (st_x < 10'd72) begin st_char_index = 5'd11; st_x_in_char = st_x - 10'd66; end
                else                    begin st_char_index = 5'd12; st_x_in_char = st_x - 10'd72; end
                st_char_px = st_x_in_char[2:0];
                st_char_py = st_y[2:0];
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

            // Colour priority: title > subtitle > box > pencil sprite
            if (big_text_on) begin
                R_out = 10'h000; G_out = 10'h3FF; B_out = 10'h3FF; // Cyan
            end else if (small_text_on) begin
                R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h3FF; // White
            end else if (start_box_on) begin
                R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h000; // Yellow
            end else if (spr_eraser_on) begin
                R_out = 10'h3FF; G_out = 10'h100; B_out = 10'h180; // Pink
            end else if (spr_band_on) begin
                R_out = 10'h3FF; G_out = 10'h2A0; B_out = 10'h000; // Gold
            end else if (spr_body_on) begin
                R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h000; // Yellow body
            end else if (spr_tip_on) begin
                R_out = 10'h180; G_out = 10'h180; B_out = 10'h180; // Gray tip
            end

        end else begin
            // ------------------------------------------------------------------
            // Game active
            // ------------------------------------------------------------------
            if (canvas[pixel_col][pixel_row]) begin
                // Painted cell — white
                R_out = 10'h3FF; G_out = 10'h3FF; B_out = 10'h3FF;
            end else if (spr_eraser_on) begin
                R_out = 10'h3FF; G_out = 10'h100; B_out = 10'h180; // Pink eraser
            end else if (spr_band_on) begin
                R_out = 10'h3FF; G_out = 10'h2A0; B_out = 10'h000; // Gold band
            end else if (spr_body_on) begin
                // Yellow when pen down, red when pen up
                R_out = 10'h3FF;
                G_out = pen_down ? 10'h3FF : 10'h000;
                B_out = 10'h000;
            end else if (spr_tip_on) begin
                R_out = 10'h180; G_out = 10'h180; B_out = 10'h180; // Gray tip
            end
        end
    end

endmodule
