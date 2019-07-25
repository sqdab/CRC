`ifndef MY_IF__SV
`define MY_IF__SV

interface my_if(input clk_in, input rstn,input [19:0] data_length,input [3:0] crc_mode,input work_mode,input data_in_valid);
	logic [31:0] dmac;
	logic [15:0] dr;
endinterface

`endif
