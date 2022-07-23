module lab2_2 (clk, rst, carA, carB, lightA, lightB);
    input clk, rst, carA, carB;
    output reg [2:0] lightA, lightB;
    reg [5:0] state, next_state;
    reg A = 1'b0, B = 1'b0;
    parameter S0 = 6'b001100;
    parameter S1 = 6'b010100;
    parameter S2 = 6'b100001;
    parameter S3 = 6'b100010;

    always@(posedge rst, posedge clk) begin
        if(rst) begin
            state <= S0;
            next_state <= S0;
            lightA <= S0[5:3];
            lightB <= S0[2:0];
            {A, B} <= 2'b00;
        end else begin
            state <= next_state;
        end
    end
    
    always@(posedge clk) begin 
        if(rst) begin
            {A, B} = 2'b00;
        end
        state = next_state;
        case (state)
            S0 : begin
                if(!carA && carB && A) next_state = S1;
                else next_state = S0;
                if(!A && !rst) A = 1'b1;
            end
            S1 : begin
                next_state = S2;
                A = 1'b0;
            end
            S2 : begin
                if(carA && !carB && B) next_state = S3;
                else next_state = S2;
                if(!B && !rst) B = 1'b1;
            end
            S3 : begin
                next_state = S0;
                B = 1'b0;
            end
            default : begin
                next_state = S0;
                {A, B} = 2'b00;
            end
        endcase
        lightA = next_state[5:3];
        lightB = next_state[2:0];
    end
endmodule