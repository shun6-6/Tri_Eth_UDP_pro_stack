`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/15 11:32:21
// Design Name: 
// Module Name: RGMII_RAM
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


module RGMII_RAM(
    /*-----UDP stack port-----*/
    input           i_udp_stack_clk ,
    input  [7 :0]   i_gmii_tx_data  ,
    input           i_gmii_tx_valid ,
    output [7 :0]   o_gmii_rx_data  ,
    output          o_gmii_rx_valid ,
    /*-----RGMII port-----*/
    input           i_rxc           ,
    output [7 :0]   o_tx_data       ,
    output          o_tx_valid      ,  

    input           i_speed1000     ,
    input  [7 :0]   i_rx_data       ,
    input           i_rx_valid      ,      
    input           i_rx_end        
);
/******************************function***************************/

/******************************parameter**************************/

/******************************port*******************************/

/******************************machine****************************/

/******************************reg********************************/
reg  [10:0]     r_ram_addr_a = 0    ;
reg  [10:0]     r_ram_addr_b = 0    ;
reg             r_ram_en_b   = 0    ;
reg             r_fifo_wren  = 0    ;
reg             r_fifo_rden  = 0    ;

reg  [10:0]     r_recv_len   = 0    ;
reg             ri_rx_valid  = 0    ;
reg             r_read_run   = 0    ;
reg  [15:0]     r_read_cnt   = 0    ;
/******************************wire*******************************/
wire [7 :0]     w_ram_dout_b        ;
wire [10:0]     w_fifo_dout         ;
wire            w_fifo_full         ;
wire            w_fifo_empty        ;
/******************************component**************************/
RAM_8x1526 RAM_8x1526_u0 (
  .clka     (i_rxc              ), 
  .ena      (i_rx_valid         ), 
  .wea      (i_rx_valid         ), 
  .addra    (r_ram_addr_a       ), 
  .dina     (i_rx_data          ), 
  .douta    (), 

  .clkb     (i_udp_stack_clk    ), 
  .enb      (r_ram_en_b         ), 
  .web      (0), 
  .addrb    (r_ram_addr_b       ), 
  .dinb     (0), 
  .doutb    (w_ram_dout_b       ) 
);

FIFO_ASYNC_11X64 FIFO_ASYNC_11X64_U0 (
  .wr_clk   (i_rxc              ),
  .rd_clk   (i_udp_stack_clk    ),
  .din      (r_recv_len         ),
  .wr_en    (r_fifo_wren        ),
  .rd_en    (r_fifo_rden        ),
  .dout     (w_fifo_dout        ),
  .full     (w_fifo_full        ),
  .empty    (w_fifo_empty       )
);

/******************************assign*****************************/

/******************************always*****************************/
//==============rgmii clock=================//
always @(posedge i_rxc)begin
    if(i_rx_valid)
        r_ram_addr_a <= r_ram_addr_a + 1;
    else if(i_rx_end)
        r_ram_addr_a <= 0;
    else
        r_ram_addr_a <= r_ram_addr_a;
end

always @(posedge i_rxc)begin
    if(i_rx_valid)
        r_recv_len <= r_ram_addr_a;
    else
        r_recv_len <= r_recv_len;
end

always @(posedge i_rxc)begin
    ri_rx_valid <= i_rx_valid;
end

always @(posedge i_rxc)begin
    if(!i_rx_valid & ri_rx_valid)
        r_fifo_wren <= 1;
    else
        r_fifo_wren <= 0;
end

//==============udp stack clock=================//
always @(posedge i_udp_stack_clk)begin
    if(r_read_cnt == w_fifo_dout)
        r_read_run <= 'd0;
    else if(!w_fifo_empty)
        r_read_run <= 'd1;
    else
        r_read_run <= r_read_run;
end

always @(posedge i_udp_stack_clk)begin
    if(!w_fifo_empty && !r_read_run && !r_fifo_rden)
        r_fifo_rden <= 'd1; 
    else
        r_fifo_rden <= 'd0; 
end

always @(posedge i_udp_stack_clk)begin
    if(r_read_cnt == w_fifo_dout)
        r_read_cnt <= 'd0';
    else if(r_ram_en_b)
        r_read_cnt <= r_read_cnt + 'd1;
    else
        r_read_cnt <= r_read_cnt;
end

always @(posedge i_udp_stack_clk)begin
    if(r_fifo_rden)
        r_ram_en_b <= 'd1;
    else if()
        r_ram_en_b <= 'd0;
    else
        r_ram_en_b <= r_ram_en_b;
end

endmodule
