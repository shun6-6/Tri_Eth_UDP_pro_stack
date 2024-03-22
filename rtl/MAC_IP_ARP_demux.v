`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/12 20:59:11
// Design Name: 
// Module Name: MAC_IP_ARP_demux
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


module MAC_IP_ARP_demux(
    input           i_clk           ,
    input           i_rst           ,

    input  [15:0]   i_pre_type      ,
    input  [7 :0]   i_pre_data      ,
    input           i_pre_valid     ,
    input           i_pre_last      ,

    output [7 :0]   o_ip_data       ,
    output          o_ip_valid      ,
    output          o_ip_last       ,
    output [7 :0]   o_arp_data      ,
    output          o_arp_valid     ,
    output          o_arp_last      
);
/******************************function***************************/

/******************************parameter**************************/
localparam      P_TYPE_IP  = 16'h0800;
localparam      P_TYPE_ARP = 16'h0806;
/******************************port*******************************/

/******************************machine****************************/

/******************************reg********************************/
reg  [7 :0]     ro_ip_data      ;
reg             ro_ip_valid     ;
reg             ro_ip_last      ;
reg  [7 :0]     ro_arp_data     ;
reg             ro_arp_valid    ;
reg             ro_arp_last     ;
/******************************wire*******************************/

/******************************component**************************/

/******************************assign*****************************/
assign  o_ip_data   = ro_ip_data    ;
assign  o_ip_valid  = ro_ip_valid   ;
assign  o_ip_last   = ro_ip_last    ;
assign  o_arp_data  = ro_arp_data   ;
assign  o_arp_valid = ro_arp_valid  ;
assign  o_arp_last  = ro_arp_last   ;
/******************************always*****************************/
always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)begin
        ro_arp_data  <= 'd0;
        ro_arp_valid <= 'd0;
        ro_arp_last  <= 'd0;        
    end
    else if(i_pre_valid && i_pre_type == P_TYPE_ARP)begin
        ro_arp_data  <= i_pre_data ;
        ro_arp_valid <= i_pre_valid;
        ro_arp_last  <= i_pre_last ;         
    end
    else begin
        ro_arp_data  <= 'd0;
        ro_arp_valid <= 'd0;
        ro_arp_last  <= 'd0;         
    end
end

always @(posedge i_clk or posedge i_rst) begin
    if(i_rst)begin
        ro_ip_data  <= 'd0;
        ro_ip_valid <= 'd0;
        ro_ip_last  <= 'd0;        
    end
    else if(i_pre_valid && i_pre_type == P_TYPE_IP)begin
        ro_ip_data  <= i_pre_data ;
        ro_ip_valid <= i_pre_valid;
        ro_ip_last  <= i_pre_last ;         
    end
    else begin
        ro_ip_data  <= 'd0;
        ro_ip_valid <= 'd0;
        ro_ip_last  <= 'd0;         
    end
end

endmodule
