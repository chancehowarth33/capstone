module color_detect (
    input        clk,
    input        rst_n,
    input        vsync,
    input        active,
    input  [9:0] R,
    input  [9:0] G,
    input  [9:0] B,
    input  [9:0] vga_x,
    input  [9:0] vga_y,
    output reg [9:0] hand_x,
    output reg [9:0] hand_y,
    output reg       detected,
    output reg [9:0] dbg_avgR,
    output reg [9:0] dbg_avgG,
    output reg [9:0] dbg_avgB,
    output reg [7:0] dbg_count
);

    parameter NUM_BLOCK_COLS = 20;
    parameter MIN_MATCH_BLOCKS = 2;

    integer i;

    wire [4:0] block_col;
    wire [3:0] block_row;
    wire       end_of_block;

    reg        vsync_prev;
    wire       vsync_fall;

    reg [19:0] sum_R [0:NUM_BLOCK_COLS-1];
    reg [19:0] sum_G [0:NUM_BLOCK_COLS-1];
    reg [19:0] sum_B [0:NUM_BLOCK_COLS-1];

    reg        frame_detected;
    reg [7:0]  frame_count;

    wire [19:0] cur_sum_R;
    wire [19:0] cur_sum_G;
    wire [19:0] cur_sum_B;

    wire [19:0] next_sum_R;
    wire [19:0] next_sum_G;
    wire [19:0] next_sum_B;

    wire [9:0] avgR;
    wire [9:0] avgG;
    wire [9:0] avgB;

    assign block_col    = vga_x[9:5];
    assign block_row    = vga_y[8:5];
    assign end_of_block = (vga_x[4:0] == 5'd31) && (vga_y[4:0] == 5'd31);

    assign vsync_fall = vsync_prev && !vsync;

    assign cur_sum_R = sum_R[block_col];
    assign cur_sum_G = sum_G[block_col];
    assign cur_sum_B = sum_B[block_col];

    assign next_sum_R = cur_sum_R + R;
    assign next_sum_G = cur_sum_G + G;
    assign next_sum_B = cur_sum_B + B;

    assign avgR = next_sum_R[19:10];
    assign avgG = next_sum_G[19:10];
    assign avgB = next_sum_B[19:10];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hand_x         <= 10'd0;
            hand_y         <= 10'd0;
            detected       <= 1'b0;
            dbg_avgR       <= 10'd0;
            dbg_avgG       <= 10'd0;
            dbg_avgB       <= 10'd0;
            dbg_count      <= 8'd0;
            frame_detected <= 1'b0;
            frame_count    <= 8'd0;
            vsync_prev     <= 1'b0;

            for (i = 0; i < NUM_BLOCK_COLS; i = i + 1) begin
                sum_R[i] <= 20'd0;
                sum_G[i] <= 20'd0;
                sum_B[i] <= 20'd0;
            end
        end
        else begin
            vsync_prev <= vsync;

            if (vsync_fall) begin
                dbg_count <= frame_count;

                if (frame_count >= MIN_MATCH_BLOCKS) begin
                    detected <= 1'b1;
                end
                else begin
                    detected <= 1'b0;
                    hand_x   <= 10'd0;
                    hand_y   <= 10'd0;
                end

                frame_detected <= 1'b0;
                frame_count    <= 8'd0;

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
                    dbg_avgR <= avgR;
                    dbg_avgG <= avgG;
                    dbg_avgB <= avgB;

                    if ((avgR > 10'd350) &&
                        (avgR > (avgG + 10'd100)) &&
                        (avgB < 10'd300)) begin
                        hand_x         <= {block_col, 5'd16};
                        hand_y         <= {block_row, 5'd16};
                        frame_detected <= 1'b1;
                        frame_count    <= frame_count + 8'd1;
                    end

                    sum_R[block_col] <= 20'd0;
                    sum_G[block_col] <= 20'd0;
                    sum_B[block_col] <= 20'd0;
                end
            end
        end
    end

endmodule