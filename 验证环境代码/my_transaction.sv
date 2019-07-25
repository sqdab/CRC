`ifndef MY_TRANSACTION__SV
`define MY_TRANSACTION__SV

class my_transaction extends uvm_sequence_item;
	rand bit[31:0] dmac;
	rand bit[15:0] dr;
	`uvm_object_utils_begin(my_transaction)
	`uvm_field_int(dmac, UVM_ALL_ON)
	`uvm_field_int(dr, UVM_ALL_ON)
	`uvm_object_utils_end

	function new(string name = "my_transaction");
		super.new();
	endfunction

endclass
`endif
