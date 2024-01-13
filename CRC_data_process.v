`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/05 21:24:33
// Design Name: 
// Module Name: CRC_data_process
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


module CRC_data_process(
    input           i_clk           ,
    input           i_rst           ,

    /*----data port----*/
    input  [15:0]   i_pre_type      ,
    input  [7 :0]   i_pre_data      ,
    input           i_pre_valid     ,
    input           i_pre_last      ,
    input           i_pre_crc_error ,
    input           i_pre_crc_valid ,

    output [15:0]   o_post_type     ,
    output [7 :0]   o_post_data     ,
    output          o_post_valid    ,
    output          o_post_last     
);
/******************************function***************************/

/******************************parameter**************************/
localparam      P_FRAME_GAP = 12 - 4;//frame gap 12cycle 96bit 数据处理过程使用了4个
/******************************port*******************************/

/******************************machine****************************/

/******************************reg********************************/
reg  [15:0]     ri_pre_type         ;
reg  [7 :0]     ri_pre_data         ;
reg             ri_pre_valid        ;
reg             ri_pre_last         ;
reg             ri_pre_crc_error    ;
reg             ri_pre_crc_valid    ;
reg  [15:0]     ro_post_type        ;
reg  [7 :0]     ro_post_data        ;
reg             ro_post_valid       ;
reg             ro_post_last        ;
//rma
reg             r_ram_ena           ;
reg             r_ram_wea           ;
reg  [10:0]     r_ram_addra         ;
reg             r_ram_enb           ;
reg             r_ram_enb_1d        ;
reg             r_ram_web           ;
reg  [10:0]     r_ram_addrb         ;
reg  [10:0]     r_ram_pre_addra         ;

reg  [10:0]     r_data_len          ;
reg             r_fifo_wren         ;
reg             r_fifo_rden         ;
reg             r_fifo_rden_1d      ;
reg  [10:0]     r_data_actl_len     ;
reg             r_out_run           ;
reg             r_out_run_1d        ;
reg  [10:0]     r_fifo_rd_len       ;//读出的数据包长度信息
reg  [3: 0]     r_gap_cnt           ;//frame gap 12cycle 96bit
reg             r_gap               ;
reg             r_crc_error_1d      ;
/******************************wire*******************************/
wire [7 :0]     w_ram_douta         ;
wire [7 :0]     w_ram_doutb         ;
wire [10:0]     w_fifo_dout         ;
wire            w_fifo_full         ;
wire            w_fifo_empty        ;
wire [15:0]     w_fifo_type         ;

wire            w_crc_error         ;
/******************************component**************************/
RAM_8X1500_TDM RAM_8X1500_TDM_u0 (
//only write
  .clka     (i_clk          ),    // input wire clka
  .ena      (r_ram_ena      ),      // input wire ena
  .wea      (r_ram_wea      ),      // input wire [0 : 0] wea
  .addra    (r_ram_addra    ),  // input wire [10 : 0] addra
  .dina     (ri_pre_data    ),    // input wire [7 : 0] dina
  .douta    (w_ram_douta    ),  // output wire [7 : 0] douta
//only read
  .clkb     (i_clk          ),    // input wire clkb
  .enb      (r_ram_enb      ),      // input wire enb
  .web      (r_ram_web      ),      // input wire [0 : 0] web
  .addrb    (r_ram_addrb    ),  // input wire [10 : 0] addrb
  .dinb     (0              ),    // input wire [7 : 0] dinb
  .doutb    (w_ram_doutb    )  // output wire [7 : 0] doutb
);
//fifo buf，因为ram里会存入多个数据，需要用FIFO把长度信息缓存下来
FIFO_buf_11x64 FIFO_buf_11x64_u0 (
  .clk      (i_clk          ),      // input wire clk
  .din      (r_data_len     ),      // input wire [10 : 0] din
  .wr_en    (r_fifo_wren    ),  // input wire wr_en
  .rd_en    (r_fifo_rden    ),  // input wire rd_en
  .dout     (w_fifo_dout    ),    // output wire [10 : 0] dout
  .full     (w_fifo_full    ),    // output wire full
  .empty    (w_fifo_empty   )  // output wire empty
);
//type也存入，操作过程和len一致
FIFO16x64_buf_type FIFO16x64_buf_type_u0 (
  .clk      (i_clk          ),      // input wire clk
  .din      (ri_pre_type    ),      // input wire [10 : 0] din
  .wr_en    (r_fifo_wren    ),  // input wire wr_en
  .rd_en    (r_fifo_rden    ),  // input wire rd_en
  .dout     (w_fifo_type    ),    // output wire [10 : 0] dout
  .full     (),    // output wire full
  .empty    ()  // output wire empty
);
/******************************assign*****************************/
assign  o_post_data     = ro_post_data  ;
assign  o_post_valid    = ro_post_valid ;
assign  o_post_last     = ro_post_last  ;
assign  o_post_type     = ro_post_type  ;
assign  w_crc_error     = ri_pre_crc_valid && ri_pre_crc_error;
/******************************always*****************************/
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)begin
        ri_pre_type      <= 'd0;
        ri_pre_data      <= 'd0;
        ri_pre_valid     <= 'd0;
        ri_pre_last      <= 'd0;
        ri_pre_crc_error <= 'd0;
        ri_pre_crc_valid <= 'd0;        
    end
    else begin
        ri_pre_type      <= i_pre_type      ;
        ri_pre_data      <= i_pre_data      ;
        ri_pre_valid     <= i_pre_valid     ;
        ri_pre_last      <= i_pre_last      ;
        ri_pre_crc_error <= i_pre_crc_error ;
        ri_pre_crc_valid <= i_pre_crc_valid ;         
    end
end
//ram a端口写入数据
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)begin
        r_ram_ena   <= 'd0;
        r_ram_wea   <= 'd0;   
    end
    else if(i_pre_valid)begin//用ri_pre_valid是要慢一拍其实
        r_ram_ena   <= 'd1;
        r_ram_wea   <= 'd1;     
    end
    else begin
        r_ram_ena   <= 'd0;
        r_ram_wea   <= 'd0;     
    end
end

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_crc_error_1d <= 'd0;
    else
        r_crc_error_1d <= w_crc_error;
end
//环形ram，0-2047循环
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_ram_addra <= 'd0;  
    else if(ri_pre_crc_valid && ri_pre_crc_error)//出现错误，需要去除掉这一帧数据
        r_ram_addra <= r_ram_addra - r_data_actl_len;//当前地址直接减掉长度就可以覆盖当前crc错误数据
    else if(r_ram_ena & r_ram_wea)
        r_ram_addra <= r_ram_addra + 'd1;  
    else
        r_ram_addra <= r_ram_addra;  
end
//记录当前数据长度，该数值为ram对应地址，所以实际数字相当于实际长度-1
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_data_len <= 'd0;
    else if(ri_pre_last)
        r_data_len <= r_ram_addra;
    else
        r_data_len <= r_data_len;
end
//记录上次的ram地址
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_ram_pre_addra <= 'd0;
    else if(r_crc_error_1d)
        r_ram_pre_addra <= r_ram_addra;
    else if(ri_pre_last)
        r_ram_pre_addra <= r_ram_addra;
    else
        r_ram_pre_addra <= r_ram_pre_addra;
end
//这才是一个数据包真正的长度
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_data_actl_len <= 'd0;
    else if(ri_pre_last)
        r_data_actl_len <= r_ram_addra - r_ram_pre_addra;//这才是一个数据包真正的长度
    else
        r_data_actl_len <= r_data_actl_len;
end

//没有crc错误，记录长度信息到FIFO
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_fifo_wren <= 'd0;
    else if(ri_pre_crc_valid && !ri_pre_crc_error)
        r_fifo_wren <= 'd1;
    else
        r_fifo_wren <= 'd0;
end
//fifo read
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_fifo_rden <= 'd0;
    else if(r_fifo_rden)
        r_fifo_rden <= 'd0;
    else if(!w_fifo_empty && !r_out_run && (r_gap_cnt == P_FRAME_GAP))//fifo不为空且没有正在输出数据的时候从FIFO当中读一个长度信息出来
        r_fifo_rden <= 'd1;
    else
        r_fifo_rden <= 'd0;
end

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_fifo_rden_1d <= 'd0;
    else
        r_fifo_rden_1d <= r_fifo_rden;
end
//表示当前正在输出数据
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_out_run <= 'd0;
    else if(r_ram_addrb == r_fifo_rd_len - 1)
        r_out_run <= 'd0;
    else if(!r_fifo_rden && r_fifo_rden_1d)
        r_out_run <= 'd1;
    else
        r_out_run <= r_out_run;
end

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_out_run_1d <= 'd0;
    else
        r_out_run_1d <= r_out_run;
end
//读出FIFO当中存入的数据
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_fifo_rd_len <= 'd0;
    else if(r_fifo_rden_1d)
        r_fifo_rd_len <= w_fifo_dout;
    else
        r_fifo_rd_len <= r_fifo_rd_len;
end

//ram b端口读出数据
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)begin
        r_ram_enb   <= 'd0;
        r_ram_web   <= 'd0;   
    end
    else if(r_ram_addrb == r_fifo_rd_len)begin
        r_ram_enb   <= 'd0;
        r_ram_web   <= 'd0;     
    end
    else if(r_out_run && !r_out_run_1d)begin
        r_ram_enb   <= 'd1;
        r_ram_web   <= 'd0;     
    end
    else begin
        r_ram_enb   <= r_ram_enb;
        r_ram_web   <= r_ram_web;     
    end
end

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_ram_addrb <= 'd0; 
    else if(r_ram_enb && (r_ram_addrb == r_fifo_rd_len))
        r_ram_addrb <= r_ram_addrb;   
    else if(r_ram_enb & !r_ram_web)
        r_ram_addrb <= r_ram_addrb + 'd1;  
    else
        r_ram_addrb <= r_ram_addrb;  
end

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_ram_enb_1d <= 'd0;
    else
        r_ram_enb_1d <= r_ram_enb;
end
//输出数据data valid last
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        ro_post_valid <= 'd0;
    else
        ro_post_valid <= r_ram_enb_1d;
end

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        ro_post_type <= 'd0;
    else if(r_fifo_rden_1d)
        ro_post_type <= w_fifo_type;
    else
        ro_post_type <= ro_post_type;
end

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        ro_post_data <= 'd0;
    else if(r_ram_enb_1d)
        ro_post_data <= w_ram_doutb;
    else
        ro_post_data <= ro_post_data;
end

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        ro_post_last <= 'd0;
    else if(!r_ram_enb & r_ram_enb_1d)
        ro_post_last <= 'd1;
    else
        ro_post_last <= 'd0;
end
//

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_gap <= 'd1;
    else if(r_gap_cnt == P_FRAME_GAP)
        r_gap <= 'd0;
    else if(ro_post_last)
        r_gap <= 'd1;
    else
        r_gap <= r_gap;
end

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_gap_cnt <= 'd0;
    else if(r_fifo_rden)
        r_gap_cnt <= 'd0;
    else if(r_gap_cnt == P_FRAME_GAP)
        r_gap_cnt <= r_gap_cnt;
    else if(r_gap)
        r_gap_cnt <= r_gap_cnt + 1;
    else
        r_gap_cnt <= r_gap_cnt;
end


endmodule
