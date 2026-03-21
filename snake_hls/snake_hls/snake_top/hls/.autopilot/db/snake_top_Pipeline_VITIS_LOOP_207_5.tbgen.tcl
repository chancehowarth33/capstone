set moduleName snake_top_Pipeline_VITIS_LOOP_207_5
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
set C_modelName {snake_top_Pipeline_VITIS_LOOP_207_5}
set C_modelType { void 0 }
set ap_memory_interface_dict [dict create]
dict set ap_memory_interface_dict st_body_col { MEM_WIDTH 5 MEM_SIZE 300 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 0 }
dict set ap_memory_interface_dict st_body_row { MEM_WIDTH 4 MEM_SIZE 300 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 0 }
set C_modelArgList {
	{ new_len_2 int 9 regular  }
	{ st_body_col int 5 regular {array 300 { 0 1 } 1 1 } {global 2}  }
	{ st_body_row int 4 regular {array 300 { 0 1 } 1 1 } {global 2}  }
}
set hasAXIMCache 0
set l_AXIML2Cache [list]
set AXIMCacheInstDict [dict create]
set C_modelArgMapList {[ 
	{ "Name" : "new_len_2", "interface" : "wire", "bitwidth" : 9, "direction" : "READONLY"} , 
 	{ "Name" : "st_body_col", "interface" : "memory", "bitwidth" : 5, "direction" : "READWRITE", "extern" : 0} , 
 	{ "Name" : "st_body_row", "interface" : "memory", "bitwidth" : 4, "direction" : "READWRITE", "extern" : 0} ]}
# RTL Port declarations: 
set portNum 21
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ new_len_2 sc_in sc_lv 9 signal 0 } 
	{ st_body_col_address0 sc_out sc_lv 9 signal 1 } 
	{ st_body_col_ce0 sc_out sc_logic 1 signal 1 } 
	{ st_body_col_we0 sc_out sc_logic 1 signal 1 } 
	{ st_body_col_d0 sc_out sc_lv 5 signal 1 } 
	{ st_body_col_address1 sc_out sc_lv 9 signal 1 } 
	{ st_body_col_ce1 sc_out sc_logic 1 signal 1 } 
	{ st_body_col_q1 sc_in sc_lv 5 signal 1 } 
	{ st_body_row_address0 sc_out sc_lv 9 signal 2 } 
	{ st_body_row_ce0 sc_out sc_logic 1 signal 2 } 
	{ st_body_row_we0 sc_out sc_logic 1 signal 2 } 
	{ st_body_row_d0 sc_out sc_lv 4 signal 2 } 
	{ st_body_row_address1 sc_out sc_lv 9 signal 2 } 
	{ st_body_row_ce1 sc_out sc_logic 1 signal 2 } 
	{ st_body_row_q1 sc_in sc_lv 4 signal 2 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "new_len_2", "direction": "in", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "new_len_2", "role": "default" }} , 
 	{ "name": "st_body_col_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "st_body_col", "role": "address0" }} , 
 	{ "name": "st_body_col_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "st_body_col", "role": "ce0" }} , 
 	{ "name": "st_body_col_we0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "st_body_col", "role": "we0" }} , 
 	{ "name": "st_body_col_d0", "direction": "out", "datatype": "sc_lv", "bitwidth":5, "type": "signal", "bundle":{"name": "st_body_col", "role": "d0" }} , 
 	{ "name": "st_body_col_address1", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "st_body_col", "role": "address1" }} , 
 	{ "name": "st_body_col_ce1", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "st_body_col", "role": "ce1" }} , 
 	{ "name": "st_body_col_q1", "direction": "in", "datatype": "sc_lv", "bitwidth":5, "type": "signal", "bundle":{"name": "st_body_col", "role": "q1" }} , 
 	{ "name": "st_body_row_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "st_body_row", "role": "address0" }} , 
 	{ "name": "st_body_row_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "st_body_row", "role": "ce0" }} , 
 	{ "name": "st_body_row_we0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "st_body_row", "role": "we0" }} , 
 	{ "name": "st_body_row_d0", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "st_body_row", "role": "d0" }} , 
 	{ "name": "st_body_row_address1", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "st_body_row", "role": "address1" }} , 
 	{ "name": "st_body_row_ce1", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "st_body_row", "role": "ce1" }} , 
 	{ "name": "st_body_row_q1", "direction": "in", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "st_body_row", "role": "q1" }}  ]}

set ArgLastReadFirstWriteLatency {
	snake_top_Pipeline_VITIS_LOOP_207_5 {
		new_len_2 {Type I LastRead 0 FirstWrite -1}
		st_body_col {Type IO LastRead 0 FirstWrite 1}
		st_body_row {Type IO LastRead 0 FirstWrite 1}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "301", "Max" : "301"}
	, {"Name" : "Interval", "Min" : "300", "Max" : "300"}
]}

set PipelineEnableSignalInfo {[
	{"Pipeline" : "0", "EnableSignal" : "ap_enable_pp0"}
]}

set Spec2ImplPortList { 
	new_len_2 { ap_none {  { new_len_2 in_data 0 9 } } }
	st_body_col { ap_memory {  { st_body_col_address0 mem_address 1 9 }  { st_body_col_ce0 mem_ce 1 1 }  { st_body_col_we0 mem_we 1 1 }  { st_body_col_d0 mem_din 1 5 }  { st_body_col_address1 MemPortADDR2 1 9 }  { st_body_col_ce1 MemPortCE2 1 1 }  { st_body_col_q1 MemPortDOUT2 0 5 } } }
	st_body_row { ap_memory {  { st_body_row_address0 mem_address 1 9 }  { st_body_row_ce0 mem_ce 1 1 }  { st_body_row_we0 mem_we 1 1 }  { st_body_row_d0 mem_din 1 4 }  { st_body_row_address1 MemPortADDR2 1 9 }  { st_body_row_ce1 MemPortCE2 1 1 }  { st_body_row_q1 MemPortDOUT2 0 4 } } }
}
