`default_nettype none

module hud (
    input wire [9:0] x, y,
    input wire start, game_over, win,
    input wire [3:0] hundreds, tens, ones,
    output wire score_pixel, state_display_pixel
);
    localparam X0 = 510, Y_SCORE = 20;   // score block (3 digits, right edge at 590)
    localparam Y_MSG = 222;              // message rows: 240 - H/2
    localparam W = 20, H = 36, T = 4, GAP = 10;
    localparam XT = X0 + (W + GAP), XO = X0 + 2*(W + GAP);   // tens/ones cell start

    // row windows, the two never overlap
    wire in_ys = (y >= Y_SCORE) && (y < Y_SCORE + H);
    wire in_ym = (y >= Y_MSG) && (y < Y_MSG + H);

    // row select, only used inside the windows (y = 256, 257 are message rows)
    wire msg_row = y[8] | y[7];

    // 6 bits are enough, ly < 36 inside the windows
    wire [5:0] Y0 = msg_row ? Y_MSG[5:0] : Y_SCORE[5:0];
    wire [5:0] ly = y[5:0] - Y0;

    // score position check ------------------------------------------------------------------------------------
    wire in_h = (x >= X0) && (x < X0 + W);
    wire in_t = (x >= XT) && (x < XT + W);
    wire in_o = (x >= XO) && (x < XO + W);
    wire in_xs = in_h || in_t || in_o;

    // 5 bits are enough, lx < 20 inside the glyph
    wire [4:0] Xc = in_h ? X0[4:0] : in_t ? XT[4:0] : XO[4:0];
    wire [4:0] lx_s = x[4:0] - Xc;
    wire [3:0] digit_s = in_h ? hundreds : in_t ? tens : ones;

    // gamestate position check --------------------------------------------------------------------------------
    // 32 px cells, cell = x[9:5], local x = x[4:0], glyph is the first W=20 px of the cell
    // codes: 0=O 1=I 5=S 10=E 11=D 12=r 13=t 14=A 15=U 17=y
    reg [4:0] digit_m;
    reg valid_m;

    always @(*) begin
        digit_m = 5'd0;
        valid_m = 1'b1;
        if (start) begin                            // cells 8..12 : START
            case (x[9:5])
                5'd8: digit_m = 5'd5;               // S
                5'd9: digit_m = 5'd13;              // t
                5'd10: digit_m = 5'd14;             // A
                5'd11: digit_m = 5'd12;             // r
                5'd12: digit_m = 5'd13;             // t
                default: valid_m = 1'b0;
            endcase
        end else if (win) begin                     // cells 8..10 : yAy
            case (x[9:5])
                5'd8: digit_m = 5'd17;              // y
                5'd9: digit_m = 5'd14;              // A
                5'd10: digit_m = 5'd17;             // y
                default: valid_m = 1'b0;
            endcase
        end else if (game_over) begin               // cells 6..13 : YOU DIED
            case (x[9:5])
                5'd6: digit_m = 5'd17;              // y
                5'd7: digit_m = 5'd0;               // O
                5'd8: digit_m = 5'd15;              // U
                5'd10: digit_m = 5'd11;             // d
                5'd11: digit_m = 5'd1;              // I
                5'd12: digit_m = 5'd10;             // E
                5'd13: digit_m = 5'd11;             // d
                default: valid_m = 1'b0;            // cell 9 is the space
            endcase
        end else begin
            valid_m = 1'b0;                         // nothing to show
        end
    end

    wire in_xm = valid_m && x[4:0] < W;

    // select, then shared 7-segment logic 
    wire [4:0] lx = msg_row ? x[4:0] : lx_s;
    wire [4:0] digit = msg_row ? digit_m : {1'b0, digit_s};

    // segments {a,b,c,d,e,f,g}, digit[4] is only set by the y code
    reg [6:0] seg;
    always @(*) begin
        case (digit[3:0])
            4'd0:  seg = 7'b1111110;   // 0 / O
            4'd1:  seg = 7'b0110000;   // 1 / I
            4'd2:  seg = 7'b1101101;
            4'd3:  seg = 7'b1111001;
            4'd4:  seg = 7'b0110011;   // 4
            4'd5:  seg = 7'b1011011;   // 5 / S
            4'd6:  seg = 7'b1011111;
            4'd7:  seg = 7'b1110000;
            4'd8:  seg = 7'b1111111;
            4'd9:  seg = 7'b1111011;
            4'd10: seg = 7'b1001111;   // E
            4'd11: seg = 7'b0111101;   // d (D)
            4'd12: seg = 7'b0000101;   // r
            4'd13: seg = 7'b0001111;   // t
            4'd14: seg = 7'b1110111;   // A
            4'd15: seg = 7'b0111110;   // U
        endcase
        if (digit[4]) seg = 7'b0111011;   // Y
    end

    wire top = ly < T;
    wire bot = ly >= H-T;
    wire mid = (ly >= H/2 - T/2) && (ly < H/2 + T/2);
    wire up = ly < H/2;
    wire lo = ly >= H/2;
    wire left = lx < T;
    wire rght = lx >= W - T;

    wire [6:0] hit = {top, rght & up, rght & lo, bot, left & lo, left & up, mid};

    // one glyph hit, routed to exactly one output by row window
    wire glyph = |(seg & hit);

    assign score_pixel = in_ys && in_xs && glyph;
    assign state_display_pixel = in_ym && in_xm && glyph;
endmodule
