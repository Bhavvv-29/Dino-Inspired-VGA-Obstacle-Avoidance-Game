module circle_lut #(
    parameter BALL_X = 100
)(
    input [9:0] x, y, ball_y,
    output inside_circle
);
    localparam BALL_R = 30;

    wire [10:0] diff_x = x-BALL_X;
    wire [10:0] diff_y = y-ball_y+BALL_R;

    wire [9:0] dx = diff_x[9:0]^{10{diff_x[10]}};
    wire [9:0] dy = diff_y[9:0]^{10{diff_y[10]}};

    reg [4:0] width;

    always @(*) begin
        case (dy[4:0])
            5'd0: width = 5'd30;
            5'd1: width = 5'd29;
            5'd2: width = 5'd29;
            5'd3: width = 5'd29;
            5'd4: width = 5'd29;
            5'd5: width = 5'd29;
            5'd6: width = 5'd29;
            5'd7: width = 5'd29;
            5'd8: width = 5'd28;
            5'd9: width = 5'd28;
            5'd10: width = 5'd28;
            5'd11: width = 5'd27;
            5'd12: width = 5'd27;
            5'd13: width = 5'd27;
            5'd14: width = 5'd26;
            5'd15: width = 5'd25;
            5'd16: width = 5'd25;
            5'd17: width = 5'd24;
            5'd18: width = 5'd24;
            5'd19: width = 5'd23;
            5'd20: width = 5'd22;
            5'd21: width = 5'd21;
            5'd22: width = 5'd20;
            5'd23: width = 5'd19;
            5'd24: width = 5'd18;
            5'd25: width = 5'd16;
            5'd26: width = 5'd14;
            5'd27: width = 5'd13;
            5'd28: width = 5'd10;
            5'd29: width = 5'd7;
            5'd30: width = 5'd0;
            default: width = 5'd0;
        endcase
    end

    assign inside_circle = (dy<=BALL_R) && (dx[9:5]==0) && (dx[4:0]<=width);

endmodule