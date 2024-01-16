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
reg  [7 :0]     ro_gmii_rx_data     = 0 ;
reg             ro_gmii_rx_valid    = 0 ;
reg  [7 :0]     ro_tx_data          = 0 ;
reg             ro_tx_valid         = 0 ;
//recv port 
reg  [10:0]     r_ram_addr_a        = 0 ;
reg  [10:0]     r_ram_addr_b        = 0 ;
reg             r_ram_en_b          = 0 ;
reg             r_ram_en_b_1d       = 0 ;
reg             r_fifo_wren         = 0 ;
reg             r_fifo_rden         = 0 ;

reg  [10:0]     r_recv_len          = 0 ;
reg             ri_rx_valid         = 0 ;
reg             r_read_run          = 0 ;
reg  [15:0]     r_read_cnt          = 0 ;
//send port 
reg  [10:0]     r_tx_ram_addr_a     = 0 ;
reg  [10:0]     r_tx_ram_addr_b     = 0 ;
reg             r_tx_ram_en_b       = 0 ;
reg             r_tx_ram_en_b_1d    = 0 ;
reg  [10:0]     r_send_len          = 0 ;
reg             r_tx_fifo_wren      = 0 ;
reg             r_tx_fifo_rden      = 0 ;
reg             r_tx_read_run       = 0 ;
reg  [15:0]     r_tx_read_cnt       = 0 ;

reg             ri_gmii_tx_valid    = 0 ;
/******************************wire*******************************/
wire [7 :0]     w_ram_dout_b        ;
wire [10:0]     w_fifo_dout         ;
wire            w_fifo_full         ;
wire            w_fifo_empty        ;

