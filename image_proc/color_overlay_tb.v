`timescale 1ns/1ps

module color_overlay_tb;

    // color_detect signals
    reg        clk;
    reg        vsync;
    reg        active;
    reg  [9:0] R, G, B;
    reg  [9:0] vga_x, vga_y;
    wire [9:0] hand_x, hand_y;
    wire       detected;

    color_detect uut_cd (
        .clk(clk), .vsync(vsync), .active(active),
        .R(R), .G(G), .B(B),
        .vga_x(vga_x), .vga_y(vga_y),
        .hand_x(hand_x), .hand_y(hand_y), .detected(detected)
    );

    // overlay signals
    reg  [9:0] R_in, G_in, B_in;
    reg  [9:0] ov_x, ov_y, ov_hx, ov_hy;
    reg        ov_det;
    wire [9:0] R_out, G_out, B_out;

    overlay uut_ov (
        .R_in(R_in), .G_in(G_in), .B_in(B_in),
        .vga_x(ov_x), .vga_y(ov_y),
        .hand_x(ov_hx), .hand_y(ov_hy), .detected(ov_det),
        .R_out(R_out), .G_out(G_out), .B_out(B_out)
    );

    // 25 mhz clock
    initial clk = 0;
    always #20 clk = ~clk;

    integer errors;
    integer px, py;

    initial begin
        errors = 0;
        vsync = 1; active = 0; R = 0; G = 0; B = 0; vga_x = 0; vga_y = 0;
        R_in = 10'h155; G_in = 10'h2AA; B_in = 10'h100;
        ov_x = 0; ov_y = 0; ov_hx = 300; ov_hy = 240; ov_det = 0;
        repeat(8) @(posedge clk);

        // ---- t1: no orange pixels → detected stays low ----
        // vsync high then falling edge starts the frame
        vsync = 1; active = 0; R = 0; G = 0; B = 0;
        repeat(4) @(posedge clk);
        @(posedge clk); #1; vsync = 0;
        for (py = 0; py < 480; py = py + 1)
            for (px = 0; px < 640; px = px + 1) begin
                @(posedge clk); #1;
                vga_x = px[9:0]; vga_y = py[9:0]; active = 1;
                R = 10'd100; G = 10'd100; B = 10'd100;
            end
        active = 0; R = 0; G = 0; B = 0;
        // second vsync pulse latches result into hand_x/y/detected
        repeat(4) @(posedge clk);
        vsync = 1; repeat(4) @(posedge clk);
        @(posedge clk); #1; vsync = 0;
        repeat(4) @(posedge clk);
        if (detected !== 1'b0) begin $display("FAIL T1: detected=%b expected 0", detected); errors = errors + 1; end
        else $display("PASS T1: no match, detected=0");

        // ---- t2: 5x5 cluster (25 px <= 300) → detected stays low ----
        vsync = 1; active = 0; R = 0; G = 0; B = 0;
        repeat(4) @(posedge clk);
        @(posedge clk); #1; vsync = 0;
        for (py = 0; py < 480; py = py + 1)
            for (px = 0; px < 640; px = px + 1) begin
                @(posedge clk); #1;
                vga_x = px[9:0]; vga_y = py[9:0]; active = 1;
                if (px >= 100 && px <= 104 && py >= 100 && py <= 104)
                    begin R = 10'd700; G = 10'd50; B = 10'd10; end
                else
                    begin R = 10'd100; G = 10'd100; B = 10'd100; end
            end
        active = 0; R = 0; G = 0; B = 0;
        repeat(4) @(posedge clk);
        vsync = 1; repeat(4) @(posedge clk);
        @(posedge clk); #1; vsync = 0;
        repeat(4) @(posedge clk);
        if (detected !== 1'b0) begin $display("FAIL T2: detected=%b expected 0", detected); errors = errors + 1; end
        else $display("PASS T2: small cluster, detected=0");

        // ---- t3: 40x20 cluster (800 px > 300) → detected=1, centroid inside cluster bounding box ----
        vsync = 1; active = 0; R = 0; G = 0; B = 0;
        repeat(4) @(posedge clk);
        @(posedge clk); #1; vsync = 0;
        for (py = 0; py < 480; py = py + 1)
            for (px = 0; px < 640; px = px + 1) begin
                @(posedge clk); #1;
                vga_x = px[9:0]; vga_y = py[9:0]; active = 1;
                if (px >= 280 && px <= 319 && py >= 220 && py <= 239)
                    begin R = 10'd700; G = 10'd50; B = 10'd10; end
                else
                    begin R = 10'd100; G = 10'd100; B = 10'd100; end
            end
        active = 0; R = 0; G = 0; B = 0;
        repeat(4) @(posedge clk);
        vsync = 1; repeat(4) @(posedge clk);
        @(posedge clk); #1; vsync = 0;
        repeat(4) @(posedge clk);
        if (detected !== 1'b1) begin $display("FAIL T3: detected=%b expected 1", detected); errors = errors + 1; end
        else $display("PASS T3: large cluster, detected=1");

        // ---- t4: object then gone → detected transitions 1→0 ----
        vsync = 1; active = 0; R = 0; G = 0; B = 0;
        repeat(4) @(posedge clk);
        @(posedge clk); #1; vsync = 0;
        for (py = 0; py < 480; py = py + 1)
            for (px = 0; px < 640; px = px + 1) begin
                @(posedge clk); #1;
                vga_x = px[9:0]; vga_y = py[9:0]; active = 1;
                if (px >= 200 && px <= 250 && py >= 150 && py <= 180)
                    begin R = 10'd700; G = 10'd50; B = 10'd10; end
                else
                    begin R = 10'd100; G = 10'd100; B = 10'd100; end
            end
        active = 0; R = 0; G = 0; B = 0;
        repeat(4) @(posedge clk);
        vsync = 1; repeat(4) @(posedge clk);
        @(posedge clk); #1; vsync = 0;
        repeat(4) @(posedge clk);
        if (detected !== 1'b1) begin $display("FAIL T4a: expected detected=1"); errors = errors + 1; end
        else $display("PASS T4a: detected=1 with object");

        vsync = 1; active = 0; R = 0; G = 0; B = 0;
        repeat(4) @(posedge clk);
        @(posedge clk); #1; vsync = 0;
        for (py = 0; py < 480; py = py + 1)
            for (px = 0; px < 640; px = px + 1) begin
                @(posedge clk); #1;
                vga_x = px[9:0]; vga_y = py[9:0]; active = 1;
                R = 10'd100; G = 10'd100; B = 10'd100;
            end
        active = 0; R = 0; G = 0; B = 0;
        repeat(4) @(posedge clk);
        vsync = 1; repeat(4) @(posedge clk);
        @(posedge clk); #1; vsync = 0;
        repeat(4) @(posedge clk);
        if (detected !== 1'b0) begin $display("FAIL T4b: expected detected=0"); errors = errors + 1; end
        else $display("PASS T4b: detected=0 after object gone");

        // ---- t5: overlay passthrough when detected=0 ----
        ov_det = 0; ov_hx = 10'd320; ov_hy = 10'd240;
        ov_x = 10'd320; ov_y = 10'd240;
        R_in = 10'h155; G_in = 10'h2AA; B_in = 10'h100; #5;
        if (R_out !== R_in || G_out !== G_in || B_out !== B_in) begin
            $display("FAIL T5: out=(%0d,%0d,%0d) expected passthrough", R_out, G_out, B_out); errors = errors + 1;
        end else $display("PASS T5: passthrough when detected=0");

        // ---- t6: white dot at centroid ----
        ov_det = 1; ov_hx = 10'd320; ov_hy = 10'd240;
        ov_x = 10'd320; ov_y = 10'd240; #5;
        if (R_out !== 10'h3FF || G_out !== 10'h3FF || B_out !== 10'h3FF) begin
            $display("FAIL T6: out=(%0d,%0d,%0d) expected white", R_out, G_out, B_out); errors = errors + 1;
        end else $display("PASS T6: white dot at centroid");

        // ---- t7: crosshair h-line outside dot ----
        ov_x = ov_hx + 10'd30; ov_y = ov_hy; #5;
        if (R_out !== 10'h3FF || G_out !== 10'h3FF || B_out !== 10'h3FF) begin
            $display("FAIL T7: out=(%0d,%0d,%0d) expected white h-line", R_out, G_out, B_out); errors = errors + 1;
        end else $display("PASS T7: crosshair h-line white");

        // ---- t8: crosshair v-line outside dot ----
        ov_x = ov_hx; ov_y = ov_hy + 10'd30; #5;
        if (R_out !== 10'h3FF || G_out !== 10'h3FF || B_out !== 10'h3FF) begin
            $display("FAIL T8: out=(%0d,%0d,%0d) expected white v-line", R_out, G_out, B_out); errors = errors + 1;
        end else $display("PASS T8: crosshair v-line white");

        // ---- t9: passthrough far from centroid ----
        R_in = 10'd256; G_in = 10'd512; B_in = 10'd128;
        ov_x = ov_hx + 10'd100; ov_y = ov_hy + 10'd100; #5;
        if (R_out !== R_in || G_out !== G_in || B_out !== B_in) begin
            $display("FAIL T9: out=(%0d,%0d,%0d) expected passthrough", R_out, G_out, B_out); errors = errors + 1;
        end else $display("PASS T9: passthrough far from centroid");

        // ---- t10: dot boundary — pixel at exactly +-20 is inside dot ----
        ov_x = ov_hx + 10'd20; ov_y = ov_hy; #5;
        if (R_out !== 10'h3FF || G_out !== 10'h3FF || B_out !== 10'h3FF) begin
            $display("FAIL T10: out=(%0d,%0d,%0d) expected white at dot edge", R_out, G_out, B_out); errors = errors + 1;
        end else $display("PASS T10: dot edge pixel white");

        // ---- t11: pixel at +-21 off lines is passthrough ----
        R_in = 10'd300; G_in = 10'd400; B_in = 10'd500;
        ov_x = ov_hx + 10'd21; ov_y = ov_hy + 10'd10; #5;
        if (R_out !== R_in || G_out !== G_in || B_out !== B_in) begin
            $display("FAIL T11: out=(%0d,%0d,%0d) expected passthrough", R_out, G_out, B_out); errors = errors + 1;
        end else $display("PASS T11: passthrough just outside dot");

        $display("=========================================");
        if (errors == 0) $display("ALL TESTS PASSED");
        else $display("%0d TEST(S) FAILED", errors);
        $display("=========================================");
        $stop();
    end

    // watchdog
    initial begin
        #200000;
        $display("TIMEOUT");
        $stop();
    end

endmodule