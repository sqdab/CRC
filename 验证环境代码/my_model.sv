`ifndef MY_MODEL__SV
`define MY_MODEL__SV
`include "configv.sv"
class my_model extends uvm_component;
	uvm_blocking_get_port #(my_transaction)  port;
	uvm_analysis_port #(my_transaction)  ap;
	bit [15:0] crc0;
	bit pp;
	int p;
	bit [47:0] pfifo;
	extern function new(string name, uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern function bit[15:0] f1(int x,int r,int mode);
	extern virtual task main_phase(uvm_phase phase);
	`uvm_component_utils(my_model)
endclass 

function my_model::new(string name, uvm_component parent);
	super.new(name, parent);
	p=0;
	crc0 = 0;
	pp = 0;
	pfifo = 0;
endfunction 

function void my_model::build_phase(uvm_phase phase);
	super.build_phase(phase);
	port = new("port", this);
	ap = new("ap", this);
endfunction

function bit[15:0] my_model::f1(int x,int r,int mode);  
	bit[15:0] g,q;
	case(mode)
		1:begin
			g = 'h131;
			q = (r<<1)^(x<<8);
			if(q>>8==1)
				return q^g;
			else
				return q;
		end
		2:begin
			g = 'h180f;
			q = (r<<1)^(x<<12);
			if(q>>12==1)
				return q^g;
			else
				return q;
		end
		4:begin
			g = 'h18005;
			q = (r<<1)^(x<<16);
			if(q>>12==1)
				return q^g;
			else
				return q;
		end
		8:begin
			g = 'h11021;
			q = (r<<1)^(x<<16);
			if(q>>12==1)
				return q^g;
			else
				return q;
		end
	endcase
endfunction


task my_model::main_phase(uvm_phase phase);
	my_transaction tr,out_tr;
	bit[15:0] temp;
	bit [3:0] test;
	super.main_phase(phase);
	while(1)
		begin
			port.get(tr);
			out_tr = new("out_tr");
			out_tr.copy(tr);
			this.p++;
			if(this.pp==0)
				temp = out_tr.dmac[31:16];
			else
				temp = out_tr.dmac[15:0];
			for(int i=15;i>=0;i--)
				this.crc0 = f1(temp[i],this.crc0,`MODE);
			this.pfifo = {this.pfifo[31:0],this.crc0};
			out_tr.dr = this.pfifo[47:32];
			ap.write(out_tr);
			this.pp=~this.pp;
		end
endtask

`endif
