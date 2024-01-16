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
    input           i_speed1000 ,
    input  [7 :0]   i_tx_data   ,
    input           i_tx_valid  , 

    output [7 :0]   o_rx_data   ,
    output          o_rx_valid  ,      
    output          o_rx_end    
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
/******************************wire*******************************/
wire            w_rxc_bufio         ;
wire            w_rxc_idelay        ;
wire            w_rxc_bufr          ;
wire [3 :0]     w_rxd_ibuf          ;
wire            w_rx_ctrl_ibuf      ;
wire [7 :0]     w_recv_data         ;
wire [1 :0]     w_recv_valid        ;

wire [3 :0]     w_send_d1           ;//上升沿数据
wire [3 :0]     w_send_d2           ;//下降沿数据
wire            w_send_valid_d1     ;
wire            w_send_valid_d2     ;    
/******************************component**************************/
//================rgmii rx=====================//
IDELAYE3 #(
   .CASCADE             ("NONE"         ),  // Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
   .DELAY_FORMAT        ("TIME"         ),  // Units of the DELAY_VALUE (COUNT, TIME)
   .DELAY_SRC           ("IDATAIN"      ),  // Delay input (DATAIN, IDATAIN)
   .DELAY_TYPE          ("FIXED"        ),  // Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
   .DELAY_VALUE         (0              ),  // Input delay value setting
   .IS_CLK_INVERTED     (1'b0           ),  // Optional inversion for CLK
   .IS_RST_INVERTED     (1'b0           ),  // Optional inversion for RST
   .REFCLK_FREQUENCY    (300.0          ),  // IDELAYCTRL clock input frequency in MHz (200.0-800.0)
   .SIM_DEVICE          ("ULTRASCALE"   ),  // Set the device version for simulation functionality (ULTRASCALE)
   .UPDATE_MODE         ("ASYNC"        )   // Determines when updates to the delay will take effect (ASYNC, MANUAL, SYNC)
)
IDELAYE3_inst (
   .CASC_OUT            (               ),  // 1-bit output: Cascade delay output to ODELAY input cascade
   .CNTVALUEOUT         (               ),  // 9-bit output: Counter value output
   .DATAOUT             (w_rxc_idelay   ),  // 1-bit output: Delayed data output
   .CASC_IN             (               ),  // 1-bit input: Cascade delay input from slave ODELAY CASCADE_OUT
   .CASC_RETURN         (               ),  // 1-bit input: Cascade delay returning from slave ODELAY DATAOUT
   .CE                  (               ),  // 1-bit input: Active-High enable increment/decrement input
   .CLK                 (               ),  // 1-bit input: Clock input
   .CNTVALUEIN          (               ),  // 9-bit input: Counter value input
   .DATAIN              (               ),  // 1-bit input: Data input from the logic
   .EN_VTC              (               ),  // 1-bit input: Keep delay constant over VT
   .IDATAIN             (w_rxc_bufio    ),  // 1-bit input: Data input from the IOBUF
   .INC                 (               ),  // 1-bit input: Increment / Decrement tap delay input
   .LOAD                (               ),  // 1-bit input: Load DELAY_VALUE input
   .RST                 (               )   // 1-bit input: Asynchronous Reset to the DELAY_VALUE
);

BUFIO BUFIO_rxc (
   .O(w_rxc_bufio   ), 
   .I(i_rxc         )  
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
    .C               (w_rxc_idelay          ),// 1-bit input: High-speed clock
    .CB              (~w_rxc_idelay         ),// 1-bit input: Inversion of High-speed clock C
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
.C               (w_rxc_idelay          ),
.CB              (~w_rxc_idelay         ),
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
   .I           (w_rxc_bufio)  // 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
);
//================rgmii tx=====================//
OBUF OBUF_txc (
   .O(o_txc         ), // 1-bit output: Buffer output (connect directly to top-level port)
   .I(w_rxc_bufr    )  // 1-bit input: Buffer input
);

genvar txd_i;
generate
for(txd_i = 0; txd_i < 4; txd_i = txd_i + 1)begin:txd_oddr
//如果不是千兆，则上升沿和下降沿发送数据一致
    assign w_send_d1[txd_i] =   i_speed1000 ? i_tx_data[txd_i]   : 
                                r_10_100_tx_cnt == 0 ? i_tx_data[3:0] : ri_tx_data[7:4];
    assign w_send_d2[txd_i] =   i_speed1000 ? i_tx_data[txd_i+4] : 
                                r_10_100_tx_cnt == 0 ? i_tx_data[3:0] : ri_tx_data[7:4];

    ODDRE1 #(
    .IS_C_INVERTED   (1'b0              ), // Optional inversion for C
    .IS_D1_INVERTED  (1'b0              ), // Unsupported, do not use
    .IS_D2_INVERTED  (1'b0              ), // Unsupported, do not use
    .SIM_DEVICE      ("ULTRASCALE"      ), // Set the device version for simulation functionality (ULTRASCALE)
    .SRVAL           (1'b0              )  // Initializes the ODDRE1 Flip-Flops to the specified value (1'b0, 1'b1)
    )
    ODDRE1_txd (
    .Q               (o_txd[txd_i]      ), // 1-bit output: Data output to IOB
    .C               (w_rxc_bufr        ), // 1-bit input: High-speed clock input
    .D1              (w_send_d1         ), // 1-bit input: Parallel data input 1
    .D2              (w_send_d2         ), // 1-bit input: Parallel data input 2
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
   .C               (w_rxc_bufr         ), // 1-bit input: High-speed clock input
   .D1              (w_send_valid       ), // 1-bit input: Parallel data input 1
   .D2              (w_send_valid       ), // 1-bit input: Parallel data input 2
   .SR              (0                  )  // 1-bit input: Active-High Async Reset
);

/******************************assign*****************************/
assign o_rx_data    =   ro_rx_data  ;
assign o_rx_valid   =   ro_rx_valid ;
assign o_rx_end     =   ro_rx_end   ;

assign o_rxc        =   w_rxc_bufr  ;
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
        ro_rx_data <= {ro_rx_data[3:0],w_recv_data[3:0]};
end

always @(posedge w_rxc_bufr)begin
    if(&w_recv_valid)
        ro_rx_end <= 'd0;
    else
        ro_rx_end <= 'd1;
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
