`timescale 1ns/1ps
//  Testbench de mux_alu_b — um caso por tipo de instrucao do programa.
module mux_alu_b_tb;

    reg  [31:0] read_data_2, imm_extended;
    reg         alu_src_b;
    wire [31:0] alu_input_b;

    mux_alu_b #(.DATA_WIDTH(32)) dut (
        .read_data_2(read_data_2), .imm_extended(imm_extended),
        .alu_src_b(alu_src_b), .alu_input_b(alu_input_b)
    );

    integer erros = 0;

    task confere(input [31:0] reg2, input [31:0] imm, input sel,
                 input [31:0] esperado, input [80*8:1] nome);
        begin
            read_data_2 = reg2; imm_extended = imm; alu_src_b = sel; #1;
            if (alu_input_b !== esperado) begin
                $display("  ERRO  %0s: obtido=%0d esperado=%0d",
                         nome, $signed(alu_input_b), $signed(esperado));
                erros = erros + 1;
            end else
                $display("  ok    %-48s B = %0d", nome, $signed(alu_input_b));
        end
    endtask

    initial begin
        $dumpfile("build/mux_alu_b_tb.vcd");
        $dumpvars(0, mux_alu_b_tb);
        $display("");
        $display("== mux_alu_b (sinal ALUSrc) ==");

        //         read_data_2  imediato  sel
        confere(   40,          999,      1'b0, 40,  "add $t1,$a0,$t1 -> registrador");
        confere(   999,         0,        1'b1, 0,   "lw $t2,0($t1)   -> imediato 0");
        confere(   999,         4,        1'b1, 4,   "lw $t0,4($t1)   -> imediato 4");
        confere(   999,         -20,      1'b1, -20, "addi $sp,$sp,-20 -> imediato negativo");
        confere(   0,           999,      1'b0, 0,   "beq $t0,$zero   -> registrador ($zero)");
        confere(   999,         16,       1'b1, 16,  "sw $ra,16($sp)  -> imediato 16");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display("");
        $finish;
    end
endmodule
