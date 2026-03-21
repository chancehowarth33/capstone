set moduleName snake_top
set isTopModule 1
set isCombinational 0
set isDatapathOnly 0
set isPipelined 0
set isPipelined_legacy 0
set pipeline_type none
set FunctionProtocol ap_ctrl_hs
set restart_counter_num 0
set isOneStateSeq 0
set ProfileFlag 0
set StallSigGenFlag 0
set isEnableWaveformDebug 1
set hasInterrupt 0
set DLRegFirstOffset 0
set DLRegItemOffset 0
set svuvm_can_support 1
set cdfgNum 9
set C_modelName {snake_top}
set C_modelType { void 0 }
set ap_memory_interface_dict [dict create]
set C_modelArgList {
	{ hand_x int 10 regular  }
	{ hand_y int 10 regular  }
	{ detected uint 1 regular  }
	{ vga_x int 10 regular  }
	{ vga_y int 10 regular  }
	{ vsync uint 1 regular  }
	{ rst_n uint 1 regular  }
	{ R_out int 10 regular {pointer 1}  }
	{ G_out int 10 regular {pointer 1}  }
	{ B_out int 10 regular {pointer 1}  }
}
set hasAXIMCache 0
set l_AXIML2Cache [list]
set AXIMCacheInstDict [dict create]
set C_modelArgMapList {[ 
	{ "Name" : "hand_x", "interface" : "wire", "bitwidth" : 10, "direction" : "READONLY"} , 
 	{ "Name" : "hand_y", "interface" : "wire", "bitwidth" : 10, "direction" : "READONLY"} , 
 	{ "Name" : "detected", "interface" : "wire", "bitwidth" : 1, "direction" : "READONLY"} , 
 	{ "Name" : "vga_x", "interface" : "wire", "bitwidth" : 10, "direction" : "READONLY"} , 
 	{ "Name" : "vga_y", "interface" : "wire", "bitwidth" : 10, "direction" : "READONLY"} , 
 	{ "Name" : "vsync", "interface" : "wire", "bitwidth" : 1, "direction" : "READONLY"} , 
 	{ "Name" : "rst_n", "interface" : "wire", "bitwidth" : 1, "direction" : "READONLY"} , 
 	{ "Name" : "R_out", "interface" : "wire", "bitwidth" : 10, "direction" : "WRITEONLY"} , 
 	{ "Name" : "G_out", "interface" : "wire", "bitwidth" : 10, "direction" : "WRITEONLY"} , 
 	{ "Name" : "B_out", "interface" : "wire", "bitwidth" : 10, "direction" : "WRITEONLY"} ]}
# RTL Port declarations: 
set portNum 19
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ hand_x sc_in sc_lv 10 signal 0 } 
	{ hand_y sc_in sc_lv 10 signal 1 } 
	{ detected sc_in sc_lv 1 signal 2 } 
	{ vga_x sc_in sc_lv 10 signal 3 } 
	{ vga_y sc_in sc_lv 10 signal 4 } 
	{ vsync sc_in sc_lv 1 signal 5 } 
	{ rst_n sc_in sc_lv 1 signal 6 } 
	{ R_out sc_out sc_lv 10 signal 7 } 
	{ R_out_ap_vld sc_out sc_logic 1 outvld 7 } 
	{ G_out sc_out sc_lv 10 signal 8 } 
	{ G_out_ap_vld sc_out sc_logic 1 outvld 8 } 
	{ B_out sc_out sc_lv 10 signal 9 } 
	{ B_out_ap_vld sc_out sc_logic 1 outvld 9 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "hand_x", "direction": "in", "datatype": "sc_lv", "bitwidth":10, "type": "signal", "bundle":{"name": "hand_x", "role": "default" }} , 
 	{ "name": "hand_y", "direction": "in", "datatype": "sc_lv", "bitwidth":10, "type": "signal", "bundle":{"name": "hand_y", "role": "default" }} , 
 	{ "name": "detected", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "detected", "role": "default" }} , 
 	{ "name": "vga_x", "direction": "in", "datatype": "sc_lv", "bitwidth":10, "type": "signal", "bundle":{"name": "vga_x", "role": "default" }} , 
 	{ "name": "vga_y", "direction": "in", "datatype": "sc_lv", "bitwidth":10, "type": "signal", "bundle":{"name": "vga_y", "role": "default" }} , 
 	{ "name": "vsync", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "vsync", "role": "default" }} , 
 	{ "name": "rst_n", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "rst_n", "role": "default" }} , 
 	{ "name": "R_out", "direction": "out", "datatype": "sc_lv", "bitwidth":10, "type": "signal", "bundle":{"name": "R_out", "role": "default" }} , 
 	{ "name": "R_out_ap_vld", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "outvld", "bundle":{"name": "R_out", "role": "ap_vld" }} , 
 	{ "name": "G_out", "direction": "out", "datatype": "sc_lv", "bitwidth":10, "type": "signal", "bundle":{"name": "G_out", "role": "default" }} , 
 	{ "name": "G_out_ap_vld", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "outvld", "bundle":{"name": "G_out", "role": "ap_vld" }} , 
 	{ "name": "B_out", "direction": "out", "datatype": "sc_lv", "bitwidth":10, "type": "signal", "bundle":{"name": "B_out", "role": "default" }} , 
 	{ "name": "B_out_ap_vld", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "outvld", "bundle":{"name": "B_out", "role": "ap_vld" }}  ]}

