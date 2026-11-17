// ============================================================================
//  Testbench de banco_registradores
//
//  Os casos saem do programa real: escreve em $t1, $sp e $ra, le pares como
//  "add $t1, $a0, $t1", e confere que $zero resiste a escrita.
//
//      iverilog -g2012 -o build/sim rtl/banco_registradores.v tb/banco_registradores_tb.v
//      ./build/sim
// ============================================================================
`timescale 1ns/1ps

module banco_registradores_tb;

    // nomes dos registradores, para o teste ficar legivel
    localparam ZERO = 5'd0,  A0 = 5'd4,  A1 = 5'd5,
               T0   = 5'd8,  T1 = 5'd9,  S0 = 5'd16,
               SP   = 5'd29, RA = 5'd31;

    reg         clk = 0;
    reg         escreve_reg;
    reg  [4:0]  reg_leitura_1, reg_leitura_2, reg_escrita;
    reg  [31:0] dado_escrita;
    wire [31:0] dado_1, dado_2;

    always #5 clk = ~clk;

    banco_registradores #(.LARGURA(32), .N_REGS(32)) dut (
        .clk(clk), .escreve_reg(escreve_reg),
        .reg_leitura_1(reg_leitura_1), .reg_leitura_2(reg_leitura_2),
        .reg_escrita(reg_escrita), .dado_escrita(dado_escrita),
        .dado_1(dado_1), .dado_2(dado_2)
    );

    // ---- segunda instancia, em modo write-first (BYPASS = 1) --------------
    // E assim que ele sera usado no pipeline: a instrucao no estagio WB grava
    // enquanto outra, tres estagios atras, le o mesmo registrador.
    reg  [4:0]  bp_leitura_1, bp_escrita;
    reg  [31:0] bp_dado;
    reg         bp_habilita;
    wire [31:0] bp_saida_1, bp_saida_2;

    banco_registradores #(.LARGURA(32), .N_REGS(32), .BYPASS(1)) dut_bypass (
        .clk(clk), .escreve_reg(bp_habilita),
        .reg_leitura_1(bp_leitura_1), .reg_leitura_2(5'd0),
        .reg_escrita(bp_escrita), .dado_escrita(bp_dado),
        .dado_1(bp_saida_1), .dado_2(bp_saida_2)
    );

    integer erros = 0;

    // grava um valor num registrador (um ciclo de clock)
    task escreve(input [4:0] endereco, input [31:0] valor);
        begin
            reg_escrita = endereco;
            dado_escrita = valor;
            escreve_reg = 1;
            @(posedge clk); #1;
            escreve_reg = 0;
        end
    endtask

    // le os dois registradores e confere os dois valores (sem clock: e combinacional)
    task le_e_confere(input [4:0] r1, input [4:0] r2,
                      input [31:0] esp1, input [31:0] esp2,
                      input [80*8:1] nome);
        begin
            reg_leitura_1 = r1;
            reg_leitura_2 = r2;
            #1;
            if (dado_1 !== esp1 || dado_2 !== esp2) begin
                $display("  ERRO  %0s", nome);
                $display("        dado_1 = %0d (esperado %0d) | dado_2 = %0d (esperado %0d)",
                         $signed(dado_1), $signed(esp1), $signed(dado_2), $signed(esp2));
                erros = erros + 1;
            end else
                $display("  ok    %-44s %0d , %0d", nome, $signed(dado_1), $signed(dado_2));
        end
    endtask

    initial begin
        $dumpfile("build/banco_registradores_tb.vcd");
        $dumpvars(0, banco_registradores_tb);
        escreve_reg = 0; reg_leitura_1 = 0; reg_leitura_2 = 0;
        bp_habilita = 0; bp_leitura_1 = 0; bp_escrita = 0; bp_dado = 0;

        $display("");
        $display("== banco_registradores ==");

        // --- tudo comeca zerado --------------------------------------------
        le_e_confere(T0, T1, 0, 0, "estado inicial: tudo zerado");

        // --- escrita e leitura basicas --------------------------------------
        escreve(A0, 32'd1000);            // v = endereco do vetor
        escreve(A1, 32'd8);               // n = 8
        le_e_confere(A0, A1, 1000, 8, "sort(v,n): $a0=1000, $a1=8");

        // --- duas leituras do MESMO registrador ao mesmo tempo --------------
        escreve(T1, 32'd40);
        le_e_confere(T1, T1, 40, 40, "mesmo registrador nas duas portas");

        // --- o par de leitura de uma instrucao real --------------------------
        le_e_confere(A0, T1, 1000, 40, "add $t1,$a0,$t1 le $a0 e $t1");

        // --- $sp e $ra, usados pelo prologo do sort --------------------------
        escreve(SP, 32'd1024);
        escreve(RA, 32'd172);
        le_e_confere(SP, RA, 1024, 172, "$sp=1024 e $ra=172 (retorno do jal)");

        // --- $zero: leitura sempre zero -------------------------------------
        le_e_confere(ZERO, A0, 0, 1000, "$zero devolve 0 na leitura");

        // --- $zero: escrita e DESCARTADA ------------------------------------
        escreve(ZERO, 32'hDEAD_BEEF);
        le_e_confere(ZERO, ZERO, 0, 0, "escrita em $zero nao tem efeito");

        // --- escreve_reg desligado nao grava nada ----------------------------
        reg_escrita = S0; dado_escrita = 32'd777; escreve_reg = 0;
        @(posedge clk); #1;
        le_e_confere(S0, A0, 0, 1000, "escreve_reg=0 nao grava (lw sem WB)");

        // --- sobrescrever um registrador ja usado ----------------------------
        escreve(A0, 32'd0);
        le_e_confere(A0, A1, 0, 8, "sobrescrita de $a0");

        // ===== modo write-first, para o pipeline ============================
        $display("");
        $display("== o MESMO banco com BYPASS = 1 (modo pipeline) ==");

        // grava 777 em $s0 de verdade, com o bypass desligado da leitura
        bp_habilita = 1; bp_escrita = S0; bp_dado = 32'd777; bp_leitura_1 = T0;
        @(posedge clk); #1;
        bp_habilita = 0; bp_leitura_1 = S0; #1;
        if (bp_saida_1 !== 32'd777) begin
            $display("  ERRO  escrita normal falhou: $s0 = %0d", bp_saida_1);
            erros = erros + 1;
        end else
            $display("  ok    %-46s $s0 = %0d", "escrita normal continua funcionando", bp_saida_1);

        // agora o caso que o pipeline cria: ler $s0 no MESMO ciclo em que o
        // estagio WB esta gravando 999 nele
        bp_habilita = 1; bp_escrita = S0; bp_dado = 32'd999; bp_leitura_1 = S0; #1;
        if (bp_saida_1 !== 32'd999) begin
            $display("  ERRO  write-first: leu %0d, deveria ler o valor sendo escrito (999)",
                     bp_saida_1);
            erros = erros + 1;
        end else
            $display("  ok    %-46s le %0d, nao o valor antigo",
                     "write-first: le a escrita do mesmo ciclo", bp_saida_1);

        // ler OUTRO registrador no mesmo ciclo nao pode sofrer bypass
        bp_leitura_1 = T0; #1;
        if (bp_saida_1 !== 32'd0) begin
            $display("  ERRO  bypass vazou para outro registrador: $t0 = %0d", bp_saida_1);
            erros = erros + 1;
        end else
            $display("  ok    %-46s $t0 = 0", "bypass so afeta o registrador escrito");

        // e o registrador 0 continua intocavel, mesmo com bypass
        bp_escrita = ZERO; bp_dado = 32'hDEAD; bp_leitura_1 = ZERO; #1;
        if (bp_saida_1 !== 32'd0) begin
            $display("  ERRO  bypass furou a protecao de $zero: %0d", bp_saida_1);
            erros = erros + 1;
        end else
            $display("  ok    %-46s", "$zero resiste ao bypass");
        bp_habilita = 0;

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display("");
        $finish;
    end

endmodule
