`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: ICMP_module
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


module ICMP_module(
    input               i_clk           ,
    input               i_rst           ,
    
    /*----send port----*/
    output [7 :0]       o_icmp_data     ,
    output [15:0]       o_icmp_len      ,
    output              o_icmp_last     ,
    output              o_icmp_valid    ,
    /*----recv port----*/
    input  [7 :0]       i_icmp_data     ,
    input  [15:0]       i_icmp_len      ,
    input               i_icmp_last     ,
    input               i_icmp_valid     
);

wire                 w_trig_reply   ;
wire    [15:0]       w_trig_seq     ;

ICMP_TX ICMP_TX_u0(
    .i_clk           (i_clk         ),
    .i_rst           (i_rst         ),

    .i_trig_reply    (w_trig_reply  ),
    .i_trig_seq      (w_trig_seq    ),

    .o_icmp_data     (o_icmp_data   ),
    .o_icmp_len      (o_icmp_len    ),
    .o_icmp_last     (o_icmp_last   ),
    .o_icmp_valid    (o_icmp_valid  ) 
);

ICMP_RX ICMP_RX_u0(
    .i_clk           (i_clk         ),
    .i_rst           (i_rst         ),

    .i_icmp_data     (i_icmp_data   ),
    .i_icmp_len      (i_icmp_len    ),
    .i_icmp_last     (i_icmp_last   ),
    .i_icmp_valid    (i_icmp_valid  ),

    .o_trig_reply    (w_trig_reply  ),
    .o_trig_seq      (w_trig_seq    ) 
);

endmodule
