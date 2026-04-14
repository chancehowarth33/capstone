// draw_game.v
// Sketchpad-style drawing game.
//
// The screen is divided into the same 20x15 grid of 32x32 cells that
// color_detect uses.  When the hand is detected, the cell under the
// hand centroid is marked as painted on every vsync falling edge.
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
    output reg [9:0]  R_out,
    output reg [9:0]  G_out,
    output reg [9:0]  B_out
);

    localparam GRID_COLS = 20;
    localparam GRID_ROWS = 15;

    // -----------------------------------------------------------------------
    // Canvas — one bit per 32x32 grid cell
    // -----------------------------------------------------------------------
    reg canvas [0:GRID_COLS-1][0:GRID_ROWS-1];

    // Grid cell of the hand centroid (divide pixel coords by 32)
    wire [4:0] hand_col = overlay_x[9:5];
    wire [4:0] hand_row = overlay_y[9:5];

    // Grid cell of the current VGA scan pixel
    wire [4:0] pixel_col = vga_x[9:5];
    wire [4:0] pixel_row = vga_y[9:5];

    // -----------------------------------------------------------------------
    // vsync falling-edge detect (matches color_detect convention)
    // -----------------------------------------------------------------------
    reg vsync_prev;
    wire vsync_fall = vsync_prev && !vsync;

    integer i, j;

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
            end else if (vsync_fall && detected) begin
                // Paint the cell the hand is currently over
                canvas[hand_col][hand_row] <= 1'b1;
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