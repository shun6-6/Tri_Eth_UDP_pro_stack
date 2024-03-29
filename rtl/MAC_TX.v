`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: MAC_TX
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


module MAC_TX#(
    parameter       P_SRC_MAC   = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
    parameter       P_DEST_MAC  = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00},
    parameter       P_CRC_CHECK = 1
)(
    input           i_clk               ,
    input           i_rst               ,
    /*----info port----*/   
    input  [47:0]   i_src_mac           ,
    input           i_src_mac_valid     ,
    input  [47:0]   i_dest_mac          ,
    input           i_dest_mac_valid    ,
    /*----data port----*/   
    input           i_udp_valid         ,
    output          o_udp_ready         ,
    input  [15:0]   i_send_type         ,
    input  [7 :0]   i_send_data         ,
    input  [15:0]   i_send_len          ,
    input           i_send_last         ,
    input           i_send_valid        ,
    /*----GMII port----*/
    output [7 :0]   o_gmii_data         ,
    output          o_gmii_valid         
);
/******************************function***************************/

/******************************parameter**************************/
localparam      P_GAP_LEN   =   30;
/******************************port*******************************/

/******************************machine****************************/

/******************************reg********************************/
reg  [47:0]     r_src_mac               ;
reg  [47:0]     r_dest_mac              ;
reg  [15:0]     ri_send_type            ;
reg  [7 :0]     ri_send_data            ;
reg  [15:0]     ri_send_len             ;
reg             ri_send_last            ;
reg             ri_send_valid           ;
reg             ri_send_valid_1d        ;
reg  [7 :0]     ro_gmii_data            ;
reg             ro_gmii_valid           ;
reg             ro_gmii_valid_1d        ;

reg             ri_udp_valid            ;
reg             ro_udp_ready            ;
reg  [15:0]     r_gap_cnt               ;
//组帧
reg  [15:0]     r_mac_pkt_cnt           ;//组帧计数器
reg  [7 :0]     r_mac_data              ;
reg  [7 :0]     r_mac_data_1d           ;
reg             r_mac_data_valid        ;
reg             r_mac_data_valid_1d     ;
reg  [25:0]     r_mac_fifo_rd_cnt       ;
//fifo
reg             r_fifo_rden             ;
reg             r_fifo_rden_1d          ;
reg             r_fifo_rden_2d          ;
//crc
reg             r_crc_rst               ;
reg             r_crc_en                ;
reg  [1 :0]     r_crc_out_cnt           ;
reg  [1 :0]     r_crc_out_cnt_1d        ;
/******************************wire*******************************/
wire [7 :0]     w_fifo_rdata            ;
wire            w_fifo_full             ;
wire            w_fifo_empty            ;
wire            w_send_valid_pos        ;
wire            w_send_valid_neg        ;
//crc
wire [31:0]     w_crc_result            ;

wire [15:0]     w_fifo_len_dout         ;
wire            w_fifo_len_full         ;
wire            w_fifo_len_empty        ;
/******************************component**************************/
MAC_TX_FIFO_8x512 MAC_TX_FIFO_8x512_u0 (
  .clk              (i_clk          ), 
  .srst             (i_rst          ), 
  .din              (ri_send_data   ), 
  .wr_en            (ri_send_valid  ), 
  .rd_en            (r_fifo_rden    ), 
  .dout             (w_fifo_rdata   ), 
  .full             (w_fifo_full    ), 
  .empty            (w_fifo_empty   )
  //.wr_rst_busy      (), 
  //.rd_rst_busy      ()  
);

FIFO_16x64 FIFO_16x64_len (
  .clk              (i_clk          ),
  .din              (i_send_len     ),
  .wr_en            (i_send_valid && !ri_send_valid),
  .rd_en            (r_fifo_rden && !r_fifo_rden_1d),
  .dout             (w_fifo_len_dout ),
  .full             (w_fifo_len_full ),
  .empty            (w_fifo_len_empty)
);

//crc check
CRC32_D8 CRC32_D8_u0(
	.i_clk	(i_clk          ),
	.i_rst	(r_crc_rst      ),
	.i_en	(r_crc_en       ),
	.i_data	(r_mac_data     ),
	.o_crc  (w_crc_result   )	
);
/******************************assign*****************************/
assign  o_gmii_data         =   ro_gmii_data    ;
assign  o_gmii_valid        =   ro_gmii_valid   ;
//assign  w_send_valid_pos    =   ri_send_valid & !ri_send_valid_1d;
assign  w_send_valid_pos    =   (r_gap_cnt == P_GAP_LEN) && (!w_fifo_len_empty);
assign  w_send_valid_neg    =   !ri_send_valid & ri_send_valid_1d;  
assign  o_udp_ready         =   ro_udp_ready    ;
/******************************always*****************************/
//源mac地址可设置
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_src_mac  <= P_SRC_MAC ;      
    else if(i_src_mac_valid)
        r_src_mac  <= i_src_mac;                 
    else 
        r_src_mac  <= r_src_mac ;
end
//目的mac地址可设置
// always @(posedge i_clk or posedge i_rst)begin
//     if(i_rst)
//         r_dest_mac <= P_DEST_MAC;              
//     else if(i_dest_mac_valid)
//         r_dest_mac <= i_dest_mac;          
//     else 
//         r_dest_mac <= r_dest_mac;
// end
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_dest_mac <= P_DEST_MAC;              
    else if(i_dest_mac_valid)
        r_dest_mac <= P_DEST_MAC;          
    else 
        r_dest_mac <= P_DEST_MAC;
end
//输入寄存
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        ri_send_type  <= 'd0;
        ri_send_data  <= 'd0;
        ri_send_len   <= 'd0;
        ri_send_last  <= 'd0;
        ri_send_valid <= 'd0;        
    end                    
    else if(i_send_valid)begin
        ri_send_type  <= i_send_type ;
        ri_send_data  <= i_send_data ;
        ri_send_len   <= i_send_len  ;
        //ri_send_last  <= i_send_last ;
        ri_send_valid <= i_send_valid;        
    end
    else begin
        ri_send_type  <= i_send_type ;
        ri_send_data  <= 'd0;
        ri_send_len   <= i_send_len  ;
        //ri_send_last  <= i_send_last ;
        ri_send_valid <= 'd0;        
    end
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ri_send_valid_1d <= 'd0;                       
    else 
        ri_send_valid_1d <= ri_send_valid;  
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_mac_pkt_cnt <= 'd0;                 
    else if(r_crc_out_cnt == 3)
        r_mac_pkt_cnt <= 'd0;    
    else if(w_send_valid_pos || r_mac_pkt_cnt)
        r_mac_pkt_cnt <= r_mac_pkt_cnt + 'd1;         
    else 
        r_mac_pkt_cnt <= r_mac_pkt_cnt;  
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_mac_data <= 'd0;        
    else begin
        case (r_mac_pkt_cnt)
            0,1,2,3,4,5,6   : r_mac_data <= 8'h55;
            7               : r_mac_data <= 8'hD5;
            8               : r_mac_data <= ri_send_type == 16'h0806 ? 8'hff : r_dest_mac[47:40];
            9               : r_mac_data <= ri_send_type == 16'h0806 ? 8'hff : r_dest_mac[39:32];
            10              : r_mac_data <= ri_send_type == 16'h0806 ? 8'hff : r_dest_mac[31:24];
            11              : r_mac_data <= ri_send_type == 16'h0806 ? 8'hff : r_dest_mac[23:16];
            12              : r_mac_data <= ri_send_type == 16'h0806 ? 8'hff : r_dest_mac[15: 8];
            13              : r_mac_data <= ri_send_type == 16'h0806 ? 8'hff : r_dest_mac[7 : 0];
            14              : r_mac_data <= r_src_mac[47:40];
            15              : r_mac_data <= r_src_mac[39:32];
            16              : r_mac_data <= r_src_mac[31:24];
            17              : r_mac_data <= r_src_mac[23:16];
            18              : r_mac_data <= r_src_mac[15: 8];
            19              : r_mac_data <= r_src_mac[7 : 0];
            20              : r_mac_data <= ri_send_type[15:8];
            21              : r_mac_data <= ri_send_type[7 :0];
            default         : r_mac_data <= w_fifo_rdata; 
        endcase
    end 
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_mac_data_1d <= 'd0;                         
    else 
        r_mac_data_1d <= r_mac_data;  
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_mac_data_valid <= 'd0;                 
    else if(r_mac_fifo_rd_cnt == w_fifo_len_dout + 1)
        r_mac_data_valid <= 'd0;    
    else if(w_send_valid_pos)
        r_mac_data_valid <= 'd1;         
    else 
        r_mac_data_valid <= r_mac_data_valid;  
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_mac_fifo_rd_cnt <= 'd0;                 
    else if(r_mac_fifo_rd_cnt == w_fifo_len_dout + 1)
        r_mac_fifo_rd_cnt <= 'd0;    
    else if(r_fifo_rden || r_mac_fifo_rd_cnt)
        r_mac_fifo_rd_cnt <= r_mac_fifo_rd_cnt + 1;         
    else 
        r_mac_fifo_rd_cnt <= r_mac_fifo_rd_cnt;  
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_mac_data_valid_1d <= 'd0;                         
    else 
        r_mac_data_valid_1d <= r_mac_data_valid;  
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_fifo_rden <= 'd0;                 
    else if(r_mac_fifo_rd_cnt == w_fifo_len_dout - 1)
        r_fifo_rden <= 'd0;    
    else if(r_mac_pkt_cnt == 20)
        r_fifo_rden <= 'd1;         
    else 
        r_fifo_rden <= r_fifo_rden;  
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_fifo_rden_1d <= 'd0;                         
    else 
        r_fifo_rden_1d <= r_fifo_rden;  
end
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_fifo_rden_2d <= 'd0;                         
    else 
        r_fifo_rden_2d <= r_fifo_rden_1d;  
end

//crc check
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_crc_rst <= 'd1;                 
    else if(r_mac_pkt_cnt == 8)//前导码不应该校验
        r_crc_rst <= 'd0;    
    else if(r_crc_out_cnt == 3)
        r_crc_rst <= 'd1;         
    else 
        r_crc_rst <= r_crc_rst;  
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_crc_en <= 'd0;                 
    else if(!r_fifo_rden_1d & r_fifo_rden_2d)
        r_crc_en <= 'd0;    
    else if(r_mac_pkt_cnt == 8)
        r_crc_en <= 'd1;         
    else 
        r_crc_en <= r_crc_en;  
end
 
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_crc_out_cnt <= 'd0;                 
    else if(r_crc_out_cnt == 3)
        r_crc_out_cnt <= 'd0;    
    else if((!r_mac_data_valid & r_mac_data_valid_1d) || r_crc_out_cnt)
        r_crc_out_cnt <= r_crc_out_cnt + 'd1;         
    else 
        r_crc_out_cnt <= r_crc_out_cnt;  
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_crc_out_cnt_1d <= 'd0;                         
    else 
        r_crc_out_cnt_1d <= r_crc_out_cnt;  
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_gmii_data <= 'd0;                 
    else if(r_mac_data_valid)
        ro_gmii_data <= r_mac_data;            
    else case (r_crc_out_cnt)
        3       : ro_gmii_data <= w_crc_result[31:24];
        2       : ro_gmii_data <= w_crc_result[23:16];
        1       : ro_gmii_data <= w_crc_result[15: 8];
        0       : ro_gmii_data <= w_crc_result[7 : 0];
        default : ro_gmii_data <= 'd0; 
    endcase
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_gmii_valid <= 'd0;  
    else if (r_crc_out_cnt_1d == 3) 
        ro_gmii_valid <= 'd0;  
    else if(r_mac_data_valid)
        ro_gmii_valid <= 'd1;  
    else 
        ro_gmii_valid <= ro_gmii_valid;  
end
   

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        ri_udp_valid <= 'd0;
        ro_gmii_valid_1d <= 'd0;
    end
    else begin
        ri_udp_valid <= i_udp_valid;
        ro_gmii_valid_1d <= ro_gmii_valid;
    end
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_udp_ready <= 'd1;  
    else if(r_mac_fifo_rd_cnt == w_fifo_len_dout - 2) 
        ro_udp_ready <= 'd1;  
    else if(i_udp_valid)
        ro_udp_ready <= 'd0;  
    else 
        ro_udp_ready <= ro_udp_ready;  
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_gap_cnt <= 'd1;  
    else if(ro_gmii_valid) 
        r_gap_cnt <= 'd0; 
    else if(r_gap_cnt == P_GAP_LEN) 
        r_gap_cnt <= r_gap_cnt;  
    else if((!ro_gmii_valid && ro_gmii_valid_1d) || r_gap_cnt)
        r_gap_cnt <= r_gap_cnt + 'd1;  
    else 
        r_gap_cnt <= r_gap_cnt;  
end

endmodule
