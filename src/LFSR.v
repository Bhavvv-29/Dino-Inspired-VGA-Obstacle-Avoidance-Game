module LFSR #(
    parameter N = 6,
    parameter [N-1:0] TAPS = 6'b110000,
    parameter [N-1:0] SEED = 6'b001100
)(
    input clk, rst_n, 
    output reg [N-1:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= SEED;
        else 
            q <= {q[N-2:0], ^(q & TAPS)};   
    end
endmodule