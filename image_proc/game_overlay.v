module game_overlay (
    input  [9:0] vga_x,
    input  [9:0] vga_y,
    input  [9:0] hand_x,
    input  [9:0] hand_y,
    input        detected,
    output [9:0] R_out,
    output [9:0] G_out,
    output [9:0] B_out
);

    // 5x5 white dot centered at hand_x, hand_y
    wire dot_on;

    assign dot_on =
        detected &&
        (vga_x >= (hand_x - 10'd2)) && (vga_x <= (hand_x + 10'd2)) &&
        (vga_y >= (hand_y - 10'd2)) && (vga_y <= (hand_y + 10'd2));

    assign R_out = dot_on ? 10'h3FF : 10'd0;
    assign G_out = dot_on ? 10'h3FF : 10'd0;
    assign B_out = dot_on ? 10'h3FF : 10'd0;

endmodule