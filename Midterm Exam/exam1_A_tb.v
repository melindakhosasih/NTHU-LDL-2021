`timescale 10ps/1ps

`define WIDTH 8
`define DELAY 10
`define PATTERN_NUM 800
`define CYCLE 10
module exam1_A_tb(

);

    reg mul_pass, append_pass, shift_pass, default_pass, feed_finish;
    reg clk;
    reg rst;
    reg  [1:0] ctrl, last_ctrl;
    reg  signed [`WIDTH-1:0] A, last_A;
    reg  signed [`WIDTH-1:0] B, last_B;
    wire signed [`WIDTH*2-1:0] out;
    reg signed [`WIDTH*2-1:0] golden, last_golden;
    integer feed_index, fetch_index;
    reg [35:0] mem [0:998];
    integer file;

    initial begin
        clk = 0;
        while(1) #(`CYCLE/2) clk = ~clk;
    end

    exam1_A ALU(
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .ctrl(ctrl),
        .out(out)
    );
    
    initial begin
        // input feeding init
        $readmemh("pattern_A.dat", mem);
           if(mem[1] !== 36'h1_5e_81_00dd) begin
            $display(">>>>>>>>>>> [ERROR] Can not find patter_A.dat, make sure you have added it to simulation source!");
            $finish;
        end

        mul_pass=1;default_pass=1;append_pass=1;shift_pass=1;feed_finish=0;
        #(`CYCLE*10);
        ctrl = {2{1'bz}};
        A    = {`WIDTH{1'bz}};
        B    = {`WIDTH{1'bz}};
        rst  = 1;
        #(`CYCLE*10);
        rst = 0;


        // Feed addition input
        for(feed_index = 0 ; feed_index < `PATTERN_NUM ; feed_index = feed_index + 1) begin
            @(posedge clk); #1;
            {last_ctrl, last_A, last_B, last_golden} = {ctrl, A, B, golden}; 
            {ctrl, A, B, golden} = mem[feed_index][33:0];
        end 
        
        feed_finish = 1;
        // Input feeding stop
        #(`CYCLE*10);
        ctrl = {2{1'bz}};
        A    = {`WIDTH{1'bz}};
        B    = {`WIDTH{1'bz}};

    end
    

    integer scores;
    initial begin

        wait(rst == 1);
        wait(rst == 0);
        @(negedge clk);
        for(fetch_index = 0 ; fetch_index < `PATTERN_NUM-1 ; fetch_index = fetch_index + 1) begin
            @(negedge clk);
            if(out !== last_golden) begin
                $display("<ERROR> [pattern %0d]    ctrl=%b, A=%d, B=%d, out=%d, golden=%d",
                        fetch_index, last_ctrl, last_A, last_B, out, last_golden);
                case(last_ctrl)
                    2'b00:
                        mul_pass = 0;
                    2'b10:
                        append_pass = 0;
                    2'b11:
                        shift_pass = 0;
                    default:
                        default_pass = 0;
                endcase
            end
            
        end 

        #(`CYCLE*20);
        scores = 0;

        if(mul_pass) begin
            scores = scores + 6;
            $display("Function Multiplication PASS! 6/6");
        end
        else begin
            $display("Function Multiplication FAIL!  0/6");
        end

        if(append_pass) begin
            scores = scores + 6;
            $display("Function Append         PASS! 6/6");
        end
        else begin
            $display("Function Append         FAIL!  0/6");
        end
        
        if(shift_pass) begin
            scores = scores + 6;
            $display("Function Shift          PASS! 6/6");
        end
        else begin
            $display("Function Shift          FAIL!  0/6");
        end

        if(default_pass) begin
            scores = scores + 6;
            $display("Function Default        PASS! 6/6");
        end
        else begin
            $display("Function Default        FAIL!  0/6");
        end

        if(feed_finish)
            $display("Pattern Score: %d/24", scores);
        else
            $display("<ERROR> Simulation time is not enough, please add it to 10000ps");

        $finish;
    end



endmodule