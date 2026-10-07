// ============================================================================
//  pc — Program Counter (contador de programa)
//
//  OBJETIVO
//  Guardar o endereco da instrucao que esta sendo executada agora, e trocar
//  esse endereco por um novo a cada subida do clock.
//
//  O QUE ELE E
//  Um registrador de LARGURA bits. So isso. Nao calcula nada: quem decide o
//  proximo endereco e a logica de fora (somador de PC+4, logica de branch,
//  logica de jump). O pc apenas SEGURA o valor entre um ciclo e outro.
//
//      PC = 0    -> executando "j main"
//      PC = 4    -> executando "sll $t1, $a1, 2"
//      PC = 8    -> executando "add $t1, $a0, $t1"
//
//  POR QUE ELE PRECISA DE CLOCK
//  Durante o ciclo inteiro o endereco tem que ficar firme, enquanto a memoria
//  de instrucoes busca, o banco de registradores le e a ALU calcula. Se ele
//  mudasse no meio do ciclo, a instrucao seria buscada pela metade. O clock
//  define o unico instante em que a troca pode acontecer.
//
//  Este e o primeiro bloco SEQUENCIAL do projeto: diferente do extensor de
//  sinal, ele tem memoria — lembra do valor entre ciclos.
// ============================================================================
`timescale 1ns/1ps

module pc #(
    parameter LARGURA           = 32,
    parameter ENDERECO_INICIAL  = 0     // no boot o MIPS comeca no endereco 0
)(
    input  wire                clk,             // clock do processador
    input  wire                reset,           // volta ao endereco inicial
    input  wire [LARGURA-1:0]  proximo_pc,      // calculado fora deste modulo
    output reg  [LARGURA-1:0]  endereco_atual   // reg, porque guarda estado
);

    // Reset ASSINCRONO: age no instante em que o sinal sobe, sem esperar
    // borda de clock.
    //
    // Por que nao sincrono: na placa o clock do processador e derivado — ou
    // dividido para 1 Hz, ou gerado por um botao no modo passo-a-passo.
    // Enquanto o reset esta apertado o clock pode simplesmente nao ter
    // nenhuma borda, e um reset sincrono nunca chegaria a agir: o PC ficaria
    // indefinido e todo o datapath propagaria x. Foi exatamente isso que o
    // testbench do involucro de placa pegou.
    always @(posedge clk or posedge reset) begin
        if (reset)
            endereco_atual <= ENDERECO_INICIAL;
        else
            endereco_atual <= proximo_pc;
    end

    // O operador <= (atribuicao nao-bloqueante) e o que se usa dentro de
    // always @(posedge clk). Ele significa: "no fim desta borda, o registrador
    // passa a valer isto". Todos os registradores do processador atualizam
    // juntos, e nao um depois do outro.

endmodule
