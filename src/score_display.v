module score_display (
    input  wire [9:0] x, y,
    input  wire       start, game_over,
    input  wire [3:0] thousands, hundreds, tens, ones,
    output wire       pixel
);
    // ---------------- score (unchanged) ----------------
    localparam X0 = 480, Y0 = 20;   // top-left of the 4-digit block
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

    wire score_pixel = in_y && (in_th || in_h || in_t || in_o) && |(seg & hit);

    // ---------------- centre message: "START" / "YOU DIED" ----------------
    // 32 px cells (cell = x[9:5]); glyph is 16 px wide centred in the cell (x[4:0] = 8..23)
    // rows y = 224..255 (y[9:5] == 7)
    reg [6:0] mseg;                         // {a,b,c,d,e,f,g}
    always @(*) begin
        mseg = 7'b0;
        if (game_over) begin                // cells 6..13 : Y O U _ D I E D
            case (x[9:5])
                5'd6:  mseg = 7'b0111011;   // Y
                5'd7:  mseg = 7'b1111110;   // O
                5'd8:  mseg = 7'b0111110;   // U
                5'd10: mseg = 7'b0111101;   // D
                5'd11: mseg = 7'b0110000;   // I
                5'd12: mseg = 7'b1001111;   // E
                5'd13: mseg = 7'b0111101;   // D
                default: mseg = 7'b0;
            endcase
        end else if (start) begin           // cells 7..11 : S T A R T
            case (x[9:5])
                5'd7:  mseg = 7'b1011011;   // S
                5'd8:  mseg = 7'b0001111;   // t
                5'd9:  mseg = 7'b1110111;   // A
                5'd10: mseg = 7'b0000101;   // r
                5'd11: mseg = 7'b0001111;   // t
                default: mseg = 7'b0;
            endcase
        end
    end

    wire m_glyph = x[4] ^ x[3];             // x[4:0] in 8..23
    wire m_top   = (y[4:2] == 3'd0);
    wire m_bot   = (y[4:2] == 3'd7);
    wire m_mid   = (y[4:1] == 4'd7) || (y[4:1] == 4'd8);   // rows 14..17
    wire m_up    = ~y[4];
    wire m_lo    =  y[4];
    wire m_left  = ~x[4] & ~x[2];           // first 4 px of the glyph
    wire m_rght  =  x[4] &  x[2];           // last 4 px of the glyph

    wire [6:0] mhit = { m_top, m_rght & m_up, m_rght & m_lo, m_bot,
                        m_left & m_lo, m_left & m_up, m_mid };

    wire msg_pixel = (y[9:5] == 5'd7) && m_glyph && |(mseg & mhit);

    assign pixel = score_pixel | msg_pixel;
endmodule