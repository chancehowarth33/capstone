// DE1_SoC_CAMERA.v
// Hand tracking PoC — D5M camera feed with color-based centroid detection
// and crosshair overlay on VGA output.
//
// SW[0]  : camera exposure decrease
// SW[9]  : zoom mode
// KEY[0] : reset
// KEY[1] : exposure adjust
// KEY[2] : stop capture
// KEY[3] : start capture
//
// HEX0/1 : hand X coordinate (0-639)
// HEX2/3 : hand Y coordinate (0-479)
// HEX4   : shows detected flag
// LEDR   : Y frame counter (debug)

module DE1_SoC_CAMERA(

      ///////// ADC /////////
      inout              ADC_CS_N,
      output             ADC_DIN,
      input              ADC_DOUT,
      output             ADC_SCLK,

      ///////// AUD /////////
      input              AUD_ADCDAT,
      inout              AUD_ADCLRCK,
      inout              AUD_BCLK,
      output             AUD_DACDAT,
      inout              AUD_DACLRCK,
      output             AUD_XCK,

      ///////// CLOCK2 /////////
      input              CLOCK2_50,

      ///////// CLOCK3 /////////
      input              CLOCK3_50,

      ///////// CLOCK4 /////////
      input              CLOCK4_50,

      ///////// CLOCK /////////
      input              CLOCK_50,

      ///////// DRAM /////////
      output      [12:0] DRAM_ADDR,
      output      [1:0]  DRAM_BA,
      output             DRAM_CAS_N,
      output             DRAM_CKE,
      output             DRAM_CLK,
      output             DRAM_CS_N,
      inout       [15:0] DRAM_DQ,
      output             DRAM_LDQM,
      output             DRAM_RAS_N,
      output             DRAM_UDQM,
      output             DRAM_WE_N,

      ///////// FAN /////////
      output             FAN_CTRL,

      ///////// FPGA /////////
      output             FPGA_I2C_SCLK,
      inout              FPGA_I2C_SDAT,

      ///////// GPIO /////////
      inout     [35:0]   GPIO_0,

      ///////// HEX /////////
      output      [6:0]  HEX0,
      output      [6:0]  HEX1,
      output      [6:0]  HEX2,
      output      [6:0]  HEX3,
      output      [6:0]  HEX4,
      output      [6:0]  HEX5,

      ///////// IRDA /////////
      input              IRDA_RXD,
      output             IRDA_TXD,

      ///////// KEY /////////
      input       [3:0]  KEY,

      ///////// LEDR /////////
      output      [9:0]  LEDR,

      ///////// PS2 /////////
      inout              PS2_CLK,
      inout              PS2_CLK2,
      inout              PS2_DAT,
      inout              PS2_DAT2,

      ///////// SW /////////
      input       [9:0]  SW,

      ///////// TD /////////
      input              TD_CLK27,
      input      [7:0]   TD_DATA,
      input              TD_HS,
      output             TD_RESET_N,
      input              TD_VS,

      ///////// VGA /////////
      output      [7:0]  VGA_B,
      output             VGA_BLANK_N,
      output             VGA_CLK,
      output      [7:0]  VGA_G,
      output             VGA_HS,
      output      [7:0]  VGA_R,
      output             VGA_SYNC_N,
      output             VGA_VS,

      ///////// D5M Camera /////////
      input       [11:0] D5M_D,
      input              D5M_FVAL,
      input              D5M_LVAL,
      input              D5M_PIXLCLK,
      output             D5M_RESET_N,
      output             D5M_SCLK,
      inout              D5M_SDATA,
      input              D5M_STROBE,
      output             D5M_TRIGGER,
      output             D5M_XCLKIN
);

//=============================================================================
// Wire / Reg declarations
//=============================================================================

wire [15:0] Read_DATA1;
wire [15:0] Read_DATA2;

wire [11:0] mCCD_DATA;
wire        mCCD_DVAL;
wire [15:0] X_Cont;
wire [15:0] Y_Cont;
wire [31:0] Frame_Cont;

wire DLY_RST_0, DLY_RST_1, DLY_RST_2, DLY_RST_3, DLY_RST_4;
wire Read;

reg  [11:0] rCCD_DATA;
reg         rCCD_LVAL;
reg         rCCD_FVAL;

wire [11:0] sCCD_R, sCCD_G, sCCD_B;
wire        sCCD_DVAL;

wire sdram_ctrl_clk;

