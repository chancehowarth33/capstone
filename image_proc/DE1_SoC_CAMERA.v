// DE1_SoC_CAMERA.v
// Hand tracking PoC — D5M camera feed with color-based centroid detection
// and crosshair overlay on VGA output.
//
// color_detect runs on the camera pixel clock domain and outputs one tracking result per full frame (25 updates/sec).
// VGA always reads the latest pixels written to SDRAM with no buffering delay.
//
// SW[0]  : exposure direction select
//          0 = increase exposure when KEY[1] is pressed
//          1 = decrease exposure when KEY[1] is pressed
//
// SW[1]  : pong player calibration select (only active in calibration mode SW[8]=1)
//          0 = KEY[1] calibrates Player 1 color
//          1 = KEY[1] calibrates Player 2 color
//
// SW[3]  : pong game mode (ignored when SW[4], SW[6], or SW[7] are active)
//          0 = normal mode
//          1 = pong game — two players control paddles with independently
//              calibrated colors; hold both hands in centre box to start
//
// SW[4]  : catch game mode (overrides SW[3])
//          0 = normal mode
//          1 = catch game — move hand horizontally to control paddle
//
// SW[6]  : draw game mode (overrides all other game modes)
//          0 = normal mode (controlled by SW[7])
//          1 = drawing game — hand leaves a white trail on a black canvas
//              KEY[3] clears the canvas
//
// SW[7]  : snake game mode (ignored when SW[6]=1)
//          0 = normal camera/overlay view
//          1 = snake game
//
// SW[8]  : calibration mode enable
//          0 = normal tracking mode
//          1 = calibration mode
//              - draw a fixed 32x32 box in the center of the screen
//              - HEX displays the average RGB value of that center block
//              - KEY[1] captures color for the player selected by SW[1]
//
// SW[9]  : camera zoom mode
//          0 = normal sensor window
//          1 = zoomed / cropped sensor window
//
// KEY[0] : system reset
//
// KEY[1] : dual function button
//          normal mode (SW[8] = 0):
//              adjust exposure step in the direction selected by SW[0]
//          calibration mode (SW[8] = 1):
//              capture the RGB value of the center 32x32 block
//              (captures for P1 when SW[1]=0, P2 when SW[1]=1)
//
// KEY[2] : stop camera capture
// KEY[3] : start camera capture (draw game: clears the canvas)
//
// VGA mux priority (highest to lowest):
//      SW[6]=1 → draw game
//      SW[4]=1 → catch game
//      SW[3]=1 → pong game
//      SW[7]=1 → snake game
//      default → camera feed with crosshair overlay
//
// HEX display behavior:
//
// normal mode:
//      HEX5 HEX4 HEX3 HEX2 HEX1 HEX0
//      show hand position from color tracking
//      HEX3 HEX2 HEX1 HEX0 = hand_x / hand_y values
//
// calibration mode:
//      HEX5 HEX4 = center block average R
//      HEX3 HEX2 = center block average G
//      HEX1 HEX0 = center block average B
//
// LEDR : debug display (currently shows Y_Cont[9:0])

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


// Game logic wires and instantiations

// SW[1]=0 calibrates P1, SW[1]=1 calibrates P2
wire p1_capture = SW[1] ? 1'b1 : KEY[1];
wire p2_capture = SW[1] ? KEY[1] : 1'b1;

// Raw color_detect outputs — player 1 (camera clock domain)
wire [9:0] cd_overlay_x, cd_overlay_y;
wire [9:0] cd_coord_x,   cd_coord_y;
wire       cd_hand_detected;
wire [9:0] cd_box_left, cd_box_right, cd_box_top, cd_box_bottom;

// Raw color_detect outputs — player 2 (camera clock domain)
wire [9:0] cd2_overlay_x, cd2_overlay_y;
wire [9:0] cd2_coord_x,   cd2_coord_y;
wire       cd2_hand_detected;
wire [9:0] cd2_center_avgR, cd2_center_avgG, cd2_center_avgB;
wire [9:0] cd2_cal_sample_R, cd2_cal_sample_G, cd2_cal_sample_B;
wire       cd2_cal_valid;
wire [9:0] cd2_box_left, cd2_box_right, cd2_box_top, cd2_box_bottom;

// Synchronized outputs — player 1 (VGA clock domain)
reg [9:0] overlay_x, overlay_y;
reg [9:0] coord_x,   coord_y;
reg       hand_detected;
reg [9:0] box_left_sync, box_right_sync, box_top_sync, box_bottom_sync;

