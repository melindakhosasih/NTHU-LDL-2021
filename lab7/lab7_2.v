// module clock_divider(clk1, clk, clk22);
//     input clk;
//     output clk1;
//     output clk22;
//     reg [21:0] num;
//     wire [21:0] next_num;

//     always @(posedge clk) begin
//         num <= next_num;
//     end

//     assign next_num = num + 1'b1;
//     assign clk1 = num[1];
//     assign clk22 = num[21];
// endmodule

module mem_addr_gen_puzzle(clk, rst, hold, shift, key, h_cnt, v_cnt, pass, pixel_addr);
	input clk, rst, hold, shift;
	input [3:0] key;
	input [9:0] h_cnt, v_cnt;
	output reg pass;
	output [16:0] pixel_addr;

	reg [16:0] pixel_address;
	reg [1:0] mem [0:11] = {
		2'b01, 2'b11, 2'b11, 2'b10,
		2'b00, 2'b01, 2'b10, 2'b01,
		2'b10, 2'b00, 2'b10, 2'b11
	};
	reg [1:0] pos, flip;
	
	assign pixel_addr = (hold) ? ((h_cnt>>1)+320*(v_cnt>>1)) % 76800 : pixel_address;

	always@(posedge clk or posedge rst) begin
		if(rst) begin
			mem[0] <= 2'b01;
			mem[1] <= 2'b11;
			mem[2] <= 2'b11;
			mem[3] <= 2'b10;
			mem[4] <= 2'b00;
			mem[5] <= 2'b01;
			mem[6] <= 2'b10;
			mem[7] <= 2'b01;
			mem[8] <= 2'b10;
			mem[9] <= 2'b00;
			mem[10] <= 2'b10;
			mem[11] <= 2'b11;
		end else begin
			if(key != 4'b1111 && !pass && !hold) begin
				if(shift) mem[key] <= mem[key] - 2'b01;
				else mem[key] <= mem[key] + 2'b01;
			end
			if(mem[0] == 2'b00 && mem[1] == 2'b00 && mem[2] == 2'b00 && mem[3] == 2'b00 && mem[4] == 2'b00 && 
			mem[5] == 2'b00 && mem[6] == 2'b00 && mem[7] == 2'b00 &&  mem[8] == 2'b00 && mem[9] == 2'b00 && 
			mem[10] == 2'b00 && mem[11] == 2'b00) pass <= 1'b1;
			else pass <= 1'b0;
		end
	end

	always@(*) begin
		pixel_address = ((h_cnt>>1)+320*(v_cnt>>1)) % 76800;
		pos = 2'd0;
		flip = 2'd0;
		if ((v_cnt>>1) < 80) begin
			if ((h_cnt>>1) > 240) pos = 2'd3;	
			else if ((h_cnt>>1) > 160) pos = 2'd2;
			else if((h_cnt>>1) > 80) pos = 2'd1;

			if((h_cnt>>1) < 80) begin
				pos = 2'd0;
				flip = mem[0];
			end else if ((h_cnt>>1) < 160) begin
				pos = 2'd1;
				flip = mem[1];
			end else if ((h_cnt>>1) < 240) begin
				pos = 2'd2;
				flip = mem[2];
			end else begin
				pos = 2'd3;
				flip = mem[3];
			end
			
			if((flip == 2'b01)) pixel_address = (((v_cnt>>1) + 80 * pos) + 320 * (((240 * (pos+1))-1) - (h_cnt>>1))) % 25600;
			else if(flip == 2'b10) pixel_address = (320 * (79 + (2*80*pos) - (v_cnt>>1)) + (79 + (2*80*pos) - (h_cnt>>1))) % 25600;
			else if(flip == 2'b11) pixel_address = ((80 * (pos+1) - 1) - ((v_cnt>>1)) + 320 * ((h_cnt>>1) + 80)) % 25600;
		end else if ((v_cnt>>1) < 160) begin
			if((h_cnt>>1) < 80) begin
				pos = 2'd0;
				flip = mem[4];
			end else if ((h_cnt>>1) < 160) begin
				pos = 2'd1;
				flip = mem[5];
			end else if ((h_cnt>>1) < 240) begin
				pos = 2'd2;
				flip = mem[6];
			end else begin
				pos = 2'd3;
				flip = mem[7];
			end

			if(flip == 2'b01) pixel_address = 25600 + (((((v_cnt>>1) % 80) + 80 * pos) + 320 * (((240 * (pos+1))-1) - (h_cnt>>1))) % 25600);
			else if(flip == 2'b10) pixel_address = 25600 + ((320 * (79 + (2*80*pos) - ((v_cnt>>1) % 80)) + (79 + (2*80*pos) - (h_cnt>>1))) % 25600);
			else if(flip == 2'b11) pixel_address = 25600 + ((((80 * (pos+1) - 1) - ((v_cnt>>1) % 80) + 320 * ((h_cnt>>1) + 80)) % 25600));
		end else if((v_cnt>>1) < 240) begin
			if((h_cnt>>1) < 80) begin
				pos = 2'd0;
				flip = mem[8];
			end else if ((h_cnt>>1) < 160) begin
				pos = 2'd1;
				flip = mem[9];
			end else if ((h_cnt>>1) < 240) begin
				pos = 2'd2;
				flip = mem[10];
			end else begin
				pos = 2'd3;
				flip = mem[11];
			end

			if(flip == 2'b01) pixel_address = 51200 + (((((v_cnt>>1) % 80) + 80 * pos) + 320 * (((240 * (pos+1))-1) - (h_cnt>>1))) % 25600);
			else if(flip == 2'b10) pixel_address = 51200 + ((320 * (79 + (2*80*pos) - ((v_cnt>>1) % 80)) + (79 + (2*80*pos) - (h_cnt>>1))) % 25600);
			else if(flip == 2'b11) pixel_address = 51200 + (((80 * (pos+1) - 1) - ((v_cnt>>1) % 80) + 320 * ((h_cnt>>1) + 80)) % 25600);
		end
	end

endmodule

module lab7_2 (clk, rst, hold, PS2_CLK, PS2_DATA, vgaRed, vgaGreen, vgaBlue, hsync, vsync, pass);
    input clk, rst, hold;
    inout PS2_CLK, PS2_DATA;
    output [3:0] vgaRed, vgaGreen, vgaBlue;
    output hsync, vsync;
    output pass;

    parameter [8:0] LEFT_SHIFT_CODES  = 9'b0_0001_0010;
	parameter [8:0] RIGHT_SHIFT_CODES = 9'b0_0101_1001;
	parameter [8:0] KEY_CODES [0:11] = {
		9'h44,	// O => 44
		9'h4D,	// P => 4D
		9'h54,	// [ => 54
		9'h5B,	// ] => 5B
		9'h42,	// K => 42
		9'h4B,	// L => 4B
		9'h4C,	// ; => 4C
		9'h52,	// ' => 52
		9'h3A,	// M => 3A
		9'h41,	// , => 41
		9'h49,  // . => 49
		9'h4A   // / => 4A
	};
	
	reg [3:0] key_num, key;
	reg [9:0] last_key;

	wire shift_down, hold_db, valid;
	wire [511:0] key_down;
	wire [16:0] pixel_addr;
	wire [11:0] pixel, data;
	wire [9:0] h_cnt, v_cnt;
	wire [8:0] last_change;
	wire clk_25MHz, clk_22;
	wire been_ready;

	clock_divider clk_div (.clk(clk), .clk1(clk_25MHz), .clk22(clk_22));
	debounce hold_debounce (hold_db, hold, clk);

    vga_controller vga(
        .pclk(clk_25MHz),
        .reset(rst),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );

    blk_mem_gen_0 blk_mem_gen_0_inst(
      .clka(clk_25MHz),
      .wea(0),
      .addra(pixel_addr),
      .dina(data[11:0]),
      .douta(pixel)
    );

    mem_addr_gen_puzzle mem_addr_gen2(
		.clk(clk),
		.rst(rst),
		.hold(hold_db),
		.shift(shift_down),
		.key(key),
		.h_cnt(h_cnt),
		.v_cnt(v_cnt),
		.pass(pass),
		.pixel_addr(pixel_addr)
    );
	
	KeyboardDecoder key_de (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);

	assign {vgaRed, vgaGreen, vgaBlue} = (valid==1'b1) ? pixel:12'h0;
	assign shift_down = (key_down[LEFT_SHIFT_CODES] == 1'b1 || key_down[RIGHT_SHIFT_CODES] == 1'b1) ? 1'b1 : 1'b0;

	always @(posedge clk) begin
		if (been_ready && key_down[last_change] == 1'b1) begin
			if (key_num != 4'b1111)begin
				key <= key_num;
			end else key <= 4'b1111;
		end else key <= 4'b1111;
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
			KEY_CODES[10] : key_num = 4'b1010;
			KEY_CODES[11] : key_num = 4'b1011;
			default		  : key_num = 4'b1111;
		endcase
	end
endmodule