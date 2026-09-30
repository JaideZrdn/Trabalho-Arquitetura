// ============================================================================
//  Testbench de pc
//
//  Diferente do testbench do extensor de sinal, este precisa GERAR CLOCK —
//  o modulo sob teste e sequencial, entao nada acontece sem borda de subida.
//
//  A sequencia de teste imita o programa real: conta de 4 em 4, depois um
//  salto para 168 (o "main" do programa.asm), depois um desvio para tras
//  para 80 (o "for2tst"), e por fim um reset no meio da execucao.
//
//  COMO RODAR
//      iverilog -g2012 -o build/sim rtl/pc.v tb/pc_tb.v
//      ./build/sim
// ============================================================================
`timescale 1ns/1ps

module pc_tb;

    reg         clk = 0;
    reg         reset;
    reg  [31:0] proximo_pc;
    wire [31:0] endereco_atual;

    // ---- gerador de clock --------------------------------------------------
    // inverte a cada 5ns -> periodo de 10ns. Existe so no simulador; na FPGA
    // o clock vem de um pino fisico (um oscilador na placa).
    always #5 clk = ~clk;

    pc #(
        .LARGURA(32),
        .ENDERECO_INICIAL(0)
    ) dut (
        .clk(clk),
        .reset(reset),
        .proximo_pc(proximo_pc),
        .endereco_atual(endereco_atual)
    );

    // ---- segunda instancia, larguras diferentes: prova a parametrizacao ----
    reg  [15:0] proximo_pc_16;
    wire [15:0] endereco_16;

    pc #(
        .LARGURA(16),
        .ENDERECO_INICIAL(16'h0100)
    ) dut_16 (
        .clk(clk),
        .reset(reset),
        .proximo_pc(proximo_pc_16),
        .endereco_atual(endereco_16)
    );

    integer erros = 0;

    // avanca um ciclo e confere o valor que o PC passou a ter
    task ciclo(input [31:0] esperado, input [80*8:1] nome);
        begin
            @(posedge clk);
            #1;                 // deixa a atribuicao nao-bloqueante assentar
            if (endereco_atual !== esperado) begin
                $display("  ERRO  %0s: obtido=%0d esperado=%0d",
                         nome, endereco_atual, esperado);
                erros = erros + 1;
            end else
                $display("  ok    %-42s PC = %0d", nome, endereco_atual);
        end
    endtask

    initial begin
        $dumpfile("build/pc_tb.vcd");
        $dumpvars(0, pc_tb);

        $display("");
        $display("== pc: contagem, saltos e reset ==");

        // --- reset: o PC tem que ir para o endereco inicial ----------------
        reset         = 1;
        proximo_pc    = 32'd999;      // valor qualquer: o reset deve ignorar
        proximo_pc_16 = 16'd999;
        ciclo(0, "reset ativo -> endereco inicial");

        // --- contagem normal: quem soma 4 e a logica de fora ---------------
        reset = 0;
        proximo_pc = 4;    ciclo(4,   "PC+4  -> sll $t1,$a1,2");
        proximo_pc = 8;    ciclo(8,   "PC+4  -> add $t1,$a0,$t1");
        proximo_pc = 12;   ciclo(12,  "PC+4  -> lw $t2,0($t1)");

        // --- salto para frente: "j main" (main fica em 168) -----------------
        proximo_pc = 168;  ciclo(168, "j main -> salto para frente");

        // --- desvio para tras: "j for2tst" (for2tst fica em 80) -------------
        proximo_pc = 80;   ciclo(80,  "j for2tst -> desvio para tras");

        // --- halt: "j end" aponta para si mesmo -----------------------------
        proximo_pc = 248;  ciclo(248, "j end -> chega no halt");
        proximo_pc = 248;  ciclo(248, "j end -> continua parado (halt)");

        // --- reset no meio da execucao --------------------------------------
        reset = 1;         ciclo(0,   "reset no meio -> volta para 0");

        // --- confere a instancia parametrizada em 16 bits --------------------
        $display("");
        $display("== o MESMO modulo com LARGURA=16 e inicio em 0x0100 ==");
        if (endereco_16 !== 16'h0100) begin
            $display("  ERRO  instancia de 16 bits: obtido=%h esperado=0100", endereco_16);
            erros = erros + 1;
        end else
            $display("  ok    reset leva ao endereco inicial parametrizado  PC = 0x%h",
                     endereco_16);

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display("");
        $finish;
    end

endmodule
