`default_nettype none

module hud (
	input wire [9:0] x, y,
	input wire start, game_over, win,
	input wire [3:0] hundreds, tens, ones,
	output wire score_pixel,
	output wire state_display_pixel          //1 for msg 0 for score display 
);
 
localparam X0 = 510, Y_SCORE = 20;   // score block 3 digits right pos 590
localparam Y_MSG = 222;              // message rows pos 240 - H/2
localparam W = 20, H = 36, T = 4, GAP = 10; // width height thickness gap for digits of score  

// message rows are y >= 128 score rows are y < 128
assign state_display_pixel = |y[9:7];
wire [9:0] Y0 = state_display_pixel ? Y_MSG : Y_SCORE;
wire in_y = (y >= Y0) && (y < Y0 + H);
wire [9:0] ly = y - Y0;

//score position 
wire in_h = (x >= X0) && (x < X0 + W);
wire in_t = (x >= X0+(W+GAP)) && (x < X0 + 2*W + GAP);
wire in_o = (x >= X0+2*(W+GAP)) && (x < X0 + 3*W + 2*GAP);
 
wire [9:0] lx_s = in_h ? (x - X0) :in_t ? (x - (X0 + (W + GAP))) : (x - (X0 + 2*(W + GAP)));
wire [3:0] digit_s = in_h ? hundreds : in_t ? tens : ones;

//msg position 
reg [4:0] digit_m;
reg valid_m;
always @(*) begin
	digit_m = 5'd0;
	valid_m = 1'b1;
	if (start) begin            //start
		case (x[9:5])
			5'd8: digit_m = 5'd5;    // S
			5'd9: digit_m = 5'd13;   // t
			5'd10: digit_m = 5'd14;  // A
			5'd11: digit_m = 5'd12;  // r
			5'd12: digit_m = 5'd13;  // t
			default: valid_m = 1'b0;
		endcase
	end 
	else if (win) begin                  
		case (x[9:5]) //win - display YAY 
			5'd8: digit_m = 5'd17; //Y   
			5'd9: digit_m = 5'd14; //A  
			5'd10: digit_m = 5'd17; //Y  
                default: valid_m = 1'b0;
            endcase
    	end 
	else if (game_over) begin //lose : you died 
		case (x[9:5])
			5'd6: digit_m = 5'd17;              // Y
			5'd7: digit_m = 5'd0;              // O
			5'd8: digit_m = 5'd15;             // U
			5'd10: digit_m = 5'd11;             // D
			5'd11: digit_m = 5'd1;              // I
			5'd12: digit_m = 5'd10;             // E
			5'd13: digit_m = 5'd11;             // D
			default: valid_m = 1'b0;            // cell 9 is the space
		endcase
	end 
	else begin
		valid_m = 1'b0;                         // nothing to show
	end
end
 
// select, then shared 7-segment logic ----------------
wire [9:0] lx = state_display_pixel ? {5'b0, x[4:0]}: lx_s;
wire [4:0] digit = state_display_pixel ? digit_m: {1'b0, digit_s};
wire in_x = state_display_pixel ? (valid_m && x[4:0] < W): (in_h || in_t || in_o);
// segments {a,b,c,d,e,f,g}
reg [6:0] seg;
always @(*) begin
	case (digit)
		5'd0: seg = 7'b1111110;   // 0 / O
		5'd1: seg = 7'b0110000;   // 1 / I
		5'd2: seg = 7'b1101101;
		5'd3: seg = 7'b1111001;
		5'd4: seg = 7'b0110011;   // 4 
		5'd5: seg = 7'b1011011;   // 5 / S
		5'd6: seg = 7'b1011111;
		5'd7: seg = 7'b1110000;
		5'd8: seg = 7'b1111111;
		5'd9: seg = 7'b1111011;
		5'd10: seg = 7'b1001111;   // E
		5'd11: seg = 7'b0111101;   // d (D)
		5'd12: seg = 7'b0000101;   // r
		5'd13: seg = 7'b0001111;   // t
		5'd14: seg = 7'b1110111;   // A
		5'd15: seg = 7'b0111110;   // U
		5'd16: seg = 7'b0010101;   // n
        5'd17: seg = 7'b0111011;   // Y
		default: seg = 7'b0;
	endcase
end
wire top = ly < T;
wire bot = ly >= H - T;
wire mid = (ly >= H/2 - T/2) && (ly < H/2 + T/2);
wire up = ly < H/2;
wire lo = ly >= H/2;
wire left = lx < T;
wire rght = lx >= W - T;
wire [6:0] hit = { top, rght & up, rght & lo, bot, left & lo, left & up, mid };
assign score_pixel = in_y && in_x && |(seg & hit);
endmodule
