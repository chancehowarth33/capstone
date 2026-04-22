`timescale 1ns/1ps

module pong_game_tb;

    // DUT inputs
    reg         clk;
    reg         rst_n;
    reg         vsync;

    reg  [9:0]  p1_x;
    reg  [9:0]  p1_y;
    reg  [9:0]  p2_x;
    reg  [9:0]  p2_y;
    reg         p1_detected;
    reg         p2_detected;

    reg  [9:0]  vga_x;
    reg  [9:0]  vga_y;

    // DUT outputs
    wire [9:0]  R_out;
    wire [9:0]  G_out;
    wire [9:0]  B_out;

    // Instantiate DUT
    pong_game dut (
        .clk(clk),
        .rst_n(rst_n),
        .vsync(vsync),
        .p1_x(p1_x),
        .p1_y(p1_y),
        .p2_x(p2_x),
        .p2_y(p2_y),
        .p1_detected(p1_detected),
        .p2_detected(p2_detected),
        .vga_x(vga_x),
        .vga_y(vga_y),
        .R_out(R_out),
        .G_out(G_out),
        .B_out(B_out)
    );

    // ------------------------------------------------------------
    // Clock generation: 25 MHz
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #20 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Generate one frame boundary (vsync falling edge)
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
    // Hold P1 hand in start box for N frames
    // ------------------------------------------------------------
    task hold_p1_in_start_box;
        input integer frames;
        integer i;
    begin
        p1_detected = 1'b1;
        p1_x        = 10'd320;
        p1_y        = 10'd240;
        for (i = 0; i < frames; i = i + 1)
            do_frame();
    end
    endtask

    // ------------------------------------------------------------
    // Simple equality checker
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
    // Optional raster movement for combinational renderer
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
        $display("=== pong_game testbench start ===");

        // Initial values
        rst_n       = 1'b0;
        vsync       = 1'b1;
        p1_x        = 10'd0;
        p1_y        = 10'd0;
        p2_x        = 10'd0;
        p2_y        = 10'd0;
        p1_detected = 1'b0;
        p2_detected = 1'b0;
        vga_x       = 10'd0;
        vga_y       = 10'd0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // --------------------------------------------------------
        // 1) Reset checks
        // --------------------------------------------------------
        expect_eq("state after reset should be S_IDLE", dut.state, 0);
        expect_eq("ball_x after reset should be centered", dut.ball_x, 316); // (640-8)/2
        expect_eq("ball_y after reset should be centered", dut.ball_y, 236); // (480-8)/2
        expect_eq("score1 after reset should be 0", dut.score1, 0);
        expect_eq("score2 after reset should be 0", dut.score2, 0);
        expect_eq("cur_speed after reset should be 3", dut.cur_speed, 3);
        expect_eq("paddle1_y after reset", dut.paddle1_y, 210); // (480-60)/2
        expect_eq("paddle2_y after reset", dut.paddle2_y, 210);

        // --------------------------------------------------------
        // 2) Start arming logic
        // --------------------------------------------------------
        p1_detected = 1'b0;
        do_frame();
        expect_eq("start_armed should become 1 after not in start box", dut.start_armed, 1);

        // --------------------------------------------------------
        // 3) Hold P1 in start box for 120 frames -> enter PLAY
        // --------------------------------------------------------
        hold_p1_in_start_box(120);

        expect_eq("state should become S_PLAY after hold-to-start", dut.state, 1);
        expect_eq("score1 reset on start", dut.score1, 0);
        expect_eq("score2 reset on start", dut.score2, 0);
        expect_eq("ball_x reset on start", dut.ball_x, 316);
        expect_eq("ball_y reset on start", dut.ball_y, 236);
        expect_eq("ball_vx reset on start", dut.ball_vx, 3);
        expect_eq("ball_vy reset on start", dut.ball_vy, 2);
        expect_eq("cur_speed reset on start", dut.cur_speed, 3);

        // --------------------------------------------------------
        // 4) Paddle tracking / remapping / clamping while in PLAY
        // CAM_Y_MIN=60, CAM_Y_MAX=420
        // p?_yf = ((clamped_y - 60) * 3) >> 1
        // --------------------------------------------------------

        // P1 clamp low
        p1_detected = 1'b1;
        p1_y        = 10'd0;
        repeat (2) @(posedge clk);
        expect_eq("paddle1 clamps to top", dut.paddle1_y, 0);

        // P1 clamp high
        p1_y = 10'd500;
        repeat (2) @(posedge clk);
        expect_eq("paddle1 clamps to bottom", dut.paddle1_y, 420);

        // P1 mapped mid example: y=200
        // (200-60)*3 >> 1 = 210, paddle = 210-30 = 180
        p1_y = 10'd200;
        repeat (2) @(posedge clk);
        expect_eq("paddle1 mapped position", dut.paddle1_y, 180);

        // P2 mapped mid example
        p2_detected = 1'b1;
        p2_y        = 10'd200;
        repeat (2) @(posedge clk);
        expect_eq("paddle2 mapped position", dut.paddle2_y, 180);

        // --------------------------------------------------------
        // 5) Ball top wall bounce
        // Need ball_y <= 4 and vy < 0
        // --------------------------------------------------------
        dut.ball_y  = 10'd4;
        dut.ball_vy = -5'sd2;
        do_frame();
        expect_eq("top wall should flip vy positive", dut.ball_vy, 2);

        // --------------------------------------------------------
        // 6) Ball bottom wall bounce
        // Need ball_y + BALL_H >= SCREEN_H - 4, so y+8 >= 476 -> y >= 468
        // --------------------------------------------------------
        dut.ball_y  = 10'd468;
        dut.ball_vy = 5'sd2;
        do_frame();
        expect_eq("bottom wall should flip vy negative", dut.ball_vy, -2);

        // --------------------------------------------------------
        // 7) P1 paddle collision should flip vx positive and increase speed
        // P1 paddle x-range [16..24), collision checks around it
        // --------------------------------------------------------
        dut.paddle1_y = 10'd200;
        dut.ball_x    = 10'd20;
        dut.ball_y    = 10'd220;
        dut.ball_vx   = -5'sd3;
        dut.cur_speed = 3'd3;

        do_frame();

        expect_eq("P1 hit should send ball right", dut.ball_vx, 3);
        expect_eq("P1 hit should increase cur_speed", dut.cur_speed, 4);

        // --------------------------------------------------------
        // 8) P2 paddle collision should flip vx negative and increase speed
        // P2 paddle x-range [616..624)
        // --------------------------------------------------------
        dut.paddle2_y = 10'd200;
        dut.ball_x    = 10'd616;
        dut.ball_y    = 10'd220;
        dut.ball_vx   = 5'sd3;
        dut.cur_speed = 3'd4;

        do_frame();

        expect_eq("P2 hit should send ball left", dut.ball_vx, -4);
        expect_eq("P2 hit should increase cur_speed", dut.cur_speed, 5);

        // --------------------------------------------------------
        // 9) P2 scores when ball exits left
        // --------------------------------------------------------
        dut.score2    = 4'd0;
        dut.ball_x    = 10'd2;
        dut.ball_vx   = -5'sd3;
        dut.vy_flip   = 1'b0;
        dut.cur_speed = 3'd6;

        do_frame();

        expect_eq("P2 score increments on left exit", dut.score2, 1);
        expect_eq("ball resets to center after P2 score", dut.ball_x, 316);
        expect_eq("ball_y resets to center after P2 score", dut.ball_y, 236);
        expect_eq("ball_vx resets positive after P2 score", dut.ball_vx, 3);
        expect_eq("ball_vy resets using vy_flip", dut.ball_vy, 2);
        expect_eq("cur_speed resets after score", dut.cur_speed, 3);
        expect_eq("vy_flip toggles after score", dut.vy_flip, 1);

        // --------------------------------------------------------
        // 10) P1 scores when ball exits right
        // Need ball_x + 8 >= 638 -> choose 630
        // --------------------------------------------------------
        dut.score1    = 4'd0;
        dut.ball_x    = 10'd630;
        dut.ball_vx   = 5'sd3;
        dut.vy_flip   = 1'b1;
        dut.cur_speed = 3'd7;

        do_frame();

        expect_eq("P1 score increments on right exit", dut.score1, 1);
        expect_eq("ball resets to center after P1 score", dut.ball_x, 316);
        expect_eq("ball_y resets to center after P1 score", dut.ball_y, 236);
        expect_eq("ball_vx resets negative after P1 score", dut.ball_vx, -3);
        expect_eq("ball_vy resets using vy_flip", dut.ball_vy, -2);
        expect_eq("cur_speed resets after score", dut.cur_speed, 3);
        expect_eq("vy_flip toggles after score", dut.vy_flip, 0);

        // --------------------------------------------------------
        // 11) P2 winning score transitions to S_WIN
        // --------------------------------------------------------
        dut.score2 = 4'd8;
        dut.ball_x = 10'd2;
        dut.ball_vx = -5'sd3;

        do_frame();

        expect_eq("P2 reaches win score", dut.score2, 9);
        expect_eq("state should go to S_WIN when P2 wins", dut.state, 2);
        expect_eq("winner should indicate P2", dut.winner, 1);
        expect_eq("win_count reset on entry to S_WIN", dut.win_count, 0);

        // --------------------------------------------------------
        // 12) Win screen timeout returns to IDLE and clears scores
        // --------------------------------------------------------
        repeat (240) do_frame();

        expect_eq("after WIN timeout state returns to S_IDLE", dut.state, 0);
        expect_eq("win_count resets after WIN screen", dut.win_count, 0);
        expect_eq("score1 cleared after WIN screen", dut.score1, 0);
        expect_eq("score2 cleared after WIN screen", dut.score2, 0);

        // Re-enter PLAY for P1 win case
        p1_detected = 1'b0;
        do_frame();
        hold_p1_in_start_box(120);
        expect_eq("state should re-enter S_PLAY", dut.state, 1);

        // --------------------------------------------------------
        // 13) P1 winning score transitions to S_WIN
        // --------------------------------------------------------
        dut.score1 = 4'd8;
        dut.ball_x = 10'd630;
        dut.ball_vx = 5'sd3;

        do_frame();

        expect_eq("P1 reaches win score", dut.score1, 9);
        expect_eq("state should go to S_WIN when P1 wins", dut.state, 2);
        expect_eq("winner should indicate P1", dut.winner, 0);

        $display("=== ALL TESTS PASSED ===");
        $finish;
    end

endmodule