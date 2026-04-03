module color_detect (
    input        clk,
    input        rst_n,
    input        fval,
    input        active,
    input        calibrate,
    input        capture_btn_n,   // KEY[1], active-low
    input  [9:0] R,
    input  [9:0] G,
    input  [9:0] B,
    input  [9:0] vga_x,
    input  [9:0] vga_y,

    // outputs
    output reg [9:0] overlay_x,
    output reg [9:0] overlay_y,
    output reg [9:0] coord_x,
    output reg [9:0] coord_y,

    output reg [9:0] box_left,
    output reg [9:0] box_right,
    output reg [9:0] box_top,
    output reg [9:0] box_bottom,

    output reg       detected,

    output reg [9:0] center_avgR,
    output reg [9:0] center_avgG,
    output reg [9:0] center_avgB,

    output reg [9:0] cal_sample_R,
    output reg [9:0] cal_sample_G,
    output reg [9:0] cal_sample_B,
    output reg       cal_valid
);

    parameter NUM_BLOCK_COLS   = 20;
    parameter MIN_MATCH_BLOCKS = 1;

    // tuned for orange object
    parameter TOL_R = 10'd60;
    parameter TOL_G = 10'd100;
    parameter TOL_B = 10'd120;

    integer i;

    //========================
    // block math (32x32)
    //========================
    wire [4:0] block_col = vga_x[9:5];
    wire [3:0] block_row = vga_y[8:5];

    wire end_of_block =
        (vga_x[4:0] == 5'd31) &&
        (vga_y[4:0] == 5'd31);

    wire is_center_block =
        (block_col == 5'd10) &&
        (block_row == 4'd7);

    wire [9:0] block_center_x = {block_col, 5'd16};
    wire [9:0] block_center_y = {block_row, 5'd16};

    wire [9:0] block_left_w   = {block_col, 5'd0};
    wire [9:0] block_right_w  = {block_col, 5'd31};
    wire [9:0] block_top_w    = {block_row, 5'd0};
    wire [9:0] block_bottom_w = {block_row, 5'd31};

    //========================
    // control
    //========================
    reg fval_prev;
    wire fval_fall = fval_prev && !fval;

    reg capture_prev;
    wire capture_fall = capture_prev && !capture_btn_n;

    reg capture_pending;

    //========================
    // accumulators
    //========================
    reg [19:0] sum_R [0:NUM_BLOCK_COLS-1];
    reg [19:0] sum_G [0:NUM_BLOCK_COLS-1];
    reg [19:0] sum_B [0:NUM_BLOCK_COLS-1];

    reg [15:0] centroid_sum_x;
    reg [15:0] centroid_sum_y;
    reg [10:0] match_count;

    reg [9:0] frame_min_x;
    reg [9:0] frame_max_x;
    reg [9:0] frame_min_y;
    reg [9:0] frame_max_y;

    // calibration reference
    reg [9:0] cal_R, cal_G, cal_B;

    //========================
    // math
    //========================
    wire [19:0] next_sum_R = sum_R[block_col] + R;
    wire [19:0] next_sum_G = sum_G[block_col] + G;
    wire [19:0] next_sum_B = sum_B[block_col] + B;

    wire [9:0] avgR = next_sum_R[19:10];
    wire [9:0] avgG = next_sum_G[19:10];
    wire [9:0] avgB = next_sum_B[19:10];

    wire [9:0] diffR = (avgR > cal_R) ? avgR - cal_R : cal_R - avgR;
    wire [9:0] diffG = (avgG > cal_G) ? avgG - cal_G : cal_G - avgG;
    wire [9:0] diffB = (avgB > cal_B) ? avgB - cal_B : cal_B - avgB;

    wire color_match =
        cal_valid &&
        (diffR <= TOL_R) &&
        (diffG <= TOL_G) &&
        (diffB <= TOL_B);

    wire [9:0] tracked_x = centroid_sum_x / match_count;
    wire [9:0] tracked_y = centroid_sum_y / match_count;

    //========================
    // main logic
    //========================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            overlay_x <= 0;
            overlay_y <= 0;
            coord_x   <= 0;
            coord_y   <= 0;
            detected  <= 0;

            cal_valid <= 0;
            capture_pending <= 0;

            for (i=0;i<NUM_BLOCK_COLS;i=i+1) begin
                sum_R[i] <= 0;
                sum_G[i] <= 0;
                sum_B[i] <= 0;
            end
        end else begin
            fval_prev   <= fval;
            capture_prev <= capture_btn_n;

            if (calibrate && capture_fall)
                capture_pending <= 1;

            //========================
            // frame end
            //========================
            if (fval_fall) begin
                if (!calibrate && match_count >= MIN_MATCH_BLOCKS) begin
                    detected  <= 1;

                    overlay_x <= tracked_x;
                    overlay_y <= tracked_y;

                    // mirrored for game
                    coord_x   <= 10'd639 - tracked_x;
                    coord_y   <= tracked_y;

                    box_left   <= frame_min_x;
                    box_right  <= frame_max_x;
                    box_top    <= frame_min_y;
                    box_bottom <= frame_max_y;
                end else begin
                    detected <= 0;
                end

                centroid_sum_x <= 0;
                centroid_sum_y <= 0;
                match_count    <= 0;

                frame_min_x <= 639;
                frame_max_x <= 0;
                frame_min_y <= 479;
                frame_max_y <= 0;

                for (i=0;i<NUM_BLOCK_COLS;i=i+1) begin
                    sum_R[i] <= 0;
                    sum_G[i] <= 0;
                    sum_B[i] <= 0;
                end
            end

            //========================
            // pixel accumulation
            //========================
            else if (active) begin
                sum_R[block_col] <= next_sum_R;
                sum_G[block_col] <= next_sum_G;
                sum_B[block_col] <= next_sum_B;

                if (end_of_block) begin

                    // calibration capture
                    if (is_center_block) begin
                        center_avgR <= avgR;
                        center_avgG <= avgG;
                        center_avgB <= avgB;

                        if (calibrate && capture_pending) begin
                            cal_R <= avgR;
                            cal_G <= avgG;
                            cal_B <= avgB;

                            cal_sample_R <= avgR;
                            cal_sample_G <= avgG;
                            cal_sample_B <= avgB;

                            cal_valid <= 1;
                            capture_pending <= 0;
                        end
                    end

                    // detection
                    if (!calibrate && color_match) begin
                        centroid_sum_x <= centroid_sum_x + block_center_x;
                        centroid_sum_y <= centroid_sum_y + block_center_y;
                        match_count    <= match_count + 1;

                        if (block_left_w < frame_min_x) frame_min_x <= block_left_w;
                        if (block_right_w > frame_max_x) frame_max_x <= block_right_w;
                        if (block_top_w < frame_min_y) frame_min_y <= block_top_w;
                        if (block_bottom_w > frame_max_y) frame_max_y <= block_bottom_w;
                    end

                    sum_R[block_col] <= 0;
                    sum_G[block_col] <= 0;
                    sum_B[block_col] <= 0;
                end
            end
        end
    end

endmodule