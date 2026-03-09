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
    output [9:0] R_out,
    output [9:0] G_out,
    output [9:0] B_out
);

    parameter BOX_THICK = 10'd2;
    parameter DOT_R     = 10'd4;

    wire on_top;
    wire on_bottom;
    wire on_left;
    wire on_right;
    wire on_box;

    wire signed [10:0] dx;
    wire signed [10:0] dy;
    wire [21:0] dist2;
    wire on_dot;

    assign on_top =
        (vga_y >= box_top) && (vga_y < box_top + BOX_THICK) &&
        (vga_x >= box_left) && (vga_x <= box_right);

    assign on_bottom =
        (vga_y <= box_bottom) && (vga_y > box_bottom - BOX_THICK) &&
        (vga_x >= box_left) && (vga_x <= box_right);

    assign on_left =
        (vga_x >= box_left) && (vga_x < box_left + BOX_THICK) &&
        (vga_y >= box_top) && (vga_y <= box_bottom);

    assign on_right =
        (vga_x <= box_right) && (vga_x > box_right - BOX_THICK) &&
        (vga_y >= box_top) && (vga_y <= box_bottom);

    assign on_box = on_top || on_bottom || on_left || on_right;

    assign dx = $signed({1'b0, vga_x}) - $signed({1'b0, hand_x});
    assign dy = $signed({1'b0, vga_y}) - $signed({1'b0, hand_y});

    assign dist2 = dx*dx + dy*dy;
    assign on_dot = (dist2 <= (DOT_R * DOT_R));

    assign R_out = (detected && (on_box || on_dot)) ? 10'h3FF : R_in;
    assign G_out = (detected && (on_box || on_dot)) ? 10'h3FF : G_in;
    assign B_out = (detected && (on_box || on_dot)) ? 10'h3FF : B_in;

endmodule