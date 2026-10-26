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