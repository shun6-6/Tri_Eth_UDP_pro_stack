`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/23 16:02:21
// Design Name: 
// Module Name: MAC_RX
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


module MAC_RX#(
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
    output [15:0]   o_post_type         ,
    output [7 :0]   o_post_data         ,
    output          o_post_valid        ,
    output          o_post_last         ,

    output [47:0]   o_recv_src_mac      ,
    output          o_recv_src_mac_valid,
    output          o_crc_error         ,
    output          o_crc_valid         ,
    /*----GMII port----*/
    input  [7 :0]   i_gmii_data         ,
    input           i_gmii_valid         
);
/******************************function***************************/

/******************************parameter**************************/
localparam      P_TYPE_IP  = 16'h0800;
localparam      P_TYPE_ARP = 16'h0806;
/******************************port*******************************/

/******************************machine****************************/

/******************************reg********************************/
reg             ro_post_valid               ;
reg             ro_post_last                ;
reg  [47:0]     ro_recv_src_mac             ;
reg             ro_recv_src_mac_valid       ;
reg             ro_crc_error                ;
reg             ro_crc_valid                ;
reg  [7 :0]     ri_gmii_data                ;
reg             ri_gmii_valid               ;
reg  [7 :0]     ri_gmii_data_1d             ;
reg             ri_gmii_valid_1d            ;
reg  [7 :0]     ri_gmii_data_2d             ;
reg             ri_gmii_valid_2d            ;
reg  [7 :0]     ri_gmii_data_3d             ;
reg             ri_gmii_valid_3d            ;
reg  [7 :0]     ri_gmii_data_4d             ;
reg             ri_gmii_valid_4d            ;
reg  [7 :0]     ri_gmii_data_5d             ;
reg             ri_gmii_valid_5d            ;//打5拍，可以将最后的四个crc校验码去除掉
reg  [47:0]     r_src_mac                   ;
reg  [47:0]     r_dest_mac                  ;

reg  [47:0]     r_recv_mac                  ;
reg             r_mac_access                ;
reg  [15:0]     r_recv_cnt                  ;
reg  [15:0]     r_recv_5d_cnt               ;
reg             r_header_access             ;
reg             r_header_check              ;
reg  [15:0]     r_recv_type                 ;//0x0800:IP4 0x0806:ARP
//crc   
reg             r_crc_en                    ;
reg             r_crc_en_1d                 ;
reg             r_crc_rst                   ;
reg  [31:0]     r_crc_recv                  ;
/******************************wire*******************************/
wire [31:0]     w_crc_result                ;
/******************************component**************************/
mac_rx_ila mac_rx_ila_u0 (
	.clk    (i_clk), // input wire clk


	.probe0 (ri_gmii_data ), // input wire [7:0]  probe0  
	.probe1 (ri_gmii_valid), // input wire [0:0]  probe1 
	.probe2 (ro_recv_src_mac      ), // input wire [47:0]  probe2 
	.probe3 (ro_recv_src_mac_valid), // input wire [0:0]  probe3 
	.probe4 (ro_crc_error), // input wire [0:0]  probe4 
	.probe5 (ro_crc_valid), // input wire [0:0]  probe5 
	.probe6 (r_recv_type   ), // input wire [15:0]  probe6 
	.probe7 (ri_gmii_data_5d ), // input wire [7:0]  probe7 
	.probe8 (ro_post_last   ), // input wire [0:0]  probe8 
	.probe9 (ro_post_valid  ) , 
	.probe10(r_crc_recv), // input wire [31:0]  probe10 
	.probe11(w_crc_result) // input wire [31:0]  probe11
);

CRC32_D8 CRC32_D8_u0(
	.i_clk	(i_clk          ),
	.i_rst	(r_crc_rst      ),
	.i_en	(r_crc_en       ),
	.i_data	(ri_gmii_data_5d),
	.o_crc  (w_crc_result   )	
);
/******************************assign*****************************/
assign  o_post_data             =   ri_gmii_data_5d         ;//输出最后打了5拍的数据（能够去除掉4byte的crc）
assign  o_post_valid            =   ro_post_valid           ;
assign  o_post_last             =   ro_post_last            ;
assign  o_post_type             =   r_recv_type             ;
assign  o_recv_src_mac          =   ro_recv_src_mac         ;
assign  o_recv_src_mac_valid    =   ro_recv_src_mac_valid   ;
assign  o_crc_error             =   ro_crc_error            ;
assign  o_crc_valid             =   ro_crc_valid            ;
/******************************always*****************************/
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        ri_gmii_data     <= 'd0;
        ri_gmii_valid    <= 'd0;    
        ri_gmii_data_1d  <= 'd0;
        ri_gmii_valid_1d <= 'd0;  
        ri_gmii_data_2d  <= 'd0; 
        ri_gmii_valid_2d <= 'd0; 
        ri_gmii_data_3d  <= 'd0;
        ri_gmii_valid_3d <= 'd0;
        ri_gmii_data_4d  <= 'd0;
        ri_gmii_valid_4d <= 'd0;  
        ri_gmii_data_5d  <= 'd0;
        ri_gmii_valid_5d <= 'd0; 
    end
    else begin
        ri_gmii_data     <= i_gmii_data     ;
        ri_gmii_valid    <= i_gmii_valid    ;  
        ri_gmii_data_1d  <= ri_gmii_data    ;
        ri_gmii_valid_1d <= ri_gmii_valid   ;
        ri_gmii_data_2d  <= ri_gmii_data_1d ; 
        ri_gmii_valid_2d <= ri_gmii_valid_1d; 
        ri_gmii_data_3d  <= ri_gmii_data_2d ;
        ri_gmii_valid_3d <= ri_gmii_valid_2d;
        ri_gmii_data_4d  <= ri_gmii_data_3d ;
        ri_gmii_valid_4d <= ri_gmii_valid_3d;    
        ri_gmii_data_5d  <= ri_gmii_data_4d ;
        ri_gmii_valid_5d <= ri_gmii_valid_4d;      
    end
end
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
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_dest_mac <= P_DEST_MAC;              
    else if(i_dest_mac_valid)
        r_dest_mac <= i_dest_mac;          
    else 
        r_dest_mac <= r_dest_mac;
end
//mac前导码和SFD：有可能是6个55加一个D5，协议里是7个55加一个D5，计数器需要涵盖这俩个情况
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_recv_cnt <= 'd0;
    else if(ri_gmii_valid && r_recv_cnt == 6 && ri_gmii_data == 8'h55)
        r_recv_cnt <= r_recv_cnt;
    else if(ri_gmii_valid)
        r_recv_cnt <= r_recv_cnt + 1;
    else
        r_recv_cnt <= 'd0;
end
//接收到的数据包当中的目的mac
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_recv_mac <= 'd0;
    else if(r_recv_cnt >= 7 && r_recv_cnt <= 12)
        r_recv_mac <= {r_recv_mac[39:0],ri_gmii_data};
    else
        r_recv_mac <= r_recv_mac;
end
//比较接收到的数据包当中的目的mac和自身mac
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_mac_access <= 'd1;
    else if(r_recv_mac != r_src_mac && r_recv_cnt == 13)
        r_mac_access <= 'd0;
    else if(((r_recv_mac == r_src_mac) || &r_recv_mac) && r_recv_cnt == 13)
        r_mac_access <= 'd1;
    else 
        r_mac_access <= r_mac_access;
end

always @(*)begin
    case (r_recv_cnt)
        0,1,2,3,4,5 : r_header_check = ri_gmii_data == 8'h55 ? 'd1 : 'd0;
        6           : r_header_check = ri_gmii_data == 8'hD5 || ri_gmii_data == 8'h55 ? 'd1 : 'd0;
        default     : r_header_check = 'd1;
    endcase
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_header_access <= 'd1;
    else if(!ri_gmii_valid)
        r_header_access <= 'd1;
    else if(ri_gmii_valid && r_recv_cnt >= 0 && r_recv_cnt <= 6 && !r_header_check)
        r_header_access <= 'd0;
    else 
        r_header_access <= r_header_access;
end
//获取发送方的源mac地址
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_recv_src_mac <= 'd0;
    else if(r_recv_cnt >= 13 && r_recv_cnt <= 18)
        ro_recv_src_mac <= {ro_recv_src_mac[39:0],ri_gmii_data};
    else
        ro_recv_src_mac <= ro_recv_src_mac;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_recv_src_mac_valid <= 'd0;
    else if(r_recv_cnt == 18)
        ro_recv_src_mac_valid <= 'd1;
    else
        ro_recv_src_mac_valid <= 'd0;
end
//接收报文类型
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_recv_type <= 'd0;
    else if(r_recv_cnt >= 19 && r_recv_cnt <= 20)
        r_recv_type <= {r_recv_type[7:0],ri_gmii_data};
    else
        r_recv_type <= r_recv_type;
end

/*输出IP或者ARP报文*/
//对打5拍后的数据进行计数 输出的IP或者ARP报文有效以及last按照该计数器
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_recv_5d_cnt <= 'd0;
    else if(ri_gmii_valid_5d)
        r_recv_5d_cnt <= r_recv_5d_cnt + 1;
    else
        r_recv_5d_cnt <= 'd0;
end
//IP data
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_post_valid <= 'd0;
    else if(!ri_gmii_valid && ri_gmii_valid_1d)
        ro_post_valid <= 'd0;
    else if(r_recv_5d_cnt == 21)
        ro_post_valid <= 'd1;
    else
        ro_post_valid <= ro_post_valid;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_post_last <= 'd0;
    else if(!i_gmii_valid && ri_gmii_valid)
        ro_post_last <= 'd1;
    else
        ro_post_last <= 'd0;
end

//crc ctrl
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_crc_rst <= 'd1;
    else if(r_recv_5d_cnt == 7)//除去前导码和校验码的数据才需要进行校验，所以也只需要对打5拍后的数据进行校验
        r_crc_rst <= 'd0;
    else if(!r_crc_en && r_crc_en_1d)
        r_crc_rst <= 'd1;
    else
        r_crc_rst <= r_crc_rst;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_crc_en <= 'd0;
    else if(!ri_gmii_valid && ri_gmii_valid_1d)
        r_crc_en <= 'd0;
    else if(r_recv_5d_cnt == 7)//除去前导码和校验码的数据才需要进行校验，所以也只需要对打5拍后的数据进行校验
        r_crc_en <= 'd1;
    else
        r_crc_en <= r_crc_en;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_crc_en_1d <= 'd0;
    else
        r_crc_en_1d <= r_crc_en;
end

//接收数据自带的crc结果
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_crc_recv <= 'd0;
    else if(ri_gmii_valid_1d)
        // r_crc_recv <= {r_crc_recv[23:0],ri_gmii_data_1d};
        r_crc_recv <= {ri_gmii_data,r_crc_recv[31:8]};
    else
        r_crc_recv <= r_crc_recv;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_crc_valid <= 'd0;
    else if(!r_crc_en && r_crc_en_1d)
        ro_crc_valid <= 'd1;
    else
        ro_crc_valid <= 'd0;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_crc_error <= 'd0;
    else if(!P_CRC_CHECK)
        ro_crc_error <= 'd0;
    else if(!r_crc_en && r_crc_en_1d && r_crc_recv != w_crc_result)
        ro_crc_error <= 'd1;
    else
        ro_crc_error <= 'd0;
end


endmodule   