// CDC intermediate stage — player 1
reg [9:0] s1_overlay_x, s1_overlay_y;
reg [9:0] s1_coord_x,   s1_coord_y;
reg       s1_hand_detected;
reg [9:0] s1_box_left, s1_box_right, s1_box_top, s1_box_bottom;

// Synchronized outputs — player 2 (VGA clock domain)
reg [9:0] p2_coord_y;
reg       p2_detected;
reg [9:0] s1_p2_coord_y;
reg       s1_p2_detected;

// P2 calibration / center-block values synced to VGA domain (for HEX display)
reg [9:0] p2_center_avgR,  p2_center_avgG,  p2_center_avgB;
reg [9:0] p2_cal_sample_R, p2_cal_sample_G, p2_cal_sample_B;
reg       p2_cal_valid;
reg [9:0] s1_p2_center_avgR, s1_p2_center_avgG, s1_p2_center_avgB;
reg [9:0] s1_p2_cal_sample_R, s1_p2_cal_sample_G, s1_p2_cal_sample_B;
reg       s1_p2_cal_valid;

// P2 overlay position synced to VGA domain (for pong cursor)
reg [9:0] p2_overlay_x, p2_overlay_y;
reg [9:0] s1_p2_overlay_x, s1_p2_overlay_y;

wire [9:0] final_R, final_G, final_B;
wire VGA_CTRL_CLK;
wire auto_start;

// color detect  and overlay wires

// box_left/right/top/bottom are now reg (CDC'd) — see declarations above
// when calibrate is high, show a fixed box in the center of the screen for camera calibration.
// otherwise, show the tracking box and crosshair based on detected hand position.
wire calibrate;
assign calibrate = SW[8];

// game overlay wires

// when SW[7] is high, override VGA input to the overlay and show a white dot at the detected hand position on a black background
wire game_mode;
assign game_mode = SW[7];

// Instantiate new RGB values for game mode output from the overlay
wire [9:0] game_R, game_G, game_B;
wire [9:0] draw_R, draw_G, draw_B;
wire [9:0] catch_R, catch_G, catch_B;
wire [9:0] mux_R, mux_G, mux_B;

wire draw_mode;
assign draw_mode = SW[6];

// SW[3] = pong game mode
wire pong_mode;
assign pong_mode = SW[3];
wire [9:0] pong_R, pong_G, pong_B;

// SW[4] = catch game mode
wire catch_mode;
assign catch_mode = SW[4];

// Draw game — pen up/down and brush size controls
wire pen_down;
assign pen_down = SW[5]; // SW[5]=1 draws, SW[5]=0 lifts the pen

reg  [1:0] brush_size;
reg        key1_prev;
wire       key1_fall = key1_prev && !KEY[1]; // falling edge = button press (active-low)

