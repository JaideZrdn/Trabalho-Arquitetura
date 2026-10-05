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

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display("");
        $finish;
    end

endmodule
