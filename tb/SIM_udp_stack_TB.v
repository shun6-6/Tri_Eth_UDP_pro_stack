`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/05 19:27:48
// Design Name: 
// Module Name: SIM_udp_stack_TB
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


module SIM_udp_stack_TB();

localparam      P_SEND_LEN  = 100;
reg clk,rst;

always begin
    clk = 1;
    #10;
    clk = 0;
    #10;
end

initial begin
    rst = 1;
    #50;
    @(posedge clk) rst = 0;
end

wire [7 :0]     w_gmii_data_0         ;
wire            w_gmii_valid_0        ;
wire            w_send_ready        ;

wire [7 :0]     w_gmii_data_1         ;
wire            w_gmii_valid_1        ;
//send udp
reg  [7 :0]     r_send_udp_data     ;
reg  [15:0]     r_send_udp_len      ;
reg             r_send_udp_last     ;
reg             r_send_udp_valid    ;
reg  [15:0]     r_start_cnt;
reg  [15:0]     r_send_cnt          ;

//send arp
wire [7 :0]     o_mac_data_arp ;
wire            o_mac_last_arp ;
wire            o_mac_valid_arp;
reg             r_active_req        ;
wire [7 :0]     w_gmii_data_arp     ;
wire            w_gmii_valid_arp    ;

//send icmp
reg             r_trig_reply    ;

wire [7 :0]     w_icmp_data ;
wire [15:0]     w_icmp_len  ;
wire            w_icmp_last ;
wire            w_icmp_valid;

wire [15:0]     w_mac_type_ip ;
wire [7 :0]     w_mac_data_ip ;
wire [15:0]     w_mac_len_ip  ;
wire            w_mac_last_ip ;
wire            w_mac_valid_ip;

wire [7 :0]     w_gmii_data_icmp     ;
wire            w_gmii_valid_icmp    ;

wire [7 :0]     w_tx_data   ;
wire            w_tx_valid  ;

wire w_user_clk;

UDP_Stack_TOP#(
    .P_DST_UDP_PORT         (16'h8080                              )   ,
    .P_SRC_UDP_PORT         (16'h8080                              )   ,
    .P_DST_IP               ({8'd192,8'd168,8'd01,8'd0}            )   ,
    .P_SRC_IP               ({8'd192,8'd168,8'd01,8'd0}            )   ,
    .P_SRC_MAC              ({8'h11,8'h11,8'h00,8'h00,8'h00,8'h00} )   ,
    //.P_DEST_MAC             ({8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} )   ,
    .P_DEST_MAC             ({8'hb4,8'hb6,8'h86,8'hd6,8'h83,8'hb8}  )   ,
    .P_CRC_CHECK            (1                                     )
)UDP_Stack_TOP_u0(
    .i_clk                  (w_user_clk                    ),
    .i_rst                  (rst                    ),

    .i_dst_udp_port         ('d0                    ),
    .i_dst_udp_valid        ('d0                    ),
    .i_src_udp_port         ('d0                    ),
    .i_src_udp_valid        ('d0                    ),
    .i_dst_ip               ('d0                    ),
    .i_dst_ip_valid         ('d0                    ),
    .i_src_ip               ('d0                    ),
    .i_src_ip_valid         ('d0                    ),
    .i_src_mac              (48'd0                    ),
    .i_src_mac_valid        ('d0                    ),
    .i_dest_mac             (48'd0                    ),
    .i_dest_mac_valid       ('d0                    ),

    .i_send_udp_data        (r_send_udp_data        ),
    .i_send_udp_len         (r_send_udp_len         ),
    .i_send_udp_last        (r_send_udp_last        ),
    .i_send_udp_valid       (r_send_udp_valid       ),
    .o_send_ready           (w_send_ready           ),

    .o_recv_udp_data        (),
    .o_recv_udp_len         (),
    .o_recv_udp_last        (),
    .o_recv_udp_valid       (),

    .o_recv_src_mac         (),
    .o_recv_src_mac_valid   (),
    .o_crc_error            (),
    .o_crc_valid            (),
    .o_recv_src_ip          (),
    .o_recv_src_valid       (),

    .i_gmii_data            (w_gmii_data_0             ),
    .i_gmii_valid           (w_gmii_valid_0           ),
    .o_gmii_data            (w_gmii_data_0            ),
    .o_gmii_valid           (w_gmii_valid_0           ) 
);

RGMII_RAM RGMII_RAM_u0(
    .i_udp_stack_clk    (w_user_clk),
    .i_gmii_tx_data     (w_gmii_data_0 ),
    .i_gmii_tx_valid    (w_gmii_valid_0),
    .o_gmii_rx_data     (),
    .o_gmii_rx_valid    (),

    .i_rxc              (w_user_clk          ),
    .o_tx_data          (w_tx_data      ),
    .o_tx_valid         (w_tx_valid     ),  

    .i_speed1000        (1    ),
    .i_rx_data          (0     ),
    .i_rx_valid         (0     ),      
    .i_rx_end           (0     )
);

RGMII_Tri RGMII_Tri_u0(
    .i_rxc              (clk          ),
    .i_rxd              (0          ),
    .i_rx_ctrl          (0      ),
    .o_txc              (o_txc          ),
    .o_txd              (o_txd          ),
    .o_tx_ctrl          (o_tx_ctrl      ),

    .o_rxc              (w_user_clk          ),
    //.i_speed1000        (i_speed1000    ),
    .i_tx_data          (w_tx_data      ),
    .i_tx_valid         (w_tx_valid     ), 

    .o_rx_data          (     ),
    .o_rx_valid         (     ),        
    .o_rx_end           (     ),
    .o_speed            (     ),
    .o_link             (     )
);

UDP_Stack_TOP#(
    .P_DST_UDP_PORT         (16'h8080                              )   ,
    .P_SRC_UDP_PORT         (16'h8080                              )   ,
    .P_DST_IP               ({8'd192,8'd168,8'd01,8'd0}            )   ,
    .P_SRC_IP               ({8'd192,8'd168,8'd01,8'd1}            )   ,
    .P_SRC_MAC              ({8'h22,8'h22,8'h00,8'h00,8'h00,8'h00} )   ,
    .P_DEST_MAC             ({8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} )   ,
    .P_CRC_CHECK            (1                                     )
)UDP_Stack_TOP_u1(
    .i_clk                  (clk                    ),
    .i_rst                  (rst                    ),

    .i_dst_udp_port         ('d0                    ),
    .i_dst_udp_valid        ('d0                    ),
    .i_src_udp_port         ('d0                    ),
    .i_src_udp_valid        ('d0                    ),
    .i_dst_ip               ('d0                    ),
    .i_dst_ip_valid         ('d0                    ),
    .i_src_ip               ('d0                    ),
    .i_src_ip_valid         ('d0                    ),
    .i_src_mac              (48'd0                    ),
    .i_src_mac_valid        ('d0                    ),
    .i_dest_mac             (48'd0                    ),
    .i_dest_mac_valid       ('d0                    ),

    .i_send_udp_data        (       ),
    .i_send_udp_len         (       ),
    .i_send_udp_last        (       ),
    .i_send_udp_valid       (       ),
    .o_send_ready           (       ),

    .o_recv_udp_data        (),
    .o_recv_udp_len         (),
    .o_recv_udp_last        (),
    .o_recv_udp_valid       (),

    .o_recv_src_mac         (),
    .o_recv_src_mac_valid   (),
    .o_crc_error            (),
    .o_crc_valid            (),
    .o_recv_src_ip          (),
    .o_recv_src_valid       (),

    .i_gmii_data            (w_gmii_data_0 ),
    .i_gmii_valid           (w_gmii_valid_0),
    .o_gmii_data            (w_gmii_data_1 ),
    .o_gmii_valid           (w_gmii_valid_1) 
);

UDP_Stack_TOP#(
    .P_DST_UDP_PORT         (16'h8080                              )   ,
    .P_SRC_UDP_PORT         (16'h8080                              )   ,
    .P_DST_IP               ({8'd192,8'd168,8'd01,8'd0}            )   ,
    .P_SRC_IP               ({8'd192,8'd168,8'd01,8'd1}            )   ,
    .P_SRC_MAC              ({8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} )   ,
    .P_DEST_MAC             ({8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} )   ,
    .P_CRC_CHECK            (1                                     )
)UDP_Stack_TOP_u2(
    .i_clk                  (clk                    ),
    .i_rst                  (rst                    ),

    .i_dst_udp_port         ('d0                    ),
    .i_dst_udp_valid        ('d0                    ),
    .i_src_udp_port         ('d0                    ),
    .i_src_udp_valid        ('d0                    ),
    .i_dst_ip               ('d0                    ),
    .i_dst_ip_valid         ('d0                    ),
    .i_src_ip               ('d0                    ),
    .i_src_ip_valid         ('d0                    ),
    .i_src_mac              (48'd0                    ),
    .i_src_mac_valid        ('d0                    ),
    .i_dest_mac             (48'd0                    ),
    .i_dest_mac_valid       ('d0                    ),

    .i_send_udp_data        (      ),
    .i_send_udp_len         (      ),
    .i_send_udp_last        (      ),
    .i_send_udp_valid       (      ),
    .o_send_ready           (      ),

    .o_recv_udp_data        (),
    .o_recv_udp_len         (),
    .o_recv_udp_last        (),
    .o_recv_udp_valid       (),

    .o_recv_src_mac         (),
    .o_recv_src_mac_valid   (),
    .o_crc_error            (),
    .o_crc_valid            (),
    .o_recv_src_ip          (),
    .o_recv_src_valid       (),

    .i_gmii_data            (w_gmii_data_icmp   ),
    .i_gmii_valid           (w_gmii_valid_icmp  ),
    .o_gmii_data            (          ),
    .o_gmii_valid           (          ) 
);

ARP_TX#(
    .P_DST_IP           ({8'd192,8'd168,8'd01,8'd0}           ),
    .P_SRC_IP           ({8'd192,8'd168,8'd01,8'd1}           ),
    .P_SRC_MAC          ({8'h00,8'h00,8'h00,8'h00,8'h00,8'h01})
)ARP_TX_u0(
    .i_clk              (clk          ),
    .i_rst              (rst          ),  

    .i_dst_ip           ('d0), 
    .i_dst_ip_valid     ('d0),
    .i_src_ip           ('d0), 
    .i_src_ip_valid     ('d0),
    .i_src_mac          (48'd0), 
    .i_src_mac_valid    ('d0),  

    .i_trig_reply       (0   ),
    .i_active_req       (r_active_req), 

    .o_mac_data         (o_mac_data_arp     ),
    .o_mac_last         (o_mac_last_arp     ),
    .o_mac_valid        (o_mac_valid_arp    )
);
MAC_TX#(
    .P_SRC_MAC   ({8'h00,8'h00,8'h00,8'h00,8'h00,8'h01} ),
    .P_DEST_MAC  ({8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} ),
    .P_CRC_CHECK (1)
)MAC_TX_u0(
    .i_clk                  (clk                  ),
    .i_rst                  (rst                  ),
            
    .i_src_mac              (  'd0),
    .i_src_mac_valid        (  'd0),
    .i_dest_mac             (48'd0),
    .i_dest_mac_valid       (  'd0),
            
    .i_send_type            (16'h0806           ),
    .i_send_data            (o_mac_data_arp     ),
    .i_send_len             ('d46),
    .i_send_last            (o_mac_last_arp     ),
    .i_send_valid           (o_mac_valid_arp    ),
    
    .o_gmii_data            (w_gmii_data_arp    ),
    .o_gmii_valid           (w_gmii_valid_arp   ) 
);

ICMP_TX ICMP_TX_u0(
    .i_clk           (clk         ),
    .i_rst           (rst         ),

    .i_trig_reply    (r_trig_reply  ),
    .i_trig_seq      (0    ),

    .o_icmp_data     (w_icmp_data ),
    .o_icmp_len      (w_icmp_len  ),
    .o_icmp_last     (w_icmp_last ),
    .o_icmp_valid    (w_icmp_valid) 
);
IP_TX#(
    .P_DST_IP           ({8'd192,8'd168,8'd01,8'd1}),
    .P_SRC_IP           ({8'd192,8'd168,8'd01,8'd0})
)IP_TX_u0(
    .i_clk              (clk              ),
    .i_rst              (rst              ),

    .i_dst_ip           (0),
    .i_dst_ip_valid     (0),
    .i_src_ip           (0),
    .i_src_ip_valid     (0),

    .i_send_data        (w_icmp_data        ),
    .i_send_type        ('d1          ),
    .i_send_len         (w_icmp_len         ),
    .i_send_last        (w_icmp_last        ),
    .i_send_valid       (w_icmp_valid       ),

    // .o_seek_ip          (o_seek_ip          ),
    // .o_seek_valid       (o_seek_valid       ),

    .o_mac_type         (w_mac_type_ip         ),
    .o_mac_data         (w_mac_data_ip         ),
    .o_mac_len          (w_mac_len_ip          ),
    .o_mac_last         (w_mac_last_ip         ),
    .o_mac_valid        (w_mac_valid_ip        ) 
);

MAC_TX#(
    .P_SRC_MAC   ({8'h00,8'h00,8'h00,8'h00,8'h00,8'h01} ),
    .P_DEST_MAC  ({8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} ),
    .P_CRC_CHECK (1)
)MAC_TX_u1(
    .i_clk                  (clk                  ),
    .i_rst                  (rst                  ),
            
    .i_src_mac              (  'd0),
    .i_src_mac_valid        (  'd0),
    .i_dest_mac             (48'd0),
    .i_dest_mac_valid       (  'd0),
            
    .i_send_type            (w_mac_type_ip     ),
    .i_send_data            (w_mac_data_ip     ),
    .i_send_len             (w_mac_len_ip       ),
    .i_send_last            (w_mac_last_ip     ),
    .i_send_valid           (w_mac_valid_ip    ),
    
    .o_gmii_data            (w_gmii_data_icmp    ),
    .o_gmii_valid           (w_gmii_valid_icmp   ) 
);


always @(posedge clk or posedge rst)begin
    if(rst)
        r_start_cnt <= 'd0;
    else if(r_start_cnt == 100)
        r_start_cnt <= r_start_cnt;
    else
        r_start_cnt <= r_start_cnt + 1;
end

always @(posedge clk or posedge rst)begin
    if(rst)
        r_send_cnt <= 'd0;
    else if(r_send_cnt == P_SEND_LEN - 1)
        r_send_cnt <= 'd0;
    else if(r_send_udp_valid)
        r_send_cnt <= r_send_cnt + 1;
    else
        r_send_cnt <= r_send_cnt;
end

always @(posedge clk or posedge rst)begin
    if(rst)
        r_send_udp_valid <= 'd0;
    else if(r_send_cnt == P_SEND_LEN - 1)
        r_send_udp_valid <= 'd0;
    else if(r_start_cnt == 100 && w_send_ready)
        r_send_udp_valid <= 'd1;
    else
        r_send_udp_valid <= r_send_udp_valid;
end

always @(posedge clk or posedge rst)begin
    if(rst)
        r_send_udp_data <= 'd0;
    else if(r_send_udp_valid)
        r_send_udp_data <= r_send_udp_data + 1;
    else
        r_send_udp_data <= 'd0;
end

always @(posedge clk or posedge rst)begin
    if(rst)
        r_send_udp_last <= 'd0;
    else if(r_send_cnt == P_SEND_LEN - 2)
        r_send_udp_last <= 'd1;
    else
        r_send_udp_last <= 'd0;
end

always @(posedge clk or posedge rst)begin
    if(rst)
        r_send_udp_len <= 'd0;
    else
        r_send_udp_len <= P_SEND_LEN;
end



// initial begin
//     r_send_udp_data  <= 'd0;
//     r_send_udp_len   <= 'd0;
//     r_send_udp_last  <= 'd0;
//     r_send_udp_valid <= 'd0;
//     r_active_req <= 'd0;
//     wait(!rst);
//     repeat(10) @(posedge clk);
//     ARP_send();
//     repeat(80) @(posedge clk);
//     ICMP_send();
//     repeat(200) @(posedge clk);
//     UDP_Send_Data(30);   //udp len : 18-1472
//     repeat(80) @(posedge clk);
//     UDP_Send_Data(30);
//     // repeat(80) @(posedge clk);
//     // UDP_Send_Data(30);
 
// end


// task UDP_Send_Data(input [15:0] byte_len);
// begin : udp_send
//     integer i;
//     r_send_udp_data  <= 'd0;
//     r_send_udp_len   <= 'd0;
//     r_send_udp_last  <= 'd0;
//     r_send_udp_valid <= 'd0;
//     @(posedge clk);
//     wait(w_send_ready);
//     @(posedge clk);
//     for(i = 0; i < byte_len; i = i + 1)begin
//         r_send_udp_data  <= i;
//         r_send_udp_len   <= byte_len;
//         if(i == byte_len - 1)
//             r_send_udp_last  <= 'd1;
//         else
//             r_send_udp_last  <= 'd0;
//             r_send_udp_valid <= 'd1;  
//         @(posedge clk);    
//     end
//     r_send_udp_data  <= 'd0;
//     r_send_udp_len   <= 'd0;
//     r_send_udp_last  <= 'd0;
//     r_send_udp_valid <= 'd0;
//     @(posedge clk);
// end
// endtask


// task ARP_send();
// begin:arp_send
//     r_active_req <= 'd0;
//     @(posedge clk); 
//     wait(w_send_ready);
//     @(posedge clk); 
//     r_active_req <= 'd1;
//     @(posedge clk);
//     r_active_req <= 'd0; 
// end
// endtask

// task ICMP_send();
// begin : icmp_send
//     r_trig_reply <= 'd0;
//     @(posedge clk); 
//     wait(w_send_ready);
//     @(posedge clk); 
//     r_trig_reply <= 'd1;
//     @(posedge clk);
//     r_trig_reply <= 'd0; 
// end
// endtask



endmodule
