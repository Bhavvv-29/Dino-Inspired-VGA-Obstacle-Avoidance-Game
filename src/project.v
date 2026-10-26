`default_nettype none

module tt_um_vga_example(
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
    wire clk_25mhz;
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

  //25Mhz clock gen
  dff #(
   .RST_VAL(1'b0)
  ) u_dff_25mhz(
   .clk_25mhz(clk),
   .rst(rst_n),
   .d(~clk_25mhz),
   .q(clk_25mhz)
);

  //LFSR 
  LFSR #(
   .N    (6),
   .TAPS (6'b110000),
   .SEED (6'b001100)
) u_lfsr (
   .clk_25mhz (clk),
   .rst       (rst_n),
   .tick      (speed_tick),
   .rand_bit  (obstical_tick)
);

    // edge detector
    wire db_in, jmp_in;
    reg db_in_reg;

    assign db_in = ui_in[0];

    always @(posedge clk or negedge rst_n) begin
      if(!rst_n)
          db_in_reg <= 1'b0;
      else
          db_in_reg <= db_in;
    end

    assign jmp_in = db_in != (db_in_reg);

    // tick generator ----------------------------------------------------------------------
    wire speed_tick, ball_k_tick;
    
    localparam SPEED_TICK_MAX_COUNT = 1_724_137;
    
    wire [20:0] speed_tick_max_count;

    fixed_tick_gen #(   
        .MAX_COUNT(SPEED_TICK_MAX_COUNT)
    ) u_speed_tick (
        .clk(clk),
        .rst_n(rst_n),
        .tick(speed_tick)
    );

    var_tick_gen u_ball_k_tick (
        .clk(clk),
        .rst_n(rst_n),
        .max_count(speed_tick_max_count),
        .tick(ball_k_tick)
    );

  reg game_over;
  wire hit = video_active && inside_circle && inside_triangle;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        game_over <= 1'b0;
    else if (hit)
        game_over <= 1'b1;
  end

    // ball jump logic ----------------------------------------------------------------------------
    localparam BALL_H = 100;
    localparam BALL_R = 30;
    localparam BALL_K_BOTTOM = 400;

    localparam signed [9:0] BALL_INITIAL_SPEED = -85;
    
    reg [9:0] ball_k;
    reg signed [9:0] ball_speed;
    
    wire [9:0] ball_speed_abs;

    assign ball_speed_abs = ball_speed[9] ? (~ball_speed+1) : ball_speed;

    wire [9:0] safe_speed = (ball_speed_abs==0) ? 1 : ball_speed_abs;

    assign speed_tick_max_count = (ball_speed_abs == 0)
        ? SPEED_TICK_MAX_COUNT
        : (SPEED_TICK_MAX_COUNT / safe_speed);

  always @(posedge clk or negedge rst_n) begin
      if (!rst_n)
          ball_speed <= 0;
      else if (game_over)  ball_speed <= ball_speed;
      else if (jmp_in && ball_k == BALL_K_BOTTOM && ball_speed == 0)
          ball_speed <= BALL_INITIAL_SPEED;
      else if (speed_tick) begin
          if (ball_k >= BALL_K_BOTTOM && ball_speed >= 0)
              ball_speed <= 0;
          else
              ball_speed <= ball_speed + 20;
      end
  end

    always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ball_k <= BALL_K_BOTTOM;
    else if (game_over)  ball_k <= ball_k;
    else if (ball_k_tick) begin
        if (ball_speed==0)
            ball_k <= ball_k;
        else if (ball_k >= BALL_K_BOTTOM && ball_speed > 0)
            ball_k <= BALL_K_BOTTOM;
        else if (ball_speed < 0)
            ball_k <= ball_k-1;
        else
            ball_k <= ball_k+1;
    end
end

    // display logic -------------------------------------------------------------------------------
    wire inside_circle = ((x-BALL_H)*(x-BALL_H) + (y-ball_k+BALL_R)*(y-ball_k+BALL_R)) <= BALL_R*BALL_R;

    
localparam OBSTACLE_Y     = 320;
localparam OBSTACLE_WIDTH = 30;

wire frame_tick = (x == 10'd0) && (y == 10'd480);

localparam OBSTACLE_SPEED = 15;

reg [9:0] OBSTACLE_X;

//obstical colision 
//wire colison = (OBSTACLE_X == x) && (OBSTACLE_Y == y);

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    OBSTACLE_X <= 10'd665;
  else if (frame_tick && !game_over) begin
    if ((OBSTACLE_X <= OBSTACLE_SPEED)&&(obstical_tick))
      OBSTACLE_X <= 10'd665;
    else
      OBSTACLE_X <= OBSTACLE_X - OBSTACLE_SPEED;
  end
end


// Distance below the triangle's top point.
wire [10:0] obstacle_dy =
    (y >= OBSTACLE_Y) ? (y - OBSTACLE_Y) : 0;

// Half-width grows linearly from 0 at the top
// to OBSTACLE_WIDTH/2 at BALL_K_BOTTOM.
wire [10:0] obstacle_half_width =
    (OBSTACLE_WIDTH * obstacle_dy) /
    (2 * (BALL_K_BOTTOM - OBSTACLE_Y));

wire inside_triangle =
    (y >= OBSTACLE_Y) &&
    (y <= BALL_K_BOTTOM) &&
    (x >= OBSTACLE_X - obstacle_half_width) &&
    (x <= OBSTACLE_X + obstacle_half_width);

    always @(*) begin
        {R, G, B} = 6'b0;
        if(video_active) begin
          if(inside_triangle)
              {R, G, B} = 6'b101010;
          if(y>BALL_K_BOTTOM)
              {R, G, B} =  6'b010100;
          if(inside_circle)
              {R, G, B} = 6'b111000;
         
        end     
    end
endmodulemain