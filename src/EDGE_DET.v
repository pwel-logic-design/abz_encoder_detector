`default_nettype none
module EDGE_DET (
    input wire CLK,
    input wire ARSTN,
    input wire IN,
    output wire POS,
    output wire NEG
);

reg in_0;

always @(posedge CLK or negedge ARSTN) begin
    if (!ARSTN) begin
        in_0 <= 1'b0;
    end
    else begin
        in_0 <= IN;
    end
end

assign POS = ~in_0 & IN;
assign NEG = in_0 & ~IN;

    
endmodule

`default_nettype wire