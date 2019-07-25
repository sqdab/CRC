/***********************************************
#
#      Filename: top_CRC_core.v
#
#        Author: lixiaofei
#   Description: TOP module fo the IP
#        Create: 2019-06-15 15:36:15
#     Copyright: 302-2 Studio
***********************************************/

module top_CRC_core #(

parameter ADDR_WIDTH=32,
parameter DATA_WIDTH=32

)(
output  intr,
output  idle,

input   bus_clk,
input   bus_rst_n,

input   crc_clk,
input   crc_rst_n,

//output of AXI_slv
output  o_awready,
output  o_wready,
output  [3:0]o_bid,
output  [1:0]o_bresp,
output  o_bvalid,
output  o_arready,
output  [3:0]o_rid,
output  [DATA_WIDTH-1:0]o_rdata,
output  [1:0]o_rresp,
output  o_rlast,
output  o_rvalid,

//input of AXI_slv
input   [3:0]i_awid,
input   [ADDR_WIDTH-1:0]i_awaddr,
input   [3:0]i_awlen,
input   [2:0]i_awsize,
input   [1:0]i_awburst,
input   [1:0]i_awlock,
input   i_awvalid,
input   [3:0]i_wid,
input   [DATA_WIDTH-1:0]i_wdata,
input   [3:0]i_wstrb,
input   i_wlast,
input   i_wvalid,
input   i_bready,
input   [3:0]i_arid,
input   [ADDR_WIDTH-1:0]i_araddr,
input   [3:0]i_arlen,
input   [2:0]i_arsize,
input   [1:0]i_arburst,
input   [1:0]i_arlock,
input   i_arvalid,
input   i_rready,

//output of AXI3_mst_read
output  [3:0]o_arid,
output  [ADDR_WIDTH-1:0]o_araddr,
output  [3:0]o_arlen,
output  [2:0]o_arsize,
output  [1:0]o_arburst,
output  [1:0]o_arlock,
output  [3:0]o_arcache,
output  [2:0]o_arprot,
output  o_arvalid,
output  o_rready,

//input of AXI3_mst_read
input   i_arready,
input   [3:0]i_rid,
input   [DATA_WIDTH-1:0]i_rdata,
input   [1:0]i_rresp,
input   i_rlast,
input   i_rvalid,

//output of AXI3_mst_write
output  [3:0]o_awid,
output  [ADDR_WIDTH-1:0]o_awaddr,
output  [3:0]o_awlen,
output  [2:0]o_awsize,
output  [1:0]o_awburst,
output  [1:0]o_awlock,
output  [3:0]o_awcache,
output  [2:0]o_awprot,
output  o_awvalid,
output  [3:0]o_wid,
output  [DATA_WIDTH-1:0]o_wdata,
output  [3:0]o_wstrb,
output  o_wlast,
output  o_wvalid,
output  o_bready,

//input of AXI3_mst_write
input   i_awready,
input   i_wready,
input   [3:0]i_bid,
input   [1:0]i_bresp,
input   i_bvalid
);


wire     data_received;
wire     intr_checked;
wire     [31:0]addr_src;
wire     [31:0]addr_dst;
wire     [15:0]data_len;
wire     [2:0]crc_mode;

wire     [1:0]veri_result;
wire     [5:0]intr_type;
wire     error_read;
wire     error_write;

wire     data_received2crc;

wire     crc_result_received;
wire     [DATA_WIDTH-1:0]data_in_crc;
wire     empty_asyn_fifo;
wire     en_read_asyn;
wire     [15:0]crc_result;
wire     process_complt;

wire     [DATA_WIDTH-1:0]data_out_sync;
wire     fifo_full;
wire     fifo_empty_sync;
wire     [DATA_WIDTH-1:0]data_in;
wire     en_write;
wire     en_read_sync;

wire     error_mst_read;

wire     en_data_crc;
wire     error_mst_write;
wire     data_written;


reg      bus_rst_n_reg1;
reg      bus_rst_n_reg2;
reg      crc_rst_n_reg1;
reg      crc_rst_n_reg2;


always @(posedge bus_clk,negedge bus_rst_n) begin        // Synchronized release for bus_rst_n
  if(~bus_rst_n) begin
    bus_rst_n_reg1<=0;
    bus_rst_n_reg2<=0;
  end

  else
  begin
    bus_rst_n_reg1<=1'b1;
    bus_rst_n_reg2<=bus_rst_n_reg1;
  end
