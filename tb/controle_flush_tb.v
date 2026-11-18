`timescale 1ns/1ps
// Testbench do controle de flush.
// Cobre as seis situacoes: beq e bne nos dois resultados possiveis da
// comparacao, mais salto e retorno de funcao.
module controle_flush_tb;
    reg  branch_eq, branch_ne, jump, jr, zero;
    wire tomado, limpa_if_id, limpa_id_ex;

    controle_flush dut (
        .branch_eq(branch_eq), .branch_ne(branch_ne),
        .jump(jump), .jr(jr), .zero(zero),
        .tomado(tomado), .limpa_if_id(limpa_if_id), .limpa_id_ex(limpa_id_ex)
    );

    integer erros = 0;

    task confere(input esperado, input [80*8:1] nome);
        begin
            #1;
            if (tomado !== esperado || limpa_if_id !== esperado || limpa_id_ex !== esperado) begin
                $display("  ERRO  %0s: tomado=%b (esperado %b)", nome, tomado, esperado);
                erros = erros + 1;
            end else
                $display("  ok    %-50s tomado = %b", nome, tomado);
        end
    endtask

    initial begin
        $dumpfile("build/controle_flush_tb.vcd"); $dumpvars(0, controle_flush_tb);
        $display(""); $display("== controle_flush ==");

        branch_eq=0; branch_ne=0; jump=0; jr=0; zero=0;
        confere(1'b0, "instrucao comum: nada e descartado");

        branch_eq=1; branch_ne=0; jump=0; jr=0; zero=1;
        confere(1'b1, "beq com operandos iguais: desvia");

        branch_eq=1; zero=0;
        confere(1'b0, "beq com operandos diferentes: segue em frente");

        branch_eq=0; branch_ne=1; zero=0;
        confere(1'b1, "bne com operandos diferentes: desvia");

        branch_ne=1; zero=1;
        confere(1'b0, "bne com operandos iguais: segue em frente");

        branch_ne=0; jump=1; zero=0;
        confere(1'b1, "j / jal: sempre desvia");

        jump=0; jr=1;
        confere(1'b1, "jr: sempre desvia");

        // o zero nao pode influenciar um salto incondicional
        jr=1; zero=1;
        confere(1'b1, "jr nao depende do sinal zero");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display(""); $finish;
    end
endmodule
