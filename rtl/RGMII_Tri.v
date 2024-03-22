`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/15 11:32:21
// Design Name: 
// Module Name: RGMII_Tri
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


module RGMII_Tri(
    /*-----GMII port-----*/
    input           i_rxc       ,
    input  [3:0]    i_rxd       ,
    input           i_rx_ctrl   ,
    output          o_txc       ,
    output [3:0]    o_txd       ,
    output          o_tx_ctrl   ,
    /*-----data port-----*/
    output          o_rxc       ,
    //input           i_speed1000 ,
    input  [7 :0]   i_tx_data   ,
    input           i_tx_valid  , 

    output [7 :0]   o_rx_data   ,
    output          o_rx_valid  ,      
    output          o_rx_end    ,

    output [1 :0]   o_speed     ,
    output          o_link      
);
/******************************function***************************/

/******************************parameter**************************/

/******************************port*******************************/

/******************************machine****************************/

/******************************reg********************************/
reg  [7 :0]     ro_rx_data      = 0     ;
reg             ro_rx_valid     = 0     ;
reg             ro_rx_end       = 0     ;
reg             r_10_100_rx_cnt = 0     ; 

reg  [7 :0]     ri_tx_data      = 0     ;
reg             ri_tx_valid     = 0     ;
reg             r_10_100_tx_cnt = 0     ; 

reg  [1 :0]     ro_speed        = 0     ;
reg             ro_link         = 0     ;
/******************************wire*******************************/
wire            w_rxc_bufio         ;
wire            w_rxc_bufio_90         ;
wire            w_rxc_idelay        ;
wire            w_rxc_bufr          ;
wire [3 :0]     w_rxd_ibuf          ;
wire            w_rx_ctrl_ibuf      ;
wire [7 :0]     w_recv_data         ;
wire [1 :0]     w_recv_valid        ;

wire [3 :0]     w_send_d1           ;//上升沿数�?
wire [3 :0]     w_send_d2           ;//下降沿数�?
wire            w_send_valid_d1     ;
wire            w_send_valid_d2     ; 
wire            w_send_valid        ;   

wire            w_txc               ;

wire            i_speed1000         ;
assign          i_speed1000 = 1     ;

wire            w_txc_90            ;
wire  locked;
wire  locked_1;
/******************************component**************************/

//================rgmii rx=====================//

ila_rgmii ila_rgmii_u0 (
	.clk(w_txc), // input wire clk

	.probe0(ri_tx_data ), // input wire [7:0]  probe0  
	.probe1(ri_tx_valid), // input wire [0:0]  probe1 
	.probe2(w_send_d1), // input wire [3:0]  probe2 
	.probe3(w_send_d2), // input wire [3:0]  probe3 
	.probe4(w_send_valid) // input wire [0:0]  probe4
);

// ila_rgmii ila_rgmii_u1 (
// 	.clk(w_rxc_bufr), // input wire clk

// 	.probe0(o_rx_data ), // input wire [7:0]  probe0  
// 	.probe1(w_recv_data), // input wire [0:0]  probe1 
// 	.probe2(0), // input wire [3:0]  probe2 
// 	.probe3(0), // input wire [3:0]  probe3 
// 	.probe4(0) // input wire [0:0]  probe4
// );

BUFIO BUFIO_rxc (
   .O(w_rxc_bufio   ), 
   .I(i_rxc         )  
);

clk_wiz_0 clk_wiz_0_u1
(
    .clk_out1   (w_rxc_bufio_90   ),    
    .locked     (locked_1     ),     
    .clk_in1    (w_rxc_bufio      )      
);

genvar rxd_i;
generate
for(rxd_i = 0; rxd_i < 4; rxd_i = rxd_i + 1)begin:txd_ibuf
    IBUF #(
       .CCIO_EN("TRUE") 
    )
    IBUF_rxd (
       .O(w_rxd_ibuf[rxd_i]  ), 
       .I(i_rxd[rxd_i]       )  
    );

    IDDRE1 #(
    .DDR_CLK_EDGE    ("SAME_EDGE_PIPELINED" ),// IDDRE1 mode (OPPOSITE_EDGE, SAME_EDGE, SAME_EDGE_PIPELINED)
    .IS_CB_INVERTED  (1'b0                  ),// Optional inversion for CB
    .IS_C_INVERTED   (1'b0                  ) // Optional inversion for C
    )
    IDDRE1_rxd (
    .Q1              (w_recv_data[rxd_i]    ),// 1-bit output: Registered parallel output 1
    .Q2              (w_recv_data[rxd_i+4]  ),// 1-bit output: Registered parallel output 2
    .C               (w_rxc_bufio_90          ),// 1-bit input: High-speed clock
    .CB              (~w_rxc_bufio_90         ),// 1-bit input: Inversion of High-speed clock C
    .D               (w_rxd_ibuf[rxd_i]     ),// 1-bit input: Serial Data Input
    .R               (0                     ) // 1-bit input: Active-High Async Reset
    );

end
endgenerate

IBUF #(
   .CCIO_EN("TRUE") 
)
IBUF_rxctrl (
   .O(w_rx_ctrl_ibuf    ), 
   .I(i_rx_ctrl         )  
);

IDDRE1 #(
.DDR_CLK_EDGE    ("SAME_EDGE_PIPELINED" ),
.IS_CB_INVERTED  (1'b0                  ),
.IS_C_INVERTED   (1'b0                  ) 
)
IDDRE1_rxctrl (
.Q1              (w_recv_valid[0]       ),
.Q2              (w_recv_valid[1]       ),
.C               (w_rxc_bufio_90          ),
.CB              (~w_rxc_bufio_90         ),
.D               (w_rx_ctrl_ibuf        ),
.R               (0                     ) 
);

BUFR #(
   .BUFR_DIVIDE ("BYPASS"   ), // Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
   .SIM_DEVICE  ("7SERIES"  )  // Must be set to "7SERIES" 
)
BUFR_rxc (
   .O           (w_rxc_bufr ), // 1-bit output: Clock output port
   .CE          (1          ), // 1-bit input: Active high, clock enable (Divided modes only)
   .CLR         (0          ), // 1-bit input: Active high, asynchronous clear (Divided modes only)
   .I           (i_rxc)  // 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
);
//================rgmii tx=====================//
clk_wiz_0 clk_wiz_0_u0
(
    .clk_out1   (w_txc_90   ),    
    .locked     (locked     ),     
    .clk_in1    (w_txc      )      
);

assign w_txc = w_rxc_bufr;
OBUF OBUF_txc (
   .O(o_txc         ), // 1-bit output: Buffer output (connect directly to top-level port)
   .I(w_txc_90      )  // 1-bit input: Buffer input
);

genvar txd_i;
generate
for(txd_i = 0; txd_i < 4; txd_i = txd_i + 1)begin:txd_oddr
//如果不是千兆，则上升沿和下降沿发送数据一�?
    assign w_send_d1[txd_i] =   i_speed1000 ? i_tx_data[txd_i]   : 
                                r_10_100_tx_cnt == 0 ? i_tx_data[txd_i] : ri_tx_data[txd_i+4];
    assign w_send_d2[txd_i] =   i_speed1000 ? i_tx_data[txd_i+4] : 
                                r_10_100_tx_cnt == 0 ? i_tx_data[txd_i] : ri_tx_data[txd_i+4];

    ODDRE1 #(
    .IS_C_INVERTED   (1'b0              ), // Optional inversion for C
    .IS_D1_INVERTED  (1'b0              ), // Unsupported, do not use
    .IS_D2_INVERTED  (1'b0              ), // Unsupported, do not use
    .SIM_DEVICE      ("ULTRASCALE"      ), // Set the device version for simulation functionality (ULTRASCALE)
    .SRVAL           (1'b0              )  // Initializes the ODDRE1 Flip-Flops to the specified value (1'b0, 1'b1)
    )
    ODDRE1_txd (
    .Q               (o_txd[txd_i]      ), // 1-bit output: Data output to IOB
    .C               (w_txc             ), // 1-bit input: High-speed clock input
    .D1              (w_send_d1[txd_i]  ), // 1-bit input: Parallel data input 1
    .D2              (w_send_d2[txd_i]  ), // 1-bit input: Parallel data input 2
    .SR              (0                 )  // 1-bit input: Active-High Async Reset
    );
end
endgenerate

assign w_send_valid  = i_speed1000 ? i_tx_valid : (i_tx_valid | ri_tx_valid);


ODDRE1 #(
   .IS_C_INVERTED   (1'b0               ), // Optional inversion for C
   .IS_D1_INVERTED  (1'b0               ), // Unsupported, do not use
   .IS_D2_INVERTED  (1'b0               ), // Unsupported, do not use
   .SIM_DEVICE      ("ULTRASCALE"       ), // Set the device version for simulation functionality (ULTRASCALE)
   .SRVAL           (1'b0               )  // Initializes the ODDRE1 Flip-Flops to the specified value (1'b0, 1'b1)
)
ODDRE1_txctrl (
   .Q               (o_tx_ctrl          ), // 1-bit output: Data output to IOB
   .C               (w_txc              ), // 1-bit input: High-speed clock input
   .D1              (w_send_valid       ), // 1-bit input: Parallel data input 1
   .D2              (w_send_valid       ), // 1-bit input: Parallel data input 2
   .SR              (0                  )  // 1-bit input: Active-High Async Reset
);

/******************************assign*****************************/
assign o_rx_data    =   ro_rx_data  ;
assign o_rx_valid   =   ro_rx_valid ;
assign o_rx_end     =   ro_rx_end   ;

assign o_rxc        =   w_rxc_bufr  ;

assign o_speed      =   ro_speed    ;
assign o_link       =   ro_link     ;
/******************************always*****************************/
always @(posedge w_rxc_bufr)begin
    if((&w_recv_valid) && !i_speed1000)
        r_10_100_rx_cnt <= r_10_100_rx_cnt + 'd1;
    else
        r_10_100_rx_cnt <= 'd0;
end

always @(posedge w_rxc_bufr)begin
    if((&w_recv_valid) && i_speed1000)
        ro_rx_valid <= 'd1;
    else
        ro_rx_valid <= r_10_100_rx_cnt;
end

always @(posedge w_rxc_bufr)begin
    if(i_speed1000)
        ro_rx_data <= w_recv_data;
    else
        ro_rx_data <= {w_recv_data[3:0],ro_rx_data[7:4]};
end

always @(posedge w_rxc_bufr)begin
    if(&w_recv_valid)
        ro_rx_end <= 'd0;
    else
        ro_rx_end <= 'd1;
end

always @(posedge w_rxc_bufr)begin
    if(w_recv_valid == 'd0)begin
        ro_speed <= w_recv_data[2:1];
        ro_link  <= w_recv_data[0];        
    end
    else begin
        ro_speed <= ro_speed;
        ro_link  <= ro_link ;
    end
end
//==================gmii tx====================//
always @(posedge w_rxc_bufr)begin
    ri_tx_data  <= i_tx_data ;
    ri_tx_valid <= i_tx_valid;
end

always @(posedge w_rxc_bufr)begin
    if(i_tx_valid)
        r_10_100_tx_cnt <= r_10_100_tx_cnt + 'd1;
    else
        r_10_100_tx_cnt <= 'd0;
end

endmodule
