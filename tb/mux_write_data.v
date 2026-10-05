module mux_write_data #(
    parameter DATA_WIDTH = 32,
    parameter SEL_WIDTH = 2
)(
    input  wire [DATA_WIDTH-1:0] alu_result,
    input  wire [DATA_WIDTH-1:0] mem_read_data,
    input  wire [DATA_WIDTH-1:0] pc_plus_4,     
    input  wire [SEL_WIDTH-1:0]  mem_to_reg,    
    output reg  [DATA_WIDTH-1:0] write_data
);
    always @(*) begin
        case (mem_to_reg)
            2'b00: write_data = alu_result;
            2'b01: write_data = mem_read_data;
            2'b10: write_data = pc_plus_4; 
            default: write_data = {DATA_WIDTH{1'b0}};
        endcase
    end
endmodule