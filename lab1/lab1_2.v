`timescale 1ns/100ps
module lab1_2 (a, b, aluctr, d);
    input [3:0] a;
    input [1:0] b, aluctr;
    output reg [3:0] d;
    wire [3:0] leftshift, rightshift;
    lab1_1 lshift (a, b, 1'b0, leftshift);
    lab1_1 rshift (a, b, 1'b1, rightshift);
    always@* begin
        d = 4'd0;
        case(aluctr)
            2'b00 : d = leftshift;
            2'b01 : d = rightshift;
            2'b10 : d = a + b;
            2'b11 : d = a - b;
        endcase
    end
endmodule