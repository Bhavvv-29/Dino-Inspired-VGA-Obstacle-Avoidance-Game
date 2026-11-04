`default_nettype none

module circle_lut #(
    parameter BALL_X = 100
)(
    input wire [9:0] x, y, ball_y,
    output wire inside_circle
);

    localparam BALL_R = 30;

    // distance from circle center to the current pixel (x,y)
    wire [9:0] dx = (x >= BALL_X) ? x-BALL_X : BALL_X-x;
    wire [9:0] dy = (y >= ball_y-BALL_R) ? y-(ball_y-BALL_R) : (ball_y-BALL_R)-y;

    reg [4:0] width;

    // circle rendering lut, as dy increases, width decreases
    always @(*) begin
        case (dy)
            10'd0:  width = 5'd30;
            10'd1:  width = 5'd29;
            10'd2:  width = 5'd29;
            10'd3:  width = 5'd29;
            10'd4:  width = 5'd29;
            10'd5:  width = 5'd29;
            10'd6:  width = 5'd29;
            10'd7:  width = 5'd29;
            10'd8:  width = 5'd28;
            10'd9:  width = 5'd28;
            10'd10: width = 5'd28;
            10'd11: width = 5'd27;
            10'd12: width = 5'd27;
            10'd13: width = 5'd27;
            10'd14: width = 5'd26;
            10'd15: width = 5'd25;
            10'd16: width = 5'd25;
            10'd17: width = 5'd24;
            10'd18: width = 5'd24;
            10'd19: width = 5'd23;
            10'd20: width = 5'd22;
            10'd21: width = 5'd21;
            10'd22: width = 5'd20;
            10'd23: width = 5'd19;
            10'd24: width = 5'd18;
            10'd25: width = 5'd16;
            10'd26: width = 5'd14;
            10'd27: width = 5'd13;
            10'd28: width = 5'd10;
            10'd29: width = 5'd7;
            10'd30: width = 5'd0;
            default: width = 5'd0;
        endcase
    end

    // pixel (x,y) is inside the circle, if dy is less than the radius, and dx is less than the width
    assign inside_circle = (dy <= BALL_R) && (dx <= {5'd0, width});

endmodule