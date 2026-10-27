module score_display (
    input  wire [9:0] x, y,
    input  wire [3:0] tens, ones,
    output wire       pixel
);
    localparam X0 = 540, Y0 = 20;   // top-right corner
    localparam W = 20, H = 36, T = 4, GAP = 10;

    wire in_tens = (x >= X0)         && (x < X0 + W);
    wire in_ones = (x >= X0+W+GAP)   && (x < X0 + 2*W + GAP);
    wire in_y    = (y >= Y0)         && (y < Y0 + H);

    wire [9:0] lx = in_tens ? (x - X0) : (x - (X0 + W + GAP));
    wire [9:0] ly = y - Y0;
    wire [3:0] digit = in_tens ? tens : ones;

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

    wire [6:0] hit = { top,        // a
                       rght & up,  // b
                       rght & lo,  // c
                       bot,        // d
                       left & lo,  // e
                       left & up,  // f
                       mid };      // g

    assign pixel = in_y && (in_tens || in_ones) && |(seg & hit);
endmodule