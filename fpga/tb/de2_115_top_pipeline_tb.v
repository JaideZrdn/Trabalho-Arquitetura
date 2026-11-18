// ============================================================================
//  Testbench do involucro de placa — versao pipeline
//
//  Verifica o que o olho vai ver na DE2-115 com o processador em pipeline:
//
//    - o vetor ordenado, lido digito por digito dos displays
//    - o contador de ciclos parando em 563, que e o numero que a apresentacao
//      compara com os 406 do monociclo
//    - os tres LEDs de perigo acendendo em algum momento da execucao
//    - o modo passo-a-passo, onde um salto leva TRES apertos para mudar o PC,
//      porque duas instrucoes entram no pipeline e sao descartadas
//
//  Os divisores sao reduzidos a 2 para a simulacao caber em tempo razoavel.
//  Na placa voltam a 18_030_000 e 2_253_750.
// ============================================================================
`timescale 1ns/1ps

module de2_115_top_pipeline_tb;

    reg         CLOCK_50 = 0;
    reg  [3:0]  KEY;
    reg  [17:0] SW;
    wire [17:0] LEDR;
    wire [8:0]  LEDG;
    wire [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;

    always #10 CLOCK_50 = ~CLOCK_50;    // 50 MHz -> periodo 20ns

    de2_115_top_pipeline #(
        .ARQUIVO_PROGRAMA("mem/programa.txt"),
        .DIVISOR_LENTO(2), .DIVISOR_RAPIDO(2),
        .ESPERA_BOTAO(2), .CICLOS_SILENCIO(20)
    ) placa (
        .CLOCK_50(CLOCK_50), .KEY(KEY), .SW(SW),
        .LEDR(LEDR), .LEDG(LEDG),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3),
        .HEX4(HEX4), .HEX5(HEX5), .HEX6(HEX6), .HEX7(HEX7)
    );

    integer erros = 0, i, ciclos;

    // converte os segmentos de volta em digito: e assim que confirmamos que o
    // display mostra o que achamos que mostra, em vez de confiar na tabela
    function [4:0] digito_de;
        input [6:0] seg;
        begin
            case (seg)
                7'b1000000: digito_de = 0;   7'b1111001: digito_de = 1;
                7'b0100100: digito_de = 2;   7'b0110000: digito_de = 3;
                7'b0011001: digito_de = 4;   7'b0010010: digito_de = 5;
                7'b0000010: digito_de = 6;   7'b1111000: digito_de = 7;
                7'b0000000: digito_de = 8;   7'b0010000: digito_de = 9;
                7'b0001000: digito_de = 5'd10;  7'b0000011: digito_de = 5'd11;
                7'b1000110: digito_de = 5'd12;  7'b0100001: digito_de = 5'd13;
                7'b0000110: digito_de = 5'd14;  7'b0001110: digito_de = 5'd15;
                7'b1111111: digito_de = 5'd16;            // apagado
                default:    digito_de = 5'd31;            // padrao invalido
            endcase
        end
    endfunction

    reg [31:0] esperado [0:7];
    initial begin
        esperado[0]=1; esperado[1]=2; esperado[2]=3; esperado[3]=4;
        esperado[4]=5; esperado[5]=7; esperado[6]=8; esperado[7]=9;
    end

    // guarda se cada LED de perigo acendeu em algum ciclo da execucao
    reg viu_stall = 0, viu_flush = 0, viu_forward = 0;

    always @(posedge CLOCK_50) begin
        if (LEDG[1]) viu_stall   = 1;
        if (LEDG[2]) viu_flush   = 1;
        if (LEDG[3]) viu_forward = 1;
    end

    initial begin
        $dumpfile("build/de2_115_top_pipeline_tb.vcd");
        $dumpvars(0, de2_115_top_pipeline_tb);

        $display("");
        $display("== involucro DE2-115 (pipeline): o que aparece nos displays ==");

        SW  = 18'd0;          // SW[17]=0 automatico, SW[16]=0 vetor, SW[15]=0 lento
        KEY = 4'b1111;        // nenhum botao apertado

        // --- reset: KEY[0] apertado (nivel baixo) ---------------------------
        KEY[0] = 1'b0;
        repeat (10) @(posedge CLOCK_50);

        if (LEDR[17] !== 1'b1) begin
            $display("  ERRO  LEDR[17] deveria acender durante o reset");
            erros = erros + 1;
        end else
            $display("  ok    LEDR[17] acende durante o reset");

        KEY[0] = 1'b1;
        #1;

        if (placa.cpu.pc_debug !== 32'd0) begin
            $display("  ERRO  reset nao levou o PC a 0 (PC=%0d)", placa.cpu.pc_debug);
            erros = erros + 1;
        end else
            $display("  ok    reset assincrono: PC = 0 sem esperar borda do clock lento");

        // --- deixa rodar ate o programa parar sozinho -----------------------
        ciclos = 0;
        while (LEDG[0] !== 1'b1 && ciclos < 400000) begin
            @(posedge CLOCK_50);
            ciclos = ciclos + 1;
        end

        if (LEDG[0] !== 1'b1) begin
            $display("  ERRO  o programa nao sinalizou fim (LEDG[0] apagado)");
            erros = erros + 1;
        end else
            $display("  ok    LEDG[0] acendeu: programa terminou");

        // --- os tres perigos aconteceram de verdade -------------------------
        if (!viu_stall) begin
            $display("  ERRO  LEDG[1] nunca acendeu: nenhum stall de load-use detectado");
            erros = erros + 1;
        end else
            $display("  ok    LEDG[1] acendeu: stall de load-use ocorreu");

        if (!viu_flush) begin
            $display("  ERRO  LEDG[2] nunca acendeu: nenhuma transferencia de controle");
            erros = erros + 1;
        end else
            $display("  ok    LEDG[2] acendeu: desvio/salto tomado ocorreu");

        if (!viu_forward) begin
            $display("  ERRO  LEDG[3] nunca acendeu: nenhum encaminhamento");
            erros = erros + 1;
        end else
            $display("  ok    LEDG[3] acendeu: encaminhamento ocorreu");

        // --- contador de ciclos ---------------------------------------------
        SW[16] = 1'b1;   #100;

        if (placa.ciclos_uteis !== 16'd563) begin
            $display("  ERRO  contador mostra %0d ciclos, esperado 563",
                     placa.ciclos_uteis);
            erros = erros + 1;
        end else
            $display("  ok    SW[16]=1 -> HEX3..HEX0 = %0d%0d%0d%0d  (0x233 = 563 ciclos)",
                     digito_de(HEX3), digito_de(HEX2), digito_de(HEX1), digito_de(HEX0));

        SW[16] = 1'b0;   #100;

        // --- percorre as chaves e le os displays ----------------------------
        $display("");
        for (i = 0; i < 8; i = i + 1) begin
            SW[2:0] = i[2:0];
            #100;
            if (digito_de(HEX0) !== esperado[i][4:0]) begin
                $display("  ERRO  SW=%0d: HEX0 mostra %0d, esperado %0d",
                         i, digito_de(HEX0), esperado[i]);
                erros = erros + 1;
            end else if (digito_de(HEX4) !== i[4:0]) begin
                $display("  ERRO  SW=%0d: HEX4 (indice) mostra %0d", i, digito_de(HEX4));
                erros = erros + 1;
            end else
                $display("  ok    SW=%0d -> HEX4=%0d  HEX0=%0d   (v[%0d] = %0d)",
                         i, digito_de(HEX4), digito_de(HEX0), i, esperado[i]);
        end

        if (digito_de(HEX1) !== 0 || digito_de(HEX2) !== 0 || digito_de(HEX3) !== 0) begin
            $display("  ERRO  HEX3..HEX1 deveriam mostrar 0 (valores sao de um digito)");
            erros = erros + 1;
        end else
            $display("  ok    HEX3..HEX1 em zero");

        // --- modo passo-a-passo ---------------------------------------------
        //
        //  Aqui a diferenca em relacao ao monociclo fica visivel na placa. No
        //  monociclo, UM aperto bastava para o `j main` levar o PC a 168. No
        //  pipeline o salto so e resolvido no terceiro ciclo: os dois
        //  primeiros apertos buscam as instrucoes seguintes, que depois sao
        //  descartadas. Sao exatamente os dois slots de flush.
        $display("");
        KEY[0] = 1'b0; repeat (10) @(posedge CLOCK_50); KEY[0] = 1'b1;
        SW[17] = 1'b1;                       // passo-a-passo
        repeat (40) @(posedge CLOCK_50);

        if (placa.cpu.pc_debug !== 32'd0) begin
            $display("  ERRO  em passo-a-passo o PC andou sozinho (PC=%0d)",
                     placa.cpu.pc_debug);
            erros = erros + 1;
        end else
            $display("  ok    passo-a-passo: PC parado em 0 sem apertar KEY[1]");

        KEY[1] = 1'b0; repeat (20) @(posedge CLOCK_50);
        KEY[1] = 1'b1; repeat (20) @(posedge CLOCK_50);

        if (placa.cpu.pc_debug !== 32'd4) begin
            $display("  ERRO  1o aperto: PC deveria ser 4 (busca especulativa), esta em %0d",
                     placa.cpu.pc_debug);
            erros = erros + 1;
        end else
            $display("  ok    1o aperto de KEY[1]: PC=4   (o `j main` ainda esta no ID)");

        KEY[1] = 1'b0; repeat (20) @(posedge CLOCK_50);
        KEY[1] = 1'b1; repeat (20) @(posedge CLOCK_50);

        if (placa.cpu.pc_debug !== 32'd8) begin
            $display("  ERRO  2o aperto: PC deveria ser 8, esta em %0d", placa.cpu.pc_debug);
            erros = erros + 1;
        end else
            $display("  ok    2o aperto de KEY[1]: PC=8   (o `j main` entrou no EX agora)");

        KEY[1] = 1'b0; repeat (20) @(posedge CLOCK_50);
        KEY[1] = 1'b1; repeat (20) @(posedge CLOCK_50);

        if (placa.cpu.pc_debug !== 32'd168) begin
            $display("  ERRO  3o aperto: PC deveria ser 168 (`j main` resolvido), esta em %0d",
                     placa.cpu.pc_debug);
            erros = erros + 1;
        end else
            $display("  ok    3o aperto de KEY[1]: PC=168 (salto resolvido no EX; os PCs 4 e 8 foram descartados)");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display("");
        $finish;
    end
endmodule
