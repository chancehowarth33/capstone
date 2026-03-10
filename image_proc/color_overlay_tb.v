`timescale 1ns/1ps

module color_overlay_tb;

    //-------------------------------------------------------------------------
    // color_detect signals
    //-------------------------------------------------------------------------
    reg        clk;
    reg        rst_n;
    reg        vsync;
    reg        active;
    reg        calibrate;
    reg        capture_btn_n;
    reg  [9:0] R, G, B;
    reg  [9:0] vga_x, vga_y;

    wire [9:0] hand_x, hand_y;
    wire [9:0] box_left, box_right, box_top, box_bottom;
    wire       detected;
    wire [9:0] center_avgR, center_avgG, center_avgB;

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
        .hand_x       (hand_x),
        .hand_y       (hand_y),
        .box_left     (box_left),
        .box_right    (box_right),
        .box_top      (box_top),
        .box_bottom   (box_bottom),
        .detected     (detected),
        .center_avgR  (center_avgR),
        .center_avgG  (center_avgG),
        .center_avgB  (center_avgB)
    );

    //-------------------------------------------------------------------------
    // overlay signals
    //-------------------------------------------------------------------------
    reg  [9:0] R_in, G_in, B_in;
    reg  [9:0] ov_x, ov_y;
    reg  [9:0] ov_hx, ov_hy;
    reg  [9:0] ov_box_left, ov_box_right, ov_box_top, ov_box_bottom;
    reg        ov_det, ov_cal;

    wire [9:0] R_out, G_out, B_out;

    overlay uut_ov (
        .R_in      (R_in),
        .G_in      (G_in),
        .B_in      (B_in),
        .vga_x     (ov_x),
        .vga_y     (ov_y),
        .hand_x    (ov_hx),
        .hand_y    (ov_hy),
        .box_left  (ov_box_left),
        .box_right (ov_box_right),
        .box_top   (ov_box_top),
        .box_bottom(ov_box_bottom),
        .detected  (ov_det),
        .calibrate (ov_cal),
        .R_out     (R_out),
        .G_out     (G_out),
        .B_out     (B_out)
    );

    //-------------------------------------------------------------------------
    // 25 MHz clock
    //-------------------------------------------------------------------------
    initial clk = 0;
    always #20 clk = ~clk;

    //-------------------------------------------------------------------------
    // Calibration color
    //   For a uniform block of 1024 pixels at value V:
    //     sum = V*1024  →  avg = (V*1024) >> 10 = V
    //   So choosing any value ≤ 1023 gives a clean round-trip.
    //
    // Detection blocks (two non-center blocks used for T4/T6):
    //   Block A — col=5  row=4 : x=160-191  y=128-159
    //   Block B — col=8  row=6 : x=256-287  y=192-223
    //
    // Center block (col=10 row=7): x=320-351  y=224-255
    //   Always painted with CAL color; only captured when calibrate=1 + button pressed.
    //   In normal-mode scans it provides exactly 1 matching block (< MIN_MATCH_BLOCKS=2).
    //-------------------------------------------------------------------------
    localparam [9:0] CAL_R = 10'd700;
    localparam [9:0] CAL_G = 10'd50;
    localparam [9:0] CAL_B = 10'd10;
    localparam [9:0] BG_R  = 10'd100;   // background — diffR=600, well outside TOL=80
    localparam [9:0] BG_G  = 10'd100;
    localparam [9:0] BG_B  = 10'd100;

    integer errors;
    integer px, py;

    //-------------------------------------------------------------------------
    // Task: generate one vsync falling edge and wait for the DUT to register it.
    //   Sequence: drive vsync=1, then vsync=0; one more posedge lets the DUT
    //   sample vsync_prev=1/vsync=0 → vsync_fall=1 fires and resets accumulators.
    //-------------------------------------------------------------------------
    task gen_vsync_fall;
    begin
        @(posedge clk); #1; vsync = 1;
        @(posedge clk); #1; vsync = 0;
        @(posedge clk);          // vsync_fall registered here
    end
    endtask

    //-------------------------------------------------------------------------
    // Task: drive one complete 640×480 frame pixel-by-pixel.
    //   Center block (col=10 row=7, x=320-351 y=224-255) always receives CAL color.
    //   When det_on=1, two extra detection blocks also receive CAL color.
    //-------------------------------------------------------------------------
    task scan_frame;
        input det_on;
    begin
        for (py = 0; py < 480; py = py + 1) begin
            for (px = 0; px < 640; px = px + 1) begin
                @(posedge clk); #1;
                vga_x  = px[9:0];
                vga_y  = py[9:0];
                active = 1;

                // Center calibration block
                if (px >= 320 && px <= 351 && py >= 224 && py <= 255) begin
                    R = CAL_R; G = CAL_G; B = CAL_B;

                // Detection block A (col=5 row=4)
                end else if (det_on && px >= 160 && px <= 191 && py >= 128 && py <= 159) begin
                    R = CAL_R; G = CAL_G; B = CAL_B;

                // Detection block B (col=8 row=6)
                end else if (det_on && px >= 256 && px <= 287 && py >= 192 && py <= 223) begin
                    R = CAL_R; G = CAL_G; B = CAL_B;

                end else begin
                    R = BG_R; G = BG_G; B = BG_B;
                end
            end
        end
        @(posedge clk); #1;
        active = 0; R = 0; G = 0; B = 0;
    end
    endtask

    //=========================================================================
    // Main test sequence
    //=========================================================================
    initial begin
        errors        = 0;

        // color_detect defaults
        rst_n         = 0;
        vsync         = 1;
        active        = 0;
        calibrate     = 0;
        capture_btn_n = 1;
        R = 0; G = 0; B = 0;
        vga_x = 0; vga_y = 0;

        // overlay defaults
        R_in  = 0; G_in  = 0; B_in  = 0;
        ov_x  = 0; ov_y  = 0;
        ov_hx = 0; ov_hy = 0;
        ov_box_left = 0; ov_box_right  = 0;
        ov_box_top  = 0; ov_box_bottom = 0;
        ov_det = 0; ov_cal = 0;

        repeat(8) @(posedge clk);
        rst_n = 1;
        repeat(4) @(posedge clk);

        // ---- T1: after reset detected=0 ----
        if (detected !== 1'b0) begin
            $display("FAIL T1: detected=%b after reset, expected 0", detected);
            errors = errors + 1;
        end else
            $display("PASS T1: detected=0 after reset");

        // ---- T2: no calibration → detected stays 0 even with target-colored pixels ----
        //   cal_valid=0 so color_match is always 0.
        calibrate = 0; capture_btn_n = 1;
        gen_vsync_fall();
        scan_frame(1);         // paint detection blocks with CAL color, but no cal captured
        gen_vsync_fall();      // latch frame results
        repeat(4) @(posedge clk);
        if (detected !== 1'b0) begin
            $display("FAIL T2: detected=%b without calibration, expected 0", detected);
            errors = errors + 1;
        end else
            $display("PASS T2: detected=0 without calibration");

        // ---- T3: calibration capture stores center-block color ----
        //   Enter calibrate mode, press KEY[1] (capture_btn_n 1→0→1) before the
        //   center block is reached.  When end-of-block fires for the center block
        //   (x=351, y=255), capture_pending=1 triggers the cal_R/G/B latch.
        //   We verify the capture via center_avgR/G/B (updated at same point).
        calibrate = 1; capture_btn_n = 1;
        gen_vsync_fall();
        // Press and release button before center block (starts at py=224)
        @(posedge clk); #1; capture_btn_n = 0;   // falling edge → capture_pending=1
        @(posedge clk); #1; capture_btn_n = 1;
        scan_frame(0);         // only center block gets CAL color
        gen_vsync_fall();      // latch; center_avgR persists (not cleared by vsync_fall)
        repeat(4) @(posedge clk);
        if (center_avgR !== CAL_R || center_avgG !== CAL_G || center_avgB !== CAL_B) begin
            $display("FAIL T3: center_avg=(%0d,%0d,%0d) expected (%0d,%0d,%0d)",
                     center_avgR, center_avgG, center_avgB, CAL_R, CAL_G, CAL_B);
            errors = errors + 1;
        end else
            $display("PASS T3: calibration color captured correctly");

        // ---- T4: after calibration, ≥2 matching blocks → detected=1 ----
        //   scan_frame(1) gives center block + block A + block B = 3 matches ≥ MIN_MATCH_BLOCKS=2
        calibrate = 0; capture_btn_n = 1;
        gen_vsync_fall();
        scan_frame(1);
        gen_vsync_fall();
        repeat(4) @(posedge clk);
        if (detected !== 1'b1) begin
            $display("FAIL T4: detected=%b after calibration+match, expected 1", detected);
            errors = errors + 1;
        end else
            $display("PASS T4: detected=1 after calibration with matching pixels");

        // ---- T5: only center block matches (1 < MIN_MATCH_BLOCKS=2) → detected=0 ----
        calibrate = 0; capture_btn_n = 1;
        gen_vsync_fall();
        scan_frame(0);         // center block matches (1), detection blocks are BG
        gen_vsync_fall();
        repeat(4) @(posedge clk);
        if (detected !== 1'b0) begin
            $display("FAIL T5: detected=%b with only 1 matching block, expected 0", detected);
            errors = errors + 1;
        end else
            $display("PASS T5: detected=0 with only 1 matching block");

        // ---- T6: detected transitions 1→0 when object disappears ----
        calibrate = 0;
        gen_vsync_fall();
        scan_frame(1);
        gen_vsync_fall();
        repeat(4) @(posedge clk);
        if (detected !== 1'b1) begin
            $display("FAIL T6a: expected detected=1 with matching blocks");
            errors = errors + 1;
        end else
            $display("PASS T6a: detected=1 with matching blocks");

        gen_vsync_fall();
        scan_frame(0);
        gen_vsync_fall();
        repeat(4) @(posedge clk);
        if (detected !== 1'b0) begin
            $display("FAIL T6b: expected detected=0 after object disappears");
            errors = errors + 1;
        end else
            $display("PASS T6b: detected=0 after object disappears");

        //=====================================================================
        // Overlay tests — purely combinational, no clock needed
        //
        // Calibration box (from overlay.v):
        //   cal_left=304  cal_right=335  cal_top=224  cal_bottom=255  THICK=2
        //   Top border:    y in [224,225],  x in [304,335]
        //   Bottom border: y in [254,255],  x in [304,335]
        //   Left border:   x in [304,305],  y in [224,255]
        //   Right border:  x in [334,335],  y in [224,255]
        //=====================================================================

        // ---- T7: calibrate mode, pixel on cal box top border → white ----
        ov_cal = 1; ov_det = 0;
        R_in = 10'h155; G_in = 10'h2AA; B_in = 10'h100;
        ov_x = 10'd320; ov_y = 10'd224;   // y=cal_top, x inside [304,335]
        #5;
        if (R_out !== 10'h3FF || G_out !== 10'h3FF || B_out !== 10'h3FF) begin
            $display("FAIL T7: out=(%0d,%0d,%0d) expected white at cal box top border",
                     R_out, G_out, B_out);
            errors = errors + 1;
        end else
            $display("PASS T7: white at calibration box top border");

        // ---- T8: calibrate mode, pixel far outside cal box → passthrough ----
        ov_x = 10'd100; ov_y = 10'd100;
        #5;
        if (R_out !== R_in || G_out !== G_in || B_out !== B_in) begin
            $display("FAIL T8: out=(%0d,%0d,%0d) expected passthrough outside cal box",
                     R_out, G_out, B_out);
            errors = errors + 1;
        end else
            $display("PASS T8: passthrough outside calibration box");

        // ---- T9: normal mode, detected=0 → passthrough regardless of position ----
        ov_cal = 0; ov_det = 0;
        ov_box_left = 10'd160; ov_box_right  = 10'd287;
        ov_box_top  = 10'd128; ov_box_bottom = 10'd223;
        ov_x = 10'd200; ov_y = 10'd160;
        R_in = 10'd300; G_in = 10'd400; B_in = 10'd500;
        #5;
        if (R_out !== R_in || G_out !== G_in || B_out !== B_in) begin
            $display("FAIL T9: out=(%0d,%0d,%0d) expected passthrough when detected=0",
                     R_out, G_out, B_out);
            errors = errors + 1;
        end else
            $display("PASS T9: passthrough when detected=0");

        // ---- T10: normal mode, detected=1, pixel on tracking box left border → white ----
        //   left border: x in [box_left, box_left+THICK-1] = [160,161], y in [128,223]
        ov_det = 1;
        ov_x = 10'd160; ov_y = 10'd170;
        R_in = 10'h155; G_in = 10'h2AA; B_in = 10'h100;
        #5;
        if (R_out !== 10'h3FF || G_out !== 10'h3FF || B_out !== 10'h3FF) begin
            $display("FAIL T10: out=(%0d,%0d,%0d) expected white on tracking box left border",
                     R_out, G_out, B_out);
            errors = errors + 1;
        end else
            $display("PASS T10: white on tracking box left border");

        // ---- T11: normal mode, detected=1, pixel inside box but not on any border → passthrough ----
        //   x=220 is not in left[160,161], right[286,287]
        //   y=170 is not in top[128,129], bottom[222,223]
        ov_x = 10'd220; ov_y = 10'd170;
        R_in = 10'd200; G_in = 10'd300; B_in = 10'd400;
        #5;
        if (R_out !== R_in || G_out !== G_in || B_out !== B_in) begin
            $display("FAIL T11: out=(%0d,%0d,%0d) expected passthrough inside tracking box",
                     R_out, G_out, B_out);
            errors = errors + 1;
        end else
            $display("PASS T11: passthrough inside tracking box (not on border)");

        $display("=========================================");
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $display("=========================================");
        $stop();
    end

    // Watchdog: 6 full-frame scans × ~12.3 ms each + overhead → 200 ms is safe
    initial begin
        #200_000_000;
        $display("TIMEOUT");
        $stop();
    end

endmodule
