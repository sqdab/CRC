`ifndef MY_DRIVER__SV
`define MY_DRIVER__SV
class my_driver extends uvm_driver#(my_transaction);

	virtual my_if vif;
	`uvm_component_utils(my_driver)
	function new(string name = "my_driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
			`uvm_fatal("my_driver", "virtual interface must be set for vif!!!")
	endfunction
	
	extern task main_phase(uvm_phase phase);
	extern task drive_one_pkt(my_transaction tr);
endclass

task my_driver::main_phase(uvm_phase phase);
	vif.dmac <= 0;
	while(!vif.rstn)
		@(posedge vif.clk_in);
	while(1)
		begin
			seq_item_port.get_next_item(req);
			drive_one_pkt(req);
			seq_item_port.item_done();
		end
endtask

task my_driver::drive_one_pkt(my_transaction tr);  
	vif.dmac <= tr.dmac; 
	repeat(2)
		@(posedge vif.clk_in);
endtask
`endif