wire [9:0] oVGA_R, oVGA_G, oVGA_B;
wire [9:0] oVGA_X, oVGA_Y;
wire       oVGA_ACTIVE;

wire [9:0] hand_x, hand_y;
wire       hand_detected;

wire [9:0] final_R, final_G, final_B;

wire auto_start;

//=============================================================================
// Static assignments
//=============================================================================

assign D5M_TRIGGER  = 1'b1;
assign D5M_RESET_N  = DLY_RST_1;
assign VGA_CTRL_CLK = VGA_CLK;
assign LEDR         = Y_Cont[9:0];
assign auto_start   = (KEY[0] && DLY_RST_3 && !DLY_RST_4) ? 1'b1 : 1'b0;

// Route overlay output to VGA DAC (top 8 of 10 bits)
assign VGA_R = final_R[9:2];
assign VGA_G = final_G[9:2];
assign VGA_B = final_B[9:2];

//=============================================================================
// Camera input latch
//=============================================================================

always @(posedge D5M_PIXLCLK) begin
    rCCD_DATA <= D5M_D;
    rCCD_LVAL <= D5M_LVAL;
    rCCD_FVAL <= D5M_FVAL;
end

//=============================================================================
// u2 — Reset sequencer
//=============================================================================

Reset_Delay u2 (
    .iCLK  (CLOCK_50),
    .iRST  (KEY[0]),
    .oRST_0(DLY_RST_0),
    .oRST_1(DLY_RST_1),
    .oRST_2(DLY_RST_2),
    .oRST_3(DLY_RST_3),
    .oRST_4(DLY_RST_4)
);

//=============================================================================
// u3 — CCD capture
//=============================================================================

CCD_Capture u3 (
    .oDATA      (mCCD_DATA),
    .oDVAL      (mCCD_DVAL),
    .oX_Cont    (X_Cont),
    .oY_Cont    (Y_Cont),
    .oFrame_Cont(Frame_Cont),
    .iDATA      (rCCD_DATA),
    .iFVAL      (rCCD_FVAL),
    .iLVAL      (rCCD_LVAL),
    .iSTART     (!KEY[3] | auto_start),
    .iEND       (!KEY[2]),
    .iCLK       (~D5M_PIXLCLK),
    .iRST       (DLY_RST_2)
);

//=============================================================================
// u4 — RAW2RGB Bayer demosaicing
//=============================================================================

RAW2RGB u4 (
    .iCLK   (D5M_PIXLCLK),
    .iRST   (DLY_RST_1),
    .iDATA  (mCCD_DATA),
    .iDVAL  (mCCD_DVAL),
    .oRed   (sCCD_R),
    .oGreen (sCCD_G),
    .oBlue  (sCCD_B),
    .oDVAL  (sCCD_DVAL),
    .iX_Cont(X_Cont),
    .iY_Cont(Y_Cont)
);

//=============================================================================
// u5 — 7-segment: HEX1/0 = hand X, HEX3/2 = hand Y, HEX4 = detected flag
//=============================================================================

reg [9:0] sample_R, sample_G, sample_B;

always @(posedge VGA_CLK) begin
    if (oVGA_X == 10'd320 && oVGA_Y == 10'd240) begin
        sample_R <= oVGA_R;
        sample_G <= oVGA_G;
        sample_B <= oVGA_B;
    end
end

SEG7_LUT_6 u5 (
    .oSEG0(HEX0), .oSEG1(HEX1),   // shows R value in hex
    .oSEG2(HEX2), .oSEG3(HEX3),   // shows B value in hex
    .oSEG4(HEX4), .oSEG5(HEX5),   // shows G value in hex
    .iDIG({sample_G[7:0], sample_B[7:0], sample_R[7:0]})
);

//=============================================================================
// u6 — PLL
//=============================================================================

