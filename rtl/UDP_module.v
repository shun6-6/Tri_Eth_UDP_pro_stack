`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: UDP_module
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


module UDP_module#(
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

    output  [7 :0]  o_udp_data      ,
    output  [15:0]  o_udp_len       ,
    output          o_udp_last      ,
    output          o_udp_valid     ,
    /*----ip port----*/
    output  [7 :0]  o_ip_type       ,
    output  [7 :0]  o_ip_data       ,
    output  [15:0]  o_ip_len        ,
    output          o_ip_last       ,
    output          o_ip_valid      ,

    input   [7 :0]  i_ip_data       ,
    input   [15:0]  i_ip_len        ,
    input           i_ip_last       ,
    input           i_ip_valid      
);

UDP_RX#(
    .P_DST_UDP_PORT     (P_DST_UDP_PORT),
    .P_SRC_UDP_PORT     (P_SRC_UDP_PORT)
)UDP_RX_u0(
    .i_clk              (i_clk              ),
    .i_rst              (i_rst              ),
    .i_dst_udp_port     (i_dst_udp_port     ),
    .i_dst_udp_valid    (i_dst_udp_valid    ),
    .i_src_udp_port     (i_src_udp_port     ),
    .i_src_udp_valid    (i_src_udp_valid    ),
    .o_udp_data         (o_udp_data         ),
    .o_udp_len          (o_udp_len          ),
    .o_udp_last         (o_udp_last         ),
    .o_udp_valid        (o_udp_valid        ),
    .i_ip_data          (i_ip_data          ),
    .i_ip_len           (i_ip_len           ),
    .i_ip_last          (i_ip_last          ),
    .i_ip_valid         (i_ip_valid         ) 
);

UDP_TX#(
    .P_DST_UDP_PORT     (P_DST_UDP_PORT),
    .P_SRC_UDP_PORT     (P_SRC_UDP_PORT)
)UDP_TX_u0(
    .i_clk              (i_clk              ),
    .i_rst              (i_rst              ),
    .i_dst_udp_port     (i_dst_udp_port     ),
    .i_dst_udp_valid    (i_dst_udp_valid    ),
    .i_src_udp_port     (i_src_udp_port     ),
    .i_src_udp_valid    (i_src_udp_valid    ),
    .i_send_udp_data    (i_send_udp_data    ),
    .i_send_udp_len     (i_send_udp_len     ),
    .i_send_udp_last    (i_send_udp_last    ),
    .i_send_udp_valid   (i_send_udp_valid   ),
    .o_ip_type          (o_ip_type          ),
    .o_ip_data          (o_ip_data          ),
    .o_ip_len           (o_ip_len           ),
    .o_ip_last          (o_ip_last          ),
    .o_ip_valid         (o_ip_valid         ) 
);

endmodule
