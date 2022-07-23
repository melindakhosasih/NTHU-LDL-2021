`timescale 1ns / 1ps
module clock_divider (clk, clk_div);
    parameter n = 25;
    input clk;
    output clk_div;
    reg [n-1 : 0] num = 0;
    wire [n-1 : 0] next_num;
    always@(posedge clk) begin
        num = next_num;
    end
    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule

module lab3_1 (clk, rst, en, speed, led);
    input clk, rst, en, speed;
    output [15:0] led;
    reg [15:0] led_next;
    wire clock;
    wire clk_0, clk_1;

    clock_divider #(24) speed_0 (clk, clk_0);
    clock_divider #(27) speed_1 (clk, clk_1);
    
    assign clock = (speed == 0) ? clk_0 : clk_1;

    always@(posedge clock, posedge rst) begin
        if(rst) begin
            led_next = 16'b1111_1111_1111_1111;
        end else begin
            if(en) begin
                if(led == 16'b1111_1111_1111_1111) begin
                    led_next = 16'b0000_0000_0000_0000;
                end else begin
                    led_next = 16'b1111_1111_1111_1111;
                end
            end
            else led_next = led;
        end
    end
    assign led = led_next;
endmodule