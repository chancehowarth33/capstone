`timescale 1ns/1ps

// color_detect + overlay Testbench
//
// color_detect tests:
//   T1:  detected=0, cal_valid=0 after reset
//   T2:  no calibration → detected=0 even with target-colored pixels
//   T3:  calibration capture: center_avgR/G/B updated, cal_valid=1
//   T4:  cal_sample_R/G/B match the captured values
//   T5:  1 matching block → detected=1  (validates MIN_MATCH_BLOCKS=1)
//   T6:  3 matching blocks → detected=1
//   T7:  centroid: overlay_x / overlay_y correct for 3-block frame
//   T8:  coord_x = 639 - overlay_x  (camera-to-game mirror)
//   T9:  coord_y == overlay_y  (no vertical mirror)
//   T10: bounding box outputs (box_left/right/top/bottom) correct
//   T11: detected transitions 1→0 when object disappears
//
// overlay tests (combinational):
//   T12: calibrate mode, pixel on cal box border → white
//   T13: calibrate mode, pixel outside cal box → passthrough
//   T14: calibrate mode, pixel on cal center dot → white
//   T15: normal mode, detected=0 → passthrough regardless of position
//   T16: normal mode, detected=1, on tracking box left border → white
//   T17: normal mode, detected=1, inside box but not on border → passthrough
//   T18: normal mode, detected=1, on tracking center dot → white
//
// -----------------------------------------------------------------------
// Frame layout (scan_frame task)
//   Background : BG_R=100, BG_G=100, BG_B=100
//   CAL color  : CAL_R=700, CAL_G=50, CAL_B=10  (orange-ish)
//
//   Center block  col=10 row=7  x=[320,351]  y=[224,255]  — always CAL
//   Block A       col=5  row=4  x=[160,191]  y=[128,159]  — CAL when det_on=1
//   Block B       col=8  row=6  x=[256,287]  y=[192,223]  — CAL when det_on=1
//
// Expected centroid for 3-block frame (det_on=1):
//   block_center_x  = {block_col, 5'd16}  → A=176, B=272, Center=336
//   block_center_y  = {block_row, 5'd16}  → A=144, B=208, Center=240
//   centroid_sum_x  = 176+272+336 = 784  → tracked_x = 784/3 = 261
//   centroid_sum_y  = 144+208+240 = 592  → tracked_y = 592/3 = 197
//   overlay_x=261, overlay_y=197, coord_x=639-261=378, coord_y=197
//
// Expected bounding box for 3-block frame:
//   box_left=160, box_right=351, box_top=128, box_bottom=255

module color_detect_tb;

    // -------------------------------------------------------------------
    // color_detect signals
    // -------------------------------------------------------------------
    reg        clk, rst_n;
    reg        vsync, active, calibrate;
    reg        capture_btn_n;
    reg  [9:0] R, G, B;
    reg  [9:0] vga_x, vga_y;

    wire [9:0] overlay_x, overlay_y;
    wire [9:0] coord_x,   coord_y;
    wire [9:0] box_left,  box_right, box_top, box_bottom;
    wire       detected;
    wire [9:0] center_avgR, center_avgG, center_avgB;
    wire [9:0] cal_sample_R, cal_sample_G, cal_sample_B;
    wire       cal_valid;

    color_detect uut_cd (
        .clk          (clk),
        .rst_n        (rst_n),
        .vsync        (vsync),
        .active       (active),
        .calibrate    (calibrate),
        .capture_btn_n(capture_btn_n),
        .R            (R),
        .G            (G),
        .B            (B),
        .vga_x        (vga_x),
        .vga_y        (vga_y),
        .overlay_x    (overlay_x),
        .overlay_y    (overlay_y),
        .coord_x      (coord_x),
        .coord_y      (coord_y),
        .box_left     (box_left),
        .box_right    (box_right),
        .box_top      (box_top),
        .box_bottom   (box_bottom),
        .detected     (detected),
        .center_avgR  (center_avgR),
        .center_avgG  (center_avgG),
        .center_avgB  (center_avgB),
        .cal_sample_R (cal_sample_R),
        .cal_sample_G (cal_sample_G),
        .cal_sample_B (cal_sample_B),
        .cal_valid    (cal_valid)
    );

    // -------------------------------------------------------------------
    // overlay signals
    // -------------------------------------------------------------------
    reg  [9:0] ov_R_in,  ov_G_in,  ov_B_in;
    reg  [9:0] ov_vga_x, ov_vga_y;
    reg  [9:0] ov_overlay_x, ov_overlay_y;
    reg  [9:0] ov_box_left, ov_box_right, ov_box_top, ov_box_bottom;
    reg        ov_detected, ov_calibrate;

    wire [9:0] R_out, G_out, B_out;

    overlay uut_ov (
        .R_in      (ov_R_in),
        .G_in      (ov_G_in),
        .B_in      (ov_B_in),
        .vga_x     (ov_vga_x),
        .vga_y     (ov_vga_y),
        .overlay_x (ov_overlay_x),
        .overlay_y (ov_overlay_y),
        .box_left  (ov_box_left),
        .box_right (ov_box_right),
        .box_top   (ov_box_top),
        .box_bottom(ov_box_bottom),
        .detected  (ov_detected),
        .calibrate (ov_calibrate),
        .R_out     (R_out),
        .G_out     (G_out),
        .B_out     (B_out)
    );

    // -------------------------------------------------------------------
    // 25 MHz clock
    // -------------------------------------------------------------------
    initial clk = 0;
    always #20 clk = ~clk;

    // -------------------------------------------------------------------
    // Test constants
    // -------------------------------------------------------------------
    localparam [9:0] CAL_R = 10'd700;
    localparam [9:0] CAL_G = 10'd50;
    localparam [9:0] CAL_B = 10'd10;
    localparam [9:0] BG_R  = 10'd100;
    localparam [9:0] BG_G  = 10'd100;
    localparam [9:0] BG_B  = 10'd100;
    localparam [9:0] WHITE = 10'h3FF;

    // Expected centroid outputs for 3-block scan
    localparam [9:0] EXP_OVERLAY_X = 10'd261;
    localparam [9:0] EXP_OVERLAY_Y = 10'd197;
    localparam [9:0] EXP_COORD_X   = 10'd378; // 639 - 261
    localparam [9:0] EXP_COORD_Y   = 10'd197;

    // Expected bounding box for 3-block scan
    localparam [9:0] EXP_BOX_LEFT   = 10'd160;
    localparam [9:0] EXP_BOX_RIGHT  = 10'd351;
    localparam [9:0] EXP_BOX_TOP    = 10'd128;
    localparam [9:0] EXP_BOX_BOTTOM = 10'd255;

    // -------------------------------------------------------------------
    // Test helpers
    // -------------------------------------------------------------------
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

    // Generate a vsync falling edge and let the DUT register it.
    // Sequence: ensure vsync=1 is sampled first, then drop to 0.
    task gen_vsync_fall;
    begin
        @(posedge clk); #1; vsync = 1;
        @(posedge clk); #1; vsync = 0;
        @(posedge clk);          // vsync_fall fires here
        #1; vsync = 1;
        @(posedge clk); #1;      // outputs settle
    end
    endtask

    // Scan one complete 640×480 frame pixel-by-pixel.
    //   - Center block (col=10 row=7, x=[320,351] y=[224,255]) always gets CAL color.
    //   - When det_on=1, Block A (col=5 row=4) and Block B (col=8 row=6) also get CAL.
    //   - All other pixels get background color.
    integer px, py;
    task scan_frame;
        input det_on;
    begin
        for (py = 0; py < 480; py = py + 1) begin
            for (px = 0; px < 640; px = px + 1) begin
                @(posedge clk); #1;
                vga_x  = px[9:0];
                vga_y  = py[9:0];
                active = 1;

                if (px >= 320 && px <= 351 && py >= 224 && py <= 255) begin
                    // Center calibration block — always CAL color
                    R = CAL_R; G = CAL_G; B = CAL_B;

                end else if (det_on && px >= 160 && px <= 191 && py >= 128 && py <= 159) begin
                    // Block A (col=5, row=4)
                    R = CAL_R; G = CAL_G; B = CAL_B;

                end else if (det_on && px >= 256 && px <= 287 && py >= 192 && py <= 223) begin
                    // Block B (col=8, row=6)
                    R = CAL_R; G = CAL_G; B = CAL_B;

                end else begin
                    R = BG_R; G = BG_G; B = BG_B;
                end
            end
        end
        @(posedge clk); #1;
        active = 0;
        R = 0; G = 0; B = 0;
    end
    endtask

    // =======================================================================
    // Main test sequence
    // =======================================================================
    initial begin
        // ---- Defaults ----
        rst_n         = 0;
        vsync         = 1;
        active        = 0;
        calibrate     = 0;
        capture_btn_n = 1;
        R = 0; G = 0; B = 0;
        vga_x = 0; vga_y = 0;

        ov_R_in  = 0; ov_G_in  = 0; ov_B_in  = 0;
        ov_vga_x = 0; ov_vga_y = 0;
        ov_overlay_x = 0; ov_overlay_y = 0;
        ov_box_left = 0; ov_box_right  = 0;
        ov_box_top  = 0; ov_box_bottom = 0;
        ov_detected = 0; ov_calibrate = 0;

        repeat(8) @(posedge clk);
        rst_n = 1;
        repeat(4) @(posedge clk); #1;

        // ================================================================
        // T1: detected=0 and cal_valid=0 immediately after reset
        // ================================================================
        check(detected  == 1'b0, "T1a: detected=0 after reset");
        check(cal_valid == 1'b0, "T1b: cal_valid=0 after reset");

        // ================================================================
        // T2: no calibration → detected=0 even with target-colored pixels
        //   cal_valid=0 so color_match is always 0.
        // ================================================================
        calibrate = 0; capture_btn_n = 1;
        gen_vsync_fall;
        scan_frame(1);   // paint detection blocks with CAL color
        gen_vsync_fall;  // latch results
        check(detected == 1'b0,
              "T2: detected=0 without calibration (cal_valid=0)");

        // ================================================================
        // T3: calibration capture stores center-block average into cal_R/G/B
        //   Press button before scanning, confirm center_avgR/G/B and cal_valid.
        // ================================================================
        calibrate = 1; capture_btn_n = 1;
        gen_vsync_fall;
        // Press and release the capture button — sets capture_pending=1
        @(posedge clk); #1; capture_btn_n = 0;
        @(posedge clk); #1; capture_btn_n = 1;
        scan_frame(0);   // only center block gets CAL color
        gen_vsync_fall;
        repeat(2) @(posedge clk); #1;

        check(center_avgR == CAL_R && center_avgG == CAL_G && center_avgB == CAL_B,
              "T3: center_avg matches CAL color after capture");
        check(cal_valid == 1'b1,
              "T3b: cal_valid=1 after capture");

        // ================================================================
        // T4: cal_sample_R/G/B output matches the captured values
        // ================================================================
        check(cal_sample_R == CAL_R, "T4a: cal_sample_R matches CAL_R");
        check(cal_sample_G == CAL_G, "T4b: cal_sample_G matches CAL_G");
        check(cal_sample_B == CAL_B, "T4c: cal_sample_B matches CAL_B");

        // ================================================================
        // T5: single matching block (center only) → detected=1
        //   MIN_MATCH_BLOCKS=1, so even 1 match suffices.
        // ================================================================
        calibrate = 0; capture_btn_n = 1;
        gen_vsync_fall;
        scan_frame(0);   // only center block matches
        gen_vsync_fall;
        repeat(2) @(posedge clk); #1;
        check(detected == 1'b1,
              "T5: detected=1 with 1 matching block (MIN_MATCH_BLOCKS=1)");

        // ================================================================
        // T6: three matching blocks → detected=1
        // ================================================================
        gen_vsync_fall;
        scan_frame(1);   // center + A + B all match
        gen_vsync_fall;
        repeat(2) @(posedge clk); #1;
        check(detected == 1'b1,
              "T6: detected=1 with 3 matching blocks");

        // ================================================================
        // T7: centroid: overlay_x / overlay_y correct for 3-block frame
        //   Expected: overlay_x=261, overlay_y=197 (see header comments)
        // ================================================================
        check(overlay_x == EXP_OVERLAY_X,
              "T7a: overlay_x=(centroid_sum_x / match_count) correct");
        check(overlay_y == EXP_OVERLAY_Y,
              "T7b: overlay_y=(centroid_sum_y / match_count) correct");

        // ================================================================
        // T8: coord_x = 639 - overlay_x  (horizontal camera mirror for game)
        // ================================================================
        check(coord_x == EXP_COORD_X,
              "T8: coord_x = 639 - overlay_x (mirrored)");

        // ================================================================
        // T9: coord_y == overlay_y (vertical axis is not mirrored)
        // ================================================================
        check(coord_y == EXP_COORD_Y,
              "T9: coord_y == overlay_y (not mirrored)");

        // ================================================================
        // T10: bounding box latched at vsync_fall matches block extents
        //   Expected: left=160 right=351 top=128 bottom=255
        // ================================================================
        check(box_left   == EXP_BOX_LEFT,   "T10a: box_left=160  (col 5 left edge)");
        check(box_right  == EXP_BOX_RIGHT,  "T10b: box_right=351 (col 10 right edge)");
        check(box_top    == EXP_BOX_TOP,    "T10c: box_top=128   (row 4 top edge)");
        check(box_bottom == EXP_BOX_BOTTOM, "T10d: box_bottom=255 (row 7 bottom edge)");

        // ================================================================
        // T11: detected transitions 1→0 when object disappears
        // ================================================================
        // Confirm currently 1 (from T6 scan)
        check(detected == 1'b1,
              "T11a: detected=1 with object present (baseline)");

        // Scan frame with no matching blocks (background only)
        gen_vsync_fall;
        // Override CAL scan with all-background scan:
        begin : bg_scan
            integer bx, by;
            for (by = 0; by < 480; by = by + 1) begin
                for (bx = 0; bx < 640; bx = bx + 1) begin
                    @(posedge clk); #1;
                    vga_x  = bx[9:0];
                    vga_y  = by[9:0];
                    active = 1;
                    R = BG_R; G = BG_G; B = BG_B;
                end
            end
            @(posedge clk); #1;
            active = 0;
        end
        gen_vsync_fall;
        repeat(2) @(posedge clk); #1;
        check(detected == 1'b0,
              "T11b: detected=0 after object disappears");

        // ================================================================
        // Overlay tests — purely combinational
        // ================================================================

        // ----------------------------------------------------------------
        // T12: calibrate mode, pixel on cal box top border → white
        //   cal_top=224, THICK=2 → border at y=[224,225], x=[304,335]
        // ----------------------------------------------------------------
        ov_calibrate = 1; ov_detected = 0;
        ov_R_in = 10'h155; ov_G_in = 10'h2AA; ov_B_in = 10'h100;
        ov_vga_x = 10'd320; ov_vga_y = 10'd224;
        #5;
        check(R_out == WHITE && G_out == WHITE && B_out == WHITE,
              "T12: calibrate mode - cal box top border is white");

        // ----------------------------------------------------------------
        // T13: calibrate mode, pixel well outside cal box → passthrough
        // ----------------------------------------------------------------
        ov_vga_x = 10'd100; ov_vga_y = 10'd100;
        #5;
        check(R_out == ov_R_in && G_out == ov_G_in && B_out == ov_B_in,
              "T13: calibrate mode - outside cal box is passthrough");

        // ----------------------------------------------------------------
        // T14: calibrate mode, pixel on cal center dot → white
        //   cal_dot_on: x=[318,321], y=[238,241] — center of screen
        // ----------------------------------------------------------------
        ov_vga_x = 10'd320; ov_vga_y = 10'd240;
        #5;
        check(R_out == WHITE && G_out == WHITE && B_out == WHITE,
              "T14: calibrate mode - cal center dot is white");

        // ----------------------------------------------------------------
        // T15: normal mode, detected=0 → passthrough regardless of position
        // ----------------------------------------------------------------
        ov_calibrate = 0; ov_detected = 0;
        ov_box_left = 10'd160; ov_box_right  = 10'd287;
        ov_box_top  = 10'd128; ov_box_bottom = 10'd223;
        ov_vga_x = 10'd200; ov_vga_y = 10'd160;  // inside box extents
        ov_R_in = 10'd300; ov_G_in = 10'd400; ov_B_in = 10'd500;
        #5;
        check(R_out == ov_R_in && G_out == ov_G_in && B_out == ov_B_in,
              "T15: normal mode detected=0 - passthrough inside box area");

        // ----------------------------------------------------------------
        // T16: normal mode, detected=1, on tracking box left border → white
        //   left border: x=[box_left, box_left+THICK-1]=[160,161], y in [128,223]
        // ----------------------------------------------------------------
        ov_detected = 1;
        ov_vga_x = 10'd160; ov_vga_y = 10'd170;
        ov_R_in = 10'h155; ov_G_in = 10'h2AA; ov_B_in = 10'h100;
        #5;
        check(R_out == WHITE && G_out == WHITE && B_out == WHITE,
              "T16: normal mode detected=1 - tracking box left border is white");

        // ----------------------------------------------------------------
        // T17: normal mode, detected=1, inside box but not on any border → passthrough
        //   x=220 is between left[160,161] and right[286,287]
        //   y=170 is between top[128,129]  and bottom[222,223]
        // ----------------------------------------------------------------
        ov_vga_x = 10'd220; ov_vga_y = 10'd170;
        ov_R_in = 10'd200; ov_G_in = 10'd300; ov_B_in = 10'd400;
        #5;
        check(R_out == ov_R_in && G_out == ov_G_in && B_out == ov_B_in,
              "T17: normal mode detected=1 - inside box, not on border is passthrough");

        // ----------------------------------------------------------------
        // T18: normal mode, detected=1, on tracking center dot → white
        //   trk_dot_on: vga_x in [overlay_x-2, overlay_x+2],
        //               vga_y in [overlay_y-2, overlay_y+2]
        //   Use overlay_x=261, overlay_y=197 from color_detect centroid test
        // ----------------------------------------------------------------
        ov_overlay_x = EXP_OVERLAY_X;   // 261
        ov_overlay_y = EXP_OVERLAY_Y;   // 197
        ov_vga_x = EXP_OVERLAY_X;       // center of dot
        ov_vga_y = EXP_OVERLAY_Y;
        ov_R_in = 10'h155; ov_G_in = 10'h2AA; ov_B_in = 10'h100;
        #5;
        check(R_out == WHITE && G_out == WHITE && B_out == WHITE,
              "T18: normal mode detected=1 - tracking center dot is white");

        // ================================================================
        // Summary
        // ================================================================
        $display("=========================================");
        $display("Results: %0d passed, %0d failed", pass_count, fail_count);
        $display("=========================================");
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

    // Watchdog: 7 full-frame scans × ~12.3 ms each + overhead
    initial begin
        #200_000_000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
