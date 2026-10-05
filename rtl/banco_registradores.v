// ============================================================================
//  banco_registradores — os 32 registradores do MIPS
//
//  OBJETIVO
//  Guardar os 32 registradores ($zero, $a0, $t1, $sp, $ra, ...), entregando
//  DOIS valores por ciclo para a ALU e gravando UM de volta no fim do ciclo.
//
//  POR QUE DUAS LEITURAS AO MESMO TEMPO
//  "add $t1, $a0, $t1" precisa de $a0 e $t1 simultaneamente — a ALU tem duas
//  entradas. Por isso sao duas portas de leitura independentes, cada uma com
//  seu proprio endereco e seu proprio barramento de saida.
//
//  LEITURA E ESCRITA TEM NATUREZAS DIFERENTES
//  - Leitura e COMBINACIONAL: o valor precisa estar disponivel no meio do
//    ciclo, para a ALU calcular a tempo. Nao pode esperar borda de clock.
//  - Escrita e SEQUENCIAL: so acontece na subida do clock, no fim do ciclo,
//    quando o resultado ja foi calculado.
//
//  O REGISTRADOR 0 E FIACAO, NAO CONVENCAO
//  $zero vale 0 sempre, por construcao: leitura do endereco 0 devolve zero, e
//  escrita no endereco 0 e descartada. Nao e um acordo entre programadores —
//  e hardware. O programa depende disso:
//      addi $s0, $zero, 0      <- "i = 0" so funciona porque $zero e 0
//      add  $s3, $a0, $zero    <- copia de registrador, sem instrucao "move"
// ============================================================================
`timescale 1ns/1ps

module banco_registradores #(
    parameter LARGURA = 32,     // largura de cada registrador
    parameter N_REGS  = 32      // quantidade de registradores
)(
    input  wire                        clk,
    input  wire                        escreve_reg,    // habilita a escrita
    input  wire [$clog2(N_REGS)-1:0]   reg_leitura_1,  // campo rs da instrucao
    input  wire [$clog2(N_REGS)-1:0]   reg_leitura_2,  // campo rt
    input  wire [$clog2(N_REGS)-1:0]   reg_escrita,    // rd, rt ou 31 (jal)
    input  wire [LARGURA-1:0]          dado_escrita,
    output wire [LARGURA-1:0]          dado_1,         // vai para a ALU
    output wire [LARGURA-1:0]          dado_2          // ALU ou memoria (sw)
);

    // $clog2(32) = 5 bits de endereco. Nao por acaso: e exatamente a largura
    // dos campos rs, rt e rd na instrucao.
    localparam BITS_REG = $clog2(N_REGS);

    reg [LARGURA-1:0] registradores [0:N_REGS-1];

    // Estado inicial. Em simulacao evita que tudo comece em 'x'; na FPGA da
    // Altera o initial vira o valor de power-up gravado no bitstream.
    integer i;
    initial begin
        for (i = 0; i < N_REGS; i = i + 1)
            registradores[i] = {LARGURA{1'b0}};
    end

    // ---- leitura: combinacional, e o endereco 0 sempre devolve zero --------
    assign dado_1 = (reg_leitura_1 == {BITS_REG{1'b0}})
                    ? {LARGURA{1'b0}}
                    : registradores[reg_leitura_1];

    assign dado_2 = (reg_leitura_2 == {BITS_REG{1'b0}})
                    ? {LARGURA{1'b0}}
                    : registradores[reg_leitura_2];

    // ---- escrita: so na subida do clock, e nunca no registrador 0 ----------
    always @(posedge clk) begin
        if (escreve_reg && reg_escrita != {BITS_REG{1'b0}})
            registradores[reg_escrita] <= dado_escrita;
    end

    // Nota para o monociclo: a escrita acontece no FIM do ciclo, entao uma
    // leitura feita no mesmo ciclo ainda ve o valor antigo. Isso esta correto
    // aqui — cada instrucao ocupa um ciclo inteiro. Quando o projeto virar
    // pipeline (3a entrega), esse detalhe reaparece como hazard de dados.

endmodule
