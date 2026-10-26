module hvsync_generator (
    input  wire       clk,
    input  wire       rst_n,
    output reg        hsync,
    output reg        vsync,
    output wire       display_on,
    output reg [9:0]  hpos,
    output reg [9:0]  vpos
);

    // Horizontal timing parameters
    parameter H_DISPLAY = 640;
    parameter H_BACK    = 48;
    parameter H_FRONT   = 16;
    parameter H_SYNC    = 96;

    // Vertical timing parameters
    parameter V_DISPLAY = 480;
    parameter V_TOP     = 33;
    parameter V_BOTTOM  = 10;
    parameter V_SYNC    = 2;

    // Derived parameters
    parameter H_SYNC_START = H_DISPLAY + H_FRONT;
    parameter H_SYNC_END   = H_DISPLAY + H_FRONT + H_SYNC - 1;
    parameter H_MAX        = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;

    parameter V_SYNC_START = V_DISPLAY + V_BOTTOM;
    parameter V_SYNC_END   = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
    parameter V_MAX        = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;

    // horizontal logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hpos <= 0;
            hsync <= 1;
        end
        else begin
            hsync <= ~((hpos >= H_SYNC_START) && (hpos <= H_SYNC_END));
            hpos <= (hpos == H_MAX) ? 0 : hpos+1;
        end
    end

    // vertical logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vpos <= 0;
            vsync <= 1;
        end
        else begin
            vsync <= ~((vpos >= V_SYNC_START) && (vpos <= V_SYNC_END));
            if (hpos == H_MAX)
                vpos <= (vpos == V_MAX) ? 0 : vpos+1;
        end
    end

    // is the current area in the visible display region
    assign display_on = (hpos < H_DISPLAY) && (vpos < V_DISPLAY);

endmodule