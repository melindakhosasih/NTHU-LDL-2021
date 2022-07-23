module onepulse (pb_debounced, clk, pb_1pulse);
    input pb_debounced, clk;
    output reg pb_1pulse;
    reg pb_debounced_delay;

    always@(posedge clk) begin
        if(pb_debounced == 1'b1 && pb_debounced_delay == 1'b0) pb_1pulse <= 1'b1;
        else pb_1pulse <= 1'b0;
        pb_debounced_delay <= pb_debounced;
    end
endmodule