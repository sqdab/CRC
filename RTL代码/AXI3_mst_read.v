/***********************************************
#
#      Filename: AXI3_mst_read.v
#
#        Author: lixiaofei
#   Description: AXI master, read module.
#        Create: 2019-05-21 09:37:14
#     Copyright: 302-2 Studio
***********************************************/
module AXI3_mst_read #(
parameter ADDR_WIDTH=32,
          DATA_WIDTH=32         
)
(
input           clk,
                rst_n,

input           [ADDR_WIDTH-1:0]addr_src,   //source addr
input           [15:0]data_len,              //length of data
input           mst_begin,                   //slave has received the data, master begin to work




input           fifo_full,                   //stop receive data if asyn-fifo_full is 1, if sync is needed, how to deal with the delay
output          [DATA_WIDTH-1:0]read_data,
output          en_write,                    //enable asyn-fifo to write.              


output reg      error,                 //the memory response bad.for intr!!!!    
  


// read addr channel

input           arready,

output reg      [3:0]arid,
output          [ADDR_WIDTH-1:0]araddr,
output reg      [3:0]arlen,
output reg      [2:0]arsize,
output reg      [1:0]arburst,
output reg      [1:0]arlock,
output reg      [3:0]arcache,
output reg      [2:0]arprot,
output          arvalid,

// read data channel
//
input           [3:0]rid,
input                [DATA_WIDTH-1:0]rdata,
input                [1:0]rresp,
input                rlast,
input                rvalid,

output reg      rready  
);

reg [2:0]count;
reg [6:0]len_reg;


reg [ADDR_WIDTH-1:0]addr_src_reg;
reg [15:0]data_len_reg;

reg [9:0]num_incr16;
reg num_incr8;
reg num_incr4;
reg [1:0]num_incr1_1;
reg num_incr1_2;
reg num_incr1_3;


reg [DATA_WIDTH-1:0]rdata_reg;

//read addr&data channel begin--------------------------------------------------

always@(posedge clk,negedge rst_n) begin
  if(~rst_n) begin
    addr_src_reg<=0;
    data_len_reg<=0;
    num_incr16<=0;
    num_incr8<=0;
    num_incr4<=0;
    num_incr1_1<=0;
    num_incr1_2<=0;
    num_incr1_3<=0;
  end
  else if(mst_begin)begin
    addr_src_reg<=addr_src;
    data_len_reg<=data_len;
    num_incr16[9:0]<=data_len[15:6];
    num_incr8<=data_len[5];
    num_incr4<=data_len[4];
    num_incr1_1[1:0]<=data_len[3:2];
    num_incr1_2<=data_len[1];
    num_incr1_3<=data_len[0];
  end
end


assign araddr=addr_src_reg;                            //addr output
assign en_write=rvalid&&rready&&(arid==rid);            //the data read is available
assign read_data=rdata;                                      //output data



always@(posedge clk,negedge rst_n) begin
  if(~rst_n) begin
    
    len_reg<=0;
    arid<=0;
    arlen<=0;
    arsize<=0;
    arburst<=0;
    arlock<=0;
    arcache<=0;
    arprot<=0;

  end

  else if(arready&&arvalid) begin //the first addr send directly,next send should be after the addr before received.
    
    arid<=4'b0000;                                    //outstanding5 
    arburst<=2'b01;
    arlock<=2'b00;
    arcache<=4'b0000;
    arprot<=3'b000;

    if(num_incr16!=0)begin
      num_incr16<=num_incr16-1;
      arlen<=4'b1111;
      arsize<=3'b010;
      data_len_reg<=data_len_reg-64;
      len_reg<=7'd64;
      addr_src_reg<=addr_src_reg+len_reg;           //refresh the awddr output
    end
    else if(num_incr8!=0)begin
      num_incr8<=num_incr8-1;
      arlen<=4'b0111;
      arsize<=3'b010;
      data_len_reg<=data_len_reg-32;
      len_reg<=7'd32;
      addr_src_reg<=addr_src_reg+len_reg;  
    end
    else if(num_incr4!=0)begin
      num_incr4<=num_incr4-1;
      arlen<=4'b0011;
      arsize<=3'b010;
      data_len_reg<=data_len_reg-16;
      len_reg<=7'd16;
      addr_src_reg<=addr_src_reg+len_reg;  
    end
    else if(num_incr1_1!=0)begin 
      num_incr1_1<=num_incr1_1-1;
      arlen<=4'b0000;
      arsize<=3'b010;
      data_len_reg<=data_len_reg-4;      
      len_reg<=7'd4;
      addr_src_reg<=addr_src_reg+len_reg;  
    end
    else if(num_incr1_2!=0)begin
      num_incr1_2<=num_incr1_2-1;
      arlen<=4'b0000;
      arsize<=3'b001;
      data_len_reg<=data_len_reg-2;
      len_reg<=7'd2;
      addr_src_reg<=addr_src_reg+len_reg;  
    end
    else if(num_incr1_3!=0)begin
      num_incr1_3<=num_incr1_3-1;
      arlen<=4'b0000;
      arsize<=3'b000;
      data_len_reg<=data_len_reg-1;
      len_reg<=7'd1;
      addr_src_reg<=addr_src_reg+len_reg;
    end     
  end

end

assign arvalid=data_len_reg?((count<5)?1:0):0;


always@(posedge clk,negedge rst_n) begin                                    //count!!!!!!!!!
  if(~rst_n) 
    count<=0;
  else if(arvalid&&arready&&rlast&&rvalid&&rready)                          //count hold.
    count<=count;
  else if(arvalid&&arready)                                                 //one more addr was sent
    count<=count+1;
  else if(rlast&&rvalid&&rready)                                            //one more burst was written
    count<=count-1;
end



always@(posedge clk,negedge rst_n) begin
  if(~rst_n)
    rready<=1;
  else if(fifo_full)
    rready<=0;
  else
    rready<=1;
end


always@(posedge clk,negedge rst_n) begin                                   
  if(~rst_n)
   error<=0; 
  else if(rresp!=0)
   error<=1;
end 


//read addr&data channel end--------------------------------------------------

endmodule 
