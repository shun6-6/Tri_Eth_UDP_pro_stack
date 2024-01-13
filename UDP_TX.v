`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: UDP_TX
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


module UDP_TX#(
    parameter       P_DST_UDP_PORT  =   16'h8080,
    parameter       P_SRC_UDP_PORT  =   16'h8080
)(
    input           i_clk           ,
    input           i_rst           ,
    /*----info port----*/
    input   [15:0]  i_dst_udp_port  ,
    input           i_dst_udp_valid ,
    input   [15:0]  i_src_udp_port  ,
    input           i_src_udp_valid ,
    /*----data port----*/
    input   [7 :0]  i_send_udp_data ,
    input   [15:0]  i_send_udp_len  ,
    input           i_send_udp_last ,
    input           i_send_udp_valid,
    /*----ip port----*/
    output  [7 :0]  o_ip_type       ,
    output  [7 :0]  o_ip_data       ,
    output  [15:0]  o_ip_len        ,
    output          o_ip_last       ,
    output          o_ip_valid      
);
/******************************function***************************/

/******************************parameter**************************/
localparam      P_UDP_MIN_LEN = 18  ;
/******************************port*******************************/

/******************************machine****************************/

/******************************reg********************************/
reg  [15:0]     r_dst_udp_port      ;
reg  [15:0]     r_src_udp_port      ;
reg  [7 :0]     ri_send_udp_data    ;
reg  [15:0]     ri_send_udp_len     ;
reg             ri_send_udp_last    ;
reg             ri_send_udp_valid   ;
reg             ri_send_udp_valid_1d;

reg  [7 :0]     ro_ip_data          ;
reg             ro_ip_last          ;
reg             ro_ip_valid         ;
reg  [15:0]     ro_ip_len           ;
//fifo
reg             r_fifo_rden         ;
reg             r_fifo_rden_1d      ; 
reg             r_fifo_empty        ;
//组帧
reg  [15:0]     r_udp_data_cnt      ;
/******************************wire*******************************/
wire [7 :0]     w_fifo_rdata        ;
wire            w_fifo_full         ;
wire            w_fifo_empty        ;
/******************************component**************************/
MAC_TX_FIFO_8x512 UDP_TX_FIFO_8x512_u0 (
  .clk              (i_clk              ), 
  .srst             (i_rst              ), 
  .din              (ri_send_udp_data   ), 
  .wr_en            (ri_send_udp_valid  ), 
  .rd_en            (r_fifo_rden        ), 
  .dout             (w_fifo_rdata       ), 
  .full             (w_fifo_full        ), 
  .empty            (w_fifo_empty       ), 
  .wr_rst_busy      (), 
  .rd_rst_busy      ()  
);
/******************************assign*****************************/
assign  o_ip_type   =   8'd17  ;
assign  o_ip_data   =   ro_ip_data  ;
assign  o_ip_len    =   ro_ip_len   ;
assign  o_ip_last   =   ro_ip_last  ;
assign  o_ip_valid  =   ro_ip_valid ;
/******************************always*****************************/
//源udp端口可设置?
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_src_udp_port  <= P_SRC_UDP_PORT ;      
    else if(i_src_udp_valid)
        r_src_udp_port  <= i_src_udp_port; 
    else 
        r_src_udp_port  <= r_src_udp_port ;
end
//目的udp端口可设置?
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_dst_udp_port <= P_DST_UDP_PORT;              
    else if(i_dst_udp_valid)
        r_dst_udp_port <= i_dst_udp_port;          
    else 
        r_dst_udp_port <= r_dst_udp_port;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst) begin
        ri_send_udp_data  <= 'd0;
        //ri_send_udp_len   <= 'd0;
        ri_send_udp_last  <= 'd0;
        ri_send_udp_valid <= 'd0;        
        ri_send_udp_valid_1d <= 'd0;
    end                    
    else begin 
        ri_send_udp_data  <= i_send_udp_data ;
        //ri_send_udp_len   <= i_send_udp_len + 8;
        ri_send_udp_last  <= i_send_udp_last ;
        ri_send_udp_valid <= i_send_udp_valid;  
        ri_send_udp_valid_1d <= ri_send_udp_valid;
    end
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ri_send_udp_len <= 'd0;             
    else if(i_send_udp_valid)
        ri_send_udp_len <= i_send_udp_len;         
    else 
        ri_send_udp_len <= ri_send_udp_len;
end

//组帧计数器 计数器与valid同步开始计数，因此发送38个数据计数器就要计数到38而不是37了
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_udp_data_cnt <= 'd0;   
    else if((ri_send_udp_len < P_UDP_MIN_LEN) && (r_udp_data_cnt == P_UDP_MIN_LEN))
        r_udp_data_cnt <= 'd0;   
    else if((ri_send_udp_len >= P_UDP_MIN_LEN) && (r_udp_data_cnt == (ri_send_udp_len + 8)))
        r_udp_data_cnt <= 'd0;           
    else if(ri_send_udp_valid || r_udp_data_cnt)
        r_udp_data_cnt <= r_udp_data_cnt + 1;          
    else 
        r_udp_data_cnt <= r_udp_data_cnt;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_fifo_rden <= 'd0;    
    else if(r_udp_data_cnt == ri_send_udp_len + 8 - 2)//FIFO输出延迟1拍，应该在last拉高时同时拉高?
        r_fifo_rden <= 'd0;           
    else if(r_udp_data_cnt == 6)
        r_fifo_rden <= 'd1;          
    else 
        r_fifo_rden <= r_fifo_rden;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_fifo_empty <= 'd0;          
    else 
        r_fifo_empty <= w_fifo_empty;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_ip_data <= 'd0;        
    else case (r_udp_data_cnt)
        0       : ro_ip_data <= r_src_udp_port[15:8];     
        1       : ro_ip_data <= r_src_udp_port[7 :0];     
        2       : ro_ip_data <= r_dst_udp_port[15:8];     
        3       : ro_ip_data <= r_dst_udp_port[7 :0];     
        4       : ro_ip_data <= ro_ip_len[15:8];     
        5       : ro_ip_data <= ro_ip_len[7 :0];     
        6       : ro_ip_data <= 'd0;     
        7       : ro_ip_data <= 'd0;     
        default : ro_ip_data <= r_fifo_empty ? 'd0 : w_fifo_rdata;
    endcase
end
//计数器与valid同步开始计数，因此发送38个数据计数器就要计数到38而不是37,valid和last也不是-1和-2了，相应加1
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_ip_valid <= 'd0;  
    else if((ri_send_udp_len < P_UDP_MIN_LEN) && (r_udp_data_cnt == P_UDP_MIN_LEN))
        ro_ip_valid <= 'd0;  
    else if((r_udp_data_cnt == ri_send_udp_len + 8) && (ri_send_udp_len >= P_UDP_MIN_LEN))
        ro_ip_valid <= 'd0;           
    else if(ri_send_udp_valid && !ri_send_udp_valid_1d)
        ro_ip_valid <= 'd1;          
    else 
        ro_ip_valid <= ro_ip_valid;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_ip_last <= 'd0;  
    else if((ri_send_udp_len < P_UDP_MIN_LEN) && (r_udp_data_cnt == P_UDP_MIN_LEN - 1))
        ro_ip_last <='d1;          
    else if((r_udp_data_cnt == ri_send_udp_len + 8 - 1) && (ri_send_udp_len >= P_UDP_MIN_LEN))
        ro_ip_last <='d1;          
    else 
        ro_ip_last <= 'd0;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_ip_len <= 'd0; 
    else if(ri_send_udp_valid && ri_send_udp_len < P_UDP_MIN_LEN)
        ro_ip_len <= 'd18 + 8;             
    else if(ri_send_udp_valid && ri_send_udp_len >= P_UDP_MIN_LEN)
        ro_ip_len <= ri_send_udp_len + 'd8;          
    else 
        ro_ip_len <= ro_ip_len;
end

endmodule
