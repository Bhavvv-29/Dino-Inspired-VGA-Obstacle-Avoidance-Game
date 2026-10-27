module tt_um_dino(
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock - 50Mhz
    input  wire       rst_n     // reset_n - low to reset
);

    // VGA signals
    wire hsync, vsync;
    wire video_active;
    wire [9:0] x, y;

    reg [1:0] R, G, B;
    
    // TinyVGA PMOD
    assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

    // Unused outputs assigned to 0.
    assign uio_out = 0;
    assign uio_oe  = 0;

    // hvsync generator
    hvsync_generator hvsync_gen(
    .clk(clk),
    .rst_n(rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(x),
    .vpos(y)
    );


    // edge detector
    wire jmp_in;
    reg jmp_in_reg;

    always @(posedge clk or negedge rst_n) begin
      if(!rst_n)
          jmp_in_reg <= 1'b0;
      else
          jmp_in_reg <= ui_in[0];
    end

    assign jmp_in = (ui_in[0]!=jmp_in_reg);

    // ball speed -------------------------------------------------------------------------------
    reg signed [9:0] ball_speed;

    wire [9:0] ball_speed_abs = ball_speed[9] ? -ball_speed : ball_speed;
    wire ball_dir = ball_speed[9]; 

    // tick generator ---------------------------------------------------------------------------
    wire tick, ball_tick, obs_tick;
    wire tick_sync;

    fixed_tick_gen u_tick (
        .clk(clk),
        .rst_n(rst_n),
        .sync(tick_sync),
        .tick(tick),
        .obs_tick(obs_tick)
    );

    ball_tick_gen u_ball_tick (
        .clk(clk),
        .rst_n(rst_n),
        .ball_speed(ball_speed_abs),
        .ball_tick(ball_tick)
    );

    // game over logic -------------------------------------------------------------------------
    reg game_over;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            game_over <= 1'b0;
        else if (video_active && inside_circle && inside_triangle)
            game_over <= 1'b1;
    end

    // game parameters ---------------------------------------------------------------------------
    localparam BALL_X = 100;
    localparam signed BALL_INITIAL_SPEED = -5;

    localparam GROUND_Y = 400;
    
    localparam OBSTACLE_Y = 380;
    localparam OBSTACLE_SPEED = 15;
    localparam TRIANGLE_SLOPE = 2;

    // ball jump logic ----------------------------------------------------------------------------
    
    reg [9:0] ball_y;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ball_speed <= 0;
        else if (game_over)  
            ball_speed <= ball_speed;
        else if (jmp_in && ball_y == GROUND_Y && ball_speed == 0)
            ball_speed <= BALL_INITIAL_SPEED;
        else if (tick) begin
            if (ball_y >= GROUND_Y && ball_speed >= 0)
                ball_speed <= 0;
            else
                ball_speed <= ball_speed + 5;
        end
    end
    
    assign tick_sync = jmp_in && ball_y == GROUND_Y && ball_speed == 0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ball_y <= GROUND_Y;
        else if (ball_tick && !game_over) begin
            if (ball_y >= GROUND_Y && ball_speed > 0)
                ball_y <= GROUND_Y;
            else if(ball_speed_abs!=0)
                ball_y <= ball_dir ? ball_y-1 : ball_y+1;
        end
    end
    
    // obstacle logic -------------------------------------------------------------------------------
    reg [9:0] obstacle_x;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            obstacle_x <= 10'd1023;
        else if (obs_tick && !game_over) begin
            obstacle_x <= (obstacle_x==10'd0) ? 10'd500 + rnd[10:2] : obstacle_x-1;
        end
    end
    

    // circle lut ---------------------------------------------------------------------------------
    wire inside_circle;
    
    circle_lut #(
        .BALL_X(BALL_X)
    ) u_circle_lut (
        .x(x),
        .y(y),
        .ball_y(ball_y),
        .inside_circle(inside_circle)
    );

    // scoreboard ---------------------------------------------------------------------------------
    wire score_inc = obs_tick && !game_over && obstacle_x==BALL_X-80;

    reg [3:0] score_ones, score_tens;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            score_ones <= 0;
            score_tens <= 0;
        end else if (score_inc) begin
            if (score_ones == 9) begin
                score_ones <= 0;
                score_tens <= (score_tens == 9) ? 4'd0 : score_tens + 1'b1;
            end else begin
                score_ones <= score_ones + 1'b1;
            end
        end
    end
    
    wire score_pixel;

    score_display u_score (
        .x(x), .y(y),
        .tens(score_tens), .ones(score_ones),
        .pixel(score_pixel)
    );
    
    // random generation ---------------------------------------------------------------------------
    wire [15:0] rnd;

    LFSR #(.N(16)) u_lfsr (
        .clk(clk),
        .rst_n(rst_n), 
        .q(rnd)
    );

    reg [1:0] cluster_size;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
          cluster_size <= 2'b00;
        else if(obstacle_x==0)
          cluster_size <= rnd[1:0];
    end
    
    // display logic -------------------------------------------------------------------------------
    wire [10:0] x_scaled = x*TRIANGLE_SLOPE;
    
    reg [10:0] obs_x_scaled;
    reg inside_triangle;
    
    reg [2:0] i;
    always @(*) begin
        inside_triangle = 1'b0;
        obs_x_scaled = obstacle_x*TRIANGLE_SLOPE; 

        for (i=0; i<4; i=i+1) begin
            if (i <= {1'b0, cluster_size}) begin
                obs_x_scaled = (obstacle_x - i*32)*TRIANGLE_SLOPE;

                if ((x_scaled+y > obs_x_scaled+OBSTACLE_Y) && (x_scaled+OBSTACLE_Y < obs_x_scaled+y))
                    inside_triangle = 1'b1;
            end
        end
    end

    always @(*) begin
        {R, G, B} = 6'b0;
        if(video_active) begin
            if(inside_circle)
                {R, G, B} = 6'b111000;
            else if(score_pixel)
                {R, G, B} = 6'b111111;
            else if(y>GROUND_Y)
                {R, G, B} = 6'b010100;
            else if(inside_triangle)
                {R, G, B} = 6'b101010;
        end
    end

endmodule
