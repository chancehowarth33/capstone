module snake_wrapper (
    input  logic clk, 
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

// Simple snake core instantiation
snake_top u_snake_top (
    .ap_clk   (clk),
    .ap_rst   (~rst_n),

    .hand_x   (hand_x),
    .hand_y   (hand_y),
    .detected (detected),

    .vga_x    (vga_x),
    .vga_y    (vga_y),
    .vsync    (vsync),
    .rst_n    (rst_n),

    .R_out    (snake_r),
    .G_out    (snake_g),
    .B_out    (snake_b)
);

// Direct output mapping
always_comb begin
    R_out = snake_r;
    G_out = snake_g;
    B_out = snake_b;
end


endmodule