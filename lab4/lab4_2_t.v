`timescale 1ns / 1ps
module lab4_2_t;
    reg clk, rst, en, input_number, enter, count_down;
    reg [3:0] DIGIT;
    reg [6:0] DISPLAY;
    wire led0;
    
    lab4_2 test(clk, rst, en, input_number, enter, count_down, DIGIT, DISPLAY, led0);
    
    initial begin
        clk = 1'b1;
        rst = 1'b1;
        #5 rst = 1'b0;
        #5 input_number = 1'b1;
        #300 //en = 1'b0; 
        #300 //en = 1'b1;
        //#1000 en = 1'b0;      
    end
    
    always #5 clk = ~clk;
    
endmodule