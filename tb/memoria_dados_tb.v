// ============================================================================
//  Testbench de memoria_dados
//
//  Exercita as duas regioes que o programa realmente usa: o vetor (palavras
//  0 a 7) e a pilha (palavras 251 a 255), com os mesmos enderecos que o
//  sort/swap produzem.
//
//      iverilog -g2012 -o build/sim rtl/memoria_dados.v tb/memoria_dados_tb.v
//      ./build/sim
// ============================================================================
`timescale 1ns/1ps

module memoria_dados_tb;

    reg         clk = 0;
    reg         escreve_mem;
    reg  [31:0] endereco, dado_escrita, endereco_debug;
    wire [31:0] dado_leitura, dado_debug;

    always #5 clk = ~clk;

    memoria_dados #(.LARGURA(32), .PROFUNDIDADE(256)) dut (
        .clk(clk), .escreve_mem(escreve_mem),
        .endereco(endereco), .dado_escrita(dado_escrita),
        .dado_leitura(dado_leitura),
        .endereco_debug(endereco_debug), .dado_debug(dado_debug)
    );

    integer erros = 0;

    task sw(input [31:0] end_bytes, input [31:0] valor);   // imita um "sw"
        begin
            endereco = end_bytes; dado_escrita = valor; escreve_mem = 1;
            @(posedge clk); #1;
            escreve_mem = 0;
        end
    endtask

    task lw(input [31:0] end_bytes, input [31:0] esperado, input [80*8:1] nome);
        begin
            endereco = end_bytes; #1;                      // imita um "lw"
            if (dado_leitura !== esperado) begin
                $display("  ERRO  %0s: end=%0d obtido=%0d esperado=%0d",
                         nome, end_bytes, $signed(dado_leitura), $signed(esperado));
                erros = erros + 1;
            end else
                $display("  ok    %-46s end=%0d -> %0d",
                         nome, end_bytes, $signed(dado_leitura));
        end
    endtask

    initial begin
        $dumpfile("build/memoria_dados_tb.vcd");
        $dumpvars(0, memoria_dados_tb);
        escreve_mem = 0; endereco_debug = 0;

        $display("");
        $display("== memoria_dados ==");

        lw(0, 0, "comeca zerada");

        // --- o vetor de teste, como o main grava ---------------------------
        sw(0,  5);  sw(4,  3);  sw(8,  8);  sw(12, 1);
        sw(16, 9);  sw(20, 2);  sw(24, 7);  sw(28, 4);
        lw(0,  5, "v[0] = 5");
        lw(12, 1, "v[3] = 1");
        lw(28, 4, "v[7] = 4 (topo do vetor)");

        // --- a troca que o swap faz: v[0] <-> v[1] ---------------------------
        sw(0, 3); sw(4, 5);
        lw(0, 3, "apos swap(v,0): v[0] = 3");
        lw(4, 5, "apos swap(v,0): v[1] = 5");

        // --- a pilha: enderecos reais do prologo do sort ---------------------
        // $sp = 1024 - 20 = 1004;  sw $s0,0($sp) ... sw $ra,16($sp)
        sw(1004, 32'd111);  // $s0
        sw(1008, 32'd222);  // $s1
        sw(1012, 32'd333);  // $s2
        sw(1016, 32'd444);  // $s3
        sw(1020, 32'd172);  // $ra
        lw(1004, 111, "pilha: $s0 em 0($sp)");
        lw(1020, 172, "pilha: $ra em 16($sp), endereco mais alto usado");

        // --- o vetor continua intacto: pilha e vetor nao se tocam ------------
        lw(0,  3, "vetor intacto depois de usar a pilha");
        lw(28, 4, "vetor intacto no topo");

        // --- escreve_mem = 0 nao grava (todo ciclo que nao e sw) -------------
        endereco = 8; dado_escrita = 32'hDEAD_BEEF; escreve_mem = 0;
        @(posedge clk); #1;
        lw(8, 8, "escreve_mem=0 nao altera a memoria");

        endereco = 0; endereco_debug = 28; #1;
        if (dado_debug !== 32'd4) begin
            $display("  ERRO  porta de debug: end=28 deu %0d, esperado 4", $signed(dado_debug));
            erros = erros + 1;
        end else
            $display("  ok    %-46s end=28 -> %0d", "porta de debug, endereco independente", $signed(dado_debug));

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display("");
        $finish;
    end

endmodule
