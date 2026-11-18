// Decide se uma transferencia de controle acontece e descarta o que entrou
// no pipeline por engano.
//
// Enquanto o processador nao sabe se um desvio sera tomado, ele continua
// buscando as instrucoes seguintes. Quando a decisao sai, essas instrucoes
// ja estao dentro do pipeline e precisam ser anuladas.
//
// A decisao e tomada no estagio EX, onde o sinal zero da ALU existe. Duas
// instrucoes ja entraram ate la — a que esta no ID e a que esta no IF —
// entao sao dois registradores a limpar. Resolver no MEM, como a primeira
// versao do livro, custaria tres.
//
// Casos tratados:
//     beq  desvia se zero = 1      bne  desvia se zero = 0
//     j    e jal: sempre           jr: sempre
`timescale 1ns/1ps

module controle_flush (
    input  wire branch_eq,
    input  wire branch_ne,
    input  wire jump,
    input  wire jr,
    input  wire zero,
    output wire tomado,
    output wire limpa_if_id,
    output wire limpa_id_ex
);
    assign tomado = (branch_eq &&  zero) ||
                    (branch_ne && !zero) ||
                     jump || jr;

    assign limpa_if_id = tomado;
    assign limpa_id_ex = tomado;
endmodule
