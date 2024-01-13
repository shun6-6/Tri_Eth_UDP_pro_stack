`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: Ethernet_MAC
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


module Ethernet_MAC#(
    parameter       P_SRC_MAC   = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
    parameter       P_DEST_MAC  = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
    parameter       P_CRC_CHECK = 1
)(
    input           i_clk               ,
    input           i_rst               ,
    //tx
    /*----info port----*/   
    input  [47:0]   i_src_mac           ,
    input           i_src_mac_valid     ,
    input  [47:0]   i_dest_mac          ,
    input           i_dest_mac_valid    ,
    /*----data port----*/   
    input  [15:0]   i_send_type         ,
    input  [7 :0]   i_send_data         ,
    input  [15:0]   i_send_len          ,
    input           i_send_last         ,
    input           i_send_valid        ,
    /*----GMII port----*/
    output [7 :0]   o_gmii_data         ,
    output          o_gmii_valid        ,
    //rx
    /*----data port----*/   
    output [7 :0]   o_ip_data           ,
    output          o_ip_valid          ,
    output          o_ip_last           ,
    output [7 :0]   o_arp_data          ,
    output          o_arp_valid         ,
    output          o_arp_last          ,

    output [47:0]   o_recv_src_mac      ,
    output          o_recv_src_mac_valid,
    output          o_crc_error         ,
    output          o_crc_valid         ,
    /*----GMII port----*/
    input  [7 :0]   i_gmii_data         ,
    input           i_gmii_valid         
    );


wire    [15:0]  w_mac_post_type     ;
wire    [7 :0]  w_mac_post_data     ;
wire            w_mac_post_valid    ;
wire            w_mac_post_last     ;
wire    [15:0]  w_crc_post_type     ;
wire    [7 :0]  w_crc_post_data     ;
wire            w_crc_post_valid    ;
wire            w_crc_post_last     ;

MAC_TX#(
    .P_SRC_MAC   (P_SRC_MAC  ),
    .P_DEST_MAC  (P_DEST_MAC ),
    .P_CRC_CHECK (P_CRC_CHECK)
)MAC_TX_u0(
    .i_clk                  (i_clk                  ),
    .i_rst                  (i_rst                  ),
            
    .i_src_mac              (i_src_mac              ),
    .i_src_mac_valid        (i_src_mac_valid        ),
    .i_dest_mac             (i_dest_mac             ),
    .i_dest_mac_valid       (i_dest_mac_valid       ),
            
    .i_send_type            (i_send_type            ),
    .i_send_data            (i_send_data            ),
    .i_send_len             (i_send_len             ),
    .i_send_last            (i_send_last            ),
    .i_send_valid           (i_send_valid           ),
    
    .o_gmii_data            (o_gmii_data            ),
    .o_gmii_valid           (o_gmii_valid           ) 
);

MAC_RX#(
    .P_SRC_MAC   (P_SRC_MAC  ),
    .P_DEST_MAC  (P_DEST_MAC ),
    .P_CRC_CHECK (P_CRC_CHECK)
)MAC_RX_u0(
    .i_clk                  (i_clk                  ),
    .i_rst                  (i_rst                  ),

    .i_src_mac              (i_src_mac              ),
    .i_src_mac_valid        (i_src_mac_valid        ),
    .i_dest_mac             (i_dest_mac             ),
    .i_dest_mac_valid       (i_dest_mac_valid       ),

    .o_post_type            (w_mac_post_type        ),
    .o_post_data            (w_mac_post_data        ),
    .o_post_valid           (w_mac_post_valid       ),
    .o_post_last            (w_mac_post_last        ),

    .o_recv_src_mac         (o_recv_src_mac         ),
    .o_recv_src_mac_valid   (o_recv_src_mac_valid   ),
    .o_crc_error            (o_crc_error            ),
    .o_crc_valid            (o_crc_valid            ),
        
    .i_gmii_data            (i_gmii_data            ),
    .i_gmii_valid           (i_gmii_valid           ) 
);

CRC_data_process CRC_data_process_u0(
    .i_clk                  (i_clk                  ),
    .i_rst                  (i_rst                  ),
    .i_pre_type             (w_mac_post_type        ),
    .i_pre_data             (w_mac_post_data        ),
    .i_pre_valid            (w_mac_post_valid       ),
    .i_pre_last             (w_mac_post_last        ),
    .i_pre_crc_error        (o_crc_error            ),
    .i_pre_crc_valid        (o_crc_valid            ),
    .o_post_type            (w_crc_post_type        ),
    .o_post_data            (w_crc_post_data        ),
    .o_post_valid           (w_crc_post_valid       ),
    .o_post_last            (w_crc_post_last        ) 
);

MAC_IP_ARP_demux MAC_IP_ARP_demux_u0(
    .i_clk                  (i_clk                  ),
    .i_rst                  (i_rst                  ),

    .i_pre_type             (w_crc_post_type        ),
    .i_pre_data             (w_crc_post_data        ),
    .i_pre_valid            (w_crc_post_valid       ),
    .i_pre_last             (w_crc_post_last        ),

    .o_ip_data              (o_ip_data              ),
    .o_ip_valid             (o_ip_valid             ),
    .o_ip_last              (o_ip_last              ),
    .o_arp_data             (o_arp_data             ),
    .o_arp_valid            (o_arp_valid            ),
    .o_arp_last             (o_arp_last             ) 
);

endmodule
