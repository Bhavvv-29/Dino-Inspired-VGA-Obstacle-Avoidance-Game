`default_nettype none

module tick_gen #(
    parameter OBSTACLE_SPEED=7
)(
    input wire clk, rst_n, sync,
    output wire ball_tick, obs_tick
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
    
    assign ball_tick = (count=={COUNT_WIDTH{1'b1}});   // simple counter based pulse generator

    // obstacle tick occurs more frequently as the comparison is only done for the upper bits. hence, the actual obstacle speed scales exponentially with the OBSTACLE_SPEED parameter
    assign obs_tick = (count[COUNT_WIDTH-OBSTACLE_SPEED:0] == {(COUNT_WIDTH-OBSTACLE_SPEED+1){1'b1}});  
endmodule

            
            