end

always @(posedge crc_clk,negedge crc_rst_n) begin       // Synchronized release for crc_rst_n
  if(~crc_rst_n) begin
    crc_rst_n_reg1<=0;
    crc_rst_n_reg2<=0;
  end
  else
  begin
    crc_rst_n_reg1<=1'b1;
    crc_rst_n_reg2<=crc_rst_n_reg1;
  end
end



AXI3_slv#(
.ADDR_WIDTH(ADDR_WIDTH),
.DATA_WIDTH(DATA_WIDTH)
)
U1_AXI3_slv(

bus_clk,
bus_rst_n_reg2,

data_received,
intr_checked,

addr_src,
addr_dst,
data_len,
crc_mode,

veri_result,
intr_type,
error_read,
error_write,
o_awready,

i_awid,
i_awaddr,
i_awlen,
i_awsize,
i_awburst,
i_awlock,          
i_awvalid,

o_wready,

i_wid,
i_wdata,
i_wstrb,
i_wlast,
i_wvalid,

o_bid,
o_bresp,
o_bvalid,

i_bready,

o_arready,

i_arid,
i_araddr,
i_arlen,
i_arsize,
i_arburst,
i_arlock,

i_arvalid,
o_rid,
o_rdata,
o_rresp,
o_rlast,
o_rvalid,

i_rready    
);

//data_received from slv to crc
slow2fast U1_slow2fast(

data_received2crc,
data_received,
crc_clk,
crc_rst_n_reg2
);




crc_cal U1_crc_cal(

crc_clk,
crc_rst_n_reg2,
crc_result_received,
data_in_crc,
data_len,
crc_mode[1:0],
crc_mode[2],
empty_asyn_fifo,
data_received2crc,
en_read_asyn,
veri_result,
crc_result,
process_complt
);



fifo_asyn_sync#(
.DATA_WIDTH(DATA_WIDTH),
.DATA_DEEPTH(8),
.ADDR_WIDTH(3)
) 
U1_fifo_asyn_sync(

data_in_crc,
data_out_sync,
fifo_full,
empty_asyn_fifo,
fifo_empty_sync,

data_in,
en_write,
en_read_asyn,
en_read_sync,

bus_clk,              
bus_rst_n_reg2,

crc_clk,               
crc_rst_n_reg2
);



AXI3_mst_read#(
.ADDR_WIDTH(ADDR_WIDTH),
.DATA_WIDTH(DATA_WIDTH)
)
U1_AXI3_mst_read(
bus_clk,
bus_rst_n_reg2,

addr_src, 
data_len,              
data_received,                   

fifo_full,                   
data_in,
en_write,                               

error_mst_read,                 

i_arready,

o_arid,
o_araddr,
o_arlen,
o_arsize,
o_arburst,
o_arlock,
o_arcache,
o_arprot,
o_arvalid,



i_rid,
i_rdata,
i_rresp,
i_rlast,
i_rvalid,
o_rready  
);


fast2slow U1_fast2slow(

en_data_crc,
crc_result_received,
process_complt,

crc_clk,
crc_rst_n_reg2,

bus_clk,
bus_rst_n_reg2
);







AXI3_mst_write#(
.ADDR_WIDTH(ADDR_WIDTH),
.DATA_WIDTH(DATA_WIDTH)
)
U1_AXI3_mst_write(
bus_clk,
bus_rst_n_reg2,

addr_dst,   
data_len,              
crc_mode,               
data_received,                 

en_data_crc,              

fifo_empty_sync,                  
data_out_sync,      
crc_result,           

en_read_sync,                 
error_mst_write,               

data_written,           

i_awready,

o_awid,
o_awaddr,
o_awlen,
o_awsize,
o_awburst,
o_awlock,
o_awcache,
o_awprot,  
o_awvalid,

i_wready,

o_wid,
o_wdata,
o_wstrb,
o_wlast,
o_wvalid,

i_bid,
i_bresp,
i_bvalid,

o_bready
);



interrupt U1_interrupt(

intr_type,
idle,
intr,

bus_clk,
bus_rst_n_reg2,

data_received,
intr_checked,

en_data_crc,
error_read,
error_write,
error_mst_read,
error_mst_write,
data_written
); 


endmodule







