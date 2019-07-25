/***********************************************
#
#      Filename: AXI3_slv.v
#
#        Author: lixiaofei
#   Description: AXI SLAVE FOR BOTH READ AND WRITE
#        Create: 2019-05-16 14:24:33
#     Copyright: 302-2 Studio
***********************************************/
module AXI3_slv#(

parameter ADDR_WIDTH=32,
parameter DATA_WIDTH=32

)
(
input           clk,
input           rst_n,

output reg      data_received,                //slave has received configdata.
output reg      intr_checked,                 //software has checked the intr.

output          [31:0]addr_src,               //source addr of raw data
output          [31:0]addr_dst,               //destination addr to write raw data and crc code
output          [15:0]data_len,               //the length of raw data
output          [2:0]crc_mode,                //crc-8 crc-12 crc-16 crc-ccitt

input           [1:0]veri_result,             //verification resulr
input           [5:0]intr_type,               //6 types of intrrupt
output          error_read,                   //error to read 
output          error_write,                  //error to write

// write addr channel

output          awready,

input           [3:0]awid,
input           [ADDR_WIDTH-1:0]awaddr,
input           [3:0]awlen,
input           [2:0]awsize,
input           [1:0]awburst,
input           [1:0]awlock,          
input           awvalid,

// write data channel

output          wready,

input           [3:0]wid,
input           [DATA_WIDTH-1:0]wdata,
input           [3:0]wstrb,
input           wlast,
input           wvalid,

// write response channel

output       reg [3:0]bid,
output       reg [1:0]bresp,
output       reg bvalid,

input        bready,

// read addr channel
//
output          arready,

input           [3:0]arid,
input           [ADDR_WIDTH-1:0]araddr,
input           [3:0]arlen,
input           [2:0]arsize,
input           [1:0]arburst,
input           [1:0]arlock,
           
           
input           arvalid,

// read data channel
//
output       reg [3:0]rid,
output       reg [DATA_WIDTH-1:0]rdata,
output       reg [1:0]rresp,
output       reg rlast,
output       reg rvalid,

input        rready     
);


reg write_flag;                                   //sign of whether the next data will wirte or not


reg read_time;
reg [7:0]reg_file[11:0];                          //for configdata


wire error1;
wire error2;
wire error3;
wire error4;


reg [3:0]arid_reg;
reg [ADDR_WIDTH-1:0]araddr_reg;
reg [4:0]arlen_reg;
reg [2:0]arsize_reg;
reg [1:0]arburst_reg;
reg [1:0]arlock_reg;


reg [3:0]awid_reg;
reg [ADDR_WIDTH-1:0]awaddr_reg;
reg [4:0]awlen_reg;
reg [2:0]awsize_reg;
reg [1:0]awburst_reg;
reg [1:0]awlock_reg;

reg [1:0]veri_result_reg;
//write addr channel

assign awready=1'b1;                           

assign wready=1'b1;                       

assign addr_src={reg_file[0],reg_file[1],reg_file[2],reg_file[3]};
assign addr_dst={reg_file[4],reg_file[5],reg_file[6],reg_file[7]};
assign data_len={reg_file[8],reg_file[9]};
assign crc_mode=reg_file[10][7:5];

assign error_read=error1||error2;
assign error_write=error3||error4;


always@(posedge clk,negedge rst_n) 
  if(~rst_n) begin
    reg_file[11][7:6]<=0;
    veri_result_reg<=0;
  end
  else begin
    reg_file[11][7:6]<=veri_result_reg;
    veri_result_reg<=veri_result;
  end

always@(posedge clk,negedge rst_n) 
  if(~rst_n) 
    reg_file[11][5:0]<=0;
  else
    reg_file[11][5:0]<=intr_type[5:0];



always@(posedge clk,negedge rst_n) begin
  if(~rst_n) begin
    awid_reg<=0;
    awaddr_reg<=0;
    awlen_reg<=0;
    awsize_reg<=0;
    awburst_reg<=0;
    awlock_reg<=0;
  end
  else if(awvalid&&awready) begin
    awid_reg<=awid;
    awaddr_reg<=awaddr;
    awlen_reg<=awlen;                              //!!!!!!!
    awsize_reg<=awsize;
    awburst_reg<=awburst;
    awlock_reg<=awlock;
  end
end

