`timescale 1ns/1ps
// Testbench do registrador IF/ID.
// Alem do carregamento normal, testa as duas situacoes que o pipeline usa:
// congelar (stall de load-use) e descartar (flush de desvio).
module reg_if_id_tb;
    reg clk = 0, reset, habilita, limpa;
    reg  [31:0] instrucao_in, pc_plus_4_in;
    wire [31:0] instrucao_out, pc_plus_4_out;

    reg_if_id #(.LARGURA(32)) dut (
        .clk(clk), .reset(reset), .habilita(habilita), .limpa(limpa),
        .instrucao_in(instrucao_in), .pc_plus_4_in(pc_plus_4_in),
        .instrucao_out(instrucao_out), .pc_plus_4_out(pc_plus_4_out)
    );

    always #5 clk = ~clk;
    integer erros = 0;

    task ciclo(input [31:0] esp_instr, input [31:0] esp_pc, input [80*8:1] nome);
        begin
            @(posedge clk); #1;
            if (instrucao_out !== esp_instr || pc_plus_4_out !== esp_pc) begin
                $display("  ERRO  %0s", nome);
                $display("        instrucao = %h (esperado %h) | pc+4 = %0d (esperado %0d)",
                         instrucao_out, esp_instr, pc_plus_4_out, esp_pc);
                erros = erros + 1;
            end else
                $display("  ok    %-46s instr=%h pc+4=%0d", nome, instrucao_out, pc_plus_4_out);
        end
    endtask

    initial begin
        $dumpfile("build/reg_if_id_tb.vcd"); $dumpvars(0, reg_if_id_tb);
        $display(""); $display("== reg_if_id ==");

        reset = 1; habilita = 1; limpa = 0;
        instrucao_in = 32'hDEADBEEF; pc_plus_4_in = 32'd999;
        ciclo(32'h0, 32'd0, "reset zera as duas saidas");
        reset = 0;

        // instrucoes reais do programa: "sll $t1,$a1,2" esta em PC=4
        instrucao_in = 32'h00054880; pc_plus_4_in = 32'd8;
        ciclo(32'h00054880, 32'd8, "carrega sll $t1,$a1,2 (PC+4 = 8)");

        instrucao_in = 32'h00894820; pc_plus_4_in = 32'd12;
        ciclo(32'h00894820, 32'd12, "carrega add $t1,$a0,$t1 (PC+4 = 12)");

        // --- stall: habilita = 0 congela ------------------------------------
        habilita = 0;
        instrucao_in = 32'hAAAAAAAA; pc_plus_4_in = 32'd16;
        ciclo(32'h00894820, 32'd12, "stall: segura a instrucao anterior");
        ciclo(32'h00894820, 32'd12, "stall: continua segurando no 2o ciclo");

        habilita = 1;
        ciclo(32'hAAAAAAAA, 32'd16, "fim do stall: volta a carregar");

        // --- flush: limpa = 1 descarta --------------------------------------
        limpa = 1;
        instrucao_in = 32'hBBBBBBBB; pc_plus_4_in = 32'd20;
        ciclo(32'h0, 32'd0, "flush: instrucao descartada vira nop");
        limpa = 0;

        instrucao_in = 32'hCCCCCCCC; pc_plus_4_in = 32'd24;
        ciclo(32'hCCCCCCCC, 32'd24, "apos o flush volta ao normal");

        // --- os dois ao mesmo tempo: stall tem prioridade --------------------
        habilita = 0; limpa = 1;
        instrucao_in = 32'hEEEEEEEE; pc_plus_4_in = 32'd28;
        ciclo(32'hCCCCCCCC, 32'd24, "stall + flush juntos: o stall vence");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display(""); $finish;
    end
endmodule
