`ifndef MY_MONITOR__SV
`define MY_MONITOR__SV
class my_monitor extends uvm_monitor;

	virtual my_if vif;
	uvm_analysis_port #(my_transaction)  ap;
	`uvm_component_utils(my_monitor)
	function new(string name = "my_monitor", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
	super.build_phase(phase);
	if(!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
		`uvm_fatal("my_monitor", "virtual interface must be set for vif!!!")
		ap = new("ap", this);
	endfunction
	
	extern task main_phase(uvm_phase phase);
	extern task collect_one_pkt(my_transaction tr);
endclass

task my_monitor::main_phase(uvm_phase phase);
	my_transaction tr;
	while(1)
		begin
			tr = new("tr");
			collect_one_pkt(tr);
			ap.write(tr);
		end
endtask

task my_monitor::collect_one_pkt(my_transaction tr);
	while(!vif.rstn)
		begin
			@(posedge vif.clk_in);
		end
	@(posedge vif.clk_in);
	tr.dr = vif.dr;
	tr.dmac = vif.dmac;
endtask


`endif