module mux_alu_a #(
    parameter DATA_WIDTH = 32,
    parameter SHAMT_WIDTH = 5
)(
    input  wire [DATA_WIDTH-1:0]  read_data_1,   
    input  wire [SHAMT_WIDTH-1:0] shamt,         
    input  wire                   alu_src_a,     
    output wire [DATA_WIDTH-1:0]  alu_input_a
);
    // Se alu_src_a for 1, o shamt é concatenado com a quantidade necessária de zeros à esquerda 
    // para atingir o tamanho de DATA_WIDTH (ex: 27 zeros + 5 bits do shamt).
    assign alu_input_a = (alu_src_a) ? { {(DATA_WIDTH - SHAMT_WIDTH){1'b0}}, shamt } : read_data_1;
endmodule
