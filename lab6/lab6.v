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

	module KeyboardDecoder(
		output reg [511:0] key_down,
		output wire [8:0] last_change,
		output reg key_valid,
		inout wire PS2_DATA,
		inout wire PS2_CLK,
		input wire rst,
		input wire clk
		);
		
		parameter [1:0] INIT			= 2'b00;
		parameter [1:0] WAIT_FOR_SIGNAL = 2'b01;
		parameter [1:0] GET_SIGNAL_DOWN = 2'b10;
		parameter [1:0] WAIT_RELEASE    = 2'b11;
		
		parameter [7:0] IS_INIT			= 8'hAA;
		parameter [7:0] IS_EXTEND		= 8'hE0;
		parameter [7:0] IS_BREAK		= 8'hF0;
		
		reg [9:0] key;		// key = {been_extend, been_break, key_in}
		reg [1:0] state;
		reg been_ready, been_extend, been_break;
		
		wire [7:0] key_in;
		wire is_extend;
		wire is_break;
		wire valid;
		wire err;
		
		wire [511:0] key_decode = 1 << last_change;
		assign last_change = {key[9], key[7:0]};
		
		KeyboardCtrl_0 inst (
			.key_in(key_in),
			.is_extend(is_extend),
			.is_break(is_break),
			.valid(valid),
			.err(err),
			.PS2_DATA(PS2_DATA),
			.PS2_CLK(PS2_CLK),
			.rst(rst),
			.clk(clk)
		);
		
		OnePulse op (
			.signal_single_pulse(pulse_been_ready),
			.signal(been_ready),
			.clock(clk)
		);
		
		always @ (posedge clk, posedge rst) begin
			if (rst) begin
				state <= INIT;
				been_ready  <= 1'b0;
				been_extend <= 1'b0;
				been_break  <= 1'b0;
				key <= 10'b0_0_0000_0000;
			end else begin
				state <= state;
				been_ready  <= been_ready;
				been_extend <= (is_extend) ? 1'b1 : been_extend;
				been_break  <= (is_break ) ? 1'b1 : been_break;
				key <= key;
				case (state)
					INIT : begin
							if (key_in == IS_INIT) begin
								state <= WAIT_FOR_SIGNAL;
								been_ready  <= 1'b0;
								been_extend <= 1'b0;
								been_break  <= 1'b0;
								key <= 10'b0_0_0000_0000;
							end else begin
								state <= INIT;
							end
						end
					WAIT_FOR_SIGNAL : begin
							if (valid == 0) begin
								state <= WAIT_FOR_SIGNAL;
								been_ready <= 1'b0;
							end else begin
								state <= GET_SIGNAL_DOWN;
							end
						end
					GET_SIGNAL_DOWN : begin
							state <= WAIT_RELEASE;
							key <= {been_extend, been_break, key_in};
							been_ready  <= 1'b1;
						end
					WAIT_RELEASE : begin
							if (valid == 1) begin
								state <= WAIT_RELEASE;
							end else begin
								state <= WAIT_FOR_SIGNAL;
								been_extend <= 1'b0;
								been_break  <= 1'b0;
							end
						end
					default : begin
							state <= INIT;
							been_ready  <= 1'b0;
							been_extend <= 1'b0;
							been_break  <= 1'b0;
							key <= 10'b0_0_0000_0000;
						end
				endcase
			end
		end
		
		always @ (posedge clk, posedge rst) begin
			if (rst) begin
				key_valid <= 1'b0;
				key_down <= 511'b0;
			end else if (key_decode[last_change] && pulse_been_ready) begin
				key_valid <= 1'b1;
				if (key[8] == 0) begin
					key_down <= key_down | key_decode;
				end else begin
					key_down <= key_down & (~key_decode);
				end
			end else begin
				key_valid <= 1'b0;
				key_down <= key_down;
			end
		end

	endmodule

	module SevenSegment(
		output reg [6:0] display,
		output reg [3:0] digit,
		input wire [15:0] nums,
		input wire rst,
		input wire clk
		);
		
		reg [9:0] clk_divider;
		reg [3:0] display_num;
		
		always @ (posedge clk) begin
			clk_divider <= clk_divider + 10'b1;
		end
		
		always @ (posedge clk_divider[9]) begin
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
				default : display = 7'b1111111;
			endcase
		end
		
	endmodule

	module lab06 (clk, rst, PS2_CLK, PS2_DATA, DIGIT, DISPLAY, LED);
		input clk, rst;
		inout PS2_CLK, PS2_DATA;
		output [3:0] DIGIT;
		output [6:0] DISPLAY;
		output [15:0] LED;

		wire [511:0] key_down;
		wire [8:0] last_change;
		wire clk_10, clk_26, been_ready;

		reg [15:0] BCD, BCD_next;
		reg [6:0] busway, busway_next;
		reg [3:0] key_num;
		reg [1:0] B1, B2, passenger, B1_next, B2_next, passenger_next, state, next_state;
		reg dir = 0, dir_next, go = 0, go_next, clear = 0, clear_next, pay = 0, pay_next;

		// parameter [8:0] KEY_CODES_1 = 9'b0_0001_0110;
		// parameter [8:0] KEY_CODES_2 = 9'b0_0001_1110;
		parameter [8:0] KEY_CODES [0:19] = {
			9'b0_0100_0101,	// 0 => 45
			9'b0_0001_0110,	// 1 => 16
			9'b0_0001_1110,	// 2 => 1E
			9'b0_0010_0110,	// 3 => 26
			9'b0_0010_0101,	// 4 => 25
			9'b0_0010_1110,	// 5 => 2E
			9'b0_0011_0110,	// 6 => 36
			9'b0_0011_1101,	// 7 => 3D
			9'b0_0011_1110,	// 8 => 3E
			9'b0_0100_0110,	// 9 => 46
			
			9'b0_0111_0000, // right_0 => 70
			9'b0_0110_1001, // right_1 => 69
			9'b0_0111_0010, // right_2 => 72
			9'b0_0111_1010, // right_3 => 7A
			9'b0_0110_1011, // right_4 => 6B
			9'b0_0111_0011, // right_5 => 73
			9'b0_0111_0100, // right_6 => 74
			9'b0_0110_1100, // right_7 => 6C
			9'b0_0111_0101, // right_8 => 75
			9'b0_0111_1101  // right_9 => 7D
		};
		parameter [6:0] LED0 = 7'b0000_001;
		parameter [6:0] LED1 = 7'b0000_010;
		parameter [6:0] LED2 = 7'b0000_100;
		parameter [6:0] LED3 = 7'b0001_000;
		parameter [6:0] LED4 = 7'b0010_000;
		parameter [6:0] LED5 = 7'b0100_000;
		parameter [6:0] LED6 = 7'b1000_000;
		parameter [1:0] G1 = 2'b00;
		parameter [1:0] G2 = 2'b01;
		parameter [1:0] G3 = 2'b10;
		parameter [1:0] Yellow = 2'b11;

		clock_divider #(10) clock_div10 (clk, clk_10);
		clock_divider #(26) clock_div26 (clk, clk_26);
		
		SevenSegment seven_seg (.display(DISPLAY), .digit(DIGIT), .nums(BCD), .rst(rst), .clk(clk));
		KeyboardDecoder key_de (.key_down(key_down), .last_change(last_change), .key_valid(been_ready), .PS2_DATA(PS2_DATA), .PS2_CLK(PS2_CLK), .rst(rst), .clk(clk));

		always@(posedge clk_26 or posedge rst) begin
			if(rst) begin
				state <= G1;
				dir <= 0;
				busway <= 7'b0000_001;
				passenger <= 2'b00;
			end else begin
				state <= next_state;
				dir <= dir_next;
				busway <= busway_next;
				passenger <= passenger_next;
			end
		end

		always@(*) begin
			next_state = state;
			dir_next = dir;
			busway_next = busway;
			case (state)
				G1 : begin
					if(go) begin
						next_state = Yellow;
						busway_next = LED1;
					end
				end
				G2 : if(go) next_state = Yellow;
				G3 : begin
					if(go) begin
						next_state = Yellow;
						busway_next = LED5;
					end
				end
				Yellow : begin
					if(dir) begin
						busway_next = busway >> 1;
						if(busway == LED1) begin
							next_state = G1;
							dir_next = 1'b0;
						end else if(busway == LED4 && passenger != 2'b00) next_state = G2;
					end else begin
						busway_next = busway << 1;
						if(busway == LED2 && passenger != 2'b00) next_state = G2;
						else if(busway == LED6) begin
							busway_next = LED6;
							next_state = G3;
							dir_next = 1'b1;
						end
					end
				end
			endcase
		end

		always@(posedge clk_26 or posedge rst) begin
			if(rst) begin
				BCD <= 16'b0000_0000_0000_0000;
				go <= 1'b0;
				clear <= 1'b0;
				pay <= 1'b0;
			end else begin 
				BCD <= BCD_next;
				go <= go_next;
				clear <= clear_next;
				pay <= pay_next;
			end
		end

		always@(posedge clk or posedge rst) begin
			if(rst) begin
				B1 <= 2'b00;
				B2 <= 2'b00;
			end else if (been_ready && key_down[last_change] == 1'b1) begin
				if (key_num != 4'b1111) begin
					if(key_num == 4'b0001) begin
						B2 <= B2_next;
						if(B1 == 2'b00) B1 <= 2'b10;
						else if(B1 == 2'b10) B1 <= 2'b11;
						else B1 <= B1_next;
					end else if(key_num == 4'b0010) begin
						B1 <= B1_next;
						if(B2 == 2'b00) B2 <= 2'b10;
						else if(B2 == 2'b10) B2 <= 2'b11;
						else B2 <= B2_next;
					end else begin
						B1 <= B1_next;
						B2 <= B2_next;
					end
				end else begin
					B1 <= B1_next;
					B2 <= B2_next;
				end
			end else begin 
				B1 <= B1_next;
				B2 <= B2_next;
			end
		end

		always @ (*) begin
			case (last_change)
				KEY_CODES[00] : key_num = 4'b0000;
				KEY_CODES[01] : key_num = 4'b0001;
				KEY_CODES[02] : key_num = 4'b0010;
				KEY_CODES[03] : key_num = 4'b0011;
				KEY_CODES[04] : key_num = 4'b0100;
				KEY_CODES[05] : key_num = 4'b0101;
				KEY_CODES[06] : key_num = 4'b0110;
				KEY_CODES[07] : key_num = 4'b0111;
				KEY_CODES[08] : key_num = 4'b1000;
				KEY_CODES[09] : key_num = 4'b1001;
				KEY_CODES[10] : key_num = 4'b0000;
				KEY_CODES[11] : key_num = 4'b0001;
				KEY_CODES[12] : key_num = 4'b0010;
				KEY_CODES[13] : key_num = 4'b0011;
				KEY_CODES[14] : key_num = 4'b0100;
				KEY_CODES[15] : key_num = 4'b0101;
				KEY_CODES[16] : key_num = 4'b0110;
				KEY_CODES[17] : key_num = 4'b0111;
				KEY_CODES[18] : key_num = 4'b1000;
				KEY_CODES[19] : key_num = 4'b1001;
				default		  : key_num = 4'b1111;
			endcase
		end

		always@(*) begin
			passenger_next = passenger;
			B1_next = B1;
			B2_next = B2;
			BCD_next = BCD;
			go_next = go;
			clear_next = clear;
			pay_next = pay;
			case(state)
				G1 : begin
					if(!go) begin
						if(!clear) begin
							if(passenger == 2'b11) passenger_next = 2'b10;
							else if(passenger == 2'b10) passenger_next = 2'b00;
							else if(passenger == 2'b00) clear_next = 1'b1;
						end else begin
							if(!pay) begin
								if(B1 == 2'b11) begin
									passenger_next = B1;
									pay_next = 1'b1;
									if(BCD[7:4] > 4'd2) begin
										BCD_next[7:4] = 4'd9;
										BCD_next[3:0] = 4'd0;
									end else BCD_next[7:4] = BCD[7:4] + 4'd6;
								end else if (B1 == 2'b10) begin
									passenger_next = B1;
									pay_next = 1'b1;
									if(BCD[7:4] > 4'd5) begin
										BCD_next[7:4] = 4'd9;
										BCD_next[3:0] = 4'd0;
									end else BCD_next[7:4] = BCD[7:4] + 4'd3;
								 end else if (B2 != 2'b00) begin
								 	go_next = 1'b1;
								 end
							end else begin
								B1_next = 2'b00;
								if((BCD[15:12] == 4'd2) || (BCD[15:12] == 4'd1 && BCD[7:4] == 4'd0)) go_next = 1'b1;
								else if(BCD[7:4] != 4'd0) begin
									if(BCD[15:12] == 4'd1 && BCD[11:8] == 4'd5) begin
										BCD_next[15:12] = 4'd2;
										BCD_next[11:8] = 4'd0;
										BCD_next[7:4] = BCD[7:4] - 4'd1;
									end else begin
										BCD_next[15:12] = BCD[15:12] + 4'd1;
										BCD_next[7:4] = BCD[7:4] - 4'd1;
									end
								end
							end
						end
					end
				end
				G2 : begin
					if(!go) begin
						if((BCD[15:12] == 4'd2) || (BCD[15:12] == 4'd1 && BCD[7:4] == 4'd0)) go_next = 1'b1;
						else if(BCD[7:4] != 4'd0) begin
							if(BCD[15:12] == 4'd1 && BCD[11:8] == 4'd5) begin
								BCD_next[15:12] = 4'd2;
								BCD_next[11:8] = 4'd0;
								BCD_next[7:4] = BCD[7:4] - 4'd1;
							end else begin
								BCD_next[15:12] = BCD[15:12] + 4'd1;
								BCD_next[7:4] = BCD[7:4] - 4'd1;
							end
						end
					end
				end
				G3 : begin
					if(!go) begin
						if(!clear) begin
							if(passenger == 2'b11) passenger_next = 2'b10;
							else if(passenger == 2'b10) passenger_next = 2'b00;
							else if(passenger == 2'b00) clear_next = 1'b1;
						end else begin
							if(!pay) begin
								if(B2 == 2'b11) begin
									passenger_next = B2;
									pay_next = 1'b1;
									if(BCD[7:4] > 4'd4) begin
										BCD_next[7:4] = 4'd9;
										BCD_next[3:0] = 4'd0;
									end else BCD_next[7:4] = BCD[7:4] + 4'd4;
								end else if (B2 == 2'b10) begin
									passenger_next = B2;
									pay_next = 1'b1;
									if(BCD[7:4] > 4'd6) begin
										BCD_next[7:4] = 4'd9;
										BCD_next[3:0] = 4'd0;
									end else BCD_next[7:4] = BCD[7:4] + 4'd2;
								end else if (B1 != 2'b00)begin
									go_next = 1'b1;
								end
							end else begin
								B2_next = 2'b00;
								if((BCD[15:12] == 4'd2) || (BCD[15:12] == 4'd1 && BCD[7:4] == 4'd0)) go_next = 1'b1;
								else if(BCD[7:4] != 4'd0) begin
									if(BCD[15:12] == 4'd1 && BCD[11:8] == 4'd5) begin
										BCD_next[15:12] = 4'd2;
										BCD_next[11:8] = 4'd0;
										BCD_next[7:4] = BCD[7:4] - 4'd1;
									end else begin
										BCD_next[15:12] = BCD[15:12] + 4'd1;
										BCD_next[7:4] = BCD[7:4] - 4'd1;
									end
								end
							end
						end
					end
				end
				Yellow : begin
					go_next = 1'b0;
					clear_next = 1'b0;
					pay_next = 1'b0;
					if(dir) begin
						if(busway == LED1 || busway == LED4) begin
							if(passenger == 2'b11) BCD_next[15:12] = BCD[15:12] - 4'd1;
							else if(passenger == 2'b10) begin
								if(BCD[11:8] == 4'd5) BCD_next[11:8] = 4'd0;
								else begin
									BCD_next[15:12] = BCD[15:12] - 4'd1;
									BCD_next[11:8] = 4'd5;
								end
							end
						end
					end else begin
						if(busway == LED2 || busway == LED6) begin
							if(passenger == 2'b11) BCD_next[15:12] = BCD[15:12] - 4'd1;
							else if(passenger == 2'b10) begin
								if(BCD[11:8] == 4'd5) BCD_next[11:8] = 4'd0;
								else begin
									BCD_next[15:12] = BCD[15:12] - 4'd1;
									BCD_next[11:8] = 4'd5;
								end
							end
						end
					end
				end
			endcase
		end

		assign LED = {B1, 1'b0, B2, passenger, 2'b00, busway};
		
	endmodule