`define c   32'd262   // C4
`define d   32'd294   // D4
`define e   32'd330   // E4
`define f   32'd349   // F4
`define bg  32'd370   // bG4
`define g   32'd392   // G4
`define ba  32'd415   // bA4
`define a   32'd440   // A4
`define bb  32'd466   // bB4
`define b   32'd494   // B4
`define hc  32'd524   // C5
`define hd  32'd588   // D5
`define bhe 32'd622   // bE5
`define he  32'd660   // E5
`define hf  32'd698   // F5
`define hg  32'd784   // G5
`define ha  32'd880   // A5
//`define hb  32'd988   // B5
`define hhc 32'd1046   // C6
`define silence   32'd50000000

module note_gen(
    clk, // clock from crystal
    rst, // active high reset
    volume, 
    note_div_left, // div for note generation
    note_div_right,
    audio_left,
    audio_right
);

    // I/O declaration
    input clk; // clock from crystal
    input rst; // active low reset
    input [2:0] volume;
    input [21:0] note_div_left, note_div_right; // div for note generation
    output reg [15:0] audio_left, audio_right;

    // Declare internal signals
    reg [21:0] clk_cnt_next, clk_cnt;
    reg [21:0] clk_cnt_next_2, clk_cnt_2;
    reg b_clk, b_clk_next;
    reg c_clk, c_clk_next;

    // Note frequency generation
    // clk_cnt, clk_cnt_2, b_clk, c_clk
    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            begin
                clk_cnt <= 22'd0;
                clk_cnt_2 <= 22'd0;
                b_clk <= 1'b0;
                c_clk <= 1'b0;
            end
        else
            begin
                clk_cnt <= clk_cnt_next;
                clk_cnt_2 <= clk_cnt_next_2;
                b_clk <= b_clk_next;
                c_clk <= c_clk_next;
            end
    
    // clk_cnt_next, b_clk_next
    always @*
        if (clk_cnt == note_div_left)
            begin
                clk_cnt_next = 22'd0;
                b_clk_next = ~b_clk;
            end
        else
            begin
                clk_cnt_next = clk_cnt + 1'b1;
                b_clk_next = b_clk;
            end

    // clk_cnt_next_2, c_clk_next
    always @*
        if (clk_cnt_2 == note_div_right)
            begin
                clk_cnt_next_2 = 22'd0;
                c_clk_next = ~c_clk;
            end
        else
            begin
                clk_cnt_next_2 = clk_cnt_2 + 1'b1;
                c_clk_next = c_clk;
            end

    // Assign the amplitude of the note
    // Volume is controlled here
    // assign audio_left = (note_div_left == 22'd1) ? 16'h0000 : 
    //                             (b_clk == 1'b0) ? 16'hE000 : 16'h2000;
    // assign audio_right = (note_div_right == 22'd1) ? 16'h0000 : 
    //                             (c_clk == 1'b0) ? 16'hE000 : 16'h2000;
    always@(posedge clk) begin
        if(note_div_left == 22'd1 && note_div_right == 22'd1) begin
            audio_left <= 16'h0000;
            audio_right <= 16'h0000;
        end else begin
            case(volume)
                3'd0 : begin
                    audio_left = (b_clk) ? 16'h0FFF : 16'hF001;
                    audio_right = (c_clk) ? 16'h0FFF : 16'hF001;
                end
                3'd1 : begin
                    audio_left = (b_clk) ? 16'h1FFF : 16'hE001;
                    audio_right = (c_clk) ? 16'h1FFF : 16'hE001;
                end
                3'd2 : begin
                    audio_left = (b_clk) ? 16'h3FFF : 16'hC001;
                    audio_right = (c_clk) ? 16'h3FFF : 16'hC001;
                end
                3'd3 : begin
                    audio_left = (b_clk) ? 16'h5FFF : 16'hA001;
                    audio_right = (c_clk) ? 16'h5FFF : 16'hA001;
                end
                3'd4 : begin
                    audio_left = (b_clk) ? 16'h7FFF : 16'h8001;
                    audio_right = (c_clk) ? 16'h7FFF : 16'h8001;
                end
            endcase
        end
    end
endmodule

module player_control (
	input clk, 
	input reset, 
	input _play, 
	input _music, 
	input _mode, 
	output wire [11:0] ibeat
);
	parameter LEN = 4095;
    reg [11:0] ibeat1, ibeat2, next_ibeat1, next_ibeat2;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			ibeat1 <= 0;
			ibeat2 <= 0;
		end else begin
			if(_play && _mode) begin
				if(_music) begin
					ibeat1 <= 0;
					ibeat2 <= next_ibeat2;
				end else begin
          	  		ibeat1 <= next_ibeat1;
					ibeat2 <= 0;
				end
			end
		end
	end

	assign ibeat = (_music) ? ibeat2 : ibeat1;

    always @* begin
        next_ibeat1 = ((ibeat1 + 1 <= LEN) && !_music) ? (ibeat1 + 1) : 0;
		next_ibeat2 = ((ibeat2 + 1 <= LEN) && _music) ? (ibeat2 + 1) : 0;
    end

endmodule

module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit,
	input wire [7:0] nums,
	input wire rst,
	input wire clk
    );
    
    reg [15:0] clk_divider;
    reg [3:0] display_num;
    
    always @ (posedge clk) begin
        case (digit)
            4'b1110 : begin
                    display_num <= nums[7:4];
                    digit <= 4'b1101;
                end
            4'b1101 : begin
                    display_num <= 4'd0;
                    digit <= 4'b1011;
                end
            4'b1011 : begin
                    display_num <= 4'd0;
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
    		0 : display = 7'b0111111;	//-
            1 : display = 7'b0100000;   //a
            2 : display = 7'b0000011;   //b
            3 : display = 7'b0100111;   //c
			4 : display = 7'b0100001;   //d
			5 : display = 7'b0000110;   //e
			6 : display = 7'b0001110;   //f
			7 : display = 7'b1000010;   //g
			8 : display = 7'b0011100;   //#
			default : display = 7'b0111111;
    	endcase
    end
    
endmodule


