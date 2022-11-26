`default_nettype none

module ABZ_DET
    # ( parameter BIT_LENGTH = 12 
    )    
    (
    input wire CLK,     // clock
    input wire ARSTN,   // Async Reset (inverted)
    input wire A_IN,    // Async input
    input wire B_IN,    // Async input
    input wire Z_IN,    // Async input
    input wire EN_INIT_IN,                  // Enable initialize position value
    input wire [BIT_LENGTH-1:0] INIT_COUNT, // Initial encoder count value for 
    input wire [BIT_LENGTH-1:0] POS_OFFSET, // Position offset value for zero position
    input wire EN_OUTPUT_IN,                // Enable output 
    output reg [BIT_LENGTH-1:0] CNT_OUT,    // continuous count output
    output reg [BIT_LENGTH-1:0] LATCHED_CNT_OUT // Latched count output with EN_OUTPUT_IN
);

reg [1:0] A_IN_TMP;
reg [1:0] B_IN_TMP;
reg [1:0] Z_IN_TMP;
reg DIRECTION;
wire POS_A;
wire POS_B;
wire POS_Z;
wire NEG_A;
wire NEG_B;
wire NEG_Z;
wire POS_EN_INIT_IN;
wire POS_EN_OUTPUT;
wire [3:0] CONDITION;
wire RISE_CONDITION;
wire FALL_CONDITION;
wire CLEAR_CONTIDION;

// Double FF to AVOID meta-stable
always @(posedge CLK or negedge ARSTN) begin
    if (!ARSTN) begin
        A_IN_TMP    <= 2'b0;
        B_IN_TMP    <= 2'b0;
        Z_IN_TMP    <= 2'b0;
    end
    else begin
        A_IN_TMP[0]    <= A_IN;
        B_IN_TMP[0]    <= B_IN;
        Z_IN_TMP[0]    <= Z_IN;
        A_IN_TMP[1]    <= A_IN_TMP[0];
        B_IN_TMP[1]    <= B_IN_TMP[0];
        Z_IN_TMP[1]    <= Z_IN_TMP[0];
    end
end

// Edge detection
EDGE_DET A_EDGE(.CLK(CLK),.ARSTN(ARSTN),.IN(A_IN_TMP[1]),.POS(POS_A),.NEG(NEG_A));
EDGE_DET B_EDGE(.CLK(CLK),.ARSTN(ARSTN),.IN(B_IN_TMP[1]),.POS(POS_B),.NEG(NEG_B));
EDGE_DET Z_EDGE(.CLK(CLK),.ARSTN(ARSTN),.IN(Z_IN_TMP[1]),.POS(POS_Z),.NEG(NEG_Z));
EDGE_DET INIT_EN_EDGE(.CLK(CLK),.ARSTN(ARSTN),.IN(EN_INIT_IN),.POS(POS_EN_INIT_IN),.NEG());
EDGE_DET OUTPUT_EN_EDGE(.CLK(CLK),.ARSTN(ARSTN),.IN(EN_OUTPUT_IN),.POS(POS_EN_OUTPUT),.NEG());

// Combine COUNT UP & DOWN condition
assign RISE_CONDITION = (~B_IN_TMP[1] && POS_A) |
                        ( A_IN_TMP[1] && POS_B) |
                        ( B_IN_TMP[1] && NEG_A) |
                        (~A_IN_TMP[1] && NEG_B);
assign FALL_CONDITION = (~A_IN_TMP[1] && POS_B) |
                        ( B_IN_TMP[1] && POS_A) |
                        ( A_IN_TMP[1] && NEG_B) |
                        (~B_IN_TMP[1] && NEG_A);

// Detect Z pulse at one side edge
always @(posedge CLK or negedge ARSTN) begin
    if (!ARSTN) begin
        DIRECTION <= 1'b0;
    end
    else begin
        if (RISE_CONDITION) DIRECTION <= 1'b1;
        else if (FALL_CONDITION) DIRECTION <= 1'b0;
    end
end

assign CLEAR_CONTIDION = DIRECTION ? POS_Z : NEG_Z;

// Counting logic
assign CONDITION = {FALL_CONDITION, RISE_CONDITION, CLEAR_CONTIDION, POS_EN_INIT_IN};

always @(posedge CLK or negedge ARSTN) begin
    if (!ARSTN) begin
        CNT_OUT <= 0;
    end
    else begin
        casex (CONDITION)
            4'bXXX1:    CNT_OUT <= INIT_COUNT;
            4'bXX10:    CNT_OUT <= POS_OFFSET;
            4'b0100:    CNT_OUT <= CNT_OUT + 1'b1;
            4'b1000:    CNT_OUT <= CNT_OUT - 1'b1;
            default:    CNT_OUT <= CNT_OUT;
        endcase
    end
end

// Latched count output 
always @(posedge CLK or negedge ARSTN) begin
    if (!ARSTN) begin
        LATCHED_CNT_OUT <= 0;
    end
    else begin
        if (EN_OUTPUT_IN) begin
            LATCHED_CNT_OUT <= CNT_OUT;
        end
    end
end


endmodule

`default_nettype wire