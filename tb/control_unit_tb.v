`timescale 1ns/1ps
// ============================================================================
//  Testbench da control_unit
//
//  Verifica o pacote COMPLETO de sinais para cada uma das doze instrucoes do
//  programa de teste, contra a codificacao registrada em
//  docs/contrato-sinais.md. Este e o teste que protege a integracao: um erro
//  aqui so apareceria com o processador inteiro montado.
// ============================================================================
module control_unit_tb;
    reg  [5:0] opcode, funct;
    reg        zero;
    wire [1:0] pc_src, reg_dst, mem_to_reg, alu_op;
    wire       alu_src_a, alu_src_b, reg_write, mem_write;

    control_unit dut (
        .opcode(opcode), .funct(funct), .zero(zero),
        .pc_src(pc_src), .reg_dst(reg_dst), .mem_to_reg(mem_to_reg),
        .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .reg_write(reg_write), .mem_write(mem_write), .alu_op(alu_op)
    );

    integer erros = 0;

    task confere(input [5:0] op, input [5:0] f, input z,
                 input [1:0] e_pc, input [1:0] e_rd, input [1:0] e_m2r,
                 input e_a, input e_b, input e_rw, input e_mw, input [1:0] e_aop,
                 input [80*8:1] nome);
        begin
            opcode = op; funct = f; zero = z; #1;
            if (pc_src !== e_pc || reg_dst !== e_rd || mem_to_reg !== e_m2r ||
                alu_src_a !== e_a || alu_src_b !== e_b ||
                reg_write !== e_rw || mem_write !== e_mw || alu_op !== e_aop) begin
                $display("  ERRO  %0s", nome);
                $display("        obtido   pc_src=%b reg_dst=%b mem_to_reg=%b a=%b b=%b rw=%b mw=%b alu_op=%b",
                         pc_src, reg_dst, mem_to_reg, alu_src_a, alu_src_b, reg_write, mem_write, alu_op);
                $display("        esperado pc_src=%b reg_dst=%b mem_to_reg=%b a=%b b=%b rw=%b mw=%b alu_op=%b",
                         e_pc, e_rd, e_m2r, e_a, e_b, e_rw, e_mw, e_aop);
                erros = erros + 1;
            end else
                $display("  ok    %-40s pc_src=%b rd=%b m2r=%b a=%b b=%b rw=%b mw=%b aop=%b",
                         nome, pc_src, reg_dst, mem_to_reg, alu_src_a, alu_src_b,
                         reg_write, mem_write, alu_op);
        end
    endtask

    initial begin
        $dumpfile("build/control_unit_tb.vcd"); $dumpvars(0, control_unit_tb);
        $display(""); $display("== control_unit: as 12 instrucoes do programa ==");

        //       op     funct  z   pc_src rd    m2r   a b rw mw alu_op
        confere(6'h00, 6'h20, 1'b0, 2'b00, 2'b01, 2'b00, 0,0, 1, 0, 2'b10, "add  $t1,$a0,$t1");
        confere(6'h00, 6'h2a, 1'b0, 2'b00, 2'b01, 2'b00, 0,0, 1, 0, 2'b10, "slt  $t0,$s0,$s2");
        confere(6'h00, 6'h00, 1'b0, 2'b00, 2'b01, 2'b00, 1,0, 1, 0, 2'b10, "sll  $t1,$a1,2   (shamt na entrada A)");
        confere(6'h00, 6'h08, 1'b0, 2'b11, 2'b00, 2'b00, 0,0, 0, 0, 2'b00, "jr   $ra         (nao escreve)");

        confere(6'h08, 6'h00, 1'b0, 2'b00, 2'b00, 2'b00, 0,1, 1, 0, 2'b00, "addi $sp,$sp,-20");
        confere(6'h0a, 6'h00, 1'b0, 2'b00, 2'b00, 2'b00, 0,1, 1, 0, 2'b11, "slti $t0,$s1,0");
        confere(6'h23, 6'h00, 1'b0, 2'b00, 2'b00, 2'b01, 0,1, 1, 0, 2'b00, "lw   $t2,0($t1)  (dado vem da memoria)");
        confere(6'h2b, 6'h00, 1'b0, 2'b00, 2'b00, 2'b00, 0,1, 0, 1, 2'b00, "sw   $t0,0($t1)  (nao escreve em reg)");

        // desvios: o mesmo opcode produz pc_src diferente conforme o zero
        confere(6'h04, 6'h00, 1'b1, 2'b01, 2'b00, 2'b00, 0,0, 0, 0, 2'b01, "beq  com zero=1  -> desvia");
        confere(6'h04, 6'h00, 1'b0, 2'b00, 2'b00, 2'b00, 0,0, 0, 0, 2'b01, "beq  com zero=0  -> segue");
        confere(6'h05, 6'h00, 1'b0, 2'b01, 2'b00, 2'b00, 0,0, 0, 0, 2'b01, "bne  com zero=0  -> desvia");
        confere(6'h05, 6'h00, 1'b1, 2'b00, 2'b00, 2'b00, 0,0, 0, 0, 2'b01, "bne  com zero=1  -> segue");

        confere(6'h02, 6'h00, 1'b0, 2'b10, 2'b00, 2'b00, 0,0, 0, 0, 2'b00, "j    main");
        confere(6'h03, 6'h00, 1'b0, 2'b10, 2'b10, 2'b10, 0,0, 1, 0, 2'b00, "jal  sort        (grava PC+4 em $ra)");

        // opcode desconhecido nao pode escrever em lugar nenhum
        confere(6'h3f, 6'h00, 1'b0, 2'b00, 2'b00, 2'b00, 0,0, 0, 0, 2'b00, "opcode invalido  -> inofensivo");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display(""); $finish;
    end
endmodule
