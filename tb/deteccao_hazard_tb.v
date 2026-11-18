`timescale 1ns/1ps
// Testbench da deteccao de load-use.
// Os dois casos positivos sao os que existem de verdade no programa.
module deteccao_hazard_tb;
    reg        eh_load;
    reg  [4:0] destino, rs, rt;
    reg        usa_rs, usa_rt;
    wire       segura_pc, segura_if_id, bolha;

    deteccao_hazard #(.REG_BITS(5)) dut (
        .id_ex_eh_load(eh_load), .id_ex_destino(destino),
        .if_id_rs(rs), .if_id_rt(rt),
        .if_id_usa_rs(usa_rs), .if_id_usa_rt(usa_rt),
        .segura_pc(segura_pc), .segura_if_id(segura_if_id), .bolha_id_ex(bolha)
    );

    integer erros = 0;

    task confere(input esperado, input [80*8:1] nome);
        begin
            #1;
            if (segura_pc !== esperado || segura_if_id !== esperado || bolha !== esperado) begin
                $display("  ERRO  %0s: parar=%b (esperado %b)", nome, segura_pc, esperado);
                erros = erros + 1;
            end else
                $display("  ok    %-50s parar = %b", nome, segura_pc);
        end
    endtask

    initial begin
        $dumpfile("build/deteccao_hazard_tb.vcd"); $dumpvars(0, deteccao_hazard_tb);
        $display(""); $display("== deteccao_hazard (load-use) ==");

        // --- os dois load-use reais do programa ------------------------------
        // PC=16: lw $t0,4($t1) -> sw $t0,0($t1)    ($t0 = 8)
        eh_load=1; destino=5'd8; rs=5'd9; rt=5'd8; usa_rs=1; usa_rt=1;
        confere(1'b1, "lw $t0 -> sw $t0 (PC=16 do programa)");

        // PC=100: lw $t4,4($t2) -> slt $t0,$t4,$t3  ($t4 = 12)
        eh_load=1; destino=5'd12; rs=5'd12; rt=5'd11; usa_rs=1; usa_rt=1;
        confere(1'b1, "lw $t4 -> slt $t4,$t3 (PC=100 do programa)");

        // --- colisao apenas em rt --------------------------------------------
        eh_load=1; destino=5'd10; rs=5'd9; rt=5'd10; usa_rs=1; usa_rt=1;
        confere(1'b1, "colisao so no segundo operando");

        // --- nao e load: o forwarding resolve, nao precisa parar -------------
        eh_load=0; destino=5'd8; rs=5'd8; rt=5'd8; usa_rs=1; usa_rt=1;
        confere(1'b0, "add -> uso imediato: forwarding resolve, sem stall");

        // --- e load, mas ninguem usa o registrador ---------------------------
        eh_load=1; destino=5'd8; rs=5'd4; rt=5'd5; usa_rs=1; usa_rt=1;
        confere(1'b0, "lw sem colisao de registrador");

        // --- e load e coincide, mas a instrucao nao LE aquele operando -------
        eh_load=1; destino=5'd8; rs=5'd8; rt=5'd8; usa_rs=0; usa_rt=0;
        confere(1'b0, "coincide, mas a instrucao nao le nenhum dos dois");

        // --- destino e o registrador 0: nunca precisa parar -------------------
        eh_load=1; destino=5'd0; rs=5'd0; rt=5'd0; usa_rs=1; usa_rt=1;
        confere(1'b0, "destino $zero nao gera stall");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display(""); $finish;
    end
endmodule
