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

    //rand bit
    wire obstical_tick; 
    
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

    //LFSR 
    LFSR #(
    .N    (6),
    .TAPS (6'b110000),
    .SEED (6'b001100)
    ) u_lfsr (
    .clk_25mhz (clk),
    .rst       (rst_n),
    .tick      (tick),
    .rand_bit  (obstical_tick)
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

    // tick generator ---------------------------------------------------------------------------
    wire tick, ball_y_tick, obs_tick;
    
    localparam TICK_MAX_COUNT = 1_724_137;
    
    wire [20:0] tick_max_count;

    fixed_tick_gen #(   
        .MAX_COUNT(TICK_MAX_COUNT)
    ) u_tick (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick)
    );

    var_tick_gen u_ball_y_tick (
        .clk(clk),
        .rst_n(rst_n),
        .max_count(tick_max_count),
        .tick(ball_y_tick)
    );

    fixed_tick_gen #(
      .MAX_COUNT(50_000)
    ) u_obstacle_tick (
        .clk(clk),
        .rst_n(rst_n),
        .tick(obs_tick)
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
    localparam GROUND_Y = 400;
    
    localparam OBSTACLE_WIDTH = 380;
    localparam OBSTACLE_SPEED = 15;

    // ball jump logic ----------------------------------------------------------------------------
    localparam signed [9:0] BALL_INITIAL_SPEED = -85;
    
    reg [9:0] ball_y;
    reg signed [9:0] ball_speed;
    
    wire [9:0] ball_speed_abs = ball_speed[9] ? (~ball_speed+1) : ball_speed;
    wire [9:0] safe_speed = (ball_speed_abs==0) ? 1 : ball_speed_abs;

    assign tick_max_count = (ball_speed_abs == 0) ? TICK_MAX_COUNT : (TICK_MAX_COUNT / safe_speed);

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
                ball_speed <= ball_speed + 20;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ball_y <= GROUND_Y;
        else if (game_over)
            ball_y <= ball_y;
        else if (ball_y_tick) begin
            if (ball_speed==0)
                ball_y <= ball_y;
            else if (ball_y >= GROUND_Y && ball_speed > 0)
                ball_y <= GROUND_Y;
            else if (ball_speed < 0)
                ball_y <= ball_y-1;
            else
                ball_y <= ball_y+1;
        end
    end
    
    // obstacle logic -------------------------------------------------------------------------------
    reg [9:0] obstacle_x;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            obstacle_x <= 10'd665;
        else if (obs_tick && !game_over) begin
            obstacle_x <= obstacle_x-1;
        end
    end
    
    // circle lut ---------------------------------------------------------------------------------
    wire inside_circle;
    
    circle_lut #(
        .BALL_X(100)
    ) u_circle_lut (
        .x(x),
        .y(y),
        .ball_y(ball_y),
        .inside_circle(inside_circle)
    );
    // display logic -------------------------------------------------------------------------------
    wire inside_triangle = (x+y>obstacle_x+OBSTACLE_WIDTH) && (x+OBSTACLE_WIDTH<obstacle_x+y);

    always @(*) begin
        {R, G, B} = 6'b0;
        if(video_active) begin
            if(inside_triangle)
                {R, G, B} = 6'b101010;
            if(y>GROUND_Y)
                {R, G, B} =  6'b010100;
            if(inside_circle)
                {R, G, B} = 6'b111000;
        end     
    end

endmodule