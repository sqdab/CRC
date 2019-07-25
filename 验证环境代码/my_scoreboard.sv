`ifndef MY_SCOREBOARD__SV
`define MY_SCOREBOARD__SV
class my_scoreboard extends uvm_scoreboard;
	my_transaction expect_queue[$];
	int s=0;
	int f=0;
	uvm_blocking_get_port #(my_transaction) exp_port;
	uvm_blocking_get_port #(my_transaction) act_port;
	`uvm_component_utils(my_scoreboard)
	extern function new(string name, uvm_component parent = null);
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual task main_phase(uvm_phase phase);
endclass 

function my_scoreboard::new(string name, uvm_component parent = null);
	super.new(name, parent);
endfunction 

function void my_scoreboard::build_phase(uvm_phase phase);
	super.build_phase(phase);
	exp_port = new("exp_port", this);
	act_port = new("act_port", this);
endfunction 

task my_scoreboard::main_phase(uvm_phase phase);
	my_transaction get_expect,get_actual,tmp_tran;
	bit result;
	super.main_phase(phase);
	fork 
		while (1)
			begin
				exp_port.get(get_expect);
				expect_queue.push_back(get_expect);
			end
		while (1)
			begin
				act_port.get(get_actual);
				if(expect_queue.size() > 0)
					begin
						tmp_tran = expect_queue.pop_front();
						result = get_actual.dr ==tmp_tran.dr;
						if(result)
							begin 
								this.s = this.s+1;
								`uvm_info("my_scoreboard", $sformatf("[%4d,%4d]PASS",this.s,this.s+this.f), UVM_LOW);
							end
						else
							begin
								this.f = this.f+1;
								`uvm_error("my_scoreboard", $sformatf("[%4d,%4d]FAIL",this.f,this.s+this.f));
								$display("the expect pkt is");
								tmp_tran.print();
								$display("the actual pkt is");
								get_actual.print();
							end
					end
				else
					begin
						`uvm_error("my_scoreboard", "Received from DUT, while Expect Queue is empty");
						this.s = this.s+1;
					end 
			end
	join
endtask
`endif