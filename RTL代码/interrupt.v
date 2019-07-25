/***********************************************
#
#      Filename: interrupt.v
#
#        Author: lixiaofei
#   Description: interrupt with 6 input and 1 output
#        Create: 2019-06-14 09:58:25
#     Copyright: 302-2 Studio
***********************************************/

module interrupt(

output     [5:0]intr_type,             //output to AXI_SLV for software to read
output reg idle,
output     intr,

input      clk,rst_n,

input      data_received,               //AXI_SLV has received configdata
input      intr_checked,                 //software has checked intr

input      crc_veri,
input      error_slv_read,
input      error_slv_write,
input      error_mst_read,
input      error_mst_write,
input      data_written
);

reg        crc_veri_reg;                //CRC module has generated verification result
reg        error_slv_read_reg;          //AXI_SLV read error
reg        error_slv_write_reg;          //AXI_SLV write error
reg        error_mst_read_reg;          //AXI_mst read error
reg        error_mst_write_reg;          //AXI_mst write error
reg        data_written_reg;             //CRC code has been written to the destination


always@(posedge clk,negedge rst_n)
   if(~rst_n||intr_checked)
     crc_veri_reg<=0;
   else if(crc_veri) 
     crc_veri_reg<=1;
   
always@(posedge clk,negedge rst_n)
   if(~rst_n||intr_checked)
     error_slv_read_reg<=0;
   else if(error_slv_read) 
     error_slv_read_reg<=1;

always@(posedge clk,negedge rst_n)
   if(~rst_n||intr_checked)
     error_slv_write_reg<=0;
   else if(error_slv_write) 
     error_slv_write_reg<=1;

always@(posedge clk,negedge rst_n)
   if(~rst_n||intr_checked)
     error_mst_read_reg<=0;
   else if(error_mst_read) 
     error_mst_read_reg<=1;

always@(posedge clk,negedge rst_n)
   if(~rst_n||intr_checked)
     error_mst_write_reg<=0;
   else if(error_mst_write) 
     error_mst_write_reg<=1;

always@(posedge clk,negedge rst_n)
   if(~rst_n||intr_checked)
     data_written_reg<=0;
   else if(data_written) 
     data_written_reg<=1;  

always@(posedge clk,negedge rst_n)
  if(~rst_n)
    idle<=0;
  else if(data_written_reg||crc_veri_reg)
    idle<=1;
  else if(data_received)
    idle<=0;

assign intr= crc_veri_reg|| error_slv_read_reg|| error_slv_write_reg|| error_mst_read_reg|| error_mst_write_reg||data_written_reg;

assign intr_type=error_slv_write_reg?7'b000001:
                   error_mst_read_reg?7'b000010:
                     error_mst_write_reg?7'b000100:
                        error_slv_read_reg?7'b001000:
                                crc_veri_reg?7'b010000:
                              data_written_reg?7'b100000:7'b000000;

endmodule


