/* //----------------------------------------------------------------------------------------------------------//
//Title: crc_cal;
//Author: lyl;
//Function: crc_cal.
//Version: 1. 20190515.Write this file.
                2.20190524, add fifo to read the data out. now, I can run this function in serial way.
                3.20190527, after check, all functions work well!!!
                4.20190527, add data_in_valid signal.
                5.20190527, change the module's name, let it be a submodule.
//Function: when time 0, first 1 bit data comes in, and some input signals tell me the data_length, crc_mode,
                work_mode. then it caculate the crc number. In work_mode_crc, it writes the data_in and crc to fifo, 
                and in a suitable time, it read the data out(but for convience, I use the clk_in as both input and 
                output fifo clock). In work_mode_chk, it output the chk_result signal.
//---------------------------------------------------------------------------------------------------------// */

module crc_cal(

/* ////test addition, just for test---- */


/* //these are normal signals. ----------------*/
clk_in,
rstn,
data_in,
data_length,
crc_mode,
work_mode,
data_in_valid,
data_out,
chk_result,
crc_result
);

/* //crc_mode---------- */
parameter crc_8bit_mode= 4'b0001;
parameter crc_12bit_mode= 4'b0010;
parameter crc_16bit_mode= 4'b0100;
parameter crc_ccitt_16bit_mode= 4'b1000;
/* ////work_mode------------- */
parameter work_mode_crc= 1'b0;
parameter work_mode_chk= 1'b1;

//------------------------------------------------------------------------------------------------------//
//----------------------------input/output declarations-------------------------------------------//
//--------------------------------------------------------------------------------------------------//
input                   clk_in;                      //input 50mhz clk source
input                     rstn;                         //rstn
input [31:0]         data_in;                     //1 bit data_in 
input [19:0]         data_length;                //the valid data's length, 65536*8= 'h80000;
input [3:0]           crc_mode;                 //crc8,12,16,16. selected by 1,2,4,8
input                   work_mode;              //crc or chk
input                   data_in_valid;           //data_in is valid
output                data_out;                  //32 bit data_out
output                chk_result;                //01 is right, 10 is wrong. 00 is default
output                crc_result;                  //the crc result

//------------------------------------------------------------------------------------------------------//
//---------------------------------------------main code-------------------------------------------//
//--------------------------------------------------------------------------------------------------//
/* //delay the data, prepare to split the data into 2 parts -------------------*/
reg [31:0] data_in_d1;

/* //generate a flip signal, use it to select which 16-bits data to use -------------------*/
reg data_select;

/* //select which 16-bits data to use-------------------*/
reg [15:0] data_using;

/* ////assign the divider value---- */
wire [15: 0] div_num/* synthesis keep */;       //select which num to be xor, depend on crc_mode.
// reg [15: 0] div_num;

/* ////crc calculate valid. */
wire    crc_cal_valid/* synthesis keep */;
///////chk_result
/* ////generate crc---- */
reg [15:0] crc_8bit;         //div_num=0x31
reg [15:0] crc_12bit;       //div_num=0x80f
reg [15:0] crc_16bit;       //div_num=0x8005
reg [15:0] crc_ccitt_16bit;     //div_num=0x1021

/* ////generate counter---- */
reg [19:0] data_count;    //65536*8= 'h80000;

/* ////initail bit length---- */
// reg [5:0] initial_bitlength;
wire [5:0] initial_bitlength/* synthesis keep */;       //8, 12, 16, 16
// integer initial_bitlength;

/* ////Generate a cal_complete signal */
reg cal_complt;         //after data_length+initial_bitlength, 1
reg data_end;           //after data_length, 1

/* ////Data out1----     */
// reg [31:0]    data_out1;      //data to fifo. then read data from fifo to output.
// reg wr_en;          //write fifo enable

/* ////check crc. work_mode_chk---------  */
reg [1:0] chk_result;       //if right ,01; if wrong, 10.
reg [15:0] crc_chk_tmp;     //crc data in data_in

/* ////crc_result. make a final result---------- */
wire [15:0] crc_result/* synthesis keep */;     //crc_result from caculate the data_in

