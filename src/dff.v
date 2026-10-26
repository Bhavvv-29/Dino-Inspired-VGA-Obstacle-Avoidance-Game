`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.10.2026 10:43:40
// Design Name: 
// Module Name: dff
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

/*
module dff(
input wire clk_25mhz,
input wire d,
input wire rst,
output reg q

    );
    
    always@(posedge clk_25mhz or negedge rst) begin
    
    if(!rst)
        q <= 1'b0;
    else 
        q <= d;
    end
    
endmodule
*/

module dff #(
    parameter RST_VAL = 1'b0
)(
    input  wire clk_25mhz,
    input  wire rst,
    input  wire d,
    output reg  q
);
    always @(posedge clk_25mhz or negedge rst) begin
        if (!rst)
            q <= RST_VAL;
        else
            q <= d;
    end
endmodule