`timescale 1ns/1ps
//  Testbench de somador — os casos sao os dois usos reais no datapath.
module somador_tb;

    reg  [31:0] a, b;
    wire [31:0] soma;

    somador #(.LARGURA(32)) dut (.a(a), .b(b), .soma(soma));

    // segunda instancia, outra largura: prova a parametrizacao (rubrica 4)
    reg  [15:0] a16, b16;
    wire [15:0] soma16;
    somador #(.LARGURA(16)) dut16 (.a(a16), .b(b16), .soma(soma16));

    integer erros = 0;

    task confere(input [31:0] x, input [31:0] y, input [31:0] esperado,
                 input [80*8:1] nome);
        begin
            a = x; b = y; #1;
            if (soma !== esperado) begin
                $display("  ERRO  %0s: %0d + %0d = %0d, esperado %0d",
                         nome, $signed(a), $signed(b), $signed(soma), $signed(esperado));
                erros = erros + 1;
            end else
                $display("  ok    %-44s %0d + %0d = %0d",
                         nome, $signed(a), $signed(b), $signed(soma));
        end
    endtask

    initial begin
        $dumpfile("build/somador_tb.vcd");
        $dumpvars(0, somador_tb);
        $display("");
        $display("== somador ==");

        // --- uso 1: PC+4, percorrendo o inicio do programa real ------------
        confere(0,   4, 4,   "PC+4: j main     -> proxima");
        confere(4,   4, 8,   "PC+4: sll        -> proxima");
        confere(164, 4, 168, "PC+4: jr $ra     -> main");
        confere(244, 4, 248, "PC+4: ultima instrucao do programa");

        // --- uso 2: destino de desvio = PC+4 + imediato*4 -------------------
        // beq $t0,$zero,exit1 esta em PC=72, imediato +16 -> 76 + 64 = 140
        confere(76,  64,  140, "desvio: beq em 72, imm +16 -> exit1 (140)");
        // bne $t0,$zero,exit2 esta em PC=84, imediato +11 -> 88 + 44 = 132
        confere(88,  44,  132, "desvio: bne em 84, imm +11 -> exit2 (132)");

        // --- imediato negativo: desvio para tras ----------------------------
        confere(100, -40, 60, "desvio para tras com imediato negativo");

        // --- borda: estouro da largura e descartado -------------------------
        confere(32'hFFFF_FFFF, 1, 32'h0000_0000, "estouro: volta a zero (ignorado)");

        // --- instancia de 16 bits -------------------------------------------
        a16 = 16'd1000; b16 = 16'd24; #1;
        if (soma16 !== 16'd1024) begin
            $display("  ERRO  instancia de 16 bits: %0d", soma16);
            erros = erros + 1;
        end else
            $display("  ok    %-44s %0d + %0d = %0d",
                     "LARGURA=16: 1000 + 24", a16, b16, soma16);

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display("");
        $finish;
    end
endmodule
