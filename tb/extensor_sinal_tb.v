// ============================================================================
//  Testbench de extensor_sinal
//
//  O QUE E UM TESTBENCH
//  Um modulo Verilog que NAO vai para a FPGA. Ele existe so dentro do
//  simulador: instancia o modulo sob teste (o "dut" — device under test),
//  aplica entradas, le as saidas e compara com o valor esperado.
//
//  Por isso ele pode usar coisas que nao existem em hardware: $display para
//  imprimir, #1 para esperar, $finish para encerrar a simulacao.
//
//  COMO RODAR
//      iverilog -g2012 -o build/sim rtl/extensor_sinal.v tb/extensor_sinal_tb.v
//      ./build/sim
// ============================================================================
`timescale 1ns/1ps

module extensor_sinal_tb;

    // ---- sinais que ligam o testbench ao modulo testado --------------------
    // reg  = o testbench ESCREVE neste sinal (e uma entrada do dut)
    // wire = o testbench so LE este sinal (e uma saida do dut)
    reg  [15:0] entrada;
    wire [31:0] saida;

    // ---- instancia do modulo sob teste -------------------------------------
    // #(...) passa os parametros; (...) liga as portas.
    // A forma .porta(sinal) e a ligacao por nome: nao depende da ordem e nao
    // quebra silenciosamente se alguem reordenar as portas do modulo.
    extensor_sinal #(
        .LARGURA_ENTRADA(16),
        .LARGURA_SAIDA(32)
    ) dut (
        .entrada(entrada),
        .saida(saida)
    );

    // ---- segunda instancia, com OUTRAS larguras ---------------------------
    // A rubrica 4 exige codigo parametrizado. Isto e a prova de que o
    // parametro realmente controla o hardware gerado: o MESMO modulo, com
    // outros numeros, vira um circuito de tamanho diferente.
    reg  [7:0]  entrada_8;
    wire [31:0] saida_8_32;

    extensor_sinal #(
        .LARGURA_ENTRADA(8),
        .LARGURA_SAIDA(32)
    ) dut_8_32 (
        .entrada(entrada_8),
        .saida(saida_8_32)
    );

    integer erros = 0;

    // ---- uma verificacao ---------------------------------------------------
    // aplica `valor` na entrada, espera o sinal propagar, compara com `esperado`
    // versao para a instancia de 8 bits
    task confere_8(input [7:0] valor, input [31:0] esperado, input [80*8:1] nome);
        begin
            entrada_8 = valor;
            #1;
            if (saida_8_32 !== esperado) begin
                $display("  ERRO  %0s: obtido=%b esperado=%b", nome, saida_8_32, esperado);
                erros = erros + 1;
            end else
                $display("  ok    %-34s  %0d -> %0d", nome, $signed(entrada_8), $signed(saida_8_32));
        end
    endtask

    task confere(input [15:0] valor, input [31:0] esperado, input [80*8:1] nome);
        begin
            entrada = valor;
            #1;                       // deixa a logica combinacional assentar
            if (saida !== esperado) begin
                $display("  ERRO  %0s", nome);
                $display("        entrada  = %b (%0d com sinal)", entrada, $signed(entrada));
                $display("        obtido   = %b (%0d)", saida, $signed(saida));
                $display("        esperado = %b (%0d)", esperado, $signed(esperado));
                erros = erros + 1;
            end else begin
                $display("  ok    %-34s  %0d -> %0d", nome, $signed(entrada), $signed(saida));
            end
        end
    endtask

    initial begin
        // gera forma de onda para abrir no GTKWave/Surfer, se precisar depurar
        $dumpfile("build/extensor_sinal_tb.vcd");
        $dumpvars(0, extensor_sinal_tb);

        $display("");
        $display("== extensor_sinal: 16 -> 32 bits ==");

        // --- positivos: os bits novos devem ser ZERO ------------------------
        confere(16'd0,      32'h0000_0000, "zero");
        confere(16'd1,      32'h0000_0001, "um");
        confere(16'd16,     32'h0000_0010, "16 (deslocamento de sw $ra,16($sp))");
        confere(16'd32767,  32'h0000_7FFF, "32767 (maior positivo em 16 bits)");

        // --- negativos: os bits novos devem ser UM --------------------------
        confere(16'hFFFF,   32'hFFFF_FFFF, "-1");
        confere(16'hFFEC,   32'hFFFF_FFEC, "-20 (imediato de addi $sp,$sp,-20)");
        confere(16'h8000,   32'hFFFF_8000, "-32768 (menor negativo em 16 bits)");

        // --- a fronteira: 0x7FFF e positivo, 0x8000 e negativo --------------
        // um bit de diferenca na entrada troca TODOS os 16 bits de cima
        confere(16'h7FFF,   32'h0000_7FFF, "fronteira positiva 0x7FFF");

        $display("");
        $display("== o MESMO modulo, parametrizado para 8 -> 32 bits ==");
        confere_8(8'd5,    32'h0000_0005, "5 em 8 bits");
        confere_8(8'd127,  32'h0000_007F, "127 (maior positivo em 8 bits)");
        confere_8(8'hFF,   32'hFFFF_FFFF, "-1 em 8 bits");
        confere_8(8'h80,   32'hFFFF_FF80, "-128 (menor negativo em 8 bits)");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display("");
        $finish;
    end

endmodule