/* //read data from fifo-------     */
// reg rd_en;      //read data from fifo enable

/* ////fifo_0---- */
// wire wr_full; 
// wire rd_empty;
// wire [31:0]     data_out;      //output



////---------------------------------------------------------------------------------------------------

/* //delay the data, prepare to split the data into 2 parts -------------------*/
always@(posedge clk_in or negedge rstn)
    begin
    if ( ~rstn )
        begin
        data_in_d1<= 'h0;
        end
    else 
        begin
        data_in_d1<= data_in;
        end
    end
    
    
/* //generate a flip signal, use it to select which 16-bits data to use -------------------*/
always@(posedge clk_in or negedge rstn)
    begin
    if ( ~rstn )
        begin
        data_select<= 'b0;
        end
    else 
        begin
        data_select<= ~data_select;
        end
    end
    
    
/* //select which 16-bits data to use-------------------*/
always@(posedge clk_in or negedge rstn)
    begin
    if ( ~rstn )
        begin
        data_using<= 'h0;
        end
    else 
        begin
        if ( ~data_select )
            begin
            data_using<= data_in[31:16];
            end
        else 
            data_using<= data_in_d1[15:0];
        end
    end
    
    
/* ////assign the divider value---- */
// always@(posedge clk_in or negedge rstn)
    // begin
    // if ( ~rstn )
        // begin
        // div_num<= 16'h0;
        // end
    // else 
        // begin
        // if (crc_mode== crc_8bit_mode)
            // div_num<= 8'h31;
        // else if (crc_mode== crc_12bit_mode)
            // div_num<= 12'h80f;
        // else if (crc_mode== crc_16bit_mode)
            // div_num<= 16'h8005;
        // else if (crc_mode== crc_ccitt_16bit_mode)
            // div_num<= 16'h1021;
        // else
            // div_num<= 16'h0;
        // end
    // end        
assign div_num= (crc_mode== crc_8bit_mode)?16'h0031:
                                (crc_mode== crc_12bit_mode)?16'h080f:
                                    (crc_mode== crc_16bit_mode)?16'h8005:
                                        (crc_mode== crc_ccitt_16bit_mode)?16'h1021:
                                            16'h0;
 
 
/* ////crc calculate valid.because check mode need input extra data, so we should decide which time to caculate
        the crc depend on the work mode.*/
assign crc_cal_valid=  ~data_end && data_in_valid ;
// assign crc_cal_valid= (work_mode== work_mode_chk)? ( ~data_end && data_in_valid ):
                                        // ( ~cal_complt && (data_in_valid || data_end) );
 
 
