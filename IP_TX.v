`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: IP_TX
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


module IP_TX#(
    parameter       P_DST_IP = {8'd192,8'd168,8'd1,8'd0},
    parameter       P_SRC_IP = {8'd192,8'd168,8'd1,8'd1}
)(
    input           i_clk               ,
    input           i_rst               ,
    /*----info port----*/   
    input  [31:0]   i_dst_ip            ,
    input           i_dst_ip_valid      ,
    input  [31:0]   i_src_ip            ,
    input           i_src_ip_valid      ,
    /*----data port----*/   
    input  [7 :0]   i_send_data         ,
    input  [7 :0]   i_send_type         ,
    input  [15:0]   i_send_len          ,
    input           i_send_last         ,
    input           i_send_valid        ,
    /*----arp port----*/
    output [31:0]   o_seek_ip           ,
    output          o_seek_valid        ,
    /*----mac port----*/
    output [15:0]   o_mac_type          ,
    output [7 :0]   o_mac_data          ,
    output [15:0]   o_mac_len           ,
    output          o_mac_last          ,
    output          o_mac_valid         
);
/******************************function***************************/

/******************************parameter**************************/
localparam      P_TYPE_UDP  =   8'd17   ;
localparam      P_TYPE_ICMP =   8'd1    ;
localparam      P_TYPE_IP   =   16'h0800;
/******************************port*******************************/

/******************************machine****************************/

/******************************reg********************************/
reg  [31:0]     r_dst_ip            ;      
reg  [31:0]     r_src_ip            ; 
reg  [7 :0]     ri_send_data        ;
reg  [7 :0]     ri_send_type        ;
reg  [15:0]     ri_send_len         ;
reg             ri_send_last        ;
reg             ri_send_valid       ;
reg             ri_send_valid_1d    ;
reg  [15:0]     ro_mac_type         ;
reg             ro_mac_last         ;

reg  [31:0]     ro_seek_ip          ;
reg             ro_seek_valid       ;
//fifo
reg             r_fifo_rden         ;
reg             r_fifo_rden_1d      ;
//组帧
reg  [7 :0]     r_ip_data           ;
reg             r_ip_data_valid     ;
reg  [15:0]     r_ip_data_cnt       ;
reg  [15:0]     r_ip_tag            ;//标识
reg  [31:0]     r_ip_header_chk     ;//首部校验和
/******************************wire*******************************/
wire [7 :0]     w_fifo_rdata        ;
wire            w_fifo_full         ;
wire            w_fifo_empty        ;
wire            w_send_valid_pos    ;
wire            w_send_valid_neg    ;
/******************************component**************************/
MAC_TX_FIFO_8x512 IP_TX_FIFO_8x512_u0 (
  .clk              (i_clk          ), 
  .srst             (i_rst          ), 
  .din              (ri_send_data   ), 
  .wr_en            (ri_send_valid  ), 
  .rd_en            (r_fifo_rden    ), 
  .dout             (w_fifo_rdata   ), 
  .full             (w_fifo_full    ), 
  .empty            (w_fifo_empty   ), 
  .wr_rst_busy      (), 
  .rd_rst_busy      ()  
);
/******************************assign*****************************/
assign  o_mac_valid     =   r_ip_data_valid ;
assign  o_mac_data      =   r_ip_data       ;
assign  o_mac_type      =   ro_mac_type     ;
assign  o_mac_len       =   ri_send_len     ;
assign  o_mac_last      =   ro_mac_last     ;

assign  o_seek_ip       =   ro_seek_ip      ;
assign  o_seek_valid    =   ro_seek_valid   ;
/******************************always*****************************/
//源ip地址可设置
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_src_ip  <= P_SRC_IP ;      
    else if(i_src_ip_valid)
        r_src_ip  <= i_src_ip;                 
    else 
        r_src_ip  <= r_src_ip ;
end
//目的ip地址可设置
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_dst_ip <= P_DST_IP;
    else if(i_dst_ip_valid)
        r_dst_ip <= i_dst_ip;          
    else 
        r_dst_ip <= r_dst_ip;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst) begin
        ri_send_data  <= 'd0;
        ri_send_type  <= 'd0;
        ri_send_len   <= 'd0;
        ri_send_last  <= 'd0;
        ri_send_valid <= 'd0;        
    end         
    else if(i_send_valid)begin
        ri_send_data  <= i_send_data ;
        ri_send_type  <= i_send_type ;
        ri_send_len   <= i_send_len + 20;//需要加IP头长度
        ri_send_last  <= i_send_last ;
        ri_send_valid <= i_send_valid;        
    end
    else begin
        ri_send_data  <= ri_send_data ;
        ri_send_type  <= ri_send_type ;
        ri_send_len   <= ri_send_len  ;
        ri_send_last  <= 'd0;
        ri_send_valid <= 'd0;        
    end
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ri_send_valid_1d <= 'd0;      
    else 
        ri_send_valid_1d <= ri_send_valid;
end
//组帧
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_ip_data_cnt <= 'd0;
    else if(r_ip_data_cnt == ri_send_len)
        r_ip_data_cnt <= 'd0; 
    else if(ri_send_valid && !ri_send_valid_1d || r_ip_data_cnt)
        r_ip_data_cnt <= r_ip_data_cnt + 1;          
    else 
        r_ip_data_cnt <= 'd0;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_ip_tag <= 'd0; 
    else if(ro_mac_last)
        r_ip_tag <= r_ip_tag + 1;          
    else 
        r_ip_tag <= r_ip_tag;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_ip_header_chk <= 'd0; 
    else if(ri_send_valid && r_ip_data_cnt == 0)
        r_ip_header_chk <= 16'h4500 + ri_send_len + r_ip_tag + 16'h4000 + {8'd64,ri_send_type} + 16'd0
                            + r_src_ip[31:16] + r_src_ip[15:0] + r_dst_ip[31:16] + r_dst_ip[15:0];  
    else if(r_ip_data_cnt == 1)
        r_ip_header_chk <= r_ip_header_chk[31:16] + r_ip_header_chk[15:0];       
    else if(r_ip_data_cnt == 2)
        r_ip_header_chk <= r_ip_header_chk[31:16] + r_ip_header_chk[15:0];   
    else if(r_ip_data_cnt == 3)
        r_ip_header_chk <= ~r_ip_header_chk;  
    else 
        r_ip_header_chk <= r_ip_header_chk;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_ip_data_valid <= 'd0;
    else if(r_ip_data_cnt == ri_send_len)
        r_ip_data_valid <= 'd0; 
    else if(ri_send_valid & !ri_send_valid_1d)
        r_ip_data_valid <= 'd1;     
    else 
        r_ip_data_valid <= r_ip_data_valid;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_fifo_rden <= 'd0;
    else if(ro_mac_last)//!!
        r_fifo_rden <= 'd0; 
    else if(r_ip_data_cnt == 18)
        r_fifo_rden <= 'd1;     
    else 
        r_fifo_rden <= r_fifo_rden;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_ip_data <= 'd0;        
    else case (r_ip_data_cnt)
        0       : r_ip_data <= {4'b0100,4'b0101};       //版本+首部长度
        1       : r_ip_data <= 'd0;                     //服务类型
        2       : r_ip_data <= ri_send_len[15:8];       //总长度高8位
        3       : r_ip_data <= ri_send_len[7 :0];       //总长度低8位
        4       : r_ip_data <= r_ip_tag[15:8];          //标识高8
        5       : r_ip_data <= r_ip_tag[7 :0];          //标识低8
        6       : r_ip_data <= {3'b010,5'b00000};       //标志3bit+片偏移高5bit
        7       : r_ip_data <= 'd0;                     //片偏移低8bit
        8       : r_ip_data <= 'd64;                    //生存时间
        9       : r_ip_data <= ri_send_type;            //协议
        10      : r_ip_data <= r_ip_header_chk[15:8];   //首部校验和高8
        11      : r_ip_data <= r_ip_header_chk[7 :0];   //首部校验和低8
        12      : r_ip_data <= r_src_ip[31:24];         //源地址
        13      : r_ip_data <= r_src_ip[23:16];         //源地址
        14      : r_ip_data <= r_src_ip[15: 8];         //源地址
        15      : r_ip_data <= r_src_ip[7 : 0];         //源地址
        16      : r_ip_data <= r_dst_ip[31:24];         //目的地址
        17      : r_ip_data <= r_dst_ip[23:16];         //目的地址
        18      : r_ip_data <= r_dst_ip[15: 8];         //目的地址
        19      : r_ip_data <= r_dst_ip[7 : 0];         //目的地址
        default : r_ip_data <= w_fifo_rdata;            //fifo read data
    endcase
end
//输出数据到mac模块
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_mac_type <= 'd0;
    else if(ri_send_valid)
        ro_mac_type <= P_TYPE_IP;          
    else 
        ro_mac_type <= ro_mac_type;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_mac_last <= 'd0;
    else if(r_ip_data_cnt == ri_send_len - 1)
        ro_mac_last <= 'd1;          
    else 
        ro_mac_last <= 'd0;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        ro_seek_ip    <= P_DST_IP;
        ro_seek_valid <= 'd0;
    end
    else if(ri_send_valid && !ri_send_valid_1d)begin
        ro_seek_ip    <= r_dst_ip;
        ro_seek_valid <= 'd1;
    end
    else begin
        ro_seek_ip    <= ro_seek_ip;
        ro_seek_valid <= 'd0;        
    end
end

endmodule
