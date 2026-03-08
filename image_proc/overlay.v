// overlay.v
// Draws a crosshair and filled dot at the detected hand centroid.
// All other pixels pass through unchanged from the camera feed.
// When no hand is detected, the camera feed passes through unmodified.

module overlay (
    input  [9:0] R_in, G_in, B_in,  // pixel from VGA_Controller (camera feed)
    input  [9:0] vga_x, vga_y,       // current scan position
    input  [9:0] hand_x, hand_y,     // centroid from color_detect
    input        detected,            // if low, passthrough only
    output reg [9:0] R_out, G_out, B_out
);

    // Crosshair: 1-pixel-thick horizontal and vertical lines
    wire on_h_line = (vga_y >= hand_y - 10'd1) && (vga_y <= hand_y + 10'd1);
    wire on_v_line = (vga_x >= hand_x - 10'd1) && (vga_x <= hand_x + 10'd1);

    // Filled red dot at the centroid center (±6 pixels)
    wire on_dot = (vga_x >= hand_x - 10'd6) && (vga_x <= hand_x + 10'd6)
               && (vga_y >= hand_y - 10'd6) && (vga_y <= hand_y + 10'd6);

    always @(*) begin
        if (!detected) begin
            // No detection — show camera feed unmodified
            R_out = R_in;
            G_out = G_in;
            B_out = B_in;
        end else if (on_dot) begin
            // Solid red dot at centroid
            R_out = 10'h3FF;
            G_out = 10'h000;
            B_out = 10'h000;
        end else if (on_h_line || on_v_line) begin
            // White crosshair lines
            R_out = 10'h3FF;
            G_out = 10'h3FF;
            B_out = 10'h3FF;
        end else begin
            // Normal camera passthrough
            R_out = R_in;
            G_out = G_in;
            B_out = B_in;
        end
    end

endmodule