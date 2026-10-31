module game_over_display (
    input  wire [9:0] x, y,
    input  wire       game_over,
    output wire       pixel
);
    localparam X0 = 265, Y0 = 222;
    localparam W = 20, H = 36, T = 4, GAP = 10;

    wire in_th = (x >= X0)           && (x < X0 + W);
    wire in_h  = (x >= X0+(W+GAP))   && (x < X0 + 2*W + GAP);
    wire in_t  = (x >= X0+2*(W+GAP)) && (x < X0 + 3*W + 2*GAP);
    wire in_o  = (x >= X0+3*(W+GAP)) && (x < X0 + 4*W + 3*GAP);
    wire in_y  = (y >= Y0)           && (y < Y0 + H);

    wire [9:0] lx = in_th ? (x - X0) :
                    in_h  ? (x - (X0 + (W + GAP))) :
                    in_t  ? (x - (X0 + 2*(W + GAP))) :
                            (x - (X0 + 3*(W + GAP)));
    wire [9:0] ly = y - Y0;

    // segments {a,b,c,d,e,f,g}
    wire [6:0] seg = in_th ? 7'b1111110 :
                     in_h  ? 7'b0111110 :
                     in_t  ? 7'b1001111 :
                             7'b1110111;

    wire top  = ly < T;
    wire bot  = ly >= H - T;
    wire mid  = (ly >= H/2 - T/2) && (ly < H/2 + T/2);
    wire up   = ly < H/2;
    wire lo   = ly >= H/2;
    wire left = lx < T;
    wire rght = lx >= W - T;

    wire [6:0] hit = { top, rght & up, rght & lo, bot, left & lo, left & up, mid };

    assign pixel = game_over && in_y && (in_th || in_h || in_t || in_o) && |(seg & hit);
endmodule