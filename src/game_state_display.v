module game_state_display (
    input  wire [9:0] x, y,
    input  wire       game_over,
    output wire       pixel
);

    localparam X0 = 224;
    localparam Y0 = 220;

    // Character start positions
    localparam X_G  = X0;
    localparam X_A  = X0 + 16;
    localparam X_M  = X0 + 32;
    localparam X_E1 = X0 + 48;

    localparam X_O  = X0 + 76;
    localparam X_V  = X0 + 92;
    localparam X_E2 = X0 + 108;
    localparam X_R  = X0 + 124;

    wire active_y = (y >= Y0) && (y < Y0 + 20);

    wire row0 = y < Y0+4;
    wire row1 = y >= Y0+4  && y < Y0+8;
    wire row2 = y >= Y0+8  && y < Y0+12;
    wire row3 = y >= Y0+12 && y < Y0+16;
    wire row4 = y >= Y0+16;

    reg [2:0] glyph;
    reg [9:0] char_x;
    reg active_char;

    always @(*) begin
        glyph = 3'b000;
        char_x = 0;
        active_char = 1'b0;

        if (x >= X_G && x < X_G+12) begin
            char_x = x-X_G;
            active_char = 1'b1;
            case (1'b1)
                row0: glyph = 3'b011;
                row1: glyph = 3'b100;
                row2: glyph = 3'b101;
                row3: glyph = 3'b101;
                row4: glyph = 3'b011;
            endcase
        end

        else if (x >= X_A && x < X_A+12) begin
            char_x = x-X_A;
            active_char = 1'b1;
            case (1'b1)
                row0: glyph = 3'b010;
                row1: glyph = 3'b101;
                row2: glyph = 3'b111;
                row3: glyph = 3'b101;
                row4: glyph = 3'b101;
            endcase
        end

        else if (x >= X_M && x < X_M+12) begin
            char_x = x-X_M;
            active_char = 1'b1;
            case (1'b1)
                row0: glyph = 3'b101;
                row1: glyph = 3'b111;
                row2: glyph = 3'b111;
                row3: glyph = 3'b101;
                row4: glyph = 3'b101;
            endcase
        end

        else if (x >= X_E1 && x < X_E1+12) begin
            char_x = x-X_E1;
            active_char = 1'b1;
            case (1'b1)
                row0: glyph = 3'b111;
                row1: glyph = 3'b100;
                row2: glyph = 3'b110;
                row3: glyph = 3'b100;
                row4: glyph = 3'b111;
            endcase
        end

        else if (x >= X_O && x < X_O+12) begin
            char_x = x-X_O;
            active_char = 1'b1;
            case (1'b1)
                row0: glyph = 3'b010;
                row1: glyph = 3'b101;
                row2: glyph = 3'b101;
                row3: glyph = 3'b101;
                row4: glyph = 3'b010;
            endcase
        end

        else if (x >= X_V && x < X_V+12) begin
            char_x = x-X_V;
            active_char = 1'b1;
            case (1'b1)
                row0: glyph = 3'b101;
                row1: glyph = 3'b101;
                row2: glyph = 3'b101;
                row3: glyph = 3'b101;
                row4: glyph = 3'b010;
            endcase
        end

        else if (x >= X_E2 && x < X_E2+12) begin
            char_x = x-X_E2;
            active_char = 1'b1;
            case (1'b1)
                row0: glyph = 3'b111;
                row1: glyph = 3'b100;
                row2: glyph = 3'b110;
                row3: glyph = 3'b100;
                row4: glyph = 3'b111;
            endcase
        end

        else if (x >= X_R && x < X_R+12) begin
            char_x = x-X_R;
            active_char = 1'b1;
            case (1'b1)
                row0: glyph = 3'b110;
                row1: glyph = 3'b101;
                row2: glyph = 3'b110;
                row3: glyph = 3'b101;
                row4: glyph = 3'b101;
            endcase
        end
    end

    wire col0 = char_x < 4;
    wire col1 = char_x >= 4 && char_x < 8;
    wire col2 = char_x >= 8;

    assign pixel = game_over && active_y && active_char &&
                   ((col0 && glyph[2]) ||
                    (col1 && glyph[1]) ||
                    (col2 && glyph[0]));

endmodule