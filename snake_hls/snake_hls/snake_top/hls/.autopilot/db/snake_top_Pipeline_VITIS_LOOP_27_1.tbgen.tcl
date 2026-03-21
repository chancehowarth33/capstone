set moduleName snake_top_Pipeline_VITIS_LOOP_27_1
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
set C_modelName {snake_top_Pipeline_VITIS_LOOP_27_1}
set C_modelType { void 0 }
set ap_memory_interface_dict [dict create]
dict set ap_memory_interface_dict grid { MEM_WIDTH 1 MEM_SIZE 300 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 1 }
set C_modelArgList {
	{ or_ln_out int 16 regular {pointer 1}  }
	{ r_5_out int 4 regular {pointer 1}  }
	{ c_6_out int 5 regular {pointer 1}  }
	{ grid int 1 regular {array 300 { 1 3 } 1 1 } {global 0}  }
}
set hasAXIMCache 0
set l_AXIML2Cache [list]
set AXIMCacheInstDict [dict create]
set C_modelArgMapList {[ 
	{ "Name" : "or_ln_out", "interface" : "wire", "bitwidth" : 16, "direction" : "WRITEONLY"} , 
 	{ "Name" : "r_5_out", "interface" : "wire", "bitwidth" : 4, "direction" : "WRITEONLY"} , 
 	{ "Name" : "c_6_out", "interface" : "wire", "bitwidth" : 5, "direction" : "WRITEONLY"} , 
 	{ "Name" : "grid", "interface" : "memory", "bitwidth" : 1, "direction" : "READONLY", "extern" : 0} ]}
# RTL Port declarations: 
set portNum 15
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ or_ln_out sc_out sc_lv 16 signal 0 } 
	{ or_ln_out_ap_vld sc_out sc_logic 1 outvld 0 } 
	{ r_5_out sc_out sc_lv 4 signal 1 } 
	{ r_5_out_ap_vld sc_out sc_logic 1 outvld 1 } 
	{ c_6_out sc_out sc_lv 5 signal 2 } 
	{ c_6_out_ap_vld sc_out sc_logic 1 outvld 2 } 
	{ grid_address0 sc_out sc_lv 9 signal 3 } 
	{ grid_ce0 sc_out sc_logic 1 signal 3 } 
	{ grid_q0 sc_in sc_lv 1 signal 3 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "or_ln_out", "direction": "out", "datatype": "sc_lv", "bitwidth":16, "type": "signal", "bundle":{"name": "or_ln_out", "role": "default" }} , 
 	{ "name": "or_ln_out_ap_vld", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "outvld", "bundle":{"name": "or_ln_out", "role": "ap_vld" }} , 
 	{ "name": "r_5_out", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "r_5_out", "role": "default" }} , 
 	{ "name": "r_5_out_ap_vld", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "outvld", "bundle":{"name": "r_5_out", "role": "ap_vld" }} , 
 	{ "name": "c_6_out", "direction": "out", "datatype": "sc_lv", "bitwidth":5, "type": "signal", "bundle":{"name": "c_6_out", "role": "default" }} , 
 	{ "name": "c_6_out_ap_vld", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "outvld", "bundle":{"name": "c_6_out", "role": "ap_vld" }} , 
 	{ "name": "grid_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "grid", "role": "address0" }} , 
 	{ "name": "grid_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "grid", "role": "ce0" }} , 
 	{ "name": "grid_q0", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "grid", "role": "q0" }}  ]}

set ArgLastReadFirstWriteLatency {
	snake_top_Pipeline_VITIS_LOOP_27_1 {
		or_ln_out {Type O LastRead -1 FirstWrite 1}
		r_5_out {Type O LastRead -1 FirstWrite 1}
		c_6_out {Type O LastRead -1 FirstWrite 1}
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
	or_ln_out { ap_vld {  { or_ln_out out_data 1 16 }  { or_ln_out_ap_vld out_vld 1 1 } } }
	r_5_out { ap_vld {  { r_5_out out_data 1 4 }  { r_5_out_ap_vld out_vld 1 1 } } }
	c_6_out { ap_vld {  { c_6_out out_data 1 5 }  { c_6_out_ap_vld out_vld 1 1 } } }
	grid { ap_memory {  { grid_address0 mem_address 1 9 }  { grid_ce0 mem_ce 1 1 }  { grid_q0 mem_dout 0 1 } } }
}
