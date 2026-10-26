module var_tick_gen (
    input clk,
    input rst_n,
    input [20:0] max_count,
    output tick
);

    reg [20:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 0;
        else
            count <= (count >= max_count) ? 0 : count+1;
    end

    assign tick = (count >= max_count);

endmodule