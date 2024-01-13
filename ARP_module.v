`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: ARP_module
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


module ARP_module#(
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

    input   [31:0]  i_seek_ip       ,
    input           i_seek_valid    ,
    output  [47:0]  o_tab_dst_mac   ,
    output          o_tab_dst_valid ,
    /*----MAC port----*/     
    output  [7 :0]  o_mac_data      ,
    output          o_mac_last      ,
    output          o_mac_valid     ,

    input   [7 :0]  i_mac_data      ,
    input           i_mac_last      ,
    input           i_mac_valid     
);

wire            w_trig_reply    ;
wire [47:0]     w_dst_mac       ;
wire [31:0]     w_dst_ip        ;
wire            w_dst_valid     ;

ARP_TX#(
    .P_DST_IP           (P_DST_IP ),
    .P_SRC_IP           (P_SRC_IP ),
    .P_SRC_MAC          (P_SRC_MAC)
)ARP_TX_u0(
    .i_clk              (i_clk          ),
    .i_rst              (i_rst          ),  

    .i_dst_ip           (i_dst_ip       ), 
    .i_dst_ip_valid     (i_dst_ip_valid ),
    .i_src_ip           (i_src_ip       ), 
    .i_src_ip_valid     (i_src_ip_valid ),
    .i_src_mac          (i_src_mac      ), 
    .i_src_mac_valid    (i_src_mac_valid),  

    .i_trig_reply       (w_trig_reply   ),
    .i_active_req       (0), 

    .o_mac_data         (o_mac_data     ),
    .o_mac_last         (o_mac_last     ),
    .o_mac_valid        (o_mac_valid    )
);

ARP_RX#(
    .P_DST_IP           (P_DST_IP ),
    .P_SRC_IP           (P_SRC_IP ),
    .P_SRC_MAC          (P_SRC_MAC)
)ARP_RX_u0(
    .i_clk              (i_clk          ),
    .i_rst              (i_rst          ),

    .o_dst_mac          (w_dst_mac      ),
    .o_dst_ip           (w_dst_ip       ),
    .o_dst_valid        (w_dst_valid    ),
    .i_src_ip           (i_src_ip       ), 
    .i_src_ip_valid     (i_src_ip_valid ),

    .o_trig_reply       (w_trig_reply   ),

    .i_mac_data         (i_mac_data     ),
    .i_mac_last         (i_mac_last     ),
    .i_mac_valid        (i_mac_valid    )
);

ARP_table ARP_table_u0(
    .i_clk              (i_clk          ),
    .i_rst              (i_rst          ),

    .i_seek_ip          (i_seek_ip      ),
    .i_seek_valid       (i_seek_valid   ),
    .i_updata_ip        (w_dst_ip       ),
    .i_updata_mac       (w_dst_mac      ),
    .i_updata_valid     (w_dst_valid    ),

    .o_active_mac       (o_tab_dst_mac  ),
    .o_active_valid     (o_tab_dst_valid) 
);


endmodule
