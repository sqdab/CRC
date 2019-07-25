/***********************************************
#
#      Filename: AXI3_mst_write.v
#
#        Author: lixiaofei
#   Description: AXI master, write module.
#        Create: 2019-05-24 21:50:31
#     Copyright: 302-2 Studio
***********************************************/
module AXI3_mst_write #(
parameter ADDR_WIDTH=32,
           DATA_WIDTH=32          
)
(
input           clk,
                rst_n,

input           [ADDR_WIDTH-1:0]addr_dst,   //destination addr
input           [15:0]data_len,              //length of data
input           [2:0]crc_mode,               //[1:0]:crc_8,crc_12,_crc_16,crc_ccitt   [2]:verification,operation 
input           mst_begin,                   //slv has received the configdata.  this signal is already synced.



input           en_data_crc,                 //crc_data is ready     is already synced 

input           fifo_empty,                  //sync-fifo is empty,stop read
input           [DATA_WIDTH-1:0]fifo_in,      //the data from sync-fifo, output to the destination
input           [15:0]crc_data,              //crc result

output          en_read,                     //enable the sync-fifo to read
output reg      error,                 //the memory response bad. for intr!!!!

output reg      data_written,           //the operation result has been written
  
// write addr channel

input           awready,

output reg      [3:0]awid,
output          [ADDR_WIDTH-1:0]awaddr,
output reg      [3:0]awlen,
output reg      [2:0]awsize,
output reg      [1:0]awburst,
output reg      [1:0]awlock,
output reg      [3:0]awcache,
output reg      [2:0]awprot,  
output          awvalid,

// write data channel

input           wready,

output reg      [3:0]wid,
output          [DATA_WIDTH-1:0]wdata,
output reg      [3:0]wstrb,
output reg      wlast,
output reg      wvalid,

// write response channel

input           [3:0]bid,
input           [1:0]bresp,
input           bvalid,

output          bready

);

reg write_time;
reg [2:0]count;
reg [6:0]len_reg;


reg [ADDR_WIDTH-1:0]addr_dst_reg;
reg [15:0]data_len_reg;
reg [9:0]num_incr16;
reg num_incr8;
reg num_incr4;
reg [1:0]num_incr1_1;
reg num_incr1_2;
reg num_incr1_3;

reg [9:0]num_last_incr16;
reg num_last_incr8;
reg num_last_incr4;
reg [1:0]num_last_incr1_1;
reg num_last_incr1_2;
reg num_last_incr1_3;


wire en_wvalid;
reg [2:0]crc_mode_reg;



reg en_data_crc_reg;

reg   send_data_crc;
reg   [3:0]data_sent;                               //count the beat write in a burst

//write addr&data channel begin--------------------------------------------------

always@(posedge clk,negedge rst_n)
  if(~rst_n)
    data_written<=0;
  else if(mst_begin)
    data_written<=0;
  else if(send_data_crc)
    data_written<=1;



always@(posedge clk,negedge rst_n) begin
  if(~rst_n) begin
    addr_dst_reg<=0;
    data_len_reg<=0;
    crc_mode_reg<=0;
    num_incr16<=0;
    num_incr8<=0;
    num_incr4<=0;
    num_incr1_1<=0;
    num_incr1_2<=0;
    num_incr1_3<=0;
   
    num_last_incr16<=0;
    num_last_incr8<=0;
    num_last_incr4<=0;
    num_last_incr1_1<=0;
    num_last_incr1_2<=0;
    num_last_incr1_3<=0;
  end
  else if(mst_begin)begin
    addr_dst_reg<=addr_dst;
    data_len_reg<=data_len;
    crc_mode_reg<=crc_mode;
    num_incr16[9:0]<=data_len[15:6];
    num_incr8<=data_len[5];
    num_incr4<=data_len[4];
    num_incr1_1[1:0]<=data_len[3:2];
    num_incr1_2<=data_len[1];
    num_incr1_3<=data_len[0];
   
    num_last_incr16[9:0]<=data_len[15:6];
    num_last_incr8<=data_len[5];
    num_last_incr4<=data_len[4];
    num_last_incr1_1[1:0]<=data_len[3:2];
    num_last_incr1_2<=data_len[1];
    num_last_incr1_3<=data_len[0];

  end
