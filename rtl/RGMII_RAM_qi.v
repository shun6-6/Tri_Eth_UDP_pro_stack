`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/19 19:18:27
// Design Name: 
// Module Name: RGMII_RAM_qi
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


module RGMII_RAM_qi(
input               i_udp_stack_clk ,
    input  [7 :0]       i_GMII_data     ,
    input               i_GMII_valid    ,
    output [7 :0]       o_GMII_data     ,
    output              o_GMII_valid    ,

    input               i_rxc           ,
    input               i_speed1000     ,
    output  [7 :0]      o_send_data     ,
    output              o_send_valid    ,
    input   [7 :0]      i_rec_data      ,
    input               i_rec_valid     ,
    input               i_rec_end       
);

/***************function**************/

/***************parameter*************/
localparam              P_GAP   =   4      ;

/***************port******************/             

/***************mechine***************/

/***************reg*******************/
reg  [11:0]             r_ram_addr_A=0      ;
reg  [11:0]             r_rec_len   =0      ;
reg                     r_ram_en_B  =0      ;
reg                     r_ram_en_B_1d=0     ;
reg                     r_ram_en_B_2d=0     ;
reg  [11:0]             r_ram_addr_B=0      ;
reg                     r_fifo_wr_en=0      ;
reg                     r_fifo_rd_en=0      ;
reg                     ri_rec_en   =0      ;
reg                     r_read_run  =0      ;
reg  [11:0]             r_read_cnt  =0      ;
reg  [7 :0]             ro_GMII_data =0     ;
reg                     ro_GMII_valid=0     ;
reg  [11:0]             r_tx_ram_addr_A=0   ;
reg  [11:0]             r_tx_len=0          ;
reg                     r_tx_fifo_wren=0    ;
reg                     ri_GMII_valid=0     ;
reg                     r_tx_ram_en_B=0     ;
reg  [11:0]             r_tx_ram_addr_B=0   ;
reg                     r_tx_fifo_rden=0    ;
reg                     r_tx_read_run=0     ;
reg  [11:0]             r_tx_cnt =0         ;
reg  [7 :0]             ro_send_data =0     ;
reg                     ro_send_valid=0     ;
reg                     w_rxc=0             ;
reg                     ri_rec_end=0        ;
reg                     ro_send_valid_1d=0  ;
reg  [7 :0]             r_gap_cnt=0         ;

/***************wire******************/
wire [7 :0]             w_ram_dout_B    ;
wire [10:0]             w_fifo_dout     ;
wire                    w_fifo_full     ;
wire                    w_fifo_empty    ;
wire [7 :0]             w_tx_ram_dout   ;
wire [10:0]             w_tx_fifo_dout  ;
wire                    w_tx_fifo_full  ;
wire                    w_tx_fifo_empty ;


/***************component*************/
RAM_8x1526 RAM_8x1526_U0 (//8X3000
  .clka             (i_rxc          ),    // input wire clka
  .ena              (i_rec_valid    ),      // input wire ena
  .wea              (i_rec_valid    ),      // input wire [0 : 0] wea
  .addra            (r_ram_addr_A   ),  // input wire [10 : 0] addra
  .dina             (i_rec_data     ),    // input wire [7 : 0] dina
  .douta            (               ),  // output wire [7 : 0] douta
  
  .clkb             (i_udp_stack_clk),    // input wire clkb
  .enb              (r_ram_en_B     ),      // input wire enb
  .web              (0              ),      // input wire [0 : 0] web
  .addrb            (r_ram_addr_B   ),  // input wire [10 : 0] addrb
  .dinb             (0              ),    // input wire [7 : 0] dinb
  .doutb            (w_ram_dout_B   )  // output wire [7 : 0] doutb
);

FIFO_ASYNC_11X64 FIFO_ASYNC_11_64_u0 (
  .wr_clk           (i_rxc          ),  // input wire wr_clk
  .rd_clk           (i_udp_stack_clk),  // input wire rd_clk
  .din              (r_rec_len      ),        // input wire [10 : 0] din
  .wr_en            (r_fifo_wr_en   ),    // input wire wr_en
  .rd_en            (r_fifo_rd_en   ),    // input wire rd_en
  .dout             (w_fifo_dout    ),      // output wire [10 : 0] dout
  .full             (w_fifo_full    ),      // output wire full
  .empty            (w_fifo_empty   )    // output wire empty
);

RAM_8x1526 RAM_8x1526_tx_U0 (//8X3000
  .clka             (i_udp_stack_clk    ),    // input wire clka
  .ena              (i_GMII_valid       ),      // input wire ena
  .wea              (i_GMII_valid       ),      // input wire [0 : 0] wea
  .addra            (r_tx_ram_addr_A    ),  // input wire [10 : 0] addra
  .dina             (i_GMII_data        ),    // input wire [7 : 0] dina
  .douta            (),  // output wire [7 : 0] douta
  
  .clkb             (i_rxc              ),    // input wire clkb
  .enb              (r_tx_ram_en_B      ),      // input wire enb
  .web              (0                  ),      // input wire [0 : 0] web
  .addrb            (r_tx_ram_addr_B    ),  // input wire [10 : 0] addrb
  .dinb             (0                  ),    // input wire [7 : 0] dinb
  .doutb            (w_tx_ram_dout      )  // output wire [7 : 0] doutb
);

FIFO_ASYNC_11X64 FIFO_ASYNC_11_64_tx_u0 (
  .wr_clk           (i_udp_stack_clk    ),  // input wire wr_clk
  .rd_clk           (i_rxc              ),  // input wire rd_clk
  .din              (r_tx_len           ),        // input wire [10 : 0] din
  .wr_en            (r_tx_fifo_wren     ),    // input wire wr_en
  .rd_en            (r_tx_fifo_rden     ),    // input wire rd_en
  .dout             (w_tx_fifo_dout     ),      // output wire [10 : 0] dout
  .full             (w_tx_fifo_full     ),      // output wire full
  .empty            (w_tx_fifo_empty    )    // output wire empty
);

/***************assign****************/
assign o_GMII_data  = ro_GMII_data  ;
assign o_GMII_valid = ro_GMII_valid ;
assign o_send_data  = ro_send_data  ;
assign o_send_valid = ro_send_valid_1d ;

/***************always****************/
/*--------rgmii--------*/
always@(posedge i_rxc)
begin
    if(i_rec_valid)
        r_ram_addr_A <= r_ram_addr_A + 1;
    else if(i_rec_end)
        r_ram_addr_A <= 'd0;
    else 
        r_ram_addr_A <= r_ram_addr_A;
end

always@(posedge i_rxc)
begin
    if(r_fifo_wr_en)
        r_rec_len <= 'd0;
    else if(i_rec_valid)
        r_rec_len <= r_rec_len + 1;
    else 
        r_rec_len <= r_rec_len;
end

always@(posedge i_rxc)
begin
    ri_rec_end <= i_rec_end;
end

always@(posedge i_rxc)
begin
    if(i_rec_end & !ri_rec_end)
        r_fifo_wr_en <= 'd1;
    else 
        r_fifo_wr_en <= 'd0;
end




always@(posedge i_rxc)
begin
    if(i_speed1000)
        if(r_tx_cnt && r_tx_cnt == w_tx_fifo_dout - 1)
            r_tx_read_run <= 'd0;
        else if(!r_tx_read_run && !w_tx_fifo_empty && r_gap_cnt == 'd0)
            r_tx_read_run <= 'd1;
        else 
            r_tx_read_run <= r_tx_read_run;
    else 
        if(r_tx_cnt && r_tx_cnt == w_tx_fifo_dout - 1 && r_tx_ram_en_B)
            r_tx_read_run <= 'd0;
        else if(!r_tx_read_run && !w_tx_fifo_empty && r_gap_cnt == 'd0)
            r_tx_read_run <= 'd1;
        else 
            r_tx_read_run <= r_tx_read_run;
end

always@(posedge i_rxc)
begin
    if(!r_tx_read_run && !w_tx_fifo_empty && r_gap_cnt == 'd0)
        r_tx_fifo_rden <= 'd1;
    else 
        r_tx_fifo_rden <= 'd0;
end

always@(posedge i_rxc)
begin
    if(r_gap_cnt == P_GAP - 2)
        r_gap_cnt <= 'd0;
    else if(r_gap_cnt || (r_tx_cnt && r_tx_cnt == w_tx_fifo_dout - 1))
        r_gap_cnt <= r_gap_cnt + 1;
    else 
        r_gap_cnt <= r_gap_cnt;
end


always@(posedge i_rxc)
begin
    if(i_speed1000)
        if(r_tx_cnt && r_tx_cnt == w_tx_fifo_dout - 1)
            r_tx_ram_en_B <= 'd0;
        else if(r_tx_fifo_rden)
            r_tx_ram_en_B <= 'd1;
        else 
            r_tx_ram_en_B <= r_tx_ram_en_B;
    else 
        if(r_tx_ram_en_B)
            r_tx_ram_en_B <= 'd0;
        else if(r_tx_fifo_rden || r_tx_read_run)
            r_tx_ram_en_B <= 'd1;
        else 
            r_tx_ram_en_B <= 'd0;
end

always@(posedge i_rxc)
begin
    if(r_tx_ram_addr_B == 2999)
        r_tx_ram_addr_B <= 'd0;
    else if(r_tx_ram_en_B)
        r_tx_ram_addr_B <= r_tx_ram_addr_B + 1;
    else 
        r_tx_ram_addr_B <= r_tx_ram_addr_B;
end

always@(posedge i_rxc)
begin
    if(i_speed1000)
        if(r_tx_cnt && r_tx_cnt == w_tx_fifo_dout - 1)
            r_tx_cnt <= 'd0;
        else if(r_tx_ram_en_B)
            r_tx_cnt <= r_tx_cnt + 1;
        else 
            r_tx_cnt <= r_tx_cnt;
    else 
        if(r_tx_cnt && r_tx_cnt == w_tx_fifo_dout - 1 && r_tx_ram_en_B)
            r_tx_cnt <= 'd0;
        else if(r_tx_ram_en_B)
            r_tx_cnt <= r_tx_cnt + 1;
        else 
            r_tx_cnt <= r_tx_cnt;
end

always@(posedge i_rxc)
begin
    ro_send_data  <= w_tx_ram_dout;
    ro_send_valid <= r_tx_ram_en_B;
end
/*--------udp--------*/
always@(posedge i_udp_stack_clk)
begin
    if(r_read_cnt == w_fifo_dout )
        r_read_run <= 'd0;
    else if(!w_fifo_empty)
        r_read_run <= 'd1;
    else 
        r_read_run <= r_read_run;
end

always@(posedge i_udp_stack_clk)
begin
    if(!r_read_run && !w_fifo_empty)
        r_fifo_rd_en <= 'd1;
    else 
        r_fifo_rd_en <= 'd0;
end

always@(posedge i_udp_stack_clk)
begin
    if(r_read_cnt == w_fifo_dout  )    
        r_read_cnt <= 'd0;
    else if(r_ram_en_B)       
        r_read_cnt <= r_read_cnt + 1;
    else 
        r_read_cnt <= r_read_cnt;
end


always@(posedge i_udp_stack_clk)
begin
    if(r_read_cnt == w_fifo_dout )
        r_ram_en_B <= 'd0;
    else if(r_fifo_rd_en)  
        r_ram_en_B <= 'd1;
    else
        r_ram_en_B <= r_ram_en_B;
end

always@(posedge i_udp_stack_clk)
begin
    if(r_ram_en_B)
        r_ram_addr_B <= r_ram_addr_B + 1;
    else 
        r_ram_addr_B <= 'd0;
end

always@(posedge i_udp_stack_clk)
begin
    r_ram_en_B_1d <= r_ram_en_B;
    ro_GMII_data  <= w_ram_dout_B;
    r_ram_en_B_2d <= r_ram_en_B_1d;
end

always@(posedge i_udp_stack_clk)
begin
    if(!r_ram_en_B & r_ram_en_B_1d)
        ro_GMII_valid <= 'd0;
    else if(r_ram_en_B_1d & !r_ram_en_B_2d)
        ro_GMII_valid <= 'd1;
    else 
        ro_GMII_valid <= ro_GMII_valid;
end



always@(posedge i_udp_stack_clk)
begin
    if(r_tx_ram_addr_A == 2999)
        r_tx_ram_addr_A <= 'd0;
    else if(i_GMII_valid)
        r_tx_ram_addr_A <= r_tx_ram_addr_A + 1;
    else 
        r_tx_ram_addr_A <= r_tx_ram_addr_A;
end

always@(posedge i_udp_stack_clk)
begin
    if(r_tx_fifo_wren)
        r_tx_len <= 'd0;
    else if(i_GMII_valid)
        r_tx_len <= r_tx_len + 1;
    else 
        r_tx_len <= r_tx_len;
end
      
always@(posedge i_udp_stack_clk)
begin
    ri_GMII_valid <= i_GMII_valid;
    ro_send_valid_1d <= ro_send_valid;
end      

always@(posedge i_udp_stack_clk)
begin
    if(!i_GMII_valid & ri_GMII_valid)
        r_tx_fifo_wren <= 'd1;
    else 
        r_tx_fifo_wren <= 'd0;
end


endmodule

