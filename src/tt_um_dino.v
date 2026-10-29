module tt_um_dino(
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock - 50Mhz
    output wire video_active,    // only for fpga
    input  wire       rst_n     // reset_n - low to reset
);

    // VGA signals
    wire hsync, vsync;
    //wire video_active;
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

    // game reset
    wire game_reset = ui_in[1];
    reg game_over;

    // game parameters ---------------------------------------------------------------------------
    localparam BALL_X = 100;
    localparam GROUND_Y = 400;
    localparam GRAVITY_SCALE = 3750;

    localparam OBSTACLE_HEIGHT = 23;
    localparam OBSTACLE_SPEED = 6;

    // edge detector ----------------------------------------------------------------------------
    wire jmp_in;
    reg jmp_in_reg;

    always @(posedge clk or negedge rst_n) begin
      if(!rst_n)
          jmp_in_reg <= 1'b0;
      else
          jmp_in_reg <= ui_in[0];
    end

    assign jmp_in = (ui_in[0]!=jmp_in_reg);  // only for vga playground
    // assign jmp_in = (ui_in[0] && !jmp_in_reg);  
    // tick generator ---------------------------------------------------------------------------
    wire ball_tick, obs_tick;

    tick_gen #(
        .OBSTACLE_SPEED(OBSTACLE_SPEED)
    ) u_tick_gen (
        .clk(clk),
        .rst_n(rst_n),
        .sync(jmp_in && ball_y==GROUND_Y),
        .ball_tick(ball_tick),
        .obs_tick(obs_tick)
    );

    // ball speed controller -------------------------------------------------------------------
    wire [9:0] ball_y;

    ball_controller #(
        .GROUND_Y(GROUND_Y),
        .GRAVITY_SCALE(GRAVITY_SCALE)
    ) u_bsc (
        .clk(clk),
        .rst_n(rst_n),
        .tick(ball_tick),
        .stop(game_over),
        .jmp_in(jmp_in),
        .ball_y(ball_y)
    );

    // obstacle logic -------------------------------------------------------------------------------
    reg [9:0] obstacle_x [0:1];
    reg obstacle_2_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            obstacle_x[0] <= 10'd1023;
            obstacle_x[1] <= 10'd1023;
            obstacle_2_valid <= 1'b0;
        end else if (game_reset) begin
            obstacle_x[0] <= 10'd1023;
            obstacle_x[1] <= 10'd1023;
            obstacle_2_valid <= 1'b0;
        end else if (obs_tick && !game_over) begin
            obstacle_x[0] <= (obstacle_x[0]==10'd0) ? 10'd896 + rnd[8:2] : obstacle_x[0]-1;
                if(obstacle_x[0] == 10'd511)begin
                    obstacle_2_valid <= 1;
                    obstacle_x[1] <= 10'd896 + rnd[8:2];
                end
                if(obstacle_x[1] == 0)
                    obstacle_2_valid <= 0;
                if(obstacle_2_valid == 1)
                    obstacle_x[1] <= (obstacle_x[1]==10'd0) ? 10'd1023 : obstacle_x[1]-1;
        end
    end
    
    // circle lut ---------------------------------------------------------------------------------
    wire ball_pixel;
    
    circle_lut #(
        .BALL_X(BALL_X)
    ) u_circle_lut (
        .x(x),
        .y(y),
        .ball_y(ball_y),
        .inside_circle(ball_pixel)
    );

    // scoreboard ---------------------------------------------------------------------------------
   wire score_inc = obs_tick && !game_over && (obstacle_x[0]==BALL_X-80 | obstacle_x[1]==BALL_X-80);
    reg [3:0] score_ones, score_tens, score_hundreds, score_thousands;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            score_ones      <= 0;
            score_tens      <= 0;
            score_hundreds  <= 0;
            score_thousands <= 0;
        end else if(game_reset) begin
            score_ones      <= 0;
            score_tens      <= 0;
            score_hundreds  <= 0;
            score_thousands <= 0;
        end else if (score_inc) begin
            if (score_ones == 9) begin
                score_ones <= 0;
                if (score_tens == 9) begin
                    score_tens <= 0;
                    if (score_hundreds == 9) begin
                        score_hundreds  <= 0;
                        score_thousands <= (score_thousands == 9) ? 4'd0 : score_thousands + 1'b1;
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
 
    wire score_pixel;

   score_display u_score (
        .x(x), .y(y),.thousands(score_thousands),
        .hundreds(score_hundreds), .tens(score_tens), .ones(score_ones),
        .pixel(score_pixel)
   ); 

    // random generation ---------------------------------------------------------------------------
    wire [15:0] rnd;

    LFSR #(.N(16)) u_lfsr (
        .clk(clk),
        .rst_n(rst_n), 
        .q(rnd)
    );

    reg [1:0] cluster_size[0:1];

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          cluster_size[0] <= 2'b00;
          cluster_size[1] <= 2'b00;
          end
        else if(obstacle_x[0]==0)
          cluster_size[0] <= rnd[1:0];
        else if(obstacle_x[1]==0)
          cluster_size[1] <= rnd[1:0];
    end
    
    // display logic -------------------------------------------------------------------------------
        // display logic -------------------------------------------------------------------------------
    localparam OBS_TOP = GROUND_Y - OBSTACLE_HEIGHT + 1;

    wire [9:0]  y_off = y - OBS_TOP;
    wire        y_win = (y_off[9:6] == 4'd0);
    wire [4:0]  h     = y_off[5:1];

    wire [10:0] d0 = {1'b0, x} - {1'b0, obstacle_x[0]};
    wire [10:0] d1 = {1'b0, x} - {1'b0, obstacle_x[1]};

    wire        pos0 = (d0[4:0] <= h);
    wire        pos1 = (d1[4:0] <= h);

    wire [5:0]  sum0 = d0[4:0] + h;
    wire [5:0]  sum1 = d1[4:0] + h;
    wire        neg0 = sum0[5];
    wire        neg1 = sum1[5];

    reg obstacle_pixel;
    reg obstacle_pixel_1;

    reg [2:0] i;
    always @(*) begin
        obstacle_pixel   = 1'b0;
        obstacle_pixel_1 = 1'b0;

        for (i = 0; i < 4; i = i + 1) begin
            if (i <= {1'b0, cluster_size[0]})
                if (((d0[10:5] == 6'd0  - i) && pos0) || ((d0[10:5] == 6'd63 - i) && neg0))
                    obstacle_pixel = 1'b1;

            if (i <= {1'b0, cluster_size[1]})
                if (((d1[10:5] == 6'd0  - i) && pos1) || ((d1[10:5] == 6'd63 - i) && neg1))
                    obstacle_pixel_1 = 1'b1;
        end

        obstacle_pixel   = obstacle_pixel   & y_win;
        obstacle_pixel_1 = obstacle_pixel_1 & y_win;
    end

    wire score_bg = x>450 && y<75;

    always @(*) begin
        {R, G, B} = 6'b0;
        if(video_active) begin
            if(ball_pixel)
                {R, G, B} = 6'b100000;
            else if(score_pixel)
                {R, G, B} = 6'b000000;
            else if(score_bg) 
                {R, G, B} = 6'b101000;
            else if(y>GROUND_Y)
                {R, G, B} = 6'b010100;
            else if(obstacle_pixel)
                {R, G, B} = 6'b101010;
            else if(obstacle_pixel_1)
                {R, G, B} = 6'b101010;
        end
    end

    // game over logic -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            game_over <= 1'b0;
        else if (game_reset)
            game_over <= 1'b0;
        else if ({score_thousands, score_hundreds, score_tens, score_ones} = 16'h9999)
            game_over <= 1'b1;
        else if (video_active && ball_pixel && (obstacle_pixel | obstacle_pixel_1))
            game_over <= 1'b1;
    end
    

endmodule