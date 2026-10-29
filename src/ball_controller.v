module ball_controller #(
    parameter GROUND_Y=400,
    parameter GRAVITY_SCALE=2000
)(
    input clk, rst_n, jmp_in, tick, stop,
    output reg [9:0] ball_y
);

    localparam signed [6:0] BALL_INITIAL_SPEED = -13;

    // speed only ever needs -13..+32 (see saturation below) -> 7 bits instead of 10
    reg signed [6:0] ball_speed;

    wire        ball_dir       = ball_speed[6];
    wire [6:0]  speed_abs7     = ball_dir ? -ball_speed : ball_speed;
    wire [5:0]  ball_speed_abs = speed_abs7[5:0];
    wire        moving         = |ball_speed;
    wire        at_ground      = (ball_y == GROUND_Y);   // ball_y never goes below the ground line
    wire        speed_sat      = !ball_dir && ball_speed[5];  // speed >= 32: same period bucket as the original (>30)

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

    wire period_hit = (count == period);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 0;
        else
            count <= period_hit ? 16'd0 : count+1'b1;
    end

    // ball speed logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ball_speed <= 0;
        else if (jmp_in && at_ground && !moving)
            ball_speed <= BALL_INITIAL_SPEED;
        else if (tick) begin
            if (at_ground && !ball_dir)
                ball_speed <= 0;
            else if (!speed_sat)
                ball_speed <= ball_speed + 7'sd5;
        end
    end

    // ball position logic: one +/-1 adder instead of an incrementer, a decrementer and a mux
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ball_y <= GROUND_Y;
        else if (period_hit && moving && !stop && !(at_ground && !ball_dir))
            ball_y <= ball_y + {{9{ball_dir}}, 1'b1};
    end
endmodule