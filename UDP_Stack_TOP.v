`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: UDP_Stack_TOP
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


module UDP_Stack_TOP#(
    parameter           P_DST_UDP_PORT  =   16'h8080                                ,
    parameter           P_SRC_UDP_PORT  =   16'h8080                                ,
    parameter           P_DST_IP        =   {8'd192,8'd168,8'd1,8'd0}               ,
    parameter           P_SRC_IP        =   {8'd192,8'd168,8'd1,8'd1}               ,
    parameter           P_SRC_MAC       =   {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00}   ,
    parameter           P_DEST_MAC      =   {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00}   ,
    parameter           P_CRC_CHECK     =   1
)(
    input               i_clk               ,
    input               i_rst               ,
    /*----info port----*/
    input   [15:0]      i_dst_udp_port      ,
    input               i_dst_udp_valid     ,
    input   [15:0]      i_src_udp_port      ,
    input               i_src_udp_valid     ,
    input   [31:0]      i_dst_ip            ,
    input               i_dst_ip_valid      ,
    input   [31:0]      i_src_ip            ,
    input               i_src_ip_valid      ,
    input   [47:0]      i_src_mac           ,
    input               i_src_mac_valid     ,
    input   [47:0]      i_dest_mac          ,
    input               i_dest_mac_valid    ,
    /*----data port----*/
    input   [7 :0]      i_send_udp_data     ,
    input   [15:0]      i_send_udp_len      ,
    input               i_send_udp_last     ,
    input               i_send_udp_valid    ,
    output              o_send_ready        ,

    output  [7 :0]      o_recv_udp_data     ,
    output  [15:0]      o_recv_udp_len      ,
    output              o_recv_udp_last     ,
    output              o_recv_udp_valid    ,

    output [47:0]       o_recv_src_mac      ,
    output              o_recv_src_mac_valid,
    output              o_crc_error         ,
    output              o_crc_valid         ,
    output [31:0]       o_recv_src_ip       ,
    output              o_recv_src_valid    ,
    /*----GMII port----*/
    input   [7 :0]      i_gmii_data         ,
    input               i_gmii_valid        ,
    output  [7 :0]      o_gmii_data         ,
    output              o_gmii_valid          
);

wire [7 :0]     w_udp2ip_type       ;
wire [7 :0]     w_udp2ip_data       ;
wire [15:0]     w_udp2ip_len        ;
wire            w_udp2ip_last       ;
wire            w_udp2ip_valid      ;
wire [7 :0]     w_ip2udp_data       ;
wire [15:0]     w_ip2udp_len        ;
wire            w_ip2udp_last       ;
wire            w_ip2udp_valid      ;

wire [7 :0]     w_send_icmp_data    ;
wire [15:0]     w_send_icmp_len     ;
wire            w_send_icmp_last    ;
wire            w_send_icmp_valid   ;
wire [7 :0]     w_recv_icmp_data    ;
wire [15:0]     w_recv_icmp_len     ;
wire            w_recv_icmp_last    ;
wire            w_recv_icmp_valid   ;

wire [7 :0]     w_udp_icmp_data     ;
wire            w_udp_icmp_valid    ;
wire            w_udp_icmp_last     ;
wire [15:0]     w_udp_icmp_len      ;
wire [15:0]     w_udp_icmp_type     ;
wire            w_nxt_udp_icmp_stop ;

wire [47:0]     w_arp_recv_dst_mac  ;
wire [31:0]     w_arp_recv_dst_ip   ;
wire            w_arp_recv_dst_valid;

wire [7 :0]     w_arp2mac_data      ;
wire            w_arp2mac_last      ;
wire            w_arp2mac_valid     ;
wire [7 :0]     w_mac2arp_data      ;
wire            w_mac2arp_last      ;
wire            w_mac2arp_valid     ;

wire [15:0]     w_ip2mac_type       ;
wire [7 :0]     w_ip2mac_data       ;
wire [15:0]     w_ip2mac_len        ;
wire            w_ip2mac_last       ;
wire            w_ip2mac_valid      ;
wire [7 :0]     w_mac2ip_data       ;
wire            w_mac2ip_last       ;
wire            w_mac2ip_valid      ;

wire [7 :0]     w_ip_arp_data       ;
wire            w_ip_arp_valid      ;
wire            w_ip_arp_last       ;
wire [15:0]     w_ip_arp_len        ;
wire [15:0]     w_ip_arp_type       ;
wire            w_nxt_ip_arp_stop   ;

wire [31:0]     w_seek_ip           ;
wire            w_seek_valid        ;
wire [47:0]     w_tab_dst_mac       ;
wire            w_tab_dst_valid     ;

assign o_send_ready = !(w_nxt_udp_icmp_stop & w_nxt_ip_arp_stop);

UDP_module#(
    .P_DST_UDP_PORT     (P_DST_UDP_PORT),
    .P_SRC_UDP_PORT     (P_SRC_UDP_PORT)
) UDP_module_u0(
    .i_clk                  (i_clk              ),
    .i_rst                  (i_rst              ),

    .i_dst_udp_port         (i_dst_udp_port     ),
    .i_dst_udp_valid        (i_dst_udp_valid    ),
    .i_src_udp_port         (i_src_udp_port     ),
    .i_src_udp_valid        (i_src_udp_valid    ),

    .i_send_udp_data        (i_send_udp_data    ),
    .i_send_udp_len         (i_send_udp_len     ),
    .i_send_udp_last        (i_send_udp_last    ),
    .i_send_udp_valid       (i_send_udp_valid   ),

    .o_udp_data             (o_recv_udp_data    ),
    .o_udp_len              (o_recv_udp_len     ),
    .o_udp_last             (o_recv_udp_last    ),
    .o_udp_valid            (o_recv_udp_valid   ),

    .o_ip_type              (w_udp2ip_type      ),
    .o_ip_data              (w_udp2ip_data      ),
    .o_ip_len               (w_udp2ip_len       ),
    .o_ip_last              (w_udp2ip_last      ),
    .o_ip_valid             (w_udp2ip_valid     ),
    .i_ip_data              (w_ip2udp_data      ),
    .i_ip_len               (w_ip2udp_len       ),
    .i_ip_last              (w_ip2udp_last      ),
    .i_ip_valid             (w_ip2udp_valid     ) 
);

ICMP_module ICMP_module_u0(
    .i_clk                  (i_clk              ),
    .i_rst                  (i_rst              ),

    .o_icmp_data            (w_send_icmp_data   ),
    .o_icmp_len             (w_send_icmp_len    ),
    .o_icmp_last            (w_send_icmp_last   ),
    .o_icmp_valid           (w_send_icmp_valid  ),
    .i_icmp_data            (w_recv_icmp_data   ),
    .i_icmp_len             (w_recv_icmp_len    ),
    .i_icmp_last            (w_recv_icmp_last   ),
    .i_icmp_valid           (w_recv_icmp_valid  ) 
);

Data_2to1_arbiter Data_arbiter_UDP_ICMP(
    .i_clk                  (i_clk              ),
    .i_rst                  (i_rst              ),

    .i_data_a               (w_send_icmp_data   ), 
    .i_valid_a              (w_send_icmp_valid  ),  
    .i_last_a               (w_send_icmp_last   ), 
    .i_len_a                (w_send_icmp_len    ),
    .i_type_a               (16'd1              ),
   
    .i_data_b               (w_udp2ip_data      ),
    .i_valid_b              (w_udp2ip_valid     ),
    .i_last_b               (w_udp2ip_last      ),
    .i_len_b                (w_udp2ip_len       ),
    .i_type_b               (16'd17             ),
    .o_nxt_frame_stop       (w_nxt_udp_icmp_stop),
 
    .o_data                 (w_udp_icmp_data    ),
    .o_valid                (w_udp_icmp_valid   ),
    .o_last                 (w_udp_icmp_last    ),
    .o_len                  (w_udp_icmp_len     ),
    .o_type                 (w_udp_icmp_type    ) 
);

IP_module#(
    .P_DST_IP               (P_DST_IP),
    .P_SRC_IP               (P_SRC_IP)
) IP_module_u0(
    .i_clk                  (i_clk              ),
    .i_rst                  (i_rst              ),

    .i_dst_ip               (i_dst_ip           ),
    .i_dst_ip_valid         (i_dst_ip_valid     ),
    .i_src_ip               (i_src_ip           ),
    .i_src_ip_valid         (i_src_ip_valid     ),
    
    .i_send_data            (w_udp_icmp_data    ),
    .i_send_type            (w_udp_icmp_type[7:0]),
    .i_send_len             (w_udp_icmp_len     ),
    .i_send_last            (w_udp_icmp_last    ),
    .i_send_valid           (w_udp_icmp_valid   ),

    .o_mac_type             (w_ip2mac_type      ),
    .o_mac_data             (w_ip2mac_data      ),
    .o_mac_len              (w_ip2mac_len       ),
    .o_mac_last             (w_ip2mac_last      ),
    .o_mac_valid            (w_ip2mac_valid     ),
  
    .o_udp_data             (w_ip2udp_data      ),
    .o_udp_len              (w_ip2udp_len       ),
    .o_udp_last             (w_ip2udp_last      ),
    .o_udp_valid            (w_ip2udp_valid     ),
    .o_icmp_data            (w_recv_icmp_data   ),
    .o_icmp_len             (w_recv_icmp_len    ),
    .o_icmp_last            (w_recv_icmp_last   ),
    .o_icmp_valid           (w_recv_icmp_valid  ),
    .o_recv_src_ip          (o_recv_src_ip      ),
    .o_recv_src_valid       (o_recv_src_valid   ),

    .o_seek_ip              (w_seek_ip          ),
    .o_seek_valid           (w_seek_valid       ),

    .i_mac_data             (w_mac2ip_data      ),
    .i_mac_valid            (w_mac2ip_valid     ),
    .i_mac_last             (w_mac2ip_last      ) 
);

ARP_module#(
    .P_DST_IP               (P_DST_IP ),
    .P_SRC_IP               (P_SRC_IP ),
    .P_SRC_MAC              (P_SRC_MAC)
)ARP_module_u0(
    .i_clk                  (i_clk                  ),
    .i_rst                  (i_rst                  ),

    .i_dst_ip               (i_dst_ip               ), 
    .i_dst_ip_valid         (i_dst_ip_valid         ),
    .i_src_ip               (i_src_ip               ), 
    .i_src_ip_valid         (i_src_ip_valid         ),
    .i_src_mac              (i_src_mac              ), 
    .i_src_mac_valid        (i_src_mac_valid        ),  

    .i_seek_ip              (w_seek_ip              ),
    .i_seek_valid           (w_seek_valid           ),
    .o_tab_dst_mac          (w_tab_dst_mac          ),
    .o_tab_dst_valid        (w_tab_dst_valid        ),

    .o_mac_data             (w_arp2mac_data         ),
    .o_mac_last             (w_arp2mac_last         ),
    .o_mac_valid            (w_arp2mac_valid        ),
    .i_mac_data             (w_mac2arp_data         ),
    .i_mac_last             (w_mac2arp_last         ),
    .i_mac_valid            (w_mac2arp_valid        )
);

Data_2to1_arbiter Data_arbiter_IP_ARP(
    .i_clk                  (i_clk              ),
    .i_rst                  (i_rst              ),

    .i_data_a               (w_arp2mac_data     ),
    .i_valid_a              (w_arp2mac_valid    ),
    .i_last_a               (w_arp2mac_last     ),
    .i_len_a                (16'd46             ),
    .i_type_a               (16'h0806           ),
 
    .i_data_b               (w_ip2mac_data      ),
    .i_valid_b              (w_ip2mac_valid     ),
    .i_last_b               (w_ip2mac_last      ),
    .i_len_b                (w_ip2mac_len       ),
    .i_type_b               (16'h0800           ),
    .o_nxt_frame_stop       (w_nxt_ip_arp_stop  ),

    .o_data                 (w_ip_arp_data      ),
    .o_valid                (w_ip_arp_valid     ),
    .o_last                 (w_ip_arp_last      ),
    .o_len                  (w_ip_arp_len       ),
    .o_type                 (w_ip_arp_type      ) 
);

Ethernet_MAC#(
    .P_SRC_MAC   (P_SRC_MAC  ),
    .P_DEST_MAC  (P_DEST_MAC ),
    .P_CRC_CHECK (P_CRC_CHECK)
) Ethernet_MAC_u0(
    .i_clk                  (i_clk              ),
    .i_rst                  (i_rst              ),
  
    .i_src_mac              (i_src_mac          ),
    .i_src_mac_valid        (i_src_mac_valid    ),
    .i_dest_mac             (w_tab_dst_mac      ),
    .i_dest_mac_valid       (w_tab_dst_valid    ),

    .i_send_type            (w_ip_arp_type      ),
    .i_send_data            (w_ip_arp_data      ),
    .i_send_len             (w_ip_arp_len       ),
    .i_send_last            (w_ip_arp_last      ),
    .i_send_valid           (w_ip_arp_valid     ),

    .o_ip_data              (w_mac2ip_data      ),
    .o_ip_valid             (w_mac2ip_valid     ),
    .o_ip_last              (w_mac2ip_last      ),
    .o_arp_data             (w_mac2arp_data     ),
    .o_arp_valid            (w_mac2arp_valid    ),
    .o_arp_last             (w_mac2arp_last     ),

    .o_recv_src_mac         (o_recv_src_mac      ),
    .o_recv_src_mac_valid   (o_recv_src_mac_valid),
    .o_crc_error            (o_crc_error         ),
    .o_crc_valid            (o_crc_valid         ),

    .o_gmii_data            (o_gmii_data        ),
    .o_gmii_valid           (o_gmii_valid       ),
    .i_gmii_data            (i_gmii_data        ),
    .i_gmii_valid           (i_gmii_valid       ) 
);

endmodule