assign error3=~(awburst_reg==2'b00||awburst_reg==2'b01);
assign error4=(awsize_reg>3'b010);

// write data channel

always@(posedge clk,negedge rst_n) begin    
  if(~rst_n)
    write_flag<=0;
  else if(wvalid&&wready) begin
    write_flag<=1;
    if(wstrb[0]==1'b1)
      reg_file[awaddr_reg+3]<=wdata[7:0];
    if(wstrb[1]==1'b1)
      reg_file[awaddr_reg+2]<=wdata[15:8];
    if(wstrb[2]==1'b1)
      reg_file[awaddr_reg+1]<=wdata[23:16];
    if(wstrb[3]==1'b1)
      reg_file[awaddr_reg]<=wdata[31:24];
    if(awburst==2'b01)
      awaddr_reg<=awaddr_reg+4;
  end
end

always@(posedge clk,negedge rst_n)begin  
  if(~rst_n)
    data_received<=0;
  else if(awaddr_reg==32'd12)
    data_received<=1;
  else 
    data_received<=data_received;
end

always@(posedge clk,negedge rst_n)begin  
  if(~rst_n)
    intr_checked<=0;
  else if(araddr_reg==32'd12)
    intr_checked<=1;
  else 
    intr_checked<=intr_checked;
end


// write response channel signals

always@(posedge clk,negedge rst_n)
 if(~rst_n)
  bid<=3'b0;
 else if(wlast&&wvalid)
  bid<=awid;                                   


always@(posedge clk,negedge rst_n) begin 
 if(~rst_n)
   bresp<=2'b00;                                 //reset to okay   
 else if(wlast&&wready) begin
   if(error3||error4||awlen_reg>8)
     bresp<=2'b10;                                 //SLVERR
   else
     bresp<=2'b00;
   end
 else
   bresp<=bresp;
end

always@(posedge clk,negedge rst_n) begin 
 if(~rst_n)
   bvalid<=0;
 else if(wlast&&wvalid)
   bvalid<=1;
 else if(bvalid&&bready)
   bvalid<=0;
 else
   bvalid<=bvalid;
end




// read channel begin------------------------------------------------

assign arready=1'b1;                                          

always@(posedge clk,negedge rst_n) 
  if(~rst_n)
  begin
   arid_reg<=0;
   araddr_reg<=0;
   arlen_reg<=0;
   arsize_reg<=0;
   arburst_reg<=0;
   arlock_reg<=0;
 end
  else if(arvalid&&arready)
  begin                                             //pipeline
   arid_reg<=arid;
   araddr_reg<=araddr;
   arlen_reg<=arlen+1;                             
   arsize_reg<=arsize;
   arburst_reg<=arburst;
   arlock_reg<=arlock;
 end

assign error1=~(arburst_reg==2'b00||arburst_reg==2'b01);
assign error2=(arsize_reg>3'b010);



// read data channel signal
//
 always@(posedge clk,negedge rst_n) 
  if(~rst_n) 
   rid<=3'b000;
 else
   rid<=arid_reg;                                     //pipeline

// rresp

always@(posedge clk,negedge rst_n) 
  if(~rst_n)
    rresp<=2'b00;                                     //okay
  else if(error1||error2||(araddr_reg>32'd31&&arlen_reg>0))
    rresp<=2'b01;                                     //SLVERR
  else 
    rresp<=2'b00;
   




always@(posedge clk,negedge rst_n) begin                                                    //read data
  if(~rst_n)begin
   rdata<=32'b0;
   rvalid<=1'b0;
   read_time<=1'b0;
 end


   else if((arburst_reg==2'b01||arburst_reg==2'b00)&&arlen_reg>4'b0&&read_time==1'b0) begin                   
     case(arsize)
       3'b000:begin
     rdata<=reg_file[araddr_reg];
     rvalid<=1'b1;
     if(arburst_reg==2'b01)                                                                   //fixed or incr burst!
     araddr_reg<=araddr_reg+1;
     arlen_reg<=arlen_reg-1;
     read_time<=1'b1;
   end
       3'b001:begin
     rdata<={reg_file[araddr_reg],reg_file[araddr_reg+1]};
     rvalid<=1'b1;
     if(arburst_reg==2'b01)
     araddr_reg<=araddr_reg+2;
     arlen_reg<=arlen_reg-1;
     read_time<=1'b1;
   end
       3'b010:begin
     rdata<={reg_file[araddr_reg],reg_file[araddr_reg+1],reg_file[araddr_reg+2],reg_file[araddr_reg+3]};
     rvalid<=1'b1;
     if(arburst_reg==2'b01)
     araddr_reg<=araddr_reg+4;
     arlen_reg<=arlen_reg-1;
     read_time<=1'b1;
   end
   endcase
   end
   else if((arburst_reg==2'b01||arburst_reg==2'b00)&&arlen_reg>4'b0&&read_time==1'b1) begin  //if rready is 0,then hold the data and valid signal           
     if(rready) begin                                                                     //if rready is 1,then transfer the next data
     case(arsize)
       3'b000:begin
     rdata<=reg_file[araddr_reg];
     rvalid<=1'b1;
     if(arburst_reg==2'b01)
     araddr_reg<=araddr_reg+1;
     arlen_reg<=arlen_reg-1;
     read_time<=1'b1;
   end
       3'b001:begin
     rdata<={reg_file[araddr_reg],reg_file[araddr_reg+1]};
     rvalid<=1'b1;
     if(arburst_reg==2'b01)
     araddr_reg<=araddr_reg+2;
     arlen_reg<=arlen_reg-1;
     read_time<=1'b1;
   end
       3'b010:begin
     rdata<={reg_file[araddr_reg],reg_file[araddr_reg+1],reg_file[araddr_reg+2],reg_file[araddr_reg+3]};
     rvalid<=1'b1;
     if(arburst_reg==2'b01)
     araddr_reg<=araddr_reg+4;
     arlen_reg<=arlen_reg-1;
     read_time<=1'b1;
   end
   endcase
   end
   end
   else if(arlen_reg==5'b0&&rready==1) begin          //end of the burst
     rvalid<=1'b0;
     read_time<=1'b0;
     rdata<=32'b0;
   end
 end   //end of always

 always@(posedge clk,negedge rst_n) begin
  if(~rst_n)
    rlast<=1'b0;
  else if(arlen_reg==5'b1)                           //represent the last data to be read
    rlast<=1'b1;
  else if(arlen_reg==5'b0&&rready==1)
    rlast<=1'b0;
end
    
//read channel end----------------------------------------------------------

endmodule 


       
       
     








