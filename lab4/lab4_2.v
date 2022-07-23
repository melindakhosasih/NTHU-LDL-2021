`timescale 1ns / 1ps
module clock_ds (clk, clk_div);
    parameter n = 24;
    input clk;
    output clk_div;
    reg [n-1 : 0] num = 0;
    wire [n-1 : 0] next_num;
    reg flag = 0;
    always@(posedge clk) begin
        if(num == 25'd5000000) begin
            flag <= ~flag;
            num <= next_num;
        end else if(num == 25'd10000000) begin
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

module lab4_2 (clk, rst, en, input_number, enter, count_down, DIGIT, DISPLAY, led0);
    input clk, rst, en, input_number, enter, count_down;
    output reg [3:0] DIGIT;
    output reg [6:0] DISPLAY;
    output led0;
    reg [3:0] value, cnt_0, cnt_1, cnt_2, cnt_3, cnt_0_next, cnt_1_next, cnt_2_next, cnt_3_next;
    reg [1:0] state, next_state, pos = 2'b0, next_pos;
    reg dir, next_dir, cnt_down, counting = 1'b0, counting_next;
    reg [10:0] goal = 11'd0, goal_next, timer = 11'd0, timer_next;
    wire clock, clk_tes, cnt_down_db, cnt_down_op, enter_db, enter_op, enter_btn, num_sel_db, num_sel_op;

    clock_divider #(13) clock_div (.clk(clk), .clk_div(clock));
    clock_ds #(24) decisecond (.clk(clk), .clk_div(clk_ds));

    debounce countdown_db (.pb_debounced(cnt_down_db), .pb(count_down), .clk(clk));
    onepulse countdown_op (.pb_debounced(cnt_down_db), .clk(clk), .pb_1pulse(cnt_down_op));

    debounce enter_button_db (.pb_debounced(enter_db), .pb(enter), .clk(clk));
    onepulse enter_button_op (.pb_debounced(enter_db), .clk(clock), .pb_1pulse(enter_op));

    debounce input_num_db (.pb_debounced(num_sel_db), .pb(input_number), .clk(clk));
    onepulse input_num_op (.pb_debounced(num_sel_db), .clk(clk_ds), .pb_1pulse(num_sel_op));

    always @(posedge clk or posedge rst) begin
        if(rst) cnt_down <= 1'b0;
        else begin
            if(cnt_down_op) cnt_down <= !cnt_down;
        end
    end

    always @(posedge clk_ds, posedge rst) begin
        if(rst) begin
            cnt_0 <= 4'd10;
            cnt_1 <= 4'd10;
            cnt_2 <= 4'd10;
            cnt_3 <= 4'd10;
            timer <= 11'd0;
            goal <= 11'd0;
            counting <= 1'd0;
        end else begin
            cnt_0 <= cnt_0_next;
            cnt_1 <= cnt_1_next;
            cnt_2 <= cnt_2_next;
            cnt_3 <= cnt_3_next;
            timer <= timer_next;
            goal <= goal_next;
            counting <= counting_next;
        end
    end

    always @(*) begin
        cnt_0_next = cnt_0;
        cnt_1_next = cnt_1;
        cnt_2_next = cnt_2;
        cnt_3_next = cnt_3;
        goal_next = goal;
        timer_next = timer;
        counting_next = counting;
        if(state == 2'd1) begin
            if(cnt_0 == 4'd10) begin
                cnt_0_next = 4'd0;
                cnt_1_next = 4'd0;
                cnt_2_next = 4'd0;
                cnt_3_next = 4'd0;
            end else begin
                if(num_sel_op) begin
                    case (pos)
                        2'd0 : cnt_0_next = (cnt_0 == 4'd1) ? 4'd0 : (cnt_0 + 4'd1);
                        2'd1 : cnt_1_next = (cnt_1 == 4'd5) ? 4'd0 : (cnt_1 + 4'd1);
                        2'd2 : cnt_2_next = (cnt_2 == 4'd9) ? 4'd0 : (cnt_2 + 4'd1);
                        2'd3 : cnt_3_next = (cnt_3 == 4'd9) ? 4'd0 : (cnt_3 + 4'd1);
                    endcase    
                    counting_next = 1'd1;
                    goal_next = cnt_0_next * 600 + cnt_1_next * 100 + cnt_2_next * 10 + cnt_3_next;
                end
            end
        end else if(state == 2'd2) begin
            if(counting) begin
                counting_next = 1'd0;
                if(dir) begin
                    timer_next = goal;
                end else begin
                    cnt_0_next = 4'd0;
                    cnt_1_next = 4'd0;
                    cnt_2_next = 4'd0;
                    cnt_3_next = 4'd0;
                    timer_next = 11'd0;
                end
            end else begin
                if(en) begin
                    if(dir) begin //count down
                        if(timer > 11'd0) begin
                            cnt_0_next = timer / 600;
                            cnt_1_next = (timer % 600) / 100;
                            cnt_2_next = (timer % 100) / 10;
                            cnt_3_next = timer % 10;
                            timer_next = timer - 11'd1;
                        end else begin
                            cnt_0_next = timer / 600;
                            cnt_1_next = (timer % 600) / 100;
                            cnt_2_next = (timer % 100) / 10;
                            cnt_3_next = timer % 10;
                            timer_next = timer;
                        end
                    end else begin //count up
                        if(timer < goal) begin
                            cnt_0_next = timer / 600;
                            cnt_1_next = (timer % 600) / 100;
                            cnt_2_next = (timer % 100) / 10;
                            cnt_3_next = timer % 10;
                            timer_next = timer + 11'd1;
                        end else begin
                            cnt_0_next = timer / 600;
                            cnt_1_next = (timer % 600) / 100;
                            cnt_2_next = (timer % 100) / 10;
                            cnt_3_next = timer % 10;
                            timer_next = timer;
                        end
                    end
                end
            end
        end
    end

    always @(posedge clock, posedge rst) begin
        if(rst) begin
            state <= 2'd0;
            pos <= 2'd0;
            dir <= 1'd0;
        end else begin
            state <= next_state;
            pos <= next_pos;
            dir <= next_dir;
        end
    end

    always @(*) begin
        next_state = state;
        next_pos = pos;
        next_dir = dir;
        if(state == 2'd0) begin
            if(enter_op) begin
                next_state = 2'd1;
                next_pos = 2'd0;
                if(cnt_down) next_dir = 1'b1;
                else next_dir = 1'b0;
            end
        end else if(state == 2'd1) begin
            if(enter_op) begin
                if(pos == 2'd3) begin
                    next_state = 2'd2;
                    next_pos = 2'd0;
                end else begin
                    next_pos = pos + 2'd1;
                end
            end
        end
    end

    always @(posedge clock) begin
        case (DIGIT)
            4'b1110 : begin
                value = cnt_2;
                DIGIT = 4'b1101;
            end
            4'b1101 : begin
                value = cnt_1;
                DIGIT = 4'b1011;
            end
            4'b1011 : begin
                value = cnt_0;
                DIGIT = 4'b0111;
            end
            4'b0111 : begin
                value = cnt_3;
                DIGIT = 4'b1110;
            end
            default : begin
                value = cnt_3;
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
            4'd10 : DISPLAY = 7'b011_1111;
        endcase
    end

    assign led0 = (cnt_down) ? 1'b1 : 1'b0;

endmodule