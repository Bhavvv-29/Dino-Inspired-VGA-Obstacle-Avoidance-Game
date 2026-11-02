module game_state_display (
    input  wire [9:0] x, y,
    input  wire       game_over,
    output wire       pixel
);

    localparam X0 = 224;
    localparam Y0 = 220;
    localparam CHAR_W = 20;
    localparam CHAR_H = 28;
    localparam CHAR_GAP = 8;
    localparam WORD_GAP = 12;

    // Character starting X positions
    localparam X_G = X0;
    localparam X_A = X_G + CHAR_W + CHAR_GAP;
    localparam X_M = X_A + CHAR_W + CHAR_GAP;
    localparam X_E1 = X_M + CHAR_W + CHAR_GAP;

    localparam X_O = X_E1 + CHAR_W + CHAR_GAP + WORD_GAP;
    localparam X_V = X_O + CHAR_W + CHAR_GAP;
    localparam X_E2 = X_V + CHAR_W + CHAR_GAP;
    localparam X_R = X_E2 + CHAR_W + CHAR_GAP;

    wire [4:0] glyph_row;

    wire row0 = y >= Y0      && y < Y0+4;
    wire row1 = y >= Y0+4    && y < Y0+8;
    wire row2 = y >= Y0+8    && y < Y0+12;
    wire row3 = y >= Y0+12   && y < Y0+16;
    wire row4 = y >= Y0+16   && y < Y0+20;
    wire row5 = y >= Y0+20   && y < Y0+24;
    wire row6 = y >= Y0+24   && y < Y0+28;

    reg [4:0] bitmap;

    always @(*) begin
        bitmap = 5'b00000;

        // GAME
        if (x >= X_G && x < X_G+20) begin
            if      (row0) bitmap = 5'b01110;
            else if (row1) bitmap = 5'b10001;
            else if (row2) bitmap = 5'b10000;
            else if (row3) bitmap = 5'b10111;
            else if (row4) bitmap = 5'b10001;
            else if (row5) bitmap = 5'b10001;
            else if (row6) bitmap = 5'b01110;
        end

        else if (x >= X_A && x < X_A+20) begin
            if      (row0) bitmap = 5'b01110;
            else if (row1) bitmap = 5'b10001;
            else if (row2) bitmap = 5'b10001;
            else if (row3) bitmap = 5'b11111;
            else if (row4) bitmap = 5'b10001;
            else if (row5) bitmap = 5'b10001;
            else if (row6) bitmap = 5'b10001;
        end

        else if (x >= X_M && x < X_M+20) begin
            if      (row0) bitmap = 5'b10001;
            else if (row1) bitmap = 5'b11011;
            else if (row2) bitmap = 5'b10101;
            else if (row3) bitmap = 5'b10101;
            else if (row4) bitmap = 5'b10001;
            else if (row5) bitmap = 5'b10001;
            else if (row6) bitmap = 5'b10001;
        end

        else if (x >= X_E1 && x < X_E1+20) begin
            if      (row0) bitmap = 5'b11111;
            else if (row1) bitmap = 5'b10000;
            else if (row2) bitmap = 5'b10000;
            else if (row3) bitmap = 5'b11110;
            else if (row4) bitmap = 5'b10000;
            else if (row5) bitmap = 5'b10000;
            else if (row6) bitmap = 5'b11111;
        end

        // OVER
        else if (x >= X_O && x < X_O+20) begin
            if      (row0) bitmap = 5'b01110;
            else if (row1) bitmap = 5'b10001;
            else if (row2) bitmap = 5'b10001;
            else if (row3) bitmap = 5'b10001;
            else if (row4) bitmap = 5'b10001;
            else if (row5) bitmap = 5'b10001;
            else if (row6) bitmap = 5'b01110;
        end

        else if (x >= X_V && x < X_V+20) begin
            if      (row0) bitmap = 5'b10001;
            else if (row1) bitmap = 5'b10001;
            else if (row2) bitmap = 5'b10001;
            else if (row3) bitmap = 5'b10001;
            else if (row4) bitmap = 5'b10001;
            else if (row5) bitmap = 5'b01010;
            else if (row6) bitmap = 5'b00100;
        end

        else if (x >= X_E2 && x < X_E2+20) begin
            if      (row0) bitmap = 5'b11111;
            else if (row1) bitmap = 5'b10000;
            else if (row2) bitmap = 5'b10000;
            else if (row3) bitmap = 5'b11110;
            else if (row4) bitmap = 5'b10000;
            else if (row5) bitmap = 5'b10000;
            else if (row6) bitmap = 5'b11111;
        end

        else if (x >= X_R && x < X_R+20) begin
            if      (row0) bitmap = 5'b11110;
            else if (row1) bitmap = 5'b10001;
            else if (row2) bitmap = 5'b10001;
            else if (row3) bitmap = 5'b11110;
            else if (row4) bitmap = 5'b10100;
            else if (row5) bitmap = 5'b10010;
            else if (row6) bitmap = 5'b10001;
        end
    end

    // Decode the five horizontal pixel columns
    wire c0 = (x >= X_G     && x < X_G+4)     ||
              (x >= X_A     && x < X_A+4)     ||
              (x >= X_M     && x < X_M+4)     ||
              (x >= X_E1    && x < X_E1+4)    ||
              (x >= X_O     && x < X_O+4)     ||
              (x >= X_V     && x < X_V+4)     ||
              (x >= X_E2    && x < X_E2+4)    ||
              (x >= X_R     && x < X_R+4);

    wire c1 = (x >= X_G+4  && x < X_G+8)  ||
              (x >= X_A+4  && x < X_A+8)  ||
              (x >= X_M+4  && x < X_M+8)  ||
              (x >= X_E1+4 && x < X_E1+8) ||
              (x >= X_O+4  && x < X_O+8)  ||
              (x >= X_V+4  && x < X_V+8)  ||
              (x >= X_E2+4 && x < X_E2+8) ||
              (x >= X_R+4  && x < X_R+8);

    wire c2 = (x >= X_G+8  && x < X_G+12)  ||
              (x >= X_A+8  && x < X_A+12)  ||
              (x >= X_M+8  && x < X_M+12)  ||
              (x >= X_E1+8 && x < X_E1+12) ||
              (x >= X_O+8  && x < X_O+12)  ||
              (x >= X_V+8  && x < X_V+12)  ||
              (x >= X_E2+8 && x < X_E2+12) ||
              (x >= X_R+8  && x < X_R+12);

    wire c3 = (x >= X_G+12  && x < X_G+16)  ||
              (x >= X_A+12  && x < X_A+16)  ||
              (x >= X_M+12  && x < X_M+16)  ||
              (x >= X_E1+12 && x < X_E1+16) ||
              (x >= X_O+12  && x < X_O+16)  ||
              (x >= X_V+12  && x < X_V+16)  ||
              (x >= X_E2+12 && x < X_E2+16) ||
              (x >= X_R+12  && x < X_R+16);

    wire c4 = (x >= X_G+16  && x < X_G+20)  ||
              (x >= X_A+16  && x < X_A+20)  ||
              (x >= X_M+16  && x < X_M+20)  ||
              (x >= X_E1+16 && x < X_E1+20) ||
              (x >= X_O+16  && x < X_O+20)  ||
              (x >= X_V+16  && x < X_V+20)  ||
              (x >= X_E2+16 && x < X_E2+20) ||
              (x >= X_R+16  && x < X_R+20);

    assign pixel = game_over &&
                   ((c0 && bitmap[4]) ||
                    (c1 && bitmap[3]) ||
                    (c2 && bitmap[2]) ||
                    (c3 && bitmap[1]) ||
                    (c4 && bitmap[0]));

endmodule