module score_display (
    input  wire [9:0] x, y,
    input  wire [3:0] thousands, hundreds, tens, ones,
    output wire       pixel
);
    localparam X0 = 480, Y0 = 20;   // top-left of the 4-digit block
    localparam W = 20, H = 36, T = 4, GAP = 10;

    wire in_th = (x >= X0)           && (x < X0 + W);
    wire in_h  = (x >= X0+(W+GAP))   && (x < X0 + 2*W + GAP);
    wire in_t  = (x >= X0+2*(W+GAP)) && (x < X0 + 3*W + 2*GAP);
    wire in_o  = (x >= X0+3*(W+GAP)) && (x < X0 + 4*W + 3*GAP);
    wire in_y  = (y >= Y0)           && (y < Y0 + H);

    // local coordinates only matter inside a digit box (< 20 x < 36),
    // and 'pixel' is gated by in_*, so 5 / 6 bits are enough
    wire [4:0] lx = in_th ? (x[4:0] - X0[4:0]) :
                    in_h  ? (x[4:0] - (X0 + (W + GAP))) :
                    in_t  ? (x[4:0] - (X0 + 2*(W + GAP))) :
                            (x[4:0] - (X0 + 3*(W + GAP)));
    wire [5:0] ly = y[5:0] - Y0[5:0];
    wire [3:0] digit = in_th ? thousands :
                       in_h  ? hundreds  :
                       in_t  ? tens      : ones;

    // segments {a,b,c,d,e,f,g}
    reg [6:0] seg;
    always @(*) begin
        case (digit)
            4'd0: seg = 7'b1111110;
            4'd1: seg = 7'b0110000;
            4'd2: seg = 7'b1101101;
            4'd3: seg = 7'b1111001;
            4'd4: seg = 7'b0110011;
            4'd5: seg = 7'b1011011;
            4'd6: seg = 7'b1011111;
            4'd7: seg = 7'b1110000;
            4'd8: seg = 7'b1111111;
            4'd9: seg = 7'b1111011;
            default: seg = 7'b0;
        endcase
    end

    wire top  = ly < T;
    wire bot  = ly >= H - T;
    wire mid  = (ly >= H/2 - T/2) && (ly < H/2 + T/2);
    wire up   = ly < H/2;
    wire lo   = ly >= H/2;
    wire left = lx < T;
    wire rght = lx >= W - T;

    wire [6:0] hit = { top, rght & up, rght & lo, bot, left & lo, left & up, mid };

    assign pixel = in_y && (in_th || in_h || in_t || in_o) && |(seg & hit);
endmodule