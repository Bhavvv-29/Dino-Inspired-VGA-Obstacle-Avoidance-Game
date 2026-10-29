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

    // signals declared before first use
    wire [9:0]  ball_y;
    wire [15:0] rnd;

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
            // 896 + rnd[8:2] == {3'b111, rnd[8:2]}  (no adder needed)
            obstacle_x[0] <= (obstacle_x[0]==10'd0) ? {3'b111, rnd[8:2]} : obstacle_x[0]-1'b1;
                if(obstacle_x[0] == 10'd511)begin
                    obstacle_2_valid <= 1;
                    obstacle_x[1] <= {3'b111, rnd[8:2]};
                end
                if(obstacle_x[1] == 0)
                    obstacle_2_valid <= 0;
                if(obstacle_2_valid == 1)
                    obstacle_x[1] <= obstacle_x[1]-1'b1;   // 0-1 wraps to 1023 by itself
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

    // digits are always BCD (0..9), so "== 9" is just bit3 & bit0
    wire ones_9      = score_ones[3]      & score_ones[0];
    wire tens_9      = score_tens[3]      & score_tens[0];
    wire hundreds_9  = score_hundreds[3]  & score_hundreds[0];
    wire thousands_9 = score_thousands[3] & score_thousands[0];
    wire score_full  = ones_9 & tens_9 & hundreds_9 & thousands_9;   // == 16'h9999

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
            if (ones_9) begin
                score_ones <= 0;
                if (tens_9) begin
                    score_tens <= 0;
                    if (hundreds_9) begin
                        score_hundreds  <= 0;
                        score_thousands <= thousands_9 ? 4'd0 : score_thousands + 1'b1;
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
        .x(x), .y(y), .thousands(score_thousands),
        .hundreds(score_hundreds), .tens(score_tens), .ones(score_ones),
        .pixel(score_pixel)
    );

    // random generation ---------------------------------------------------------------------------
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

    // obstacle pixels -----------------------------------------------------------------------------
    // The obstacle is a cluster of up to 4 triangles, 32 px apart. A pixel is inside triangle i when
    //     |2*(x - ox) + 64*i|  <  y - (GROUND_Y - OBSTACLE_HEIGHT)
    // The ground (y > GROUND_Y) is drawn on top of obstacles and the ball can never be below the
    // ground line, so obstacles only matter for y in (377 .. 400]; there the right-hand side is 1..23.
    // Splitting 2*(x-ox) = hi*64 + lo lets one pair of comparators on 'lo' serve all 4 triangles.
    localparam [9:0] OBS_TOP = GROUND_Y - OBSTACLE_HEIGHT;           // 377
    wire        obs_band = (y > OBS_TOP) && (y <= GROUND_Y);
    wire [5:0]  e   = y[5:0] - OBS_TOP[5:0];                          // 1..23 inside the band
    wire [5:0]  e_c = 6'd0 - e;                                       // 64 - e

    wire [10:0] dx0 = {1'b0, x} - {1'b0, obstacle_x[0]};
    wire [10:0] dx1 = {1'b0, x} - {1'b0, obstacle_x[1]};

    wire [5:0] hi0 = dx0[10:5];
    wire [5:0] lo0 = {dx0[4:0], 1'b0};
    wire [5:0] hi1 = dx1[10:5];
    wire [5:0] lo1 = {dx1[4:0], 1'b0};

    // triangle i is drawn if i <= cluster_size and it has not wrapped below x=0 (ox >= 32*i)
    wire a0_0 = 1'b1;
    wire a1_0 = (cluster_size[0] >= 1) && (obstacle_x[0][9:5] >= 1);
    wire a2_0 = (cluster_size[0] >= 2) && (obstacle_x[0][9:5] >= 2);
    wire a3_0 = (cluster_size[0] == 3) && (obstacle_x[0][9:5] >= 3);

    wire a0_1 = 1'b1;
    wire a1_1 = (cluster_size[1] >= 1) && (obstacle_x[1][9:5] >= 1);
    wire a2_1 = (cluster_size[1] >= 2) && (obstacle_x[1][9:5] >= 2);
    wire a3_1 = (cluster_size[1] == 3) && (obstacle_x[1][9:5] >= 3);

    wire h0_0  = (hi0 == 6'b000000), hm1_0 = (hi0 == 6'b111111), hm2_0 = (hi0 == 6'b111110),
         hm3_0 = (hi0 == 6'b111101), hm4_0 = (hi0 == 6'b111100);
    wire h0_1  = (hi1 == 6'b000000), hm1_1 = (hi1 == 6'b111111), hm2_1 = (hi1 == 6'b111110),
         hm3_1 = (hi1 == 6'b111101), hm4_1 = (hi1 == 6'b111100);

    wire posA_0 = (h0_0 & a0_0) | (hm1_0 & a1_0) | (hm2_0 & a2_0) | (hm3_0 & a3_0);   // triangle's right half
    wire posB_0 = (hm1_0 & a0_0) | (hm2_0 & a1_0) | (hm3_0 & a2_0) | (hm4_0 & a3_0); // triangle's left half
    wire posA_1 = (h0_1 & a0_1) | (hm1_1 & a1_1) | (hm2_1 & a2_1) | (hm3_1 & a3_1);
    wire posB_1 = (hm1_1 & a0_1) | (hm2_1 & a1_1) | (hm3_1 & a2_1) | (hm4_1 & a3_1);

    wire obstacle_pixel   = obs_band & ((posA_0 & (lo0 < e)) | (posB_0 & (lo0 > e_c)));
    wire obstacle_pixel_1 = obs_band & ((posA_1 & (lo1 < e)) | (posB_1 & (lo1 > e_c)));

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
            else if(obstacle_pixel | obstacle_pixel_1)
                {R, G, B} = 6'b101010;
        end
    end

    // game over logic -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            game_over <= 1'b0;
        else if (game_reset)
            game_over <= 1'b0;
        else if (score_full)
            game_over <= 1'b1;
        else if (video_active && ball_pixel && (obstacle_pixel | obstacle_pixel_1))
            game_over <= 1'b1;
    end

endmodule