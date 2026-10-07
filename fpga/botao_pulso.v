// ============================================================================
//  botao_pulso — transforma um aperto de botao num unico pulso limpo
//
//  Botao mecanico "quica": um aperto gera dezenas de transicoes em poucos
//  milissegundos. Sem tratamento, um toque avancaria varias instrucoes de uma
//  vez e o passo-a-passo nao serviria para nada.
//
//  O filtro espera o sinal ficar estavel por ESPERA ciclos antes de aceitar a
//  mudanca, e so entao emite um pulso de um ciclo na borda de descida do
//  botao (os KEY da DE2-115 sao ativos em nivel BAIXO: apertado = 0).
// ============================================================================
`timescale 1ns/1ps

module botao_pulso #(
    parameter ESPERA = 500_000      // 10 ms a 50 MHz
)(
    input  wire clk,
    input  wire reset,
    input  wire botao_n,            // ativo em nivel baixo
    output reg  pulso
);
    wire pressionado = ~botao_n;
    reg [31:0] conta;
    reg estavel, anterior;

    always @(posedge clk) begin
        if (reset) begin
            conta <= 32'd0; estavel <= 1'b0; anterior <= 1'b0; pulso <= 1'b0;
        end else begin
            pulso <= 1'b0;

            if (pressionado != estavel) begin
                if (conta == ESPERA - 1) begin
                    estavel <= pressionado;
                    conta   <= 32'd0;
                end else
                    conta <= conta + 32'd1;
            end else
                conta <= 32'd0;

            anterior <= estavel;
            if (estavel && !anterior) pulso <= 1'b1;   // borda de aperto
        end
    end
endmodule
