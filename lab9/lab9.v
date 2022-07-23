module Lab9(
    input clk,
    input rst,
    input echo,
    input left_track,
    input right_track,
    input mid_track,
    output trig,
    output IN1,
    output IN2,
    output IN3, 
    output IN4,
    output left_pwm,
    output right_pwm
);

    reg [1:0] mode;
    wire [19:0] distance;
    wire [1:0] tracker_state;
    
    motor A(
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .pwm({left_pwm, right_pwm}),
        .l_IN({IN1, IN2}),
        .r_IN({IN3, IN4})
    );

    sonic_top B(
        .clk(clk), 
        .rst(rst), 
        .Echo(echo), 
        .Trig(trig),
        .distance(distance)
    );

    tracker_sensor C(
        .clk(clk), 
        .reset(rst), 
        .left_track(left_track), 
        .right_track(right_track),
        .mid_track(mid_track), 
        .state(tracker_state)
    );

    always@(posedge clk, posedge rst) begin
        if(rst) begin
            mode <= 2'b00;
        end else begin
            if(distance > 20) begin
                mode <= tracker_state;
            end else begin
                mode <= 2'b00;
            end
        end
    end

endmodule

// This module take "mode" input and control two motors accordingly.
// clk should be 100MHz for PWM_gen module to work correctly.
// You can modify / add more inputs and outputs by yourself.
module motor(
    input clk,
    input rst,
    input [1:0] mode,
    output [1:0] pwm,
    output [1:0] r_IN,
    output [1:0] l_IN
);
    reg [9:0] next_left_motor, next_right_motor;
    reg [9:0] left_motor, right_motor;
    reg [1:0] r_temp, l_temp; // direction
    wire left_pwm, right_pwm;

    motor_pwm m0(clk, rst, left_motor, left_pwm);
    motor_pwm m1(clk, rst, right_motor, right_pwm);

    assign pwm = {left_pwm, right_pwm};
    assign r_IN = r_temp;
    assign l_IN = l_temp;

    always@(posedge clk, posedge rst) begin
        if(rst) begin
            left_motor <= 10'd0;
            right_motor <= 10'd0;
        end else begin
            left_motor <= next_left_motor;
            right_motor <= next_right_motor;
        end
    end

    always@(*)begin
        case(mode)
            2'b00 : begin   // stop
                next_left_motor = 10'd0;
                next_right_motor = 10'd0;
                l_temp = 2'b00; // off
                r_temp = 2'b00; // off
            end
            2'b01 : begin   // turn left
                next_left_motor = 10'd750;
                next_right_motor = 10'd750;
                l_temp = 2'b01; // backward
                r_temp = 2'b01; // forward
            end
            2'b10 : begin   // turn right
                next_left_motor = 10'd750;
                next_right_motor = 10'd750;
                l_temp = 2'b10; // forward
                r_temp = 2'b10; // backward
            end
            2'b11 : begin   // go forward
                next_left_motor = 10'd750;
                next_right_motor = 10'd750;
                l_temp = 2'b01; // forward
                r_temp = 2'b10; // forward
            end
        endcase
    end
endmodule

