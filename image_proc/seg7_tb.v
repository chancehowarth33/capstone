`timescale 1ns/1ps

module seg7_tb;

    reg  [23:0] iDIG;
    wire [6:0]  oSEG0, oSEG1, oSEG2, oSEG3, oSEG4, oSEG5;

    SEG7_LUT_6 uut (
        .iDIG (iDIG),
        .oSEG0(oSEG0),
        .oSEG1(oSEG1),
        .oSEG2(oSEG2),
        .oSEG3(oSEG3),
        .oSEG4(oSEG4),
        .oSEG5(oSEG5)
    );

    // Expected 7-segment encoding for digits 0-F (active-low segments)
    // Segment order: gfedcba
    function [6:0] expected_seg;
        input [3:0] digit;
        case (digit)
            4'h0: expected_seg = 7'b1000000;
            4'h1: expected_seg = 7'b1111001;
            4'h2: expected_seg = 7'b0100100;
            4'h3: expected_seg = 7'b0110000;
            4'h4: expected_seg = 7'b0011001;
            4'h5: expected_seg = 7'b0010010;
            4'h6: expected_seg = 7'b0000010;
            4'h7: expected_seg = 7'b1111000;
            4'h8: expected_seg = 7'b0000000;
            4'h9: expected_seg = 7'b0011000;
            4'ha: expected_seg = 7'b0001000;
            4'hb: expected_seg = 7'b0000011;
            4'hc: expected_seg = 7'b1000110;
            4'hd: expected_seg = 7'b0100001;
            4'he: expected_seg = 7'b0000110;
            4'hf: expected_seg = 7'b0001110;
        endcase
    endfunction

    integer errors;
    integer d;

    initial begin
        errors = 0;

        // Test every hex digit on every display simultaneously
        // by putting the same digit on all 6 nibbles of iDIG
        for (d = 0; d <= 15; d = d + 1) begin
            iDIG = {4{6{1'b0}}}; // clear
            iDIG = { d[3:0], d[3:0], d[3:0], d[3:0], d[3:0], d[3:0] };
            #10;

            if (oSEG0 !== expected_seg(d[3:0])) begin
                $display("FAIL SEG0 digit %0h: got %b expected %b",
                         d, oSEG0, expected_seg(d[3:0]));
                errors = errors + 1;
            end
            if (oSEG1 !== expected_seg(d[3:0])) begin
                $display("FAIL SEG1 digit %0h: got %b expected %b",
                         d, oSEG1, expected_seg(d[3:0]));
                errors = errors + 1;
            end
            if (oSEG2 !== expected_seg(d[3:0])) begin
                $display("FAIL SEG2 digit %0h: got %b expected %b",
                         d, oSEG2, expected_seg(d[3:0]));
                errors = errors + 1;
            end
            if (oSEG3 !== expected_seg(d[3:0])) begin
                $display("FAIL SEG3 digit %0h: got %b expected %b",
                         d, oSEG3, expected_seg(d[3:0]));
                errors = errors + 1;
            end
            if (oSEG4 !== expected_seg(d[3:0])) begin
                $display("FAIL SEG4 digit %0h: got %b expected %b",
                         d, oSEG4, expected_seg(d[3:0]));
                errors = errors + 1;
            end
            if (oSEG5 !== expected_seg(d[3:0])) begin
                $display("FAIL SEG5 digit %0h: got %b expected %b",
                         d, oSEG5, expected_seg(d[3:0]));
                errors = errors + 1;
            end
        end

        // Test that each display reads its own nibble independently
        // iDIG[3:0]=0, [7:4]=1, [11:8]=2, [15:12]=3, [19:16]=4, [23:20]=5
        iDIG = 24'h543210;
        #10;
        if (oSEG0 !== expected_seg(4'h0)) begin
            $display("FAIL SEG0 nibble isolation: got %b expected %b",
                     oSEG0, expected_seg(4'h0));
            errors = errors + 1;
        end
        if (oSEG1 !== expected_seg(4'h1)) begin
            $display("FAIL SEG1 nibble isolation: got %b expected %b",
                     oSEG1, expected_seg(4'h1));
            errors = errors + 1;
        end
        if (oSEG2 !== expected_seg(4'h2)) begin
            $display("FAIL SEG2 nibble isolation: got %b expected %b",
                     oSEG2, expected_seg(4'h2));
            errors = errors + 1;
        end
        if (oSEG3 !== expected_seg(4'h3)) begin
            $display("FAIL SEG3 nibble isolation: got %b expected %b",
                     oSEG3, expected_seg(4'h3));
            errors = errors + 1;
        end
        if (oSEG4 !== expected_seg(4'h4)) begin
            $display("FAIL SEG4 nibble isolation: got %b expected %b",
                     oSEG4, expected_seg(4'h4));
            errors = errors + 1;
        end
        if (oSEG5 !== expected_seg(4'h5)) begin
            $display("FAIL SEG5 nibble isolation: got %b expected %b",
                     oSEG5, expected_seg(4'h5));
            errors = errors + 1;
        end

        $display("=========================================");
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $display("=========================================");
        $stop();
    end

endmodule
