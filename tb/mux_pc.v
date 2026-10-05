module mux_pc #(
    parameter DATA_WIDTH = 32,
    parameter SEL_WIDTH = 2
)(
    input  wire [DATA_WIDTH-1:0] pc_plus_4,
    input  wire [DATA_WIDTH-1:0] branch_target,
    input  wire [DATA_WIDTH-1:0] jump_target,
    input  wire [DATA_WIDTH-1:0] jr_target,
    input  wire [SEL_WIDTH-1:0]  pc_src,
    output reg  [DATA_WIDTH-1:0] next_pc
);
    always @(*) begin
        case (pc_src)
            2'b00: next_pc = pc_plus_4;
            2'b01: next_pc = branch_target;
            2'b10: next_pc = jump_target;
            2'b11: next_pc = jr_target; 
            default: next_pc = pc_plus_4;
        endcase
    end
endmodule