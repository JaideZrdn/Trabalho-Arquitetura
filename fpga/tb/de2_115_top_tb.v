// ============================================================================
//  Testbench do invólucro de placa
//
//  Verifica o que o olho vai ver na DE2-115: percorre SW[2:0] e confere o
//  digito aceso em HEX0 para cada posicao do vetor. Tambem testa o modo
//  passo-a-passo pelo KEY[1].
//
//  O DIVISOR e reduzido a 2 para a simulacao caber em tempo razoavel. Na
//  placa ele volta a 25_000_000, que da 1 Hz.
// ============================================================================
`timescale 1ns/1ps

module de2_115_top_tb;

    reg         CLOCK_50 = 0;
    reg  [3:0]  KEY;
    reg  [17:0] SW;
    wire [17:0] LEDR;
    wire [8:0]  LEDG;
    wire [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;

    always #10 CLOCK_50 = ~CLOCK_50;    // 50 MHz -> periodo 20ns

    de2_115_top #(
        .ARQUIVO_PROGRAMA("mem/programa.txt"),
        .DIVISOR(2), .ESPERA_BOTAO(2)
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

    initial begin
        $dumpfile("build/de2_115_top_tb.vcd");
        $dumpvars(0, de2_115_top_tb);

        $display("");
        $display("== invólucro DE2-115: o que aparece nos displays ==");

        SW  = 18'd0;          // SW[17]=0 -> clock automatico
        KEY = 4'b1111;        // nenhum botao apertado

        // --- reset: KEY[0] apertado (nivel baixo) ---------------------------
        KEY[0] = 1'b0;
        repeat (10) @(posedge CLOCK_50);
        KEY[0] = 1'b1;

        // --- deixa rodar ate o programa parar sozinho -----------------------
        ciclos = 0;
        while (LEDG[0] !== 1'b1 && ciclos < 200000) begin
            @(posedge CLOCK_50);
            ciclos = ciclos + 1;
        end

        if (LEDG[0] !== 1'b1) begin
            $display("  ERRO  o programa nao sinalizou fim (LEDG[0] apagado)");
            erros = erros + 1;
        end else
            $display("  ok    LEDG[0] acendeu: programa terminou");

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

        // --- digitos altos do valor devem estar em zero ---------------------
        if (digito_de(HEX1) !== 0 || digito_de(HEX2) !== 0 || digito_de(HEX3) !== 0) begin
            $display("  ERRO  HEX3..HEX1 deveriam mostrar 0 (valores sao de um digito)");
            erros = erros + 1;
        end else
            $display("  ok    HEX3..HEX1 em zero, HEX5 apagado (%0d)", digito_de(HEX5));

        // --- modo passo-a-passo ---------------------------------------------
        $display("");
        KEY[0] = 1'b0; repeat (10) @(posedge CLOCK_50); KEY[0] = 1'b1;
        SW[17] = 1'b1;                       // passo-a-passo
        repeat (20) @(posedge CLOCK_50);

        if (placa.cpu.pc_debug !== 32'd0) begin
            $display("  ERRO  em passo-a-passo o PC andou sozinho (PC=%0d)", placa.cpu.pc_debug);
            erros = erros + 1;
        end else
            $display("  ok    passo-a-passo: PC parado em 0 sem apertar KEY[1]");

        KEY[1] = 1'b0; repeat (20) @(posedge CLOCK_50);
        KEY[1] = 1'b1; repeat (20) @(posedge CLOCK_50);

        // a primeira instrucao e "j main", que leva o PC para 168
        if (placa.cpu.pc_debug !== 32'd168) begin
            $display("  ERRO  apos um aperto o PC deveria estar em 168 (j main), esta em %0d",
                     placa.cpu.pc_debug);
            erros = erros + 1;
        end else
            $display("  ok    um aperto de KEY[1] executou exatamente uma instrucao (j main -> PC=168)");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display("");
        $finish;
    end
endmodule
