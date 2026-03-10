module overlay (
    input  [9:0] R_in,
    input  [9:0] G_in,
    input  [9:0] B_in,
    input  [9:0] vga_x,
    input  [9:0] vga_y,
    input  [9:0] hand_x,
    input  [9:0] hand_y,
    input  [9:0] box_left,
    input  [9:0] box_right,
    input  [9:0] box_top,
    input  [9:0] box_bottom,
    input        detected,
    input        calibrate,
    output [9:0] R_out,
    output [9:0] G_out,
    output [9:0] B_out
);

    parameter THICK = 10'd2;

    // Center 32x32 calibration box:
    // x = 304..335
    // y = 224..255
    wire [9:0] cal_left   = 10'd304;
    wire [9:0] cal_right  = 10'd335;
    wire [9:0] cal_top    = 10'd224;
    wire [9:0] cal_bottom = 10'd255;

    wire cal_on_top;
    wire cal_on_bottom;
    wire cal_on_left;
    wire cal_on_right;
    wire cal_box_on;

    wire trk_on_top;
    wire trk_on_bottom;
    wire trk_on_left;
    wire trk_on_right;
    wire trk_box_on;

    // Calibration box
    assign cal_on_top =
        (vga_y >= cal_top) && (vga_y < cal_top + THICK) &&
        (vga_x >= cal_left) && (vga_x <= cal_right);

    assign cal_on_bottom =
        (vga_y <= cal_bottom) && (vga_y > cal_bottom - THICK) &&
        (vga_x >= cal_left) && (vga_x <= cal_right);

    assign cal_on_left =
        (vga_x >= cal_left) && (vga_x < cal_left + THICK) &&
        (vga_y >= cal_top) && (vga_y <= cal_bottom);

    assign cal_on_right =
        (vga_x <= cal_right) && (vga_x > cal_right - THICK) &&
        (vga_y >= cal_top) && (vga_y <= cal_bottom);

    assign cal_box_on = cal_on_top || cal_on_bottom || cal_on_left || cal_on_right;

    // Tracking box
    assign trk_on_top =
        (vga_y >= box_top) && (vga_y < box_top + THICK) &&
        (vga_x >= box_left) && (vga_x <= box_right);

    assign trk_on_bottom =
        (vga_y <= box_bottom) && (vga_y > box_bottom - THICK) &&
        (vga_x >= box_left) && (vga_x <= box_right);

    assign trk_on_left =
        (vga_x >= box_left) && (vga_x < box_left + THICK) &&
        (vga_y >= box_top) && (vga_y <= box_bottom);

    assign trk_on_right =
        (vga_x <= box_right) && (vga_x > box_right - THICK) &&
        (vga_y >= box_top) && (vga_y <= box_bottom);

    assign trk_box_on = detected && (trk_on_top || trk_on_bottom || trk_on_left || trk_on_right);

    assign R_out = (calibrate ? cal_box_on : trk_box_on) ? 10'h3FF : R_in;
    assign G_out = (calibrate ? cal_box_on : trk_box_on) ? 10'h3FF : G_in;
    assign B_out = (calibrate ? cal_box_on : trk_box_on) ? 10'h3FF : B_in;

endmodule