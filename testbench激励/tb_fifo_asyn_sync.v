/***********************************************
#
#      Filename: tb_fifo_asyn_sync.v
#
#        Author: lixiaofei
#   Description: Testbench for fifo
#        Create: 2019-06-03 08:43:17
#     Copyright: 302-2 Studio
***********************************************/
`timescale 1ns/100ps

module tb_fifo_asyn_sync();

wire [31:0]data_out_asyn;
wire [31:0]data_out_sync;
wire fifo_full;
wire fifo_empty_asyn;
wire fifo_empty_sync;

reg  [31:0]data_in;
reg  en_write;
reg  en_read_asyn;
reg  en_read_sync;

reg w_clk;
reg wrst_n;

reg r_clk;
reg rrst_n;

fifo_asyn_sync U1(
   data_out_asyn,
   data_out_sync,
   fifo_full,
   fifo_empty_asyn,
   fifo_empty_sync,

   data_in,
   en_write,
   en_read_asyn,
  en_read_sync,
    w_clk,              
     wrst_n,

     r_clk,               
       rrst_n



);

initial #1500 $stop;

initial begin
  data_in=0;
  en_write=0;
  en_read_asyn=0;
  en_read_sync=0;
  w_clk=0;
  wrst_n=0;
  r_clk=0;
  rrst_n=0;
end

initial begin
  #11 
  wrst_n=1;
  rrst_n=1;
end

always #5 w_clk=~w_clk;
always #2 r_clk=~r_clk;

initial begin
  #100 en_write=1;
  #500 en_read_asyn=1;
  #200 en_read_sync=1;
end

always@(posedge w_clk) data_in=data_in+1;

endmodule
