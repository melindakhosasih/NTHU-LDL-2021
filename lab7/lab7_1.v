module clock_divider(clk1, clk, clk22);
    input clk;
    output clk1;
    output clk22;
    reg [21:0] num;
    wire [21:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1'b1;
    assign clk1 = num[1];
    assign clk22 = num[21];
endmodule

module mem_addr_gen(
   input clk,
   input rst,
   input en,
   input dir,
   input [9:0] h_cnt,
   input [9:0] v_cnt,
   output [16:0] pixel_addr
   );
    
   reg [7:0] position;
  
   assign pixel_addr = ((h_cnt>>1)+320*(v_cnt>>1)+ position*320 )% 76800;  //640*480 --> 320*240 

   always @ (posedge clk or posedge rst) begin
        if(rst) position <= 0;
        else begin
            if(en) begin
               if(!dir) begin
                   if(position < 239) position <= position + 1;
                   else position <= 0;
               end else begin
                   if(position > 0) position <= position - 1;
                   else position <= 239;
               end
            end
        end
   end
    
endmodule

module lab7_1 (clk, rst, en, dir, nf, vgaRed, vgaGreen, vgaBlue, hsync, vsync);
    input clk, rst, en, dir, nf;
    output reg [3:0] vgaRed, vgaGreen, vgaBlue;
    output hsync, vsync;
    
    wire [16:0] pixel_addr;
    wire [11:0] pixel, data, pixel_neg;
    wire [9:0] h_cnt, v_cnt;
    wire clk_25Mhz, clk_22;
    wire valid;

    assign pixel_neg = 12'hFFF - pixel;

    always @(*) begin
        if(nf) {vgaRed, vgaGreen, vgaBlue} = (valid==1'b1) ? pixel_neg:12'h0;
        else {vgaRed, vgaGreen, vgaBlue} = (valid==1'b1) ? pixel:12'h0;
    end
    
    clock_divider clk_div (.clk(clk), .clk1(clk_25MHz), .clk22(clk_22));
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

    mem_addr_gen mem_addr_gen_inst(
    .clk(clk_22),
    .rst(rst),
    .en(en),
    .dir(dir),
    .h_cnt(h_cnt),
    .v_cnt(v_cnt),
    .pixel_addr(pixel_addr)
    );
endmodule