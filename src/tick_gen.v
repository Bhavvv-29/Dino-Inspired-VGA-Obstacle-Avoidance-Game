module tick_gen #(
    parameter OBSTACLE_SPEED=7
)(
    input clk, rst_n, sync,
    output ball_tick, obs_tick
);

    localparam COUNT_WIDTH = 21;
    localparam LOW_W       = COUNT_WIDTH-OBSTACLE_SPEED+1;   // width of the obstacle-tick window

    reg [COUNT_WIDTH-1:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 0;
        else if (sync)
            count <= 0;
        else
            count <= count+1;
    end

    // share the AND-tree of the low bits between both ticks
    wire low_ones = &count[LOW_W-1:0];
    assign obs_tick  = low_ones;
    assign ball_tick = low_ones & (&count[COUNT_WIDTH-1:LOW_W]);
endmodule 