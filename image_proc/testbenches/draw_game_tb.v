`timescale 1ns/1ps

module draw_game_tb;

    // DUT inputs
    reg         clk;
    reg         rst_n;
    reg         vsync;
    reg         detected;
    reg  [9:0]  overlay_x;
    reg  [9:0]  overlay_y;
    reg  [9:0]  vga_x;
    reg  [9:0]  vga_y;
    reg         clear_n;
    reg         pen_down;
    reg  [1:0]  brush_size;

    // DUT outputs
    wire [9:0]  R_out;
    wire [9:0]  G_out;
    wire [9:0]  B_out;

    // Instantiate DUT
    draw_game dut (
        .clk(clk),
        .rst_n(rst_n),
        .vsync(vsync),
        .detected(detected),
        .overlay_x(overlay_x),
        .overlay_y(overlay_y),
        .vga_x(vga_x),
        .vga_y(vga_y),
        .clear_n(clear_n),
        .pen_down(pen_down),
        .brush_size(brush_size),
        .R_out(R_out),
        .G_out(G_out),
        .B_out(B_out)
    );

    // ------------------------------------------------------------
    // Clock: 25 MHz
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #20 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Frame helper: create one vsync falling edge
    // ------------------------------------------------------------
    task do_frame;
    begin
        vsync = 1'b1;
        repeat (2) @(posedge clk);

        vsync = 1'b0;
        repeat (2) @(posedge clk);

        vsync = 1'b1;
        repeat (2) @(posedge clk);
    end
    endtask

    // ------------------------------------------------------------
    // Hold hand in start box
    // ------------------------------------------------------------
    task hold_in_start_box;
        input integer frames;
        integer k;
    begin
        detected  = 1'b1;
        overlay_x = 10'd320;
        overlay_y = 10'd240;
        for (k = 0; k < frames; k = k + 1)
            do_frame();
    end
    endtask

    // ------------------------------------------------------------
    // Clear hand
    // ------------------------------------------------------------
    task clear_hand;
    begin
        detected  = 1'b0;
        overlay_x = 10'd0;
        overlay_y = 10'd0;
    end
    endtask

    // ------------------------------------------------------------
    // Simple checker
    // ------------------------------------------------------------
    task expect_eq;
        input [255:0] msg;
        input integer actual;
        input integer expected;
    begin
        if (actual !== expected) begin
            $display("FAIL: %0s | actual=%0d expected=%0d at t=%0t",
                     msg, actual, expected, $time);
            $stop;
        end else begin
            $display("PASS: %0s | value=%0d at t=%0t", msg, actual, $time);
        end
    end
    endtask

    // ------------------------------------------------------------
    // Check a canvas cell
    // ------------------------------------------------------------
    task expect_canvas;
        input [255:0] msg;
        input integer col;
        input integer row;
        input integer expected;
    begin
        if (dut.canvas[col][row] !== expected) begin
            $display("FAIL: %0s | canvas[%0d][%0d]=%0d expected=%0d at t=%0t",
                     msg, col, row, dut.canvas[col][row], expected, $time);
            $stop;
        end else begin
            $display("PASS: %0s | canvas[%0d][%0d]=%0d at t=%0t",
                     msg, col, row, dut.canvas[col][row], $time);
        end
    end
    endtask

    // ------------------------------------------------------------
    // Wait until Bresenham engine finishes
    // ------------------------------------------------------------
    task wait_line_done;
        integer timeout;
    begin
        timeout = 0;
        while (dut.line_state != dut.LINE_IDLE && timeout < 500) begin
            @(posedge clk);
            timeout = timeout + 1;
        end

        if (timeout >= 500) begin
            $display("FAIL: line drawing engine did not return to IDLE");
            $stop;
        end
    end
    endtask

    // ------------------------------------------------------------
    // Optional VGA raster movement
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            vga_x <= 10'd0;
            vga_y <= 10'd0;
        end else begin
            if (vga_x == 10'd639) begin
                vga_x <= 10'd0;
                if (vga_y == 10'd479)
                    vga_y <= 10'd0;
                else
                    vga_y <= vga_y + 10'd1;
            end else begin
                vga_x <= vga_x + 10'd1;
            end
        end
    end

    // ------------------------------------------------------------
    // Main stimulus
    // ------------------------------------------------------------
    initial begin
        integer c, r;

        $display("=== draw_game testbench start ===");

        // Initial values
        rst_n      = 1'b0;
        vsync      = 1'b1;
        detected   = 1'b0;
        overlay_x  = 10'd0;
        overlay_y  = 10'd0;
        vga_x      = 10'd0;
        vga_y      = 10'd0;
        clear_n    = 1'b1;
        pen_down   = 1'b0;
        brush_size = 2'd0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // --------------------------------------------------------
        // 1) Reset checks
        // --------------------------------------------------------
        expect_eq("game_active after reset should be 0", dut.game_active, 0);
        expect_eq("start_hold_count after reset should be 0", dut.start_hold_count, 0);
        expect_eq("prev_pen_valid after reset should be 0", dut.prev_pen_valid, 0);
        expect_eq("line_state after reset should be LINE_IDLE", dut.line_state, 0);

        expect_canvas("canvas cleared on reset", 0, 0, 0);
        expect_canvas("canvas cleared on reset", 10, 10, 0);
        expect_canvas("canvas cleared on reset", 79, 59, 0);

        // --------------------------------------------------------
        // 2) Must arm start first
        // --------------------------------------------------------
        clear_hand();
        do_frame();
        expect_eq("start_armed should become 1 after no-hand frame", dut.start_armed, 1);

        // --------------------------------------------------------
        // 3) Hold in start box for 120 frames -> game_active
        // --------------------------------------------------------
        hold_in_start_box(120);
        expect_eq("game_active should become 1 after hold-to-start", dut.game_active, 1);

        // --------------------------------------------------------
        // 4) pen_up should not paint anything
        // hand_col = overlay_x[9:3], hand_row = overlay_y[9:3]
        // choose (80,40) => grid cell (10,5)
        // --------------------------------------------------------
        detected   = 1'b1;
        pen_down   = 1'b0;
        brush_size = 2'd0;
        overlay_x  = 10'd80;
        overlay_y  = 10'd40;

        do_frame();

        expect_canvas("pen up should not paint cell", 10, 5, 0);
        expect_eq("prev_pen_valid remains 0 when pen is up", dut.prev_pen_valid, 0);

        // --------------------------------------------------------
        // 5) pen_down small brush paints 1x1
        // --------------------------------------------------------
        pen_down   = 1'b1;
        brush_size = 2'd0;   // span = 1
        overlay_x  = 10'd80; // col 10
        overlay_y  = 10'd40; // row 5

        do_frame();

        expect_canvas("small brush paints origin cell", 10, 5, 1);
        expect_canvas("small brush does not paint neighboring cell", 11, 5, 0);
        expect_eq("prev_pen_valid set after pen down", dut.prev_pen_valid, 1);
        expect_eq("prev_col captured", dut.prev_col, 10);
        expect_eq("prev_row captured", dut.prev_row, 5);

        // --------------------------------------------------------
        // 6) medium brush paints 2x2
        // use cell (20,10) => pixel (160,80)
        // --------------------------------------------------------
        overlay_x  = 10'd160; // col 20
        overlay_y  = 10'd80;  // row 10
        brush_size = 2'd1;    // span = 2
        pen_down   = 1'b1;

        // Since move is large enough, line engine may also paint path.
        do_frame();
        wait_line_done();

        expect_canvas("medium brush paints (20,10)", 20, 10, 1);
        expect_canvas("medium brush paints (21,10)", 21, 10, 1);
        expect_canvas("medium brush paints (20,11)", 20, 11, 1);
        expect_canvas("medium brush paints (21,11)", 21, 11, 1);

        // --------------------------------------------------------
        // 7) large brush paints 4x4
        // use cell (30,15) => pixel (240,120)
        // --------------------------------------------------------
        overlay_x  = 10'd240; // col 30
        overlay_y  = 10'd120; // row 15
        brush_size = 2'd2;    // span = 4
        pen_down   = 1'b1;

        do_frame();
        wait_line_done();

        expect_canvas("large brush paints (30,15)", 30, 15, 1);
        expect_canvas("large brush paints (31,15)", 31, 15, 1);
        expect_canvas("large brush paints (32,16)", 32, 16, 1);
        expect_canvas("large brush paints (33,18)", 33, 18, 1);

        // --------------------------------------------------------
        // 8) Small movement below MIN_MOVE should not start line engine
        // MIN_MOVE = 2 cells. Move by only 1 cell.
        // --------------------------------------------------------
        brush_size = 2'd0;
        overlay_x  = 10'd80;  // col 10
        overlay_y  = 10'd80;  // row 10
        pen_down   = 1'b1;
        do_frame();

        overlay_x  = 10'd88;  // col 11
        overlay_y  = 10'd80;  // row 10, dx = 1
        do_frame();

        expect_eq("small move should not start line engine", dut.line_state, 0);

        // --------------------------------------------------------
        // 9) Large move should trigger Bresenham interpolation
        // Draw horizontal line from (10,10) to (14,10)
        // --------------------------------------------------------
        // First point
        overlay_x  = 10'd80;   // col 10
        overlay_y  = 10'd80;   // row 10
        pen_down   = 1'b1;
        brush_size = 2'd0;
        do_frame();

        // Second point far enough away
        overlay_x  = 10'd112;  // col 14
        overlay_y  = 10'd80;   // row 10
        do_frame();

        // Line engine should now run and fill intermediate cells
        wait_line_done();

        expect_canvas("line includes start cell", 10, 10, 1);
        expect_canvas("line includes intermediate cell 11,10", 11, 10, 1);
        expect_canvas("line includes intermediate cell 12,10", 12, 10, 1);
        expect_canvas("line includes intermediate cell 13,10", 13, 10, 1);
        expect_canvas("line includes end cell 14,10", 14, 10, 1);

        // --------------------------------------------------------
        // 10) Pen lift resets prev_pen_valid and stops line state
        // --------------------------------------------------------
        pen_down = 1'b0;
        do_frame();

        expect_eq("pen lift clears prev_pen_valid", dut.prev_pen_valid, 0);
        expect_eq("pen lift forces line_state to IDLE", dut.line_state, 0);

        // --------------------------------------------------------
        // 11) clear_n low should wipe canvas and return to start screen
        // --------------------------------------------------------
        clear_n = 1'b0;
        repeat (3) @(posedge clk);
        clear_n = 1'b1;
        repeat (2) @(posedge clk);

        expect_eq("clear should deactivate game", dut.game_active, 0);
        expect_eq("clear should reset hold count", dut.start_hold_count, 0);
        expect_eq("clear should reset prev_pen_valid", dut.prev_pen_valid, 0);
        expect_eq("clear should reset line_state", dut.line_state, 0);

        expect_canvas("clear wipes painted cell 10,5", 10, 5, 0);
        expect_canvas("clear wipes painted cell 20,10", 20, 10, 0);
        expect_canvas("clear wipes painted cell 30,15", 30, 15, 0);
        expect_canvas("clear wipes painted line cell 12,10", 12, 10, 0);

        $display("=== ALL TESTS PASSED ===");
        $finish;
    end

endmodule