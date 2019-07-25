/***********************************************
#
#      Filename: fifo_asyn_sync.v
#
#        Author: lixiaofei
#   Description: A asyn fifo with the function of sync read.
#        Create: 2019-05-28 17:09:23
#     Copyright: 302-2 Studio
***********************************************/


module fifo_asyn_sync#(
  parameter DATA_WIDTH=32,
  parameter DATA_DEEPTH=8,
  parameter ADDR_WIDTH=3

)(
  output wire [DATA_WIDTH-1:0]data_out_asyn,   //output to crc module
  output     [DATA_WIDTH-1:0]data_out_sync,    //output to AXI_mst_write
  output reg fifo_full,
  output reg fifo_empty_asyn,
  output reg fifo_empty_sync,

  input      [DATA_WIDTH-1:0]data_in,
  input      en_write,
  input      en_read_asyn,
  input      en_read_sync,

  input      w_clk,               //sync clock
  input      wrst_n,

  input      r_clk,               //asyn clock
  input      rrst_n
);

//asyn fifo begin---------------------------------------------

reg [DATA_WIDTH-1:0]mem[DATA_DEEPTH-1:0];

reg [ADDR_WIDTH:0]addr_read;
reg [ADDR_WIDTH:0]addr_write;
reg [ADDR_WIDTH:0]addr_read_gray;
reg [ADDR_WIDTH:0]addr_write_gray;
reg [ADDR_WIDTH:0]addr_read_gray1;
reg [ADDR_WIDTH:0]addr_write_gray1;
reg [ADDR_WIDTH:0]addr_read_gray2;
reg [ADDR_WIDTH:0]addr_write_gray2;

wire [ADDR_WIDTH-1:0]addr_read_mem;
wire [ADDR_WIDTH-1:0]addr_write_mem;

wire [ADDR_WIDTH:0]addr_read_next;
wire [ADDR_WIDTH:0]addr_write_next;
wire [ADDR_WIDTH:0]addr_read_nextgray;
wire [ADDR_WIDTH:0]addr_write_nextgray;

reg  [ADDR_WIDTH-1:0]addr_read_sync;
reg  fifo_full_sync;

wire fifo_full_asyn;
wire empty;

wire [DATA_WIDTH-1:0]data_out_asyn_reg2;
reg  [DATA_WIDTH-1:0]data_out_asyn_reg1;
reg  en_read_asyn_time;

always@(posedge r_clk,negedge rrst_n)
  if(~rrst_n)begin
    en_read_asyn_time<=0;
  end
  else if(en_read_asyn)
    en_read_asyn_time<=1;


assign addr_read_mem=addr_read[ADDR_WIDTH-1:0];               //addr for mem to read 
assign addr_write_mem=addr_write[ADDR_WIDTH-1:0];             //addr for mem to write

assign addr_read_next=(en_read_asyn_time&&en_read_asyn&&(~fifo_empty_asyn))?addr_read+1:addr_read;  //addr changes or not 
assign addr_write_next=(en_write&&~(fifo_full))?addr_write+1:addr_write;

assign addr_read_nextgray=addr_read_next^(addr_read_next>>1);                 //to generate gray code 
assign addr_write_nextgray=addr_write_next^(addr_write_next>>1);

//assign data_out_asyn=mem[addr_read_mem];                     //data output to crc module
assign data_out_asyn=(addr_read_mem== 'd0 && en_read_asyn_time=='d0)? 'd0 :mem[addr_read_mem];                     //data output to crc module

always@(posedge r_clk,negedge rrst_n) begin                  //
  if(~rrst_n)begin
    addr_read<=0;
    addr_read_gray<=0;    
  end
  else begin
    addr_read<=addr_read_next;
    addr_read_gray<=addr_read_nextgray;                      //to sync the gray code
  end 
end
 

always@(posedge w_clk,negedge wrst_n) begin
  if(~wrst_n)begin
    addr_write<=0;
    addr_write_gray<=0;
  end
  else begin
    addr_write<=addr_write_next;
    addr_write_gray<=addr_write_nextgray;
  end
end

always@(posedge w_clk)begin                                 //write data to mem
  if(en_write&&(~fifo_full))
    mem[addr_write_mem][31:0]<=data_in;
end

always@(posedge r_clk,negedge rrst_n) begin                 //sync the gray code from w_clk to r_clk
  if(~rrst_n)begin
    addr_write_gray1<=0;
    addr_write_gray2<=0;
  end
  else begin
    addr_write_gray1<=addr_write_gray;
    addr_write_gray2<=addr_write_gray1;
  end
end

always@(posedge w_clk,negedge wrst_n) begin                //sync the gray code from r_clk to w_clk
  if(~wrst_n)begin
    addr_read_gray1<=0;
    addr_read_gray2<=0;
  end
  else begin
    addr_read_gray1<=addr_read_gray;
    addr_read_gray2<=addr_read_gray1;
  end
end

//if the topest two numbers meet, fifo is empty. or full. 
assign fifo_full_asyn=(addr_write_nextgray=={~addr_read_gray2[ADDR_WIDTH:ADDR_WIDTH-1],addr_read_gray2[ADDR_WIDTH-2:0]});
assign empty=(addr_read_nextgray==addr_write_gray2);

always@(posedge r_clk,negedge rrst_n)
//  if(~rrst_n)
//    fifo_empty_asyn<=0;
//  else
    fifo_empty_asyn<=empty;

always@(posedge w_clk,negedge wrst_n)
  if(~wrst_n)
    fifo_full<=0;
  else
    fifo_full<=(fifo_full_asyn|fifo_full_sync);

//asyn fifo end-------------------------------------------
//sync fifo begin-----------------------------------------

assign data_out_sync=mem[addr_read_sync];

always@(posedge w_clk,negedge wrst_n)begin    //read data from mem
  if(~wrst_n)
    addr_read_sync<=0;
  else if(en_read_sync&&(~fifo_empty_sync))
    addr_read_sync<=addr_read_sync+1;
end


always@(posedge w_clk,negedge wrst_n)begin   //fifo_empty_sync
  if(~wrst_n)
    fifo_empty_sync<=0;
  else if((en_read_sync&&(~en_write))&&(addr_write_mem==addr_read_sync+1'b1))
    fifo_empty_sync<=1;
  else if(fifo_empty_sync&&en_write)
    fifo_empty_sync<=0;
end

always@(posedge w_clk,negedge wrst_n)begin   //fifo_full_sync
  if(~wrst_n)
    fifo_full_sync<=0;
  else if((en_write&&(~en_read_sync))&&((addr_write_mem+1'b1)==addr_read_sync))
    fifo_full_sync<=1;
  else if(fifo_full_sync&&en_read_sync)
    fifo_full_sync<=0;
end


//sync fifo end--------------------------------------------



endmodule



