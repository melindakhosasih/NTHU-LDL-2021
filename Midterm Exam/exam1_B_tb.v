
`timescale 10ps/1ps

`define PATTERN_NUM 2265
`define CYCLE 10
module exam1_B_tb();


    reg clk, rst, count_up_pass, count_down_pass, count_again_pass;
    wire signed [19:0] result;
    reg signed [19:0] golden[0:`PATTERN_NUM-1];
    
    exam1_B counter(
        .clk(clk),
        .rst(rst),
        .result(result)
    );


    initial begin
        clk = 0;
        while(1) #(`CYCLE/2) clk = ~clk;
    end

    integer index, scores;
    integer file;
    initial begin
        // input feeding init
        count_up_pass = 1'b1;count_down_pass = 1'b1;count_again_pass = 1'b1;


        $readmemh("pattern_B.dat", golden);
        
        if(golden[1] !== 20'h00001) begin
            $display(">>>>>>>>>>> [ERROR] Can not find patter_B.dat, make sure you have added it to simulation source!");
            $finish;
        end

        #(`CYCLE*10);
        rst  = 1;
        #(`CYCLE*10);
        rst = 0;

        for(index = 0 ; index < `PATTERN_NUM ; index = index + 1) begin
            @(negedge clk);
            if(result !== golden[index]) begin
                if(index <= 526)
                    count_up_pass = 1'b0;
                else if(index <= 526+606)
                    count_down_pass = 1'b0;
                else
                    count_again_pass = 1'b0;
                $display("[ERROR] index:%d, result:%d, golden:%d", index, result, golden[index]);
                $finish;
            end
            else begin
                
                //$display("[CORRECT] index:%d, result:%d, golden:%d", index, result, golden[index]);
            end
        end 
        
        #(`CYCLE*10);
        rst = 1;
        $fclose(file);

        scores = 0;
        if(count_up_pass) begin
            $display("Count Up    10/10!");
            scores = scores + 10;
        end
        else begin
            $display("Count Up    0/10!");
        end
        if(count_down_pass) begin
            $display("Count Down  10/10!");
            scores = scores + 10;
        end
        else begin
            $display("Count Down  0/10!");
        end
        if(count_again_pass) begin
            $display("Count Again 10/10!");
            scores = scores + 10;
        end
        else begin
            $display("Count Again 0/10!");
        end

        $display("Your total score: %d/30", scores);

        $finish;

    end


endmodule