sdram_pll u6 (
    .refclk  (CLOCK_50),
    .rst     (1'b0),
    .outclk_0(sdram_ctrl_clk),
    .outclk_1(DRAM_CLK),
    .outclk_2(D5M_XCLKIN),
    .outclk_3(VGA_CLK)
);

//=============================================================================
// u7 — SDRAM frame buffer (raw RGB, no image processing)
//=============================================================================

Sdram_Control u7 (
    .RESET_N      (KEY[0]),
    .CLK          (sdram_ctrl_clk),

    .WR1_DATA     ({1'b0, sCCD_G[11:7], sCCD_B[11:2]}),
    .WR1          (sCCD_DVAL),
    .WR1_ADDR     (0),
    .WR1_MAX_ADDR (640*480),
    .WR1_LENGTH   (8'h50),
    .WR1_LOAD     (!DLY_RST_0),
    .WR1_CLK      (~D5M_PIXLCLK),

    .WR2_DATA     ({1'b0, sCCD_G[6:2], sCCD_R[11:2]}),
    .WR2          (sCCD_DVAL),
    .WR2_ADDR     (23'h100000),
    .WR2_MAX_ADDR (23'h100000 + 640*480),
    .WR2_LENGTH   (8'h50),
    .WR2_LOAD     (!DLY_RST_0),
    .WR2_CLK      (~D5M_PIXLCLK),

    .RD1_DATA     (Read_DATA1),
    .RD1          (Read),
    .RD1_ADDR     (0),
    .RD1_MAX_ADDR (640*480),
    .RD1_LENGTH   (8'h50),
    .RD1_LOAD     (!DLY_RST_0),
    .RD1_CLK      (~VGA_CTRL_CLK),

    .RD2_DATA     (Read_DATA2),
    .RD2          (Read),
    .RD2_ADDR     (23'h100000),
    .RD2_MAX_ADDR (23'h100000 + 640*480),
    .RD2_LENGTH   (8'h50),
    .RD2_LOAD     (!DLY_RST_0),
    .RD2_CLK      (~VGA_CTRL_CLK),

    .SA           (DRAM_ADDR),
    .BA           (DRAM_BA),
    .CS_N         (DRAM_CS_N),
    .CKE          (DRAM_CKE),
    .RAS_N        (DRAM_RAS_N),
    .CAS_N        (DRAM_CAS_N),
    .WE_N         (DRAM_WE_N),
    .DQ           (DRAM_DQ),
    .DQM          ({DRAM_UDQM, DRAM_LDQM})
);

//=============================================================================
// u8 — I2C camera configuration
//=============================================================================

I2C_CCD_Config u8 (
    .iCLK           (CLOCK2_50),
    .iRST_N         (DLY_RST_2),
    .iEXPOSURE_ADJ  (KEY[1]),
    .iEXPOSURE_DEC_p(SW[0]),
    .iZOOM_MODE_SW  (SW[9]),
    .I2C_SCLK       (D5M_SCLK),
    .I2C_SDAT       (D5M_SDATA)
);

//=============================================================================
// u1 — VGA controller (with scan coordinate outputs)
//=============================================================================

VGA_Controller u1 (
    .oRequest    (Read),
    .iRed        (Read_DATA2[9:0]),
    .iGreen      ({Read_DATA1[14:10], Read_DATA2[14:10]}),
    .iBlue       (Read_DATA1[9:0]),
    .oVGA_R      (oVGA_R),
    .oVGA_G      (oVGA_G),
    .oVGA_B      (oVGA_B),
    .oVGA_H_SYNC (VGA_HS),
    .oVGA_V_SYNC (VGA_VS),
    .oVGA_SYNC   (VGA_SYNC_N),
    .oVGA_BLANK  (VGA_BLANK_N),
    .oVGA_X      (oVGA_X),
    .oVGA_Y      (oVGA_Y),
    .oVGA_ACTIVE (oVGA_ACTIVE),
    .iCLK        (VGA_CTRL_CLK),
    .iRST_N      (DLY_RST_2),
    .iZOOM_MODE_SW(SW[9])
);

//=============================================================================
// u_detect — color centroid tracker
//=============================================================================

color_detect u_detect (
    .clk     (VGA_CTRL_CLK),
    .vsync   (VGA_VS),
    .active  (oVGA_ACTIVE),
    .R       (oVGA_R),
    .G       (oVGA_G),
    .B       (oVGA_B),
    .vga_x   (oVGA_X),
    .vga_y   (oVGA_Y),
    .hand_x  (hand_x),
    .hand_y  (hand_y),
    .detected(hand_detected)
);

//=============================================================================
// u_overlay — crosshair renderer
//=============================================================================

overlay u_overlay (
    .R_in    (oVGA_R),
    .G_in    (oVGA_G),
    .B_in    (oVGA_B),
    .vga_x   (oVGA_X),
    .vga_y   (oVGA_Y),
    .hand_x  (hand_x),
    .hand_y  (hand_y),
    .detected(hand_detected),
    .R_out   (final_R),
    .G_out   (final_G),
    .B_out   (final_B)
);

endmodule