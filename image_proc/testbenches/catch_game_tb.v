`timescale 1ns/1ps

module catch_game_tb;

    // DUT inputs
    reg         clk;
    reg         rst_n;
    reg         vsync;
    reg         detected;
    reg  [9:0]  overlay_x;
    reg  [9:0]  overlay_y;
    reg  [9:0]  vga_x;
    reg  [9:0]  vga_y;

    // DUT outputs
    wire [9:0]  R_out;
    wire [9:0]  G_out;
    wire [9:0]  B_out;

    // Instantiate DUT
    catch_game dut (
        .clk(clk),
        .rst_n(rst_n),
        .vsync(vsync),
        .detected(detected),
        .overlay_x(overlay_x),
        .overlay_y(overlay_y),
        .vga_x(vga_x),
        .vga_y(vga_y),
        .R_out(R_out),
        .G_out(G_out),
        .B_out(B_out)
    );

    // ------------------------------------------------------------
    // Clock generation: 25 MHz => 40 ns period
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #20 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Helper: generate one falling edge of vsync
    // DUT updates on vsync_fall = vsync_prev && !vsync
    // ------------------------------------------------------------
    task do_frame;
    begin
        // Keep vsync high for a bit
        vsync = 1'b1;
        repeat (2) @(posedge clk);

        // Falling edge
        vsync = 1'b0;
        repeat (2) @(posedge clk);

        // Return high
        vsync = 1'b1;
        repeat (2) @(posedge clk);
    end
    endtask

    // ------------------------------------------------------------
    // Helper: hold hand in start box for N frames
    // Centre box is around (320,240)
    // ------------------------------------------------------------
    task hold_in_start_box;
        input integer frames;
        integer i;
    begin
        detected  = 1'b1;
        overlay_x = 10'd320;
        overlay_y = 10'd240;
        for (i = 0; i < frames; i = i + 1)
            do_frame();
    end
    endtask

    // ------------------------------------------------------------
    // Helper: move hand away / undetected
    // ------------------------------------------------------------
    task clear_hand;
    begin
        detected  = 1'b0;
        overlay_x = 10'd0;
        overlay_y = 10'd0;
    end
    endtask

    // ------------------------------------------------------------
    // Helper: basic check
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
    // Optional simple raster stimulus so combinational renderer
    // isn't left with X-ish coordinates
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
        $display("=== catch_game testbench start ===");

        // Initial values
        rst_n      = 1'b0;
        vsync      = 1'b1;
        detected   = 1'b0;
        overlay_x  = 10'd0;
        overlay_y  = 10'd0;
        vga_x      = 10'd0;
        vga_y      = 10'd0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // --------------------------------------------------------
        // 1) Reset checks
        // --------------------------------------------------------
        expect_eq("state after reset should be IDLE", dut.state, 0);
        expect_eq("score after reset should be 0", dut.score, 0);
        expect_eq("lives after reset should be 3", dut.lives, 3);
        expect_eq("paddle_center after reset should be 320", dut.paddle_center, 320);

        // --------------------------------------------------------
        // 2) Must arm start by first not being detected / not in box
        // --------------------------------------------------------
        clear_hand();
        do_frame();
        expect_eq("start_armed should become 1 after idle frame with no hand", dut.start_armed, 1);

        // --------------------------------------------------------
        // 3) Hold in start box for 120 frames -> enter PLAYING
        // --------------------------------------------------------
        hold_in_start_box(120);

        expect_eq("state should become PLAYING after hold-to-start", dut.state, 1);
        expect_eq("score should reset to 0 on game start", dut.score, 0);
        expect_eq("lives should reset to 3 on game start", dut.lives, 3);
        expect_eq("obj_y should respawn at top on game start", dut.obj_y, 0);

        // --------------------------------------------------------
        // 4) Paddle follows hand while playing
        // --------------------------------------------------------
        detected  = 1'b1;
        overlay_x = 10'd100;
        overlay_y = 10'd300;
        repeat (2) @(posedge clk);
        expect_eq("paddle should track overlay_x in PLAYING", dut.paddle_center, 100);

        // Clamp left
        overlay_x = 10'd10;
        repeat (2) @(posedge clk);
        expect_eq("paddle should clamp at left edge to 32", dut.paddle_center, 32);

        // Clamp right
        overlay_x = 10'd639;
        repeat (2) @(posedge clk);
        expect_eq("paddle should clamp at right edge to 607", dut.paddle_center, 607);

        // --------------------------------------------------------
        // 5) Coin catch increments score and respawns object
        // Force internal state so collision happens on next frame
        // --------------------------------------------------------
        dut.obj_type       = 1'b0;      // coin
        dut.obj_x          = 10'd300;
        dut.obj_y          = 10'd438;   // within catch window
        dut.paddle_center  = 10'd320;

        do_frame();

        expect_eq("coin catch should increment score", dut.score, 1);
        expect_eq("coin catch should keep state PLAYING", dut.state, 1);
        expect_eq("coin catch should respawn object at top", dut.obj_y, 0);
        expect_eq("coin catch should not change lives", dut.lives, 3);

        // --------------------------------------------------------
        // 6) Coin miss should decrement lives and respawn
        // --------------------------------------------------------
        dut.obj_type       = 1'b0;      // coin
        dut.obj_y          = 10'd481;   // missed
        dut.obj_x          = 10'd0;
        dut.paddle_center  = 10'd320;
        dut.lives          = 3;

        do_frame();

        expect_eq("coin miss should decrement lives", dut.lives, 2);
        expect_eq("coin miss should stay in PLAYING while lives remain", dut.state, 1);
        expect_eq("coin miss should respawn object at top", dut.obj_y, 0);

        // --------------------------------------------------------
        // 7) Missing final coin should enter GAMEOVER
        // --------------------------------------------------------
        dut.obj_type = 1'b0;
        dut.obj_y    = 10'd481;
        dut.lives    = 1;

        do_frame();

        expect_eq("last missed coin should set lives to 0", dut.lives, 0);
        expect_eq("last missed coin should enter GAMEOVER", dut.state, 2);
        expect_eq("game_over_count reset on GAMEOVER entry", dut.game_over_count, 0);

        // --------------------------------------------------------
        // 8) GAMEOVER lasts 180 frames then returns to IDLE
        // --------------------------------------------------------
        repeat (180) do_frame();

        expect_eq("after GAMEOVER timeout state should return to IDLE", dut.state, 0);
        expect_eq("game_over_count should reset after return to IDLE", dut.game_over_count, 0);

        // Re-arm and start again for bomb test
        clear_hand();
        do_frame();
        hold_in_start_box(120);
        expect_eq("state should re-enter PLAYING", dut.state, 1);

        // --------------------------------------------------------
        // 9) Bomb catch should instantly game over
        // --------------------------------------------------------
        dut.obj_type      = 1'b1;      // bomb
        dut.obj_x         = 10'd300;
        dut.obj_y         = 10'd438;   // within catch window
        dut.paddle_center = 10'd320;
        dut.lives         = 3;

        do_frame();

        expect_eq("bomb catch should set lives to 0", dut.lives, 0);
        expect_eq("bomb catch should enter GAMEOVER", dut.state, 2);

        $display("=== ALL TESTS PASSED ===");
        $finish;
    end

endmodule