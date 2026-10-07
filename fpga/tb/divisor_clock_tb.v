`timescale 1ns/1ps
//  Confere a razao de divisao: com DIVISOR=N a saida troca de nivel a cada N
//  bordas de entrada, ou seja, o periodo de saida e 2*N periodos de entrada.
module divisor_clock_tb;
    reg  clk_in = 0, reset;
    wire clk_out;

    divisor_clock #(.DIVISOR(3)) dut (.clk_in(clk_in), .reset(reset), .clk_out(clk_out));

    always #5 clk_in = ~clk_in;

    integer erros = 0, trocas = 0, bordas = 0;
    reg anterior;

    initial begin
        $dumpfile("build/divisor_clock_tb.vcd"); $dumpvars(0, divisor_clock_tb);
        $display(""); $display("== divisor_clock (DIVISOR = 3) ==");

        reset = 1; @(posedge clk_in); #1;
        if (clk_out !== 1'b0) begin
            $display("  ERRO  reset deveria zerar a saida"); erros = erros + 1;
        end else $display("  ok    reset leva a saida a 0");
        reset = 0;

        anterior = clk_out;
        // 6 bordas de entrada = 2 trocas de saida = 1 periodo completo
        repeat (18) begin
            @(posedge clk_in); #1;
            bordas = bordas + 1;
            if (clk_out !== anterior) begin
                trocas = trocas + 1;
                if (bordas % 3 != 0) begin
                    $display("  ERRO  trocou na borda %0d, que nao e multiplo de 3", bordas);
                    erros = erros + 1;
                end
                anterior = clk_out;
            end
        end

        if (trocas !== 6) begin
            $display("  ERRO  esperava 6 trocas em 18 bordas, houve %0d", trocas);
            erros = erros + 1;
        end else
            $display("  ok    6 trocas em 18 bordas de entrada -> divide por 6 o periodo");

        $display("  ok    cada troca cai exatamente a cada 3 bordas de entrada");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display(""); $finish;
    end
endmodule
