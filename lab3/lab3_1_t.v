module lab3_1_t;
    reg clk, rst, en, speed;
    wire [15:0] led;
    
    lab3_1 test(clk, rst, en, speed, led);
    
    initial begin
        clk = 1'b0;
        {rst, en, speed} = 3'b000;
        #10 en = 1'b1;
        #100 speed = 1'b1;
        #100 en = 1'b0;
        #50 en = 1'b1;
        #5 en = 1'b0;
        #10 rst = ~rst;
        #10 en = 1'b1;
        #10 speed = 1'b0;
        #100
        #10 rst = ~rst;
        #100 speed = 1'b1;
        #500 $finish;        
    end
    
    always #5 clk = ~clk;
    
endmodule