set moduleName snake_top_Pipeline_VITIS_LOOP_85_3
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
set C_modelName {snake_top_Pipeline_VITIS_LOOP_85_3}
set C_modelType { void 0 }
set ap_memory_interface_dict [dict create]
dict set ap_memory_interface_dict st_body_col { MEM_WIDTH 5 MEM_SIZE 300 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 0 }
dict set ap_memory_interface_dict st_body_row { MEM_WIDTH 4 MEM_SIZE 300 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 0 }
dict set ap_memory_interface_dict grid { MEM_WIDTH 1 MEM_SIZE 300 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 0 }
set C_modelArgList {
	{ st_body_col int 5 regular {array 300 { 0 3 } 0 1 } {global 1}  }
	{ st_body_row int 4 regular {array 300 { 0 3 } 0 1 } {global 1}  }
	{ grid int 1 regular {array 300 { 0 3 } 0 1 } {global 1}  }
}
set hasAXIMCache 0
set l_AXIML2Cache [list]
set AXIMCacheInstDict [dict create]
set C_modelArgMapList {[ 
	{ "Name" : "st_body_col", "interface" : "memory", "bitwidth" : 5, "direction" : "WRITEONLY", "extern" : 0} , 
 	{ "Name" : "st_body_row", "interface" : "memory", "bitwidth" : 4, "direction" : "WRITEONLY", "extern" : 0} , 
 	{ "Name" : "grid", "interface" : "memory", "bitwidth" : 1, "direction" : "WRITEONLY", "extern" : 0} ]}
# RTL Port declarations: 
set portNum 18
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ st_body_col_address0 sc_out sc_lv 9 signal 0 } 
	{ st_body_col_ce0 sc_out sc_logic 1 signal 0 } 
	{ st_body_col_we0 sc_out sc_logic 1 signal 0 } 
	{ st_body_col_d0 sc_out sc_lv 5 signal 0 } 
	{ st_body_row_address0 sc_out sc_lv 9 signal 1 } 
	{ st_body_row_ce0 sc_out sc_logic 1 signal 1 } 
	{ st_body_row_we0 sc_out sc_logic 1 signal 1 } 
	{ st_body_row_d0 sc_out sc_lv 4 signal 1 } 
	{ grid_address0 sc_out sc_lv 9 signal 2 } 
	{ grid_ce0 sc_out sc_logic 1 signal 2 } 
	{ grid_we0 sc_out sc_logic 1 signal 2 } 
	{ grid_d0 sc_out sc_lv 1 signal 2 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "st_body_col_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "st_body_col", "role": "address0" }} , 
 	{ "name": "st_body_col_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "st_body_col", "role": "ce0" }} , 
 	{ "name": "st_body_col_we0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "st_body_col", "role": "we0" }} , 
 	{ "name": "st_body_col_d0", "direction": "out", "datatype": "sc_lv", "bitwidth":5, "type": "signal", "bundle":{"name": "st_body_col", "role": "d0" }} , 
 	{ "name": "st_body_row_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "st_body_row", "role": "address0" }} , 
 	{ "name": "st_body_row_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "st_body_row", "role": "ce0" }} , 
 	{ "name": "st_body_row_we0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "st_body_row", "role": "we0" }} , 
 	{ "name": "st_body_row_d0", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "st_body_row", "role": "d0" }} , 
 	{ "name": "grid_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":9, "type": "signal", "bundle":{"name": "grid", "role": "address0" }} , 
 	{ "name": "grid_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "grid", "role": "ce0" }} , 
 	{ "name": "grid_we0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "grid", "role": "we0" }} , 
 	{ "name": "grid_d0", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "grid", "role": "d0" }}  ]}

set ArgLastReadFirstWriteLatency {
	snake_top_Pipeline_VITIS_LOOP_85_3 {
		st_body_col {Type O LastRead -1 FirstWrite 0}
		st_body_row {Type O LastRead -1 FirstWrite 0}
		grid {Type O LastRead -1 FirstWrite 0}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "5", "Max" : "5"}
	, {"Name" : "Interval", "Min" : "4", "Max" : "4"}
]}

set PipelineEnableSignalInfo {[
]}

set Spec2ImplPortList { 
	st_body_col { ap_memory {  { st_body_col_address0 mem_address 1 9 }  { st_body_col_ce0 mem_ce 1 1 }  { st_body_col_we0 mem_we 1 1 }  { st_body_col_d0 mem_din 1 5 } } }
	st_body_row { ap_memory {  { st_body_row_address0 mem_address 1 9 }  { st_body_row_ce0 mem_ce 1 1 }  { st_body_row_we0 mem_we 1 1 }  { st_body_row_d0 mem_din 1 4 } } }
	grid { ap_memory {  { grid_address0 mem_address 1 9 }  { grid_ce0 mem_ce 1 1 }  { grid_we0 mem_we 1 1 }  { grid_d0 mem_din 1 1 } } }
}
