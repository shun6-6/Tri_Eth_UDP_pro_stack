`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: UDP_RX
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


module UDP_RX#(
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
    output  [7 :0]  o_udp_data      ,
    output  [15:0]  o_udp_len       ,
    output          o_udp_last      ,
    output          o_udp_valid     ,
    /*----ip port----*/
    input   [7 :0]  i_ip_data       ,
    input   [15:0]  i_ip_len        ,
    input           i_ip_last       ,
    input           i_ip_valid      
);
/******************************function***************************/

/******************************parameter**************************/

/******************************port*******************************/

/******************************machine****************************/

/******************************reg********************************/
reg  [15:0] r_dst_udp_port ;
reg  [15:0] r_src_udp_port ;
reg  [7 :0] ri_ip_data     ;
reg  [15:0] ri_ip_len      ;
reg         ri_ip_last     ;
reg         ri_ip_valid    ;
//reg  [7 :0] ro_udp_data    ;
reg  [15:0] ro_udp_len     ;
reg         ro_udp_last    ;
reg         ro_udp_valid   ;
reg  [15:0] r_udp_recv_cnt ;     
/******************************wire*******************************/

/******************************component**************************/

/******************************assign*****************************/
assign  o_udp_data  =   ri_ip_data      ;
assign  o_udp_len   =   ro_udp_len      ;
assign  o_udp_last  =   ro_udp_last     ;
assign  o_udp_valid =   ro_udp_valid    ;
/******************************always*****************************/
//源udp端口可设置
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_src_udp_port  <= P_SRC_UDP_PORT ;      
    else if(i_src_udp_valid)
        r_src_udp_port  <= i_src_udp_port; 
    else 
        r_src_udp_port  <= r_src_udp_port ;
end
//目的udp端口可设置
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
        ri_ip_data  <= 'd0;
        ri_ip_len   <= 'd0;
        ri_ip_last  <= 'd0;
        ri_ip_valid <= 'd0;        
    end                    
    else if(i_ip_valid)begin
        ri_ip_data  <= i_ip_data ;
        ri_ip_len   <= i_ip_len  ;
        ri_ip_last  <= i_ip_last ;
        ri_ip_valid <= i_ip_valid;         
    end
    else begin
        ri_ip_data  <= 'd0;
        ri_ip_len   <= ri_ip_len;
        ri_ip_last  <= 'd0;
        ri_ip_valid <= 'd0;         
    end
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_udp_recv_cnt <= 'd0;              
    else if(ri_ip_valid)
        r_udp_recv_cnt <= r_udp_recv_cnt + 1;          
    else 
        r_udp_recv_cnt <= 'd0;
end
//解析接收到的IP数据当中的udp数据内容
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_udp_len <= 'd0;                       
    else 
        ro_udp_len <= ri_ip_len - 8;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_udp_last <= 'd0;              
    else if(r_udp_recv_cnt == ri_ip_len - 2)
        ro_udp_last <= 'd1;          
    else 
        ro_udp_last <= 'd0;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_udp_valid <= 'd0; 
    else if(r_udp_recv_cnt == ri_ip_len - 1)
        ro_udp_valid <= 'd0;             
    else if(r_udp_recv_cnt == 7)
        ro_udp_valid <= 'd1;          
    else 
        ro_udp_valid <= ro_udp_valid;
end

endmodule
