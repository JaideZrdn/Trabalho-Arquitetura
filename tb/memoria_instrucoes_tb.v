// ============================================================================
//  Testbench de memoria_instrucoes
//
//  Confere que o endereco vindo do PC devolve a instrucao certa do
//  mem/programa.txt. Os valores esperados sao os binarios que o nosso proprio
//  montador gerou — se a conversao byte->palavra estiver errada, nao batem.
//
//  Rodar a partir da RAIZ do repositorio (o caminho do arquivo e relativo):
//      iverilog -g2012 -o build/sim rtl/memoria_instrucoes.v tb/memoria_instrucoes_tb.v
//      ./build/sim
// ============================================================================
`timescale 1ns/1ps

module memoria_instrucoes_tb;

    reg  [31:0] endereco;
    wire [31:0] instrucao;

    memoria_instrucoes #(
        .LARGURA(32), .PROFUNDIDADE(256), .ARQUIVO("mem/programa.txt")
    ) dut (.endereco(endereco), .instrucao(instrucao));

    integer erros = 0;

    task confere(input [31:0] pc, input [31:0] esperado, input [80*8:1] nome);
        begin
            endereco = pc; #1;
            if (instrucao !== esperado) begin
                $display("  ERRO  %0s (PC=%0d)", nome, pc);
                $display("        obtido   = %b", instrucao);
                $display("        esperado = %b", esperado);
                erros = erros + 1;
            end else
                $display("  ok    PC=%-4d  %-30s %b", pc, nome, instrucao);
        end
    endtask

    initial begin
        $dumpfile("build/memoria_instrucoes_tb.vcd");
        $dumpvars(0, memoria_instrucoes_tb);

        $display("");
        $display("== memoria_instrucoes lendo mem/programa.txt ==");

        confere(0,   32'b00001000000000000000000000101010, "j main");
        confere(4,   32'b00000000000001010100100010000000, "sll $t1,$a1,2");
        confere(8,   32'b00000000100010010100100000100000, "add $t1,$a0,$t1");
        confere(12,  32'b10001101001010100000000000000000, "lw $t2,0($t1)");
        confere(164, 32'b00000011111000000000000000001000, "jr $ra");

        // o PC nunca para no meio de uma palavra, mas se parasse: os 2 bits
        // de baixo sao descartados, entao 13, 14 e 15 dao a mesma de 12
        confere(13,  32'b10001101001010100000000000000000, "PC=13 cai na palavra 3");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display("");
        $finish;
    end

endmodule
