module fixed_tick_gen (
    input clk, rst_n,
    output tick, obs_tick
);  

    localparam COUNT_WIDTH = 21;
    reg [COUNT_WIDTH-1:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 0;
        else
            count <= count+1;
    end
    
    assign tick = (count=={COUNT_WIDTH{1'b1}});
    assign obs_tick = (count[COUNT_WIDTH-7:0] == {(COUNT_WIDTH-6){1'b1}});
endmodule

            
            