end


assign awaddr=addr_dst_reg;                            //addr output                       
assign wdata=en_data_crc ?{crc_data,16'b0}:fifo_in;                                  //data output   

always@(posedge clk,negedge rst_n) begin
  if(~rst_n) begin
    write_time<=0;
    len_reg<=0;
    awid<=0;
    wid<=0;
    awlen<=0;
    awsize<=0;
    awburst<=0;
    awlock<=0;
    awcache<=0;
    awprot<=0;

  end

  else if((awready&&awvalid)||(en_data_crc)) begin //the first addr send directly,next send should be after the addr before received.
    write_time<=1;
    awid<=4'b0000;                                    //outstanding5 
    awburst<=2'b01;
    awlock<=2'b00;
    awcache<=4'b0000;
    awprot<=3'b000;

    if(num_incr16!=0)begin
      num_incr16<=num_incr16-1;
      awlen<=4'b1111;
      awsize<=3'b010;
      data_len_reg<=data_len_reg-64;
      len_reg<=7'd64;
      addr_dst_reg<=addr_dst_reg+len_reg;           //refresh the awddr output
    end
    else if(num_incr8!=0)begin
      num_incr8<=num_incr8-1;
      awlen<=4'b0111;
      awsize<=3'b010;
      data_len_reg<=data_len_reg-32;      
      len_reg<=7'd32;
      addr_dst_reg<=addr_dst_reg+len_reg;  
    end
    else if(num_incr4!=0)begin
      num_incr4<=num_incr4-1;
      awlen<=4'b0011;
      awsize<=3'b010;
      data_len_reg<=data_len_reg-16;      
      len_reg<=7'd16;
      addr_dst_reg<=addr_dst_reg+len_reg;  
    end
    else if(num_incr1_1!=0)begin 
      num_incr1_1<=num_incr1_1-1;
      awlen<=4'b0000;
      awsize<=3'b010;
      data_len_reg<=data_len_reg-4;  
      len_reg<=7'd4;
      addr_dst_reg<=addr_dst_reg+len_reg;  
    end
    else if(num_incr1_2!=0)begin
      num_incr1_2<=num_incr1_2-1;
      awlen<=4'b0000;
      awsize<=3'b001;
      data_len_reg<=data_len_reg-2;  
      len_reg<=7'd2;
      addr_dst_reg<=addr_dst_reg+len_reg;  
    end
    else if(num_incr1_3!=0)begin
      num_incr1_3<=num_incr1_3-1;
      awlen<=4'b0000;
      awsize<=3'b000;
      data_len_reg<=data_len_reg-1;  
      len_reg<=7'd1;
      addr_dst_reg<=addr_dst_reg+len_reg;
    end
    else if(en_data_crc)begin
      awlen<=4'b0000;
      awsize<=3'b001;
    end
    else
      write_time<=0;
  end

end

always@(posedge clk,negedge rst_n)
  if(~rst_n)begin
    en_data_crc_reg<=0;
  end
  else if(en_data_crc_reg&&awready)begin
    en_data_crc_reg<=0;
  end
  else
    en_data_crc_reg<=en_data_crc;

always@(posedge clk,negedge rst_n)
  if(~rst_n)begin
    send_data_crc<=0;
  end
  else if(en_data_crc_reg&&awready)begin
    send_data_crc<=1;
  end
  else if(send_data_crc&&wvalid&&wready)
    send_data_crc<=0;





assign awvalid=(data_len_reg?((count<5)?1:0):0)||(en_data_crc_reg);


assign en_read=((awvalid&&awready&&count==0)||(wvalid&&wready&&count>0))&&(~(send_data_crc||en_data_crc_reg));   //when to try read from sync-fifo, keep low when write crc data3 
assign en_wvalid=((awvalid&&awready&&count==0)||(wready&&count>0))&&(~fifo_empty);

always@(posedge clk,negedge rst_n) begin                        //wvalid   
  if(~rst_n)begin
    wvalid<=0;
  end
  else if(send_data_crc&&wready&&wvalid)
  wvalid<=0;
  else if(en_wvalid||send_data_crc)begin
    wvalid<=1;
  end

  else if(fifo_empty||~count) begin                          
    wvalid<=0;
  end  
end

always@(posedge clk,negedge rst_n)begin
  if(~rst_n)
    data_sent<=0;
  else if(wlast&&wvalid&&wready)
    data_sent<=0;
  else if(wvalid&&wready)
    data_sent<=data_sent+1;
end


always@(posedge clk,negedge rst_n) begin                                    //wlast
  if(~rst_n) begin
    wlast<=0;
  end
  else if(num_last_incr16!=0&&data_sent==15&&en_read&&(~fifo_empty))begin
    num_last_incr16<=num_last_incr16-1;
    wlast<=1;
  end
  else if(num_last_incr16==0&&num_last_incr8!=0&&data_sent==7&&en_read&&(~fifo_empty))begin
    num_last_incr8<=num_last_incr8-1;    
    wlast<=1;
  end
  else if(num_last_incr16==0&&num_last_incr8==0&&num_last_incr4!=0&&data_sent==3&&en_read&&(~fifo_empty))begin
    num_last_incr4<=num_last_incr4-1;
    wlast<=1;
  end
  else if(num_last_incr16==0&&num_last_incr8==0&&num_last_incr4==0&&num_last_incr1_1!=0&&data_sent==0&&en_read&&(~fifo_empty))begin
    num_last_incr1_1<=num_last_incr1_1-1;
    wlast<=1;
  end
  else if(num_last_incr16==0&&num_last_incr8==0&&num_last_incr4==0&&num_last_incr1_1==0&&num_last_incr1_2!=0&&data_sent==0&&en_read&&(~fifo_empty))begin
    num_last_incr1_2<=num_last_incr1_2-1;
    wlast<=1;
  end
  else if(num_last_incr16==0&&num_last_incr8==0&&num_last_incr4==0&&num_last_incr1_1==0&&num_last_incr1_2==0&&num_last_incr1_3!=0&&data_sent==0&&en_read&&(~fifo_empty))begin
    num_last_incr1_3<=num_last_incr1_3-1;
    wlast<=1;
  end
  else if(en_data_crc_reg)
    wlast<=1;
  else if(wlast&&wvalid&&wready)
    wlast<=0;
end


always@(posedge clk,negedge rst_n) begin                                    //wstrb
  if(~rst_n) begin
    wstrb<=0;
  end
  else if((~write_time)&&(num_last_incr16||num_last_incr8||num_last_incr4||num_last_incr1_1)) //the wstrb of first burst
    wstrb<=4'b1111;
  else if((~write_time)&&(num_last_incr1_2))
    wstrb<=4'b0011;
  else if((~write_time)&&(num_last_incr1_3))
    wstrb<=4'b0001;
  else if(wlast&&wvalid&&wready&&(num_last_incr16||num_last_incr8||num_last_incr4||num_last_incr1_1))  //change wstrb after last beat
    wstrb<=4'b1111;
  else if(wlast&&wvalid&&wready&&(num_last_incr1_2))         //change wstrb after last beat
    wstrb<=4'b0011;
  else if(wlast&&wvalid&&wready&&(num_last_incr1_3))         //change wstrb after last beat
    wstrb<=4'b0001;
  else if(en_data_crc_reg&&(crc_mode_reg==2'b00))
    wstrb<=4'b0001;
  else if(en_data_crc_reg)
    wstrb<=4'b0011;
  else 
    wstrb<=wstrb;
end

//how to deal with count?

always@(posedge clk,negedge rst_n) begin                                    //count!!!!!!!!!
  if(~rst_n) 
    count<=0;
  else if(awvalid&&awready&&wlast&&wvalid&&wready)                          //count hold.
    count<=count;
  else if(awvalid&&awready)                                                 //one more addr was sent
    count<=count+1;
  else if(wlast&&wvalid&&wready)                                            //one more burst was written
    count<=count-1;
end


//error report
assign bready=1;

always@(posedge clk,negedge rst_n) begin                                   
  if(~rst_n)
   error<=0; 
  else if(bvalid)
   error<=(|bresp);
end

endmodule

