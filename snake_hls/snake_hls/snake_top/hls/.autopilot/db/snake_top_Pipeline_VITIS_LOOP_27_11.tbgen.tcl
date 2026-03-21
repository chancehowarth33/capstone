set moduleName snake_top_Pipeline_VITIS_LOOP_27_11
set isTopModule 0
set isCombinational 0
set isDatapathOnly 0
set isPipelined 1
set isPipelined_legacy 1
set pipeline_type loop_auto_rewind
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
set C_modelName {snake_top_Pipeline_VITIS_LOOP_27_11}
set C_modelType { void 0 }
set ap_memory_interface_dict [dict create]
dict set ap_memory_interface_dict grid { MEM_WIDTH 1 MEM_SIZE 300 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 1 }
set C_modelArgList {
	{ lfsr_load int 16 regular  }
	{ or_ln14_1_out int 16 regular {pointer 1}  }
	{ r_6_out int 4 regular {pointer 1}  }
	{ c_7_out int 5 regular {pointer 1}  }
	{ grid int 1 regular {array 300 { 1 3 } 1 1 } {global 0}  }
}
set hasAXIMCache 0
set l_AXIML2Cache [list]
set AXIMCacheInstDict [dict create]
set C_modelArgMapList {[ 
	{ "Name" : "lfsr_load", "interface" : "wire", "bitwidth" : 16, "direction" : "READONLY"} , 
 	{ "Name" : "or_ln14_1_out", "interface" : "wire", "bitwidth" : 16, "direction" : "WRITEONLY"} , 
 	{ "Name" : "r_6_out", "interface" : "wire", "bitwidth" : 4, "direction" : "WRITEONLY"} , 
 	{ "Name" : "c_7_out", "interface" : "wire", "bitwidth" : 5, "direction" : "WRITEONLY"} , 
 	{ "Name" : "grid", "interface" : "memory", "bitwidth" : 1, "direction" : "READONLY", "extern" : 0} ]}
# RTL Port declarations: 
set portNum 16
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ lfsr_load sc_in sc_lv 16 signal 0 } 
	{ or_ln14_1_out sc_out sc_lv 16 signal 1 } 
	{ or_ln14_1_out_ap_vld sc_out sc_logic 1 outvld 1 } 
	{ r_6_out sc_out sc_lv 4 signal 2 } 
	{ r_6_out_ap_vld sc_out sc_logic 1 outvld 2 } 
	{ c_7_out sc_out sc_lv 5 signal 3 } 
	{ c_7_out_ap_vld sc_out sc_logic 1 outvld 3 } 
	{ grid_address0 sc_out sc_lv 9 signal 4 } 
	{ grid_ce0 sc_out sc_logic 1 signal 4 } 
	{ grid_q0 sc_in sc_lv 1 signal 4 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "lfsr_load", "direction": "in", "datatype": "sc_lv", "bitwidth":16, "type": "signal", "bundle":{"name": "lfsr_load", "role": "default" }} , 
 	{ "name": "or_ln14_1_out", "direction": "out", "datatype": "sc_lv", "bitwidth":16, "type": "signal", "bundle":{"name": "or_ln14_1_out", "role": "default" }} , 
 	{ "name": "or_ln14_1_out_ap_vld", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "outvld", "bundle":{"name": "or_ln14_1_out", "role": "ap_vld" }} , 
 	{ "name": "r_6_out", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "r_6_out", "role": "default" }} , 
 	{ "name": "r_6_out_ap_vld", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "outvld", "bundle":{"name": "r_6_out", "role": "ap_vld" }} , 
 	{ "name": "c_7_out", "direction": "out", "datatype": "sc_lv", "bitwidth":5, "type": "signal", "bundle":{"name": "c_7_out", "role": "default" }} , 
 	{ "name": "c_7_out_ap_vld", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "outvld", "bundle":{"name": "c_7_out", "role": "ap_vld" }} , 
 	{ "name": "grid_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "grid", "role": "address0" }} , 
 	{ "name": "grid_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "grid", "role": "ce0" }} , 
 	{ "name": "grid_q0", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "grid", "role": "q0" }}  ]}

set ArgLastReadFirstWriteLatency {
	snake_top_Pipeline_VITIS_LOOP_27_11 {
		lfsr_load {Type I LastRead 0 FirstWrite -1}
		or_ln14_1_out {Type O LastRead -1 FirstWrite 1}
		r_6_out {Type O LastRead -1 FirstWrite 1}
		c_7_out {Type O LastRead -1 FirstWrite 1}
		grid {Type I LastRead 0 FirstWrite -1}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "3", "Max" : "34"}
	, {"Name" : "Interval", "Min" : "1", "Max" : "32"}
]}

set PipelineEnableSignalInfo {[
	{"Pipeline" : "0", "EnableSignal" : "ap_enable_pp0"}
]}

set Spec2ImplPortList { 
	lfsr_load { ap_none {  { lfsr_load in_data 0 16 } } }
	or_ln14_1_out { ap_vld {  { or_ln14_1_out out_data 1 16 }  { or_ln14_1_out_ap_vld out_vld 1 1 } } }
	r_6_out { ap_vld {  { r_6_out out_data 1 4 }  { r_6_out_ap_vld out_vld 1 1 } } }
	c_7_out { ap_vld {  { c_7_out out_data 1 5 }  { c_7_out_ap_vld out_vld 1 1 } } }
	grid { ap_memory {  { grid_address0 mem_address 1 9 }  { grid_ce0 mem_ce 1 1 }  { grid_q0 mem_dout 0 1 } } }
}
