/* //----------------------------------------------------------------------------------------------------------//
//Title: crc_cal;
//Author: lyl;
//Function: crc_cal.
//Version: 1. 20190515.Write this file.
                2.20190524, add fifo to read the data out. now, I can run this function in serial way.
                3.20190527, after check, all functions work well!!!
                4.20190527, add data_in_valid signal.
                5.20190527, change the module's name, let it be a submodule.
                6.20190610, add a input fifo, use rd_en_fifo1 to generate a data_in_valid signal, after test, I find it works well.
//Function: when time 0, first 1 bit data comes in, and some input signals tell me the data_length, crc_mode,
                work_mode. then it caculate the crc number. In work_mode_crc, it writes the data_in and crc to fifo, 
                and in a suitable time, it read the data out(but for convience, I use the clk_in as both input and 
                output fifo clock). In work_mode_chk, it output the chk_result signal.
//Some parameter:               
            ////crc_mode:
            // parameter crc_8bit_mode= 4'b00;
            // parameter crc_12bit_mode= 4'b01;
            // parameter crc_16bit_mode= 4'b10;
            // parameter crc_ccitt_16bit_mode= 4'b11;
            ////work_mode:
            // parameter work_mode_crc= 1'b0;
            // parameter work_mode_chk= 1'b1;
//---------------------------------------------------------------------------------------------------------// */

module crc_cal(
clk_in,
rstn_global,
complt_recived,
data_in,
data_length_reg,
crc_mode_reg,
work_mode_reg,
rd_empty_fifo1,
data_recived,
rd_en_fifo1,
chk_result,
crc_result,
process_complt
);

/* //crc_mode---------- */
parameter crc_8bit_mode= 2'b00;
parameter crc_12bit_mode= 2'b01;
parameter crc_16bit_mode= 2'b10;
parameter crc_ccitt_16bit_mode= 2'b11;
/* ////work_mode------------- */
parameter work_mode_crc= 1'b0;
parameter work_mode_chk= 1'b1;

//------------------------------------------------------------------------------------------------------//
//----------------------------input/output declarations-------------------------------------------//
//--------------------------------------------------------------------------------------------------//
input                   clk_in;                      //input 500mhz clk 
input                   rstn_global;              //global rstn 
input                   complt_recived;           //process restart, use as a reset.
input [31:0]         data_in;                     //32 bit data_in 
input [15:0]         data_length_reg;                //the valid data's length, 65536= 'h10000;
input [1:0]           crc_mode_reg;                 //crc8,12,16,16c. selected by 00,01,10,11
input                   work_mode_reg;              //crc or chk
input                   rd_empty_fifo1;           //200mHz fifo is empty
input                   data_recived;               //configdata will come.
output                 rd_en_fifo1;           //enable read data from 200mHz fifo 
output [1:0]         chk_result;                //01 is right, 10 is wrong. 00 is default
output [15:0]       crc_result;                  //the crc result
output                 process_complt;           //tell others that this module's process is complete.
  

//------------------------------------------------------------------------------------------------------//
//---------------------------------------------main code-------------------------------------------//
//--------------------------------------------------------------------------------------------------//
/* ////clk control------------- */
wire    clk_ctrl0;
wire    clk_ctrl1;

/* ////generate rstn, they can all enable reset----------- */
wire rstn;

/* ////if data_recived, then read config data.---------------- */
reg  [15:0]    data_length_8bit;
reg [14:0]    data_length_32bit;
reg               work_mode;
reg   [1:0]      crc_mode;

reg         process_begin;
reg         process_begin_d1;
reg         process_begin_d2;

/* //delay the data, prepare to split the data into 2 parts -------------------*/
reg [31:0] data_in_d1;

/* //generate a flip signal, use it to select which 16-bits data to use -------------------*/
reg data_select;

/* //select which 16-bits data to use-------------------*/
reg [15:0] data_using;
reg [15:0] data_using_d0;
reg [15:0] data_using_d1;


/* ////generate a rd_empty signal, and let the rd_empty signal to generate a valid signal ----------------*/
reg     rd_en_fifo1;
reg     data_in_valid_d0;       //parallel with data_in
reg     data_in_valid_d1;       //parallel with first data_using
reg     data_in_valid_d2;       //parallel with second data_using
reg     data_in_valid_3;       //parallel with second data_using
reg     data_in_valid/* synthesis keep */;         //data_in_valid is 1 when first and second data_using

