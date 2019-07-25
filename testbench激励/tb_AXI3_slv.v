/***********************************************
#
#      Filename: tb_AXI3_slv.v
#
#        Author: lixiaofei
#   Description: Testbench for AXI slave
#        Create: 2019-06-10 18:06:32
#     Copyright: 302-2 Studio
***********************************************/
`timescale 1ns/100ps
module tb_AXI3_slv();

reg clk,rst_n;

wire data_received;
wire intr_checked;
wire [31:0]addr_src;
wire [31:0]addr_dst;
wire [15:0]data_len;
wire [2:0]crc_mode;

reg  [1:0]veri_result;
reg  [5:0]intr;

wire error_read;
wire error_write;

wire awready;

reg [3:0]awid;
reg [31:0]awaddr;
reg [3:0]awlen;
reg [2:0]awsize;
reg [1:0]awburst;
reg [1:0]awlock;
reg awvalid;

wire wready;

reg [3:0]wid;
reg [31:0]wdata;
reg [3:0]wstrb;
reg wlast;
reg wvalid;

wire [3:0]bid;
wire [1:0]bresp;
wire bvalid;
reg bready;

wire arready;

reg [3:0]arid;
reg [31:0]araddr;
reg [3:0]arlen;
reg [2:0]arsize;
reg [1:0]arburst;
reg [1:0]arlock;
reg arvalid;

wire [3:0]rid;
wire [31:0]rdata;
wire [1:0]rresp;
wire rlast;
wire rvalid;

reg rready;

AXI3_slv U1_AXI3_slv(

clk,
rst_n,

data_received,
intr_checked,
addr_src,
addr_dst,
data_len,
crc_mode,

veri_result,
intr,

error_read,
error_write,

awready,

awid,
awaddr,
awlen,
awsize,
awburst,
awlock,
awvalid,

wready,

wid,
wdata,
wstrb,
wlast,
wvalid,

bid,
bresp,
bvalid,
bready,

arready,

arid,
araddr,
arlen,
arsize,
arburst,
arlock,
arvalid,

rid,
rdata,
rresp,
rlast,
rvalid,
rready
);

initial begin #200 $stop; end

initial begin
  clk=0;
  rst_n=0;
  awid=0;
  awaddr=0;
  awlen=0;
  awsize=0;
  awburst=0;
  awlock=0;
  awvalid=0;

  wid=0;
  wdata=0;
  wstrb=0;
  wlast=0;
  wvalid=0;

  bready=1;

  arid=0;
  araddr=0;
  arlen=0;
  arsize=0;
  arburst=0;
  arlock=0;
  arvalid=0;

  rready=1;
end

always  begin #2.5 clk=~clk; end

initial begin #10 rst_n=1; end

//write data

initial begin 
  #5
  awlen=4'b0100;   //5
  awsize=3'b010;   //4 byte
  awburst=2'b01;   //incr
end

initial begin
  #10
  awvalid=1;
  #5
  awvalid=0;
end

always begin
  #2.5 wdata=wdata+1;
end

initial begin #25 wstrb=4'b1111; end

initial begin #25 wvalid=1; #10 wvalid=0; #5 wvalid=1; #15 wvalid=0; end 

initial begin #50 wlast=1; #5 wlast=0; end

//read data

initial begin
  #100
  arlen=4'b0100;
  arsize=3'b010;
  arburst=2'b01;
end

initial begin
  #110
  arvalid=1;
  #5
  arvalid=0;
end

endmodule

