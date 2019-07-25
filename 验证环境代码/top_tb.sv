`timescale 1ns/1ps
`include "uvm_macros.svh"

import uvm_pkg::*;
`include "my_if.sv"
`include "my_transaction.sv"
`include "my_sequencer.sv"
`include "my_driver.sv"
`include "my_monitor.sv"
`include "my_agent.sv"
`include "my_model.sv"
`include "my_scoreboard.sv"
`include "my_env.sv"
`include "base_test.sv"
`include "my_case0.sv"
`include "configv.sv"
module top_tb;
	reg clk_in;
	reg rstn;
	reg [31:0] data_in;
	reg [19:0] data_length;
	reg [3:0] crc_mode;
	reg work_mode;
	reg data_in_valid;
	wire data_out;
	wire [1:0] chk_result;
	wire [15:0] crc_result;
	my_if input_if(clk_in,rstn,data_length,crc_mode,work_mode,data_in_valid);
	my_if output_if(clk_in,rstn,data_length,crc_mode,work_mode,data_in_valid);
	crc_cal my_dut(.clk_in(clk_in),
		.rstn(rstn),
		.data_in(input_if.dmac),
		.data_length(data_length),
		.crc_mode(crc_mode),
		.work_mode(work_mode),
		.data_in_valid(data_in_valid),
		.data_out(data_out),
		.chk_result(chk_result),
		.crc_result(output_if.dr)
	);

	initial
		begin
			clk_in = 0;
			forever
				begin
					#100 clk_in = ~clk_in;
				end
		end
	
	initial
		begin
			rstn = 1'b0;
			data_length = `COUNT;
			crc_mode = `MODE;
			work_mode = 0;
			data_in_valid = 1;
			#20;
			rstn = 1'b1;
			#5000;
		end
	
	initial
		begin
			run_test("my_case0");
		end
	
	initial
		begin
			uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.i_agt.drv", "vif", input_if);
			uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.i_agt.mon", "vif", input_if);
			uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.o_agt.mon", "vif", output_if);
		end

endmodule
