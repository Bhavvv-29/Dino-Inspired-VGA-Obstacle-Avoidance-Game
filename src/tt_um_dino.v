`default_nettype none

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

    // Unused inputs
    wire [14:0] _unused = {ui_in[7:2], uio_in, ena};

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
    
    // FOR FPGA ONLY, COMMENT OUT FOR ACTUAL IMPLEMENTATION --------------------------------------
    // assign uio_out[0] = video_active;

    // game parameters ---------------------------------------------------------------------------
    localparam BALL_X = 100;
    localparam MAX_SCORE = 999;

    localparam signed BALL_INITIAL_SPEED = -13;

    localparam GROUND_Y = 400;
    localparam GRAVITY_SCALE = 3750;

    localparam OBSTACLE_HEIGHT = 23;
    localparam OBSTACLE_SPEED = 6;
    localparam OBSTACLE_SEPERATION = 32;
    
    localparam OBSTACLE1_SPAWN_THRESHOLD = 511;
    localparam OBS_RESPAWN_X = 1023;
    localparam OBS_X_FOR_SCORE_INC = 20;

    // game input with synchronizer --------------------------------------------------------------
    reg [1:0] ui_meta, ui_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ui_meta <= 2'b00;
            ui_sync <= 2'b00;
        end else begin
            ui_meta <= ui_in[1:0];
            ui_sync <= ui_meta;
        end
    end

    // synchronized inputs
    wire jmp_in = ui_sync[0];                           // for jump input
    wire game_reset_in = ui_sync[1];                    // for game reset input

    reg game_over;
    
    // tick generator ----------------------------------------------------------------------------------------------

    // jump signal edge detector to feed ito sync pin of the tick generator
    // (edge detector is needed as we should synchronize tick_gen only once the jump starts)
    wire jmp_edge;
    reg jmp_edge_r;

    always @(posedge clk or negedge rst_n) begin
      if(!rst_n)
          jmp_edge_r <= 1'b0;
      else
          jmp_edge_r <= jmp_in;
    end

    assign jmp_edge = (jmp_in && !jmp_edge_r);  

    // actual tick generator
    wire ball_tick, obs_tick;

    tick_gen #(
        .OBSTACLE_SPEED(OBSTACLE_SPEED)
    ) u_tick_gen (
        .clk(clk),
        .rst_n(rst_n),
        .sync(jmp_edge && ball_y==GROUND_Y), // sync signal resets the tick max count to 0 to start a fresh tick when jump is pressed
        .ball_tick(ball_tick),
        .obs_tick(obs_tick)
    );

    // ball physics engine (inputs: jump signal, and game over check; outputs: ball's y position)-----------------------------------
    wire [9:0] ball_y;

    ball_controller #(
        .GROUND_Y(GROUND_Y),
        .GRAVITY_SCALE(GRAVITY_SCALE),
        .BALL_INITIAL_SPEED(BALL_INITIAL_SPEED)
    ) u_bsc (
        .clk(clk),
        .rst_n(rst_n),
        .tick(ball_tick),
        .stop(game_over),
        .jmp_in(jmp_in), 
        .ball_y(ball_y)
    );

    // circle lut (lut for the equation [x^2+y^2 < R^2] where radius is 30px ------------------------------------------------------
    wire ball_pixel;
    
    circle_lut #(
        .BALL_X(BALL_X)
    ) u_circle_lut (
        .x(x),
        .y(y),
        .ball_y(ball_y),
        .inside_circle(ball_pixel)
    );

    // scoreboard and game state(start, win, loss) ---------------------------------------------------------------------------------
    wire score_inc = obs_tick && !game_over && (obstacle_x[0]==OBS_X_FOR_SCORE_INC | obstacle_x[1]==OBS_X_FOR_SCORE_INC);  
    // increment score if any obstacle reaches the left end of the screen, which means the jump succeeded

    reg [3:0] score_ones, score_tens, score_hundreds;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            score_ones <= 0;
            score_tens <= 0;
            score_hundreds <= 0;
        end else if(game_reset_in) begin
            score_ones <= 0;
            score_tens <= 0;
            score_hundreds <= 0;
        end else if (score_inc) begin
            if (score_ones == 9) begin
                score_ones <= 0;
                if (score_tens == 9) begin
                    score_tens <= 0;
                    if (score_hundreds == 9) begin
                        score_hundreds  <= 0;
                    end else begin
                        score_hundreds <= score_hundreds + 1'b1;
                    end
                end else begin
                    score_tens <= score_tens + 1'b1;
                end
            end else begin
                score_ones <= score_ones + 1'b1;
            end
        end
    end

    // hud (head up display) refers to the on screen interface that shows stats like score and game status like start/win/loss etc.
    // hud takes the current pixel as an input and checks if its a part of the hud, and returns 1. 
    // hud has 2 parts, the scoreboard (3 digits) and the state display at the center of the screen (START, YOU LOSE(lose condition) and YAY (win condition))
    // outputs are score_pixel and state_display_pixel to indicate what the current pixel is. 

    wire score_pixel, state_display_pixel;
    wire win = {score_hundreds, score_tens, score_ones} == MAX_SCORE;

    hud u_hud (
        .x(x), 
        .y(y),
        .start(game_reset_in),
        .game_over(game_over),
        .win(win),
        .hundreds(score_hundreds), .tens(score_tens), .ones(score_ones),
        .score_pixel(score_pixel),
        .state_display_pixel(state_display_pixel)
    ); 

    // random generation ----------------------------------------------------------------------------------------------------------
    wire [15:0] rnd;

    // 16 bit LFSR
    LFSR #(.N(16)) u_lfsr (
        .clk(clk),
        .rst_n(rst_n), 
        .q(rnd)
    );

    // cluster_size is a random generated value from 0 to 3, to indicate how many extra obstacles to add to a current obstacle cluster
    // since the first obstacle in the cluster is fixed, cluster_size from 0-3 can generate 1-4 obstacles per cluster
    // cluster_size[0] and [1] correspond to the cluster size of obstacle0 and obstacle1 respectively
    reg [1:0] cluster_size[0:1];

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          cluster_size[0] <= 2'b00;
          cluster_size[1] <= 2'b10;
          end
        else if(obstacle_x[0]==0)
          cluster_size[0] <= rnd[1:0];
        else if(obstacle_x[1]==0)
          cluster_size[1] <= rnd[1:0];
    end
    
    // obstacle physics (obstacle0 and obstacle1)---------------------------------------------------------------------------------------
    reg [9:0] obstacle_x [0:1]; // x coordinate of the center of the base triangle (right most triangle) in a cluster
    reg obstacle_1_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin                          // both obstacles start at x=1023, which keeps them off screen
            obstacle_x[0] <= OBS_RESPAWN_X; 
            obstacle_x[1] <= OBS_RESPAWN_X;
            obstacle_1_valid <= 1'b0;              // obstacle1 spawning is turned off after reset
        end else if (game_reset_in) begin
            obstacle_x[0] <= OBS_RESPAWN_X;
            obstacle_x[1] <= OBS_RESPAWN_X;
            obstacle_1_valid <= 1'b0;
        end else if (obs_tick && !game_over) begin     
            /* move obstacle0 left by 1 pixel every obstacle tick. for respawning, base location is 10'b111_0000000(896)
                if it reaches x=0, respawn it at x=896+rand(0, 127). effective range for respawn is from x=896 to x=1023.*/      
            obstacle_x[0] <= (obstacle_x[0]==0) ? {3'b111, rnd[8:2]} : obstacle_x[0]-1;

            // when obstacle0 reaches x=OBSTACLE1_SPAWN_THRESHOLD, obstacle1 is now spawned, at a random location from x=896 to x=1023. 
            if(obstacle_x[0] == OBSTACLE1_SPAWN_THRESHOLD)begin
                obstacle_1_valid <= 1;
                obstacle_x[1] <= {3'b111, rnd[15:9]};
            end

            // when obstacle1 reaches x=0, make obstacle1 invalid and kill it without respawning
            if(obstacle_x[1] == 0)
                obstacle_1_valid <= 0;

            // when obstacle1 is valid, decrement it's x position by 1 every tick
            if(obstacle_1_valid == 1)
                obstacle_x[1] <= (obstacle_x[1]==0) ? OBS_RESPAWN_X : obstacle_x[1]-1;
        end
    end
    
    // obstacle rendering logic --------------------------------------------------------------------------------------------------------------
    localparam [10:0] OBS_TOP = GROUND_Y-OBSTACLE_HEIGHT;

     /* spikes(implemented with a triangle) can be formed by the area "under" 2 intersecting lines. we choose the lines:
        -> y=2x
        -> y=-2x
        here for each triangle. this gives a simple isosceles triangle with slope 2.

    however, in vga pixel rendering, the y value increases as we go from top to bottom. hence we must invert the "under" condition and check if y>2x or y>-2x.
    hence, our equations become:
        -> y>2x
        -> y>-2x
    
    now by varying x with an offset and moving the offset around, we can move the triangle around or add multiple triangles that move along together.
    */

    reg signed [10:0] dx [0:1];  // x-obstacle_x for both obstacle0 and obstacle1
    wire signed [11:0] dy = $signed({2'b0, y})-$signed(OBS_TOP); // distance to the OBS_TOP y-level from the current y value    

    reg signed [11:0] dx_with_offset;  // distance from current pixel's x value to the center of the current triangle being written
    reg [1:0] obstacle_pixel;

    integer i, j;

    always @(*) begin
        obstacle_pixel = 2'b00;

        dx[0] = x-obstacle_x[0];    
        dx[1] = x-obstacle_x[1];

        dx_with_offset = 0;          

        if (dy<=OBSTACLE_HEIGHT) begin
            for (j=0; j<2; j=j+1) begin   // iteration through each cluster (obstacle0 and obstacle1)                
                for(i=0; i<4; i=i+1) begin  // iteration through each spike in the current cluster j, which basically means obstacle(j)
                    if (i <= cluster_size[j]) begin  // checks if the spike actually exists in the cluster based on the random value

                        dx_with_offset = dx[j]+(i[10:0]*OBSTACLE_SEPERATION);       // shift current triangle left by OBSTACLE_SEPERATION*i pixels (to print a cluster)
                        if ( (dy > 2*dx_with_offset) && (dy > -(2*dx_with_offset)))    // above equations are implemented here
                            obstacle_pixel[0] = 1'b1;
                    end
                end
            end
        end
    end

    // display colouring logic -----------------------------------------------------------------------------------------------------
    always @(*) begin
        if(video_active) begin
            if(ball_pixel)
                {R, G, B} = 6'b100000;
            else if(score_pixel) 
                {R, G, B} = 6'b111111;
            else if(state_display_pixel)
                {R, G, B} = 6'b101000;
            else if(y>GROUND_Y)
                {R, G, B} = 6'b010100;
            else if(|obstacle_pixel)
                {R, G, B} = 6'b101010;
            else 
                {R, G, B} = 6'b000000;
        end
    end

    // game over logic ------------------------------------------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            game_over <= 1'b0;
        else if (game_reset_in)
            game_over <= 1'b0;
        else if (win) // win condition with score
            game_over <= 1'b1;
        else if (video_active && ball_pixel && (|obstacle_pixel))  // loss condition (collision detection)
            game_over <= 1'b1;
    end

endmodule