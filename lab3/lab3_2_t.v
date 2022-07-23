`timescale 1ns / 1ps
module lab3_2_t;
    reg clk, rst, en, dir;
    wire [15:0] led;
    
    lab3_2 test(clk, rst, en, dir, led);
    
    initial begin
        clk = 1'b0;
        {rst, en, dir} = 3'b000;
        #50 rst = 1'b1;
        #300 rst = 1'b0;
        #10 en = 1'b1;
        #1800
        #260 dir = 1'b1;
        #200 dir = 1'b0;
        #1600
        #1000 $finish;        
    end
    
    always #5 clk = ~clk;
    
endmodule