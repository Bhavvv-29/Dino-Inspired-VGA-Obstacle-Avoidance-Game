module circle_lut #(
    parameter BALL_X = 100
)(
    input [9:0] x, y, ball_y,
    output inside_circle
);

    localparam BALL_R = 30;

    wire [9:0] dx;
    wire [9:0] dy;

    assign dx = (x>=BALL_X) ? x-BALL_X : BALL_X-x;
    assign dy = (y>=ball_y) ? (y-ball_y) : (ball_y - y);

    reg [4:0] circle_half_width;

    always @(*) begin
        case (dy[4:0])
            5'd0:  circle_half_width = 5'd30;
            5'd1:  circle_half_width = 5'd29;
            5'd2:  circle_half_width = 5'd29;
            5'd3:  circle_half_width = 5'd29;
            5'd4:  circle_half_width = 5'd29;
            5'd5:  circle_half_width = 5'd29;
            5'd6:  circle_half_width = 5'd29;
            5'd7:  circle_half_width = 5'd29;
            5'd8:  circle_half_width = 5'd28;
            5'd9:  circle_half_width = 5'd28;
            5'd10: circle_half_width = 5'd28;
            5'd11: circle_half_width = 5'd27;
            5'd12: circle_half_width = 5'd27;
            5'd13: circle_half_width = 5'd27;
            5'd14: circle_half_width = 5'd26;
            5'd15: circle_half_width = 5'd25;
            5'd16: circle_half_width = 5'd25;
            5'd17: circle_half_width = 5'd24;
            5'd18: circle_half_width = 5'd24;
            5'd19: circle_half_width = 5'd23;
            5'd20: circle_half_width = 5'd22;
            5'd21: circle_half_width = 5'd21;
            5'd22: circle_half_width = 5'd20;
            5'd23: circle_half_width = 5'd19;
            5'd24: circle_half_width = 5'd18;
            5'd25: circle_half_width = 5'd16;
            5'd26: circle_half_width = 5'd14;
            5'd27: circle_half_width = 5'd13;
            5'd28: circle_half_width = 5'd10;
            5'd29: circle_half_width = 5'd7;
            5'd30: circle_half_width = 5'd0;
            default: circle_half_width = 5'd0;
        endcase
    end

    assign inside_circle = (dy<=BALL_R) && dx<=circle_half_width;

endmodule