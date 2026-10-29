module LFSR #(
    parameter N = 16,
    parameter [N-1:0] TAPS = 16'b1000100001010011,
    parameter [N-1:0] SEED = 16'b1001000110011011
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