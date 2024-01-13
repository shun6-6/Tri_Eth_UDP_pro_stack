`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: IP_module
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


module IP_module#(
    parameter       P_DST_IP = {8'd192,8'd168,8'd1,8'd0},
    parameter       P_SRC_IP = {8'd192,8'd168,8'd1,8'd1}
)(
    input           i_clk               ,
    input           i_rst               ,
    /*----info port----*/   
    input  [31:0]   i_dst_ip            ,
    input           i_dst_ip_valid      ,
    input  [31:0]   i_src_ip            ,
    input           i_src_ip_valid      ,
    //==========tx============
    /*----data port----*/   
    input  [7 :0]   i_send_data         ,
    input  [7 :0]   i_send_type         ,
    input  [15:0]   i_send_len          ,
    input           i_send_last         ,
    input           i_send_valid        ,
    /*----arp port----*/
    output [31:0]   o_seek_ip           ,
    output          o_seek_valid        ,
    //===========rx==========
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
    input           i_mac_last          ,
    output [15:0]   o_mac_type          ,
    output [7 :0]   o_mac_data          ,
    output [15:0]   o_mac_len           ,
    output          o_mac_last          ,
    output          o_mac_valid           
    );

IP_TX#(
    .P_DST_IP           (P_DST_IP),
    .P_SRC_IP           (P_SRC_IP)
)IP_TX_u0(
    .i_clk              (i_clk              ),
    .i_rst              (i_rst              ),

    .i_dst_ip           (i_dst_ip           ),
    .i_dst_ip_valid     (i_dst_ip_valid     ),
    .i_src_ip           (i_src_ip           ),
    .i_src_ip_valid     (i_src_ip_valid     ),

    .i_send_data        (i_send_data        ),
    .i_send_type        (i_send_type        ),
    .i_send_len         (i_send_len         ),
    .i_send_last        (i_send_last        ),
    .i_send_valid       (i_send_valid       ),

    .o_seek_ip          (o_seek_ip          ),
    .o_seek_valid       (o_seek_valid       ),

    .o_mac_type         (o_mac_type         ),
    .o_mac_data         (o_mac_data         ),
    .o_mac_len          (o_mac_len          ),
    .o_mac_last         (o_mac_last         ),
    .o_mac_valid        (o_mac_valid        ) 
);

IP_RX#(
    .P_DST_IP           (P_DST_IP),
    .P_SRC_IP           (P_SRC_IP)
)IP_RX_u0(
    .i_clk              (i_clk              ),
    .i_rst              (i_rst              ),

    .i_dst_ip           (i_dst_ip           ),
    .i_dst_ip_valid     (i_dst_ip_valid     ),
    .i_src_ip           (i_src_ip           ),
    .i_src_ip_valid     (i_src_ip_valid     ),

    .o_udp_data         (o_udp_data         ),
    .o_udp_len          (o_udp_len          ),
    .o_udp_last         (o_udp_last         ),
    .o_udp_valid        (o_udp_valid        ),
    .o_icmp_data        (o_icmp_data        ),
    .o_icmp_len         (o_icmp_len         ),
    .o_icmp_last        (o_icmp_last        ),
    .o_icmp_valid       (o_icmp_valid       ),
    .o_recv_src_ip      (o_recv_src_ip      ),
    .o_recv_src_valid   (o_recv_src_valid   ),

    .i_mac_data         (i_mac_data         ),
    .i_mac_valid        (i_mac_valid        ),
    .i_mac_last         (i_mac_last         ) 
);

endmodule
