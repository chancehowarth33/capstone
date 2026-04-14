// draw_game.v
// Sketchpad-style drawing game.
//
// The screen is divided into an 80x60 grid of 8x8 cells.
// When the hand is detected and pen_down is high, cells under the hand
// centroid are marked as painted on every vsync falling edge.
// Painted cells render white; the live cursor renders as a small red
// dot; everything else is black.
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

    integer i, j, di, dj;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vsync_prev <= 1'b0;
            for (i = 0; i < GRID_COLS; i = i + 1)
                for (j = 0; j < GRID_ROWS; j = j + 1)
                    canvas[i][j] <= 1'b0;
        end else begin
            vsync_prev <= vsync;

            if (!clear_n) begin
                // Hold clear_n low to wipe the canvas
                for (i = 0; i < GRID_COLS; i = i + 1)
                    for (j = 0; j < GRID_ROWS; j = j + 1)
                        canvas[i][j] <= 1'b0;
            end else if (vsync_fall && detected && pen_down) begin
                // Paint a span x span block of cells around the hand centroid
                for (di = 0; di < 4; di = di + 1)
                    for (dj = 0; dj < 4; dj = dj + 1)
                        if (di < span && dj < span)
                            if ((hand_col + di) < GRID_COLS && (hand_row + dj) < GRID_ROWS)
                                canvas[hand_col + di][hand_row + dj] <= 1'b1;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Live cursor — 5x5 pixel red dot centered on hand centroid
    // Written using addition to avoid unsigned underflow on subtraction
    // -----------------------------------------------------------------------
    wire cursor_on = detected &&
                     (vga_x + 10'd2 >= overlay_x) && (overlay_x + 10'd2 >= vga_x) &&
                     (vga_y + 10'd2 >= overlay_y) && (overlay_y + 10'd2 >= vga_y);

    // -----------------------------------------------------------------------
    // Pixel renderer (combinational)
    //   Priority: painted trail > live cursor > background
    // -----------------------------------------------------------------------
    always @(*) begin
        if (canvas[pixel_col][pixel_row]) begin
            // Painted cell — white
            R_out = 10'h3FF;
            G_out = 10'h3FF;
            B_out = 10'h3FF;
        end else if (cursor_on) begin
            // Live cursor — red
            R_out = 10'h3FF;
            G_out = 10'h000;
            B_out = 10'h000;
        end else begin
            // Background — black
            R_out = 10'h000;
            G_out = 10'h000;
            B_out = 10'h000;
        end
    end

endmodule