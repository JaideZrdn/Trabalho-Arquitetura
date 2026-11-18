// Contador de programa com entrada de habilitacao.
//
// Igual ao pc.v do monociclo, mais um sinal: quando habilita = 0, o endereco
// nao avanca. E assim que o stall de load-use segura a busca por um ciclo.
//
// O reset e assincrono pelo mesmo motivo do monociclo: o relogio pode estar
// parado enquanto o reset esta apertado.
`timescale 1ns/1ps

module pc_com_habilita #(
    parameter LARGURA          = 32,
    parameter ENDERECO_INICIAL = 0
)(
    input  wire               clk,
    input  wire               reset,
    input  wire               habilita,
    input  wire [LARGURA-1:0] proximo_pc,
    output reg  [LARGURA-1:0] endereco_atual
);
    always @(posedge clk or posedge reset) begin
        if (reset)          endereco_atual <= ENDERECO_INICIAL;
        else if (habilita)  endereco_atual <= proximo_pc;
        // habilita = 0: mantem o valor
    end
endmodule
