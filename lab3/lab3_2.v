`timescale 1ns / 1ps
module lab3_2 (clk, rst, en, dir, led);
    input clk, rst, en, dir;
    output reg [15:0] led;
    reg [15:0] next_led;
    reg [1:0] state, next_state;
    reg [2:0] cnt = 3'd0, next_cnt = 3'd0;
    reg signed [4:0] count = 5'd0, next_count = 5'd0;
    wire clk_div;

    parameter ON = 16'b1111_1111_1111_1111;
    parameter OFF = 16'b0000_0000_0000_0000;
    parameter SHIFT_INITIAL = 16'b1010_1010_1010_1010;
    parameter EXPAND_INITIAL = 16'b0000_0001_1000_0000;
    parameter S0 = 2'd0;
    parameter S1 = 2'd1;
    parameter S2 = 2'd2;

    clock_divider #(25) clock (clk, clk_div);

    always@(posedge clk_div, posedge rst) begin
        if(rst) begin
            state <= S0;
            cnt <= 3'd0;
            count <= 5'd0;
            led <= ON;
        end else begin
            state <= next_state;
            cnt <= next_cnt;
            count <= next_count;
            led <= next_led;
        end
    end

    always@(*) begin
        next_state = state;
        next_led = led;
        next_cnt = cnt;
        next_count = count;
        case(state)
            S0 : begin
                if(cnt == 3'd6) begin
                    next_state = S1;
                    next_count = 5'd0;
                    next_led = SHIFT_INITIAL;
                end else begin
                    if(led == ON) begin
                        next_led = OFF;
                    end else begin
                        next_cnt = cnt + 3'd1;
                        next_led = ON;
                        if(cnt == 3'd0) next_cnt = 3'd1;
                        else if(cnt == 3'd1) next_cnt = 3'd2;
                        else if(cnt == 3'd2) next_cnt = 3'd3;
                        else if(cnt == 3'd3) next_cnt = 3'd4;
                        else if(cnt == 3'd4) next_cnt = 3'd5;
                        else if(cnt == 3'd5) next_cnt = 3'd6;
                        else next_cnt = 3'd0;
                    end
                end
            end
            S1 : begin
                if(led == OFF) begin
                    next_state = S2;
                    next_count = 5'd0;
                    next_led = EXPAND_INITIAL;
                end else begin
                    if(dir) begin
                        if(count <= 0) next_led = led << 1;
                        else next_led = {led[14:0], !led[0]};
                        next_count = count - 5'd1;
                    end else begin
                        if(count >= 0) next_led = led >> 1;
                        else next_led = {!led[15], led[15:1]};
                        next_count = count + 5'd1;
                    end
                end
            end
            S2 : begin
                if(led == ON) begin
                    next_state = S0;
                    next_cnt = 3'd0;
                    next_led = OFF;
                end else begin
                    if(dir) begin
                        if(led != OFF) begin
                            next_led = {1'b0 , led[15:9], led[6:0], 1'b0};
                        end
                    end else begin
                        next_led = {led[14:8], 2'b11, led[7:1]};
                    end
                end
            end
        endcase
        if(!en) begin
            next_state = state;
            next_count = count;
            next_cnt = cnt;
            next_led = led;
        end
    end

endmodule