/* ////generate crc---- */
always@(posedge clk_in or negedge rstn)
    begin
    if ( ~rstn )
        begin
        crc_8bit<= 8'd0;
        crc_12bit<= 12'd0;
        crc_16bit<= 16'd0;
        crc_ccitt_16bit<= 16'd0;
        end
    else 
        begin
        if ( crc_cal_valid )
            begin
            case( crc_mode )
            crc_8bit_mode:       //crc8. xor with 0x131 if xor first (or xor with 0x31 if shift first)
                begin
                crc_8bit[7]<= crc_8bit[0]^crc_8bit[1]^crc_8bit[2]^crc_8bit[5]^crc_8bit[6]^data_using[14]^data_using[13]
                                        ^data_using[10]^data_using[9]^data_using[8]^data_using[5]^data_using[3]^data_using[2];
                crc_8bit[6]<= crc_8bit[0]^crc_8bit[1]^crc_8bit[4]^crc_8bit[5]^data_using[13]^data_using[12]^data_using[9]
                                        ^data_using[8]^data_using[7]^data_using[4]^data_using[2]^data_using[1];
                crc_8bit[5]<= crc_8bit[0]^crc_8bit[3]^crc_8bit[4]^crc_8bit[7]^data_using[15]^data_using[12]^data_using[11]
                                        ^data_using[8]^data_using[7]^data_using[6]^data_using[3]^data_using[1]^data_using[0];
                crc_8bit[4]<= crc_8bit[0]^crc_8bit[1]^crc_8bit[3]^crc_8bit[5]^data_using[13]^data_using[11]^data_using[9]
                                        ^data_using[8]^data_using[7]^data_using[6]^data_using[3]^data_using[0];
                crc_8bit[3]<= crc_8bit[1]^crc_8bit[4]^crc_8bit[5]^crc_8bit[6]^data_using[14]^data_using[13]^data_using[12]
                                        ^data_using[9] ^data_using[7]^data_using[6]^data_using[3];
                crc_8bit[2]<= crc_8bit[0]^crc_8bit[3]^crc_8bit[4]^crc_8bit[5]^data_using[13]^data_using[12]^data_using[11]
                                        ^data_using[8]^data_using[6]^data_using[5]^data_using[2];
                crc_8bit[1]<= crc_8bit[2]^crc_8bit[3]^crc_8bit[4]^crc_8bit[7]^data_using[15]^data_using[12]^data_using[11]
                                        ^data_using[10] ^data_using[7]^data_using[5]^data_using[4]^data_using[1];
                crc_8bit[0]<= crc_8bit[1]^crc_8bit[2]^crc_8bit[3]^crc_8bit[6]^crc_8bit[7]^data_using[15]^data_using[14]
                                        ^data_using[11]^data_using[10]^data_using[9]^data_using[6]^data_using[4]^data_using[3]
                                        ^data_using[0];
                end
                
            crc_12bit_mode:             //crc12. xor with 0x180f if xor first (or xor with 0x80f if shifting first)
                begin
                crc_12bit[11]<= crc_12bit[0]^crc_12bit[1]^crc_12bit[2]^crc_12bit[3]^crc_12bit[6]^crc_12bit[7]^crc_12bit[8]
                                ^crc_12bit[9]^crc_12bit[10]^crc_12bit[11]^data_using[15]^data_using[14]^data_using[13]
                                ^data_using[12]^data_using[11]^data_using[10]^data_using[7]^data_using[6]^data_using[5]
                                ^data_using[4]^data_using[3]^data_using[2]^data_using[1]^data_using[0];
                crc_12bit[10]<= crc_12bit[3]^crc_12bit[5]^data_using[9]^data_using[7];
                crc_12bit[9]<= crc_12bit[2]^crc_12bit[4]^crc_12bit[11]^data_using[15]^data_using[8]^data_using[6];
                crc_12bit[8]<= crc_12bit[1]^crc_12bit[3]^crc_12bit[10]^data_using[14]^data_using[7]^data_using[5];
                crc_12bit[7]<= crc_12bit[0]^crc_12bit[2]^crc_12bit[9]^data_using[13]^data_using[6]^data_using[4];
                crc_12bit[6]<= crc_12bit[1]^crc_12bit[8]^data_using[12]^data_using[5]^data_using[3];
                crc_12bit[5]<= crc_12bit[0]^crc_12bit[7]^crc_12bit[11]^data_using[15]^data_using[11]^data_using[4]
                                        ^data_using[2];
                crc_12bit[4]<= crc_12bit[6]^crc_12bit[10]^data_using[14]^data_using[10]^data_using[3]^data_using[1];
                crc_12bit[3]<= crc_12bit[5]^crc_12bit[9]^data_using[13]^data_using[9]^data_using[2]^data_using[0];
                crc_12bit[2]<= crc_12bit[0]^crc_12bit[1]^crc_12bit[2]^crc_12bit[3]^crc_12bit[4]^crc_12bit[6]^crc_12bit[7]
                                        ^crc_12bit[9]^crc_12bit[10]^crc_12bit[11]^data_using[15]^data_using[14]^data_using[13]
                                        ^data_using[11]^data_using[10]^data_using[8]^data_using[7]^data_using[6]^data_using[5]
                                        ^data_using[4]^data_using[3]^data_using[2]^data_using[0];
                crc_12bit[1]<= crc_12bit[5]^crc_12bit[7]^data_using[11]^data_using[9]^data_using[0];
                crc_12bit[0]<= crc_12bit[0]^crc_12bit[1]^crc_12bit[2]^crc_12bit[3]^crc_12bit[4]^crc_12bit[7]^crc_12bit[8]
                                        ^crc_12bit[9]^crc_12bit[10]^crc_12bit[11]^data_using[15]^data_using[13]^data_using[12]
                                        ^data_using[11]^data_using[8]^data_using[7]^data_using[6]^data_using[5]^data_using[4]
                                        ^data_using[3]^data_using[2]^data_using[1]^data_using[0]^data_using[14];
                end
                
            crc_16bit_mode:         //crc16. xor with 0x18005 if xor first (or xor with 0x8005 if shifting first)
                 begin
                crc_16bit[15]<= crc_16bit[0]^crc_16bit[1]^crc_16bit[2]^crc_16bit[3]^crc_16bit[4]^crc_16bit[5]^crc_16bit[6]
                                        ^crc_16bit[7]^crc_16bit[8]^crc_16bit[9]^crc_16bit[10]^crc_16bit[11]^crc_16bit[12]^crc_16bit[14]
                                        ^crc_16bit[15]^data_using[15]^data_using[14]^data_using[12]^data_using[11]^data_using[10]
                                        ^data_using[9]^data_using[8]^data_using[7]^data_using[6]^data_using[5]^data_using[4]
                                        ^data_using[3]^data_using[2]^data_using[1]^data_using[0];
                crc_16bit[14]<= crc_16bit[12]^crc_16bit[13]^data_using[13]^data_using[12];
                crc_16bit[13]<= crc_16bit[11]^crc_16bit[12]^data_using[12]^data_using[11];
                crc_16bit[12]<= crc_16bit[10]^crc_16bit[11]^data_using[11]^data_using[10];
                crc_16bit[11]<= crc_16bit[9]^crc_16bit[10]^data_using[10]^data_using[9];
                crc_16bit[10]<= crc_16bit[8]^crc_16bit[9]^data_using[9]^data_using[8];
                crc_16bit[9]<= crc_16bit[7]^crc_16bit[8]^data_using[8]^data_using[7];
                crc_16bit[8]<= crc_16bit[6]^crc_16bit[7]^data_using[7]^data_using[6];
                crc_16bit[7]<= crc_16bit[5]^crc_16bit[6]^data_using[6]^data_using[5];
                crc_16bit[6]<= crc_16bit[4]^crc_16bit[5]^data_using[5]^data_using[4];
                crc_16bit[5]<= crc_16bit[3]^crc_16bit[4]^data_using[4]^data_using[3];
                crc_16bit[4]<= crc_16bit[2]^crc_16bit[3]^data_using[3]^data_using[2];
                crc_16bit[3]<= crc_16bit[1]^crc_16bit[2]^crc_16bit[15]^data_using[15]^data_using[2]^data_using[1];
                crc_16bit[2]<= crc_16bit[0]^crc_16bit[1]^crc_16bit[14]^data_using[14]^data_using[1]^data_using[0];
                crc_16bit[1]<= crc_16bit[1]^crc_16bit[2]^crc_16bit[3]^crc_16bit[4]^crc_16bit[5]^crc_16bit[6]^crc_16bit[7]
                                        ^crc_16bit[8]^crc_16bit[9]^crc_16bit[10]^crc_16bit[11]^crc_16bit[12]^crc_16bit[13]
                                        ^crc_16bit[14]^data_using[14]^data_using[13]^data_using[12]^data_using[11]^data_using[10]
                                        ^data_using[9]^data_using[8]^data_using[7]^data_using[6]^data_using[5]^data_using[4]
                                        ^data_using[3]^data_using[2]^data_using[1];
                crc_16bit[0]<= crc_16bit[0]^crc_16bit[1]^crc_16bit[2]^crc_16bit[3]^crc_16bit[4]^crc_16bit[5]^crc_16bit[6]
                                        ^crc_16bit[7]^crc_16bit[8]^crc_16bit[9]^crc_16bit[10]^crc_16bit[11]^crc_16bit[12]^crc_16bit[13]
                                        ^crc_16bit[15]^data_using[15]^data_using[13]^data_using[12]^data_using[11]^data_using[10]
                                        ^data_using[9]^data_using[8]^data_using[7]^data_using[6]^data_using[5]^data_using[4]
                                        ^data_using[3]^data_using[2]^data_using[1]^data_using[0];
                end
                
            crc_ccitt_16bit_mode:       //crc_ccitt_16. xor with 0x11021 if xor first (or xor with 0x1021 if shifting first)
                begin
                crc_ccitt_16bit[15]<= crc_ccitt_16bit[3]^crc_ccitt_16bit[7]^crc_ccitt_16bit[10]^crc_ccitt_16bit[11]^data_using[11]
                                        ^data_using[10]^data_using[7]^data_using[3];
                crc_ccitt_16bit[14]<= crc_ccitt_16bit[2]^crc_ccitt_16bit[6]^crc_ccitt_16bit[9]^crc_ccitt_16bit[10]^data_using[10]
                                        ^data_using[9]^data_using[6]^data_using[2];
                crc_ccitt_16bit[13]<= crc_ccitt_16bit[1]^crc_ccitt_16bit[5]^crc_ccitt_16bit[8]^crc_ccitt_16bit[9]^data_using[9]
                                        ^data_using[8]^data_using[5]^data_using[1];
                crc_ccitt_16bit[12]<= crc_ccitt_16bit[0]^crc_ccitt_16bit[4]^crc_ccitt_16bit[7]^crc_ccitt_16bit[8]^crc_ccitt_16bit[15]
                                        ^data_using[15]^data_using[8]^data_using[7]^data_using[4]^data_using[0];
                crc_ccitt_16bit[11]<= crc_ccitt_16bit[6]^crc_ccitt_16bit[10]^crc_ccitt_16bit[11]^crc_ccitt_16bit[14]^crc_ccitt_16bit[15]
                                        ^data_using[15]^data_using[14]^data_using[11]^data_using[10]^data_using[6];
                crc_ccitt_16bit[10]<= crc_ccitt_16bit[5]^crc_ccitt_16bit[9]^crc_ccitt_16bit[10]^crc_ccitt_16bit[13]^crc_ccitt_16bit[14]
                                        ^data_using[14]^data_using[13]^data_using[10]^data_using[9]^data_using[5];
                crc_ccitt_16bit[9]<= crc_ccitt_16bit[4]^crc_ccitt_16bit[8]^crc_ccitt_16bit[9]^crc_ccitt_16bit[12]^crc_ccitt_16bit[13]
                                        ^crc_ccitt_16bit[15]^data_using[15]^data_using[13]^data_using[12]^data_using[9]^data_using[8]
                                        ^data_using[4];
                crc_ccitt_16bit[8]<= crc_ccitt_16bit[14]^crc_ccitt_16bit[3]^crc_ccitt_16bit[7]^crc_ccitt_16bit[8]^crc_ccitt_16bit[11]
                                        ^crc_ccitt_16bit[12]^crc_ccitt_16bit[15]^data_using[15]^data_using[14]^data_using[12]
                                        ^data_using[11]^data_using[8]^data_using[7]^data_using[3];
                crc_ccitt_16bit[7]<= crc_ccitt_16bit[2]^crc_ccitt_16bit[6]^crc_ccitt_16bit[7]^crc_ccitt_16bit[10]^crc_ccitt_16bit[11]
                                        ^crc_ccitt_16bit[13]^crc_ccitt_16bit[14]^crc_ccitt_16bit[15]^data_using[15]^data_using[14]
                                        ^data_using[13]^data_using[11]^data_using[10]^data_using[7]^data_using[6]^data_using[2];
                crc_ccitt_16bit[6]<= crc_ccitt_16bit[1]^crc_ccitt_16bit[5]^crc_ccitt_16bit[6]^crc_ccitt_16bit[9]^crc_ccitt_16bit[10]
                                        ^crc_ccitt_16bit[12]^crc_ccitt_16bit[13]^crc_ccitt_16bit[14]^data_using[14]^data_using[13]
                                        ^data_using[12]^data_using[10]^data_using[9]^data_using[6]^data_using[5]^data_using[1];
                crc_ccitt_16bit[5]<= crc_ccitt_16bit[0]^crc_ccitt_16bit[4]^crc_ccitt_16bit[5]^crc_ccitt_16bit[8]^crc_ccitt_16bit[9]
                                        ^crc_ccitt_16bit[11]^crc_ccitt_16bit[12]^crc_ccitt_16bit[13]^data_using[12]^data_using[11]
                                        ^data_using[9]^data_using[8]^data_using[5]^data_using[4]^data_using[0];
                crc_ccitt_16bit[4]<= crc_ccitt_16bit[4]^crc_ccitt_16bit[8]^crc_ccitt_16bit[12]^crc_ccitt_16bit[15]^data_using[15]
                                        ^data_using[12]^data_using[8]^data_using[4];
                crc_ccitt_16bit[3]<= crc_ccitt_16bit[3]^crc_ccitt_16bit[7]^crc_ccitt_16bit[11]^crc_ccitt_16bit[14]^crc_ccitt_16bit[15]
                                        ^data_using[15]^data_using[14]^data_using[11]^data_using[7]^data_using[3];
                crc_ccitt_16bit[2]<= crc_ccitt_16bit[2]^crc_ccitt_16bit[6]^crc_ccitt_16bit[10]^crc_ccitt_16bit[13]^crc_ccitt_16bit[14]
                                        ^data_using[14]^data_using[13]^data_using[10]^data_using[6]^data_using[2];
                crc_ccitt_16bit[1]<= crc_ccitt_16bit[1]^crc_ccitt_16bit[5]^crc_ccitt_16bit[9]^crc_ccitt_16bit[12]^crc_ccitt_16bit[13]
                                        ^data_using[13]^data_using[12]^data_using[9]^data_using[5]^data_using[1];
                crc_ccitt_16bit[0]<= crc_ccitt_16bit[0]^crc_ccitt_16bit[4]^crc_ccitt_16bit[8]^crc_ccitt_16bit[11]^crc_ccitt_16bit[12]
                                        ^data_using[12]^data_using[11]^data_using[8]^data_using[4]^data_using[0];
                end
                
            default:
                begin
                crc_8bit<= 8'd0;
                crc_12bit<= 12'd0;
                crc_16bit<= 16'd0;
                crc_ccitt_16bit<= 16'd0;
                end   
            endcase
            end  
        end
    end

    
