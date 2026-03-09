module overlay (
    input  [9:0] R_in,
    input  [9:0] G_in,
    input  [9:0] B_in,
    input  [9:0] vga_x,
    input  [9:0] vga_y,
    input  [9:0] hand_x,
    input  [9:0] hand_y,
    input        detected,
    output [9:0] R_out,
    output [9:0] G_out,
    output [9:0] B_out
);

    parameter HALF_W = 10'd24;
    parameter HALF_H = 10'd24;
    parameter THICK  = 10'd2;

    wire [9:0] left_x;
    wire [9:0] right_x;
    wire [9:0] top_y;
    wire [9:0] bot_y;

    wire on_top;
    wire on_bottom;
    wire on_left;
    wire on_right;
    wire on_box;

    assign left_x  = hand_x - HALF_W;
    assign right_x = hand_x + HALF_W;
    assign top_y   = hand_y - HALF_H;
    assign bot_y   = hand_y + HALF_H;

    assign on_top =
        (vga_y >= top_y) && (vga_y < top_y + THICK) &&
        (vga_x >= left_x) && (vga_x <= right_x);

    assign on_bottom =
        (vga_y <= bot_y) && (vga_y > bot_y - THICK) &&
        (vga_x >= left_x) && (vga_x <= right_x);

    assign on_left =
        (vga_x >= left_x) && (vga_x < left_x + THICK) &&
        (vga_y >= top_y) && (vga_y <= bot_y);

    assign on_right =
        (vga_x <= right_x) && (vga_x > right_x - THICK) &&
        (vga_y >= top_y) && (vga_y <= bot_y);

    assign on_box = detected && (on_top || on_bottom || on_left || on_right);

    assign R_out = on_box ? 10'h3FF : R_in;
    assign G_out = on_box ? 10'h3FF : G_in;
    assign B_out = on_box ? 10'h3FF : B_in;

endmodule