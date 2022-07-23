// 109000168 ?\???

// e.g. 109012345 ???j??
// Add your ID and name to FIRST line of file, or you will get 5 points penalty

`define WIDTH 8

module exam1_A(
    input wire clk,
    input wire rst,
    input wire signed[`WIDTH-1:0] A,
    input wire signed[`WIDTH-1:0] B,
    input wire [1:0] ctrl,
    output reg signed [`WIDTH*2-1:0] out // You can modify "reg" to "wire" if needed
);
    //Your design here
    always@(posedge clk or posedge rst) begin
        if(rst) out = 0;
        else begin
            case (ctrl)
                2'd0 : out = A * B;
                2'd2 : out = {(A&B), (A|B)};
                2'd3 : begin
                    if(A[`WIDTH-1]) out = {11'b1111_1111_111, A[7:3]};
                    else out = {11'b0000_0000_000, A[7:3]};
                end
                default : out = A - B;
            endcase
        end
    end

endmodule


// You can add any module you need.
// Make sure you include all modules you used in this problem.