/* ////generate counter---- */
always@(posedge clk_in or negedge rstn)
    begin
    if ( ~rstn )
        begin
        data_count<= 'd0;
        end
    else 
        begin
        // if (data_count== data_length+2*initial_bitlength+'d6 )
        if (data_count== 'h1ffff )
            begin
            data_count<= data_count;
            end
        else if ( work_mode== work_mode_crc )
            begin
            if ( (data_in_valid || data_end) && data_select=='b1 )
                begin
                data_count<= data_count+ 'd1;
                end
            end
        else if ( work_mode== work_mode_chk )
            begin
            if ( (data_in_valid || cal_complt) && data_select=='b1 )
                begin
                data_count<= data_count+ 'd1;
                end
            end
        end
    end
    

    
/* ////initail bit length---- */
// always@(posedge clk_in or negedge rstn)
    // begin
    // if ( ~rstn )
        // begin
        // initial_bitlength<= 'd0;
        // end
    // else 
        // begin
        // if (crc_mode== crc_8bit_mode)
            // begin
            // initial_bitlength<= 'd8;
            // end
        // else if (crc_mode== crc_12bit_mode)
            // begin
            // initial_bitlength<= 'd12;
            // end
        // else if (crc_mode== crc_16bit_mode)
            // begin
            // initial_bitlength<= 'd16;
            // end
        // else if (crc_mode== crc_ccitt_16bit_mode)
            // begin
            // initial_bitlength<= 'd16;
            // end
        // else
            // begin
            // initial_bitlength<= 'd8;
            // end
        // end
    // end
assign initial_bitlength= (crc_mode== crc_8bit_mode)?5'd8:
                                        (crc_mode== crc_12bit_mode)?5'd12:
                                            (crc_mode== crc_16bit_mode)?5'd16:
                                                (crc_mode== crc_ccitt_16bit_mode)?5'd16:
                                                    5'd0;    

                                            
/* ////Generate a cal_complete signal */
always@(posedge clk_in or negedge rstn)
    begin
    if ( ~rstn )
        begin
        cal_complt<= 'd0;
        data_end<= 'd0;
        end
    else 
        begin
        if (data_count== data_length && data_select=='b0 )
        // if (data_count== data_length)
            begin
            data_end<= 'd1;
            end
        else if (data_count== data_length+'d1 && data_select=='b0 )
        // else if (data_count== initial_bitlength+ data_length)
            begin
            cal_complt<= 'd1;
            end
        else
            begin
            data_end<= data_end;
            cal_complt<= cal_complt;
            end
        end
    end
    
    
    
/* ////Data out1, work_mode_crc ----    
always@(posedge clk_in or negedge rstn)
    begin
    if ( ~rstn )
        begin
        data_out1<= 'd0;
        wr_en<= 'd0;
        end
    else 
        begin    
        if( work_mode== work_mode_crc )
            begin
            if ( data_count<data_length)
                begin
                if ( data_in_valid && data_select=='b1)
                    begin
                    wr_en<= 'b1;
                    data_out1<= data_in;
                    end
                else
                    begin
                    wr_en<= 'b0;
                    data_out1<= data_in;
                    end
                end
            else if ( data_count==data_length && data_select=='b1 )
                begin
                wr_en<= 'b1;
                data_out1<= crc_result;
                end
            else 
                begin
                wr_en<= 'b0;
                data_out1<= 'b0;
                end
            end
        end
    end */
 

/* ////check crc. work_mode_chk---------  */
always@(posedge clk_in or negedge rstn)
    begin
    if ( ~rstn )
        begin          
        crc_chk_tmp<= 'd0;
        chk_result<= 'd0;
        end
    else 
        begin    
        if( work_mode== work_mode_chk )
            begin
            if ( data_count< data_length )  //data_end==0
                begin
                crc_chk_tmp<= 'd0;
                end
            else if ( data_count== data_length )    //data_end,1.cal_complt,0
                begin
                if ( data_select== 'b1 )
                    begin
                    crc_chk_tmp<= data_in[15:0];
                    end
                end
            else if ( data_count>= data_length+'d1 )    //cal_complt==1
                begin
                if (crc_chk_tmp== crc_result)
                    begin
                    chk_result<= 'b01;
                    end
                else
                    begin
                    chk_result<= 'b10;
                    end
                end
            end
        end
    end
    

/* ////crc_result. make a final result---------- */
assign crc_result= (crc_mode== crc_8bit_mode)? crc_8bit:
                                (crc_mode== crc_12bit_mode)? crc_12bit:
                                    (crc_mode== crc_16bit_mode)?crc_16bit:
                                        (crc_mode== crc_ccitt_16bit_mode)?crc_ccitt_16bit:
                                            16'h0;

/* //read data from fifo-------     */
/* always@(posedge clk_in or negedge rstn)
    begin
    if ( ~rstn )
        begin
        rd_en<= 'd0;
        end
    else 
        begin    
        if( work_mode== work_mode_crc && data_select=='b1 )
            begin
            if ( rd_empty)
                begin
                rd_en<= 'b0;
                end
            else if ( data_count== 'd7)
            // else if ( data_count>= initial_bitlength+ 'd14)
                begin
                rd_en<= 'd1;
                end
            else if (data_count==data_length+ 'd8)
            // else if (data_count>=3*data_length+4*initial_bitlength+ 'd14)
                begin
                rd_en<= 'd0;
                end
            end
        end
    end
     */
                
/* ////fifo,write data to fifo,to wait the crc sequence.                 */
/* fifo_0	fifo_0_inst (
	.aclr ( ~rstn ),
	.data ( data_out1 ),
	.rdclk ( clk_in ),
	.rdreq ( rd_en ),
	.wrclk ( clk_in ),
	.wrreq ( wr_en ),
	.q ( data_out ),
	.rdempty ( rd_empty ),
	.wrfull ( wr_full )
	);
             */
    
endmodule
