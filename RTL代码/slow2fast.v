/***********************************************
#
#      Filename: slow2fast.v
#
#        Author: lixiaofei
#   Description: control signal transfer from slow clk region  synced to fast clk region
#        Create: 2019-06-03 15:36:57
#     Copyright: 302-2 Studio
***********************************************/

module slow2fast(
  output     o_sgl,            //output to fast clk region
 
  input      i_sgl,            //input from slow clk region

  input      f_clk,
  input      frst_n
);

reg          sgl_reg1;
reg          sgl_reg2;
reg          sgl_reg3;

assign o_sgl=sgl_reg2&(~sgl_reg3);

always@(posedge f_clk,negedge frst_n) begin
  if(~frst_n) begin
    sgl_reg1<=0;
    sgl_reg2<=0;
    sgl_reg3<=0;
  end
  else begin
    sgl_reg1<=i_sgl;
    sgl_reg2<=sgl_reg1;
    sgl_reg3<=sgl_reg2;
  end
end

endmodule
