`timescale 1ns/1ps

// Reset_Delay Testbench
//
// The module drives five staggered active-high resets from a saturating
// counter.  Each output goes high the clock cycle AFTER the counter first
// equals its threshold, because both the increment and the comparison use
// the OLD counter value (non-blocking assignments read current state).
//
//   Register    Threshold      First-high cycle# after reset release
//   oRST_0     0x001FFFFF  →  0x00200000 =  2,097,152
//   oRST_1     0x002FFFFF  →  0x00300000 =  3,145,728
//   oRST_2     0x011FFFFF  →  0x01200000 = 18,874,368
//   oRST_3     0x016FFFFF  →  0x01700000 = 24,117,248
//   oRST_4     0x01FFFFFF  →  0x02000000 = 33,554,432  (counter saturates here)
//
// Clock: 2 ns period (500 MHz) — keeps total simulation time under 100 ms.
// Total cycles needed: ~35.6 M (main run + one re-reset verification).
//
// Tests:
//   T1:  Active-low async reset clears all outputs immediately
//   T2:  All outputs still 0 immediately after reset release
//   T3:  oRST_0=0 one cycle before its threshold fires
//   T4:  oRST_0=1 at threshold cycle; oRST_1..4 still 0 (strict ordering)
//   T5:  oRST_1=0 one cycle before its threshold fires
//   T6:  oRST_1=1 at threshold cycle; oRST_2..4 still 0
//   T7:  oRST_2=0 one cycle before its threshold fires
//   T8:  oRST_2=1 at threshold cycle; oRST_3,4 still 0
//   T9:  oRST_3=0 one cycle before its threshold fires
//   T10: oRST_3=1 at threshold cycle; oRST_4 still 0
//   T11: oRST_4=0 one cycle before its threshold fires
//   T12: oRST_4=1 at threshold cycle; all five outputs = 1
//   T13: Counter saturation — all outputs hold after several more cycles
//   T14: Re-reset mid-run clears all outputs asynchronously
//   T15: After re-reset release, oRST_0 fires again at the correct cycle

module reset_delay_tb;

// ---------------------------------------------------------------------------
// Threshold constants
// ---------------------------------------------------------------------------
localparam [31:0] T0_THRESH = 32'h001FFFFF;
localparam [31:0] T1_THRESH = 32'h002FFFFF;
localparam [31:0] T2_THRESH = 32'h011FFFFF;
localparam [31:0] T3_THRESH = 32'h016FFFFF;
localparam [31:0] T4_THRESH = 32'h01FFFFFF;  // also the saturation value

// First cycle (after reset release) on which each output goes high.
// Rise happens the clock after the threshold is first reached, because
// non-blocking reads old Cont and the comparison sees the pre-increment value.
localparam [31:0] T0_RISE = T0_THRESH + 1;   // 0x00200000
localparam [31:0] T1_RISE = T1_THRESH + 1;   // 0x00300000
localparam [31:0] T2_RISE = T2_THRESH + 1;   // 0x01200000
localparam [31:0] T3_RISE = T3_THRESH + 1;   // 0x01700000
localparam [31:0] T4_RISE = T4_THRESH + 1;   // 0x02000000

// ---------------------------------------------------------------------------
// DUT
// ---------------------------------------------------------------------------
reg  iCLK, iRST;
wire oRST_0, oRST_1, oRST_2, oRST_3, oRST_4;

Reset_Delay dut (
    .iCLK  (iCLK),
    .iRST  (iRST),
    .oRST_0(oRST_0),
    .oRST_1(oRST_1),
    .oRST_2(oRST_2),
    .oRST_3(oRST_3),
    .oRST_4(oRST_4)
);

// 2 ns period (500 MHz) — fast enough to keep ~35 M cycles under 100 ms
initial iCLK = 0;
always #1 iCLK = ~iCLK;

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

// ---------------------------------------------------------------------------
// Cycle counter — tracks posedges since the most recent reset release
// ---------------------------------------------------------------------------
integer cycle_count;

// Advance from current position to an absolute cycle number (relative to the
// last reset release), then sample 1 ps after the rising edge so non-blocking
// updates have resolved.
task advance_to;
    input integer target;
    integer steps;
    begin
        steps = target - cycle_count;
        if (steps > 0)
            repeat (steps) @(posedge iCLK);
        #1;
        cycle_count = target;
    end
endtask

// ---------------------------------------------------------------------------
// Main test sequence
// ---------------------------------------------------------------------------
initial begin
    iRST = 0;
    cycle_count = 0;

    // ================================================================
    // T1: Active-low async reset clears all outputs immediately
    //     No clock edge needed — reset is asynchronous.
    // ================================================================
    #3;  // a few ns into reset
    check(oRST_0 == 0 && oRST_1 == 0 && oRST_2 == 0 &&
          oRST_3 == 0 && oRST_4 == 0,
          "T1: all outputs 0 while iRST=0 (async reset)");

    // Release reset between clock edges so the first active clock
    // edge clearly starts the counter from zero
    @(negedge iCLK); #1;
    iRST = 1;

    // ================================================================
    // T2: All outputs still 0 immediately after reset release (0 clocks)
    // ================================================================
    #1;
    check(oRST_0 == 0 && oRST_1 == 0 && oRST_2 == 0 &&
          oRST_3 == 0 && oRST_4 == 0,
          "T2: all outputs 0 immediately after reset release");

    // ================================================================
    // T3: oRST_0=0 one cycle before its threshold fires
    //     At cycle T0_THRESH the counter reads T0_THRESH-1 < threshold.
    // ================================================================
    advance_to(T0_THRESH);
    check(oRST_0 == 0,
          "T3: oRST_0=0 one cycle before threshold (Cont=0x001FFFFE)");

    // ================================================================
    // T4: oRST_0=1 at T0_RISE; oRST_1..4 still 0 (strict ordering)
    // ================================================================
    advance_to(T0_RISE);
    check(oRST_0 == 1,
          "T4a: oRST_0=1 at first-high cycle (Cont reaches 0x001FFFFF)");
    check(oRST_1 == 0 && oRST_2 == 0 && oRST_3 == 0 && oRST_4 == 0,
          "T4b: oRST_1..4 still 0 when oRST_0 first fires");

    // ================================================================
    // T5: oRST_1=0 one cycle before its threshold fires
    // ================================================================
    advance_to(T1_THRESH);
    check(oRST_1 == 0,
          "T5: oRST_1=0 one cycle before threshold (Cont=0x002FFFFE)");

    // ================================================================
    // T6: oRST_1=1 at T1_RISE; oRST_0 held high; oRST_2..4 still 0
    // ================================================================
    advance_to(T1_RISE);
    check(oRST_1 == 1,
          "T6a: oRST_1=1 at first-high cycle");
    check(oRST_0 == 1,
          "T6b: oRST_0 still latched high");
    check(oRST_2 == 0 && oRST_3 == 0 && oRST_4 == 0,
          "T6c: oRST_2..4 still 0 when oRST_1 first fires");

    // ================================================================
    // T7: oRST_2=0 one cycle before its threshold fires
    // ================================================================
    advance_to(T2_THRESH);
    check(oRST_2 == 0,
          "T7: oRST_2=0 one cycle before threshold (Cont=0x011FFFFE)");

    // ================================================================
    // T8: oRST_2=1 at T2_RISE; oRST_0,1 held; oRST_3,4 still 0
    // ================================================================
    advance_to(T2_RISE);
    check(oRST_2 == 1,
          "T8a: oRST_2=1 at first-high cycle");
    check(oRST_0 == 1 && oRST_1 == 1,
          "T8b: oRST_0 and oRST_1 still latched high");
    check(oRST_3 == 0 && oRST_4 == 0,
          "T8c: oRST_3,4 still 0 when oRST_2 first fires");

    // ================================================================
    // T9: oRST_3=0 one cycle before its threshold fires
    // ================================================================
    advance_to(T3_THRESH);
    check(oRST_3 == 0,
          "T9: oRST_3=0 one cycle before threshold (Cont=0x016FFFFE)");

    // ================================================================
    // T10: oRST_3=1 at T3_RISE; oRST_0..2 held; oRST_4 still 0
    // ================================================================
    advance_to(T3_RISE);
    check(oRST_3 == 1,
          "T10a: oRST_3=1 at first-high cycle");
    check(oRST_0 == 1 && oRST_1 == 1 && oRST_2 == 1,
          "T10b: oRST_0..2 still latched high");
    check(oRST_4 == 0,
          "T10c: oRST_4 still 0 when oRST_3 first fires");

    // ================================================================
    // T11: oRST_4=0 one cycle before its threshold fires
    //      Also verifies counter has not wrapped (still < saturation)
    // ================================================================
    advance_to(T4_THRESH);
    check(oRST_4 == 0,
          "T11: oRST_4=0 one cycle before threshold (Cont=0x01FFFFFE)");

    // ================================================================
    // T12: oRST_4=1 at T4_RISE; all five outputs now high
    // ================================================================
    advance_to(T4_RISE);
    check(oRST_4 == 1,
          "T12a: oRST_4=1 at first-high cycle (Cont saturates at 0x01FFFFFF)");
    check(oRST_0 == 1 && oRST_1 == 1 && oRST_2 == 1 && oRST_3 == 1,
          "T12b: all earlier resets still latched high");

    // ================================================================
    // T13: Counter saturation — outputs stay stable after many more clocks
    // ================================================================
    advance_to(T4_RISE + 1000);
    check(oRST_0 == 1 && oRST_1 == 1 && oRST_2 == 1 &&
          oRST_3 == 1 && oRST_4 == 1,
          "T13: all outputs stable 1000 cycles after saturation");

    // ================================================================
    // T14: Re-assert iRST mid-run — async clear of all outputs
    // ================================================================
    iRST = 0;
    #1;  // no clock edge needed; reset is asynchronous
    check(oRST_0 == 0 && oRST_1 == 0 && oRST_2 == 0 &&
          oRST_3 == 0 && oRST_4 == 0,
          "T14: re-reset clears all outputs asynchronously");

    // ================================================================
    // T15: After re-reset release, oRST_0 fires again at the correct
    //      cycle count, proving the counter restarted from 0
    // ================================================================
    @(negedge iCLK); #1;
    iRST = 1;
    cycle_count = 0;

    advance_to(T0_THRESH);
    check(oRST_0 == 0,
          "T15a: oRST_0=0 one cycle before threshold after re-reset");

    advance_to(T0_RISE);
    check(oRST_0 == 1,
          "T15b: oRST_0=1 at correct cycle after re-reset (counter restarted)");
    check(oRST_1 == 0 && oRST_2 == 0 && oRST_3 == 0 && oRST_4 == 0,
          "T15c: oRST_1..4 still 0 — sequence restarts from beginning");

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

// Safety timeout: main run (~33.6 M cy) + re-reset run (~2.1 M cy) at 2 ns = ~72 ms
initial begin
    #100_000_000;
    $display("TIMEOUT: simulation exceeded 100 ms");
    $finish;
end

endmodule
