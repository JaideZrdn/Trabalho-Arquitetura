module mux_write_reg #(
    parameter REG_WIDTH = 5,
    parameter SEL_WIDTH = 2
)(
    input  wire [REG_WIDTH-1:0] rt,
    input  wire [REG_WIDTH-1:0] rd,
    input  wire [SEL_WIDTH-1:0] reg_dst,
    output reg  [REG_WIDTH-1:0] write_register
);
    always @(*) begin
        case (reg_dst)
            2'b00: write_register = rt;
            2'b01: write_register = rd;
            // {REG_WIDTH{1'b1}} preenche todos os bits com 1 (para 5 bits, resulta em 31, que é o $ra)
            2'b10: write_register = {REG_WIDTH{1'b1}}; 
            default: write_register = {REG_WIDTH{1'b0}};
        endcase
    end
endmodule
