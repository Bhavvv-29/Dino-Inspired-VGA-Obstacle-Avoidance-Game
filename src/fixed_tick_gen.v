module fixed_tick_gen #(
    parameter MAX_COUNT=100_000
  )(
    input clk, rst_n,
    output tick
); 
    reg [20:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 0;
        else
            count <= (count>=MAX_COUNT) ? 0 : count+1;
    end

    assign tick = (count>=MAX_COUNT);
endmodule

            
            