module lab8(
    clk,        // clock from crystal
    rst,        // BTNC: active high reset
    _play,      // SW0: Play/Pause
    _mute,      // SW1: Mute
    _slow,      // SW2: Slow
    _music,     // SW3: Music
    _mode,      // SW15: Mode
    _volUP,     // BTNU: Vol up
    _volDOWN,   // BTND: Vol down
    _higherOCT, // BTNR: Oct higher
    _lowerOCT,  // BTNL: Oct lower
    PS2_DATA,   // Keyboard I/O
    PS2_CLK,    // Keyboard I/O
    _led,       // LED: [15:13] octave & [4:0] volume
    audio_mclk, // master clock
    audio_lrck, // left-right clock
    audio_sck,  // serial clock
    audio_sdin, // serial audio data input
    DISPLAY,    // 7-seg
    DIGIT       // 7-seg
);

    // I/O declaration
    input clk; 
    input rst; 
    input _play, _mute, _slow, _music, _mode; 
    input _volUP, _volDOWN, _higherOCT, _lowerOCT; 
    inout PS2_DATA; 
	inout PS2_CLK; 
    output [15:0] _led; 
    output audio_mclk; 
    output audio_lrck; 
    output audio_sck; 
    output audio_sdin; 
    output [6:0] DISPLAY; 
    output [3:0] DIGIT;

    parameter [8:0] KEY_CODES [0:6] = {
    	9'h1C, // a
    	9'h1B, // s
        9'h23, // d
    	9'h2B, // f
        9'h34, // g
    	9'h33, // h
        9'h3B  // j
    };

    wire [511:0] key_down;
    wire [8:0] last_change;
    wire key_valid;

    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;

    wire [11:0] ibeatNum;               // Beat counter
    wire [31:0] freqL, freqR;           // Raw frequency, produced by music module
    wire [21:0] freq_outL, freq_outR;    // Processed frequency, adapted to the clock rate of Basys3
    wire [2:0] key;

    // clkDiv22
    wire clkDiv25, clkDiv22, clkDiv16, clk_div;
    wire vol_up_db, vol_down_db, vol_up, vol_down;
    wire oct_inc_db, oct_inc, oct_dec_db, oct_dec;
    
    reg [31:0] freqL_octave, freqR_octave;
    reg [4:0] vol_LED;
    reg [3:0] note, notation;
    reg [2:0] volume, octave, keys;

    clock_divider #(.n(23)) clock_25(.clk(clk), .clk_div(clkDiv23));
    clock_divider #(.n(22)) clock_22(.clk(clk), .clk_div(clkDiv22));    // for keyboard and audio
    clock_divider #(.n(16)) clock_16(.clk(clk), .clk_div(clkDiv16));    // for seven segment and debounce

    debounce vol_up_debounce (vol_up_db, _volUP, clkDiv16);
    onepulse vol_up_onepulse (vol_up_db, clk, vol_up);

    debounce vol_down_debounce (vol_down_db, _volDOWN, clkDiv16);
    onepulse vol_down_onepulse (vol_down_db, clk, vol_down);

    debounce octave_increase_debounce (oct_inc_db, _higherOCT, clkDiv16);
    onepulse octave_increase_onepulse (oct_inc_db, clk, oct_inc);

    debounce octave_decrease_debounce (oct_dec_db, _lowerOCT, clkDiv16);
    onepulse octave_decrease_onepulse (oct_dec_db, clk, oct_dec);

    SevenSegment sevenseg (DISPLAY, DIGIT, {notation, note}, rst, clkDiv16);

    // Modify these
    assign _led = {octave , 8'b0000_0000, vol_LED};
    assign clk_div = (_slow == 1'b1) ? clkDiv23 : clkDiv22;

    always@(*) begin
        notation = 4'd0;
        note = 4'd0;
        case(freqR)
            `a : note = 4'd1;
            `b : note = 4'd2;
            `c : note = 4'd3;
            `d : note = 4'd4;
            `e : note = 4'd5;
            `f : note = 4'd6;
            `g : note = 4'd7;
            `ha : note = 4'd1;
            //`hb : note = 4'd2;
            `hc : note = 4'd3;
            `hd : note = 4'd4;
            `he : note = 4'd5;
            `hf : note = 4'd6;
            `hg : note = 4'd7;
            `hhc : note = 4'd3;
            `ba : begin
                notation = 4'd2;
                note = 4'd1;
            end
            `bb : begin
                notation = 4'd2;
                note = 4'd2;
            end
            `bg : begin
                notation = 4'd2;
                note = 4'd7;
            end
            `bhe : begin
                notation = 4'd2;
                note = 4'd5;
            end
        endcase
    end

    always@(posedge clk, posedge rst) begin
        if(rst) begin
            octave <= 3'b010;
        end else begin
            if(oct_inc) begin
                octave <= (octave != 3'b001) ? (octave >> 1) : octave;
            end else if(oct_dec) begin
                octave <= (octave != 3'b100) ? (octave << 1) : octave;
            end
        end
    end

    always@(*) begin
        freqL_octave = freqL;
        freqR_octave = freqR;
        if(octave == 3'b100 && freqL != `silence && freqR != `silence) begin
            freqL_octave = freqL >> 1;
            freqR_octave = freqR >> 1;
        end else if(octave == 3'b001 && freqL != `silence && freqR != `silence) begin
            freqL_octave = freqL << 1;
            freqR_octave = freqR << 1;
        end
    end

    always@(*) begin
        vol_LED = 5'b00100;
        case(volume)
            3'd0 : vol_LED = 5'b00001;
            3'd1 : vol_LED = 5'b00011;
            3'd2 : vol_LED = 5'b00111;
            3'd3 : vol_LED = 5'b01111;
            3'd4 : vol_LED = 5'b11111;
        endcase
        if(_mute) vol_LED = 5'b00000;
    end

    always@(posedge clk, posedge rst) begin
        if(rst) begin
            volume <= 3'd2;
        end else begin
            if(vol_up) begin
                volume <= (volume != 3'd4) ? (volume + 3'd1) : volume;
            end if(vol_down) begin
                volume <= (volume != 3'd0) ? (volume - 3'd1) : volume;
            end
        end
    end

    assign key = (key_down[last_change]) ? keys : 3'd7;

    always@(*) begin
        keys = 3'd7;
        case (last_change)
            KEY_CODES[0] : keys = 3'd0;
            KEY_CODES[1] : keys = 3'd1;
            KEY_CODES[2] : keys = 3'd2;
            KEY_CODES[3] : keys = 3'd3;
            KEY_CODES[4] : keys = 3'd4;
            KEY_CODES[5] : keys = 3'd5;
            KEY_CODES[6] : keys = 3'd6;
        endcase
    end

    // Player Control
    // [in]  reset, clock, _play, _slow, _music, and _mode
    // [out] beat number
    player_control #(.LEN(512)) playerCtrl_00 ( 
        .clk(clk_div),
        .reset(rst),
        ._play(_play),
        ._music(_music), 
        ._mode(_mode),
        .ibeat(ibeatNum)
    );

    // Music module
    // [in]  beat number and en
    // [out] left & right raw frequency
    music_example music_00 (
        .ibeatNum(ibeatNum),
        .en(_play),
        .music(_music),
        .mode(_mode),
        .key(key),
        .toneL(freqL),
        .toneR(freqR)
    );

    // freq_outL, freq_outR
    // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    assign freq_outL = (_mute == 1'b1) ? 1 : (50000000 / freqL_octave);
    assign freq_outR = (_mute == 1'b1) ? 1 : (50000000 / freqR_octave);

    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen_00(
        .clk(clk), 
        .rst(rst), 
        .volume(volume),
        .note_div_left(freq_outL), 
        .note_div_right(freq_outR), 
        .audio_left(audio_in_left),     // left sound audio
        .audio_right(audio_in_right)    // right sound audio
    );

    // Speaker controller
    speaker_control sc(
        .clk(clk), 
        .rst(rst), 
        .audio_in_left(audio_in_left),      // left channel audio data input
        .audio_in_right(audio_in_right),    // right channel audio data input
        .audio_mclk(audio_mclk),            // master clock
        .audio_lrck(audio_lrck),            // left-right clock
        .audio_sck(audio_sck),              // serial clock
        .audio_sdin(audio_sdin)             // serial audio data input
    );

    KeyboardDecoder keydecoder(
        .rst(rst),
        .clk(clk),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(key_valid)
    );

endmodule

`define c   32'd262   // C4
`define d   32'd294   // D4
`define e   32'd330   // E4
`define f   32'd349   // F4
`define bg  32'd370   // bG4
`define g   32'd392   // G4
`define ba  32'd415   // bA4
`define a   32'd440   // A4
`define bb  32'd466   // bB4
`define b   32'd494   // B4
`define hc  32'd524   // C5
`define hd  32'd588   // D5
`define bhe 32'd622   // bE5
`define he  32'd660   // E5
`define hf  32'd698   // F5
`define hg  32'd784   // G5
`define ha  32'd880   // A5
`define hhc 32'd1046   // C6
`define sil   32'd50000000 // silence

module music_example (
	input [11:0] ibeatNum,
	input en,
    input music,
    input mode,
    input [2:0] key,
	output reg [31:0] toneL,
    output reg [31:0] toneR
);

    always @* begin
        if(en == 1 && mode == 1 && music == 0) begin
            case(ibeatNum)
                // --- Measure 1 ---
                12'd0: toneR = `hg;      12'd1: toneR = `hg; // HG (half-beat)
                12'd2: toneR = `hg;      12'd3: toneR = `hg;
                12'd4: toneR = `hg;      12'd5: toneR = `hg;
                12'd6: toneR = `hg;      12'd7: toneR = `hg;
                12'd8: toneR = `he;      12'd9: toneR = `he; // HE (half-beat)
                12'd10: toneR = `he;     12'd11: toneR = `he;
                12'd12: toneR = `he;     12'd13: toneR = `he;
                12'd14: toneR = `he;     12'd15: toneR = `sil; // (Short break for repetitive notes: high E)

                12'd16: toneR = `he;     12'd17: toneR = `he; // HE (one-beat)
                12'd18: toneR = `he;     12'd19: toneR = `he;
                12'd20: toneR = `he;     12'd21: toneR = `he;
                12'd22: toneR = `he;     12'd23: toneR = `he;
                12'd24: toneR = `he;     12'd25: toneR = `he;
                12'd26: toneR = `he;     12'd27: toneR = `he;
                12'd28: toneR = `he;     12'd29: toneR = `he;
                12'd30: toneR = `he;     12'd31: toneR = `he;

                12'd32: toneR = `hf;     12'd33: toneR = `hf; // HF (half-beat)
                12'd34: toneR = `hf;     12'd35: toneR = `hf;
                12'd36: toneR = `hf;     12'd37: toneR = `hf;
                12'd38: toneR = `hf;     12'd39: toneR = `hf;
                12'd40: toneR = `hd;     12'd41: toneR = `hd; // HD (half-beat)
                12'd42: toneR = `hd;     12'd43: toneR = `hd;
                12'd44: toneR = `hd;     12'd45: toneR = `hd;
                12'd46: toneR = `hd;     12'd47: toneR = `sil; // (Short break for repetitive notes: high D)

                12'd48: toneR = `hd;     12'd49: toneR = `hd; // HD (one-beat)
                12'd50: toneR = `hd;     12'd51: toneR = `hd;
                12'd52: toneR = `hd;     12'd53: toneR = `hd;
                12'd54: toneR = `hd;     12'd55: toneR = `hd;
                12'd56: toneR = `hd;     12'd57: toneR = `hd;
                12'd58: toneR = `hd;     12'd59: toneR = `hd;
                12'd60: toneR = `hd;     12'd61: toneR = `hd;
                12'd62: toneR = `hd;     12'd63: toneR = `hd;

                // --- Measure 2 ---
                12'd64: toneR = `hc;     12'd65: toneR = `hc; // HC (half-beat)
                12'd66: toneR = `hc;     12'd67: toneR = `hc;
                12'd68: toneR = `hc;     12'd69: toneR = `hc;
                12'd70: toneR = `hc;     12'd71: toneR = `hc;
                12'd72: toneR = `hd;     12'd73: toneR = `hd; // HD (half-beat)
                12'd74: toneR = `hd;     12'd75: toneR = `hd;
                12'd76: toneR = `hd;     12'd77: toneR = `hd;
                12'd78: toneR = `hd;     12'd79: toneR = `hd;

                12'd80: toneR = `he;     12'd81: toneR = `he; // HE (half-beat)
                12'd82: toneR = `he;     12'd83: toneR = `he;
                12'd84: toneR = `he;     12'd85: toneR = `he;
                12'd86: toneR = `he;     12'd87: toneR = `he;
                12'd88: toneR = `hf;     12'd89: toneR = `hf; // HF (half-beat)
                12'd90: toneR = `hf;     12'd91: toneR = `hf;
                12'd92: toneR = `hf;     12'd93: toneR = `hf;
                12'd94: toneR = `hf;     12'd95: toneR = `hf;

                12'd96: toneR = `hg;     12'd97: toneR = `hg; // HG (half-beat)
                12'd98: toneR = `hg;     12'd99: toneR = `hg;
                12'd100: toneR = `hg;    12'd101: toneR = `hg;
                12'd102: toneR = `hg;    12'd103: toneR = `sil; // (Short break for repetitive notes: high D)
                12'd104: toneR = `hg;    12'd105: toneR = `hg; // HG (half-beat)
                12'd106: toneR = `hg;    12'd107: toneR = `hg;
                12'd108: toneR = `hg;    12'd109: toneR = `hg;
                12'd110: toneR = `hg;    12'd111: toneR = `sil; // (Short break for repetitive notes: high D)

                12'd112: toneR = `hg;    12'd113: toneR = `hg; // HG (one-beat)
                12'd114: toneR = `hg;    12'd115: toneR = `hg;
                12'd116: toneR = `hg;    12'd117: toneR = `hg;
                12'd118: toneR = `hg;    12'd119: toneR = `hg;
                12'd120: toneR = `hg;    12'd121: toneR = `hg;
                12'd122: toneR = `hg;    12'd123: toneR = `hg;
                12'd124: toneR = `hg;    12'd125: toneR = `hg;
                12'd126: toneR = `hg;    12'd127: toneR = `sil;

                // --- Measure 3 ---
                12'd128: toneR = `hg;      12'd129: toneR = `hg;
                12'd130: toneR = `hg;      12'd131: toneR = `hg;
                12'd132: toneR = `hg;      12'd133: toneR = `hg;
                12'd134: toneR = `hg;      12'd135: toneR = `hg;
                12'd136: toneR = `he;      12'd137: toneR = `he;
                12'd138: toneR = `he;      12'd139: toneR = `he;
                12'd140: toneR = `he;      12'd141: toneR = `he;
                12'd142: toneR = `he;      12'd143: toneR = `sil;

                12'd144: toneR = `he;      12'd145: toneR = `he;
                12'd146: toneR = `he;      12'd147: toneR = `he;
                12'd148: toneR = `he;      12'd149: toneR = `he;
                12'd150: toneR = `he;      12'd151: toneR = `he;
                12'd152: toneR = `he;      12'd153: toneR = `he;
                12'd154: toneR = `he;      12'd155: toneR = `he;
                12'd156: toneR = `he;      12'd157: toneR = `he;
                12'd158: toneR = `he;      12'd159: toneR = `he;

                12'd160: toneR = `hf;      12'd161: toneR = `hf;
                12'd162: toneR = `hf;      12'd163: toneR = `hf;
                12'd164: toneR = `hf;      12'd165: toneR = `hf;
                12'd166: toneR = `hf;      12'd167: toneR = `hf;
                12'd168: toneR = `hd;      12'd169: toneR = `hd;
                12'd170: toneR = `hd;      12'd171: toneR = `hd;
                12'd172: toneR = `hd;      12'd173: toneR = `hd;
                12'd174: toneR = `hd;      12'd175: toneR = `sil;

                12'd176: toneR = `hd;      12'd177: toneR = `hd;
                12'd178: toneR = `hd;      12'd179: toneR = `hd;
                12'd180: toneR = `hd;      12'd181: toneR = `hd;
                12'd182: toneR = `hd;      12'd183: toneR = `hd;
                12'd184: toneR = `hd;      12'd185: toneR = `hd;
                12'd186: toneR = `hd;      12'd187: toneR = `hd;
                12'd188: toneR = `hd;      12'd189: toneR = `hd;
                12'd190: toneR = `hd;      12'd191: toneR = `hd;

                // --- Measure 4 ---
                12'd192: toneR = `hc;      12'd193: toneR = `hc;
                12'd194: toneR = `hc;      12'd195: toneR = `hc;
                12'd196: toneR = `hc;      12'd197: toneR = `hc;
                12'd198: toneR = `hc;      12'd199: toneR = `hc;
                12'd200: toneR = `he;      12'd201: toneR = `he;
                12'd202: toneR = `he;      12'd203: toneR = `he;
                12'd204: toneR = `he;      12'd205: toneR = `he;
                12'd206: toneR = `he;      12'd207: toneR = `he;

                12'd208: toneR = `hg;      12'd209: toneR = `hg;
                12'd210: toneR = `hg;      12'd211: toneR = `hg;
                12'd212: toneR = `hg;      12'd213: toneR = `hg;
                12'd214: toneR = `hg;      12'd215: toneR = `sil;
                12'd216: toneR = `hg;      12'd217: toneR = `hg;
                12'd218: toneR = `hg;      12'd219: toneR = `hg;
                12'd220: toneR = `hg;      12'd221: toneR = `hg;
                12'd222: toneR = `hg;      12'd223: toneR = `hg;

                12'd224: toneR = `he;      12'd225: toneR = `he;
                12'd226: toneR = `he;      12'd227: toneR = `he;
                12'd228: toneR = `he;      12'd229: toneR = `he;
                12'd230: toneR = `he;      12'd231: toneR = `he;
                12'd232: toneR = `he;      12'd233: toneR = `he;
                12'd234: toneR = `he;      12'd235: toneR = `he;
                12'd236: toneR = `he;      12'd237: toneR = `he;
                12'd238: toneR = `he;      12'd239: toneR = `he;

                12'd240: toneR = `he;      12'd241: toneR = `he;
                12'd242: toneR = `he;      12'd243: toneR = `he;
                12'd244: toneR = `he;      12'd245: toneR = `he;
                12'd246: toneR = `he;      12'd247: toneR = `he;
                12'd248: toneR = `he;      12'd249: toneR = `he;
                12'd250: toneR = `he;      12'd251: toneR = `he;
                12'd252: toneR = `he;      12'd253: toneR = `he;
                12'd254: toneR = `he;      12'd255: toneR = `he;

                // --- Measure 5 ---
                12'd256: toneR = `hd;      12'd257: toneR = `hd;
                12'd258: toneR = `hd;      12'd259: toneR = `hd;
                12'd260: toneR = `hd;      12'd261: toneR = `hd;
                12'd262: toneR = `hd;      12'd263: toneR = `sil;
                12'd264: toneR = `hd;      12'd265: toneR = `hd;
                12'd266: toneR = `hd;      12'd267: toneR = `hd;
                12'd268: toneR = `hd;      12'd269: toneR = `hd;
                12'd270: toneR = `hd;      12'd271: toneR = `sil;

                12'd272: toneR = `hd;      12'd273: toneR = `hd;
                12'd274: toneR = `hd;      12'd275: toneR = `hd;
                12'd276: toneR = `hd;      12'd277: toneR = `hd;
                12'd278: toneR = `hd;      12'd279: toneR = `sil;
                12'd280: toneR = `hd;      12'd281: toneR = `hd;
                12'd282: toneR = `hd;      12'd283: toneR = `hd;
                12'd284: toneR = `hd;      12'd285: toneR = `hd;
                12'd286: toneR = `hd;      12'd287: toneR = `sil;

                12'd288: toneR = `hd;      12'd289: toneR = `hd;
                12'd290: toneR = `hd;      12'd291: toneR = `hd;
                12'd292: toneR = `hd;      12'd293: toneR = `hd;
                12'd294: toneR = `hd;      12'd295: toneR = `hd;
                12'd296: toneR = `he;      12'd297: toneR = `he;
                12'd298: toneR = `he;      12'd299: toneR = `he;
                12'd300: toneR = `he;      12'd301: toneR = `he;
                12'd302: toneR = `he;      12'd303: toneR = `he;

                12'd304: toneR = `hf;      12'd305: toneR = `hf;
                12'd306: toneR = `hf;      12'd307: toneR = `hf;
                12'd308: toneR = `hf;      12'd309: toneR = `hf;
                12'd310: toneR = `hf;      12'd311: toneR = `hf;
                12'd312: toneR = `hf;      12'd313: toneR = `hf;
                12'd314: toneR = `hf;      12'd315: toneR = `hf;
                12'd316: toneR = `hf;      12'd317: toneR = `hf;
                12'd318: toneR = `hf;      12'd319: toneR = `hf;

                // --- Measure 6 ---
                12'd320: toneR = `he;      12'd321: toneR = `he;
                12'd322: toneR = `he;      12'd323: toneR = `he;
                12'd324: toneR = `he;      12'd325: toneR = `he;
                12'd326: toneR = `he;      12'd327: toneR = `sil;
                12'd328: toneR = `he;      12'd329: toneR = `he;
                12'd330: toneR = `he;      12'd331: toneR = `he;
                12'd332: toneR = `he;      12'd333: toneR = `he;
                12'd334: toneR = `he;      12'd335: toneR = `sil;

                12'd336: toneR = `he;      12'd337: toneR = `he;
                12'd338: toneR = `he;      12'd339: toneR = `he;
                12'd340: toneR = `he;      12'd341: toneR = `he;
                12'd342: toneR = `he;      12'd343: toneR = `sil;
                12'd344: toneR = `he;      12'd345: toneR = `he;
                12'd346: toneR = `he;      12'd347: toneR = `he;
                12'd348: toneR = `he;      12'd349: toneR = `he;
                12'd350: toneR = `he;      12'd351: toneR = `sil;

                12'd352: toneR = `he;      12'd353: toneR = `he;
                12'd354: toneR = `he;      12'd355: toneR = `he;
                12'd356: toneR = `he;      12'd357: toneR = `he;
                12'd358: toneR = `he;      12'd359: toneR = `he;
                12'd360: toneR = `hf;      12'd361: toneR = `hf;
                12'd362: toneR = `hf;      12'd363: toneR = `hf;
                12'd364: toneR = `hf;      12'd365: toneR = `hf;
                12'd366: toneR = `hf;      12'd367: toneR = `hf;

                12'd368: toneR = `hg;      12'd369: toneR = `hg;
                12'd370: toneR = `hg;      12'd371: toneR = `hg;
                12'd372: toneR = `hg;      12'd373: toneR = `hg;
                12'd374: toneR = `hg;      12'd375: toneR = `hg;
                12'd376: toneR = `hg;      12'd377: toneR = `hg;
                12'd378: toneR = `hg;      12'd379: toneR = `hg;
                12'd380: toneR = `hg;      12'd381: toneR = `hg;
                12'd382: toneR = `hg;      12'd383: toneR = `sil;

                // --- Measure 7 ---
                12'd384: toneR = `hg;      12'd385: toneR = `hg;
                12'd386: toneR = `hg;      12'd387: toneR = `hg;
                12'd388: toneR = `hg;      12'd389: toneR = `hg;
                12'd390: toneR = `hg;      12'd391: toneR = `hg;
                12'd392: toneR = `he;      12'd393: toneR = `he;
                12'd394: toneR = `he;      12'd395: toneR = `he;
                12'd396: toneR = `he;      12'd397: toneR = `he;
                12'd398: toneR = `he;      12'd399: toneR = `sil;

                12'd400: toneR = `he;      12'd401: toneR = `he;
                12'd402: toneR = `he;      12'd403: toneR = `he;
                12'd404: toneR = `he;      12'd405: toneR = `he;
                12'd406: toneR = `he;      12'd407: toneR = `he;
                12'd408: toneR = `he;      12'd409: toneR = `he;
                12'd410: toneR = `he;      12'd411: toneR = `he;
                12'd412: toneR = `he;      12'd413: toneR = `he;
                12'd414: toneR = `he;      12'd415: toneR = `he;

                12'd416: toneR = `hf;      12'd417: toneR = `hf;
                12'd418: toneR = `hf;      12'd419: toneR = `hf;
                12'd420: toneR = `hf;      12'd421: toneR = `hf;
                12'd422: toneR = `hf;      12'd423: toneR = `hf;
                12'd424: toneR = `hd;      12'd425: toneR = `hd;
                12'd426: toneR = `hd;      12'd427: toneR = `hd;
                12'd428: toneR = `hd;      12'd429: toneR = `hd;
                12'd430: toneR = `hd;      12'd431: toneR = `sil;

                12'd432: toneR = `hd;      12'd433: toneR = `hd;
                12'd434: toneR = `hd;      12'd435: toneR = `hd;
                12'd436: toneR = `hd;      12'd437: toneR = `hd;
                12'd438: toneR = `hd;      12'd439: toneR = `hd;
                12'd440: toneR = `hd;      12'd441: toneR = `hd;
                12'd442: toneR = `hd;      12'd443: toneR = `hd;
                12'd444: toneR = `hd;      12'd445: toneR = `hd;
                12'd446: toneR = `hd;      12'd447: toneR = `hd;

                // --- Measure 8 ---
                12'd448: toneR = `hc;      12'd449: toneR = `hc;
                12'd450: toneR = `hc;      12'd451: toneR = `hc;
                12'd452: toneR = `hc;      12'd453: toneR = `hc;
                12'd454: toneR = `hc;      12'd455: toneR = `hc;
                12'd456: toneR = `he;      12'd457: toneR = `he;
                12'd458: toneR = `he;      12'd459: toneR = `he;
                12'd460: toneR = `he;      12'd461: toneR = `he;
                12'd462: toneR = `he;      12'd463: toneR = `he;

                12'd464: toneR = `hg;      12'd465: toneR = `hg;
                12'd466: toneR = `hg;      12'd467: toneR = `hg;
                12'd468: toneR = `hg;      12'd469: toneR = `hg;
                12'd470: toneR = `hg;      12'd471: toneR = `sil;
                12'd472: toneR = `hg;      12'd473: toneR = `hg;
                12'd474: toneR = `hg;      12'd475: toneR = `hg;
                12'd476: toneR = `hg;      12'd477: toneR = `hg;
                12'd478: toneR = `hg;      12'd479: toneR = `hg;

                12'd480: toneR = `hc;      12'd481: toneR = `hc;
                12'd482: toneR = `hc;      12'd483: toneR = `hc;
                12'd484: toneR = `hc;      12'd485: toneR = `hc;
                12'd486: toneR = `hc;      12'd487: toneR = `hc;
                12'd488: toneR = `hc;      12'd489: toneR = `hc;
                12'd490: toneR = `hc;      12'd491: toneR = `hc;
                12'd492: toneR = `hc;      12'd493: toneR = `hc;
                12'd494: toneR = `hc;      12'd495: toneR = `hc;

                12'd496: toneR = `hc;      12'd497: toneR = `hc;
                12'd498: toneR = `hc;      12'd499: toneR = `hc;
                12'd500: toneR = `hc;      12'd501: toneR = `hc;
                12'd502: toneR = `hc;      12'd503: toneR = `hc;
                12'd504: toneR = `hc;      12'd505: toneR = `hc;
                12'd506: toneR = `hc;      12'd507: toneR = `hc;
                12'd508: toneR = `hc;      12'd509: toneR = `hc;
                12'd510: toneR = `hc;      12'd511: toneR = `hc;

                default: toneR = `sil;
            endcase
        end else if(en == 1 && mode == 1 && music == 1) begin
            case(ibeatNum)
                // --- Measure 1 ---
                12'd0: toneR = `g;      12'd1: toneR = `g;
                12'd2: toneR = `g;      12'd3: toneR = `g;
                12'd4: toneR = `g;      12'd5: toneR = `g;
                12'd6: toneR = `g;      12'd7: toneR = `g;
                12'd8: toneR = `bb;      12'd9: toneR = `bb;
                12'd10: toneR = `bb;      12'd11: toneR = `bb;
                12'd12: toneR = `bb;      12'd13: toneR = `bb;
                12'd14: toneR = `bb;      12'd15: toneR = `bb;

                12'd16: toneR = `hc;      12'd17: toneR = `hc;
                12'd18: toneR = `hc;      12'd19: toneR = `hc;
                12'd20: toneR = `hc;      12'd21: toneR = `hc;
                12'd22: toneR = `hc;      12'd23: toneR = `hc;
                12'd24: toneR = `hc;      12'd25: toneR = `hc;
                12'd26: toneR = `hc;      12'd27: toneR = `hc;
                12'd28: toneR = `ba;      12'd29: toneR = `ba;
                12'd30: toneR = `ba;      12'd31: toneR = `ba;

                12'd32: toneR = `ba;      12'd33: toneR = `ba;
                12'd34: toneR = `ba;      12'd35: toneR = `ba;
                12'd36: toneR = `ba;      12'd37: toneR = `ba;
                12'd38: toneR = `ba;      12'd39: toneR = `ba;
                12'd40: toneR = `g;      12'd41: toneR = `g;
                12'd42: toneR = `g;      12'd43: toneR = `g;
                12'd44: toneR = `g;      12'd45: toneR = `g;
                12'd46: toneR = `g;      12'd47: toneR = `g;

                12'd48: toneR = `f;      12'd49: toneR = `f;
                12'd50: toneR = `f;      12'd51: toneR = `f;
                12'd52: toneR = `f;      12'd53: toneR = `f;
                12'd54: toneR = `f;      12'd55: toneR = `f;
                12'd56: toneR = `e;      12'd57: toneR = `e;
                12'd58: toneR = `e;      12'd59: toneR = `e;
                12'd60: toneR = `e;      12'd61: toneR = `e;
                12'd62: toneR = `e;      12'd63: toneR = `e;

                // --- Measure 2 ---
                12'd64: toneR = `f;      12'd65: toneR = `f;
                12'd66: toneR = `f;      12'd67: toneR = `f;
                12'd68: toneR = `f;      12'd69: toneR = `f;
                12'd70: toneR = `f;      12'd71: toneR = `f;
                12'd72: toneR = `hc;      12'd73: toneR = `hc;
                12'd74: toneR = `hc;      12'd75: toneR = `hc;
                12'd76: toneR = `hc;      12'd77: toneR = `hc;
                12'd78: toneR = `hc;      12'd79: toneR = `hc;

                12'd80: toneR = `bb;      12'd81: toneR = `bb;
                12'd82: toneR = `bb;      12'd83: toneR = `bb;
                12'd84: toneR = `bb;      12'd85: toneR = `bb;
                12'd86: toneR = `bb;      12'd87: toneR = `bb;
                12'd88: toneR = `hc;      12'd89: toneR = `hc;
                12'd90: toneR = `hc;      12'd91: toneR = `hc;
                12'd92: toneR = `g;      12'd93: toneR = `g;
                12'd94: toneR = `g;      12'd95: toneR = `g;

                12'd96: toneR = `g;      12'd97: toneR = `g;
                12'd98: toneR = `g;      12'd99: toneR = `g;
                12'd100: toneR = `g;      12'd101: toneR = `g;
                12'd102: toneR = `g;      12'd103: toneR = `g;
                12'd104: toneR = `f;      12'd105: toneR = `f;
                12'd106: toneR = `f;      12'd107: toneR = `f;
                12'd108: toneR = `f;      12'd109: toneR = `f;
                12'd110: toneR = `f;      12'd111: toneR = `f;

                12'd112: toneR = `e;      12'd113: toneR = `e;
                12'd114: toneR = `e;      12'd115: toneR = `e;
                12'd116: toneR = `e;      12'd117: toneR = `e;
                12'd118: toneR = `e;      12'd119: toneR = `e;
                12'd120: toneR = `e;      12'd121: toneR = `e;
                12'd122: toneR = `e;      12'd123: toneR = `e;
                12'd124: toneR = `e;      12'd125: toneR = `e;
                12'd126: toneR = `e;      12'd127: toneR = `e;

                // --- Measure 3 ---
                12'd128: toneR = `c;      12'd129: toneR = `c;
                12'd130: toneR = `c;      12'd131: toneR = `c;
                12'd132: toneR = `c;      12'd133: toneR = `c;
                12'd134: toneR = `c;      12'd135: toneR = `c;
                12'd136: toneR = `e;      12'd137: toneR = `e;
                12'd138: toneR = `e;      12'd139: toneR = `e;
                12'd140: toneR = `e;      12'd141: toneR = `e;
                12'd142: toneR = `e;      12'd143: toneR = `e;

                12'd144: toneR = `f;      12'd145: toneR = `f;
                12'd146: toneR = `f;      12'd147: toneR = `f;
                12'd148: toneR = `f;      12'd149: toneR = `f;
                12'd150: toneR = `f;      12'd151: toneR = `f;
                12'd152: toneR = `f;      12'd153: toneR = `f;
                12'd154: toneR = `f;      12'd155: toneR = `f;
                12'd156: toneR = `d;      12'd157: toneR = `d;
                12'd158: toneR = `d;      12'd159: toneR = `d;

                12'd160: toneR = `d;      12'd161: toneR = `d;
                12'd162: toneR = `d;      12'd163: toneR = `d;
                12'd164: toneR = `d;      12'd165: toneR = `d;
                12'd166: toneR = `d;      12'd167: toneR = `d;
                12'd168: toneR = `ba;      12'd169: toneR = `ba;
                12'd170: toneR = `ba;      12'd171: toneR = `ba;
                12'd172: toneR = `ba;      12'd173: toneR = `ba;
                12'd174: toneR = `ba;      12'd175: toneR = `ba;

                12'd176: toneR = `g;      12'd177: toneR = `g;
                12'd178: toneR = `g;      12'd179: toneR = `g;
                12'd180: toneR = `g;      12'd181: toneR = `g;
                12'd182: toneR = `g;      12'd183: toneR = `g;
                12'd184: toneR = `hg;      12'd185: toneR = `hg;
                12'd186: toneR = `hg;      12'd187: toneR = `hg;
                12'd188: toneR = `hg;      12'd189: toneR = `hg;
                12'd190: toneR = `hg;      12'd191: toneR = `hg;

                // --- Measure 4 ---
                12'd192: toneR = `hf;      12'd193: toneR = `hf;
                12'd194: toneR = `hf;      12'd195: toneR = `hf;
                12'd196: toneR = `hf;      12'd197: toneR = `hf;
                12'd198: toneR = `hf;      12'd199: toneR = `hf;
                12'd200: toneR = `hd;      12'd201: toneR = `hd;
                12'd202: toneR = `hd;      12'd203: toneR = `hd;
                12'd204: toneR = `hd;      12'd205: toneR = `hd;
                12'd206: toneR = `hd;      12'd207: toneR = `hd;

                12'd208: toneR = `bhe;      12'd209: toneR = `bhe;
                12'd210: toneR = `bhe;      12'd211: toneR = `bhe;
                12'd212: toneR = `bhe;      12'd213: toneR = `bhe;
                12'd214: toneR = `bhe;      12'd215: toneR = `bhe;
                12'd216: toneR = `bhe;      12'd217: toneR = `bhe;
                12'd218: toneR = `bhe;      12'd219: toneR = `bhe;
                12'd220: toneR = `hd;      12'd221: toneR = `hd;
                12'd222: toneR = `hd;      12'd223: toneR = `hd;

                12'd224: toneR = `hd;      12'd225: toneR = `hd;
                12'd226: toneR = `hd;      12'd227: toneR = `hd;
                12'd228: toneR = `hd;      12'd229: toneR = `hd;
                12'd230: toneR = `hd;      12'd231: toneR = `hd;
                12'd232: toneR = `bb;      12'd233: toneR = `bb;
                12'd234: toneR = `bb;      12'd235: toneR = `bb;
                12'd236: toneR = `bb;      12'd237: toneR = `bb;
                12'd238: toneR = `bb;      12'd239: toneR = `bb;

                12'd240: toneR = `hc;      12'd241: toneR = `hc;
                12'd242: toneR = `hc;      12'd243: toneR = `hc;
                12'd244: toneR = `hc;      12'd245: toneR = `hc;
                12'd246: toneR = `hc;      12'd247: toneR = `hc;
                12'd248: toneR = `bb;      12'd249: toneR = `bb;
                12'd250: toneR = `bb;      12'd251: toneR = `bb;
                12'd252: toneR = `bb;      12'd253: toneR = `bb;
                12'd254: toneR = `bb;      12'd255: toneR = `bb;

                // --- Measure 5 ---
                12'd256: toneR = `g;      12'd257: toneR = `g;
                12'd258: toneR = `g;      12'd259: toneR = `g;
                12'd260: toneR = `g;      12'd261: toneR = `g;
                12'd262: toneR = `g;      12'd263: toneR = `g;
                12'd264: toneR = `bb;      12'd265: toneR = `bb;
                12'd266: toneR = `bb;      12'd267: toneR = `bb;
                12'd268: toneR = `bb;      12'd269: toneR = `bb;
                12'd270: toneR = `bb;      12'd271: toneR = `bb;

                12'd272: toneR = `hc;      12'd273: toneR = `hc;
                12'd274: toneR = `hc;      12'd275: toneR = `hc;
                12'd276: toneR = `hc;      12'd277: toneR = `hc;
                12'd278: toneR = `hc;      12'd279: toneR = `hc;
                12'd280: toneR = `hc;      12'd281: toneR = `hc;
                12'd282: toneR = `hc;      12'd283: toneR = `hc;
                12'd284: toneR = `ba;      12'd285: toneR = `ba;
                12'd286: toneR = `ba;      12'd287: toneR = `ba;

                12'd288: toneR = `ba;      12'd289: toneR = `ba;
                12'd290: toneR = `ba;      12'd291: toneR = `ba;
                12'd292: toneR = `ba;      12'd293: toneR = `ba;
                12'd294: toneR = `ba;      12'd295: toneR = `ba;
                12'd296: toneR = `g;      12'd297: toneR = `g;
                12'd298: toneR = `g;      12'd299: toneR = `g;
                12'd300: toneR = `g;      12'd301: toneR = `g;
                12'd302: toneR = `g;      12'd303: toneR = `g;

                12'd304: toneR = `f;      12'd305: toneR = `f;
                12'd306: toneR = `f;      12'd307: toneR = `f;
                12'd308: toneR = `f;      12'd309: toneR = `f;
                12'd310: toneR = `f;      12'd311: toneR = `f;
                12'd312: toneR = `hd;      12'd313: toneR = `hd;
                12'd314: toneR = `hd;      12'd315: toneR = `hd;
                12'd316: toneR = `hd;      12'd317: toneR = `hd;
                12'd318: toneR = `hd;      12'd319: toneR = `hd;

                // --- Measure 6 ---
                12'd320: toneR = `hc;      12'd321: toneR = `hc;
                12'd322: toneR = `hc;      12'd323: toneR = `hc;
                12'd324: toneR = `hc;      12'd325: toneR = `hc;
                12'd326: toneR = `hc;      12'd327: toneR = `hc;
                12'd328: toneR = `bb;      12'd329: toneR = `bb;
                12'd330: toneR = `bb;      12'd331: toneR = `bb;
                12'd332: toneR = `bb;      12'd333: toneR = `bb;
                12'd334: toneR = `bb;      12'd335: toneR = `sil;

                12'd336: toneR = `bb;      12'd337: toneR = `bb;
                12'd338: toneR = `bb;      12'd339: toneR = `bb;
                12'd340: toneR = `bb;      12'd341: toneR = `bb;
                12'd342: toneR = `bb;      12'd343: toneR = `bb;
                12'd344: toneR = `hc;      12'd345: toneR = `hc;
                12'd346: toneR = `hc;      12'd347: toneR = `hc;
                12'd348: toneR = `hc;      12'd349: toneR = `hc;
                12'd350: toneR = `hc;      12'd351: toneR = `hc;

                12'd352: toneR = `hd;      12'd353: toneR = `hd;
                12'd354: toneR = `hd;      12'd355: toneR = `hd;
                12'd356: toneR = `hd;      12'd357: toneR = `hd;
                12'd358: toneR = `hd;      12'd359: toneR = `hd;
                12'd360: toneR = `bhe;      12'd361: toneR = `bhe;
                12'd362: toneR = `bhe;      12'd363: toneR = `bhe;
                12'd364: toneR = `bhe;      12'd365: toneR = `bhe;
                12'd366: toneR = `bhe;      12'd367: toneR = `bhe;

                12'd368: toneR = `bhe;      12'd369: toneR = `bhe;
                12'd370: toneR = `bhe;      12'd371: toneR = `bhe;
                12'd372: toneR = `bhe;      12'd373: toneR = `bhe;
                12'd374: toneR = `bhe;      12'd375: toneR = `bhe;
                12'd376: toneR = `g;      12'd377: toneR = `g;
                12'd378: toneR = `g;      12'd379: toneR = `g;
                12'd380: toneR = `g;      12'd381: toneR = `g;
                12'd382: toneR = `g;      12'd383: toneR = `sil;

                // --- Measure 7 ---
                12'd384: toneR = `g;      12'd385: toneR = `g;
                12'd386: toneR = `g;      12'd387: toneR = `g;
                12'd388: toneR = `g;      12'd389: toneR = `g;
                12'd390: toneR = `g;      12'd391: toneR = `g;
                12'd392: toneR = `f;      12'd393: toneR = `f;
                12'd394: toneR = `f;      12'd395: toneR = `f;
                12'd396: toneR = `f;      12'd397: toneR = `f;
                12'd398: toneR = `f;      12'd399: toneR = `f;

                12'd400: toneR = `e;      12'd401: toneR = `e;
                12'd402: toneR = `e;      12'd403: toneR = `e;
                12'd404: toneR = `e;      12'd405: toneR = `e;
                12'd406: toneR = `e;      12'd407: toneR = `e;
                12'd408: toneR = `e;      12'd409: toneR = `e;
                12'd410: toneR = `e;      12'd411: toneR = `e;
                12'd412: toneR = `e;      12'd413: toneR = `e;
                12'd414: toneR = `e;      12'd415: toneR = `e;

                12'd416: toneR = `e;      12'd417: toneR = `e;
                12'd418: toneR = `e;      12'd419: toneR = `e;
                12'd420: toneR = `e;      12'd421: toneR = `e;
                12'd422: toneR = `e;      12'd423: toneR = `e;
                12'd424: toneR = `e;      12'd425: toneR = `e;
                12'd426: toneR = `e;      12'd427: toneR = `e;
                12'd428: toneR = `e;      12'd429: toneR = `e;
                12'd430: toneR = `e;      12'd431: toneR = `e;

                12'd432: toneR = `g;      12'd433: toneR = `g;
                12'd434: toneR = `g;      12'd435: toneR = `g;
                12'd436: toneR = `g;      12'd437: toneR = `g;
                12'd438: toneR = `g;      12'd439: toneR = `g;
                12'd440: toneR = `hg;      12'd441: toneR = `hg;
                12'd442: toneR = `hg;      12'd443: toneR = `hg;
                12'd444: toneR = `hg;      12'd445: toneR = `hg;
                12'd446: toneR = `hg;      12'd447: toneR = `hg;

                // --- Measure 8 ---
                12'd448: toneR = `hf;      12'd449: toneR = `hf;
                12'd450: toneR = `hf;      12'd451: toneR = `hf;
                12'd452: toneR = `hf;      12'd453: toneR = `hf;
                12'd454: toneR = `hf;      12'd455: toneR = `hf;
                12'd456: toneR = `hd;      12'd457: toneR = `hd;
                12'd458: toneR = `hd;      12'd459: toneR = `hd;
                12'd460: toneR = `hd;      12'd461: toneR = `hd;
                12'd462: toneR = `hd;      12'd463: toneR = `hd;

                12'd464: toneR = `hd;      12'd465: toneR = `hd;
                12'd466: toneR = `hd;      12'd467: toneR = `hd;
                12'd468: toneR = `hd;      12'd469: toneR = `hd;
                12'd470: toneR = `hd;      12'd471: toneR = `hd;
                12'd472: toneR = `hd;      12'd473: toneR = `hd;
                12'd474: toneR = `hd;      12'd475: toneR = `hd;
                12'd476: toneR = `hd;      12'd477: toneR = `hd;
                12'd478: toneR = `hd;      12'd479: toneR = `hd;

                12'd480: toneR = `hd;      12'd481: toneR = `hd;
                12'd482: toneR = `hd;      12'd483: toneR = `hd;
                12'd484: toneR = `hd;      12'd485: toneR = `hd;
                12'd486: toneR = `hd;      12'd487: toneR = `hd;
                12'd488: toneR = `hd;      12'd489: toneR = `hd;
                12'd490: toneR = `hd;      12'd491: toneR = `hd;
                12'd492: toneR = `hd;      12'd493: toneR = `hd;
                12'd494: toneR = `hd;      12'd495: toneR = `hd;

                12'd496: toneR = `hd;      12'd497: toneR = `hd;
                12'd498: toneR = `hd;      12'd499: toneR = `hd;
                12'd500: toneR = `hd;      12'd501: toneR = `hd;
                12'd502: toneR = `hd;      12'd503: toneR = `hd;
                12'd504: toneR = `sil;      12'd505: toneR = `sil;
                12'd506: toneR = `sil;      12'd507: toneR = `sil;
                12'd508: toneR = `sil;      12'd509: toneR = `sil;
                12'd510: toneR = `sil;      12'd511: toneR = `sil;

                default: toneR = `sil;
            endcase
        end else begin
            toneR = `sil;
            if(mode == 0) begin
                case(key)
                    3'd0: toneR = `c;
                    3'd1: toneR = `d;
                    3'd2: toneR = `e;
                    3'd3: toneR = `f;
                    3'd4: toneR = `g;
                    3'd5: toneR = `a;
                    3'd6: toneR = `b;
                endcase
            end
        end
    end

    always @(*) begin
        if(en == 1 && mode == 1 && music == 0)begin
            case(ibeatNum)
                // --- Measure 1 ---
                12'd0: toneL = `hc;  	12'd1: toneL = `hc; // HC (two-beat)
                12'd2: toneL = `hc;  	12'd3: toneL = `hc;
                12'd4: toneL = `hc;	    12'd5: toneL = `hc;
                12'd6: toneL = `hc;  	12'd7: toneL = `hc;
                12'd8: toneL = `hc;	    12'd9: toneL = `hc;
                12'd10: toneL = `hc;	12'd11: toneL = `hc;
                12'd12: toneL = `hc;	12'd13: toneL = `hc;
                12'd14: toneL = `hc;	12'd15: toneL = `hc;

                12'd16: toneL = `hc;	12'd17: toneL = `hc;
                12'd18: toneL = `hc;	12'd19: toneL = `hc;
                12'd20: toneL = `hc;	12'd21: toneL = `hc;
                12'd22: toneL = `hc;	12'd23: toneL = `hc;
                12'd24: toneL = `hc;	12'd25: toneL = `hc;
                12'd26: toneL = `hc;	12'd27: toneL = `hc;
                12'd28: toneL = `hc;	12'd29: toneL = `hc;
                12'd30: toneL = `hc;	12'd31: toneL = `hc;

                12'd32: toneL = `g;	    12'd33: toneL = `g; // G (one-beat)
                12'd34: toneL = `g;	    12'd35: toneL = `g;
                12'd36: toneL = `g;	    12'd37: toneL = `g;
                12'd38: toneL = `g;	    12'd39: toneL = `g;
                12'd40: toneL = `g;	    12'd41: toneL = `g;
                12'd42: toneL = `g;	    12'd43: toneL = `g;
                12'd44: toneL = `g;	    12'd45: toneL = `g;
                12'd46: toneL = `g;	    12'd47: toneL = `g;

                12'd48: toneL = `b;	    12'd49: toneL = `b; // B (one-beat)
                12'd50: toneL = `b;	    12'd51: toneL = `b;
                12'd52: toneL = `b;	    12'd53: toneL = `b;
                12'd54: toneL = `b;	    12'd55: toneL = `b;
                12'd56: toneL = `b;	    12'd57: toneL = `b;
                12'd58: toneL = `b;	    12'd59: toneL = `b;
                12'd60: toneL = `b;	    12'd61: toneL = `b;
                12'd62: toneL = `b;	    12'd63: toneL = `b;

                // --- Measure 2 ---
                12'd64: toneL = `hc;	12'd65: toneL = `hc; // HC (two-beat)
                12'd66: toneL = `hc;    12'd67: toneL = `hc;
                12'd68: toneL = `hc;	12'd69: toneL = `hc;
                12'd70: toneL = `hc;	12'd71: toneL = `hc;
                12'd72: toneL = `hc;	12'd73: toneL = `hc;
                12'd74: toneL = `hc;	12'd75: toneL = `hc;
                12'd76: toneL = `hc;	12'd77: toneL = `hc;
                12'd78: toneL = `hc;	12'd79: toneL = `hc;

                12'd80: toneL = `hc;	12'd81: toneL = `hc;
                12'd82: toneL = `hc;    12'd83: toneL = `hc;
                12'd84: toneL = `hc;    12'd85: toneL = `hc;
                12'd86: toneL = `hc;    12'd87: toneL = `hc;
                12'd88: toneL = `hc;    12'd89: toneL = `hc;
                12'd90: toneL = `hc;    12'd91: toneL = `hc;
                12'd92: toneL = `hc;    12'd93: toneL = `hc;
                12'd94: toneL = `hc;    12'd95: toneL = `hc;

                12'd96: toneL = `g;	    12'd97: toneL = `g; // G (one-beat)
                12'd98: toneL = `g; 	12'd99: toneL = `g;
                12'd100: toneL = `g;	12'd101: toneL = `g;
                12'd102: toneL = `g;	12'd103: toneL = `g;
                12'd104: toneL = `g;	12'd105: toneL = `g;
                12'd106: toneL = `g;	12'd107: toneL = `g;
                12'd108: toneL = `g;	12'd109: toneL = `g;
                12'd110: toneL = `g;	12'd111: toneL = `g;

                12'd112: toneL = `b;	12'd113: toneL = `b; // B (one-beat)
                12'd114: toneL = `b;	12'd115: toneL = `b;
                12'd116: toneL = `b;	12'd117: toneL = `b;
                12'd118: toneL = `b;	12'd119: toneL = `b;
                12'd120: toneL = `b;	12'd121: toneL = `b;
                12'd122: toneL = `b;	12'd123: toneL = `b;
                12'd124: toneL = `b;	12'd125: toneL = `b;
                12'd126: toneL = `b;	12'd127: toneL = `b;
                
                // --- Measure 3 ---
                12'd128: toneL = `hc;      12'd129: toneL = `hc;
                12'd130: toneL = `hc;      12'd131: toneL = `hc;
                12'd132: toneL = `hc;      12'd133: toneL = `hc;
                12'd134: toneL = `hc;      12'd135: toneL = `hc;
                12'd136: toneL = `hc;      12'd137: toneL = `hc;
                12'd138: toneL = `hc;      12'd139: toneL = `hc;
                12'd140: toneL = `hc;      12'd141: toneL = `hc;
                12'd142: toneL = `hc;      12'd143: toneL = `hc;

                12'd144: toneL = `hc;      12'd145: toneL = `hc;
                12'd146: toneL = `hc;      12'd147: toneL = `hc;
                12'd148: toneL = `hc;      12'd149: toneL = `hc;
                12'd150: toneL = `hc;      12'd151: toneL = `hc;
                12'd152: toneL = `hc;      12'd153: toneL = `hc;
                12'd154: toneL = `hc;      12'd155: toneL = `hc;
                12'd156: toneL = `hc;      12'd157: toneL = `hc;
                12'd158: toneL = `hc;      12'd159: toneL = `hc;

                12'd160: toneL = `g;      12'd161: toneL = `g;
                12'd162: toneL = `g;      12'd163: toneL = `g;
                12'd164: toneL = `g;      12'd165: toneL = `g;
                12'd166: toneL = `g;      12'd167: toneL = `g;
                12'd168: toneL = `g;      12'd169: toneL = `g;
                12'd170: toneL = `g;      12'd171: toneL = `g;
                12'd172: toneL = `g;      12'd173: toneL = `g;
                12'd174: toneL = `g;      12'd175: toneL = `g;

                12'd176: toneL = `b;      12'd177: toneL = `b;
                12'd178: toneL = `b;      12'd179: toneL = `b;
                12'd180: toneL = `b;      12'd181: toneL = `b;
                12'd182: toneL = `b;      12'd183: toneL = `b;
                12'd184: toneL = `b;      12'd185: toneL = `b;
                12'd186: toneL = `b;      12'd187: toneL = `b;
                12'd188: toneL = `b;      12'd189: toneL = `b;
                12'd190: toneL = `b;      12'd191: toneL = `b;

                // --- Measure 4 ---
                12'd192: toneL = `hc;      12'd193: toneL = `hc;
                12'd194: toneL = `hc;      12'd195: toneL = `hc;
                12'd196: toneL = `hc;      12'd197: toneL = `hc;
                12'd198: toneL = `hc;      12'd199: toneL = `hc;
                12'd200: toneL = `hc;      12'd201: toneL = `hc;
                12'd202: toneL = `hc;      12'd203: toneL = `hc;
                12'd204: toneL = `hc;      12'd205: toneL = `hc;
                12'd206: toneL = `hc;      12'd207: toneL = `hc;

                12'd208: toneL = `g;      12'd209: toneL = `g;
                12'd210: toneL = `g;      12'd211: toneL = `g;
                12'd212: toneL = `g;      12'd213: toneL = `g;
                12'd214: toneL = `g;      12'd215: toneL = `g;
                12'd216: toneL = `g;      12'd217: toneL = `g;
                12'd218: toneL = `g;      12'd219: toneL = `g;
                12'd220: toneL = `g;      12'd221: toneL = `g;
                12'd222: toneL = `g;      12'd223: toneL = `g;

                12'd224: toneL = `e;      12'd225: toneL = `e;
                12'd226: toneL = `e;      12'd227: toneL = `e;
                12'd228: toneL = `e;      12'd229: toneL = `e;
                12'd230: toneL = `e;      12'd231: toneL = `e;
                12'd232: toneL = `e;      12'd233: toneL = `e;
                12'd234: toneL = `e;      12'd235: toneL = `e;
                12'd236: toneL = `e;      12'd237: toneL = `e;
                12'd238: toneL = `e;      12'd239: toneL = `e;

                12'd240: toneL = `c;      12'd241: toneL = `c;
                12'd242: toneL = `c;      12'd243: toneL = `c;
                12'd244: toneL = `c;      12'd245: toneL = `c;
                12'd246: toneL = `c;      12'd247: toneL = `c;
                12'd248: toneL = `c;      12'd249: toneL = `c;
                12'd250: toneL = `c;      12'd251: toneL = `c;
                12'd252: toneL = `c;      12'd253: toneL = `c;
                12'd254: toneL = `c;      12'd255: toneL = `c;

                // --- Measure 5 ---
                12'd256: toneL = `g;      12'd257: toneL = `g;
                12'd258: toneL = `g;      12'd259: toneL = `g;
                12'd260: toneL = `g;      12'd261: toneL = `g;
                12'd262: toneL = `g;      12'd263: toneL = `g;
                12'd264: toneL = `g;      12'd265: toneL = `g;
                12'd266: toneL = `g;      12'd267: toneL = `g;
                12'd268: toneL = `g;      12'd269: toneL = `g;
                12'd270: toneL = `g;      12'd271: toneL = `g;

                12'd272: toneL = `g;      12'd273: toneL = `g;
                12'd274: toneL = `g;      12'd275: toneL = `g;
                12'd276: toneL = `g;      12'd277: toneL = `g;
                12'd278: toneL = `g;      12'd279: toneL = `g;
                12'd280: toneL = `g;      12'd281: toneL = `g;
                12'd282: toneL = `g;      12'd283: toneL = `g;
                12'd284: toneL = `g;      12'd285: toneL = `g;
                12'd286: toneL = `g;      12'd287: toneL = `g;

                12'd288: toneL = `f;      12'd289: toneL = `f;
                12'd290: toneL = `f;      12'd291: toneL = `f;
                12'd292: toneL = `f;      12'd293: toneL = `f;
                12'd294: toneL = `f;      12'd295: toneL = `f;
                12'd296: toneL = `f;      12'd297: toneL = `f;
                12'd298: toneL = `f;      12'd299: toneL = `f;
                12'd300: toneL = `f;      12'd301: toneL = `f;
                12'd302: toneL = `f;      12'd303: toneL = `f;

                12'd304: toneL = `d;      12'd305: toneL = `d;
                12'd306: toneL = `d;      12'd307: toneL = `d;
                12'd308: toneL = `d;      12'd309: toneL = `d;
                12'd310: toneL = `d;      12'd311: toneL = `d;
                12'd312: toneL = `d;      12'd313: toneL = `d;
                12'd314: toneL = `d;      12'd315: toneL = `d;
                12'd316: toneL = `d;      12'd317: toneL = `d;
                12'd318: toneL = `d;      12'd319: toneL = `d;

                // --- Measure 6 ---
                12'd320: toneL = `e;      12'd321: toneL = `e;
                12'd322: toneL = `e;      12'd323: toneL = `e;
                12'd324: toneL = `e;      12'd325: toneL = `e;
                12'd326: toneL = `e;      12'd327: toneL = `e;
                12'd328: toneL = `e;      12'd329: toneL = `e;
                12'd330: toneL = `e;      12'd331: toneL = `e;
                12'd332: toneL = `e;      12'd333: toneL = `e;
                12'd334: toneL = `e;      12'd335: toneL = `e;

                12'd336: toneL = `e;      12'd337: toneL = `e;
                12'd338: toneL = `e;      12'd339: toneL = `e;
                12'd340: toneL = `e;      12'd341: toneL = `e;
                12'd342: toneL = `e;      12'd343: toneL = `e;
                12'd344: toneL = `e;      12'd345: toneL = `e;
                12'd346: toneL = `e;      12'd347: toneL = `e;
                12'd348: toneL = `e;      12'd349: toneL = `e;
                12'd350: toneL = `e;      12'd351: toneL = `e;

                12'd352: toneL = `g;      12'd353: toneL = `g;
                12'd354: toneL = `g;      12'd355: toneL = `g;
                12'd356: toneL = `g;      12'd357: toneL = `g;
                12'd358: toneL = `g;      12'd359: toneL = `g;
                12'd360: toneL = `g;      12'd361: toneL = `g;
                12'd362: toneL = `g;      12'd363: toneL = `g;
                12'd364: toneL = `g;      12'd365: toneL = `g;
                12'd366: toneL = `g;      12'd367: toneL = `g;

                12'd368: toneL = `b;      12'd369: toneL = `b;
                12'd370: toneL = `b;      12'd371: toneL = `b;
                12'd372: toneL = `b;      12'd373: toneL = `b;
                12'd374: toneL = `b;      12'd375: toneL = `b;
                12'd376: toneL = `b;      12'd377: toneL = `b;
                12'd378: toneL = `b;      12'd379: toneL = `b;
                12'd380: toneL = `b;      12'd381: toneL = `b;
                12'd382: toneL = `b;      12'd383: toneL = `b;

                // --- Measure 7 ---
                12'd384: toneL = `hc;      12'd385: toneL = `hc;
                12'd386: toneL = `hc;      12'd387: toneL = `hc;
                12'd388: toneL = `hc;      12'd389: toneL = `hc;
                12'd390: toneL = `hc;      12'd391: toneL = `hc;
                12'd392: toneL = `hc;      12'd393: toneL = `hc;
                12'd394: toneL = `hc;      12'd395: toneL = `hc;
                12'd396: toneL = `hc;      12'd397: toneL = `hc;
                12'd398: toneL = `hc;      12'd399: toneL = `hc;

                12'd400: toneL = `hc;      12'd401: toneL = `hc;
                12'd402: toneL = `hc;      12'd403: toneL = `hc;
                12'd404: toneL = `hc;      12'd405: toneL = `hc;
                12'd406: toneL = `hc;      12'd407: toneL = `hc;
                12'd408: toneL = `hc;      12'd409: toneL = `hc;
                12'd410: toneL = `hc;      12'd411: toneL = `hc;
                12'd412: toneL = `hc;      12'd413: toneL = `hc;
                12'd414: toneL = `hc;      12'd415: toneL = `hc;

                12'd416: toneL = `g;      12'd417: toneL = `g;
                12'd418: toneL = `g;      12'd419: toneL = `g;
                12'd420: toneL = `g;      12'd421: toneL = `g;
                12'd422: toneL = `g;      12'd423: toneL = `g;
                12'd424: toneL = `g;      12'd425: toneL = `g;
                12'd426: toneL = `g;      12'd427: toneL = `g;
                12'd428: toneL = `g;      12'd429: toneL = `g;
                12'd430: toneL = `g;      12'd431: toneL = `g;

                12'd432: toneL = `b;      12'd433: toneL = `b;
                12'd434: toneL = `b;      12'd435: toneL = `b;
                12'd436: toneL = `b;      12'd437: toneL = `b;
                12'd438: toneL = `b;      12'd439: toneL = `b;
                12'd440: toneL = `b;      12'd441: toneL = `b;
                12'd442: toneL = `b;      12'd443: toneL = `b;
                12'd444: toneL = `b;      12'd445: toneL = `b;
                12'd446: toneL = `b;      12'd447: toneL = `b;

                // --- Measure 8 ---
                12'd448: toneL = `hc;      12'd449: toneL = `hc;
                12'd450: toneL = `hc;      12'd451: toneL = `hc;
                12'd452: toneL = `hc;      12'd453: toneL = `hc;
                12'd454: toneL = `hc;      12'd455: toneL = `hc;
                12'd456: toneL = `hc;      12'd457: toneL = `hc;
                12'd458: toneL = `hc;      12'd459: toneL = `hc;
                12'd460: toneL = `hc;      12'd461: toneL = `hc;
                12'd462: toneL = `hc;      12'd463: toneL = `hc;

                12'd464: toneL = `g;      12'd465: toneL = `g;
                12'd466: toneL = `g;      12'd467: toneL = `g;
                12'd468: toneL = `g;      12'd469: toneL = `g;
                12'd470: toneL = `g;      12'd471: toneL = `g;
                12'd472: toneL = `g;      12'd473: toneL = `g;
                12'd474: toneL = `g;      12'd475: toneL = `g;
                12'd476: toneL = `g;      12'd477: toneL = `g;
                12'd478: toneL = `g;      12'd479: toneL = `g;

                12'd480: toneL = `c;      12'd481: toneL = `c;
                12'd482: toneL = `c;      12'd483: toneL = `c;
                12'd484: toneL = `c;      12'd485: toneL = `c;
                12'd486: toneL = `c;      12'd487: toneL = `c;
                12'd488: toneL = `c;      12'd489: toneL = `c;
                12'd490: toneL = `c;      12'd491: toneL = `c;
                12'd492: toneL = `c;      12'd493: toneL = `c;
                12'd494: toneL = `c;      12'd495: toneL = `c;

                12'd496: toneL = `c;      12'd497: toneL = `c;
                12'd498: toneL = `c;      12'd499: toneL = `c;
                12'd500: toneL = `c;      12'd501: toneL = `c;
                12'd502: toneL = `c;      12'd503: toneL = `c;
                12'd504: toneL = `c;      12'd505: toneL = `c;
                12'd506: toneL = `c;      12'd507: toneL = `c;
                12'd508: toneL = `c;      12'd509: toneL = `c;
                12'd510: toneL = `c;      12'd511: toneL = `c;

                default : toneL = `sil;
            endcase
        end else if(en == 1 && mode == 1 && music == 1) begin
            case(ibeatNum)
                // --- Measure 1 ---
                12'd0: toneL = `sil;      12'd1: toneL = `sil;
                12'd2: toneL = `sil;      12'd3: toneL = `sil;
                12'd4: toneL = `sil;      12'd5: toneL = `sil;
                12'd6: toneL = `sil;      12'd7: toneL = `sil;
                12'd8: toneL = `sil;      12'd9: toneL = `sil;
                12'd10: toneL = `sil;      12'd11: toneL = `sil;
                12'd12: toneL = `sil;      12'd13: toneL = `sil;
                12'd14: toneL = `sil;      12'd15: toneL = `sil;

                12'd16: toneL = `hf;      12'd17: toneL = `hf;
                12'd18: toneL = `hf;      12'd19: toneL = `hf;
                12'd20: toneL = `hf;      12'd21: toneL = `hf;
                12'd22: toneL = `hf;      12'd23: toneL = `hf;
                12'd24: toneL = `hf;      12'd25: toneL = `hf;
                12'd26: toneL = `hf;      12'd27: toneL = `hf;
                12'd28: toneL = `hf;      12'd29: toneL = `hf;
                12'd30: toneL = `hf;      12'd31: toneL = `hf;

                12'd32: toneL = `hf;      12'd33: toneL = `hf;
                12'd34: toneL = `hf;      12'd35: toneL = `hf;
                12'd36: toneL = `hf;      12'd37: toneL = `hf;
                12'd38: toneL = `hf;      12'd39: toneL = `hf;
                12'd40: toneL = `hf;      12'd41: toneL = `hf;
                12'd42: toneL = `hf;      12'd43: toneL = `hf;
                12'd44: toneL = `hf;      12'd45: toneL = `hf;
                12'd46: toneL = `hf;      12'd47: toneL = `hf;

                12'd48: toneL = `hg;      12'd49: toneL = `hg;
                12'd50: toneL = `hg;      12'd51: toneL = `hg;
                12'd52: toneL = `hg;      12'd53: toneL = `hg;
                12'd54: toneL = `hg;      12'd55: toneL = `hg;
                12'd56: toneL = `hg;      12'd57: toneL = `hg;
                12'd58: toneL = `hg;      12'd59: toneL = `hg;
                12'd60: toneL = `hg;      12'd61: toneL = `hg;
                12'd62: toneL = `hg;      12'd63: toneL = `hg;

                // --- Measure 2 ---
                12'd64: toneL = `hg;      12'd65: toneL = `hg;
                12'd66: toneL = `hg;      12'd67: toneL = `hg;
                12'd68: toneL = `hg;      12'd69: toneL = `hg;
                12'd70: toneL = `hg;      12'd71: toneL = `hg;
                12'd72: toneL = `hg;      12'd73: toneL = `hg;
                12'd74: toneL = `hg;      12'd75: toneL = `hg;
                12'd76: toneL = `hg;      12'd77: toneL = `hg;
                12'd78: toneL = `hg;      12'd79: toneL = `hg;

                12'd80: toneL = `he;      12'd81: toneL = `he;
                12'd82: toneL = `he;      12'd83: toneL = `he;
                12'd84: toneL = `he;      12'd85: toneL = `he;
                12'd86: toneL = `he;      12'd87: toneL = `he;
                12'd88: toneL = `he;      12'd89: toneL = `he;
                12'd90: toneL = `he;      12'd91: toneL = `he;
                12'd92: toneL = `he;      12'd93: toneL = `he;
                12'd94: toneL = `he;      12'd95: toneL = `he;

                12'd96: toneL = `he;      12'd97: toneL = `he;
                12'd98: toneL = `he;      12'd99: toneL = `he;
                12'd100: toneL = `he;      12'd101: toneL = `he;
                12'd102: toneL = `he;      12'd103: toneL = `he;
                12'd104: toneL = `he;      12'd105: toneL = `he;
                12'd106: toneL = `he;      12'd107: toneL = `he;
                12'd108: toneL = `he;      12'd109: toneL = `he;
                12'd110: toneL = `he;      12'd111: toneL = `he;

                12'd112: toneL = `ha;      12'd113: toneL = `ha;
                12'd114: toneL = `ha;      12'd115: toneL = `ha;
                12'd116: toneL = `ha;      12'd117: toneL = `ha;
                12'd118: toneL = `ha;      12'd119: toneL = `ha;
                12'd120: toneL = `ha;      12'd121: toneL = `ha;
                12'd122: toneL = `ha;      12'd123: toneL = `ha;
                12'd124: toneL = `ha;      12'd125: toneL = `ha;
                12'd126: toneL = `ha;      12'd127: toneL = `ha;

                // --- Measure 3 ---
                12'd128: toneL = `ha;      12'd129: toneL = `ha;
                12'd130: toneL = `ha;      12'd131: toneL = `ha;
                12'd132: toneL = `ha;      12'd133: toneL = `ha;
                12'd134: toneL = `ha;      12'd135: toneL = `ha;
                12'd136: toneL = `ha;      12'd137: toneL = `ha;
                12'd138: toneL = `ha;      12'd139: toneL = `ha;
                12'd140: toneL = `ha;      12'd141: toneL = `ha;
                12'd142: toneL = `ha;      12'd143: toneL = `ha;

                12'd144: toneL = `hf;      12'd145: toneL = `hf;
                12'd146: toneL = `hf;      12'd147: toneL = `hf;
                12'd148: toneL = `hf;      12'd149: toneL = `hf;
                12'd150: toneL = `hf;      12'd151: toneL = `hf;
                12'd152: toneL = `hf;      12'd153: toneL = `hf;
                12'd154: toneL = `hf;      12'd155: toneL = `hf;
                12'd156: toneL = `hf;      12'd157: toneL = `hf;
                12'd158: toneL = `hf;      12'd159: toneL = `hf;

                12'd160: toneL = `hf;      12'd161: toneL = `hf;
                12'd162: toneL = `hf;      12'd163: toneL = `hf;
                12'd164: toneL = `hf;      12'd165: toneL = `hf;
                12'd166: toneL = `hf;      12'd167: toneL = `hf;
                12'd168: toneL = `hf;      12'd169: toneL = `hf;
                12'd170: toneL = `hf;      12'd171: toneL = `hf;
                12'd172: toneL = `hf;      12'd173: toneL = `hf;
                12'd174: toneL = `hf;      12'd175: toneL = `hf;

                12'd176: toneL = `he;      12'd177: toneL = `he;
                12'd178: toneL = `he;      12'd179: toneL = `he;
                12'd180: toneL = `he;      12'd181: toneL = `he;
                12'd182: toneL = `he;      12'd183: toneL = `he;
                12'd184: toneL = `he;      12'd185: toneL = `he;
                12'd186: toneL = `he;      12'd187: toneL = `he;
                12'd188: toneL = `he;      12'd189: toneL = `he;
                12'd190: toneL = `he;      12'd191: toneL = `he;

                // --- Measure 4 ---
                12'd192: toneL = `he;      12'd193: toneL = `he;
                12'd194: toneL = `he;      12'd195: toneL = `he;
                12'd196: toneL = `he;      12'd197: toneL = `he;
                12'd198: toneL = `he;      12'd199: toneL = `he;
                12'd200: toneL = `he;      12'd201: toneL = `he;
                12'd202: toneL = `he;      12'd203: toneL = `he;
                12'd204: toneL = `he;      12'd205: toneL = `he;
                12'd206: toneL = `he;      12'd207: toneL = `he;

                12'd208: toneL = `ha;      12'd209: toneL = `ha;
                12'd210: toneL = `ha;      12'd211: toneL = `ha;
                12'd212: toneL = `ha;      12'd213: toneL = `ha;
                12'd214: toneL = `ha;      12'd215: toneL = `ha;
                12'd216: toneL = `ha;      12'd217: toneL = `ha;
                12'd218: toneL = `ha;      12'd219: toneL = `ha;
                12'd220: toneL = `ha;      12'd221: toneL = `ha;
                12'd222: toneL = `ha;      12'd223: toneL = `ha;

                12'd224: toneL = `ha;      12'd225: toneL = `ha;
                12'd226: toneL = `ha;      12'd227: toneL = `ha;
                12'd228: toneL = `ha;      12'd229: toneL = `ha;
                12'd230: toneL = `ha;      12'd231: toneL = `ha;
                12'd232: toneL = `ha;      12'd233: toneL = `ha;
                12'd234: toneL = `ha;      12'd235: toneL = `ha;
                12'd236: toneL = `ha;      12'd237: toneL = `ha;
                12'd238: toneL = `ha;      12'd239: toneL = `ha;

                12'd240: toneL = `he;      12'd241: toneL = `he;
                12'd242: toneL = `he;      12'd243: toneL = `he;
                12'd244: toneL = `he;      12'd245: toneL = `he;
                12'd246: toneL = `he;      12'd247: toneL = `he;
                12'd248: toneL = `he;      12'd249: toneL = `he;
                12'd250: toneL = `he;      12'd251: toneL = `he;
                12'd252: toneL = `he;      12'd253: toneL = `he;
                12'd254: toneL = `he;      12'd255: toneL = `he;

                // --- Measure 5 ---
                12'd256: toneL = `sil;      12'd257: toneL = `sil;
                12'd258: toneL = `sil;      12'd259: toneL = `sil;
                12'd260: toneL = `sil;      12'd261: toneL = `sil;
                12'd262: toneL = `sil;      12'd263: toneL = `sil;
                12'd264: toneL = `sil;      12'd265: toneL = `sil;
                12'd266: toneL = `sil;      12'd267: toneL = `sil;
                12'd268: toneL = `sil;      12'd269: toneL = `sil;
                12'd270: toneL = `sil;      12'd271: toneL = `sil;

                12'd272: toneL = `f;      12'd273: toneL = `f;
                12'd274: toneL = `f;      12'd275: toneL = `f;
                12'd276: toneL = `f;      12'd277: toneL = `f;
                12'd278: toneL = `f;      12'd279: toneL = `f;
                12'd280: toneL = `hc;      12'd281: toneL = `hc;
                12'd282: toneL = `hc;      12'd283: toneL = `hc;
                12'd284: toneL = `hc;      12'd285: toneL = `hc;
                12'd286: toneL = `hc;      12'd287: toneL = `hc;

                12'd288: toneL = `hf;      12'd289: toneL = `hf;
                12'd290: toneL = `hf;      12'd291: toneL = `hf;
                12'd292: toneL = `hf;      12'd293: toneL = `hf;
                12'd294: toneL = `hf;      12'd295: toneL = `hf;
                12'd296: toneL = `hc;      12'd297: toneL = `hc;
                12'd298: toneL = `hc;      12'd299: toneL = `hc;
                12'd300: toneL = `hc;      12'd301: toneL = `hc;
                12'd302: toneL = `hc;      12'd303: toneL = `hc;

                12'd304: toneL = `bg;      12'd305: toneL = `bg;
                12'd306: toneL = `bg;      12'd307: toneL = `bg;
                12'd308: toneL = `bg;      12'd309: toneL = `bg;
                12'd310: toneL = `bg;      12'd311: toneL = `bg;
                12'd312: toneL = `hd;      12'd313: toneL = `hd;
                12'd314: toneL = `hd;      12'd315: toneL = `hd;
                12'd316: toneL = `hd;      12'd317: toneL = `hd;
                12'd318: toneL = `hd;      12'd319: toneL = `hd;

                // --- Measure 6 ---
                12'd320: toneL = `hg;      12'd321: toneL = `hg;
                12'd322: toneL = `hg;      12'd323: toneL = `hg;
                12'd324: toneL = `hg;      12'd325: toneL = `hg;
                12'd326: toneL = `hg;      12'd327: toneL = `hg;
                12'd328: toneL = `hd;      12'd329: toneL = `hd;
                12'd330: toneL = `hd;      12'd331: toneL = `hd;
                12'd332: toneL = `hd;      12'd333: toneL = `hd;
                12'd334: toneL = `hd;      12'd335: toneL = `hd;

                12'd336: toneL = `e;      12'd337: toneL = `e;
                12'd338: toneL = `e;      12'd339: toneL = `e;
                12'd340: toneL = `e;      12'd341: toneL = `e;
                12'd342: toneL = `e;      12'd343: toneL = `e;
                12'd344: toneL = `b;      12'd345: toneL = `b;
                12'd346: toneL = `b;      12'd347: toneL = `b;
                12'd348: toneL = `b;      12'd349: toneL = `b;
                12'd350: toneL = `b;      12'd351: toneL = `b;

                12'd352: toneL = `he;      12'd353: toneL = `he;
                12'd354: toneL = `he;      12'd355: toneL = `he;
                12'd356: toneL = `he;      12'd357: toneL = `he;
                12'd358: toneL = `he;      12'd359: toneL = `he;
                12'd360: toneL = `b;      12'd361: toneL = `b;
                12'd362: toneL = `b;      12'd363: toneL = `b;
                12'd364: toneL = `b;      12'd365: toneL = `b;
                12'd366: toneL = `b;      12'd367: toneL = `b;

                12'd368: toneL = `a;      12'd369: toneL = `a;
                12'd370: toneL = `a;      12'd371: toneL = `a;
                12'd372: toneL = `a;      12'd373: toneL = `a;
                12'd374: toneL = `a;      12'd375: toneL = `a;
                12'd376: toneL = `he;      12'd377: toneL = `he;
                12'd378: toneL = `he;      12'd379: toneL = `he;
                12'd380: toneL = `he;      12'd381: toneL = `he;
                12'd382: toneL = `he;      12'd383: toneL = `he;

                // --- Measure 7 ---
                12'd384: toneL = `hhc;      12'd385: toneL = `hhc;
                12'd386: toneL = `hhc;      12'd387: toneL = `hhc;
                12'd388: toneL = `hhc;      12'd389: toneL = `hhc;
                12'd390: toneL = `hhc;      12'd391: toneL = `hhc;
                12'd392: toneL = `he;      12'd393: toneL = `he;
                12'd394: toneL = `he;      12'd395: toneL = `he;
                12'd396: toneL = `he;      12'd397: toneL = `he;
                12'd398: toneL = `he;      12'd399: toneL = `he;

                12'd400: toneL = `hf;      12'd401: toneL = `hf;
                12'd402: toneL = `hf;      12'd403: toneL = `hf;
                12'd404: toneL = `hf;      12'd405: toneL = `hf;
                12'd406: toneL = `hf;      12'd407: toneL = `hf;
                12'd408: toneL = `hf;      12'd409: toneL = `hf;
                12'd410: toneL = `hf;      12'd411: toneL = `hf;
                12'd412: toneL = `hf;      12'd413: toneL = `hf;
                12'd414: toneL = `hf;      12'd415: toneL = `hf;

                12'd416: toneL = `hf;      12'd417: toneL = `hf;
                12'd418: toneL = `hf;      12'd419: toneL = `hf;
                12'd420: toneL = `hf;      12'd421: toneL = `hf;
                12'd422: toneL = `hf;      12'd423: toneL = `hf;
                12'd424: toneL = `hf;      12'd425: toneL = `hf;
                12'd426: toneL = `hf;      12'd427: toneL = `hf;
                12'd428: toneL = `hf;      12'd429: toneL = `hf;
                12'd430: toneL = `hf;      12'd431: toneL = `hf;

                12'd432: toneL = `he;      12'd433: toneL = `he;
                12'd434: toneL = `he;      12'd435: toneL = `he;
                12'd436: toneL = `he;      12'd437: toneL = `he;
                12'd438: toneL = `he;      12'd439: toneL = `he;
                12'd440: toneL = `he;      12'd441: toneL = `he;
                12'd442: toneL = `he;      12'd443: toneL = `he;
                12'd444: toneL = `he;      12'd445: toneL = `he;
                12'd446: toneL = `he;      12'd447: toneL = `he;

                // --- Measure 8 ---
                12'd448: toneL = `b;      12'd449: toneL = `b;
                12'd450: toneL = `b;      12'd451: toneL = `b;
                12'd452: toneL = `b;      12'd453: toneL = `b;
                12'd454: toneL = `b;      12'd455: toneL = `b;
                12'd456: toneL = `b;      12'd457: toneL = `b;
                12'd458: toneL = `b;      12'd459: toneL = `b;
                12'd460: toneL = `b;      12'd461: toneL = `b;
                12'd462: toneL = `b;      12'd463: toneL = `b;

                12'd464: toneL = `b;      12'd465: toneL = `b;
                12'd466: toneL = `b;      12'd467: toneL = `b;
                12'd468: toneL = `b;      12'd469: toneL = `b;
                12'd470: toneL = `b;      12'd471: toneL = `b;
                12'd472: toneL = `b;      12'd473: toneL = `b;
                12'd474: toneL = `b;      12'd475: toneL = `b;
                12'd476: toneL = `b;      12'd477: toneL = `b;
                12'd478: toneL = `b;      12'd479: toneL = `b;

                12'd480: toneL = `b;      12'd481: toneL = `b;
                12'd482: toneL = `b;      12'd483: toneL = `b;
                12'd484: toneL = `b;      12'd485: toneL = `b;
                12'd486: toneL = `b;      12'd487: toneL = `b;
                12'd488: toneL = `b;      12'd489: toneL = `b;
                12'd490: toneL = `b;      12'd491: toneL = `b;
                12'd492: toneL = `b;      12'd493: toneL = `b;
                12'd494: toneL = `b;      12'd495: toneL = `b;

                12'd496: toneL = `sil;      12'd497: toneL = `sil;
                12'd498: toneL = `sil;      12'd499: toneL = `sil;
                12'd500: toneL = `sil;      12'd501: toneL = `sil;
                12'd502: toneL = `sil;      12'd503: toneL = `sil;
                12'd504: toneL = `sil;      12'd505: toneL = `sil;
                12'd506: toneL = `sil;      12'd507: toneL = `sil;
                12'd508: toneL = `sil;      12'd509: toneL = `sil;
                12'd510: toneL = `sil;      12'd511: toneL = `sil;
                default : toneL = `sil;
            endcase
        end else begin
            toneL = `sil;
            if(mode == 0) begin
                case(key)
                    3'd0: toneL = `c;
                    3'd1: toneL = `d;
                    3'd2: toneL = `e;
                    3'd3: toneL = `f;
                    3'd4: toneL = `g;
                    3'd5: toneL = `a;
                    3'd6: toneL = `b;
                endcase
            end
        end
    end
endmodule