/* ////crc calculate valid. */
reg    crc_cal_valid/* synthesis keep */;      //crc_cal_valid is 1 when not crc_complete and data_in_valid is 1

/* ////generate crc---- */
reg [15:0] crc_caling;         //the realtime crc_result. 

/* ////generate counter---- */
reg [14:0] data_count;    //65536= 'h10000;

/* ////Generate a cal_complete signal */
reg chk_complt;         //after data_length_32bit+1, 1
reg crc_complt;           //after data_length_32bit, 1
reg process_complt;     //after data_length_32bit+4, 1.


/* ////check crc. work_mode_chk---------  */
reg [1:0] chk_result;       //if right ,01; if wrong, 10.
reg [15:0] crc_chk_tmp;     //crc data in data_in

/* ////crc_result. make a final result---------- */
wire [15:0] crc_result/* synthesis keep */;     //crc_result from caculating the data_in



////---------------------------------------------------------------------------------------------------
/* ////clk control------------- */
assign clk_ctrl0= clk_in && ~process_begin_d2;
assign clk_ctrl1= clk_in && ~process_complt && process_begin_d2;

////generate rstn, they can all enable reset-----------
assign rstn= rstn_global && ~complt_recived;

/* ////if data_recived, then read config data.---------------- */   
always@(posedge clk_ctrl0 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        data_length_8bit<= 'b1;
        work_mode<= 'b0;
        crc_mode<= 'b0; 
        end
    else 
        begin
        if ( data_recived )
            begin
            data_length_8bit<= data_length_reg;
            work_mode<= work_mode_reg;
            crc_mode<= crc_mode_reg;
            end
        end
    end
    
    
always@(posedge clk_ctrl0 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        process_begin<= 'b0;
        end
    else 
        begin
        if ( data_recived )
            begin
            process_begin<= 'b1;
            end
        end
    end
 
always@(posedge clk_ctrl0 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        process_begin_d1<= 'b0;
        process_begin_d2<= 'b0;
        end
    else 
        begin
        process_begin_d1<= process_begin;
        process_begin_d2<= process_begin_d1;
        end
    end
    
always@(posedge clk_ctrl0 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        data_length_32bit<= 'b1;
        end
    else 
        begin
        if (data_length_8bit[1:0]==2'b00 )
            begin
            data_length_32bit<= data_length_8bit[15:2];
            end
        else
            begin
            data_length_32bit<= data_length_8bit[15:2]+'b1;
            end
        end
    end
    
        
/* //delay the data, prepare to split the data into 2 parts -------------------*/
always@(posedge clk_ctrl1 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        data_in_d1<= 'h0;
        end
    else 
        begin
        if ( data_select== 'b1)
            begin 
            data_in_d1<= data_in;
            end
        end
    end
    
    
/* //generate a flip signal, use it to select which 16-bits data to use -------------------*/
always@(posedge clk_ctrl1 or negedge rstn)
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
always@(posedge clk_ctrl1 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        data_using_d0<= 'h0;
        end
    else 
        begin
        case( data_length_8bit[1:0] )
        2'b11 :
            begin
            if ( ~data_select )
                begin
                data_using_d0<= { data_in_d1[7:0],data_in[31:24] };
                end
            else 
                begin
                data_using_d0<= data_in[23:8];
                end
            end
        2'b10 :
            begin
            if ( ~data_select )
                begin
                data_using_d0<= data_in_d1[15:0];
                end
            else 
                begin
                data_using_d0<= data_in[31:16];
                end
            end
        2'b01 :
            begin
            if ( ~data_select )
                begin
                data_using_d0<= data_in_d1[23:8] ;
                end
            else 
                begin
                data_using_d0<= { data_in_d1[7:0],data_in[31:24] };
                end
            end
        2'b00 :
            begin
            if ( ~data_select )
                begin
                data_using_d0<= data_in[31:16] ;
                end
            else 
                begin
                data_using_d0<= data_in[15:0];
                end
            end
        default :
            begin
                data_using_d0<= 'd0;
            end
        endcase
        end
    end
    
always@(posedge clk_ctrl1 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        data_using_d1<= 'b0;
        data_using<= 'b0;
        end
    else 
        begin
        data_using_d1<= data_using_d0;      //valid is delayed, so data_using need to be delay too.
        data_using<= data_using_d1;
        end
    end
    

    
/* ////generate a rd_empty signal, and let the rd_empty signal to generate a valid signal ----------------*/
always@(posedge clk_ctrl1 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        rd_en_fifo1<= 'd0;
        end
    else 
        begin
        if ( data_select== 'd0 )
            begin
            if ( rd_empty_fifo1 )
                begin
                rd_en_fifo1<= 'd0;
                end
            else
                begin
                rd_en_fifo1<= 'd1;
                end
            end
        else
            begin
            rd_en_fifo1<= 'd0;
            end
        end
    end
                
always@(posedge clk_ctrl1 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        data_in_valid_d0<= 'd0;    
        data_in_valid_d1<= 'd0;
        data_in_valid_d2<= 'd0;
        end
    else 
        begin
        data_in_valid_d0<= rd_en_fifo1;
        data_in_valid_d1<= data_in_valid_d0;
        data_in_valid_d2<= data_in_valid_d1;
        end
    end 
 
always@(posedge clk_ctrl1 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        data_in_valid_3<= 'd0;
        end
    else 
        begin
        if ( data_in_valid_d1 || data_in_valid_d2 )
            begin
            data_in_valid_3<= 'd1;
            end
        else
            begin
            data_in_valid_3<= 'd0;
            end
        end
    end
   
always@(posedge clk_ctrl1 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        data_in_valid<= 'd0;    
        end
    else 
        begin
        data_in_valid<= data_in_valid_3;
        end
    end 
    
/* ////crc calculate valid.-----------------------*/
always@(posedge clk_ctrl1 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        crc_cal_valid<= 'd0;
        end
    else 
        begin
        if ( data_count<data_length_32bit && data_in_valid_3 )
            begin
            crc_cal_valid<= 'd1;
            end
        else
            begin
            crc_cal_valid<= 'd0;
            end
        end
    end
    
 
/* ////generate crc---- */
always@(posedge clk_ctrl1 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        crc_caling<= 16'd0;
        end
    else 
        begin
        if ( crc_cal_valid )
            begin
            case( crc_mode )
            crc_8bit_mode:       
                begin
                crc_caling[7]<= crc_caling[0]^crc_caling[1]^crc_caling[2]^crc_caling[5]^crc_caling[6]^data_using[14]^data_using[13]
                                        ^data_using[10]^data_using[9]^data_using[8]^data_using[5]^data_using[3]^data_using[2];
                crc_caling[6]<= crc_caling[0]^crc_caling[1]^crc_caling[4]^crc_caling[5]^data_using[13]^data_using[12]^data_using[9]
                                        ^data_using[8]^data_using[7]^data_using[4]^data_using[2]^data_using[1];
                crc_caling[5]<= crc_caling[0]^crc_caling[3]^crc_caling[4]^crc_caling[7]^data_using[15]^data_using[12]^data_using[11]
                                        ^data_using[8]^data_using[7]^data_using[6]^data_using[3]^data_using[1]^data_using[0];
                crc_caling[4]<= crc_caling[0]^crc_caling[1]^crc_caling[3]^crc_caling[5]^data_using[13]^data_using[11]^data_using[9]
                                        ^data_using[8]^data_using[7]^data_using[6]^data_using[3]^data_using[0];
                crc_caling[3]<= crc_caling[1]^crc_caling[4]^crc_caling[5]^crc_caling[6]^data_using[14]^data_using[13]^data_using[12]
                                        ^data_using[9] ^data_using[7]^data_using[6]^data_using[3];
                crc_caling[2]<= crc_caling[0]^crc_caling[3]^crc_caling[4]^crc_caling[5]^data_using[13]^data_using[12]^data_using[11]
                                        ^data_using[8]^data_using[6]^data_using[5]^data_using[2];
                crc_caling[1]<= crc_caling[2]^crc_caling[3]^crc_caling[4]^crc_caling[7]^data_using[15]^data_using[12]^data_using[11]
                                        ^data_using[10] ^data_using[7]^data_using[5]^data_using[4]^data_using[1];
                crc_caling[0]<= crc_caling[1]^crc_caling[2]^crc_caling[3]^crc_caling[6]^crc_caling[7]^data_using[15]^data_using[14]
                                        ^data_using[11]^data_using[10]^data_using[9]^data_using[6]^data_using[4]^data_using[3]
                                        ^data_using[0];
                end
                
            crc_12bit_mode:           
                begin
                crc_caling[11]<= crc_caling[0]^crc_caling[1]^crc_caling[2]^crc_caling[3]^crc_caling[6]^crc_caling[7]^crc_caling[8]
                                ^crc_caling[9]^crc_caling[10]^crc_caling[11]^data_using[15]^data_using[14]^data_using[13]
                                ^data_using[12]^data_using[11]^data_using[10]^data_using[7]^data_using[6]^data_using[5]
                                ^data_using[4]^data_using[3]^data_using[2]^data_using[1]^data_using[0];
                crc_caling[10]<= crc_caling[3]^crc_caling[5]^data_using[9]^data_using[7];
                crc_caling[9]<= crc_caling[2]^crc_caling[4]^crc_caling[11]^data_using[15]^data_using[8]^data_using[6];
                crc_caling[8]<= crc_caling[1]^crc_caling[3]^crc_caling[10]^data_using[14]^data_using[7]^data_using[5];
                crc_caling[7]<= crc_caling[0]^crc_caling[2]^crc_caling[9]^data_using[13]^data_using[6]^data_using[4];
                crc_caling[6]<= crc_caling[1]^crc_caling[8]^data_using[12]^data_using[5]^data_using[3];
                crc_caling[5]<= crc_caling[0]^crc_caling[7]^crc_caling[11]^data_using[15]^data_using[11]^data_using[4]
                                        ^data_using[2];
                crc_caling[4]<= crc_caling[6]^crc_caling[10]^data_using[14]^data_using[10]^data_using[3]^data_using[1];
                crc_caling[3]<= crc_caling[5]^crc_caling[9]^data_using[13]^data_using[9]^data_using[2]^data_using[0];
                crc_caling[2]<= crc_caling[0]^crc_caling[1]^crc_caling[2]^crc_caling[3]^crc_caling[4]^crc_caling[6]^crc_caling[7]
                                        ^crc_caling[9]^crc_caling[10]^crc_caling[11]^data_using[15]^data_using[14]^data_using[13]
                                        ^data_using[11]^data_using[10]^data_using[8]^data_using[7]^data_using[6]^data_using[5]
                                        ^data_using[4]^data_using[3]^data_using[2]^data_using[0];
                crc_caling[1]<= crc_caling[5]^crc_caling[7]^data_using[11]^data_using[9]^data_using[0];
                crc_caling[0]<= crc_caling[0]^crc_caling[1]^crc_caling[2]^crc_caling[3]^crc_caling[4]^crc_caling[7]^crc_caling[8]
                                        ^crc_caling[9]^crc_caling[10]^crc_caling[11]^data_using[15]^data_using[13]^data_using[12]
                                        ^data_using[11]^data_using[8]^data_using[7]^data_using[6]^data_using[5]^data_using[4]
                                        ^data_using[3]^data_using[2]^data_using[1]^data_using[0]^data_using[14];
                end
                
            crc_16bit_mode:         
                 begin
                crc_caling[15]<= crc_caling[0]^crc_caling[1]^crc_caling[2]^crc_caling[3]^crc_caling[4]^crc_caling[5]^crc_caling[6]
                                        ^crc_caling[7]^crc_caling[8]^crc_caling[9]^crc_caling[10]^crc_caling[11]^crc_caling[12]^crc_caling[14]
                                        ^crc_caling[15]^data_using[15]^data_using[14]^data_using[12]^data_using[11]^data_using[10]
                                        ^data_using[9]^data_using[8]^data_using[7]^data_using[6]^data_using[5]^data_using[4]
                                        ^data_using[3]^data_using[2]^data_using[1]^data_using[0];
                crc_caling[14]<= crc_caling[12]^crc_caling[13]^data_using[13]^data_using[12];
                crc_caling[13]<= crc_caling[11]^crc_caling[12]^data_using[12]^data_using[11];
                crc_caling[12]<= crc_caling[10]^crc_caling[11]^data_using[11]^data_using[10];
                crc_caling[11]<= crc_caling[9]^crc_caling[10]^data_using[10]^data_using[9];
                crc_caling[10]<= crc_caling[8]^crc_caling[9]^data_using[9]^data_using[8];
                crc_caling[9]<= crc_caling[7]^crc_caling[8]^data_using[8]^data_using[7];
                crc_caling[8]<= crc_caling[6]^crc_caling[7]^data_using[7]^data_using[6];
                crc_caling[7]<= crc_caling[5]^crc_caling[6]^data_using[6]^data_using[5];
                crc_caling[6]<= crc_caling[4]^crc_caling[5]^data_using[5]^data_using[4];
                crc_caling[5]<= crc_caling[3]^crc_caling[4]^data_using[4]^data_using[3];
                crc_caling[4]<= crc_caling[2]^crc_caling[3]^data_using[3]^data_using[2];
                crc_caling[3]<= crc_caling[1]^crc_caling[2]^crc_caling[15]^data_using[15]^data_using[2]^data_using[1];
                crc_caling[2]<= crc_caling[0]^crc_caling[1]^crc_caling[14]^data_using[14]^data_using[1]^data_using[0];
                crc_caling[1]<= crc_caling[1]^crc_caling[2]^crc_caling[3]^crc_caling[4]^crc_caling[5]^crc_caling[6]^crc_caling[7]
                                        ^crc_caling[8]^crc_caling[9]^crc_caling[10]^crc_caling[11]^crc_caling[12]^crc_caling[13]
                                        ^crc_caling[14]^data_using[14]^data_using[13]^data_using[12]^data_using[11]^data_using[10]
                                        ^data_using[9]^data_using[8]^data_using[7]^data_using[6]^data_using[5]^data_using[4]
                                        ^data_using[3]^data_using[2]^data_using[1];
                crc_caling[0]<= crc_caling[0]^crc_caling[1]^crc_caling[2]^crc_caling[3]^crc_caling[4]^crc_caling[5]^crc_caling[6]
                                        ^crc_caling[7]^crc_caling[8]^crc_caling[9]^crc_caling[10]^crc_caling[11]^crc_caling[12]^crc_caling[13]
                                        ^crc_caling[15]^data_using[15]^data_using[13]^data_using[12]^data_using[11]^data_using[10]
                                        ^data_using[9]^data_using[8]^data_using[7]^data_using[6]^data_using[5]^data_using[4]
                                        ^data_using[3]^data_using[2]^data_using[1]^data_using[0];
                end
                
            crc_ccitt_16bit_mode:      
                begin
                crc_caling[15]<= crc_caling[3]^crc_caling[7]^crc_caling[10]^crc_caling[11]^data_using[11]
                                        ^data_using[10]^data_using[7]^data_using[3];
                crc_caling[14]<= crc_caling[2]^crc_caling[6]^crc_caling[9]^crc_caling[10]^data_using[10]
                                        ^data_using[9]^data_using[6]^data_using[2];
                crc_caling[13]<= crc_caling[1]^crc_caling[5]^crc_caling[8]^crc_caling[9]^data_using[9]
                                        ^data_using[8]^data_using[5]^data_using[1];
                crc_caling[12]<= crc_caling[0]^crc_caling[4]^crc_caling[7]^crc_caling[8]^crc_caling[15]
                                        ^data_using[15]^data_using[8]^data_using[7]^data_using[4]^data_using[0];
                crc_caling[11]<= crc_caling[6]^crc_caling[10]^crc_caling[11]^crc_caling[14]^crc_caling[15]
                                        ^data_using[15]^data_using[14]^data_using[11]^data_using[10]^data_using[6];
                crc_caling[10]<= crc_caling[5]^crc_caling[9]^crc_caling[10]^crc_caling[13]^crc_caling[14]
                                        ^data_using[14]^data_using[13]^data_using[10]^data_using[9]^data_using[5];
                crc_caling[9]<= crc_caling[4]^crc_caling[8]^crc_caling[9]^crc_caling[12]^crc_caling[13]
                                        ^crc_caling[15]^data_using[15]^data_using[13]^data_using[12]^data_using[9]^data_using[8]
                                        ^data_using[4];
                crc_caling[8]<= crc_caling[14]^crc_caling[3]^crc_caling[7]^crc_caling[8]^crc_caling[11]
                                        ^crc_caling[12]^crc_caling[15]^data_using[15]^data_using[14]^data_using[12]
                                        ^data_using[11]^data_using[8]^data_using[7]^data_using[3];
                crc_caling[7]<= crc_caling[2]^crc_caling[6]^crc_caling[7]^crc_caling[10]^crc_caling[11]
                                        ^crc_caling[13]^crc_caling[14]^crc_caling[15]^data_using[15]^data_using[14]
                                        ^data_using[13]^data_using[11]^data_using[10]^data_using[7]^data_using[6]^data_using[2];
                crc_caling[6]<= crc_caling[1]^crc_caling[5]^crc_caling[6]^crc_caling[9]^crc_caling[10]
                                        ^crc_caling[12]^crc_caling[13]^crc_caling[14]^data_using[14]^data_using[13]
                                        ^data_using[12]^data_using[10]^data_using[9]^data_using[6]^data_using[5]^data_using[1];
                crc_caling[5]<= crc_caling[0]^crc_caling[4]^crc_caling[5]^crc_caling[8]^crc_caling[9]
                                        ^crc_caling[11]^crc_caling[12]^crc_caling[13]^data_using[13]^data_using[12]^data_using[11]
                                        ^data_using[9]^data_using[8]^data_using[5]^data_using[4]^data_using[0];
                crc_caling[4]<= crc_caling[4]^crc_caling[8]^crc_caling[12]^crc_caling[15]^data_using[15]
                                        ^data_using[12]^data_using[8]^data_using[4];
                crc_caling[3]<= crc_caling[3]^crc_caling[7]^crc_caling[11]^crc_caling[14]^crc_caling[15]
                                        ^data_using[15]^data_using[14]^data_using[11]^data_using[7]^data_using[3];
                crc_caling[2]<= crc_caling[2]^crc_caling[6]^crc_caling[10]^crc_caling[13]^crc_caling[14]
                                        ^data_using[14]^data_using[13]^data_using[10]^data_using[6]^data_using[2];
                crc_caling[1]<= crc_caling[1]^crc_caling[5]^crc_caling[9]^crc_caling[12]^crc_caling[13]
                                        ^data_using[13]^data_using[12]^data_using[9]^data_using[5]^data_using[1];
                crc_caling[0]<= crc_caling[0]^crc_caling[4]^crc_caling[8]^crc_caling[11]^crc_caling[12]
                                        ^data_using[12]^data_using[11]^data_using[8]^data_using[4]^data_using[0];
                end
                
            default:
                begin
                crc_caling<= 16'd0;
                end   
            endcase
            end  
        end
    end

    
/* ////generate counter---- */
always@(posedge clk_ctrl1 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        data_count<= 'd0;
        end
    else 
        begin
        if (data_count== 'h7fff )
            begin
            data_count<= data_count;
            end
        else if ( work_mode== work_mode_crc )
            begin
            if ( (data_in_valid || crc_complt) && data_select=='b1 )
                begin
                data_count<= data_count+ 'd1;
                end
            end
        else if ( work_mode== work_mode_chk )
            begin
            if ( (data_in_valid || chk_complt) && data_select=='b1 )
                begin
                data_count<= data_count+ 'd1;
                end
            end
        end
    end
    

                                            
/* ////Generate a cal_complete signal */
always@(posedge clk_ctrl1 or negedge rstn)
    begin
    if ( ~rstn )
        begin
        chk_complt<= 'd0;
        crc_complt<= 'd0;
        process_complt<= 'd0;
        end
    else 
        begin
        if (data_count== data_length_32bit && data_select=='b0 )
            begin
            crc_complt<= 'd1;
            end
        else if (data_count== data_length_32bit+'d1 && data_select=='b0 )
            begin
            chk_complt<= 'd1;
            end
        else if (data_count== data_length_32bit+'d4 && data_select=='b0 )
            begin
            process_complt<= 'd1;
            end
        else
            begin
            crc_complt<= crc_complt;
            chk_complt<= chk_complt;
            process_complt<= process_complt;
            end
        end
    end
    
 

/* ////check crc. work_mode_chk---------  */
always@(posedge clk_ctrl1 or negedge rstn)
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
            if ( crc_complt==0 )  
                begin
                crc_chk_tmp<= 'd0;
                end
            else if ( crc_complt==1 && chk_complt==0 )    //crc_complt,1.chk_complt,0
                begin
                if ( data_select== 'b1 )
                    begin
                    crc_chk_tmp<= data_in[15:0];
                    end
                end
            else if ( chk_complt==1 )    
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
assign crc_result= crc_caling;

    
endmodule
