// ============================================================================
//  Testbench do processador em pipeline
//
//  Executa o mesmo programa do monociclo e confere o vetor ordenado. Mede
//  tambem a contagem de ciclos, que no pipeline e maior que o numero de
//  instrucoes por causa dos stalls e dos descartes de desvio.
// ============================================================================
`timescale 1ns/1ps

module mips_pipeline_tb;

    reg         clk = 0;
    reg         reset;
    reg  [31:0] endereco_debug = 0;
    wire [31:0] dado_debug, pc_debug, instrucao_debug;

    always #5 clk = ~clk;

    mips_pipeline #(
        .LARGURA(32), .PROF_INSTRUCOES(256), .PROF_DADOS(256),
        .ARQUIVO_PROGRAMA("mem/programa.txt")
    ) dut (
        .clk(clk), .reset(reset),
        .endereco_debug(endereco_debug), .dado_debug(dado_debug),
        .pc_debug(pc_debug), .instrucao_debug(instrucao_debug)
    );

    integer ciclos = 0, erros = 0, i;
    reg chegou_no_fim;
    integer parado;

    localparam N = 8;
    reg [31:0] esperado [0:N-1];
    initial begin
        esperado[0]=1; esperado[1]=2; esperado[2]=3; esperado[3]=4;
        esperado[4]=5; esperado[5]=7; esperado[6]=8; esperado[7]=9;
    end

    initial begin
        $dumpfile("build/mips_pipeline_tb.vcd");
        $dumpvars(0, mips_pipeline_tb);

        $display("");
        $display("== pipeline de 5 estagios executando mem/programa.txt ==");
        $write("   vetor inicial :");
        for (i = 0; i < N; i = i + 1) $write(" %0d", esperado[i]);
        $display("   (embaralhado: 5 3 8 1 9 2 7 4)");

        reset = 1;
        @(posedge clk); #1;
        if (pc_debug !== 32'd0) begin
            $display("  ERRO  reset nao levou o PC a 0 (PC=%0d)", pc_debug);
            erros = erros + 1;
        end else
            $display("  ok    reset: PC = 0");
        reset = 0;

        // Nao da para detectar o fim pelo PC: ele PASSA por 248 de forma
        // especulativa enquanto o "jal sort" ainda esta em voo. O criterio
        // confiavel e outro — o programa terminou quando para de escrever,
        // porque o laco final so salta para si mesmo.
        chegou_no_fim = 0;
        parado = 0;
        while (!chegou_no_fim && ciclos < 20000) begin
            @(posedge clk); #1;
            ciclos = ciclos + 1;
            // Escrita no registrador 0 nao conta: o banco a descarta. Ela
            // aparece porque o pipeline busca especulativamente alem do fim
            // do programa, e essas instrucoes de lixo chegam ao WB.
            if ((dut.wb_reg_write && dut.wb_destino != 5'd0) || dut.mem_mem_write)
                parado = 0;
            else                                       parado = parado + 1;
            if (parado >= 20) chegou_no_fim = 1;
        end

        if (!chegou_no_fim) begin
            $display("  ERRO  o programa nao terminou em 20000 ciclos (PC=%0d)", pc_debug);
            erros = erros + 1;
        end else begin
            ciclos = ciclos - 20;      // desconta a janela de silencio
            $display("  ok    ultima escrita no ciclo %0d", ciclos);
        end

        // deixa o pipeline drenar as ultimas instrucoes em voo
        repeat (6) @(posedge clk);
        #1;

        $write("   vetor final   :");
        for (i = 0; i < N; i = i + 1) $write(" %0d", dut.mem_dados.memoria[i]);
        $display("");
        $display("   esperado      : 1 2 3 4 5 7 8 9");
        $display("");

        for (i = 0; i < N; i = i + 1) begin
            if (dut.mem_dados.memoria[i] !== esperado[i]) begin
                $display("  ERRO  v[%0d] = %0d, esperado %0d",
                         i, $signed(dut.mem_dados.memoria[i]), $signed(esperado[i]));
                erros = erros + 1;
            end else
                $display("  ok    v[%0d] = %0d", i, $signed(dut.mem_dados.memoria[i]));
        end

        if (dut.banco.registradores[29] !== 32'd1024) begin
            $display("  ERRO  $sp = %0d ao final, esperado 1024",
                     $signed(dut.banco.registradores[29]));
            erros = erros + 1;
        end else
            $display("  ok    $sp restaurado em 1024");

        if (dut.banco.registradores[0] !== 32'd0) begin
            $display("  ERRO  $zero foi alterado: %0d", dut.banco.registradores[0]);
            erros = erros + 1;
        end else
            $display("  ok    $zero permanece 0");

        $display("");
        $display("   monociclo: 406 ciclos   |   pipeline: %0d ciclos", ciclos);
        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display("");
        $finish;
    end

endmodule
