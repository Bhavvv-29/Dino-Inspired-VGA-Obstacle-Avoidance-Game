module ball_tick_gen (
    input clk, rst_n,
    input [9:0] ball_speed,
    output ball_tick
);

    reg [15:0] count;
    reg [15:0] period;

    always @(*) begin
        if      (ball_speed > 30) period = 16'd5000;
        else if (ball_speed > 25) period = 16'd7500;
        else if (ball_speed > 20) period = 16'd10000;
        else if (ball_speed > 16) period = 16'd15000;
        else if (ball_speed > 12) period = 16'd20000;
        else if (ball_speed > 9)  period = 16'd30000;
        else if (ball_speed > 6)  period = 16'd40000;
        else if (ball_speed > 3)  period = 16'd50000;
        else if (ball_speed > 0)  period = 16'd60000;
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