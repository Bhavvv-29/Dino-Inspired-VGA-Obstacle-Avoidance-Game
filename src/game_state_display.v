module game_state_display (
    input  wire [9:0] x, y,
    input  wire       game_over,
    output wire       pixel
);
    // 3x5 glyphs, row 0 in the top bits, 3 bits per row
    localparam [14:0] G = 15'b011_100_101_101_011;
    localparam [14:0] A = 15'b010_101_111_101_101;
    localparam [14:0] M = 15'b101_111_111_101_101;
    localparam [14:0] E = 15'b111_100_110_100_111;
    localparam [14:0] O = 15'b010_101_101_101_010;
    localparam [14:0] V = 15'b101_101_101_101_010;
    localparam [14:0] R = 15'b110_101_110_101_101;

    wire [3:0] chr_cell = x[7:4];     // which 16 px character cell
    wire [2:0] row  = y[4:2];     // which font row (0-4 valid)
    wire [1:0] col  = x[3:2];     // which font column (0-2 valid)

    reg [14:0] bitmap;
    reg [2:0]  glyph_row;

    always @(*) begin
        case (chr_cell)
            4'd0: bitmap = G;
            4'd1: bitmap = A;
            4'd2: bitmap = M;
            4'd3: bitmap = E;
            // 4'd4 is the space
            4'd5: bitmap = O;
            4'd6: bitmap = V;
            4'd7: bitmap = E;
            4'd8: bitmap = R;
            default: bitmap = 15'b0;
        endcase

        case (row)
            3'd0: glyph_row = bitmap[14:12];
            3'd1: glyph_row = bitmap[11:9];
            3'd2: glyph_row = bitmap[8:6];
            3'd3: glyph_row = bitmap[5:3];
            3'd4: glyph_row = bitmap[2:0];
            default: glyph_row = 3'b0;   // rows 5-7 are blank
        endcase
    end

    assign pixel = game_over
                && (x[9:8] == 2'b01)
                && (y[9:5] == 5'd7)
                && ((col == 2'd0 && glyph_row[2]) ||
                    (col == 2'd1 && glyph_row[1]) ||
                    (col == 2'd2 && glyph_row[0]));
endmodule