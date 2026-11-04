    `default_nettype none

    module ball_controller #(
        parameter GROUND_Y=400,
        parameter GRAVITY_SCALE=2000,
        parameter signed [9:0] BALL_INITIAL_SPEED=-13
    )(
        input wire clk, rst_n, jmp_in, tick, stop,
        output reg [9:0] ball_y
    );

        reg signed [9:0] ball_speed;

        // split ball_speed into absolute ball speed and direction (0-down, 1-up)
        wire [9:0] ball_speed_abs = ball_speed[9] ? -ball_speed : ball_speed; 
        wire ball_dir = ball_speed[9]; 

        reg [15:0] count;
        reg [15:0] period;

        /* lut to check waiting time before updating the ball's y position, to emulate acceleration. waiting time is dependent on speed. 
            the parameter GRAVITY_SCALE can be configured to increase or decrease this acceleration */ 
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
            else if (stop) 
                ball_speed <= 0;
            else if (jmp_in && ball_y==GROUND_Y && ball_speed==0)  // set initial speed when jump is pressed, ball is on the ground and speed is 0
                ball_speed <= BALL_INITIAL_SPEED;
            else if (tick) begin
                if (ball_y >= GROUND_Y && ball_speed >= 0)  // if ball is on the ground and positive speed (falling down), set ball speed to 0
                    ball_speed <= 0;
                else
                    ball_speed <= ball_speed + 5;   // or else, on every tick, increment ball speed by 5  
            end
        end 

        // ball position logic  
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n)
                ball_y <= GROUND_Y;
            else if (count==period) begin  // check if lut defined count is reached (for waiting period)
                if (ball_y >= GROUND_Y && !ball_dir && ball_speed_abs != 0) // if ball is on the ground, and nonzero positive speed (falling down), set ball's y to GROUND_Y
                    ball_y <= GROUND_Y;
                else if(ball_speed_abs!=0 && !stop) // if ball's absolute speed is nonzero (independent of direction), and game is not over, update the ball's y position based on the direction of speed
                    ball_y <= ball_dir ? ball_y-1 : ball_y+1;
            end
        end
    endmodule