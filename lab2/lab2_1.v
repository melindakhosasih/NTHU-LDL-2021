`timescale 1ns / 100ps
module lab2_1 (clk, rst, out);
    input clk, rst;
    output reg [5:0] out;
    reg [5:0] cnt = 6'd0, idx = 6'd0;
    reg signed [6:0] check; 
    reg dir = 1'b0;
    always@(posedge clk, posedge rst) begin
        if(rst) begin
            out = 6'd0;
            cnt = 6'd0;
            idx = 6'd1;
            dir = 1'd0;
        end else begin
            if(!dir) begin
                if(cnt == 6'd63) begin
                    dir = 1'd1;
                    out = cnt << 1;
                    idx = 6'd1;
                end else begin
                    check = cnt - idx;
                    if(idx == 0) begin
                        out = 6'd0;
                    end
                    else if(check > 0) begin
                        out = cnt - idx;
                    end
                    else begin
                        out = cnt + idx;
                    end
                    idx = idx + 1;
                end
            end else begin
                out = cnt << 1;
                if(!out) dir = 0; 
            end
        end
        cnt = out;
    end
endmodule