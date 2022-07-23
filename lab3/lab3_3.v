`timescale 1ns / 1ps
module lab3_3 (clk, rst, en, speed, led);
    input clk, rst, en, speed;
    output [15:0] led;
    wire clk0_1, clk0_3, clk1_1, clk1_3, clk1, clk3;
    reg [15:0] led1, led3, led1_next, led3_next;
    reg dir = 1'b0, dir_next; // =>
    reg [3:0] pos1, pos3, pos1_next, pos3_next;

    clock_divider #(23) speed0_1 (clk, clk0_1);
    clock_divider #(24) speed1_1 (clk, clk1_1);
    clock_divider #(25) speed0_3 (clk, clk0_3);
    clock_divider #(26) speed1_3 (clk, clk1_3);

    assign clk1 = (speed == 0) ? clk0_1 : clk1_1;
    assign clk3 = (speed == 0) ? clk0_3 : clk1_3;

    always@(posedge clk1) begin
        if(rst) begin
            led1 <= 16'b1000_0000_0000_0000;
            dir <= 1'b0;
            pos1 <= 4'd15;
        end else begin
            led1 <= led1_next;
            dir <= dir_next;
            pos1 <= pos1_next;
        end
    end

    always@(posedge clk3) begin // <=
        if(rst) begin
            led3 <= 16'b0000_0000_0000_0111;
            pos3 <= 4'd1;
        end else begin
            led3 <= led3_next;
            pos3 <= pos3_next;
        end
    end

    always@(*) begin
        if(en) begin
            led3_next[0] = led3[15];
            led3_next[15:1] = led3[14:0];
            pos3_next = (pos3 == 4'd15) ? 4'd0 : pos3 + 4'd1;
            if(!dir && (pos1 - pos3 == 4'd2 || pos1 - pos3 == 4'd1 || pos1 - pos3 == 4'd0)) begin //=>
                led1_next[0] = led1[15];
                led1_next[15:1] = led1[14:0];
                pos1_next = (pos1 == 4'd15) ? 4'd0 : pos1 + 4'd1;
                dir_next = 1'b1;
            end else if(dir && (pos3 - pos1 == 4'd2 || pos3 - pos1 == 4'd1 || pos3 - pos1 == 4'd0)) begin // <=
                led1_next[15] = led1[0];
                led1_next[14:0] = led1[15:1];
                pos1_next = (pos1 == 4'd0) ? 4'd15 : pos1 - 4'd1;
                dir_next = 1'b0;
            end else begin
                if(dir) begin
                    led1_next[0] = led1[15];
                    led1_next[15:1] = led1[14:0];
                    pos1_next = (pos1 == 4'd15) ? 4'd0 : pos1 + 4'd1;
                    dir_next = dir;
                end else begin
                    led1_next[15] = led1[0];
                    led1_next[14:0] = led1[15:1];
                    pos1_next = (pos1 == 4'd0) ? 4'd15 : pos1 - 4'd1;
                    dir_next = dir;
                end
            end
        end else begin
            led1_next = led1;
            led3_next = led3;
            dir_next = dir;
            pos1_next = pos1;
            pos3_next = pos3;
        end
    end

    assign led = led1 | led3;
    
endmodule