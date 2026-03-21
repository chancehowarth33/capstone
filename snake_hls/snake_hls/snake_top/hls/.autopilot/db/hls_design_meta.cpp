#include "hls_design_meta.h"
const Port_Property HLS_Design_Meta::port_props[]={
	Port_Property("ap_clk", 1, hls_in, -1, "", "", 1),
	Port_Property("ap_rst", 1, hls_in, -1, "", "", 1),
	Port_Property("ap_start", 1, hls_in, -1, "", "", 1),
	Port_Property("ap_done", 1, hls_out, -1, "", "", 1),
	Port_Property("ap_idle", 1, hls_out, -1, "", "", 1),
	Port_Property("ap_ready", 1, hls_out, -1, "", "", 1),
	Port_Property("hand_x", 10, hls_in, 0, "ap_none", "in_data", 1),
	Port_Property("hand_y", 10, hls_in, 1, "ap_none", "in_data", 1),
	Port_Property("detected", 1, hls_in, 2, "ap_none", "in_data", 1),
	Port_Property("vga_x", 10, hls_in, 3, "ap_none", "in_data", 1),
	Port_Property("vga_y", 10, hls_in, 4, "ap_none", "in_data", 1),
	Port_Property("vsync", 1, hls_in, 5, "ap_none", "in_data", 1),
	Port_Property("rst_n", 1, hls_in, 6, "ap_none", "in_data", 1),
	Port_Property("R_out", 10, hls_out, 7, "ap_vld", "out_data", 1),
	Port_Property("R_out_ap_vld", 1, hls_out, 7, "ap_vld", "out_vld", 1),
	Port_Property("G_out", 10, hls_out, 8, "ap_vld", "out_data", 1),
	Port_Property("G_out_ap_vld", 1, hls_out, 8, "ap_vld", "out_vld", 1),
	Port_Property("B_out", 10, hls_out, 9, "ap_vld", "out_data", 1),
	Port_Property("B_out_ap_vld", 1, hls_out, 9, "ap_vld", "out_vld", 1),
};
const char* HLS_Design_Meta::dut_name = "snake_top";
