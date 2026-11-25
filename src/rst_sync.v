`default_nettype none

module rst_sync(
    input wire clk, arstn,
    output reg srstn
);
    reg d;

    always @(posedge clk or negedge arstn) begin
        if(!arstn)
            {srstn, d} <= 2'b00;
        else
            {srstn, d} <= {d, 1'b1};
    end
endmodule
