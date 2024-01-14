`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: ICMP_TX
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


module ICMP_TX(
    input               i_clk           ,
    input               i_rst           ,
    
    input               i_trig_reply    ,
    input  [15:0]       i_trig_seq      ,
    // input               i_active_req    ,
    // input  [15:0]       i_active_seq    ,
    /*----send port----*/
    output [7 :0]       o_icmp_data     ,
    output [15:0]       o_icmp_len      ,
    output              o_icmp_last     ,
    output              o_icmp_valid    
);
/******************************function***************************/

/******************************parameter**************************/
localparam      P_ICMP_LEN  =   15'd40;
localparam      P_ICMP_REPLY_TYPE   =   8'd0;
localparam      P_ICMP_REQ_TYPE     =   8'd8;
/******************************port*******************************/

/******************************machine****************************/

/******************************reg********************************/
reg             ri_trig_reply   ;
reg  [15:0]     ri_trig_seq     ;
reg             ri_active_req   ;
reg  [15:0]     ri_active_seq   ;
reg  [7 :0]     ro_icmp_data    ;
reg             ro_icmp_last    ;
reg             ro_icmp_valid   ;
//组帧
reg  [15:0]     r_icmp_cnt      ;
reg  [31:0]     r_checksum      ;
reg  [15:0]     r_check_cnt     ;
/******************************wire*******************************/

/******************************component**************************/

/******************************assign*****************************/
assign  o_icmp_data     =   ro_icmp_data    ;
assign  o_icmp_len      =   P_ICMP_LEN      ;
assign  o_icmp_last     =   ro_icmp_last    ;
assign  o_icmp_valid    =   ro_icmp_valid   ;
/******************************always*****************************/
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)begin
        ri_trig_reply <= 'd0;
        ri_trig_seq <= 'd0;  
        ri_active_req <= 'd0;
        ri_active_seq <= 'd0;      
    end
    else begin
        ri_trig_reply <= i_trig_reply;
        ri_trig_seq <= i_trig_seq;     
        // ri_active_req <= i_active_req;
        // ri_active_seq <= i_active_seq;
    end
end
//check sum
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_check_cnt <= 'd0;
    else if(r_icmp_cnt == 3)
        r_check_cnt <= 'd0;
    else if(ri_trig_reply || r_check_cnt)
        r_check_cnt <= r_check_cnt + 'd1;
    else
        r_check_cnt <= r_check_cnt;
end

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_checksum <= 'd0;
    else if(ri_trig_reply || r_check_cnt == 0)
        r_checksum <= 16'h0001 + ri_trig_seq;
    else if(r_check_cnt == 1)
        r_checksum <= r_checksum[31:16] + r_checksum[15:0];
    else if(r_check_cnt == 2)
        r_checksum <= r_checksum[31:16] + r_checksum[15:0];
    else if(r_check_cnt == 3)
        r_checksum <= ~r_checksum;
    else
        r_checksum <= r_checksum;
end

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        r_icmp_cnt <= 'd0;
    else if(r_icmp_cnt == P_ICMP_LEN - 1)
        r_icmp_cnt <= 'd0;
    else if(r_check_cnt == 3 || r_icmp_cnt)
        r_icmp_cnt <= r_icmp_cnt + 'd1;
    else
        r_icmp_cnt <= r_icmp_cnt;
end

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        ro_icmp_data <= 'd0;
    else case (r_icmp_cnt)
        0       : ro_icmp_data <= P_ICMP_REPLY_TYPE;//类型 8:请求回显 0:回显应答
        1       : ro_icmp_data <= 'd0;//代码 0：回复应答
        2       : ro_icmp_data <= r_checksum[15:8];//校验和
        3       : ro_icmp_data <= r_checksum[7 :0];
        4       : ro_icmp_data <= 8'h00;//标识符 16'h0001
        5       : ro_icmp_data <= 8'h01;
        6       : ro_icmp_data <= ri_trig_seq[15:8];//序号
        7       : ro_icmp_data <= ri_trig_seq[7 :0];
        default : ro_icmp_data <= 'd0;//数据
    endcase 
end
 
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        ro_icmp_valid <= 'd0;
    else if(ro_icmp_last)
        ro_icmp_valid <= 'd0;
    else if(r_check_cnt == 3)
        ro_icmp_valid <= 'd1;
    else
        ro_icmp_valid <= ro_icmp_valid;
end

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)
        ro_icmp_last <= 'd0;
    else if(r_icmp_cnt == P_ICMP_LEN - 1)
        ro_icmp_last <= 'd1;
    else
        ro_icmp_last <= 'd0;
end


endmodule
