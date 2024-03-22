`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/25 10:55:03
// Design Name: 
// Module Name: crc_tb
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


module crc_tb();

localparam      P_CLK_PERIDO = 20;

reg  			clk   ;
reg  			rst   ;
reg  			i_en  ;
reg  [7 :0]	    i_data;
wire [31:0]	    o_crc ;

always begin
    clk = 0;
    #(P_CLK_PERIDO/2);
    clk = 1;
    #(P_CLK_PERIDO/2);
end

initial begin
    check_crc();
end

CRC32_D8 CRC32_D8_u0(
	.i_clk	(clk   ),
	.i_rst	(rst   ),
	.i_en	(i_en  ),
	.i_data	(i_data),
	.o_crc  (o_crc )	
);

task check_crc();
begin:check_crc
    i_en <= 'd0;
    i_data <= 'd0;
    rst <= 'd1;
    repeat(10)@(posedge clk);
    i_data <= 8'h00;
    i_en <= 'd1;
    rst <= 'd0;
    @(posedge clk);
    i_data <= 8'h00;
    i_en <= 'd0;
    rst <= 'd0;
    @(posedge clk);
    i_data <= 8'h00;
    i_en <= 'd0;
    rst <= 'd1;

    @(posedge clk);
    i_data <= 8'h00;
    i_en <= 'd1;
    rst <= 'd0;
    @(posedge clk);
    i_data <= 8'h00;
    i_en <= 'd1;
    rst <= 'd0;
    @(posedge clk);
    i_data <= 8'h00;
    i_en <= 'd0;
    rst <= 'd0;
    @(posedge clk);
    i_data <= 8'h00;
    i_en <= 'd0;
    rst <= 'd1;
    @(posedge clk);
end
endtask

endmodule
