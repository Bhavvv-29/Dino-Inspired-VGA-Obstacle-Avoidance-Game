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