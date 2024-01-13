`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/12 22:02:28
// Design Name: 
// Module Name: Data_2to1_arbiter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Data_2to1_arbiter(
    input           i_clk               ,
    input           i_rst               ,

    input  [7 :0]   i_data_a            ,
    input           i_valid_a           ,
    input           i_last_a            ,
    input  [15:0]   i_len_a             ,
    input  [15:0]   i_type_a            ,

    input  [7 :0]   i_data_b            ,
    input           i_valid_b           ,
    input           i_last_b            ,
    input  [15:0]   i_len_b             ,
    input  [15:0]   i_type_b            ,
    output          o_nxt_frame_stop    ,

    output [7 :0]   o_data              ,
    output          o_valid             ,
    output          o_last              ,
    output [15:0]   o_len               ,
    output [15:0]   o_type               
);
/******************************function***************************/

/******************************parameter**************************/

/******************************port*******************************/

/******************************machine****************************/

/******************************reg********************************/
reg  [7 :0]     ri_data_a       ;
reg             ri_valid_a      ;
reg             ri_valid_a_1d   ;
reg             ri_last_a       ;
reg  [15:0]     ri_len_a        ;
reg  [15:0]     ri_type_a       ;
reg  [7 :0]     ri_data_b       ;
reg             ri_valid_b      ;
reg             ri_valid_b_1d   ;
reg             ri_last_b       ;
reg  [15:0]     ri_len_b        ;
reg  [15:0]     ri_type_b       ;

reg             ro_valid        ;
reg             ro_last         ;
reg  [7 :0]     ro_data         ;
reg  [15:0]     ro_len          ;
reg  [15:0]     ro_type         ;
reg             ro_nxt_frame_stop   ;
//fifo ctrl port
reg             r_fifo_rden_a   ;
reg             r_fifo_rden_b   ;
reg             r_fifo_rden_a_1d;
reg             r_fifo_rden_b_1d;
//reg             r_fifo_rd       ;
reg  [15:0]     r_fifo_rd_cnt   ;
reg             r_rden_1d       ;
reg  [1 :0]     r_fifo_rden     ;
reg             r_fifo_rden_a_pos_1d;
reg             r_fifo_rden_b_pos_1d;
//arb
reg  [1 :0]     r_arbiter       ;
/******************************wire*******************************/
wire [7 :0]     w_fifo_douta    ;
wire            w_fifo_fulla    ;
wire            w_fifo_emptya   ;
wire [7 :0]     w_fifo_doutb    ;
wire            w_fifo_fullb    ;
wire            w_fifo_emptyb   ;
wire            w_rd_en         ;
wire            w_valid_a_pos   ;
wire            w_valid_b_pos   ;
wire [31:0]     w_fifo_douta_type_len   ;
wire [31:0]     w_fifo_doutb_type_len   ;
wire            w_fifo_rden_a_pos       ;
wire            w_fifo_rden_b_pos       ;
/******************************component**************************/
//a端口为arp，具有较高的优先级，b端口为ip，次优先级
FIFO_8x256 FIFO_8x256_port_a (
  .clk      (i_clk          ),   
  .din      (ri_data_a      ),   
  .wr_en    (ri_valid_a     ), 
  .rd_en    (r_fifo_rden_a  ), 
  .dout     (w_fifo_douta   ),  
  .full     (w_fifo_fulla   ),  
  .empty    (w_fifo_emptya  )  
);

FIFO_32x16 FIFO_32x16_port_a (
  .clk      (i_clk                  ), 
  .din      ({ri_type_a,ri_len_a}   ), 
  .wr_en    (w_valid_a_pos          ), 
  .rd_en    (w_fifo_rden_a_pos      ), 
  .dout     (w_fifo_douta_type_len  ), 
  .full     (), 
  .empty    ()  
);

FIFO_8x256 FIFO_8x256_port_b (
  .clk      (i_clk          ),   
  .din      (ri_data_b      ),   
  .wr_en    (ri_valid_b     ), 
  .rd_en    (r_fifo_rden_b  ), 
  .dout     (w_fifo_doutb   ),  
  .full     (w_fifo_fullb   ),  
  .empty    (w_fifo_emptyb  )  
);

FIFO_32x16 FIFO_32x16_port_b (
  .clk      (i_clk                  ), 
  .din      ({ri_type_b,ri_len_b}   ), 
  .wr_en    (w_valid_b_pos          ), 
  .rd_en    (w_fifo_rden_b_pos      ), 
  .dout     (w_fifo_doutb_type_len  ), 
  .full     (), 
  .empty    ()  
);
/******************************assign*****************************/
assign  o_data  = ro_data   ;
assign  o_valid = ro_valid  ;
assign  o_last  = ro_last   ;
assign  o_len   = ro_len    ;
assign  o_type  = ro_type   ;
assign  o_nxt_frame_stop    =   ro_nxt_frame_stop                   ;
assign  w_rd_en             =   r_fifo_rden_a | r_fifo_rden_b       ;
assign  w_valid_a_pos       =   ri_valid_a & !ri_valid_a_1d         ;
assign  w_valid_b_pos       =   ri_valid_b & !ri_valid_b_1d         ;
assign  w_fifo_rden_a_pos   =   r_fifo_rden_a & !r_fifo_rden_a_1d   ;
assign  w_fifo_rden_b_pos   =   r_fifo_rden_b & !r_fifo_rden_b_1d   ;
/******************************always*****************************/
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        ri_data_a  <= 'd0;
        ri_valid_a <= 'd0;
        ri_last_a  <= 'd0;
       // ri_len_a   <= 'd0;
        ri_type_a  <= 'd0;        
        ri_data_b  <= 'd0;
        ri_valid_b <= 'd0;
        ri_last_b  <= 'd0;   
       // ri_len_b   <= 'd0;
        ri_type_b  <= 'd0;  
        ri_valid_a_1d <= 'd0;   
        ri_valid_b_1d <= 'd0;   
    end
    else begin
        ri_data_a  <= i_data_a ;
        ri_valid_a <= i_valid_a;
        ri_last_a  <= i_last_a ;
        //ri_len_a   <= i_len_a  ;
        ri_type_a  <= i_type_a ; 
        ri_data_b  <= i_data_b ;
        ri_valid_b <= i_valid_b;
        ri_last_b  <= i_last_b ;  
       // ri_len_b   <= i_len_b  ;
        ri_type_b  <= i_type_b ; 
        ri_valid_a_1d <= ri_valid_a;   
        ri_valid_b_1d <= ri_valid_b;         
    end
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        ri_len_a   <= 'd0; 
        ri_len_b   <= 'd0;  
    end
    else begin
        ri_len_a   <= i_len_a  ; 
        ri_len_b   <= i_len_b  ;     
    end
end

//每次发完数据仲裁信号归零，当仲裁信号为0时候才会响应下一次
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_arbiter <= 'd0;
    else if(ro_last)
        r_arbiter <= 'd0;
    else if(!w_fifo_emptya && r_arbiter == 0)
        r_arbiter <= 'd1;
    else if(!w_fifo_emptyb && r_arbiter == 0)
        r_arbiter <= 'd2;
    else
        r_arbiter <= r_arbiter;
end
  
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_data <= 'd0;
    else if(r_arbiter == 1)
        ro_data <= w_fifo_douta;
    else if(r_arbiter == 2)
        ro_data <= w_fifo_doutb;
    else
        ro_data <= 'd0;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_valid <= 'd0;
    else
        ro_valid <= r_fifo_rden[0];
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_last <= 'd0;
    else if(!w_rd_en && r_rden_1d)
        ro_last <= 'd1;
    else
        ro_last <= 'd0;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_fifo_rden_a <= 'd0;
    else if(r_arbiter == 1 && r_fifo_rd_cnt == ri_len_a - 1)
        r_fifo_rden_a <= 'd0;
    else if(r_arbiter == 1 && !w_fifo_emptya && !ro_valid)
        r_fifo_rden_a <= 'd1;
    else
        r_fifo_rden_a <= r_fifo_rden_a;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_fifo_rden_b <= 'd0;
    else if(r_arbiter == 2 && r_fifo_rd_cnt == ri_len_b - 1)
        r_fifo_rden_b <= 'd0;
    else if(r_arbiter == 2 && !w_fifo_emptyb && !ro_valid)
        r_fifo_rden_b <= 'd1;
    else
        r_fifo_rden_b <= r_fifo_rden_b;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_fifo_rd_cnt <= 'd0;
    else if(r_arbiter == 1 && r_fifo_rd_cnt == ri_len_a - 1)
        r_fifo_rd_cnt <= 'd0;
    else if(r_arbiter == 2 && r_fifo_rd_cnt == ri_len_b - 1)
        r_fifo_rd_cnt <= 'd0;
    else if(r_fifo_rden_a || r_fifo_rden_b)
        r_fifo_rd_cnt <= r_fifo_rd_cnt + 'd1;
    else
        r_fifo_rd_cnt <= r_fifo_rd_cnt;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_fifo_rden <= 'd0;
    else
        r_fifo_rden <= {r_fifo_rden[0],w_rd_en};
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_rden_1d <= 'd0;
    else
        r_rden_1d <= w_rd_en;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        r_fifo_rden_a_1d <= 'd0;
        r_fifo_rden_b_1d <= 'd0; 
    end
    else begin
        r_fifo_rden_a_1d <= r_fifo_rden_a;
        r_fifo_rden_b_1d <= r_fifo_rden_b;       
    end
end

//防止ip报文链路利用率太高，导致IP FIFO溢出
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_nxt_frame_stop <= 'd0;
    else if(ro_nxt_frame_stop && r_arbiter == 2 && !w_fifo_emptya)
        ro_nxt_frame_stop <= 'd0;
    else if(r_arbiter == 1 && !w_fifo_emptyb)//发arp包并且IP FIFO有数据的时候，停止下一帧IP输入
        ro_nxt_frame_stop <= 'd1;
    else
        ro_nxt_frame_stop <= ro_nxt_frame_stop;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        r_fifo_rden_a_pos_1d <= 'd0;
        r_fifo_rden_b_pos_1d <= 'd0; 
    end
    else begin
        r_fifo_rden_a_pos_1d <= w_fifo_rden_a_pos;
        r_fifo_rden_b_pos_1d <= w_fifo_rden_b_pos;       
    end
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        ro_len  <= 'd0;
        ro_type <= 'd0;
    end
    else if(r_arbiter == 1 && r_fifo_rden_a_pos_1d)begin
        ro_type <= w_fifo_douta_type_len[31:16];
        ro_len  <= w_fifo_douta_type_len[15: 0];        
    end
    else if(r_arbiter == 2 && r_fifo_rden_b_pos_1d)begin
        ro_type <= w_fifo_doutb_type_len[31:16];
        ro_len  <= w_fifo_doutb_type_len[15: 0];          
    end   
    else begin
        ro_type <= ro_type;
        ro_len  <= ro_len ;        
    end     
end

// always @(posedge i_clk or posedge i_rst)begin
//     if(i_rst)
        
//     else if()
        
//     else
        
// end

// always @(posedge i_clk or posedge i_rst)begin
//     if(i_rst)
        
//     else if()
        
//     else
        
// end


endmodule
