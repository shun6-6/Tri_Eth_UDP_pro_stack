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

/******************************wire*******************************/
wire        w_rxc_bufio     ;
wire [3:0]  w_rxd_ibuf      ;
wire        w_rx_ctrl_ibuf  ;
/******************************component**************************/
IDELAYE3 #(
   .CASCADE             ("NONE"         ),          // Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
   .DELAY_FORMAT        ("TIME"         ),     // Units of the DELAY_VALUE (COUNT, TIME)
   .DELAY_SRC           ("IDATAIN"      ),     // Delay input (DATAIN, IDATAIN)
   .DELAY_TYPE          ("FIXED"        ),      // Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
   .DELAY_VALUE         (0              ),           // Input delay value setting
   .IS_CLK_INVERTED     (1'b0           ),    // Optional inversion for CLK
   .IS_RST_INVERTED     (1'b0           ),    // Optional inversion for RST
   .REFCLK_FREQUENCY    (300.0          ),  // IDELAYCTRL clock input frequency in MHz (200.0-800.0)
   .SIM_DEVICE          ("ULTRASCALE"   ), // Set the device version for simulation functionality (ULTRASCALE)
   .UPDATE_MODE         ("ASYNC"        )      // Determines when updates to the delay will take effect (ASYNC, MANUAL, SYNC)
)
IDELAYE3_inst (
   .CASC_OUT            (CASC_OUT   ),      // 1-bit output: Cascade delay output to ODELAY input cascade
   .CNTVALUEOUT         (CNTVALUEOUT),      // 9-bit output: Counter value output
   .DATAOUT             (DATAOUT    ),      // 1-bit output: Delayed data output
   .CASC_IN             (CASC_IN    ),      // 1-bit input: Cascade delay input from slave ODELAY CASCADE_OUT
   .CASC_RETURN         (CASC_RETURN),      // 1-bit input: Cascade delay returning from slave ODELAY DATAOUT
   .CE                  (CE         ),      // 1-bit input: Active-High enable increment/decrement input
   .CLK                 (CLK        ),      // 1-bit input: Clock input
   .CNTVALUEIN          (CNTVALUEIN ),      // 9-bit input: Counter value input
   .DATAIN              (DATAIN     ),      // 1-bit input: Data input from the logic
   .EN_VTC              (EN_VTC     ),      // 1-bit input: Keep delay constant over VT
   .IDATAIN             (IDATAIN    ),      // 1-bit input: Data input from the IOBUF
   .INC                 (INC        ),      // 1-bit input: Increment / Decrement tap delay input
   .LOAD                (LOAD       ),      // 1-bit input: Load DELAY_VALUE input
   .RST                 (RST        )       // 1-bit input: Asynchronous Reset to the DELAY_VALUE
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
end
endgenerate

IBUF #(
   .CCIO_EN("TRUE") 
)
IBUF_rxctrl (
   .O(w_rx_ctrl_ibuf    ), 
   .I(i_rx_ctrl         )  
);

/******************************assign*****************************/

/******************************always*****************************/



endmodule
