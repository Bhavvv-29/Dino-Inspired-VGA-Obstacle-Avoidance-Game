`default_nettype none
`define PYNQ_FPGA_TEST 0  

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
    // reset sync
    wire srst_n;
    rst_sync u_rst_sync(.clk(clk), .arstn(rst_n), .srstn(srst_n));

    // VGA signals
    wire hsync, vsync;
    wire video_active;
    wire [9:0] x, y;

    reg [1:0] R, G, B;
    
    // TinyVGA PMOD
    assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

    // Unused outputs assigned to 0.
    assign uio_out = `PYNQ_FPGA_TEST ? {7'd0, video_active} : 8'd0;
    assign uio_oe  = 8'd0;

    // Unused inputs
    wire [14:0] _unused = {ui_in[7:2], uio_in, ena};

    // hvsync generator
    hvsync_generator hvsync_gen(
    .clk(clk),
    .rst_n(srst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(x),
    .vpos(y)
    );

    // game parameters ---------------------------------------------------------------------------
    localparam BALL_X = 100;
    localparam MAX_SCORE = 12'h999;

    localparam signed [7:0] BALL_INITIAL_SPEED = -13;

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

    always @(posedge clk or negedge srst_n) begin
        if (!srst_n) begin
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

    always @(posedge clk or negedge srst_n) begin
      if(!srst_n)
          jmp_edge_r <= 1'b0;
      else
          jmp_edge_r <= jmp_in;
    end

    assign jmp_edge = (jmp_in && !jmp_edge_r);  

    // actual tick generator
    wire ball_tick, obs_tick;
    wire [9:0] ball_y;

    reg [9:0] obstacle_x [0:1]; // x coordinate of the leftmost point of the base slot (right most triangle) in a cluster (for obstacle spikes)

    tick_gen #(
        .OBSTACLE_SPEED(OBSTACLE_SPEED)
    ) u_tick_gen (
        .clk(clk),
        .rst_n(srst_n),
        .sync(jmp_edge && ball_y==GROUND_Y), // sync signal resets the tick max count to 0 to start a fresh tick when jump is pressed
        .ball_tick(ball_tick),
        .obs_tick(obs_tick)
    );

    // ball physics engine (inputs: jump signal, and game over check; outputs: ball's y position)-----------------------------------

    ball_controller #(
        .GROUND_Y(GROUND_Y),
        .GRAVITY_SCALE(GRAVITY_SCALE),
        .BALL_INITIAL_SPEED(BALL_INITIAL_SPEED)
    ) u_bsc (
        .clk(clk),
        .rst_n(srst_n),
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

    always @(posedge clk or negedge srst_n) begin
        if (!srst_n) begin
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
        .rst_n(srst_n), 
        .q(rnd)
    );

    // cluster_size is a random generated value from 0 to 3, to indicate how many extra obstacles to add to a current obstacle cluster
    // since the first obstacle in the cluster is fixed, cluster_size from 0-3 can generate 1-4 obstacles per cluster
    // cluster_size[0] and [1] correspond to the cluster size of obstacle0 and obstacle1 respectively
    reg [1:0] cluster_size[0:1];

    always @(posedge clk or negedge srst_n) begin
        if(!srst_n) begin
          cluster_size[0] <= 2'b00;
          cluster_size[1] <= 2'b10;
          end
        else if(obstacle_x[0]==0)
          cluster_size[0] <= rnd[1:0];
        else if(obstacle_x[1]==0)
          cluster_size[1] <= rnd[1:0];
    end
    
    // obstacle physics (obstacle0 and obstacle1)---------------------------------------------------------------------------------------
    reg obstacle_1_valid;

    always @(posedge clk or negedge srst_n) begin
        if (!srst_n) begin                          // both obstacles start at x=1023, which keeps them off screen
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

    /* spikes,which are implemented with a triangle, can be formed by the area "under" 2 intersecting lines. chosen lines are y>2x and y>-2x.
        this gives a simple isosceles triangle with slope 2. (y increases downwards on vga, so "under" the lines means a bigger y) */

    wire [10:0] dy = {1'b0, y}-OBS_TOP; 
    // rows below the top of the spikes. above the top it wraps to a huge number, 
    // so dy<=OBSTACLE_HEIGHT also takes care of 
    // the false negative problem due to overlap

    /* dx is the distance from the left end of the cluster, which is the start of the leftmost spike's 32px slot.
        the leftmost spike is centered at obstacle_x-32*cluster_size, and its slot starts 16px before that, so dx = x-obstacle_x+32*cluster_size+16
        ({cluster_size, 5'b10000} is 32*cluster_size+16). the cluster is cluster_size+1 slots of 32px:
        dx[10:5] is the slot number (0 to cluster_size) and dx[4:0] is the position in the slot, the center of the spike is at 16.
        left of the cluster dx wraps to a huge number, so a single compare also helps take care of this false negative issue */

    wire [10:0] dx [0:1];
    assign dx[0] = {1'b0, x}-{1'b0, obstacle_x[0]}+{4'b0000, cluster_size[0], 5'b10000};
    assign dx[1] = {1'b0, x}-{1'b0, obstacle_x[1]}+{4'b0000, cluster_size[1], 5'b10000};

    reg obstacle_pixel;

    integer i; 

    always @(*) begin
        obstacle_pixel = 1'b0;

        // check both obstacle clusters
        for (i=0; i<2; i=i+1) begin 
            // inside the cluster, and inside the triangle,at row dy the triangle covers dy/2 px on each side of the slot's center, so 16-dy/2 < position < 16+dy/2
            // basically we are rewriting y>2x as y/2>x. but with offset also. same for y>-2x.
            if (dy<=OBSTACLE_HEIGHT && dx[i][10:5]<={4'b0000, cluster_size[i]} && (2*dx[i][4:0]+dy>OBSTACLE_SEPERATION) && (2*dx[i][4:0]<OBSTACLE_SEPERATION+dy))
                obstacle_pixel = 1'b1;
        end
    end
    // display colouring logic -----------------------------------------------------------------------------------------------------
    always @(*) begin
        {R, G, B} = 6'b000000;
        if(video_active) begin
            if(ball_pixel)
                {R, G, B} = 6'b100000;
            else if(score_pixel) 
                {R, G, B} = 6'b111111;
            else if(state_display_pixel)
                {R, G, B} = 6'b101000;
            else if(obstacle_pixel)
                {R, G, B} = 6'b101010;
            else if(y>GROUND_Y)
                {R, G, B} = 6'b010100;
        end
    end

    // game over logic ------------------------------------------------------------------------------------------------------------
    always @(posedge clk or negedge srst_n) begin
        if (!srst_n)
            game_over <= 1'b0;
        else if (game_reset_in)
            game_over <= 1'b0;
        else if (win) // win condition with score
            game_over <= 1'b1;
        else if (video_active && ball_pixel && (|obstacle_pixel))  // loss condition (collision detection)
            game_over <= 1'b1;
    end

endmodule
