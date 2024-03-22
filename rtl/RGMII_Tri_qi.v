`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/23 19:42:11
// Design Name: 
// Module Name: RGMII_Tri_qi
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


module RGMII_Tri_qi(
 /*--------rgmii port--------*/
    input           i_rxc           ,
    input  [3 :0]   i_rxd           ,
    input           i_rx_ctl        ,

    output          o_txc           ,
    output [3 :0]   o_txd           ,
    output          o_tx_ctl        ,

    /*--------data port--------*/
    input           idelay_clk      ,
    input  dly_clk,

    output          o_rxc           ,
    input   [7 :0]  i_send_data     ,
    input           i_send_valid    ,

    output  [7 :0]  o_rec_data      ,
    output          o_rec_valid     ,
    output          o_rec_end       ,

    output  [1:0]   o_speed         ,
    output          o_link          
);
//parameter define
parameter IDELAY_VALUE = 0;

reg  [7 :0]         ri_send_data =0 ;
reg                 ri_send_valid=0 ;
reg  [7 :0]         ro_rec_data = 0 ; 
reg                 ro_rec_valid= 0 ; 
reg                 ro_rec_end  = 0 ; 
reg                 r_cnt_10_100= 0 ; 
reg                 r_tx_cnt_10_100 = 0 ;
reg  [1 :0]         ro_speed=0      ;
reg                 ro_link =0      ;
reg  [1 :0]         r_rec_valid=0   ;

wire                w_rxc_bufr      ;
wire                w_rxc_bufio     ;
wire                w_rxc_idelay    ;
wire [3 :0]         w_rxd_ibuf      ;
wire                w_rx_ctl_ibuf   ;
wire [7 :0]         w_rec_data      ;
wire [1 :0]         w_rec_valid     ;
wire [3 :0]         w_send_d1       ;
wire [3 :0]         w_send_d2       ;
wire                w_send_valid    ;
wire                i_speed1000     ;
wire                w_txc           ;  
wire                w_txc_90        ;
wire w_rxc_bufr_dly;

wire [3:0] w_rxd_idly;
wire w_rx_ctl_idly;

assign w_txc    = ~w_rxc_bufr;
assign o_rxc    = w_rxc_bufr;
assign o_speed  = ro_speed   ;
assign o_link   = ro_link    ;
assign i_speed1000 = 1;
assign o_rec_data  = ro_rec_data ;
assign o_rec_valid = ro_rec_valid;
assign o_rec_end   = ro_rec_end  ;

// ila_rgmii ila_rgmii_u0 (
// 	.clk(w_txc), // input wire clk

// 	.probe0(ri_send_data ), // input wire [7:0]  probe0  
// 	.probe1(ri_send_valid), // input wire [0:0]  probe1 
// 	.probe2(w_send_d1), // input wire [3:0]  probe2 
// 	.probe3(w_send_d2), // input wire [3:0]  probe3 
// 	.probe4(w_send_valid) // input wire [0:0]  probe4
// );


OBUF #(
   .DRIVE           (12             ),   // Specify the output drive strength
   .IOSTANDARD      ("DEFAULT"      ), // Specify the output I/O standard
   .SLEW            ("SLOW"         ) // Specify the output slew rate
) OBUF_inst (
   .O               (o_txc          ),     // Buffer output (connect directly to top-level port)
   .I               (w_txc       )      // Buffer input 
);

BUFIO BUFIO_inst (
   .O               (w_rxc_bufio   ),
   .I               (i_rxc  ) 
);

BUFG BUFG_inst (
    .O(w_rxc_bufr), // 1-bit output: Clock output
    .I(i_rxc)  // 1-bit input: Clock input
 );


genvar rxd_i;
generate for(rxd_i = 0 ;rxd_i < 4 ;rxd_i = rxd_i + 1)
begin
    IBUF #(
        .IBUF_LOW_PWR    ("TRUE"        ),  
        .IOSTANDARD      ("DEFAULT"     )
    ) 
    IBUF_U 
    (
        .O               (w_rxd_ibuf[rxd_i] ),     // Buffer output
        .I               (i_rxd[rxd_i]      )      // Buffer input (connect directly to top-level port)
    );

(* IODELAY_GROUP = "rgmii_rx_delay" *) 
IDELAYCTRL  IDELAYCTRL_inst (
    .RDY(),                      // 1-bit output: Ready output
    .REFCLK(idelay_clk),         // 1-bit input: Reference clock input
    .RST(1'b0)                   // 1-bit input: Active high reset input
);

//rgmii_rx_ctl???????????????
(* IODELAY_GROUP = "rgmii_rx_delay" *) 
IDELAYE2 #(
  .IDELAY_TYPE     ("FIXED"),           // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
  .IDELAY_VALUE    (IDELAY_VALUE),      // Input delay tap setting (0-31)
  .REFCLK_FREQUENCY(200.0)              // IDELAYCTRL clock input frequency in MHz 
)
u_delay_rxd (
  .CNTVALUEOUT     (),                  // 5-bit output: Counter value output
  .DATAOUT         (w_rxd_idly[rxd_i]),// 1-bit output: Delayed data output
  .C               (1'b0),              // 1-bit input: Clock input
  .CE              (1'b0),              // 1-bit input: enable increment/decrement
  .CINVCTRL        (1'b0),              // 1-bit input: Dynamic clock inversion input
  .CNTVALUEIN      (5'b0),              // 5-bit input: Counter value input
  .DATAIN          (1'b0),              // 1-bit input: Internal delay data input
  .IDATAIN         (w_rxd_ibuf[rxd_i]),      // 1-bit input: Data input from the I/O
  .INC             (1'b0),              // 1-bit input: Increment / Decrement tap delay
  .LD              (1'b0),              // 1-bit input: Load IDELAY_VALUE input
  .LDPIPEEN        (1'b0),              // 1-bit input: Enable PIPELINE register
  .REGRST          (1'b0)               // 1-bit input: Active-high reset tap-delay input
);

    IDDR #(
        .DDR_CLK_EDGE   ("SAME_EDGE_PIPELINED"    ),
        .INIT_Q1        (1'b0                     ),
        .INIT_Q2        (1'b0                     ),
        .SRTYPE         ("SYNC"                   ) 
    )   
    IDDR_u0     
    (   
        .Q1             (w_rec_data[rxd_i]          ), // 1-bit output for positive edge of clock 
        .Q2             (w_rec_data[rxd_i +4]       ), // 1-bit output for negative edge of clock
        .C              (w_rxc_bufio                ),  
        .CE             (1                          ),
        .D              (w_rxd_idly[rxd_i]          ),  
        .R              (0                          ),   
        .S              (0                          )   
    );
end
endgenerate

IBUF #(
    .IBUF_LOW_PWR    ("TRUE"                    ),  
    .IOSTANDARD      ("DEFAULT"                 )
)           
IBUF_U          
(           
    .O               (w_rx_ctl_ibuf             ),     // Buffer output
    .I               (i_rx_ctl                  )      // Buffer input (connect directly to top-level port)
);

(* IODELAY_GROUP = "rgmii_rx_delay" *) 
IDELAYE2 #(
  .IDELAY_TYPE     ("FIXED"),           // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
  .IDELAY_VALUE    (IDELAY_VALUE),      // Input delay tap setting (0-31)
  .REFCLK_FREQUENCY(200.0)              // IDELAYCTRL clock input frequency in MHz 
)
u_delay_rx_ctrl (
  .CNTVALUEOUT     (),                  // 5-bit output: Counter value output
  .DATAOUT         (w_rx_ctl_idly),// 1-bit output: Delayed data output
  .C               (1'b0),              // 1-bit input: Clock input
  .CE              (1'b0),              // 1-bit input: enable increment/decrement
  .CINVCTRL        (1'b0),              // 1-bit input: Dynamic clock inversion input
  .CNTVALUEIN      (5'b0),              // 5-bit input: Counter value input
  .DATAIN          (1'b0),              // 1-bit input: Internal delay data input
  .IDATAIN         (w_rx_ctl_ibuf),      // 1-bit input: Data input from the I/O
  .INC             (1'b0),              // 1-bit input: Increment / Decrement tap delay
  .LD              (1'b0),              // 1-bit input: Load IDELAY_VALUE input
  .LDPIPEEN        (1'b0),              // 1-bit input: Enable PIPELINE register
  .REGRST          (1'b0)               // 1-bit input: Active-high reset tap-delay input
);

IDDR #(
    .DDR_CLK_EDGE   ("SAME_EDGE_PIPELINED"      ),
    .INIT_Q1        (1'b0                       ),
    .INIT_Q2        (1'b0                       ),
    .SRTYPE         ("SYNC"                     ) 
)   
IDDR_u0     
(   
    .Q1             (w_rec_valid[0]             ), // 1-bit output for positive edge of clock 
    .Q2             (w_rec_valid[1]             ), // 1-bit output for negative edge of clock
    .C              (w_rxc_bufio                ),  
    .CE             (1                          ),
    .D              (w_rx_ctl_idly              ),  
    .R              (0                          ),   
    .S              (0                          )   
);
  
always@(posedge w_rxc_bufr)
begin
    if(!i_speed1000 && (&w_rec_valid))
        r_cnt_10_100 <= r_cnt_10_100 + 1;
    else 
        r_cnt_10_100 <= 'd0;
end 

always@(posedge w_rxc_bufr)
begin
    if(&w_rec_valid && i_speed1000)
        ro_rec_valid <= 'd1;
    else 
        ro_rec_valid <= r_cnt_10_100;
end

always@(posedge w_rxc_bufr)
begin
    if(i_speed1000)
        ro_rec_data <= w_rec_data;
    else 
        ro_rec_data <= {w_rec_data[3:0],ro_rec_data[7:4]};
end

always@(posedge w_rxc_bufr)
begin
    r_rec_valid <= w_rec_valid;
end

always@(posedge w_rxc_bufr)
begin
    if(!w_rec_valid && r_rec_valid)
        ro_rec_end <= 'd1;
    else 
        ro_rec_end <= 'd0;
end

always@(posedge w_rxc_bufr)
begin
    if(w_rec_valid == 'd0) begin
        ro_speed <= w_rec_data[2:1];
        ro_link  <= w_rec_data[0];
    end else begin
        ro_speed <= ro_speed;
        ro_link  <= ro_link ;
    end
end

/*---------rgmii send--------*/
always@(posedge w_rxc_bufr)
begin
    ri_send_data  <= i_send_data;
    ri_send_valid <= i_send_valid;
end

always@(posedge w_rxc_bufr)
begin
    if(i_send_valid)
        r_tx_cnt_10_100 <= r_tx_cnt_10_100 + 1;
    else 
        r_tx_cnt_10_100 <= 'd0;
end



genvar txd_i;
generate for(txd_i = 0 ;txd_i < 4 ; txd_i = txd_i + 1)
begin
    assign w_send_d1[txd_i] = i_speed1000 ? i_send_data[txd_i]     :  
                              r_tx_cnt_10_100 == 0 ? i_send_data[txd_i] : ri_send_data[txd_i + 4];

    assign w_send_d2[txd_i] = i_speed1000 ? i_send_data[txd_i + 4] : 
                              r_tx_cnt_10_100 == 0 ? i_send_data[txd_i] : ri_send_data[txd_i + 4];

    ODDR #(
        .DDR_CLK_EDGE    ("OPPOSITE_EDGE"       ),
        .INIT            (1'b0                  ),
        .SRTYPE          ("SYNC"                ) 
    ) 
    ODDR_u 
    (
        .Q               (o_txd[txd_i]          ),  
        .C               (w_txc                 ),
        .CE              (1                     ),
        .D1              (w_send_d1[txd_i]      ),    
        .D2              (w_send_d2[txd_i]      ),    
        .R               (0                     ),
        .S               (0                     ) 
    );
end
endgenerate

assign w_send_valid = i_speed1000 ? i_send_valid : i_send_valid | ri_send_valid;

ODDR#(
    .DDR_CLK_EDGE    ("OPPOSITE_EDGE"       ),
    .INIT            (1'b0                  ),
    .SRTYPE          ("SYNC"                ) 
)
ODDR_uu0 
(
    .Q               (o_tx_ctl              ),  
    .C               (w_txc                 ),
    .CE              (1                     ),
    .D1              (w_send_valid          ),    
    .D2              (w_send_valid          ),    
    .R               (0                     ),
    .S               (0                     ) 
);


endmodule

