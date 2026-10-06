// ============================================================================
//  mux_alu_b — escolhe a segunda entrada da ALU
//
//  OBJETIVO
//  Decidir se a entrada B da ALU vem do banco de registradores ou do campo
//  imediato da instrucao. E o sinal classico "ALUSrc" do MIPS.
//
//  POR QUE EXISTE
//      add  $t1, $a0, $t1    -> B = read_data_2 (valor de $t1)
//      lw   $t2, 0($t1)      -> B = imediato estendido (o deslocamento 0)
//      addi $sp, $sp, -20    -> B = imediato estendido (-20)
//      beq  $t0, $zero, ...  -> B = read_data_2 (a ALU subtrai os dois)
//
//  Repare no lw e no addi: a ALU esta somando um registrador com uma constante
//  que veio DENTRO da instrucao. Sem este mux, o processador so conseguiria
//  operar registrador com registrador — nenhuma instrucao de formato I
//  funcionaria.
//
//  Nomes em ingles para casar com o mux_alu_b irmao, o mux_alu_a, que escolhe
//  a primeira entrada (read_data_1 ou shamt).
// ============================================================================
`timescale 1ns/1ps

module mux_alu_b #(
    parameter DATA_WIDTH = 32
)(
    input  wire [DATA_WIDTH-1:0] read_data_2,     // segunda saida do banco
    input  wire [DATA_WIDTH-1:0] imm_extended,    // saida do extensor_sinal
    input  wire                  alu_src_b,       // 0 = registrador, 1 = imediato
    output wire [DATA_WIDTH-1:0] alu_input_b
);

    assign alu_input_b = alu_src_b ? imm_extended : read_data_2;

endmodule