module motor_pwm (
    input clk,
    input reset,
    input [9:0] duty,
	output pmod_1 //PWM
);
    PWM_gen pwm_0 ( 
        .clk(clk), 
        .reset(reset), 
        .freq(32'd25000),
        .duty(duty), 
        .PWM(pmod_1)
    );

endmodule

//generate PWM by input frequency & duty cycle
module PWM_gen (
    input wire clk,
    input wire reset,
	input [31:0] freq,
    input [9:0] duty,
    output reg PWM
);
    wire [31:0] count_max = 100_000_000 / freq;
    wire [31:0] count_duty = count_max * duty / 1024;
    reg [31:0] count;
        
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
            PWM <= 0;
        end else if (count < count_max) begin
            count <= count + 1;
            if(count < count_duty)
                PWM <= 1;
            else
                PWM <= 0;
        end else begin
            count <= 0;
            PWM <= 0;
        end
    end
endmodule

// sonic_top is the module to interface with sonic sensors
// clk = 100MHz
// <Trig> and <Echo> should connect to the sensor
// <distance> is the output distance in cm
module sonic_top(clk, rst, Echo, Trig, distance);
	input clk, rst, Echo;
	output Trig;
    output [19:0] distance;

	wire [19:0] dis;
    wire clk1M;
	wire clk_2_17;

    assign distance = dis;

    div clk1(clk, clk1M);   // clock divider for 1us clock (10^-6 second)
	TrigSignal u1(.clk(clk), .rst(rst), .trig(Trig));   // every 1.000 the signal is '1' but '0' for 9.999.000 (one pulse for 10us clock for 100MHz)
	PosCounter u2(.clk(clk1M), .rst(rst), .echo(Echo), .distance_count(dis));   // count the distance every 1us second
 
endmodule

module PosCounter(clk, rst, echo, distance_count); 
    input clk, rst, echo;
    output[19:0] distance_count;

    parameter S0 = 2'b00;
    parameter S1 = 2'b01; 
    parameter S2 = 2'b10;
    
    wire start, finish;
    reg[1:0] curr_state, next_state;
    reg echo_reg1, echo_reg2;
    reg[19:0] count, distance_register;
    wire[19:0] distance_count; 

    always@(posedge clk) begin
        if(rst) begin
            echo_reg1 <= 0;
            echo_reg2 <= 0;
            count <= 0;
            distance_register  <= 0;
            curr_state <= S0;
        end
        else begin
            echo_reg1 <= echo;   
            echo_reg2 <= echo_reg1; 
            case(curr_state)
                S0:begin
                    if (start) curr_state <= next_state; //S1
                    else count <= 0;
                end
                S1:begin
                    if (finish) curr_state <= next_state; //S2
                    else count <= count + 1;
                end
                S2:begin
                    distance_register <= count;
                    count <= 0;
                    curr_state <= next_state; //S0
                end
            endcase
        end
    end

    always @(*) begin
        case(curr_state)
            S0:next_state = S1;
            S1:next_state = S2;
            S2:next_state = S0;
            default:next_state = S0;
        endcase
    end

    assign start = echo_reg1 & ~echo_reg2;  // start receiving the reflected signal
    assign finish = ~echo_reg1 & echo_reg2; // no more reflected signal

    assign distance_count = distance_register >> 6;
    
endmodule

// send trigger signal to sensor
module TrigSignal(clk, rst, trig);
    input clk, rst;
    output trig;

    reg trig, next_trig;
    reg[23:0] count, next_count;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count <= 0;
            trig <= 0;
        end
        else begin
            count <= next_count;
            trig <= next_trig;
        end
    end
    // count 10us to set trig high and wait for 100ms
    always @(*) begin
        next_trig = trig;
        next_count = count + 1;
        if(count == 999)
            next_trig = 0;
        else if(count == 24'd9999999) begin
            next_trig = 1;
            next_count = 0;
        end
    end
endmodule

// clock divider for T = 1us clock
module div(clk, out_clk);
    input clk;
    output out_clk;
    reg out_clk;
    reg [6:0]cnt;
    
    always @(posedge clk) begin   
        if(cnt < 7'd50) begin
            cnt <= cnt + 1'b1;
            out_clk <= 1'b1;
        end 
        else if(cnt < 7'd100) begin
	        cnt <= cnt + 1'b1;
	        out_clk <= 1'b0;
        end
        else if(cnt == 7'd100) begin
            cnt <= 0;
            out_clk <= 1'b1;
        end
    end
endmodule

module tracker_sensor(clk, reset, left_track, right_track, mid_track, state);
    input clk;
    input reset;
    input left_track, right_track, mid_track;
    output reg [1:0] state;

    always@(posedge clk, posedge reset) begin // 1 = white, 0 = black
        if(reset) begin
            state <= 2'b00; // stop
        end else begin
            if(left_track == 1 && mid_track == 0 && right_track == 1) begin
                state <= 2'b11; // forward
            end else if(left_track == 1 && mid_track == 1 && right_track == 0) begin
                state <= 2'b01; // left
            end else if(left_track == 1 && mid_track == 0 && right_track == 0) begin
                state <= 2'b01; // left
            end else if(left_track == 0 && mid_track == 1 && right_track == 1) begin
                state <= 2'b10; // right
            end else if(left_track == 0 && mid_track == 0 && right_track == 1) begin
                state <= 2'b10; // right
            end else if(left_track == 0 && mid_track == 0 && right_track == 0) begin
                state <= 2'b10; // right
            end else if(left_track == 1 && mid_track == 1 && right_track == 1) begin
                state <= 2'b11; // forward
            end else begin
                state <= 2'b00;  // stop
            end
        end
    end


endmodule