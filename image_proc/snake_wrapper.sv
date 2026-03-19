module snake_wrapper (
    input  logic    clk, // will probably need to map clock
    input  logic    rst_n,

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


// Temporary Signals, waiting for catapult results
logic [9:0] snake_r_catapult;
logic [9:0] snake_g_catapult;
logic [9:0] snake_b_catapult;

// Combinational block, right now just places a dot where the hand is detected
// TO-DO ROUTE TO SNAKE FILE
always_comb begin
    snake_r_catapult = 10'd0;
    snake_g_catapult = 10'd0;
    snake_b_catapult = 10'd0;

    if (detected && (vga_x == hand_x) && (vga_y == hand_y)) begin
        snake_r_catapult = 10'h3FF;
        snake_g_catapult = 10'h3FF;
        snake_b_catapult = 10'h3FF;
    end
end

// RGB DISPLAY OUTPUT 
always_comb begin
    R_out = snake_r_catapult;
    G_out = snake_g_catapult;
    B_out = snake_b_catapult;
end

// Instantiate snake catapult here

endmodule