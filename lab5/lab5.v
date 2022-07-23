module clock_divider (clk, clk_div);
    parameter n = 14;
    input clk;
    output reg clk_div;
    reg [n-1 : 0] num = 0;
    reg flag = 0;
    always@(posedge clk) begin
        if(num == 15'd5000) begin
            num <= num + 1;
            clk_div <= ~clk_div;
        end else if(num == 15'd10000) begin
            num <= 0;
            clk_div <= ~clk_div;
        end else num <= num + 1;
    end
endmodule

module lab5 (clk, rst, BTNL, BTNR, BTNU, BTND, BTNC, LED, DIGIT, DISPLAY);
    input clk, rst, BTNL, BTNR, BTNU, BTND, BTNC;
    output reg [15:0] LED;
    output reg [3:0] DIGIT;
    output reg [6:0] DISPLAY;
    reg [14:0] num = 0, next_num;
    reg [15:0] led_next;
    reg [5:0] price, money;
    reg [3:0] state, next_state, value, num1, num2, num3, num4, num1_next, num2_next, num3_next, num4_next, ticket, ticket_amount, cnt, num3_change, num4_change;
    reg flash = 0, enough_money = 0;
    wire ok_db, ok_op, cancel_db, cancel_op;
    wire clk_div;

    parameter IDLE = 3'd0;
    parameter TYPE = 3'd1;
    parameter AMOUNT = 3'd2;
    parameter PAYMENT = 3'd3;
    parameter RELEASE = 3'd4;
    parameter CHANGE = 3'd5;
    parameter ON = 16'b1111_1111_1111_1111;
    parameter A = 4'd11;
    parameter C = 4'd12;
    parameter S = 4'd13;
    
    clock_divider #(14) clock (clk, clk_div);

    debounce BTNU_debounce (ok_db, BTNU, clk);
    debounce BTND_debounce (cancel_db, BTND, clk);
    debounce BTNL_debounce (BTNL_db, BTNL, clk);
    debounce BTNC_debounce (BTNC_db, BTNC, clk);
    debounce BTNR_debounce (BTNR_db, BTNR, clk);

    onepulse BTNU_onepulse (ok_db, clk_div, ok_op);
    onepulse BTND_onepulse (cancel_db, clk_div, cancel_op);
    onepulse BTNL_onepulse (BTNL_db, clk_div, BTNL_op);
    onepulse BTNC_onepulse (BTNC_db, clk_div, BTNC_op);
    onepulse BTNR_onepulse (BTNR_db, clk_div, BTNR_op);

    always@(posedge clk_div, posedge rst) begin
        if(rst) begin
            num <= 15'd10000;
            flash <= 0;
        end else begin
            if(num == 15'd10000) begin
                num <= 0;
                flash <= 1;
            end else begin
                num <= next_num;
                flash <= 0;
            end
        end
    end

    always@(posedge clk_div, posedge rst) begin
        if(rst) LED <= ON;
        else begin
            if(flash && (state == IDLE || state == RELEASE)) begin
                if(LED == ON) LED <= ~ON;
                else LED <= ON;
            end else if(state != IDLE && state != RELEASE) begin
                LED <= ~ON;
            end
        end
    end

    always@(posedge clk_div, posedge rst) begin
        if(rst) begin
            ticket <= 4'd0;
            ticket_amount <= 4'd0;
            cnt <= 4'd0;
            enough_money <= 1'b0;
            num3_change <= 4'd0;
            num4_change <= 4'd0;
        end else begin
            if(state == AMOUNT) begin
                ticket <= num1;
                ticket_amount <= num4;
                enough_money <= 1'b0;
            end else if (state == PAYMENT) begin
                if((num1 > num3) || (num1 == num3 && num2 >= num4)) begin
                    enough_money <= 1'b1;
                    if(num2 < num4) begin
                        num3_change <= (num1 - 4'd1) - num3;
                        num4_change <= (4'd10 + num2) - num4;
                    end else begin
                        num3_change <= num1 - num3;
                        num4_change <= num2 - num4;
                    end
                end else begin
                    enough_money <= 1'b0;
                    num3_change = num1;
                    num4_change = num2;
                    cnt <= 4'd0;
                end
            end else if(flash && state == RELEASE) begin
                cnt <= cnt + 4'd1;
            end
        end
    end

    always@(posedge clk_div, posedge rst) begin
        if(rst) begin
            num1 <= 4'd10;
            num2 <= 4'd10;
            num3 <= 4'd10;
            num4 <= 4'd10;
        end else begin
            if(flash && (state == IDLE)) begin
                if(LED == ON) begin
                    num1 <= 4'd15;
                    num2 <= 4'd15;
                    num3 <= 4'd15;
                    num4 <= 4'd15;
                end else begin
                    num1 <= 4'd10;
                    num2 <= 4'd10;
                    num3 <= 4'd10;
                    num4 <= 4'd10;
                end
            end else if(state == CHANGE) begin 
                if(flash) begin
                    num1 <= num1_next;
                    num2 <= num2_next;
                    num3 <= num3_next;
                    num4 <= num4_next;
                end
            end else begin
                num1 <= num1_next;
                num2 <= num2_next;
                num3 <= num3_next;
                num4 <= num4_next;
            end
        end
    end

    always@(*) begin
        next_state = state;
        next_num = num + 1;
        num1_next = num1;
        num2_next = num2;
        num3_next = num3;
        num4_next = num4;
        case (state)
            IDLE : begin
                if(BTNL_op) begin //child
                    next_state = TYPE;
                    num1_next = C;
                    num2_next = 4'd15;
                    num3_next = 4'd0;
                    num4_next = 4'd5;
                end else if(BTNC_op) begin //student
                    next_state = TYPE;
                    num1_next = S;
                    num2_next = 4'd15;
                    num3_next = 4'd1;
                    num4_next = 4'd0;
                end else if(BTNR_op) begin //adult
                    next_state = TYPE;
                    num1_next = A;
                    num2_next = 4'd15;
                    num3_next = 4'd1;
                    num4_next = 4'd5;
                end
            end
            TYPE : begin
                num2_next = 4'd15;
                if(BTNL_op) begin //child
                    num1_next = C;
                    num3_next = 4'd0;
                    num4_next = 4'd5;
                end else if(BTNC_op) begin //student
                    num1_next = S;
                    num3_next = 4'd1;
                    num4_next = 4'd0;
                end else if(BTNR_op) begin //adult
                    num1_next = A;
                    num3_next = 4'd1;
                    num4_next = 4'd5;
                end else if(ok_op) begin
                    next_state = AMOUNT;
                    num3_next = 4'd15;
                    num4_next = 4'd1;
                end else if(cancel_op) begin
                    next_state = IDLE;
                    next_num = 15'd10000;
                end
            end
            AMOUNT : begin
                num2_next = 4'd15;
                num3_next = 4'd15;
                if(BTNL_op) begin //decrease
                    case (num4)
                        4'd2 : num4_next = 4'd1;
                        4'd3 : num4_next = 4'd2;
                    endcase
                end else if(BTNR_op) begin //increase
                    case (num4)
                        4'd1 : num4_next = 4'd2;
                        4'd2 : num4_next = 4'd3;
                    endcase
                end else if (ok_op) begin
                    next_state = PAYMENT;
                    num1_next = 4'd0;
                    num2_next = 4'd0;
                    case (num1)
                        A : begin
                            case (num4)
                                4'd1 : begin
                                    num3_next = 4'd1;
                                    num4_next = 4'd5;
                                end
                                4'd2 : begin
                                    num3_next = 4'd3;
                                    num4_next = 4'd0;
                                end
                                4'd3 : begin
                                    num3_next = 4'd4;
                                    num4_next = 4'd5;
                                end
                            endcase
                        end
                        C : begin
                            case (num4)
                                4'd1 : begin
                                    num3_next = 4'd0;
                                    num4_next = 4'd5;
                                end
                                4'd2 : begin
                                    num3_next = 4'd1;
                                    num4_next = 4'd0;
                                end
                                4'd3 : begin
                                    num3_next = 4'd1;
                                    num4_next = 4'd5;
                                end
                            endcase
                        end
                        S : begin
                            case (num4)
                                4'd1 : begin
                                    num3_next = 4'd1;
                                    num4_next = 4'd0;
                                end
                                4'd2 : begin
                                    num3_next = 4'd2;
                                    num4_next = 4'd0;
                                end
                                4'd3 : begin
                                    num3_next = 4'd3;
                                    num4_next = 4'd0;
                                end
                            endcase
                        end
                    endcase
                end else if(cancel_op) begin
                    next_state = IDLE;
                    next_num = 15'd10000;
                end
            end
            PAYMENT : begin
                if(enough_money) begin
                    next_state = RELEASE;
                    num1_next = ticket;
                    num2_next = 4'd15;
                    num3_next = 4'd15;
                    num4_next = ticket_amount;
                    next_num = 15'd10000;
                end else if(cancel_op) begin
                    next_state = CHANGE;
                    num1_next = 4'd15;
                    num2_next = 4'd15;
                    num3_next = num3_change;
                    num4_next = num4_change;
                end else if(BTNL_op) begin //$1
                    if(num2 != 4'd9) num2_next = num2 + 4'd1;
                    else if(num1 != 4'd9 && num2 == 4'd9) begin
                        num1_next = num1 + 4'd1;
                        num2_next = 4'd0;
                    end
                end else if(BTNC_op) begin //$5
                    if(num2 < 4'd5) num2_next = num2 + 4'd5;
                    else if(num1 != 4'd9 && num2 >= 4'd5) begin
                        num1_next = num1 + 4'd1;
                        num2_next = num2 - 4'd5;
                    end
                end else if(BTNR_op) begin //$10
                    if(num1 != 4'd9) num1_next = num1 + 4'd1;
                end
            end
            RELEASE : begin
                num2_next = 4'd15;
                num3_next = 4'd15;
                if(cnt == 4'd6) begin
                    next_state = CHANGE;
                    num1_next = 4'd15;
                    num2_next = 4'd15;
                    num3_next = num3_change;
                    num4_next = num4_change;
                end
            end
            CHANGE : begin
                num1_next = 4'd15;
                num2_next = 4'd15;
                if(num3 == 4'd0 && num4 == 4'd0) begin
                    next_state = IDLE;
                    next_num = 15'd0;
                end else begin
                    if(num3 != 4'd0) num3_next = num3 - 4'd1;
                    else begin
                        if(num4 >= 4'd5) num4_next = num4 - 4'd5;
                        else if(num4 != 4'd0) num4_next = num4 - 4'd1;
                    end
                end
            end
        endcase
    end

    always@(posedge clk_div, posedge rst) begin
        if(rst) state <= IDLE;
        else state <= next_state;
    end
    
    always @ (posedge clk_div) begin
    	case (DIGIT)
    		4'b1110 : begin
    			value <= num3;
    			DIGIT <= 4'b1101;
    		end
    		4'b1101 : begin
				value <= num2;
				DIGIT <= 4'b1011;
			end
    		4'b1011 : begin
				value <= num1;
				DIGIT <= 4'b0111;
			end
    		4'b0111 : begin
				value <= num4;
				DIGIT <= 4'b1110;
			end
    		default : begin
				value <= num4;
				DIGIT <= 4'b1110;
			end				
    	endcase
    end
    
    always @ (*) begin
    	case (value)
    		0 : DISPLAY = 7'b1000000;	//0000
			1 : DISPLAY = 7'b1111001;   //0001                                                
			2 : DISPLAY = 7'b0100100;   //0010                                                
			3 : DISPLAY = 7'b0110000;   //0011                                             
			4 : DISPLAY = 7'b0011001;   //0100                                               
			5 : DISPLAY = 7'b0010010;   //0101                                               
			6 : DISPLAY = 7'b0000010;   //0110
			7 : DISPLAY = 7'b1111000;   //0111
			8 : DISPLAY = 7'b0000000;   //1000
			9 : DISPLAY = 7'b0010000;	//1001
			10: DISPLAY = 7'b0111111;   //-
			11: DISPLAY = 7'b0001000;   //A
            12: DISPLAY = 7'b1000110;	//C
            13: DISPLAY = 7'b0010010;   //S
			default : DISPLAY = 7'b1111111;
    	endcase
    end

endmodule