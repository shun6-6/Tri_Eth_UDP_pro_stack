`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/13 19:46:22
// Design Name: 
// Module Name: ARP_table
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


module ARP_table(
    input           i_clk           ,
    input           i_rst           ,

    input  [31:0]   i_seek_ip       ,
    input           i_seek_valid    ,
    input  [31:0]   i_updata_ip     ,
    input  [47:0]   i_updata_mac    ,
    input           i_updata_valid  ,

    output [47:0]   o_active_mac    ,
    output          o_active_valid  
);
/******************************function***************************/

/******************************parameter**************************/
localparam      P_ST_RAM_DEPTH  = 8;
localparam      P_ST_IDLE       = 0,
                P_ST_SEEK       = 1,
                P_ST_UP_SEEK    = 2,
                P_ST_UPDATA     = 3,
                P_ST_MAC        = 4;
/******************************port*******************************/

/******************************machine****************************/
reg [7 :0]      r_st_cur            ;
reg [7 :0]      r_st_nxt            ;
/******************************reg********************************/
reg             ri_seek_valid       ;
reg             ri_updata_valid     ;
reg  [31:0]     r_seek_ip           ;
reg  [31:0]     r_updata_ip         ;
reg  [47:0]     r_updata_mac        ;
reg  [47:0]     ro_active_mac       ;
reg             ro_active_valid     ;
//ram single
reg             r_ip_ram_en         ;
reg             r_ip_ram_we         ;
reg  [2 :0]     r_ip_ram_addr       ;
reg             r_mac_ram_en        ;
reg             r_mac_ram_we        ;
reg  [2 :0]     r_mac_ram_addr      ;
reg             w_ip_ram_dout_valid ;
reg             w_mac_ram_dout_valid;
reg             r_seek_ip_access    ;//在IP表当中匹配到当前查询IP
reg  [2 :0]     r_access_ip_ram_addr;//匹配成功的IP在ram当中的地址
reg             r_ip_ram_end        ;
reg             r_ip_ram_end_1d     ;
//updata ram
reg             r_updata_access     ;
reg  [2 :0]     r_updata_ram_addr   ;
/******************************wire*******************************/
wire [31:0]     w_ip_ram_dout       ;
wire [31:0]     w_mac_ram_dout      ;
wire            w_ip_ram_end_neg    ;
/******************************component**************************/
RAM_IP RAM_IP_u0 (
  .clka     (i_clk          ),     
  .ena      (r_ip_ram_en    ),     
  .wea      (r_ip_ram_we    ),     
  .addra    (r_ip_ram_addr  ),     
  .dina     (r_updata_ip    ),     
  .douta    (w_ip_ram_dout  )      
);
RAM_MAC RAM_MAC_u0 (
  .clka     (i_clk          ),     
  .ena      (r_mac_ram_en   ),     
  .wea      (r_mac_ram_we   ),     
  .addra    (r_mac_ram_addr ),     
  .dina     (r_updata_mac   ),     
  .douta    (w_mac_ram_dout )      
);
/******************************assign*****************************/
assign  o_active_mac        =   ro_active_mac  ;
assign  o_active_valid      =   ro_active_valid;
assign  w_ip_ram_end_neg    =   !r_ip_ram_end & r_ip_ram_end_1d;
/******************************always*****************************/
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_seek_ip <= 'd0;
    else if(i_seek_valid)
        r_seek_ip <= i_seek_ip;
    else
        r_seek_ip <= r_seek_ip;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        r_updata_ip  <= 'd0;
        r_updata_mac <= 'd0;        
    end
    else if(i_updata_valid)begin
        r_updata_ip  <= i_updata_ip ;
        r_updata_mac <= i_updata_mac;        
    end
    else begin
        r_updata_ip  <= r_updata_ip ;
        r_updata_mac <= r_updata_mac;        
    end
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        ri_seek_valid <= 'd0;
        ri_updata_valid <= 'd0;        
    end
    else begin
        ri_seek_valid <= i_seek_valid;
        ri_updata_valid <= i_updata_valid;        
    end
end
//FSM
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_st_cur <= P_ST_IDLE;
    else
        r_st_cur <= r_st_nxt;
end

always @(*)begin
    case (r_st_cur)
        P_ST_IDLE    : begin
            if(ri_seek_valid)
                r_st_nxt = P_ST_SEEK;
            else if(ri_updata_valid)
                r_st_nxt = P_ST_UP_SEEK;//更新table之前先检查表中是否已有相应的IP和mac
            else 
                r_st_nxt = P_ST_IDLE;
        end
        P_ST_SEEK    : begin
            if(r_seek_ip_access || (w_ip_ram_end_neg && !r_seek_ip_access))
                r_st_nxt = P_ST_MAC;
            else
                r_st_nxt = P_ST_SEEK;
        end
        P_ST_UP_SEEK : begin
            if(r_updata_access)
                r_st_nxt = P_ST_IDLE;
            else if(w_ip_ram_end_neg && !r_updata_access)
                r_st_nxt = P_ST_UPDATA;
            else
                r_st_nxt = P_ST_UP_SEEK;
        end 
        P_ST_UPDATA  : r_st_nxt = P_ST_IDLE;  
        P_ST_MAC     : r_st_nxt = P_ST_IDLE;    
        default      : r_st_nxt = P_ST_IDLE; 
    endcase
end
//查IP表
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        r_ip_ram_en   <= 'd0;
        r_ip_ram_we   <= 'd0;
        //r_ip_ram_addr <= 'd0;        
    end
    else if(r_st_cur == P_ST_SEEK && !r_ip_ram_end)begin
        r_ip_ram_en   <= 'd1;
        r_ip_ram_we   <= 'd0;     
    end
    else if(r_st_cur == P_ST_UP_SEEK && !r_ip_ram_end)begin
        r_ip_ram_en   <= 'd1;
        r_ip_ram_we   <= 'd0;       
    end
    else if(r_st_cur == P_ST_UPDATA)begin
        r_ip_ram_en   <= 'd1;
        r_ip_ram_we   <= 'd1;       
    end
    else begin
        r_ip_ram_en   <= 'd0;
        r_ip_ram_we   <= 'd0;      
    end   
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_ip_ram_addr <= 'd0; 
    else if(r_st_cur == P_ST_SEEK && r_ip_ram_en && !r_ip_ram_we)
        r_ip_ram_addr <= r_ip_ram_addr + 'd1; 
    else if(r_st_cur == P_ST_UPDATA)
        r_ip_ram_addr <= r_updata_ram_addr; 
    else
        r_ip_ram_addr <= 'd0;    
end
//查mac表
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        r_mac_ram_en   <= 'd0;
        r_mac_ram_we   <= 'd0;       
    end
    else if(r_st_cur == P_ST_UP_SEEK && !r_ip_ram_end)begin
        r_mac_ram_en   <= 'd1;
        r_mac_ram_we   <= 'd0;       
    end
    else if(r_st_cur == P_ST_UPDATA)begin
        r_mac_ram_en   <= 'd1;
        r_mac_ram_we   <= 'd1;       
    end
    else if(w_ip_ram_dout == r_seek_ip && w_ip_ram_dout_valid)begin
        r_mac_ram_en   <= 'd1;
        r_mac_ram_we   <= 'd0;       
    end
    else begin
        r_mac_ram_en   <= 'd0;
        r_mac_ram_we   <= 'd0;      
    end   
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_mac_ram_addr <= 'd0; 
    else if(r_mac_ram_en)
        r_mac_ram_addr <= r_mac_ram_addr + 'd1; 
    else if(r_st_cur == P_ST_UPDATA)
        r_mac_ram_addr <= r_updata_ram_addr;
    else if(w_ip_ram_dout == r_seek_ip && w_ip_ram_dout_valid)
        r_mac_ram_addr <= r_access_ip_ram_addr;
    else
        r_mac_ram_addr <= 'd0;    
end

//指示ip ram读出数据有效，ram读数据延迟一拍
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        w_ip_ram_dout_valid <= 'd0;
    else if(r_ip_ram_en && !r_ip_ram_we && !r_seek_ip_access)
        w_ip_ram_dout_valid <= 'd1;
    else
        w_ip_ram_dout_valid <= 'd0;   
end
//表示查询到了相应的的IP地址
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_seek_ip_access <= 'd0;
    else if(r_st_cur == P_ST_IDLE)
        r_seek_ip_access <= 'd0;
    else if(w_ip_ram_dout == r_seek_ip && w_ip_ram_dout_valid)
        r_seek_ip_access <= 'd1;
    else
        r_seek_ip_access <= r_seek_ip_access;
end
//指示当前已经来到了IP ram的最后地址
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_ip_ram_end <= 'd0;
    else if(r_st_cur != P_ST_SEEK)
        r_ip_ram_end <= 'd0;
    else if(r_st_cur == P_ST_SEEK && r_ip_ram_addr == P_ST_RAM_DEPTH - 1)
        r_ip_ram_end <= 'd1;
    else
        r_ip_ram_end <= r_ip_ram_end;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_ip_ram_end_1d <= 'd0;
    else
        r_ip_ram_end_1d <= r_ip_ram_end;
end
//指示查到的IP在IP ram当中的地址，可根据此地址获取IP所对应的mac
always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_access_ip_ram_addr <= 'd0;
    else if(r_st_cur == P_ST_IDLE)
        r_access_ip_ram_addr <= 'd0;
    else if(w_ip_ram_dout_valid && !r_seek_ip_access)
        r_access_ip_ram_addr <= r_access_ip_ram_addr + 1;
    else
        r_access_ip_ram_addr <= r_access_ip_ram_addr;  
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_updata_access <= 'd0;
    else if(r_st_cur == P_ST_IDLE)
        r_updata_access <= 'd0;
    else if(r_st_cur == P_ST_UP_SEEK && w_ip_ram_dout_valid && w_ip_ram_dout == r_updata_ip && w_mac_ram_dout == r_updata_mac)
        r_updata_access <= 'd1;
    else
        r_updata_access <= r_updata_access;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        r_updata_ram_addr <= 'd0;
    else if(r_st_cur == P_ST_UPDATA && r_st_nxt != P_ST_UPDATA)
        r_updata_ram_addr <= r_updata_ram_addr + 'd1;
    else
        r_updata_ram_addr <= r_updata_ram_addr;
end
  

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_active_mac <= 'd0;
    else if(r_st_cur == P_ST_MAC)
        ro_active_mac <= w_mac_ram_dout;
    else
        ro_active_mac <= 48'hffff_ffff_ffff;
end

always @(posedge i_clk or posedge i_rst)begin
    if(i_rst)
        ro_active_valid <= 'd0;
    else if(r_st_cur == P_ST_MAC)
        ro_active_valid <= 'd1;
    else
        ro_active_valid <= 'd0;
end

endmodule
