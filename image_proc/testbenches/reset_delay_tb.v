`timescale 1ns/1ps

// Reset_Delay Testbench
//
// Tests:
//   T1:  Active-low async reset clears all outputs immediately
//   T2:  All outputs still 0 immediately after reset release
//   T3:  oRST_0=1 at T0_RISE; oRST_1..4 still 0 (strict ordering)
//   T4:  oRST_1=1 at T1_RISE; oRST_0 held; oRST_2..4 still 0
//   T5:  oRST_2=1 at T2_RISE; oRST_0,1 held; oRST_3,4 still 0
//   T6:  oRST_3=1 at T3_RISE; oRST_0..2 held; oRST_4 still 0
//   T7:  oRST_4=1 at T4_RISE; all five outputs = 1
//   T8:  Counter saturation — all outputs hold after many more cycles
//   T9:  Re-reset mid-run clears all outputs asynchronously
//   T10: After re-reset release, oRST_0 fires again (counter restarted)

module reset_delay_tb;

// ---------------------------------------------------------------------------
// Threshold constants (from Reset_Delay.v)
// ---------------------------------------------------------------------------
localparam [31:0] T0_THRESH = 32'h001FFFFF;
localparam [31:0] T1_THRESH = 32'h002FFFFF;
localparam [31:0] T2_THRESH = 32'h011FFFFF;
localparam [31:0] T3_THRESH = 32'h016FFFFF;
localparam [31:0] T4_THRESH = 32'h01FFFFFF;

// First cycle on which each output goes high (threshold + 1, because
// the comparison reads the old Cont value before incrementing)
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

// 2 ns period (500 MHz) — keeps ~35 M cycles under 100 ms wall time
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

// Tracks posedges since the most recent reset release
integer cycle_count;

// Advance to an absolute cycle number then sample 1 ns after the edge
// so non-blocking updates have resolved.
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
    // T1: Active-low async reset — all outputs 0 (no clock needed)
    // ================================================================
    #3;
    check(oRST_0 == 0 && oRST_1 == 0 && oRST_2 == 0 &&
          oRST_3 == 0 && oRST_4 == 0,
          "T1: all outputs 0 while iRST=0 (async reset)");

    @(negedge iCLK); #1;
    iRST = 1;

    // ================================================================
    // T2: All outputs still 0 immediately after reset release
    // ================================================================
    #1;
    check(oRST_0 == 0 && oRST_1 == 0 && oRST_2 == 0 &&
          oRST_3 == 0 && oRST_4 == 0,
          "T2: all outputs 0 immediately after reset release");

    // ================================================================
    // T3: oRST_0=1 at T0_RISE; oRST_1..4 still 0 (strict ordering)
    // ================================================================
    advance_to(T0_RISE);
    check(oRST_0 == 1,
          "T3a: oRST_0=1 at T0_RISE (0x00200000 cycles)");
    check(oRST_1 == 0 && oRST_2 == 0 && oRST_3 == 0 && oRST_4 == 0,
          "T3b: oRST_1..4 still 0 when oRST_0 first fires");

    // ================================================================
    // T4: oRST_1=1 at T1_RISE; oRST_0 held; oRST_2..4 still 0
    // ================================================================
    advance_to(T1_RISE);
    check(oRST_1 == 1,
          "T4a: oRST_1=1 at T1_RISE (0x00300000 cycles)");
    check(oRST_0 == 1,
          "T4b: oRST_0 still latched high");
    check(oRST_2 == 0 && oRST_3 == 0 && oRST_4 == 0,
          "T4c: oRST_2..4 still 0 when oRST_1 first fires");

    // ================================================================
    // T5: oRST_2=1 at T2_RISE; oRST_0,1 held; oRST_3,4 still 0
    // ================================================================
    advance_to(T2_RISE);
    check(oRST_2 == 1,
          "T5a: oRST_2=1 at T2_RISE (0x01200000 cycles)");
    check(oRST_0 == 1 && oRST_1 == 1,
          "T5b: oRST_0 and oRST_1 still latched high");
    check(oRST_3 == 0 && oRST_4 == 0,
          "T5c: oRST_3,4 still 0 when oRST_2 first fires");

    // ================================================================
    // T6: oRST_3=1 at T3_RISE; oRST_0..2 held; oRST_4 still 0
    // ================================================================
    advance_to(T3_RISE);
    check(oRST_3 == 1,
          "T6a: oRST_3=1 at T3_RISE (0x01700000 cycles)");
    check(oRST_0 == 1 && oRST_1 == 1 && oRST_2 == 1,
          "T6b: oRST_0..2 still latched high");
    check(oRST_4 == 0,
          "T6c: oRST_4 still 0 when oRST_3 first fires");

    // ================================================================
    // T7: oRST_4=1 at T4_RISE; all five outputs high
    // ================================================================
    advance_to(T4_RISE);
    check(oRST_4 == 1,
          "T7a: oRST_4=1 at T4_RISE (0x02000000 cycles, counter saturated)");
    check(oRST_0 == 1 && oRST_1 == 1 && oRST_2 == 1 && oRST_3 == 1,
          "T7b: all earlier outputs still latched high");

    // ================================================================
    // T8: Counter saturation — all outputs hold after many more clocks
    // ================================================================
    advance_to(T4_RISE + 1000);
    check(oRST_0 == 1 && oRST_1 == 1 && oRST_2 == 1 &&
          oRST_3 == 1 && oRST_4 == 1,
          "T8: all outputs stable 1000 cycles after saturation");

    // ================================================================
    // T9: Re-assert iRST — async clear of all outputs
    // ================================================================
    iRST = 0;
    #1;
    check(oRST_0 == 0 && oRST_1 == 0 && oRST_2 == 0 &&
          oRST_3 == 0 && oRST_4 == 0,
          "T9: re-reset clears all outputs asynchronously");

    // ================================================================
    // T10: After re-reset release, oRST_0 fires again at T0_RISE,
    //      proving the counter restarted from 0
    // ================================================================
    @(negedge iCLK); #1;
    iRST = 1;
    cycle_count = 0;

    advance_to(T0_RISE);
    check(oRST_0 == 1,
          "T10a: oRST_0=1 at T0_RISE after re-reset (counter restarted)");
    check(oRST_1 == 0 && oRST_2 == 0 && oRST_3 == 0 && oRST_4 == 0,
          "T10b: oRST_1..4 still 0 — sequence restarts from beginning");

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

// Safety timeout
initial begin
    #100_000_000;
    $display("TIMEOUT: simulation exceeded 100 ms");
    $finish;
end

endmodule