always @(posedge VGA_CTRL_CLK or negedge DLY_RST_2) begin
    if (!DLY_RST_2) begin
        brush_size <= 2'd0;
        key1_prev  <= 1'b1;
    end else begin
        key1_prev <= KEY[1];
        if (draw_mode && key1_fall)
            brush_size <= (brush_size == 2'd2) ? 2'd0 : brush_size + 2'd1;
    end
end


//=============================================================================
// Static assignments
//=============================================================================

assign D5M_TRIGGER  = 1'b1;
assign D5M_RESET_N  = DLY_RST_1;
assign VGA_CTRL_CLK = VGA_CLK;
assign LEDR[0] = cal_valid; // debug: indicates when a new center block RGB value is captured in calibration mode
assign LEDR[9:1] = 9'b0; // turn off other LEDs
assign auto_start   = (KEY[0] && DLY_RST_3 && !DLY_RST_4) ? 1'b1 : 1'b0;

// Route overlay output to VGA DAC (top 8 of 10 bits)
/*assign VGA_R = final_R[9:2];
assign VGA_G = final_G[9:2];
assign VGA_B = final_B[9:2];
*/

// Priority: draw (SW[6]) > catch (SW[4]) > pong (SW[3]) > snake (SW[7]) > camera
assign mux_R = draw_mode ? draw_R : (catch_mode ? catch_R : (pong_mode ? pong_R : (game_mode ? game_R : final_R)));
assign mux_G = draw_mode ? draw_G : (catch_mode ? catch_G : (pong_mode ? pong_G : (game_mode ? game_G : final_G)));
assign mux_B = draw_mode ? draw_B : (catch_mode ? catch_B : (pong_mode ? pong_B : (game_mode ? game_B : final_B)));

assign VGA_R = mux_R[9:2];
assign VGA_G = mux_G[9:2];
assign VGA_B = mux_B[9:2];

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
// u5 — 7-segment: show detected block coordinates and detected flag
// HEX5/4 = hand_y, HEX3/2 = hand_x, HEX1 = detected flag, HEX0 = unused
//=============================================================================

// Calibration signals — raw camera domain
wire [9:0] cd_center_avgR, cd_center_avgG, cd_center_avgB;
wire [9:0] cd_cal_sample_R, cd_cal_sample_G, cd_cal_sample_B;
wire       cd_cal_valid;

// Synchronized to VGA domain
reg [9:0] center_avgR, center_avgG, center_avgB;
reg [9:0] cal_sample_R, cal_sample_G, cal_sample_B;
reg       cal_valid;

// CDC intermediate stage for calibration signals
reg [9:0] s1_center_avgR, s1_center_avgG, s1_center_avgB;
reg [9:0] s1_cal_sample_R, s1_cal_sample_G, s1_cal_sample_B;
reg       s1_cal_valid;

// Camera pixel coordinates derived from CCD_Capture counters
wire [9:0] cam_x = X_Cont[10:1];
wire [9:0] cam_y = Y_Cont[10:1];
wire [23:0] hex_data;

// In calibration mode, show whichever player is selected by SW[1]
assign hex_data = calibrate
                ? (SW[1]
                    ? (p2_cal_valid
                        ? {p2_cal_sample_R[9:2], p2_cal_sample_G[9:2], p2_cal_sample_B[9:2]}
                        : {p2_center_avgR[9:2],  p2_center_avgG[9:2],  p2_center_avgB[9:2]})
                    : (cal_valid
                        ? {cal_sample_R[9:2], cal_sample_G[9:2], cal_sample_B[9:2]}
                        : {center_avgR[9:2],  center_avgG[9:2],  center_avgB[9:2]}))
                : {2'b00, overlay_y, 2'b00, overlay_x};

SEG7_LUT_6 u5 (
    .oSEG0(HEX0), .oSEG1(HEX1),
    .oSEG2(HEX2), .oSEG3(HEX3),
    .oSEG4(HEX4), .oSEG5(HEX5),
    .iDIG (hex_data)
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
    .iEXPOSURE_ADJ  (calibrate ? 1'b1 : (draw_mode ? 1'b1 : KEY[1])), // calibrate/draw modes block KEY[1] from adjusting exposure
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

// color_detect runs directly on the camera pixel clock domain,
// bypassing the SDRAM/VGA pipeline for lower latency tracking.
color_detect u_detect (
    .clk          (D5M_PIXLCLK),
    .rst_n        (DLY_RST_2),
    .fval         (rCCD_FVAL),      // camera frame valid: falling edge = frame end
    .active       (sCCD_DVAL),      // valid pixel from RAW2RGB (even X and Y only)
    .calibrate    (calibrate),
    .capture_btn_n(p1_capture),
    .R            (sCCD_R[11:2]),   // 12-bit → top 10 bits
    .G            (sCCD_G[11:2]),
    .B            (sCCD_B[11:2]),
    .vga_x        (cam_x),          // X_Cont[10:1]: 0–639
    .vga_y        (cam_y),          // Y_Cont[10:1]: 0–479
    .overlay_x    (cd_overlay_x),
    .overlay_y    (cd_overlay_y),
    .coord_x      (cd_coord_x),
    .coord_y      (cd_coord_y),
    .box_left     (cd_box_left),
    .box_right    (cd_box_right),
    .box_top      (cd_box_top),
    .box_bottom   (cd_box_bottom),
    .detected     (cd_hand_detected),
    .center_avgR  (cd_center_avgR),
    .center_avgG  (cd_center_avgG),
    .center_avgB  (cd_center_avgB),
    .cal_sample_R (cd_cal_sample_R),
    .cal_sample_G (cd_cal_sample_G),
    .cal_sample_B (cd_cal_sample_B),
    .cal_valid    (cd_cal_valid)
);


//=============================================================================
// CDC synchronizers: camera clock domain → VGA clock domain
// Values update once per camera frame and are stable for millions of cycles,
// so 2-FF synchronizers are sufficient.
//=============================================================================

always @(posedge VGA_CTRL_CLK or negedge DLY_RST_2) begin
    if (!DLY_RST_2) begin
        s1_overlay_x   <= 0; overlay_x    <= 0;
        s1_overlay_y   <= 0; overlay_y    <= 0;
        s1_coord_x     <= 0; coord_x      <= 0;
        s1_coord_y     <= 0; coord_y      <= 0;
        s1_hand_detected <= 0; hand_detected <= 0;
        s1_box_left    <= 0; box_left_sync  <= 0;
        s1_box_right   <= 0; box_right_sync <= 0;
        s1_box_top     <= 0; box_top_sync   <= 0;
        s1_box_bottom  <= 0; box_bottom_sync<= 0;
        s1_center_avgR <= 0; center_avgR  <= 0;
        s1_center_avgG <= 0; center_avgG  <= 0;
        s1_center_avgB <= 0; center_avgB  <= 0;
        s1_cal_sample_R <= 0; cal_sample_R <= 0;
        s1_cal_sample_G <= 0; cal_sample_G <= 0;
        s1_cal_sample_B <= 0; cal_sample_B <= 0;
        s1_cal_valid   <= 0; cal_valid    <= 0;
    end else begin
        s1_overlay_x   <= cd_overlay_x;    overlay_x    <= s1_overlay_x;
        s1_overlay_y   <= cd_overlay_y;    overlay_y    <= s1_overlay_y;
        s1_coord_x     <= cd_coord_x;      coord_x      <= s1_coord_x;
        s1_coord_y     <= cd_coord_y;      coord_y      <= s1_coord_y;
        s1_hand_detected <= cd_hand_detected; hand_detected <= s1_hand_detected;
        s1_box_left    <= cd_box_left;     box_left_sync  <= s1_box_left;
        s1_box_right   <= cd_box_right;    box_right_sync <= s1_box_right;
        s1_box_top     <= cd_box_top;      box_top_sync   <= s1_box_top;
        s1_box_bottom  <= cd_box_bottom;   box_bottom_sync<= s1_box_bottom;
        s1_center_avgR <= cd_center_avgR;  center_avgR  <= s1_center_avgR;
        s1_center_avgG <= cd_center_avgG;  center_avgG  <= s1_center_avgG;
        s1_center_avgB <= cd_center_avgB;  center_avgB  <= s1_center_avgB;
        s1_cal_sample_R <= cd_cal_sample_R; cal_sample_R <= s1_cal_sample_R;
        s1_cal_sample_G <= cd_cal_sample_G; cal_sample_G <= s1_cal_sample_G;
        s1_cal_sample_B <= cd_cal_sample_B; cal_sample_B <= s1_cal_sample_B;
        s1_cal_valid   <= cd_cal_valid;    cal_valid    <= s1_cal_valid;
    end
end

//=============================================================================
// u_detect2 — player 2 color tracker (independent calibration via p2_capture)
//=============================================================================

color_detect u_detect2 (
    .clk          (D5M_PIXLCLK),
    .rst_n        (DLY_RST_2),
    .fval         (rCCD_FVAL),
    .active       (sCCD_DVAL),
    .calibrate    (calibrate),
    .capture_btn_n(p2_capture),
    .R            (sCCD_R[11:2]),
    .G            (sCCD_G[11:2]),
    .B            (sCCD_B[11:2]),
    .vga_x        (cam_x),
    .vga_y        (cam_y),
    .overlay_x    (cd2_overlay_x),
    .overlay_y    (cd2_overlay_y),
    .coord_x      (cd2_coord_x),
    .coord_y      (cd2_coord_y),
    .box_left     (cd2_box_left),
    .box_right    (cd2_box_right),
    .box_top      (cd2_box_top),
    .box_bottom   (cd2_box_bottom),
    .detected     (cd2_hand_detected),
    .center_avgR  (cd2_center_avgR),
    .center_avgG  (cd2_center_avgG),
    .center_avgB  (cd2_center_avgB),
    .cal_sample_R (cd2_cal_sample_R),
    .cal_sample_G (cd2_cal_sample_G),
    .cal_sample_B (cd2_cal_sample_B),
    .cal_valid    (cd2_cal_valid)
);

// CDC for player 2 (coord_y, detected, and calibration signals for HEX display)
always @(posedge VGA_CTRL_CLK or negedge DLY_RST_2) begin
    if (!DLY_RST_2) begin
        s1_p2_coord_y      <= 0; p2_coord_y      <= 0;
        s1_p2_detected     <= 0; p2_detected     <= 0;
        s1_p2_overlay_x    <= 0; p2_overlay_x    <= 0;
        s1_p2_overlay_y    <= 0; p2_overlay_y    <= 0;
        s1_p2_center_avgR  <= 0; p2_center_avgR  <= 0;
        s1_p2_center_avgG  <= 0; p2_center_avgG  <= 0;
        s1_p2_center_avgB  <= 0; p2_center_avgB  <= 0;
        s1_p2_cal_sample_R <= 0; p2_cal_sample_R <= 0;
        s1_p2_cal_sample_G <= 0; p2_cal_sample_G <= 0;
        s1_p2_cal_sample_B <= 0; p2_cal_sample_B <= 0;
        s1_p2_cal_valid    <= 0; p2_cal_valid    <= 0;
    end else begin
        s1_p2_coord_y      <= cd2_coord_y;       p2_coord_y      <= s1_p2_coord_y;
        s1_p2_detected     <= cd2_hand_detected;  p2_detected     <= s1_p2_detected;
        s1_p2_overlay_x    <= cd2_overlay_x;      p2_overlay_x    <= s1_p2_overlay_x;
        s1_p2_overlay_y    <= cd2_overlay_y;      p2_overlay_y    <= s1_p2_overlay_y;
        s1_p2_center_avgR  <= cd2_center_avgR;    p2_center_avgR  <= s1_p2_center_avgR;
        s1_p2_center_avgG  <= cd2_center_avgG;    p2_center_avgG  <= s1_p2_center_avgG;
        s1_p2_center_avgB  <= cd2_center_avgB;    p2_center_avgB  <= s1_p2_center_avgB;
        s1_p2_cal_sample_R <= cd2_cal_sample_R;   p2_cal_sample_R <= s1_p2_cal_sample_R;
        s1_p2_cal_sample_G <= cd2_cal_sample_G;   p2_cal_sample_G <= s1_p2_cal_sample_G;
        s1_p2_cal_sample_B <= cd2_cal_sample_B;   p2_cal_sample_B <= s1_p2_cal_sample_B;
        s1_p2_cal_valid    <= cd2_cal_valid;       p2_cal_valid    <= s1_p2_cal_valid;
    end
end

//=============================================================================
// u_overlay — crosshair renderer
//=============================================================================


overlay u_overlay (
    .R_in      (oVGA_R),
    .G_in      (oVGA_G),
    .B_in      (oVGA_B),
    .vga_x     (oVGA_X),
    .vga_y     (oVGA_Y),
    .overlay_x (overlay_x),
    .overlay_y (overlay_y),
    .box_left  (box_left_sync),
    .box_right (box_right_sync),
    .box_top   (box_top_sync),
    .box_bottom(box_bottom_sync),
    .detected  (hand_detected),
    .calibrate (calibrate),
    .R_out     (final_R),
    .G_out     (final_G),
    .B_out     (final_B)
);


// Draw game — hand leaves a white trail; KEY[3] clears the canvas
// SW[5]=1 pen down (draw), SW[5]=0 pen up (no paint)
// KEY[1] cycles brush size: small (8px) -> medium (16px) -> large (32px)
draw_game u_draw (
    .clk        (VGA_CTRL_CLK),
    .rst_n      (DLY_RST_2),
    .vsync      (VGA_VS),
    .detected   (hand_detected),
    .overlay_x  (coord_x),
    .overlay_y  (coord_y),
    .vga_x      (oVGA_X),
    .vga_y      (oVGA_Y),
    .clear_n    (KEY[3]),
    .pen_down   (pen_down),
    .brush_size (brush_size),
    .R_out      (draw_R),
    .G_out      (draw_G),
    .B_out      (draw_B)
);

// Catch game — SW[4]=1 to activate, hand X controls paddle
catch_game u_catch (
    .clk       (VGA_CTRL_CLK),
    .rst_n     (DLY_RST_2),
    .vsync     (VGA_VS),
    .detected  (hand_detected),
    .overlay_x (coord_x),
    .overlay_y (coord_y),
    .vga_x     (oVGA_X),
    .vga_y     (oVGA_Y),
    .R_out     (catch_R),
    .G_out     (catch_G),
    .B_out     (catch_B)
);

// Pong — SW[3]=1 to activate; SW[1] selects which player to calibrate
pong_game u_pong (
    .clk        (VGA_CTRL_CLK),
    .rst_n      (DLY_RST_2),
    .vsync      (VGA_VS),
    .p1_x       (overlay_x),
    .p1_y       (coord_y),
    .p2_x       (p2_overlay_x),
    .p2_y       (p2_coord_y),
    .p1_detected(hand_detected),
    .p2_detected(p2_detected),
    .vga_x      (oVGA_X),
    .vga_y      (oVGA_Y),
    .R_out      (pong_R),
    .G_out      (pong_G),
    .B_out      (pong_B)
);

// Snake game
snake_wrapper u_game (
    .clk      (VGA_CTRL_CLK),
    .rst_n    (DLY_RST_2),

    .coord_x   (coord_x),
    .coord_y   (coord_y),
    .detected (hand_detected),
    .game_mode (game_mode),

    .vga_x    (oVGA_X),
    .vga_y    (oVGA_Y),
    .vsync    (VGA_VS),

    .R_out    (game_R),
    .G_out    (game_G),
    .B_out    (game_B)
);





endmodule