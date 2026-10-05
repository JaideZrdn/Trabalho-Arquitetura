module jump_address_calc #(
    parameter DATA_WIDTH = 32,
    parameter TARGET_WIDTH = 26
)(
    input  wire [DATA_WIDTH-1:0]   pc_plus_4,
    input  wire [TARGET_WIDTH-1:0] target,
    output wire [DATA_WIDTH-1:0]   jump_address
);
    // Concatena os 4 bits mais significativos do PC+4 com o target e 2'b00
    // pc_plus_4[31:28] em um barramento de 32 bits = pc_plus_4[DATA_WIDTH-1 : DATA_WIDTH-4]
    assign jump_address = {pc_plus_4[DATA_WIDTH-1 : DATA_WIDTH-4], target, 2'b00};
endmodule