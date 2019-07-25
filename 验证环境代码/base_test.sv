`ifndef BASE_TEST__SV
`define BASE_TEST__SV

class base_test extends uvm_test;

	my_env env;
	
	function new(string name = "base_test", uvm_component parent = null);
		super.new(name,parent);
	endfunction
	
	extern virtual function void build_phase(uvm_phase phase);
	`uvm_component_utils(base_test)
endclass


function void base_test::build_phase(uvm_phase phase);
	super.build_phase(phase);
	env  =  my_env::type_id::create("env", this); 
endfunction

`endif