wire [7 :0]     w_tx_ram_dout_b     ;
wire [10:0]     w_tx_fifo_dout      ;
wire            w_tx_fifo_full      ;
wire            w_tx_fifo_empty     ;
/******************************component**************************/
//=================recv ram and fifo==================
RAM_8x1526 RAM_8x1526_rx_u0 (
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

FIFO_ASYNC_11X64 FIFO_ASYNC_11X64_rx_U0 (
  .wr_clk   (i_rxc              ),
  .rd_clk   (i_udp_stack_clk    ),
  .din      (r_recv_len         ),
  .wr_en    (r_fifo_wren        ),
  .rd_en    (r_fifo_rden        ),
  .dout     (w_fifo_dout        ),
  .full     (w_fifo_full        ),
  .empty    (w_fifo_empty       )
);
//=================send ram and fifo==================
RAM_8x1526 RAM_8x1526_tx_u0 (
  .clka     (i_udp_stack_clk    ), 
  .ena      (i_gmii_tx_valid    ), 
  .wea      (i_gmii_tx_valid    ), 
  .addra    (r_tx_ram_addr_a    ), 
  .dina     (i_gmii_tx_data     ), 
  .douta    (),

  .clkb     (i_rxc              ), 
  .enb      (r_tx_ram_en_b      ), 
  .web      (0),
  .addrb    (r_tx_ram_addr_b    ), 
  .dinb     (0),
  .doutb    (w_tx_ram_dout_b    ) 
);

FIFO_ASYNC_11X64 FIFO_ASYNC_11X64_tx_U0 (
  .wr_clk   (i_udp_stack_clk    ),
  .rd_clk   (i_rxc              ),
  .din      (r_send_len         ),
  .wr_en    (r_tx_fifo_wren     ),
  .rd_en    (r_tx_fifo_rden     ),
  .dout     (w_tx_fifo_dout     ),
  .full     (w_tx_fifo_full     ),
  .empty    (w_tx_fifo_empty    )
);

/******************************assign*****************************/
assign o_gmii_rx_data   =   ro_gmii_rx_data     ;
assign o_gmii_rx_valid  =   ro_gmii_rx_valid    ;
assign o_tx_data        =   ro_tx_data          ;
assign o_tx_valid       =   ro_tx_valid         ;
/******************************always*****************************/
//==============rgmii clock=================//
//recv logic
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
//send logic
always @(posedge i_rxc)begin
    if(r_tx_read_cnt == w_tx_fifo_dout)
        r_tx_read_run <= 'd0;
    else if(!w_fifo_empty)
        r_tx_read_run <= 'd1;
    else
        r_tx_read_run <= r_tx_read_run;
end

always @(posedge i_rxc)begin
    if(!w_tx_fifo_empty && !r_tx_read_run)
        r_tx_fifo_rden <= 'd1; 
    else
        r_tx_fifo_rden <= 'd0; 
end

always @(posedge i_rxc)begin
    if(r_tx_read_cnt == w_tx_fifo_dout)
        r_tx_read_cnt <= 'd0;
    else if(r_tx_ram_en_b)
        r_tx_read_cnt <= r_tx_read_cnt + 'd1;
    else
        r_tx_read_cnt <= r_tx_read_cnt;
end

// always @(posedge i_rxc)begin
//     if(r_tx_read_cnt == w_tx_fifo_dout)
//         r_tx_ram_en_b <= 'd0;
//     else if(r_tx_fifo_rden)
//         r_tx_ram_en_b <= 'd1;
//     else
//         r_tx_ram_en_b <= r_tx_ram_en_b;
// end
always @(posedge i_rxc)begin
    if(i_speed1000)begin
        if(r_tx_read_cnt == w_tx_fifo_dout)
            r_tx_ram_en_b <= 'd0;
        else if(r_tx_fifo_rden)
            r_tx_ram_en_b <= 'd1;
        else
            r_tx_ram_en_b <= r_tx_ram_en_b;
    end
    else begin
        if(r_tx_ram_en_b)
            r_tx_ram_en_b <= 'd0;
        else if(r_tx_fifo_rden || r_tx_read_run)
            r_tx_ram_en_b <= 'd1;
        else
            r_tx_ram_en_b <= 'd0;
    end
end

always @(posedge i_rxc)begin
    r_tx_ram_en_b_1d <= r_ram_en_b;
end

always @(posedge i_rxc)begin
    if(r_tx_ram_en_b)
        r_tx_ram_addr_b <= r_tx_ram_addr_b + 'd1;
    else
        r_tx_ram_addr_b <= 'd0;
end

always @(posedge i_rxc)begin
    ro_tx_valid <= r_tx_ram_en_b_1d;
    ro_tx_data <= w_tx_ram_dout_b;
end

//==============udp stack clock=================//
//recv logic
always @(posedge i_udp_stack_clk)begin
    if(r_read_cnt == w_fifo_dout)
        r_read_run <= 'd0;
    else if(!w_fifo_empty)
        r_read_run <= 'd1;
    else
        r_read_run <= r_read_run;
end

always @(posedge i_udp_stack_clk)begin
    if(!w_fifo_empty && !r_read_run)
        r_fifo_rden <= 'd1; 
    else
        r_fifo_rden <= 'd0; 
end

always @(posedge i_udp_stack_clk)begin
    if(r_read_cnt == w_fifo_dout)
        r_read_cnt <= 'd0;
    else if(r_ram_en_b)
        r_read_cnt <= r_read_cnt + 'd1;
    else
        r_read_cnt <= r_read_cnt;
end

always @(posedge i_udp_stack_clk)begin
    if(r_read_cnt == w_fifo_dout)
        r_ram_en_b <= 'd0;
    else if(r_fifo_rden)
        r_ram_en_b <= 'd1;
    else
        r_ram_en_b <= r_ram_en_b;
end

always @(posedge i_udp_stack_clk)begin
    r_ram_en_b_1d <= r_ram_en_b;
end

always @(posedge i_udp_stack_clk)begin
    if(r_ram_en_b)
        r_ram_addr_b <= r_ram_addr_b + 'd1;
    else
        r_ram_addr_b <= 'd0;
end

always @(posedge i_udp_stack_clk)begin
    ro_gmii_rx_valid <= r_ram_en_b_1d;
    ro_gmii_rx_data <= w_ram_dout_b;
end

//send logic
always @(posedge i_udp_stack_clk)begin
    if(i_gmii_tx_valid)
        r_tx_ram_addr_a <= r_tx_ram_addr_a + 'd1;
    else
        r_tx_ram_addr_a <= 'd0;
end

always @(posedge i_udp_stack_clk)begin
    if(i_gmii_tx_valid)
        r_send_len <= r_tx_ram_addr_a;
    else
        r_send_len <= r_send_len;
end

always @(posedge i_udp_stack_clk)begin
    ri_gmii_tx_valid <= i_gmii_tx_valid;
end

always @(posedge i_udp_stack_clk)begin
    if(!i_gmii_tx_valid & ri_gmii_tx_valid)
        r_tx_fifo_wren <= 'd1;
    else
        r_tx_fifo_wren <= 'd0;
end


endmodule
