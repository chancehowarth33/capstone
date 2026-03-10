module color_detect (
    input        clk,
    input        rst_n,
    input        vsync,
    input        active,
    input        calibrate,
    input        capture_btn_n,   // connect to KEY[1], active-low
    input  [9:0] R,
    input  [9:0] G,
    input  [9:0] B,
    input  [9:0] vga_x,
    input  [9:0] vga_y,
    output reg [9:0] hand_x,
    output reg [9:0] hand_y,
    output reg [9:0] box_left,
    output reg [9:0] box_right,
    output reg [9:0] box_top,
    output reg [9:0] box_bottom,
    output reg       detected,
    output reg [9:0] center_avgR,
    output reg [9:0] center_avgG,
    output reg [9:0] center_avgB
);

    parameter NUM_BLOCK_COLS   = 20;
    parameter MIN_MATCH_BLOCKS = 2;

    // tolerance around captured calibration RGB
    parameter TOL_R = 10'd80;
    parameter TOL_G = 10'd80;
    parameter TOL_B = 10'd80;

    integer i;

    wire [4:0] block_col;
    wire [3:0] block_row;
    wire       end_of_block;
    wire       is_center_block;

    wire [9:0] block_center_x;
    wire [9:0] block_center_y;
    wire [9:0] block_left_w;
    wire [9:0] block_right_w;
    wire [9:0] block_top_w;
    wire [9:0] block_bottom_w;

    reg        vsync_prev;
    wire       vsync_fall;

    reg        capture_prev;
    wire       capture_fall;
    reg        capture_pending;

    reg [19:0] sum_R [0:NUM_BLOCK_COLS-1];
    reg [19:0] sum_G [0:NUM_BLOCK_COLS-1];
    reg [19:0] sum_B [0:NUM_BLOCK_COLS-1];

    reg [15:0] centroid_sum_x;
    reg [15:0] centroid_sum_y;
    reg [7:0]  match_count;

    reg [9:0] frame_min_x;
    reg [9:0] frame_max_x;
    reg [9:0] frame_min_y;
    reg [9:0] frame_max_y;

    // stored calibrated reference color
    reg [9:0] cal_R;
    reg [9:0] cal_G;
    reg [9:0] cal_B;
    reg       cal_valid;

    wire [19:0] cur_sum_R;
    wire [19:0] cur_sum_G;
    wire [19:0] cur_sum_B;

    wire [19:0] next_sum_R;
    wire [19:0] next_sum_G;
    wire [19:0] next_sum_B;

    wire [9:0] avgR;
    wire [9:0] avgG;
    wire [9:0] avgB;

    wire [9:0] diffR;
    wire [9:0] diffG;
    wire [9:0] diffB;
    wire       color_match;

    assign block_col       = vga_x[9:5];
    assign block_row       = vga_y[8:5];
    assign end_of_block    = (vga_x[4:0] == 5'd31) && (vga_y[4:0] == 5'd31);
    assign is_center_block = (block_col == 5'd10) && (block_row == 4'd7);

    assign block_center_x  = {block_col, 5'd16};
    assign block_center_y  = {block_row, 5'd16};

    assign block_left_w    = {block_col, 5'd0};
    assign block_right_w   = {block_col, 5'd31};
    assign block_top_w     = {block_row, 5'd0};
    assign block_bottom_w  = {block_row, 5'd31};

    assign vsync_fall      = vsync_prev && !vsync;
    assign capture_fall    = capture_prev && !capture_btn_n;

    assign cur_sum_R       = sum_R[block_col];
    assign cur_sum_G       = sum_G[block_col];
    assign cur_sum_B       = sum_B[block_col];

    assign next_sum_R      = cur_sum_R + R;
    assign next_sum_G      = cur_sum_G + G;
    assign next_sum_B      = cur_sum_B + B;

    assign avgR            = next_sum_R[19:10];
    assign avgG            = next_sum_G[19:10];
    assign avgB            = next_sum_B[19:10];

    assign diffR = (avgR >= cal_R) ? (avgR - cal_R) : (cal_R - avgR);
    assign diffG = (avgG >= cal_G) ? (avgG - cal_G) : (cal_G - avgG);
    assign diffB = (avgB >= cal_B) ? (avgB - cal_B) : (cal_B - avgB);

    assign color_match = cal_valid &&
                         (diffR <= TOL_R) &&
                         (diffG <= TOL_G) &&
                         (diffB <= TOL_B);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hand_x         <= 10'd0;
            hand_y         <= 10'd0;
            box_left       <= 10'd0;
            box_right      <= 10'd0;
            box_top        <= 10'd0;
            box_bottom     <= 10'd0;
            detected       <= 1'b0;

            center_avgR    <= 10'd0;
            center_avgG    <= 10'd0;
            center_avgB    <= 10'd0;

            centroid_sum_x <= 16'd0;
            centroid_sum_y <= 16'd0;
            match_count    <= 8'd0;

            frame_min_x    <= 10'd639;
            frame_max_x    <= 10'd0;
            frame_min_y    <= 10'd479;
            frame_max_y    <= 10'd0;

            vsync_prev     <= 1'b0;
            capture_prev   <= 1'b1;
            capture_pending<= 1'b0;

            cal_R          <= 10'd0;
            cal_G          <= 10'd0;
            cal_B          <= 10'd0;
            cal_valid      <= 1'b0;

            for (i = 0; i < NUM_BLOCK_COLS; i = i + 1) begin
                sum_R[i] <= 20'd0;
                sum_G[i] <= 20'd0;
                sum_B[i] <= 20'd0;
            end
        end
        else begin
            vsync_prev   <= vsync;
            capture_prev <= capture_btn_n;

            // if button pressed during calibration mode, arm a capture.
            // actual capture happens when the center block completes.
            if (calibrate && capture_fall)
                capture_pending <= 1'b1;

            if (vsync_fall) begin
                if (!calibrate && (match_count >= MIN_MATCH_BLOCKS)) begin
                    detected   <= 1'b1;
                    hand_x     <= centroid_sum_x / match_count;
                    hand_y     <= centroid_sum_y / match_count;
                    box_left   <= frame_min_x;
                    box_right  <= frame_max_x;
                    box_top    <= frame_min_y;
                    box_bottom <= frame_max_y;
                end
                else begin
                    detected   <= 1'b0;
                    hand_x     <= 10'd0;
                    hand_y     <= 10'd0;
                    box_left   <= 10'd0;
                    box_right  <= 10'd0;
                    box_top    <= 10'd0;
                    box_bottom <= 10'd0;
                end

                centroid_sum_x <= 16'd0;
                centroid_sum_y <= 16'd0;
                match_count    <= 8'd0;

                frame_min_x    <= 10'd639;
                frame_max_x    <= 10'd0;
                frame_min_y    <= 10'd479;
                frame_max_y    <= 10'd0;

                for (i = 0; i < NUM_BLOCK_COLS; i = i + 1) begin
                    sum_R[i] <= 20'd0;
                    sum_G[i] <= 20'd0;
                    sum_B[i] <= 20'd0;
                end
            end
            else if (active) begin
                sum_R[block_col] <= next_sum_R;
                sum_G[block_col] <= next_sum_G;
                sum_B[block_col] <= next_sum_B;

                if (end_of_block) begin
                    // Always expose live center-box RGB for HEX display
                    if (is_center_block) begin
                        center_avgR <= avgR;
                        center_avgG <= avgG;
                        center_avgB <= avgB;

                        // If capture requested during calibration mode,
                        // save this center block as the new reference color.
                        if (calibrate && capture_pending) begin
                            cal_R           <= avgR;
                            cal_G           <= avgG;
                            cal_B           <= avgB;
                            cal_valid       <= 1'b1;
                            capture_pending <= 1'b0;
                        end
                    end

                    // Only track in normal mode
                    if (!calibrate && color_match) begin
                        centroid_sum_x <= centroid_sum_x + block_center_x;
                        centroid_sum_y <= centroid_sum_y + block_center_y;
                        match_count    <= match_count + 8'd1;

                        if (block_left_w < frame_min_x)
                            frame_min_x <= block_left_w;
                        if (block_right_w > frame_max_x)
                            frame_max_x <= block_right_w;
                        if (block_top_w < frame_min_y)
                            frame_min_y <= block_top_w;
                        if (block_bottom_w > frame_max_y)
                            frame_max_y <= block_bottom_w;
                    end

                    sum_R[block_col] <= 20'd0;
                    sum_G[block_col] <= 20'd0;
                    sum_B[block_col] <= 20'd0;
                end
            end
        end
    end

endmodule