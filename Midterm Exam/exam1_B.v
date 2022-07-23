// 109000168 ?\???

// e.g. 109012345 ???j??
// Add your ID and name to FIRST line of file, or you will get 5 points penalty
module exam1_B(
    input wire clk,
    input wire rst,
    output reg signed [19:0] result // You can modify "reg" to "wire" if needed
);
    //Your design here
    reg [9:0] idx = 1;
    reg dir = 0;
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            idx = 1;
            result = 0;
        end else begin
            if(!dir) begin
                if((result % 8) == (idx % 8)) begin
                    result = result + idx*3;
                end else begin
                    result = result + idx;
                end
                if(idx == 10'd527) begin
                    idx = 1;
                    dir = 1;
                    result = 20'd183920;
                end
                idx = idx + 1;
            end else begin
                result = result - idx;
                if(result == 0) begin
                    idx = 0;
                    dir = 0;
                end
                idx = idx + 1;
            end 
        end 
    end

endmodule

// You can add any module you need.
// Make sure you include all modules you used in this problem.
