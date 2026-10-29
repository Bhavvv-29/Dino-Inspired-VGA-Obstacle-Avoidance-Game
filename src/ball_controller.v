module ball_controller #(
    parameter GROUND_Y=400,
    parameter GRAVITY_SCALE=2000
)(
    input clk, rst_n, jmp_in, tick, stop,
    output reg [9:0] ball_y
);

    localparam signed BALL_INITIAL_SPEED = -13;

    reg signed [9:0] ball_speed;

    wire [9:0] ball_speed_abs = ball_speed[9] ? -ball_speed : ball_speed;
    wire ball_dir = ball_speed[9]; 

    reg [15:0] count;
    reg [15:0] period;

    always @(*) begin
        if      (ball_speed_abs > 30) period = GRAVITY_SCALE;
        else if (ball_speed_abs > 25) period = GRAVITY_SCALE * 3 / 2;
        else if (ball_speed_abs > 20) period = GRAVITY_SCALE * 2;
        else if (ball_speed_abs > 16) period = GRAVITY_SCALE * 3;
        else if (ball_speed_abs > 12) period = GRAVITY_SCALE * 4;
        else if (ball_speed_abs > 9)  period = GRAVITY_SCALE * 6;
        else if (ball_speed_abs > 6)  period = GRAVITY_SCALE * 8;
        else if (ball_speed_abs > 3)  period = GRAVITY_SCALE * 10;
        else if (ball_speed_abs > 0)  period = GRAVITY_SCALE * 12;
        else                          period = 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            count <= 0;
        else 
            count <= (count==period) ? 0 : count+1;
    end     

    // ball speed logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ball_speed <= 0;
        else if (jmp_in && ball_y==GROUND_Y && ball_speed==0)
            ball_speed <= BALL_INITIAL_SPEED;
        else if (tick) begin
            if (ball_y >= GROUND_Y && ball_speed >= 0)
                ball_speed <= 0;
            else
                ball_speed <= ball_speed + 5;
        end
    end 

    // ball position logic  
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ball_y <= GROUND_Y;
        else if (count==period) begin
            if (ball_y >= GROUND_Y && !ball_dir && ball_speed_abs != 0)
                ball_y <= GROUND_Y;
            else if(ball_speed_abs!=0 && !stop)
                ball_y <= ball_dir ? ball_y-1 : ball_y+1;
        end
    end
endmodule