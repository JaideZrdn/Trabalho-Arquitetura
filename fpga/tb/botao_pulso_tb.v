`timescale 1ns/1ps
//  O ponto deste modulo e o repique: um aperto mecanico gera dezenas de
//  transicoes. O teste simula esse repique e exige UM unico pulso.
module botao_pulso_tb;
    reg  clk = 0, reset, botao_n;
    wire pulso;

    botao_pulso #(.ESPERA(4)) dut (.clk(clk), .reset(reset), .botao_n(botao_n), .pulso(pulso));

    always #5 clk = ~clk;

    integer erros = 0, pulsos = 0, i;

    // conta pulsos o tempo todo
    always @(posedge clk) if (pulso) pulsos = pulsos + 1;

    initial begin
        $dumpfile("build/botao_pulso_tb.vcd"); $dumpvars(0, botao_pulso_tb);
        $display(""); $display("== botao_pulso (filtro de repique) ==");

        reset = 1; botao_n = 1; repeat (3) @(posedge clk); reset = 0;
        repeat (5) @(posedge clk);

        if (pulsos != 0) begin
            $display("  ERRO  houve pulso sem apertar nada"); erros = erros + 1;
        end else $display("  ok    botao solto nao gera pulso");

        // --- aperto COM REPIQUE: oscila antes de estabilizar ----------------
        for (i = 0; i < 6; i = i + 1) begin
            botao_n = 0; @(posedge clk);
            botao_n = 1; @(posedge clk);
        end
        botao_n = 0;                       // finalmente estabiliza apertado
        repeat (20) @(posedge clk);

        if (pulsos != 1) begin
            $display("  ERRO  um aperto com repique gerou %0d pulso(s), esperado 1", pulsos);
            erros = erros + 1;
        end else
            $display("  ok    aperto com 6 repiques -> exatamente 1 pulso");

        // --- segurar o botao nao gera pulsos extras -------------------------
        repeat (40) @(posedge clk);
        if (pulsos != 1) begin
            $display("  ERRO  segurar o botao gerou pulso extra (total %0d)", pulsos);
            erros = erros + 1;
        end else
            $display("  ok    segurar o botao nao repete o pulso");

        // --- soltar e apertar de novo gera o segundo pulso ------------------
        botao_n = 1; repeat (20) @(posedge clk);
        botao_n = 0; repeat (20) @(posedge clk);
        if (pulsos != 2) begin
            $display("  ERRO  segundo aperto: total de %0d pulsos, esperado 2", pulsos);
            erros = erros + 1;
        end else
            $display("  ok    segundo aperto gera o segundo pulso");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display(""); $finish;
    end
endmodule
