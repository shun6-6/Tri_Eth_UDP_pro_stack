`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: IP_RX
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


module IP_RX#(
    parameter       P_DST_IP = {8'd192,8'd168,8'd10,8'd0},
    parameter       P_SRC_IP = {8'd192,8'd168,8'd10,8'd1}
)(
    input           i_clk               ,
    input           i_rst               ,
    /*----info port----*/   
    input  [31:0]   i_dst_ip            ,
    input           i_dst_ip_valid      ,
    input  [31:0]   i_src_ip            ,
    input           i_src_ip_valid      ,
    /*----data port----*/   
    output [7 :0]   o_udp_data          ,
    output [15:0]   o_udp_len           ,
    output          o_udp_last          ,
    output          o_udp_valid         ,
    output [7 :0]   o_icmp_data         ,
    output [15:0]   o_icmp_len          ,
    output          o_icmp_last         ,
    output          o_icmp_valid        ,
    output [31:0]   o_recv_src_ip       ,
    output          o_recv_src_valid    ,
    /*----mac port----*/
    input  [7 :0]   i_mac_data          ,
    input           i_mac_valid         ,
    input           i_mac_last               
);
/******************************function***************************/

/******************************parameter**************************/
localparam      P_TYPE_UDP  =   8'd17;
localparam      P_TYPE_ICMP =   8'd1 ;
/******************************port*******************************/

/******************************machine****************************/

/******************************reg********************************/
reg  [31:0]     r_dst_ip            ;      
reg  [31:0]     r_src_ip            ;  
reg  [7 :0]     ri_mac_data         ;
reg  [7 :0]     ri_mac_data_1d      ;
reg             ri_mac_valid        ;
reg             ri_mac_valid_1d     ;
reg             ri_mac_last         ;   
reg  [15:0]     ro_udp_len          ;
reg             ro_udp_last         ;
reg             ro_udp_valid        ;
reg  [15:0]     ro_icmp_len         ;
reg             ro_icmp_last        ;
reg             ro_icmp_valid       ;
//reg  [31:0]     ro_recv_src_ip      ;
reg             ro_recv_src_valid   ;
//解析接收到的IP报文字段
reg  [15:0]     r_ip_len            ;
reg  [7 :0]     r_ip_type           ;
reg  [31:0]     r_ip_src_addr       ;
reg  [31:0]     r_ip_dst_addr       ;
reg  [15:0]     r_recv_ip_cnt       ;
/******************************wire*******************************/

/******************************component**************************/

/******************************assign*****************************/
assign  o_udp_data          =   ri_mac_data_1d      ;
assign  o_udp_len           =   ro_udp_len          ;
assign  o_udp_last          =   ro_udp_last         ;
assign  o_udp_valid         =   ro_udp_valid        ;
assign  o_icmp_data         =   ri_mac_data_1d      ;
assign  o_icmp_len          =   ro_icmp_len         ;
assign  o_icmp_last         =   ro_icmp_last        ;
assign  o_icmp_valid        =   ro_icmp_valid       ;
assign  o_recv_src_ip       =   r_ip_src_addr       ;
assign  o_recv_src_valid    =   ro_recv_src_valid   ;
/******************************always*****************************/
//源ip地址可设置
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_src_ip  <= P_SRC_IP ;      
    else if(i_src_ip_valid)
        r_src_ip  <= i_src_ip; 
    else 
        r_src_ip  <= r_src_ip ;
end
//目的ip地址可设置
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_dst_ip <= P_DST_IP;              
    else if(i_dst_ip_valid)
        r_dst_ip <= i_dst_ip;          
    else 
        r_dst_ip <= r_dst_ip;
end
   
//从mac层接收到的IP报文消息
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        ri_mac_data     <= 'd0;
        ri_mac_valid    <= 'd0;
        ri_mac_last     <= 'd0;   
        ri_mac_data_1d  <= 'd0;
        ri_mac_valid_1d <= 'd0;     
    end
    else begin
        ri_mac_data     <= i_mac_data ;
        ri_mac_valid    <= i_mac_valid;
        ri_mac_last     <= i_mac_last ;    
        ri_mac_data_1d  <= ri_mac_data;
        ri_mac_valid_1d <= ri_mac_valid;      
    end
end
//解析接收到的IP报文消息
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_recv_ip_cnt <= 'd0;
    else if(ri_mac_valid)
        r_recv_ip_cnt <= r_recv_ip_cnt + 'd1;
    else
        r_recv_ip_cnt <= 'd0;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_ip_len <= 'd0;
    else if(ri_mac_valid && r_recv_ip_cnt >= 2 && r_recv_ip_cnt <= 3)
        r_ip_len <= {r_ip_len[7:0],ri_mac_data};
    else
        r_ip_len <= r_ip_len;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_ip_type <= 'd0;
    else if(ri_mac_valid && r_recv_ip_cnt == 9)
        r_ip_type <= ri_mac_data;
    else
        r_ip_type <= r_ip_type;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_ip_src_addr <= 'd0;
    else if(ri_mac_valid && r_recv_ip_cnt >= 12 && r_recv_ip_cnt <= 15)
        r_ip_src_addr <= {r_ip_src_addr[23:0],ri_mac_data};
    else
        r_ip_src_addr <= r_ip_src_addr;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_ip_dst_addr <= 'd0;
    else if(ri_mac_valid && r_recv_ip_cnt >= 16 && r_recv_ip_cnt <= 19)
        r_ip_dst_addr <= {r_ip_dst_addr[23:0],ri_mac_data};
    else
        r_ip_dst_addr <= r_ip_dst_addr;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_recv_src_valid <= 'd0;
    else if(r_recv_ip_cnt == 15)
        ro_recv_src_valid <= 'd1;
    else 
        ro_recv_src_valid <= 'd0;
end

//将解析的数据进行输出              
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        ro_udp_len  <= 'd0;
        ro_icmp_len <= 'd0;        
    end
    else begin
        ro_udp_len  <= r_ip_len - 20;
        ro_icmp_len <= r_ip_len - 20;//要减去IP头部20字节  
    end
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_udp_valid <= 'd0;
    else if(!ri_mac_valid && ri_mac_valid_1d)
        ro_udp_valid <= 'd0;
    else if(r_recv_ip_cnt == 20 && r_ip_type == P_TYPE_UDP && r_ip_dst_addr == r_src_ip)
        ro_udp_valid <= 'd1;
    else
        ro_udp_valid <= ro_udp_valid;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_icmp_valid <= 'd0;
    else if(!ri_mac_valid && ri_mac_valid_1d)
        ro_icmp_valid <= 'd0;
    else if(r_recv_ip_cnt == 20 && r_ip_type == P_TYPE_ICMP && r_ip_dst_addr == r_src_ip)
        ro_icmp_valid <= 'd1;
    else
        ro_icmp_valid <= ro_icmp_valid;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_udp_last <= 'd0;
    else if(!i_mac_valid && ri_mac_valid && r_ip_type == P_TYPE_UDP)
        ro_udp_last <= 'd1;
    else
        ro_udp_last <= 'd0;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_icmp_last <= 'd0;
    else if(!i_mac_valid && ri_mac_valid && r_ip_type == P_TYPE_ICMP)
        ro_icmp_last <= 'd1;
    else
        ro_icmp_last <= 'd0;
end

endmodule
