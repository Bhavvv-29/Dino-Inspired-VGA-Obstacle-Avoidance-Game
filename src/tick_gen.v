module tick_gen (
    input clk, rst_n, sync,
    output ball_tick, obs_tick
);  

    localparam COUNT_WIDTH = 21;
    reg [COUNT_WIDTH-1:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 0;
        else if(sync)
            count <= 0;
        else
            count <= count+1;
    end
    
    assign ball_tick = (count=={COUNT_WIDTH{1'b1}});
    assign obs_tick = (count[COUNT_WIDTH-8:0] == {(COUNT_WIDTH-7){1'b1}});
endmodule

            
            