`default_nettype none
`timescale 1ns/1ps
module ABZ_DET_tb( );
    
parameter length = 12;

reg CLK = 0;
reg ARSTN = 0;
reg A_IN;
reg B_IN;
reg Z_IN;
reg INIT_EN_H;
reg [length-1:0] INIT_COUNT;
reg OUTPUT_EN_H;
wire [length-1:0] CNT_OUT;
wire [length-1:0] CNT_OUT_LATCH;
reg [length-1:0] POS_OFFSET;

always #10 CLK <= ~CLK; // 100MHz


ABZ_DET #(.BIT_LENGTH(length))
ABZ_DET_INST(
    .CLK(CLK),
    .ARSTN(ARSTN),
    .A_IN(A_IN),
    .B_IN(B_IN),
    .Z_IN(Z_IN),
    .EN_INIT_IN(INIT_EN_H),
    .INIT_COUNT(INIT_COUNT),
    .POS_OFFSET(POS_OFFSET),
    .EN_OUTPUT_IN(OUTPUT_EN_H),
    .CNT_OUT(CNT_OUT),
    .CNT_OUT_LATCH(CNT_OUT_LATCH)
);

initial begin
    A_IN =1'b0;
    B_IN =1'b0;
    Z_IN =1'b0;
    INIT_EN_H = 1'b0;
    INIT_COUNT = 12'b0;
    OUTPUT_EN_H = 1'b0;
    POS_OFFSET = 12'd1000;

    # 1000
    ARSTN = 1'b1;
    //INIT_COUNT = 12'd55F;

    // Check INITIALIZE
    # 20000
    INIT_EN_H = 1'b1;
    # 20000
    INIT_EN_H = 1'b0;

    // Check Z pulse det
    # 1000
    Z_IN = 1'b1;
    # 1000
    Z_IN = 1'b0;

    // Check rise count
    repeat(1024) begin
    # 1000    A_IN = 1;    B_IN = 0;
    # 1000    A_IN = 1;    B_IN = 1;
    # 1000    A_IN = 0;    B_IN = 1;
    # 1000    A_IN = 0;    B_IN = 0;
    end

    // Check OUTPUT
    # 20000
    OUTPUT_EN_H = 1'b1;
    # 20000
    OUTPUT_EN_H = 1'b0;

    // Check Z pulse det
    # 1000
    Z_IN = 1'b1;
    # 1000
    Z_IN = 1'b0;

    // Check fall count
    repeat(1024) begin
    # 1000    A_IN = 0;    B_IN = 1;
    # 1000    A_IN = 1;    B_IN = 1;
    # 1000    A_IN = 1;    B_IN = 0;
    # 1000    A_IN = 0;    B_IN = 0;
    end


end

endmodule
