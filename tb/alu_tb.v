`timescale 1ns/1ps
//  Testbench da alu — um caso por operacao, com valores do programa real.
module alu_tb;
    reg  [31:0] a, b;
    reg  [3:0]  alu_control;
    wire [31:0] result;
    wire        zero;

    alu #(.DATA_WIDTH(32)) dut (.a(a), .b(b), .alu_control(alu_control),
                                .result(result), .zero(zero));

    localparam OP_AND=4'b0000, OP_OR=4'b0001, OP_ADD=4'b0010,
               OP_SUB=4'b0110, OP_SLT=4'b0111, OP_SLL=4'b1000;

    integer erros = 0;

    task confere(input [31:0] x, input [31:0] y, input [3:0] ctrl,
                 input [31:0] esp_result, input esp_zero, input [80*8:1] nome);
        begin
            a = x; b = y; alu_control = ctrl; #1;
            if (result !== esp_result || zero !== esp_zero) begin
                $display("  ERRO  %0s: result=%0d (esp %0d) zero=%b (esp %b)",
                         nome, $signed(result), $signed(esp_result), zero, esp_zero);
                erros = erros + 1;
            end else
                $display("  ok    %-46s result=%0d zero=%b", nome, $signed(result), zero);
        end
    endtask

    initial begin
        $dumpfile("build/alu_tb.vcd"); $dumpvars(0, alu_tb);
        $display(""); $display("== alu ==");

        // ADD: aritmetica e calculo de endereco
        confere(1000, 40,  OP_ADD, 1040, 0, "add $t1,$a0,$t1");
        confere(1024, -20, OP_ADD, 1004, 0, "addi $sp,$sp,-20 (endereco da pilha)");
        confere(1004, 16,  OP_ADD, 1020, 0, "sw $ra,16($sp) (endereco)");

        // SUB: o que importa e o zero, nao o resultado
        confere(7, 7, OP_SUB, 0,  1, "beq: operandos iguais -> zero=1");
        confere(7, 3, OP_SUB, 4,  0, "beq: operandos diferentes -> zero=0");
        confere(0, 1, OP_SUB, -1, 0, "bne: $t0=0 vs 1 -> zero=0");

        // SLT: comparacao COM SINAL
        confere(3, 8, OP_SLT, 1, 0, "slt: 3 < 8");
        confere(8, 3, OP_SLT, 0, 1, "slt: 8 < 3 e falso");
        confere(-1, 0, OP_SLT, 1, 0, "slti: j = -1 < 0 (saida do laco interno)");
        confere(0,  0, OP_SLT, 0, 1, "slti: j = 0 nao e < 0");

        // SLL: desloca B pela quantidade em A (A traz o shamt)
        confere(2, 1, OP_SLL, 4,  0, "sll $t1,$a1,2 com k=1 -> 4 bytes");
        confere(2, 7, OP_SLL, 28, 0, "sll com k=7 -> 28 bytes (v[7])");
        confere(2, 0, OP_SLL, 0,  1, "sll com k=0 -> 0");

        // logicas
        confere(32'hFF00, 32'h0FF0, OP_AND, 32'h0F00, 0, "and");
        confere(32'hFF00, 32'h00FF, OP_OR,  32'hFFFF, 0, "or");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display(""); $finish;
    end
endmodule