set ArgLastReadFirstWriteLatency {
	snake_top {
		hand_x {Type I LastRead 0 FirstWrite -1}
		hand_y {Type I LastRead 0 FirstWrite -1}
		detected {Type I LastRead 0 FirstWrite -1}
		vga_x {Type I LastRead 0 FirstWrite -1}
		vga_y {Type I LastRead 0 FirstWrite -1}
		vsync {Type I LastRead 0 FirstWrite -1}
		rst_n {Type I LastRead 0 FirstWrite -1}
		R_out {Type O LastRead -1 FirstWrite 8}
		G_out {Type O LastRead -1 FirstWrite 8}
		B_out {Type O LastRead -1 FirstWrite 8}
		st_direction {Type IO LastRead -1 FirstWrite -1}
		st_frame_count {Type IO LastRead -1 FirstWrite -1}
		st_food_col {Type IO LastRead -1 FirstWrite -1}
		st_food_row {Type IO LastRead -1 FirstWrite -1}
		grid {Type IO LastRead -1 FirstWrite -1}
		st_length {Type IO LastRead -1 FirstWrite -1}
		st_game_over {Type IO LastRead -1 FirstWrite -1}
		vsync_prev {Type IO LastRead -1 FirstWrite -1}
		st_body_col {Type IO LastRead -1 FirstWrite -1}
		st_body_row {Type IO LastRead -1 FirstWrite -1}
		lfsr {Type IO LastRead -1 FirstWrite -1}}
	snake_top_Pipeline_VITIS_LOOP_73_1_VITIS_LOOP_74_2 {
		grid {Type O LastRead -1 FirstWrite 0}}
	snake_top_Pipeline_VITIS_LOOP_85_3 {
		st_body_col {Type O LastRead -1 FirstWrite 0}
		st_body_row {Type O LastRead -1 FirstWrite 0}
		grid {Type O LastRead -1 FirstWrite 0}}
	snake_top_Pipeline_VITIS_LOOP_94_4 {
		st_body_col {Type O LastRead -1 FirstWrite 0}
		st_body_row {Type O LastRead -1 FirstWrite 0}}
	snake_top_Pipeline_VITIS_LOOP_27_1 {
		or_ln_out {Type O LastRead -1 FirstWrite 1}
		r_5_out {Type O LastRead -1 FirstWrite 1}
		c_6_out {Type O LastRead -1 FirstWrite 1}
		grid {Type I LastRead 0 FirstWrite -1}}
	snake_top_Pipeline_VITIS_LOOP_207_5 {
		new_len_2 {Type I LastRead 0 FirstWrite -1}
		st_body_col {Type IO LastRead 0 FirstWrite 1}
		st_body_row {Type IO LastRead 0 FirstWrite 1}}
	snake_top_Pipeline_VITIS_LOOP_27_11 {
		lfsr_load {Type I LastRead 0 FirstWrite -1}
		or_ln14_1_out {Type O LastRead -1 FirstWrite 1}
		r_6_out {Type O LastRead -1 FirstWrite 1}
		c_7_out {Type O LastRead -1 FirstWrite 1}
		grid {Type I LastRead 0 FirstWrite -1}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "2", "Max" : "613"}
	, {"Name" : "Interval", "Min" : "3", "Max" : "614"}
]}

set PipelineEnableSignalInfo {[
]}

set Spec2ImplPortList { 
	hand_x { ap_none {  { hand_x in_data 0 10 } } }
	hand_y { ap_none {  { hand_y in_data 0 10 } } }
	detected { ap_none {  { detected in_data 0 1 } } }
	vga_x { ap_none {  { vga_x in_data 0 10 } } }
	vga_y { ap_none {  { vga_y in_data 0 10 } } }
	vsync { ap_none {  { vsync in_data 0 1 } } }
	rst_n { ap_none {  { rst_n in_data 0 1 } } }
	R_out { ap_vld {  { R_out out_data 1 10 }  { R_out_ap_vld out_vld 1 1 } } }
	G_out { ap_vld {  { G_out out_data 1 10 }  { G_out_ap_vld out_vld 1 1 } } }
	B_out { ap_vld {  { B_out out_data 1 10 }  { B_out_ap_vld out_vld 1 1 } } }
}

set maxi_interface_dict [dict create]

# RTL port scheduling information:
set fifoSchedulingInfoList { 
}

# RTL bus port read request latency information:
set busReadReqLatencyList { 
}

# RTL bus port write response latency information:
set busWriteResLatencyList { 
}

# RTL array port load latency information:
set memoryLoadLatencyList { 
}
