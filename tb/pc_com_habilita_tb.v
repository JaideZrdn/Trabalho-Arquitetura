`timescale 1ns/1ps
// Testbench do PC com habilitacao — a diferenca em relacao ao do monociclo
// e justamente poder congelar, que e o que o stall de load-use usa.
module pc_com_habilita_tb;
    reg clk = 0, reset, habilita;
    reg  [31:0] proximo;
    wire [31:0] atual;

    pc_com_habilita #(.LARGURA(32), .ENDERECO_INICIAL(0)) dut (
        .clk(clk), .reset(reset), .habilita(habilita),
        .proximo_pc(proximo), .endereco_atual(atual)
    );

    always #5 clk = ~clk;
    integer erros = 0;

    task ciclo(input [31:0] esperado, input [80*8:1] nome);
        begin
            @(posedge clk); #1;
            if (atual !== esperado) begin
                $display("  ERRO  %0s: PC=%0d, esperado %0d", nome, atual, esperado);
                erros = erros + 1;
            end else
                $display("  ok    %-50s PC = %0d", nome, atual);
        end
    endtask

    initial begin
        $dumpfile("build/pc_com_habilita_tb.vcd"); $dumpvars(0, pc_com_habilita_tb);
        $display(""); $display("== pc_com_habilita ==");

        reset=1; habilita=1; proximo=32'd999;
        ciclo(32'd0, "reset leva o PC a 0");
        reset=0;

        proximo=32'd4;   ciclo(32'd4,   "avanca para 4");
        proximo=32'd8;   ciclo(32'd8,   "avanca para 8");

        habilita=0;
        proximo=32'd12;  ciclo(32'd8,   "STALL: congela em 8");
                         ciclo(32'd8,   "STALL: continua congelado");
        habilita=1;
                         ciclo(32'd12,  "fim do stall: avanca para 12");

        proximo=32'd168; ciclo(32'd168, "salto para main");
        proximo=32'd32;  ciclo(32'd32,  "salto para sort");

        reset=1;         ciclo(32'd0,   "reset no meio volta a 0");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display(""); $finish;
    end
endmodule
