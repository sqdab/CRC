/***********************************************
#
#      Filename: tb_AXI3_mst_read.v
#
#        Author: lixiaofei
#   Description: Testbench for AXI master to read
#        Create: 2019-06-11 10:21:54
#     Copyright: 302-2 Studio
***********************************************/
`timescale 1ns/100ps
module tb_AXI3_mst_read();

reg clk,rst_n;

reg [31:0]addr_src;
reg [15:0]data_len;
reg mst_begin;

reg fifo_full;
wire [31:0]read_data;

wire en_write;
wire error;

reg arready;

wire [3:0]arid;
wire [31:0]araddr;
wire [3:0]arlen;
wire [2:0]arsize;
wire [1:0]arburst;
wire [1:0]arlock;
wire [3:0]arcache;
wire [2:0]arprot;
wire arvalid;

reg [3:0]rid;
reg [31:0]rdata;
reg [1:0]rresp;
reg rlast;
reg rvalid;

wire rready;

AXI3_mst_read U1_AXI3_mst_read(
clk,rst_n,

addr_src,
data_len,
mst_begin,

fifo_full,
read_data,

en_write,
error,

arready,

arid,
araddr,
arlen,
arsize,
arburst,
arlock,
arcache,
arprot,
arvalid,

rid,
rdata,
rresp,
rlast,
rvalid,
rready
);

initial begin #800 $stop; end

initial begin 
  clk=0;
  rst_n=0;

  addr_src=0;
  data_len=0;
  mst_begin=0;

  fifo_full=0;
  arready=1;

  rid=0;
  rdata=0;
  rresp=0;
  rlast=0;
  rvalid=0;
end

always #2.5 clk=~clk;

initial begin
  #10 rst_n=1;
end

initial begin
  #10 data_len=333;
end

initial begin 
  #30 mst_begin=1;
  #5  mst_begin=0;
end

initial begin
  #102.5 fifo_full=1;
  #10  fifo_full=0;
end

always@(posedge clk) rdata=rdata+1;

initial begin
  #40 rvalid=1;
  #15 rvalid=0;
  #10 rvalid=1;
end

initial begin 
  #130 rlast=1;
  #5   rlast=0;
  #75  rlast=1;
  #5   rlast=0;
  #75  rlast=1;
  #5   rlast=0;
  #75  rlast=1;
  #5   rlast=0;
  #75  rlast=1;
  #25  rlast=0;
end

endmodule

