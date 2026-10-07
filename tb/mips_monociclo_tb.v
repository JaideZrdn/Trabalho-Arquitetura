// ============================================================================
//  Testbench do processador completo
//
//  Carrega mem/programa.txt na memoria de instrucoes, solta o reset e deixa o
//  processador executar ate parar sozinho no laco `j end`. Depois confere o
//  vetor na memoria de dados.
//
//  Esta e a verificacao que vale: os testbenches de modulo provam que cada
//  peca funciona isolada; este prova que a FIACAO entre elas esta certa. Um
//  unico fio trocado aqui aparece como vetor desordenado.
//
//      iverilog -g2012 -o build/sim rtl/*.v tb/mips_monociclo_tb.v
//      ./build/sim
// ============================================================================
`timescale 1ns/1ps

module mips_monociclo_tb;

    reg         clk = 0;
    reg         reset;
    wire [31:0] pc_debug, instrucao_debug;
    reg  [31:0] endereco_debug = 0;
    wire [31:0] dado_debug;

    always #5 clk = ~clk;          // periodo de 10ns

    mips_monociclo #(
        .LARGURA(32), .PROF_INSTRUCOES(256), .PROF_DADOS(256),
        .ARQUIVO_PROGRAMA("mem/programa.txt")
    ) dut (
        .clk(clk), .reset(reset),
        .endereco_debug(endereco_debug), .dado_debug(dado_debug),
        .pc_debug(pc_debug), .instrucao_debug(instrucao_debug)
    );

    integer ciclos  = 0;
    integer erros   = 0;
    integer i;
    reg [31:0] pc_anterior;
    reg parado;

    // vetor de teste do programa e o resultado esperado
    localparam N = 8;
    reg [31:0] inicial  [0:N-1];
    reg [31:0] esperado [0:N-1];

    initial begin
        inicial[0]=5; inicial[1]=3; inicial[2]=8; inicial[3]=1;
        inicial[4]=9; inicial[5]=2; inicial[6]=7; inicial[7]=4;
        esperado[0]=1; esperado[1]=2; esperado[2]=3; esperado[3]=4;
        esperado[4]=5; esperado[5]=7; esperado[6]=8; esperado[7]=9;
    end

    initial begin
        $dumpfile("build/mips_monociclo_tb.vcd");
        $dumpvars(0, mips_monociclo_tb);

        $display("");
        $display("== processador completo executando mem/programa.txt ==");
        $write("   vetor inicial :");
        for (i = 0; i < N; i = i + 1) $write(" %0d", inicial[i]);
        $display("");

        // --- reset ----------------------------------------------------------
        reset = 1;
        @(posedge clk); #1;
        if (pc_debug !== 32'd0) begin
            $display("  ERRO  reset nao levou o PC a 0 (PC=%0d)", pc_debug);
            erros = erros + 1;
        end else
            $display("  ok    reset: PC = 0");
        reset = 0;

        // --- executa ate o laco de parada -----------------------------------
        parado = 0;
        pc_anterior = 32'hFFFF_FFFF;
        while (!parado && ciclos < 5000) begin
            pc_anterior = pc_debug;
            @(posedge clk); #1;
            ciclos = ciclos + 1;
            // `j end` aponta para si mesmo: quando o PC repete, parou
            if (pc_debug === pc_anterior) parado = 1;
        end

        if (!parado) begin
            $display("  ERRO  o programa nao parou em 5000 ciclos (PC=%0d)", pc_debug);
            erros = erros + 1;
        end else
            $display("  ok    parou no halt depois de %0d ciclos, PC = %0d", ciclos, pc_debug);

        // --- confere o vetor na memoria de dados ----------------------------
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

        // --- a pilha foi restaurada? $sp volta a 1024 apos o epilogo ---------
        if (dut.banco.registradores[29] !== 32'd1024) begin
            $display("  ERRO  $sp = %0d ao final, esperado 1024 (epilogo nao restaurou)",
                     $signed(dut.banco.registradores[29]));
            erros = erros + 1;
        end else
            $display("  ok    $sp restaurado em 1024 ao final do sort");

        // --- $zero continua zero? ------------------------------------------
        if (dut.banco.registradores[0] !== 32'd0) begin
            $display("  ERRO  $zero foi alterado: %0d", dut.banco.registradores[0]);
            erros = erros + 1;
        end else
            $display("  ok    $zero permanece 0");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display("");
        $finish;
    end

endmodule
