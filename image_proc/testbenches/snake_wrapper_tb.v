`timescale 1ns/1ps

// snake_wrapper Testbench
//
// Tests:
//   1.  RGB outputs are 0 while rst_n=0
//   2.  rst_n polarity inversion (ap_rst = ~rst_n) — module runs after de-assert
//   3.  Snake head cell is white after reset (col=10, row=7)
//   4.  Food cell is red after reset (col=5, row=5)
//   5.  Background cell is black
//   6.  coord in top-left quadrant (x<320, y<240) → UP movement
//   7.  coord in bottom-right quadrant (x>=320, y>=240) → DOWN movement
//   8.  coord in top-right quadrant (x>=320, y<240) → RIGHT movement
//   9.  coord in bottom-left quadrant (x<320, y>=240) → LEFT movement
//   10. detected=0 suppresses direction update
//   11. Horizontal wrap: snake at col=0 moves left → reappears at col=19

module snake_wrapper_tb;

// ---------------------------------------------------------------------------
// Game constants — must match simple_snake.h
// ---------------------------------------------------------------------------
localparam GRID_COLS = 20;
localparam GRID_ROWS = 15;
localparam CELL_SIZE = 32;
localparam INIT_COL  = 10;
localparam INIT_ROW  = 7;
localparam SPEED_DIV = 15;  // vsync falling edges per snake step

// Initial food position (set in simple_snake.cpp reset block)
localparam FOOD_COL  = 5;
localparam FOOD_ROW  = 5;

// Color constants (10-bit VGA)
localparam [9:0] WHITE = 10'd1023;
localparam [9:0] BLACK = 10'd0;

// HLS FSM settle time in cycles (synthesis latency reported as 14)
localparam FSM_SETTLE = 25;

localparam CLK_PERIOD = 40; // 25 MHz pixel clock

// ---------------------------------------------------------------------------
// DUT signals
// ---------------------------------------------------------------------------
reg        clk, rst_n;
reg  [9:0] coord_x, coord_y;
reg        detected;
reg  [9:0] vga_x, vga_y;
reg        vsync;

wire [9:0] R_out, G_out, B_out;

// ---------------------------------------------------------------------------
// DUT
// ---------------------------------------------------------------------------
snake_wrapper dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .coord_x  (coord_x),
    .coord_y  (coord_y),
    .detected (detected),
    .vga_x    (vga_x),
    .vga_y    (vga_y),
    .vsync    (vsync),
    .R_out    (R_out),
    .G_out    (G_out),
    .B_out    (B_out)
);

// ---------------------------------------------------------------------------
// Clock
// ---------------------------------------------------------------------------
initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------
integer pass_count = 0;
integer fail_count = 0;

task check;
    input       condition;
    input [255:0] test_name;
    begin
        if (condition) begin
            $display("PASS: %s", test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: %s  (time=%0t)", test_name, $time);
            fail_count = fail_count + 1;
        end
    end
endtask

task advance;
    input integer n;
    integer i;
    begin
        for (i = 0; i < n; i = i + 1) begin
            @(posedge clk); #1;
        end
    end
endtask

// Simulate one vsync pulse (high → low → high).
// The snake game detects the falling edge (vsync_prev=1, vsync=0).
// Hold vsync low long enough for the edge to be registered, then
// wait FSM_SETTLE cycles for game state to update.
task do_vsync;
    begin
        vsync = 1; advance(3);   // ensure vsync_prev latches as 1
        vsync = 0; advance(3);   // falling edge detected here
        vsync = 1; advance(FSM_SETTLE);
    end
endtask

// Advance exactly SPEED_DIV vsync pulses to trigger one snake step
task advance_one_move;
    integer i;
    begin
        for (i = 0; i < SPEED_DIV; i = i + 1)
            do_vsync;
    end
endtask

// Point vga_x/vga_y at the center pixel of a grid cell, then wait for
// the FSM to settle and check the RGB output.
task check_pixel;
    input integer cell_col;
    input integer cell_row;
    input [9:0]   exp_r, exp_g, exp_b;
    input [255:0] test_name;
    begin
        vga_x = (cell_col * CELL_SIZE) + (CELL_SIZE / 2);
        vga_y = (cell_row * CELL_SIZE) + (CELL_SIZE / 2);
        advance(FSM_SETTLE);
        check(R_out == exp_r && G_out == exp_g && B_out == exp_b, test_name);
    end
endtask

// ---------------------------------------------------------------------------
// Main test sequence
// ---------------------------------------------------------------------------
initial begin
    // Initialise all inputs
    rst_n    = 0;
    coord_x  = 10'd0;
    coord_y  = 10'd0;
    detected = 1'b0;
    vga_x    = 10'd0;
    vga_y    = 10'd0;
    vsync    = 1'b1;

    // ==================================================================
    // TEST 1: RGB all zero during reset
    // ==================================================================
    advance(10);
    check(R_out == 0 && G_out == 0 && B_out == 0,
          "T1: RGB all 0 while rst_n=0");

    // ==================================================================
    // TEST 2: rst_n polarity — wrapper drives ap_rst = ~rst_n
    // After de-asserting reset the module should run; confirm background
    // (0,0) is black (not stuck at reset output).
    // ==================================================================
    rst_n = 1;
    advance(50); // let FSM complete its init pass

    check_pixel(0, 0, BLACK, BLACK, BLACK,
                "T2: rst_n de-asserted - module running (background is black)");

    // ==================================================================
    // TEST 3: Snake head cell is white after reset
    // Initial head: INIT_COL=10, INIT_ROW=7  →  pixels [320..351, 224..255]
    // ==================================================================
    check_pixel(INIT_COL, INIT_ROW, WHITE, WHITE, WHITE,
                "T3: Snake head cell white after reset");

    // ==================================================================
    // TEST 4: Food cell is red after reset
    // Initial food: col=5, row=5  →  pixels [160..191, 160..191]
    // ==================================================================
    check_pixel(FOOD_COL, FOOD_ROW, WHITE, BLACK, BLACK,
                "T4: Food cell red after reset");

    // ==================================================================
    // TEST 5: Arbitrary background cell is black
    // ==================================================================
    check_pixel(0, 0, BLACK, BLACK, BLACK,
                "T5: Background cell is black");

    // ==================================================================
    // TEST 6: top-left quadrant (x<320, y<240) → DIR_UP
    // Snake head at (10,7); after one move it should be at (10,6).
    // ==================================================================
    coord_x  = 10'd100; // left half
    coord_y  = 10'd100; // top half
    detected = 1'b1;
    advance_one_move;

    check_pixel(INIT_COL, INIT_ROW - 1, WHITE, WHITE, WHITE,
                "T6a: UP - head moved to row 6");
    check_pixel(INIT_COL, INIT_ROW, BLACK, BLACK, BLACK,
                "T6b: UP - previous row 7 now empty");

    // ==================================================================
    // TEST 7: bottom-right quadrant (x>=320, y>=240) → DIR_DOWN
    // Snake at (10,6); should move back to (10,7).
    // ==================================================================
    coord_x  = 10'd400; // right half
    coord_y  = 10'd300; // bottom half
    detected = 1'b1;
    advance_one_move;

    check_pixel(INIT_COL, INIT_ROW, WHITE, WHITE, WHITE,
                "T7a: DOWN - head moved to row 7");
    check_pixel(INIT_COL, INIT_ROW - 1, BLACK, BLACK, BLACK,
                "T7b: DOWN - row 6 now empty");

    // ==================================================================
    // TEST 8: top-right quadrant (x>=320, y<240) → DIR_RIGHT
    // Snake at (10,7); should move to (11,7).
    // ==================================================================
    coord_x  = 10'd400; // right half
    coord_y  = 10'd100; // top half
    detected = 1'b1;
    advance_one_move;

    check_pixel(INIT_COL + 1, INIT_ROW, WHITE, WHITE, WHITE,
                "T8a: RIGHT - head moved to col 11");
    check_pixel(INIT_COL, INIT_ROW, BLACK, BLACK, BLACK,
                "T8b: RIGHT - col 10 now empty");

    // ==================================================================
    // TEST 9: bottom-left quadrant (x<320, y>=240) → DIR_LEFT
    // Snake at (11,7); should move back to (10,7).
    // ==================================================================
    coord_x  = 10'd100; // left half
    coord_y  = 10'd300; // bottom half
    detected = 1'b1;
    advance_one_move;

    check_pixel(INIT_COL, INIT_ROW, WHITE, WHITE, WHITE,
                "T9a: LEFT - head moved to col 10");
    check_pixel(INIT_COL + 1, INIT_ROW, BLACK, BLACK, BLACK,
                "T9b: LEFT - col 11 now empty");

    // ==================================================================
    // TEST 10: detected=0 suppresses direction update
    // coord is top-left (→ UP if detected), but detected=0 so direction
    // stays LEFT from T9. Snake should move left to col=9.
    // ==================================================================
    coord_x  = 10'd100; // would be UP
    coord_y  = 10'd100;
    detected = 1'b0;    // NOT detected
    advance_one_move;

    check_pixel(INIT_COL - 1, INIT_ROW, WHITE, WHITE, WHITE,
                "T10a: detected=0 - direction unchanged, moved left to col 9");
    check_pixel(INIT_COL, INIT_ROW, BLACK, BLACK, BLACK,
                "T10b: detected=0 - col 10 now empty");

    // ==================================================================
    // TEST 11: Horizontal wrap — LEFT from col=0 reappears at col=19
    // Snake is currently at (9,7). Move left 9 more times to reach col=0,
    // then one more step to wrap.
    // ==================================================================
    coord_x  = 10'd100; // keep LEFT
    coord_y  = 10'd300;
    detected = 1'b1;

    // 9 moves: col 9 → 8 → 7 → 6 → 5 → 4 → 3 → 2 → 1 → 0
    // (Note: col=5 is food column; snake does not eat it because row=7 ≠ food row=5)
    repeat(9) advance_one_move;

    check_pixel(0, INIT_ROW, WHITE, WHITE, WHITE,
                "T11a: Snake at left edge (col=0)");

    // One more step: col=0 wraps to col=GRID_COLS-1=19
    advance_one_move;
    check_pixel(GRID_COLS - 1, INIT_ROW, WHITE, WHITE, WHITE,
                "T11b: Wrap - head appeared at col=19");
    check_pixel(0, INIT_ROW, BLACK, BLACK, BLACK,
                "T11c: Wrap - col=0 now empty");

    // ==================================================================
    // Summary
    // ==================================================================
    $display("----------------------------------------");
    $display("Results: %0d passed, %0d failed", pass_count, fail_count);
    $display("----------------------------------------");
    if (fail_count == 0)
        $display("ALL TESTS PASSED");
    else
        $display("SOME TESTS FAILED");

    $finish;
end

// Safety timeout (~10 ms)
initial begin
    #10_000_000;
    $display("TIMEOUT: simulation exceeded 10 ms");
    $finish;
end

endmodule
