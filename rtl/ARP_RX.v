`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: ARP_RX
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


module ARP_RX#(
    parameter       P_DST_IP  = {8'd192,8'd168,8'd10,8'd0},
    parameter       P_SRC_IP  = {8'd192,8'd168,8'd10,8'd1},
    parameter       P_SRC_MAC = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00}
)(
    input           i_clk           ,
    input           i_rst           ,
    /*----info port----*/   
    output  [47:0]  o_dst_mac       ,
    output  [31:0]  o_dst_ip        ,
    output          o_dst_valid     ,
    input   [31:0]  i_src_ip        , 
    input           i_src_ip_valid  ,

    output          o_trig_reply    ,
    /*----MAC port----*/    
    input   [7 :0]  i_mac_data      ,
    input           i_mac_last      ,
    input           i_mac_valid     
);
/******************************function***************************/

/******************************parameter**************************/
localparam  P_ARP_OP_REQ    = 16'd1;
localparam  P_ARP_OP_REPLY  = 16'd2;
/******************************port*******************************/

/******************************machine****************************/

/******************************reg********************************/
reg  [7 :0]     ri_mac_data     ;
reg             ri_mac_last     ;
reg             ri_mac_valid    ;
reg  [31:0]     r_src_ip        ;
reg             ro_trig_reply   ;
reg  [47:0]     ro_dst_mac      ;
reg  [31:0]     ro_dst_ip       ;
reg             ro_dst_valid    ;
//解析接收数据
reg  [15:0]     r_recv_arp_cnt  ;
reg  [15:0]     r_arp_op        ;
reg  [31:0]     r_recv_dst_ip   ;
/******************************wire*******************************/

/******************************component**************************/

/******************************assign*****************************/
assign  o_dst_mac       =   ro_dst_mac      ;
assign  o_dst_ip        =   ro_dst_ip       ;
assign  o_dst_valid     =   ro_dst_valid    ;
assign  o_trig_reply    =   ro_trig_reply   ;
/******************************always*****************************/
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        ri_mac_data  <= 'd0;
        ri_mac_last  <= 'd0;
        ri_mac_valid <= 'd0;
    end
    else begin
        ri_mac_data  <= i_mac_data ;
        ri_mac_last  <= i_mac_last ;
        ri_mac_valid <= i_mac_valid;        
    end
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_src_ip <= P_SRC_IP;
    else if(i_src_ip_valid)
        r_src_ip <= i_src_ip;
    else
        r_src_ip <= r_src_ip;
end
//接收计数器
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_recv_arp_cnt <= 'd0;
    else if(ri_mac_valid)
        r_recv_arp_cnt <= r_recv_arp_cnt + 'd1;
    else
        r_recv_arp_cnt <= 'd0;
end

//获取操作类型
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_arp_op <= 'd0;
    else if(r_recv_arp_cnt >= 6 && r_recv_arp_cnt <= 7)
        r_arp_op <= {r_arp_op[7:0],ri_mac_data};
    else
        r_arp_op <= r_arp_op;
end
//获取ARP报文的源IP和mac，该内容会作为回应报文的目的地址
//所以此处获取的俩个dst IP 或者 mac 都是接收到的报文当中的源IP和mac字段
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_dst_mac <= 'd0;
    else if(r_recv_arp_cnt >= 8 && r_recv_arp_cnt <= 13 && r_arp_op == P_ARP_OP_REQ || r_arp_op == P_ARP_OP_REPLY)
        ro_dst_mac <= {ro_dst_mac[39:0],ri_mac_data};
    else
        ro_dst_mac <= ro_dst_mac;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_dst_ip <= 'd0;
    else if(r_recv_arp_cnt >= 14 && r_recv_arp_cnt <= 17 && r_arp_op == P_ARP_OP_REQ || r_arp_op == P_ARP_OP_REPLY)
        ro_dst_ip <= {ro_dst_ip[23:0],ri_mac_data};
    else
        ro_dst_ip <= ro_dst_ip;
end
//此信号才是接收数据当中的目的IP，也就是该信号才需要和本机IP作比较
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_recv_dst_ip <= 'd0;
    else if(r_recv_arp_cnt >= 24 && r_recv_arp_cnt <= 27)
        r_recv_dst_ip <= {r_recv_dst_ip[23:0],ri_mac_data};
    else
        r_recv_dst_ip <= r_recv_dst_ip;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_dst_valid <= 'd0;
    else if(r_recv_arp_cnt == 28 && r_recv_dst_ip == r_src_ip)
        ro_dst_valid <= 'd1;
    else
        ro_dst_valid <= 'd0;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_trig_reply <= 'd0;
    else if(r_recv_arp_cnt == 28 && r_arp_op == P_ARP_OP_REQ && r_recv_dst_ip == r_src_ip)
        ro_trig_reply <= 'd1;
    else
        ro_trig_reply <= 'd0;
end

endmodule
