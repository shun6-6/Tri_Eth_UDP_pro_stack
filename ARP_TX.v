`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: ARP_TX
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


module ARP_TX#(
    parameter       P_DST_IP  = {8'd192,8'd168,8'd10,8'd0},
    parameter       P_SRC_IP  = {8'd192,8'd168,8'd10,8'd1},
    parameter       P_SRC_MAC = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00}
)(
    input           i_clk           ,
    input           i_rst           ,
    /*----info port----*/   
    input   [31:0]  i_dst_ip        , 
    input           i_dst_ip_valid  ,
    input   [31:0]  i_src_ip        , 
    input           i_src_ip_valid  ,
    input   [47:0]  i_src_mac       , 
    input           i_src_mac_valid ,   

    input           i_trig_reply    ,
    input           i_active_req    ,
    /*----MAC port----*/     
    output  [7 :0]  o_mac_data      ,
    output          o_mac_last      ,
    output          o_mac_valid     
);
/******************************function***************************/

/******************************parameter**************************/
localparam      P_ARP_LEN       = 15'd46;//min mac length
localparam      P_ARP_OP_REQ    = 16'd1 ;
localparam      P_ARP_OP_REPLY  = 16'd2 ;
/******************************port*******************************/

/******************************machine****************************/

/******************************reg********************************/
reg  [31:0]     r_src_ip        ;
reg  [47:0]     r_src_mac       ;
reg  [31:0]     r_dst_ip        ;
reg             ri_trig_reply   ;
reg             ri_active_req   ;
reg  [7 :0]     ro_mac_data     ;
reg             ro_mac_last     ;
reg             ro_mac_valid    ;
//组包
reg  [15:0]     r_arp_cnt       ;//组包计数器
reg  [15:0]     r_arp_op        ;
/******************************wire*******************************/

/******************************component**************************/

/******************************assign*****************************/
assign  o_mac_data  =   ro_mac_data     ;
assign  o_mac_last  =   ro_mac_last     ;
assign  o_mac_valid =   ro_mac_valid    ;
/******************************always*****************************/
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin 
        ri_trig_reply <= 'd0;
        ri_active_req <= 'd0;      
    end
    else begin
        ri_trig_reply <= i_trig_reply;
        ri_active_req <= i_active_req; 
    end
end
//get ip and mac addr
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_dst_ip <= P_DST_IP;
    else if(i_dst_ip_valid)
        r_dst_ip <= i_dst_ip;
    else
        r_dst_ip <= r_dst_ip;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_src_ip <= P_SRC_IP;
    else if(i_src_ip_valid)
        r_src_ip <= i_src_ip;
    else
        r_src_ip <= r_src_ip;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_src_mac <= P_SRC_MAC;
    else if(i_src_mac_valid)
        r_src_mac <= i_src_mac;
    else
        r_src_mac <= r_src_mac;
end
/*=================== begin compone arp frame ======================*/
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_arp_cnt <= 'd0;
    else if(r_arp_cnt == P_ARP_LEN - 1)
        r_arp_cnt <= 'd0;
    else if(ri_trig_reply || ri_active_req || r_arp_cnt)
        r_arp_cnt <= r_arp_cnt + 'd1;
    else
        r_arp_cnt <= r_arp_cnt;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_arp_op <= 'd0;
    else if(ri_trig_reply)
        r_arp_op <= P_ARP_OP_REPLY;
    else if(ri_active_req)
        r_arp_op <= P_ARP_OP_REQ;
    else
        r_arp_op <= r_arp_op;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_mac_data <= 'd0;
    else case (r_arp_cnt)
        0       : ro_mac_data <= 8'h00;             //硬件类型，对以太网，值为1
        1       : ro_mac_data <= 8'h01;             
        2       : ro_mac_data <= 8'h08;             //协议类型，IP 0x0800
        3       : ro_mac_data <= 8'h00;     
        4       : ro_mac_data <= 'd6;               //硬件地址长度
        5       : ro_mac_data <= 'd4;               //协议长度
        6       : ro_mac_data <= r_arp_op[15:8];    //操作类型
        7       : ro_mac_data <= r_arp_op[7 :0];
        8       : ro_mac_data <= r_src_mac[47:40];
        9       : ro_mac_data <= r_src_mac[39:32];
        10      : ro_mac_data <= r_src_mac[31:24];
        11      : ro_mac_data <= r_src_mac[23:16];
        12      : ro_mac_data <= r_src_mac[15: 8];
        13      : ro_mac_data <= r_src_mac[7 : 0];
        14      : ro_mac_data <= r_src_ip[31:24];
        15      : ro_mac_data <= r_src_ip[23:16];
        16      : ro_mac_data <= r_src_ip[15: 8];
        17      : ro_mac_data <= r_src_ip[7 : 0];
        18      : ro_mac_data <= 8'hFF;
        19      : ro_mac_data <= 8'hFF; 
        20      : ro_mac_data <= 8'hFF;
        21      : ro_mac_data <= 8'hFF;
        22      : ro_mac_data <= 8'hFF;
        23      : ro_mac_data <= 8'hFF;
        24      : ro_mac_data <= r_dst_ip[31:24];
        25      : ro_mac_data <= r_dst_ip[23:16];
        26      : ro_mac_data <= r_dst_ip[15: 8];
        27      : ro_mac_data <= r_dst_ip[7 : 0];
        default : ro_mac_data <= 'd0; 
    endcase
end
 

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_mac_valid <= 'd0;
    else if(r_arp_cnt == P_ARP_LEN - 1)
        ro_mac_valid <= 'd0;
    else if(ri_trig_reply || ri_active_req)
        ro_mac_valid <= 'd1;
    else
        ro_mac_valid <= ro_mac_valid;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_mac_last <= 'd0;
    else if(r_arp_cnt == P_ARP_LEN - 2)
        ro_mac_last <= 'd1;
    else
        ro_mac_last <= 'd0;
end


endmodule
