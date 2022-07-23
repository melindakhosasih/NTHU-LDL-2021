// 109000168 ?\?í?

// e.g. 109012345 ???j??
// Add your ID and name to FIRST line of file, or you will get 5 points penalty


module exam1_C(
    input wire clk, // 100Mhz clock
    input wire rst_btn,
    input wire start_btn,
    input wire [15:0] sw,
    output wire [3:0] DIGIT,
    output wire [6:0] DISPLAY,
    output wire [15:0] led // You can modify "wire" of output ports to "reg" if needed
);
    //Your design here
	wire clk25, clk13, clk15, start_db, start_op;
	clock_divider #(25) clk1 (clk, clk25);
	clock_divider #(13) clk2 (clk, clk13);
	clock_divider #(15) clk3 (clk, clk15);
	debounce startdb (start_db, start_btn, clk);
	onepulse startop (start_db, clk, start_op);

	reg [15:0] led1, led2, led1_next, led2_next;
	reg start = 0, dir1, dir2, dir1_next, dir2_next;
	reg [3:0] pos1, pos2, pos1_next, pos2_next;

	always@(posedge rst_btn, posedge start_op) begin
		if(rst_btn) start <= 0;
		else start <= ~start;
	end 

	always@(posedge rst_btn, posedge clk25) begin
		if(rst_btn) begin
			led1 <= 16'b0000_0000_0000_0010;
			dir1 <= 1'b0; //left
			pos1 <= 4'd1;
		end else begin
			led1 <= led1_next;
			dir1 <= dir1_next;
			pos1 <= pos1_next;
		end
	end

	always@(posedge rst_btn, posedge clk25) begin
		if(rst_btn) begin
			led2 <= 16'b0000_0100_0000_0000;
			dir2 <= 1'b1; //right
			pos2 <= 4'd10;
		end else begin
			led2 <= led2_next;
			dir2 <= dir2_next;
			pos2 <= pos2_next;
		end
	end

	always@(*) begin
		if(start) begin
			dir1_next = dir1;
			dir2_next = dir2;
			led1_next = led1;
			led2_next = led2;
			pos1_next = pos1;
			pos2_next = pos2;
			if((dir2 && pos2 > pos1 && pos2 - pos1 == 4'd1) ||
				(dir2 && pos2 == 4'd0 && pos1 == 4'd15)) begin
				dir1_next = !dir1;
				dir2_next = !dir2;
				led1_next[15] = led1[0]; // to right
				led1_next[14:0] = led1[15:1];
				led2_next[0] = led2[15];
				led2_next[15:1] = led2[14:0]; // to left
				pos1_next = (pos1 == 4'd0) ? 4'd15 : (pos1 - 4'd1); // to right
				pos2_next = (pos2 == 4'd15) ? 4'd0 : (pos2 + 4'd1); // to left
			end else if ((dir1 && pos1 > pos2 && pos1 - pos2 == 4'd1) ||
				(dir1 && pos1 == 4'd0 && pos2 == 4'd15)) begin
				dir1_next = !dir1;
				dir2_next = !dir2;
				led1_next[0] = led1[15];
				led1_next[15:1] = led1[14:0]; // to left
				led2_next[15] = led2[0];
				led2_next[14:0] = led2[15:1]; // to right
				pos1_next = (pos1 == 4'd15) ? 4'd0 : (pos1 + 4'd1); // to left
				pos2_next = (pos2 == 4'd0) ? 4'd15 : (pos2 - 4'd1); // to right
			end else if (dir1) begin
				led1_next[15] = led1[0]; // to right
				led1_next[14:0] = led1[15:1];
				led2_next[0] = led2[15];
				led2_next[15:1] = led2[14:0]; // to left
				pos1_next = (pos1 == 4'd0) ? 4'd15 : (pos1 - 4'd1); // to right
				pos2_next = (pos2 == 4'd15) ? 4'd0 : (pos2 + 4'd1); // to left
			end else if(dir2) begin
				led1_next[0] = led1[15];
				led1_next[15:1] = led1[14:0]; // to left
				led2_next[15] = led2[0];
				led2_next[14:0] = led2[15:1]; // to right
				pos1_next = (pos1 == 4'd15) ? 4'd0 : (pos1 + 4'd1); // to left
				pos2_next = (pos2 == 4'd0) ? 4'd15 : (pos2 - 4'd1); // to right
			end
		end else begin
			dir1_next = dir1;
			dir2_next = dir2;
			led1_next = led1;
			led2_next = led2;
			pos1_next = pos1;
			pos2_next = pos2;
		end
	end

	assign led = led1 | led2;

endmodule

// You can modify below modules I/O or content if needed.
// Also you can add any module you need.
// Make sure you include all modules you used in this file.

module onepulse(pb_debounced, clk, pb_1pulse);	
	input pb_debounced;	
	input clk;	
	output pb_1pulse;	

	reg pb_1pulse;	
	reg pb_debounced_delay;	

	always@(posedge clk) begin
		pb_1pulse <= pb_debounced & (! pb_debounced_delay);
		pb_debounced_delay <= pb_debounced;
	end	
endmodule

module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit, 
	input wire [15:0] nums, // four 4-bits BCD number
	input wire rst,
	input wire clk  // Input 100Mhz clock
);
    
    reg [15:0] clk_divider;
    reg [3:0] display_num;
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		clk_divider <= 15'b0;
    	end else begin
    		clk_divider <= clk_divider + 15'b1;
    	end
    end
    
    always @ (posedge clk_divider[15], posedge rst) begin
    	if (rst) begin
    		display_num <= 4'b0000;
    		digit <= 4'b1111;
    	end else begin
    		case (digit)
    			4'b1110 : begin
    					display_num <= nums[7:4];
    					digit <= 4'b1101;
    				end
    			4'b1101 : begin
						display_num <= nums[11:8];
						digit <= 4'b1011;
					end
    			4'b1011 : begin
						display_num <= nums[15:12];
						digit <= 4'b0111;
					end
    			4'b0111 : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end
    			default : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end				
    		endcase
    	end
    end
    
    always @ (*) begin
    	case (display_num)
    		0 : display = 7'b1000000;	//0000
			1 : display = 7'b1111001;   //0001                                                
			2 : display = 7'b0100100;   //0010                                                
			3 : display = 7'b0110000;   //0011                                             
			4 : display = 7'b0011001;   //0100                                               
			5 : display = 7'b0010010;   //0101                                               
			6 : display = 7'b0000010;   //0110
			7 : display = 7'b1111000;   //0111
			8 : display = 7'b0000000;   //1000
			9 : display = 7'b0010000;	//1001
			10: display = 7'b0010010;	//S
			11: display = 7'b0001100;	//P
			12: display = 7'b0001000;	//R
			default : display = 7'b1111111;
    	endcase
    end
    
endmodule

module clock_divider(clk, clk_div);   
    parameter n = 26;     
    input clk;   
    output clk_div;   
    
    reg [n-1:0] num;
    wire [n-1:0] next_num;
    
    always@(posedge clk)begin
    	num <= next_num;
    end
    
    assign next_num = num +1;
    assign clk_div = num[n-1];
    
endmodule

module debounce (pb_debounced, pb, clk); 
	output pb_debounced;
	input pb;
	input clk; 
	reg [3:0] DFF;
	always @(posedge clk) begin 
		DFF[3:1] <= DFF[2:0]; 
		DFF[0] <= pb; 
	end
	assign pb_debounced = ((DFF == 4'b1111) ? 1'b1 : 1'b0);

endmodule