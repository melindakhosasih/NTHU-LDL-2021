// 109000168

// e.g. 109012345 ???p??
// Add your ID and name to FIRST line of file, or you will get 5 points penalty


module exam2(
    input wire clk, // 100Mhz clock
    input wire rst,
    input wire en,
    input wire up,       // for remedy
    input wire down,   //for remedy
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    output wire [3:0] DIGIT,
    output wire [6:0] DISPLAY,
    output reg [15:0] led  // You can modify "wire" of output ports to "reg" if needed
);
    
    parameter [8:0] KEY_CODES [0:1] = {
    	9'b0_0110_1001, // right_1 => 69
    	9'b0_0111_0010 // right_2 => 72
    };
    //add your design here
	parameter IDLE = 2'b00;
	parameter NORMAL = 2'b01;
	parameter CHANGE = 2'b10;
	wire [511:0] key_down;
	wire [8:0] last_change;
	wire key_valid;
	wire clk15, clk21, clk25, clk27, en_db, en_op, clk_op;
	reg [15:0] led_next, BCD, BCD_next;
	reg [1:0] state, next_state;
	reg clk_div;
	reg key1_op, key2_op;
	reg [1:0] speed, speed_next;
	reg key1_db, key2_db;
	wire up_db, down_db, up_op, down_op;

	clock_divider #(15) clk_div15 (clk, clk15);
	clock_divider #(21) clk_div21 (clk, clk21);
	clock_divider #(25) clk_div25 (clk, clk25);
	clock_divider #(27) clk_div27 (clk, clk27);

	debounce enable_debounce (en_db, en, clk);
	onepulse enable_onepulse (en_db, clk, en_op);

	debounce up_debounce (up_db, up, clk);
	onepulse up_onepulse (up_db, clk, up_op);

	debounce down_debounce (down_db, down, clk);
	onepulse down_onepulse (down_db, clk, down_op);

	onepulse clock_div (clk_div, clk, clk_op);

	SevenSegment seven_seg (DISPLAY, DIGIT, BCD, rst, clk);
	KeyboardDecoder key_de(key_down, last_change, key_valid, PS2_DATA, PS2_CLK, rst, clk);

	always@(posedge clk, posedge rst) begin
		if(rst) begin
			led <= 16'b1111_0000_0000_0000;
		end else begin
			led <= led_next;
		end
	end

	always@(*) begin
		led_next = led;
		case(state)
			IDLE: led_next = 16'b1111_0000_0000_0000;
			NORMAL : led_next = 16'b0000_1111_0000_0000;
			CHANGE : led_next = 16'b0000_0000_1111_0000;
		endcase
	end

	always@(posedge clk, posedge rst) begin
		if(rst) begin
			speed <= 2'd1;
		end else begin
			if(state == NORMAL || state == CHANGE) begin
				speed <= speed_next;
			end else speed <= 2'd1;
		end
	end

	always@(*) begin
		speed_next = speed;
		if(state == IDLE) begin
			speed_next = 2'd1;
		end else if(state == NORMAL) begin
			if(key1_op || up_op) speed_next = 2'd2;
			if(key2_op || down_op) speed_next = 2'd0;
		end else if(state == CHANGE) begin
			speed_next = 2'd1;
			if(key1_db || up_db) speed_next = 2'd2;
			if(key2_db || down_db) speed_next = 2'd0;
		end
	end

	// always@(posedge clk) begin
	// 	if(key_down[last_change] == KEY_CODES[0]) key1_db = 1'b1;
	// 	else key1_db = 1'b0;
	// 	if(key_down[last_change] == KEY_CODES[1]) key2_db = 1'b1;
	// 	else key2_db = 1'b0;
	// end

	// assign key1_db = (key_down[last_change] == KEY_CODES[0]) ? 1'b1 : 1'b0;
	// assign key2_db = (key_down[last_change] == KEY_CODES[1]) ? 1'b1 : 1'b0;

	always@(posedge clk, posedge rst) begin
		if(rst) begin
			key1_op <= 1'b0;
			key2_op <= 1'b0;
			key1_db <= 1'b0;
			key2_db <= 1'b0;
		end else begin
			if(key_valid && key_down[last_change] && state == NORMAL) begin
				key1_op <= 1'b0;
				key2_op <= 1'b0;
				key1_db <= 1'b0;
				key2_db <= 1'b0;
				if(last_change == KEY_CODES[0]) key1_op <= 1'b1;
				if(last_change == KEY_CODES[1]) key2_op <= 1'b1;
			end else if(state == NORMAL)begin
				key1_op <= 1'b0;
				key2_op <= 1'b0;
				key1_db <= 1'b0;
				key2_db <= 1'b0;
			end
			if(key_down[last_change] && state == CHANGE) begin
				key1_op <= 1'b0;
				key2_op <= 1'b0;
				key1_db <= 1'b0;
				key2_db <= 1'b0;
				if(last_change == KEY_CODES[0]) key1_db <= 1'b1;
				if(last_change == KEY_CODES[1]) key2_db <= 1'b1;
			end else if(state == CHANGE) begin
				key1_op <= 1'b0;
				key2_op <= 1'b0;
				key1_db <= 1'b0;
				key2_db <= 1'b0;
			end
		end
	end

	always@(*) begin
		clk_div = clk25;
		case(speed)
			2'd0 : clk_div = clk27;
			2'd1 : clk_div = clk25;
			2'd2 : clk_div = clk21;
		endcase
	end

	always@(posedge clk, posedge rst) begin
		if(rst) state <= IDLE;
		else state <= next_state;
	end

	always@(posedge clk, posedge rst) begin
		if(rst) begin
			BCD[15:12] <= 4'd0;
			BCD[11:8] <= 4'd0;
			BCD[7:4] <= 4'd0;
			BCD[3:0] <= 4'd0;
		end else begin
			if(en_op) begin
				BCD[15:12] <= 4'd0;
				BCD[11:8] <= 4'd0;
				BCD[7:4] <= 4'd0;
				BCD[3:0] <= 4'd0;
			end else if(clk_op) begin
				BCD[15:12] <= BCD_next[15:12];
				BCD[11:8] <= BCD_next[11:8];
				BCD[7:4] <= BCD_next[7:4];
				BCD[3:0] <= BCD_next[3:0];
			end
		end
	end

	always@(*) begin
		BCD_next[15:12] = BCD[15:12];
		BCD_next[11:8] = BCD[11:8];
		BCD_next[7:4] = BCD[7:4];
		BCD_next[3:0] = BCD[3:0];
		next_state = state;
		if(state == IDLE) begin
			BCD_next[15:12] = 4'd0;
			BCD_next[11:8] = 4'd0;
			BCD_next[7:4] = 4'd0;
			BCD_next[3:0] = 4'd0;
			if(en_op) begin
				next_state = NORMAL;
			end
		end else if (state == NORMAL) begin
			if(en_op) begin
				BCD_next[15:12] = 4'd0;
				BCD_next[11:8] = 4'd0;
				BCD_next[7:4] = 4'd0;
				BCD_next[3:0] = 4'd0;
				next_state = CHANGE;
			end else begin
				if(BCD[15:12] != 4'd1) begin
					if(BCD[3:0] != 4'd9) begin
						BCD_next[3:0] = BCD[3:0] + 4'd1;
					end else begin
						if(BCD_next[7:4] != 4'd9) begin
							BCD_next[7:4] = BCD[7:4] + 4'd1;
							BCD_next[3:0] = 4'd0;
						end else begin
							if(BCD_next[11:8] != 4'd5) begin
								BCD_next[11:8] = BCD[11:8] + 4'd1;
								BCD_next[7:4] = 4'd0;
								BCD_next[3:0] = 4'd0;
							end else begin
								BCD_next[15:12] = 4'd1;
								BCD_next[11:8] = 4'd0;
								BCD_next[7:4] = 4'd0;
								BCD_next[3:0] = 4'd0;
							end
						end
					end
				end
			end
		end else if(state == CHANGE) begin
			if(en_op) begin
				BCD_next[15:12] = 4'd0;
				BCD_next[11:8] = 4'd0;
				BCD_next[7:4] = 4'd0;
				BCD_next[3:0] = 4'd0;
				next_state = IDLE;
			end else begin
				if(BCD[15:12] != 4'd1) begin
					if(BCD[3:0] != 4'd9) begin
						BCD_next[3:0] = BCD[3:0] + 4'd1;
					end else begin
						if(BCD_next[7:4] != 4'd9) begin
							BCD_next[7:4] = BCD[7:4] + 4'd1;
							BCD_next[3:0] = 4'd0;
						end else begin
							if(BCD_next[11:8] != 4'd5) begin
								BCD_next[11:8] = BCD[11:8] + 4'd1;
								BCD_next[7:4] = 4'd0;
								BCD_next[3:0] = 4'd0;
							end else begin
								BCD_next[15:12] = 4'd1;
								BCD_next[11:8] = 4'd0;
								BCD_next[7:4] = 4'd0;
								BCD_next[3:0] = 4'd0;
							end
						end
					end
				end
			end
		end
	end

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
    
    always @ (posedge clk) begin
    	clk_divider <= clk_divider + 15'b1;
    end
    
    always @ (posedge clk_divider[15]) begin
    	// if (rst) begin
    	// 	display_num <= 4'b0000;
    	// 	digit <= 4'b1111;
    	// end else begin
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
    	//end
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
	
	
    onepulse op(.clk(clk), .pb_debounced(been_ready), .pb_1pulse(pulse_been_ready));
    
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
