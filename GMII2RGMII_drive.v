`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/15 11:32:21
// Design Name: 
// Module Name: GMII2RGMII_drive
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


module GMII2RGMII_drive(
    /*-----GMII port-----*/
    input           i_rxc           ,
    input  [3:0]    i_rxd           ,
    input           i_rx_ctrl       ,
    output          o_txc           ,
    output [3:0]    o_txd           ,
    output          o_tx_ctrl       ,
    /*-----UDP stack port-----*/
    //output          o_rxc           ,
    input           i_speed1000     ,
    input           i_udp_stack_clk ,
    input  [7 :0]   i_gmii_tx_data  ,
    input           i_gmii_tx_valid ,
    output [7 :0]   o_gmii_rx_data  ,
    output          o_gmii_rx_valid 
);

wire [7 :0]     w_rx_data   ;
wire            w_rx_valid  ;
wire            w_rx_end    ;

wire [7 :0]     w_tx_data   ;
wire            w_tx_valid  ;

wire            w_rxc       ;//经过bufr的rxc时钟

RGMII_Tri RGMII_Tri_u0(
    .i_rxc              (i_rxc          ),
    .i_rxd              (i_rxd          ),
    .i_rx_ctrl          (i_rx_ctrl      ),
    .o_txc              (o_txc          ),
    .o_txd              (o_txd          ),
    .o_tx_ctrl          (o_tx_ctrl      ),

    .o_rxc              (w_rxc          ),
    .i_speed1000        (i_speed1000    ),
    .i_tx_data          (w_tx_data      ),
    .i_tx_valid         (w_tx_valid     ), 

    .o_rx_data          (w_rx_data      ),
    .o_rx_valid         (w_rx_valid     ),        
    .o_rx_end           (w_rx_end       )
);

RGMII_RAM RGMII_RAM_u0(
    .i_udp_stack_clk    (i_udp_stack_clk),
    .i_gmii_tx_data     (i_gmii_tx_data ),
    .i_gmii_tx_valid    (i_gmii_tx_valid),
    .o_gmii_rx_data     (o_gmii_rx_data ),
    .o_gmii_rx_valid    (o_gmii_rx_valid),

    .i_rxc              (w_rxc          ),
    .o_tx_data          (w_tx_data      ),
    .o_tx_valid         (w_tx_valid     ),  

    .i_speed1000        (i_speed1000    ),
    .i_rx_data          (w_rx_data      ),
    .i_rx_valid         (w_rx_valid     ),      
    .i_rx_end           (w_rx_end       )
);

endmodule
