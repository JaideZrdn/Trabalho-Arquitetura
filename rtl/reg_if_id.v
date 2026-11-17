// Registrador de estagio entre a busca (IF) e a decodificacao (ID).
//
// Carrega a instrucao buscada e o PC+4. O PC+4 segue adiante porque o jal
// precisa dele la no fim do pipeline, no estagio de escrita.
//
// habilita = 0  congela o registrador (usado no stall de load-use)
// limpa    = 1  zera o conteudo, descartando a instrucao (flush de desvio)
//
// O stall tem prioridade sobre o flush: se os dois acontecerem no mesmo
// ciclo, segurar o valor e mais seguro do que descartar.
`timescale 1ns/1ps

module reg_if_id #(
    parameter LARGURA = 32
)(
    input  wire                clk,
    input  wire                reset,
    input  wire                habilita,
    input  wire                limpa,
    input  wire [LARGURA-1:0]  instrucao_in,
    input  wire [LARGURA-1:0]  pc_plus_4_in,
    output reg  [LARGURA-1:0]  instrucao_out,
    output reg  [LARGURA-1:0]  pc_plus_4_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            instrucao_out <= {LARGURA{1'b0}};
            pc_plus_4_out <= {LARGURA{1'b0}};
        end else if (!habilita) begin
            instrucao_out <= instrucao_out;      // stall: segura o que tem
            pc_plus_4_out <= pc_plus_4_out;
        end else if (limpa) begin
            instrucao_out <= {LARGURA{1'b0}};    // instrucao zerada = nop
            pc_plus_4_out <= {LARGURA{1'b0}};
        end else begin
            instrucao_out <= instrucao_in;
            pc_plus_4_out <= pc_plus_4_in;
        end
    end
endmodule
