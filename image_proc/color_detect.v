// color_detect.v
// Accumulates matching pixel coordinates across a full VGA frame
// and outputs the centroid (hand_x, hand_y) once per frame.
//
// Color match targets a bright green object by default.
// Tune thresholds with the parameters below, or wire SW switches
// into the top level to adjust live without recompiling.

module color_detect (
    input        clk,
    input        vsync,      // VGA_VS — used to detect frame boundary
    input        active,     // high only during active display area
    input  [9:0] R,
    input  [9:0] G,
    input  [9:0] B,
    input  [9:0] vga_x,
    input  [9:0] vga_y,
    output reg [9:0] hand_x,
    output reg [9:0] hand_y,
    output reg       detected
);

    // Accumulators — wide enough for worst-case 640*480 sum
    reg [26:0] sum_x;
    reg [26:0] sum_y;
    reg [16:0] count;

    reg vsync_prev;
    // Falling edge of vsync = start of new frame blanking interval
    wire frame_start = !vsync && vsync_prev;

    // ---------------------------------------------------------------
    // Color match: Orange ball with RGB value of (255, 56, 0)
    wire match = active
          && (R > 10'd600)
          && (R > G + 10'd350)
          && (B < 10'd80);

    always @(posedge clk) begin
        vsync_prev <= vsync;

        if (frame_start) begin
            // Latch centroid if we detected enough pixels this frame.
            // count > 300 avoids reacting to noise/small specular highlights.
            if (count > 17'd300) begin
                // Divide by 512 via right-shift.
                // Works cleanly when count is in the hundreds-to-thousands range.
                hand_x   <= sum_x[26:17];
                hand_y   <= sum_y[26:17];
                detected <= 1'b1;
            end else begin
                detected <= 1'b0;
            end
            // Reset accumulators for next frame
            sum_x <= 27'd0;
            sum_y <= 27'd0;
            count <= 17'd0;
        end else if (match) begin
            sum_x <= sum_x + {17'd0, vga_x};
            sum_y <= sum_y + {17'd0, vga_y};
            count <= count + 17'd1;
        end
    end

endmodule