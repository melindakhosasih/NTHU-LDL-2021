`timescale 1ns/100ps

module lab2_1_t;
    reg clk, rst, pass;
    wire [5:0] out;
    reg [5:0] count, idx, inc, dec;
    reg dir;

    lab2_1 counter (clk, rst, out);

    initial begin
        clk = 1'b1;
        rst = 1'b0;
        pass = 1'b1;
        count = 6'd0;
        dir = 1'b0;
        inc = 6'd0;
        dec = 6'd0;
        idx = 6'd0;

        $display("Starting the simulation");

        #5 rst = 1'b1;
        #25 rst = 1'b0;
        #30 rst = 1'b1;
        #10 rst = 1'b0;
        #700

        $display("%g Terminating simulation...", $time);
        if (pass) $display(">>>> [PASS]  Congratulations!");
        else      $display(">>>> [ERROR] Try it again!");
        $finish;
    end

    always #5 clk = ~clk;

    always@(posedge clk, posedge rst) begin
        cal();
    end

    always@(negedge clk) begin
        if({out != count}) begin
            pass = 0;
            $display("WRONG!!! OUTPUT %d, CORRECT %d", out, count);
        end
    end

    task cal;
        begin
            if (rst == 1'b1) begin
                count = 6'b000000;
                idx = 6'd1;
                inc = 6'd0;
                dec = 6'd0;
            end else begin
                if(dir) begin
                    count = {count[4:0], 1'b0};
                    if(out == 6'd32) dir = 0;
                end else begin
                    if (idx == 6'd0) count = 6'd0;
                    else if (idx == 6'd1) count = 6'd1;
                    else if (idx == 6'd2) begin
                        dec = 6'd3;
                        inc = 6'd5;
                        count = 6'd3;
                    end else if (idx > 6'd2 && idx < 6'd8) begin
                        if(idx[0] == 0) begin
                            count = dec - 1;
                            dec = dec - 1;
                        end else begin
                            count = inc + 1;
                            inc = inc + 1;
                        end
                    end else if (idx == 6'd8) begin
                        dec = 6'd8;
                        inc = 6'd16;
                        count = 6'd16;
                    end else if (idx > 6'd8 && idx < 6'd23) begin
                        if(idx[0] == 0) begin
                            count = inc + 1;
                            inc = inc + 1;
                        end else begin
                            count = dec - 1;
                            dec = dec - 1;
                        end
                    end else if (idx == 6'd23) begin
                        dec = 6'd23;
                        inc = 6'd46;
                        count = 6'd46;
                    end else begin
                        if(idx[0] == 0) begin
                            count = dec - 1;
                            dec = dec - 1;
                        end else begin
                            count = inc + 1;
                            inc = inc + 1;
                        end
                    end
                    if(count == 6'd63) begin
                        idx = 1'd1;
                        dir = 1'b1;
                    end else idx = idx + 1;
                end
            end
        end
    endtask
endmodule