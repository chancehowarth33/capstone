module snake_wrapper (
    input  logic clk, // will probably need to map clock
    input  logic rst_n,

    input  logic [9:0]  hand_x, // From color_detect
    input  logic [9:0]  hand_y,
    input  logic        detected,

    input  logic [9:0]  vga_x, // VGA Controller
    input  logic [9:0]  vga_y,
    input  logic        vsync,

    output logic [9:0]  R_out, // VGA Output
    output logic [9:0]  G_out,
    output logic [9:0]  B_out
);

// 
logic [9:0] snake_r;
logic [9:0] snake_g;
logic [9:0] snake_b;

// new signals from vitis, wants valid signal before updating
// we an use these for smoothness
// first pass will not use them
logic snake_r_vld;
logic snake_g_vld;
logic snake_b_vld;

// Snake core instantiation
snake_top u_snake_top (
    .ap_clk(clk),
    .ap_rst(~rst_n),
    .ap_start(1'b1),
    .ap_done(), // States left unconnected
    .ap_idle(),
    .ap_ready(),

    .hand_x(hand_x),
    .hand_y(hand_y),
    .detected(detected),

    .vga_x(vga_x),
    .vga_y(vga_y),
    .vsync(vsync),
    .rst_n(rst_n),

    .R_out(snake_r),
    .R_out_ap_vld(snake_r_vld), // RGB Checks not used yet, we can use them in the commented block on bottom.
    .G_out(snake_g),
    .G_out_ap_vld(snake_g_vld),
    .B_out(snake_b),
    .B_out_ap_vld(snake_b_vld)
);

// drive outputs directly WITHOUT USING VALID SIGNALS
always_comb begin
    R_out = snake_r;
    G_out = snake_g;
    B_out = snake_b;
end

// uses valid signals in case display is unstable
// reaplce comb block on top.
/*
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        R_out <= 10'd0;
        G_out <= 10'd0;
        B_out <= 10'd0;
    end else if (snake_r_vld && snake_g_vld && snake_b_vld) begin
        R_out <= snake_r;
        G_out <= snake_g;
        B_out <= snake_b;
    end
end
*/

endmodule