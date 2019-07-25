/***********************************************
#
#      Filename: tb_top_CRC_core.v
#
#        Author: lixiaofei
#   Description: Testbench for TOP
#        Create: 2019-06-17 14:33:22
#     Copyright: 302-2 Studio
***********************************************/

`timescale 1ns/100ps

module tb_top_CRC_core();

parameter DATA_WIDTH=32;
parameter ADDR_WIDTH=32;

wire  intr;
wire  idle;

reg   bus_clk;
reg   bus_rst_n;

reg   crc_clk;
reg   crc_rst_n;

//output of AXI_slv
wire  o_awready;
wire  o_wready;
wire  [3:0]o_bid;
wire  [1:0]o_bresp;
wire  o_bvalid;
wire  o_arready;
wire  [3:0]o_rid;
wire  [DATA_WIDTH-1:0]o_rdata;
wire  [1:0]o_rresp;
wire  o_rlast;
wire  o_rvalid;

//input of AXI_slv
reg   [3:0]i_awid;
reg   [ADDR_WIDTH-1:0]i_awaddr;
reg   [3:0]i_awlen;
reg   [2:0]i_awsize;
reg   [1:0]i_awburst;
reg   [1:0]i_awlock;
reg   i_awvalid;
reg   [3:0]i_wid;
reg   [DATA_WIDTH-1:0]i_wdata;
reg   [3:0]i_wstrb;
reg   i_wlast;
reg   i_wvalid;
reg   i_bready;
reg   [3:0]i_arid;
reg   [ADDR_WIDTH-1:0]i_araddr;
reg   [3:0]i_arlen;
reg   [2:0]i_arsize;
reg   [1:0]i_arburst;
reg   [1:0]i_arlock;
reg   i_arvalid;
reg   i_rready;

//output of AXI3_mst_read
wire  [3:0]o_arid;
wire  [ADDR_WIDTH-1:0]o_araddr;
wire  [3:0]o_arlen;
wire  [2:0]o_arsize;
wire  [1:0]o_arburst;
wire  [1:0]o_arlock;
wire  [3:0]o_archache;
wire  [2:0]o_arprot;
wire  o_arvalid;
wire  o_rready;

//input of AXI3_mst_read
reg   i_arready;
reg   [3:0]i_rid;
reg   [DATA_WIDTH-1:0]i_rdata;
reg   [1:0]i_rresp;
reg   i_rlast;
reg   i_rvalid;

//output of AXI3_mst_write
wire  [3:0]o_awid;
wire  [ADDR_WIDTH-1:0]o_awaddr;
wire  [3:0]o_awlen;
wire  [2:0]o_awsize;
wire  [1:0]o_awburst;
wire  [1:0]o_awlock;
wire  [3:0]o_awcache;
wire  [2:0]o_awprot;
wire  o_awvalid;
wire  [3:0]o_wid;
wire  [DATA_WIDTH-1:0]o_wdata;
wire  [3:0]o_wstrb;
wire  o_wlast;
wire  o_wvalid;
wire  o_bready;

//input of AXI3_mst_write
reg   i_awready;
reg   i_wready;
reg   [3:0]i_bid;
reg   [1:0]i_bresp;
reg   i_bvalid;

top_CRC_core U1_top_CRC_core(
intr,idle,bus_clk,bus_rst_n,crc_clk,crc_rst_n,o_awready,o_wready,o_bid,
o_bresp,o_bvalid,o_arready,o_rid,o_rdata,o_rresp,o_rlast,o_rvalid,i_awid,
i_awaddr,i_awlen,i_awsize,i_awburst,i_awlock,i_awvalid,i_wid,i_wdata,
i_wstrb,i_wlast,i_wvalid,i_bready,i_arid,i_araddr,i_arlen,i_arsize,
i_arburst,i_arlock,i_arvalid,i_rready,o_arid,o_araddr,o_arlen,o_arsize,
o_arburst,o_arlock,o_archache,o_arprot,o_arvalid,o_rready,i_arready,
i_rid,i_rdata,i_rresp,i_rlast,i_rvalid,o_awid,o_awaddr,o_awlen,o_awsize,
o_awburst,o_awlock,o_awcache,o_awprot,o_awvalid,o_wid,o_wdata,o_wstrb,
o_wlast,o_wvalid,o_bready,i_awready,i_wready,i_bid,i_bresp,i_bvalid
);

initial #5000 $stop;

initial begin
  bus_clk=0;
  bus_rst_n=0;
  crc_clk=0;
  crc_rst_n=0;
  #5
  bus_rst_n=1;
  crc_rst_n=1;
end

always #2.5 bus_clk=~bus_clk;
always #1   crc_clk=~crc_clk;



// AXI_slv
initial begin
  i_awid=0;
  i_awaddr=0;
  i_awlen=0;
  i_awsize=0;
  i_awburst=0;
  i_awlock=0;
  i_awvalid=0;
  i_wid=0;
  i_wdata=0;
  i_wstrb=0;
  i_wlast=0;
  i_wvalid=0;
  i_bready=1;
  i_arid=0;
  i_araddr=0;
  i_arlen=0;
  i_arsize=0;
  i_arburst=0;
  i_arlock=0;
  i_arvalid=0;
  i_rready=1;
  #0.5
  #17.5            //write addr to AXI_slv
  i_awaddr=0;
  i_awlen=4'b0010;
  i_awsize=3'b010;
  i_awburst=2'b01;
  i_awvalid=1;
//  i_wdata=0;
//  i_wstrb=0;
//  i_wlast=0;
//  i_wvalid=0;
  i_araddr=0;
  i_arlen=4'b0010;
  i_arsize=3'b010;
  i_arburst=2'b01;
//  i_arvalid=0;
  i_rready=1;
  #5               //begin to write configdata to AXI_slv
  i_awvalid=0;
  i_wvalid=1;
  #10
  i_wlast=1;
  #5
  i_wvalid=0;
  i_wlast=0;
end


initial begin
  #0.5
  #22.5
  i_wdata<=32'h0000_0000;
  #5
  i_wdata<=32'h0fff_ffff;
  #5
  i_wdata<=32'h014d_6000;
end



initial begin
 #0.5
 #22.5
  i_wstrb<=4'b1111;
 #10
  i_wstrb<=4'b1110;
 #5
  i_wstrb<=0;
end

always@(*) begin
  if(intr)begin
    i_arvalid=1;
    #5
    i_arvalid=0;
  end
end


//AXI3_mst_read

initial begin
  i_arready=1;
  i_rid=0;
  i_rdata=32'ha5a55a5a;
  i_rresp=0;
  i_rlast=0;
  i_rvalid=0;
  #0.5
  #50                    //begin to read data
  i_rvalid=1;
  #420                   //read 84 beats
  i_rvalid=0;
end

initial begin
  #0.5
  #140 i_rlast=1;
  #5   i_rlast=0;
  #80  i_rlast=1;
  #5   i_rlast=0;
  #80  i_rlast=1;
  #5   i_rlast=0;
  #80  i_rlast=1;
  #5   i_rlast=0;
  #80  i_rlast=1;
  #25  i_rlast=0;
end

always@(posedge bus_clk) i_rdata<=i_rdata+1;


//AXI3_mst_write

initial begin
  i_awready=1;
  i_wready=1;
  i_bid=0;
  i_bresp=0;
  i_bvalid=0;
 
end

always@(*) 
  if(o_wlast)begin
    i_bvalid=1;
    #5
    i_bvalid=0;
  end


























endmodule
