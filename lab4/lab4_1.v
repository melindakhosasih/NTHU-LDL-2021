`timescale 1ns / 1ps
module clock_divider_2s (clk, clk_div);
    parameter n = 27;
    input clk;
    output clk_div;
    reg [n-1 : 0] num = 0;
    wire [n-1 : 0] next_num;
    reg flag = 0;
    always@(posedge clk) begin
        if(num == 28'd100000000) begin
            flag <= ~flag;
            num <= next_num;
        end else if(num == 28'd200000000) begin
            flag <= ~flag;
            num <= 0;
        end else begin
            flag <= flag;
            num <= next_num;
        end
    end
    assign next_num = num + 1;
    assign clk_div = flag;
endmodule

module clock_divider_1s (clk, clk_div);
    parameter n = 26;
    input clk;
    output clk_div;
    reg [n-1 : 0] num = 0;
    wire [n-1 : 0] next_num;
    reg flag = 0;
    always@(posedge clk) begin
        if(num == 27'd50000000) begin
            flag <= ~flag;
            num <= next_num;
        end else if(num == 27'd100000000) begin
            flag <= ~flag;
            num <= 0;
        end else begin
            flag <= flag;
            num <= next_num;
        end
    end
    assign next_num = num + 1;
    assign clk_div = flag;
endmodule

module clock_divider_half (clk, clk_div);
    parameter n = 26;
    input clk;
    output clk_div;
    reg [n-1 : 0] num = 0;
    wire [n-1 : 0] next_num;
    reg flag = 0;
    always@(posedge clk) begin
        if(num == 27'd25000000) begin
            flag <= ~flag;
            num <= next_num;
        end else if(num == 27'd50000000) begin
            flag <= ~flag;
            num <= 0;
        end else begin
            flag <= flag;
            num <= next_num;
        end
    end
    assign next_num = num + 1;
    assign clk_div = flag;
endmodule

module clock_divider (clk, clk_div);
    parameter n = 25;
    input clk;
    output clk_div;
    reg [n-1 : 0] num = 0;
    wire [n-1 : 0] next_num;
    always@(posedge clk) begin
        num <= next_num;
    end
    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule

module lab4_1 (clk, rst, en, dir, speed_up, speed_down, DIGIT, DISPLAY, max, min);
input clk, rst, en, dir, speed_up, speed_down;
output reg [3:0] DIGIT;
output reg [6:0] DISPLAY;
output max, min;
wire cnt_down, enable, pause, fast, faster, slow, slower;
reg [3:0] value, cnt_1 = 4'd0, cnt_1_next, cnt_2 = 4'd0, cnt_2_next;
reg [1:0] speed = 2'd0, speed_next;
wire clk0, clk1, clk2, clock;
reg clk_div, start = 1'b0;

clock_divider_2s #(28) speed0 (.clk(clk), .clk_div(clk0));
clock_divider_1s #(27) speed1 (.clk(clk), .clk_div(clk1));
clock_divider_half #(26) speed2 (.clk(clk), .clk_div(clk2));
clock_divider #(13) clock_div (.clk(clk), .clk_div(clock));

debounce direction (.pb_debounced(cnt_down), .pb(dir), .clk(clk));

debounce enable_debounced (.pb_debounced(enable), .pb(en), .clk(clk));
onepulse enable_one_pulse (.pb_debounced(enable), .clk(clk), .pb_1pulse(pause));

debounce faster_debounce (.pb_debounced(fast), .pb(speed_up), .clk(clk));
onepulse faster_one_pulse (.pb_debounced(fast), .clk(clk), .pb_1pulse(faster));

debounce slower_debounce (.pb_debounced(slow), .pb(speed_down), .clk(clk));
onepulse slower_one_pulse (.pb_debounced(slow), .clk(clk), .pb_1pulse(slower));

always @(posedge clk, posedge rst) begin
    if(rst) start <= 1'b0;
    else begin
        if(pause) start <= !start;
    end
end

always @(posedge clk, posedge rst) begin
    if(rst) speed <= 2'd0;
    else begin
        speed <= speed_next;
    end
end

always @* begin
    speed_next = speed;
    if(faster) begin
        case (speed)
            2'd0 : speed_next = 2'd1;
            2'd1 : speed_next = 2'd2;
        endcase
    end
    if(slower) begin
        case (speed)
            2'd1 : speed_next = 2'd0;
            2'd2 : speed_next = 2'd1; 
        endcase
    end
end

always @* begin
    clk_div = clk0;
    case (speed)
        2'd0 : clk_div = clk0;
        2'd1 : clk_div = clk1;
        2'd2 : clk_div = clk2;
    endcase
end

always @(posedge clk_div, posedge rst) begin
    if(rst) begin
        cnt_1 <= 4'd0;
        cnt_2 <= 4'd0;
    end else begin
        if(start) begin
            cnt_1 <= cnt_1_next;
            cnt_2 <= cnt_2_next;
        end else begin
            cnt_1 <= cnt_1;
            cnt_2 <= cnt_2;
        end
    end
end

always @(*) begin
    cnt_1_next = cnt_1;
    cnt_2_next = cnt_2;
    if(!cnt_down) begin //count up
        if(cnt_1 != 4'd9) cnt_1_next = cnt_1 + 4'd1;
        else begin
            if(cnt_2 != 4'd9) begin
                cnt_1_next = 4'd0;
                cnt_2_next = cnt_2 + 4'd1;
            end
        end
    end else begin //count down
        if(cnt_1 != 4'd0) cnt_1_next = cnt_1 - 4'd1;
        else begin
            if(cnt_2 != 4'd0) begin
                cnt_1_next = 4'd9;
                cnt_2_next = cnt_2 - 4'd1;
            end
        end
    end
end

always@(posedge clock) begin
    case (DIGIT)
        4'b1110 : begin
            value = cnt_2;
            DIGIT = 4'b1101;
        end
        4'b1101 : begin
            value = (cnt_down == 1'b1) ? 4'd11 : 4'd10;
            DIGIT = 4'b1011;
        end
        4'b1011 : begin
            value = {2'b00, speed};
            DIGIT = 4'b0111;
        end
        4'b0111 : begin
            value = cnt_1;
            DIGIT = 4'b1110;
        end
        default : begin
            value = cnt_1;
            DIGIT = 4'b1110;
        end
    endcase
end

always@* begin
    DISPLAY = 7'b111_1111;
    case (value)
        4'd0 : DISPLAY = 7'b100_0000;
        4'd1 : DISPLAY = 7'b111_1001;
        4'd2 : DISPLAY = 7'b010_0100;
        4'd3 : DISPLAY = 7'b011_0000;
        4'd4 : DISPLAY = 7'b001_1001;
        4'd5 : DISPLAY = 7'b001_0010;
        4'd6 : DISPLAY = 7'b000_0010;
        4'd7 : DISPLAY = 7'b111_1000;
        4'd8 : DISPLAY = 7'b000_0000;
        4'd9 : DISPLAY = 7'b001_0000;
        4'd10 : DISPLAY = 7'b101_1100; //up
        4'd11 : DISPLAY = 7'b110_0011; //down
    endcase
end

assign max = (cnt_1 == 4'd9 && cnt_2 == 4'd9) ? 1'b1 : 1'b0;
assign min = (cnt_1 == 4'd0 && cnt_2 == 4'd0) ? 1'b1 : 1'b0;

endmodule