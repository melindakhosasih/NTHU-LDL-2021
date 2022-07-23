`timescale 1ns / 1ps
module lab4_1_t;
    reg clk, rst, en, dir, speed_up, speed_down;
    reg [3:0] DIGIT;
    reg [6:0] DISPLAY;
    wire max, min;
    
    lab4_1 test(clk, rst, en, dir, speed_up, speed_down, DIGIT, DISPLAY, max, min);
    
    initial begin
        clk = 1'b1;
        en = 1'b1;
        rst = 1'b1;
        #5 rst = 1'b0;
        #5 en = 1'b1;
        #300 en = 1'b0; 
        #300 en = 1'b1;
        speed_up = 1'b1;
        #1000 en = 1'b0;      
    end
    
    always #5 clk = ~clk;
    
endmodule