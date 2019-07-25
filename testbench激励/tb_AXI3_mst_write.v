/***********************************************
#
#      Filename: tb_AXI3_mst_write.v
#
#        Author: lixiaofei
#   Description: Testbench for AXI master to write
#        Create: 2019-06-12 11:29:57
#     Copyright: 302-2 Studio
***********************************************/
`timescale 1ns/100ps
module tb_AXI3_mst_write();

reg clk;
reg rst_n;
reg [31:0]addr_dst;
reg [15:0]data_len;
reg [2:0]crc_mode;
reg mst_begin;
reg en_data_crc;
reg fifo_empty;
reg [31:0]fifo_in;
reg [15:0]crc_data;

wire en_read;
wire error;

wire data_written;

reg awready;

wire [3:0]awid;
wire [31:0]awaddr;
wire [3:0]awlen;
wire [2:0]awsize;
wire [1:0]awburst;
wire [1:0]awlock;
wire [3:0]awcache;
wire [2:0]awprot; 
wire awvalid;

reg  wready;
wire [3:0]wid;
wire [31:0]wdata;
wire [3:0]wstrb;
wire wlast;
wire wvalid;

reg  [3:0]bid;
reg  [1:0]bresp;
reg  bvalid;

wire bready;

AXI3_mst_write U1_AXI3_mst_write(
clk,rst_n,addr_dst,data_len,crc_mode,mst_begin,en_data_crc,fifo_empty,fifo_in,crc_data,en_read,
error,data_written,awready,awid,awaddr,awlen,awsize,awburst,awlock,awcache,awprot, awvalid,wready,
wid,wdata,wstrb,wlast,wvalid,bid,bresp,bvalid,bready
);

initial #1000 $stop;

initial begin
  clk=0;
  rst_n=0;
  addr_dst=0;
  data_len=0;
  crc_mode=0;
  mst_begin=0;

  en_data_crc=0;
  fifo_empty=0;
  fifo_in=0;
  crc_data=0;

  awready=1;
  wready=1;

  bid=0;
  bresp=0;
  bvalid=0;
end

always #2.5 clk=~clk;

initial begin
  #10 rst_n=1;
end

initial begin
  #30
  data_len=333;
  crc_mode=3'b010;
  mst_begin=1;
  #5 
  mst_begin=0;
end

initial begin
  #600
  en_data_crc=1;
  crc_data=16'hA5A5;
  #5
  en_data_crc=0;
end

initial begin
  #100
  fifo_empty=1;
  #5
  fifo_empty=0;
end

always @(posedge clk) fifo_in=fifo_in+1;

initial begin
  #180
  bvalid=1;
  bresp=2'b11;
  #5
  bvalid=0;
end

endmodule



