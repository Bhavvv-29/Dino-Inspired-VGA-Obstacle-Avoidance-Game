module ball_tick_gen (
    input clk, rst_n,
    input [9:0] ball_speed,
    output ball_tick
);

    reg [15:0] count;
    reg [15:0] period;

always @(*) begin
    if      (ball_speed > 30) period = 16'd2000;
    else if (ball_speed > 25) period = 16'd3000;
    else if (ball_speed > 20) period = 16'd4000;
    else if (ball_speed > 16) period = 16'd6000;
    else if (ball_speed > 12) period = 16'd8000;
    else if (ball_speed > 9)  period = 16'd12000;
    else if (ball_speed > 6)  period = 16'd16000;
    else if (ball_speed > 3)  period = 16'd20000;
    else if (ball_speed > 0)  period = 16'd24000;
    else                      period = 16'd0;
end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            count <= 0;
        else 
            count <= (count==period) ? 0 : count+1;
    end

    assign ball_tick = (count==period);
endmodule