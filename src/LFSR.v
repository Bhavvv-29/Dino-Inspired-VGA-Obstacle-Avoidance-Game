`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.10.2026 10:41:35
// Design Name: 
// Module Name: LFSR
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
module LFSR(
input wire clk_25mhz, 
input wire rst,
input wire tick,
output reg bit
    );
    
   reg w1, w2, w3, w4, w5, w6;
    
   wire xor_out; 
  // always@(posedge clk_25mhz or negedge rst)begin 
  // if(!rst)
  //   {w1, w2, w3, w4, w5, w6} <= 6'b001100;
  // else 
    
  
  assign xor_out = w2 ^ w4; 
    
dff u_dff_1(.clk_25mhz(clk_25mhz), .d(xor_out), .rst(rst), .q(w1));
dff u_dff_2(.clk_25mhz(clk_25mhz), .d(w1), .rst(rst), .q(w2));
dff_1 u_dff_3(.clk_25mhz(clk_25mhz), .d(w2), .rst(rst), .q(w3));
dff_1 u_dff_4(.clk_25mhz(clk_25mhz), .d(w3), .rst(rst), .q(w4));
dff u_dff_5(.clk_25mhz(clk_25mhz), .d(w4), .rst(rst), .q(w5));
dff u_dff_6(.clk_25mhz(clk_25mhz), .d(w5), .rst(rst), .q(w6));

    always@(posedge clk_25mhz or negedge rst)begin
    if(!rst)
       bit <= 1'b0;
    else if (tick)
        bit <= w6;
    end
endmodule
*/

module LFSR #(
    parameter         N    = 6,
    parameter [N-1:0] TAPS = 6'b110000,
    parameter [N-1:0] SEED = 6'b001100
)(
    input  wire clk_25mhz,
    input  wire rst,
    input  wire tick,
    output reg  rand_bit
);

    wire [N-1:0] q;
    wire         xor_out;

    assign xor_out = ^(q & TAPS);

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : g_stage
            if (i == 0)
                dff #(.RST_VAL(SEED[i])) u_dff (.clk_25mhz(clk_25mhz), .rst(rst), .d(xor_out),  .q(q[i]));
            else
                dff #(.RST_VAL(SEED[i])) u_dff (.clk_25mhz(clk_25mhz), .rst(rst), .d(q[i-1]), .q(q[i]));
        end
    endgenerate

    always @(posedge clk_25mhz or negedge rst) begin
        if (!rst)
            rand_bit <= 1'b0;
        else if (tick)
            rand_bit <= q[N-1];
    end

endmodule