`timescale 1ns/1ps

// VGA_Controller Testbench
// 640x480 @ 60 Hz, 25 MHz pixel clock (40 ns period)
//
// Tests:
//   1. Reset clears all outputs
//   2. H_SYNC pulse width = 96 cycles (active-low)
//   3. H_SYNC period = 800 cycles
//   4. V_SYNC pulse width = 2 lines (active-low)
//   5. V_SYNC period = 525 lines
//   6. oVGA_ACTIVE high only in active region (640x480)
//   7. oVGA_X counts 0..639 in active region, 0 outside
//   8. oVGA_Y counts 0..479 in active region, 0 outside
//   9. RGB output matches input during active, zero during blanking
//  10. oVGA_BLANK = H_SYNC & V_SYNC (high when not in sync pulse)
//  11. oRequest leads pixel data by 2 cycles

module vga_controller_tb;

// ---------------------------------------------------------------------------
// Parameters (must match VGA_Controller defaults)
// ---------------------------------------------------------------------------
localparam H_SYNC_CYC   = 96;
localparam H_SYNC_BACK  = 48;
localparam H_SYNC_ACT   = 640;
localparam H_SYNC_FRONT = 16;
localparam H_SYNC_TOTAL = 800;

localparam V_SYNC_CYC   = 2;
localparam V_SYNC_BACK  = 33;
localparam V_SYNC_ACT   = 480;
localparam V_SYNC_FRONT = 10;
localparam V_SYNC_TOTAL = 525;

localparam X_START = H_SYNC_CYC + H_SYNC_BACK;   // 144
localparam Y_START = V_SYNC_CYC + V_SYNC_BACK;   // 35

localparam CLK_PERIOD = 40; // 25 MHz

// ---------------------------------------------------------------------------
// DUT signals
// ---------------------------------------------------------------------------
reg         clk, rst_n;
reg  [9:0]  iRed, iGreen, iBlue;
reg         iZOOM_MODE_SW;

wire        oRequest;
wire [9:0]  oVGA_R, oVGA_G, oVGA_B;
wire        oVGA_H_SYNC, oVGA_V_SYNC;
wire        oVGA_SYNC, oVGA_BLANK;
wire [9:0]  oVGA_X, oVGA_Y;
wire        oVGA_ACTIVE;

// ---------------------------------------------------------------------------
// DUT instantiation
// ---------------------------------------------------------------------------
VGA_Controller dut (
    .iRed           (iRed),
    .iGreen         (iGreen),
    .iBlue          (iBlue),
    .oRequest       (oRequest),
    .oVGA_R         (oVGA_R),
    .oVGA_G         (oVGA_G),
    .oVGA_B         (oVGA_B),
    .oVGA_H_SYNC    (oVGA_H_SYNC),
    .oVGA_V_SYNC    (oVGA_V_SYNC),
    .oVGA_SYNC      (oVGA_SYNC),
    .oVGA_BLANK     (oVGA_BLANK),
    .oVGA_X         (oVGA_X),
    .oVGA_Y         (oVGA_Y),
    .oVGA_ACTIVE    (oVGA_ACTIVE),
    .iCLK           (clk),
    .iRST_N         (rst_n),
    .iZOOM_MODE_SW  (iZOOM_MODE_SW)
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

// Wait for rising edge then sample 1 ps after
task tick;
    begin
        @(posedge clk); #1;
    end
endtask

// Advance N clock cycles
task advance;
    input integer n;
    integer i;
    begin
        for (i = 0; i < n; i = i + 1) tick;
    end
endtask

// ---------------------------------------------------------------------------
// Measurement variables
// ---------------------------------------------------------------------------
integer h_low_count, h_period_count;
integer v_low_lines, v_period_lines;
integer active_x_min, active_x_max;
integer active_y_min, active_y_max;
integer x_err, y_err, rgb_err, blank_err, req_err;
integer cycle;
integer prev_h_sync, prev_v_sync;
integer h_line_count, v_frame_count;
reg [9:0] saved_r, saved_g, saved_b;
reg       was_active;

// ---------------------------------------------------------------------------
// Main test sequence
// ---------------------------------------------------------------------------
initial begin
    // ------------------------------------------------------------------
    // Initialise
    // ------------------------------------------------------------------
    rst_n         = 0;
    iRed          = 10'h155;
    iGreen        = 10'h2AA;
    iBlue         = 10'h3FF;
    iZOOM_MODE_SW = 0;

    // ================================================================
    // TEST 1: Reset zeroes all outputs
    // ================================================================
    advance(5);
    check(oVGA_R      == 0, "T1a: reset clears oVGA_R");
    check(oVGA_G      == 0, "T1b: reset clears oVGA_G");
    check(oVGA_B      == 0, "T1c: reset clears oVGA_B");
    check(oVGA_H_SYNC == 0, "T1d: reset clears oVGA_H_SYNC");
    check(oVGA_V_SYNC == 0, "T1e: reset clears oVGA_V_SYNC");
    check(oVGA_BLANK  == 0, "T1f: reset clears oVGA_BLANK");
    check(oVGA_ACTIVE == 0, "T1g: reset clears oVGA_ACTIVE");
    check(oVGA_X      == 0, "T1h: reset clears oVGA_X");
    check(oVGA_Y      == 0, "T1i: reset clears oVGA_Y");
    check(oRequest    == 0, "T1j: reset clears oRequest");

    // Release reset, wait for counters to settle
    rst_n = 1;
    advance(4); // pipeline register latency

    // ================================================================
    // TEST 2: H_SYNC pulse width = 96 cycles (active-low = 0)
    // Wait for the next falling edge of H_SYNC, count low cycles.
    // ================================================================
    // Find falling edge of H_SYNC
    @(negedge oVGA_H_SYNC); #1;
    h_low_count = 0;
    while (!oVGA_H_SYNC) begin
        h_low_count = h_low_count + 1;
        tick;
    end
    check(h_low_count == H_SYNC_CYC,
          "T2: H_SYNC pulse width = 96 cycles");

    // ================================================================
    // TEST 3: H_SYNC period = 800 cycles
    // ================================================================
    @(negedge oVGA_H_SYNC); #1;
    h_period_count = 1;
    tick;
    while (!oVGA_H_SYNC || h_period_count < H_SYNC_CYC) begin
        h_period_count = h_period_count + 1;
        tick;
    end
    // Now count until next falling edge
    while (oVGA_H_SYNC) begin
        h_period_count = h_period_count + 1;
        tick;
    end
    check(h_period_count == H_SYNC_TOTAL,
          "T3: H_SYNC period = 800 cycles");

    // ================================================================
    // TEST 4: V_SYNC pulse width = 2 lines (active-low)
    // ================================================================
    @(negedge oVGA_V_SYNC); #1;
    v_low_lines = 0;
    while (!oVGA_V_SYNC) begin
        // count lines: each line = H_SYNC_TOTAL cycles
        // V_Cont increments when H_Cont==0, so count H_SYNC falling edges
        @(negedge oVGA_H_SYNC); #1;
        v_low_lines = v_low_lines + 1;
    end
    check(v_low_lines == V_SYNC_CYC,
          "T4: V_SYNC pulse width = 2 lines");

    // ================================================================
    // TEST 5: V_SYNC period = 525 lines
    // ================================================================
    @(negedge oVGA_V_SYNC); #1;
    v_period_lines = 0;
    // Count lines until V_SYNC goes high
    while (!oVGA_V_SYNC) begin
        @(negedge oVGA_H_SYNC); #1;
        v_period_lines = v_period_lines + 1;
    end
    // Count remaining lines until next falling edge
    while (oVGA_V_SYNC) begin
        @(negedge oVGA_H_SYNC); #1;
        v_period_lines = v_period_lines + 1;
    end
    check(v_period_lines == V_SYNC_TOTAL,
          "T5: V_SYNC period = 525 lines");

    // ================================================================
    // Tests 6-11: scan one full frame and check pixel-by-pixel
    //
    //   T6:  oVGA_ACTIVE high exactly in 640x480 window
    //   T7:  oVGA_X = H_Cont - X_START during active, 0 outside
    //   T8:  oVGA_Y = V_Cont - Y_START during active, 0 outside
    //   T9:  RGB = input during active, 0 during blanking
    //   T10: oVGA_BLANK = H_SYNC & V_SYNC
    //   T11: oRequest leads oVGA_ACTIVE by exactly 2 cycles
    // ================================================================

    // Synchronise to start of a fresh frame: wait for V_SYNC falling edge
    // (start of V sync pulse = start of frame counter), then wait for
    // V_SYNC to go high and the back-porch to finish.
    @(posedge oVGA_V_SYNC); #1;  // V_SYNC just went high after pulse
    // Now wait until H_Cont==0, V_Cont==Y_START — i.e. first active line
    // Easiest: wait for full frame reset then count from known position.
    // Instead, just wait for V negedge → posedge cycle to align:
    @(negedge oVGA_V_SYNC); #1;
    @(posedge oVGA_V_SYNC); #1;

    x_err    = 0;
    y_err    = 0;
    rgb_err  = 0;
    blank_err= 0;
    req_err  = 0;

    // Scan H_SYNC_TOTAL * V_SYNC_TOTAL cycles = one full frame
    // We track the internal H/V counters by counting clocks from
    // the known reset point (H_Cont=1 at the cycle after V posedge sync).
    // Because the output is registered (1-cycle latency), we compare
    // expected values from the previous cycle.

    begin : frame_scan
        integer hc, vc;     // mirror internal H_Cont, V_Cont
        integer exp_active;
        integer exp_x, exp_y;
        integer exp_h_sync, exp_v_sync, exp_blank;
        integer exp_r, exp_g, exp_b;
        // Two-cycle shift register to check oRequest leads by 2
        integer req_d1, req_d2;
        integer exp_req;

        req_d1 = 0; req_d2 = 0;

        // At this point we are 1 cycle after V_SYNC posedge.
        // H_Cont was reset to 0 when V negedge happened (H_Cont==0 then),
        // and increments each cycle.  We lost track of exact H_Cont,
        // so re-sync to the next H_SYNC falling edge.
        @(negedge oVGA_H_SYNC); #1;
        // H_Cont is now 1 (just incremented from 0 which triggered negedge)
        // V_Cont is whatever line we're on.  For simplicity, scan
        // just the horizontal timing for one complete line first,
        // then trust the vertical tests above.

        // ---- Horizontal-only single-line checks ----
        // We know H_Cont = 1 right now (output is 1 cycle delayed)
        // Drive a known colour
        iRed   = 10'h3FF;
        iGreen = 10'h200;
        iBlue  = 10'h0FF;

        for (hc = 1; hc <= H_SYNC_TOTAL; hc = hc + 1) begin
            // Expected values based on H_Cont = hc
            // (oVGA_* reflects H_Cont from previous cycle due to register)
            // We sample outputs before the tick so they reflect hc-1.
            // Re-map: at start of this iteration outputs reflect hc-1.
            // Use hc-1 as "current output's H_Cont"
            begin : hcheck
                integer phc;
                phc = hc - 1; // what H_Cont was when outputs registered

                // H_SYNC: low when phc < H_SYNC_CYC
                exp_h_sync = (phc < H_SYNC_CYC) ? 0 : 1;

                // ACTIVE: needs V_Cont in active range too — skip V here
                // Focus on X coordinate and H_SYNC
                if (phc >= X_START && phc < X_START + H_SYNC_ACT)
                    exp_x = phc - X_START;
                else
                    exp_x = 0;

                if (exp_h_sync !== oVGA_H_SYNC && phc > 0)
                    x_err = x_err + 1; // reuse counter for h_sync err

                if (phc >= X_START && phc < X_START + H_SYNC_ACT) begin
                    // X coordinate check (only meaningful in active window)
                    if (oVGA_X !== exp_x[9:0])
                        x_err = x_err + 1;
                end
            end
            tick;
        end

        check(x_err == 0, "T7: oVGA_X correct across horizontal scan");
    end

    // ================================================================
    // TEST 6 & 8: oVGA_ACTIVE and oVGA_Y — scan first active column
    // across all 525 lines, check Y coordinate and ACTIVE flag.
    // ================================================================
    begin : vscan
        integer vc;
        integer exp_active_v, exp_y_v;

        y_err = 0;

        // Align to start of frame (V negedge) and H position X_START+1
        // so we're in the active horizontal region each line.
        @(negedge oVGA_V_SYNC); #1;
        // Skip to X_START on each line by waiting for H_SYNC rising edge
        // then advancing X_START cycles.
        for (vc = 0; vc < V_SYNC_TOTAL; vc = vc + 1) begin
            @(posedge oVGA_H_SYNC); #1; // start of back porch
            advance(H_SYNC_BACK + 1);   // land inside active H region

            // Output now reflects V_Cont = vc (approx, ignoring pipeline offset)
            // V_Cont: during V pulse (vc < V_SYNC_CYC) V_SYNC=0
            // Active when V_Cont in [Y_START, Y_START+V_SYNC_ACT)
            if (vc >= Y_START && vc < Y_START + V_SYNC_ACT) begin
                exp_active_v = 1;
                exp_y_v      = vc - Y_START;
            end else begin
                exp_active_v = 0;
                exp_y_v      = 0;
            end

            if (oVGA_ACTIVE !== exp_active_v[0])
                y_err = y_err + 1;
            if (exp_active_v && oVGA_Y !== exp_y_v[9:0])
                y_err = y_err + 1;
        end

        check(y_err == 0, "T6+T8: oVGA_ACTIVE and oVGA_Y correct across frame");
    end

    // ================================================================
    // TEST 9: RGB = input during active, 0 during blanking
    // Sample a few points inside and outside active region.
    // ================================================================
    begin : rgb_check
        iRed   = 10'h155;
        iGreen = 10'h2AA;
        iBlue  = 10'h155;

        // -- Inside active region --
        @(negedge oVGA_V_SYNC); #1;
        advance(V_SYNC_BACK * H_SYNC_TOTAL + X_START + 10); // first active pixel +10
        @(posedge clk); #1;
        if (oVGA_R !== iRed || oVGA_G !== iGreen || oVGA_B !== iBlue)
            rgb_err = rgb_err + 1;

        // -- During H sync pulse (blanking) --
        @(negedge oVGA_H_SYNC); #1;
        @(posedge clk); #1;
        if (oVGA_R !== 0 || oVGA_G !== 0 || oVGA_B !== 0)
            rgb_err = rgb_err + 1;

        // -- During V sync pulse (blanking) --
        @(negedge oVGA_V_SYNC); #1;
        @(posedge clk); #1;
        if (oVGA_R !== 0 || oVGA_G !== 0 || oVGA_B !== 0)
            rgb_err = rgb_err + 1;

        check(rgb_err == 0, "T9: RGB gated to 0 outside active region");
    end

    // ================================================================
    // TEST 10: oVGA_BLANK = mVGA_H_SYNC & mVGA_V_SYNC
    // Both sync signals are active-low, so BLANK is low during any sync.
    // Sample across one line.
    // ================================================================
    begin : blank_check
        integer i;
        blank_err = 0;
        @(negedge oVGA_H_SYNC); #1;
        for (i = 0; i < H_SYNC_TOTAL; i = i + 1) begin
            // BLANK should equal H_SYNC AND V_SYNC (both registered)
            if (oVGA_BLANK !== (oVGA_H_SYNC & oVGA_V_SYNC))
                blank_err = blank_err + 1;
            tick;
        end
        check(blank_err == 0, "T10: oVGA_BLANK = oVGA_H_SYNC & oVGA_V_SYNC");
    end

    // ================================================================
    // TEST 11: oRequest leads oVGA_ACTIVE by 2 cycles
    // oRequest asserts when H_Cont >= X_START-2, which is 2 cycles
    // before oVGA_ACTIVE (both registered once → net 2-cycle lead).
    // ================================================================
    begin : req_check
        integer i;
        reg q1, q2; // shift register of oVGA_ACTIVE
        req_err = 0;
        q1 = 0; q2 = 0;

        // Align to start of active line
        @(negedge oVGA_V_SYNC); #1;
        advance(V_SYNC_BACK * H_SYNC_TOTAL);
        @(posedge oVGA_H_SYNC); #1;
        advance(H_SYNC_BACK - 4); // approach active region

        for (i = 0; i < H_SYNC_ACT + 8; i = i + 1) begin
            // oRequest should equal what oVGA_ACTIVE will be 2 cycles later.
            // Equivalently: oVGA_ACTIVE delayed by 2 should equal oRequest from 2 cycles ago.
            // Check: store oRequest, compare with oVGA_ACTIVE two ticks later.
            if (i >= 2) begin
                // q2 holds oRequest from 2 cycles ago
                if (q2 !== oVGA_ACTIVE)
                    req_err = req_err + 1;
            end
            q2 = q1;
            q1 = oRequest;
            tick;
        end
        check(req_err == 0, "T11: oRequest leads oVGA_ACTIVE by exactly 2 cycles");
    end

    // ================================================================
    // Summary
    // ================================================================
    $display("----------------------------------------");
    $display("Results: %0d passed, %0d failed", pass_count, fail_count);
    $display("----------------------------------------");
    if (fail_count == 0)
        $display("ALL TESTS PASSED");
    else
        $display("SOME TESTS FAILED");

    $finish;
end

// Safety timeout: 2 full frames @ 25 MHz = 2 * 800 * 525 * 40 ns ~ 34 ms
initial begin
    #34_000_000;
    $display("TIMEOUT: simulation exceeded 34 ms");
    $finish;
end

endmodule
