module tt_um_dino(
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock - 50Mhz
    // output wire video_active,    // uncomment this for fpga
    input  wire       rst_n     // reset_n - low to reset
);

    // VGA signals
    wire hsync, vsync;
    wire video_active;  // comment this out for fpga
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

    // game parameters ---------------------------------------------------------------------------
    localparam BALL_X = 100;
    localparam GROUND_Y = 400;
    localparam GRAVITY_SCALE = 3750;

    localparam OBSTACLE_HEIGHT = 23;
    localparam OBSTACLE_SPEED = 6;

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

    // game reset logic
    wire game_reset = ui_sync[1];
    reg game_over;
    
    // jump edge detector ------------------------------------------------------------------------
    wire jmp_edge;
    reg jmp_edge_r;

    always @(posedge clk or negedge rst_n) begin
      if(!rst_n)
          jmp_edge_r <= 1'b0;
      else
          jmp_edge_r <= ui_sync[0];
    end

    assign jmp_edge = (ui_sync[0] && !jmp_edge_r);  

    // tick generator ---------------------------------------------------------------------------
    wire ball_tick, obs_tick;

    tick_gen #(
        .OBSTACLE_SPEED(OBSTACLE_SPEED)
    ) u_tick_gen (
        .clk(clk),
        .rst_n(rst_n),
        .sync(jmp_edge && ball_y==GROUND_Y),
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
        .jmp_in(ui_sync[0]),
        .ball_y(ball_y)
    );

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
            score_ones <= 0;
            score_tens <= 0;
            score_hundreds <= 0;
            score_thousands <= 0;
        end else if(game_reset) begin
            score_ones <= 0;
            score_tens <= 0;
            score_hundreds <= 0;
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
 
    wire score_pixel, state_display;

    score_display u_score (
        .x(x), 
        .y(y),
        .start(game_reset),
        .game_over(game_over),
        .thousands(score_thousands),
        .hundreds(score_hundreds), .tens(score_tens), .ones(score_ones),
        .pixel(score_pixel),
        .state_display(state_display)
    ); 

    // random generation ----------------------------------------------------------------------------------------------------------
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
          cluster_size[1] <= 2'b10;
          end
        else if(obstacle_x[0]==0)
          cluster_size[0] <= rnd[1:0];
        else if(obstacle_x[1]==0)
          cluster_size[1] <= rnd[1:0];
    end
    
    // obstacle logic -------------------------------------------------------------------------------------------------------------------
    reg [9:0] obstacle_x [0:1];
    reg obstacle_2_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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
    
    // obstacle display logic --------------------------------------------------------------------------------------------------------------
    localparam OBS_TOP = GROUND_Y-OBSTACLE_HEIGHT+1;

    reg [10:0] dx [0:1];        
    reg [1:0] obstacle_pixel;

    reg [2:0] i;
    reg [1:0] j;

    always @(*) begin
        obstacle_pixel = 2'b00;

        dx[0] = x-obstacle_x[0];
        dx[1] = x-obstacle_x[1];

        if (y>=OBS_TOP && y<OBS_TOP+64) begin
            for (i=0; i<4; i=i+1) begin
                for(j=0; j<2; j=j+1) begin
                    if (i <= {1'b0, cluster_size[j]})
                        if (((dx[j][10:5] == 6'd0-i) && ({dx[j][4:0], 1'b0} <= y-OBS_TOP)) || ((dx[j][10:5] == 6'd63-i) && ({dx[j][4:0], 1'b0} + y-OBS_TOP >= 64)))
                            obstacle_pixel[0] = 1'b1;
                end
            end
        end
    end

    // display logic -------------------------------------------------------------------------------------------------------------
    reg [8:0] bg_cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bg_cnt <= 0;
        else if (x==0 && y==0 && !game_over)
            bg_cnt <= bg_cnt + 1'b1;
    end

    wire [6:0] cx = x[6:0] + bg_cnt[8:2];
    wire [5:0] hx = x[5:0] + bg_cnt[8:3];
    wire [4:0] ha = hx[4:0] ^ {5{~hx[5]}};

    wire moon = (x[9:5]==5'd2) && (y[9:5]==5'd1) && !(~(x[4]^x[3]) && ~(y[4]^y[3]));

    wire cloud = ((y[9:5]==5'd3 && !cx[6]) || (y[9:5]==5'd5 && cx[6])) &&
                 (((y[4:3]==2'd0) && (cx[5]^cx[4])) ||
                  ((y[4]^y[3]) && cx[5:3]!=3'd0 && cx[5:3]!=3'd7));

    wire hill = (y[9:5]==5'd11 && ha < y[4:0]) || (y[9:5]==5'd12);

    wire star = (y[9:7]==3'd0) && (x[3:1]==3'd2) && (y[3:1]==3'd4) && ((x[7:4]^y[6:3])==4'd0);

    reg [5:0] sky;
    always @(*) begin
        case (y[8:5])
            4'd0:    sky = 6'b000001;
            4'd1,
            4'd2:    sky = 6'b000010;
            4'd3,
            4'd4:    sky = 6'b010010;
            4'd5:    sky = 6'b010011;
            4'd6:    sky = 6'b100011;
            4'd7:    sky = 6'b100111;
            4'd8:    sky = 6'b100110;
            4'd9:    sky = 6'b110110;
            4'd10:   sky = 6'b110101;
            default: sky = 6'b111001;
        endcase
    end

    always @(*) begin
        {R, G, B} = 6'b0;
        if (video_active) begin
            if      (ball_pixel)       {R, G, B} = 6'b001111;
            else if (score_pixel)      {R, G, B} = state_display ? 6'b111100 : 6'b111111;
            else if (y > GROUND_Y)     {R, G, B} = 6'b000101;
            else if (|obstacle_pixel)  {R, G, B} = 6'b001100;
            else if (moon)             {R, G, B} = 6'b111110;
            else if (cloud)            {R, G, B} = 6'b111010;
            else if (hill)             {R, G, B} = 6'b010001;
            else if (star)             {R, G, B} = 6'b111111;
            else                       {R, G, B} = sky;
        end
    end

    // game over logic -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            game_over <= 1'b0;
        else if (game_reset)
            game_over <= 1'b0;
        else if ({score_thousands, score_hundreds, score_tens, score_ones} == 16'h9999)
            game_over <= 1'b1;
        else if (video_active && ball_pixel && (|obstacle_pixel))
            game_over <= 1'b1;
    end

endmodule