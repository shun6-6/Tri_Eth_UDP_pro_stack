`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/18 14:46:42
// Design Name: 
// Module Name: XCKU040_TOP
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


module XCKU040_TOP(
    input           i_rxc           ,
    input  [3:0]    i_rxd           ,
    input           i_rx_ctrl       ,
    output          o_txc           ,
    output [3:0]    o_txd           ,
    output          o_tx_ctrl       ,
    output          RESETn          
);

localparam      P_SEND_LEN  = 100;
assign          RESETn = 1;

wire            w_user_clk          ;
wire            w_user_rst          ;

wire [7 :0]     w_recv_udp_data     ;
wire [15:0]     w_recv_udp_len      ;
wire            w_recv_udp_last     ;
wire            w_recv_udp_valid    ;
wire [7 :0]     w_gmii_tx_data      ;
wire            w_gmii_tx_valid     ;
wire [7 :0]     w_gmii_rx_data      ;
wire            w_gmii_rx_valid     ;
wire [1 :0]     w_speed             ;
wire            w_link              ;

wire            w_send_ready        ;
reg  [7 :0]     r_send_udp_data     ;
reg  [15:0]     r_send_udp_len      ;
reg             r_send_udp_last     ;
reg             r_send_udp_valid    ;

reg  [15:0]     r_send_cnt          ;
// reg  [15:0]     r_gap_cnt           ;
// reg  [15:0]     r_pkg_cnt=0         ;
reg  [15:0]     r_start_cnt         ;

rst_gen_module#(
    .P_RST_CYCLE            (100) 
)rst_gen_module_u0(
    .i_clk                  (w_user_clk ),
    .o_rst                  (w_user_rst )
);


ila_udp ila_udp_u0 (
	.clk    (w_user_clk         ), // input wire clk
	.probe0 (w_recv_udp_data    ), // input wire [7:0]  probe0  
	.probe1 (w_recv_udp_len     ), // input wire [15:0]  probe1 
	.probe2 (w_recv_udp_last    ), // input wire [0:0]  probe2 
	.probe3 (w_recv_udp_valid   ), // input wire [0:0]  probe3 
	.probe4 (w_gmii_tx_data     ), // input wire [7:0]  probe4 
	.probe5 (w_gmii_tx_valid    ), // input wire [0:0]  probe5 
	.probe6 (w_gmii_rx_data     ), // input wire [7:0]  probe6 
	.probe7 (w_gmii_rx_valid    ), // input wire [0:0]  probe7 
	.probe8 (w_speed            ), // input wire [1:0]  probe8 
	.probe9 (w_link             ), // input wire [0:0]  probe9
    .probe10(w_send_ready       ),
    .probe11(r_send_udp_data    ), // input wire [7:0]  probe11 
	.probe12(r_send_udp_len     ), // input wire [15:0]  probe12 
	.probe13(r_send_udp_last    ), // input wire [0:0]  probe13 
	.probe14(r_send_udp_valid   ) // input wire [0:0]  probe14
);

UDP_Stack_TOP#(
    .P_DST_UDP_PORT         (16'h8080                               )   ,
    .P_SRC_UDP_PORT         (16'h8080                               )   ,
    .P_DST_IP               ({8'd192,8'd168,8'd100,8'd99}              )   ,
    .P_SRC_IP               ({8'd192,8'd168,8'd100,8'd100}              )   ,
    .P_SRC_MAC              ({8'h01,8'h02,8'h03,8'h04,8'h05,8'h06}  )   ,
    .P_DEST_MAC             ({8'h00,8'h00,8'h00,8'h00,8'h00,8'h00}  )   ,
    .P_CRC_CHECK            (1                                      )       
)UDP_Stack_TOP_u0(
    .i_clk                  (w_user_clk ),
    .i_rst                  (w_user_rst ),

    .i_dst_udp_port         (0),
    .i_dst_udp_valid        (0),
    .i_src_udp_port         (0),
    .i_src_udp_valid        (0),
    .i_dst_ip               (0),
    .i_dst_ip_valid         (0),
    .i_src_ip               (0),
    .i_src_ip_valid         (0),
    .i_src_mac              (0),
    .i_src_mac_valid        (0),
    .i_dest_mac             (0),
    .i_dest_mac_valid       (0),

    .i_send_udp_data        (r_send_udp_data    ),
    .i_send_udp_len         (r_send_udp_len     ),
    .i_send_udp_last        (r_send_udp_last    ),
    .i_send_udp_valid       (r_send_udp_valid   ),
    .o_send_ready           (w_send_ready       ),

    .o_recv_udp_data        (w_recv_udp_data    ),
    .o_recv_udp_len         (w_recv_udp_len     ),
    .o_recv_udp_last        (w_recv_udp_last    ),
    .o_recv_udp_valid       (w_recv_udp_valid   ),

    .o_recv_src_mac         (),
    .o_recv_src_mac_valid   (),
    .o_crc_error            (),
    .o_crc_valid            (),
    .o_recv_src_ip          (),
    .o_recv_src_valid       (),

    .i_gmii_data            (w_gmii_rx_data     ),
    .i_gmii_valid           (w_gmii_rx_valid    ),
    .o_gmii_data            (w_gmii_tx_data     ),
    .o_gmii_valid           (w_gmii_tx_valid    ) 
);

GMII2RGMII_drive GMII2RGMII_drive_u0(
    .i_rxc                  (i_rxc              ),
    .i_rxd                  (i_rxd              ),
    .i_rx_ctrl              (i_rx_ctrl          ),
    .o_txc                  (o_txc              ),
    .o_txd                  (o_txd              ),
    .o_tx_ctrl              (o_tx_ctrl          ),

    //.i_speed1000            (),
    .i_udp_stack_clk        (w_user_clk         ),
    .i_gmii_tx_data         (w_gmii_tx_data     ),
    .i_gmii_tx_valid        (w_gmii_tx_valid    ),
    .o_gmii_rx_data         (w_gmii_rx_data     ),
    .o_gmii_rx_valid        (w_gmii_rx_valid    ),

    .o_speed                (w_speed            ),
    .o_link                 (w_link             ),
    .o_user_clk             (w_user_clk         ) 
);



always @(posedge w_user_clk or posedge w_user_rst)begin
    if(w_user_rst)
        r_start_cnt <= 'd0;
    else if(r_start_cnt == 100)
        r_start_cnt <= r_start_cnt;
    else
        r_start_cnt <= r_start_cnt + 1;
end

always @(posedge w_user_clk or posedge w_user_rst)begin
    if(w_user_rst)
        r_send_cnt <= 'd0;
    else if(r_send_cnt == P_SEND_LEN - 1)
        r_send_cnt <= 'd0;
    else if(r_send_udp_valid)
        r_send_cnt <= r_send_cnt + 1;
    else
        r_send_cnt <= r_send_cnt;
end

always @(posedge w_user_clk or posedge w_user_rst)begin
    if(w_user_rst)
        r_send_udp_valid <= 'd0;
    else if(r_send_cnt == P_SEND_LEN - 1)
        r_send_udp_valid <= 'd0;
    else if(r_start_cnt == 100 && w_send_ready)
        r_send_udp_valid <= 'd1;
    else
        r_send_udp_valid <= r_send_udp_valid;
end

always @(posedge w_user_clk or posedge w_user_rst)begin
    if(w_user_rst)
        r_send_udp_data <= 'd0;
    else if(r_send_udp_valid)
        r_send_udp_data <= r_send_udp_data + 1;
    else
        r_send_udp_data <= 'd0;
end

always @(posedge w_user_clk or posedge w_user_rst)begin
    if(w_user_rst)
        r_send_udp_last <= 'd0;
    else if(r_send_cnt == P_SEND_LEN - 2)
        r_send_udp_last <= 'd1;
    else
        r_send_udp_last <= 'd0;
end

always @(posedge w_user_clk or posedge w_user_rst)begin
    if(w_user_rst)
        r_send_udp_len <= 'd0;
    else
        r_send_udp_len <= P_SEND_LEN;
end



endmodule
