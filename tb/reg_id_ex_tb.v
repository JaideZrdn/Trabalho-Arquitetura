`timescale 1ns/1ps
// Testbench do registrador ID/EX.
// O caso que mais importa e o da bolha: quando limpa = 1, os sinais de
// escrita tem que ir a zero. Se reg_write ou mem_write escaparem, a bolha
// vira uma instrucao fantasma que altera o estado do processador.
module reg_id_ex_tb;
    reg clk = 0, reset, limpa;
    reg  [31:0] pc4, d1, d2, imm;
    reg  [4:0]  rs, rt, rd, shamt;
    reg  [5:0]  funct;
    reg  [1:0]  alu_op, reg_dst, mem_to_reg;
    reg         alu_src_a, alu_src_b, mem_write, reg_write, usa_rs, usa_rt;

    wire [31:0] pc4_o, d1_o, d2_o, imm_o;
    wire [4:0]  rs_o, rt_o, rd_o, shamt_o;
    wire [5:0]  funct_o;
    wire [1:0]  alu_op_o, reg_dst_o, mem_to_reg_o;
    wire        alu_src_a_o, alu_src_b_o, mem_write_o, reg_write_o, usa_rs_o, usa_rt_o;

    reg_id_ex #(.LARGURA(32)) dut (
        .clk(clk), .reset(reset), .limpa(limpa),
        .pc_plus_4_in(pc4), .dado_1_in(d1), .dado_2_in(d2), .imm_in(imm),
        .rs_in(rs), .rt_in(rt), .rd_in(rd), .shamt_in(shamt), .funct_in(funct),
        .alu_op_in(alu_op), .alu_src_a_in(alu_src_a), .alu_src_b_in(alu_src_b),
        .reg_dst_in(reg_dst), .mem_write_in(mem_write), .reg_write_in(reg_write),
        .mem_to_reg_in(mem_to_reg), .usa_rs_in(usa_rs), .usa_rt_in(usa_rt),
        .pc_plus_4_out(pc4_o), .dado_1_out(d1_o), .dado_2_out(d2_o), .imm_out(imm_o),
        .rs_out(rs_o), .rt_out(rt_o), .rd_out(rd_o), .shamt_out(shamt_o), .funct_out(funct_o),
        .alu_op_out(alu_op_o), .alu_src_a_out(alu_src_a_o), .alu_src_b_out(alu_src_b_o),
        .reg_dst_out(reg_dst_o), .mem_write_out(mem_write_o), .reg_write_out(reg_write_o),
        .mem_to_reg_out(mem_to_reg_o), .usa_rs_out(usa_rs_o), .usa_rt_out(usa_rt_o)
    );

    always #5 clk = ~clk;
    integer erros = 0;

    task confere(input [80*8:1] nome, input cond);
        begin
            if (!cond) begin $display("  ERRO  %0s", nome); erros = erros + 1; end
            else        $display("  ok    %0s", nome);
        end
    endtask

    initial begin
        $dumpfile("build/reg_id_ex_tb.vcd"); $dumpvars(0, reg_id_ex_tb);
        $display(""); $display("== reg_id_ex ==");

        reset = 1; limpa = 0;
        pc4=0; d1=0; d2=0; imm=0; rs=0; rt=0; rd=0; shamt=0; funct=0;
        alu_op=0; alu_src_a=0; alu_src_b=0; reg_dst=0; mem_write=0; reg_write=0;
        mem_to_reg=0; usa_rs=0; usa_rt=0;
        @(posedge clk); #1;
        confere("reset zera reg_write e mem_write", reg_write_o===1'b0 && mem_write_o===1'b0);
        reset = 0;

        // --- carrega um "lw $t2, 0($t1)" ------------------------------------
        pc4=16; d1=1000; d2=0; imm=0;
        rs=9; rt=10; rd=0; shamt=0; funct=0;
        alu_op=2'b00; alu_src_a=0; alu_src_b=1; reg_dst=2'b00;
        mem_write=0; reg_write=1; mem_to_reg=2'b01; usa_rs=1; usa_rt=0;
        @(posedge clk); #1;
        confere("lw: dados carregados (dado_1 = 1000, imediato = 0)", d1_o===32'd1000 && imm_o===32'd0);
        confere("lw: rs = 9 e rt = 10 chegam para o forwarding", rs_o===5'd9 && rt_o===5'd10);
        confere("lw: usa_rs = 1 e usa_rt = 0", usa_rs_o===1'b1 && usa_rt_o===1'b0);
        confere("lw: alu_src_b = 1 (imediato) e mem_to_reg = 01 (memoria)",
                alu_src_b_o===1'b1 && mem_to_reg_o===2'b01);
        confere("lw: reg_write = 1", reg_write_o===1'b1);

        // --- carrega um "sw $t0, 0($t1)" ------------------------------------
        rs=9; rt=8; mem_write=1; reg_write=0; usa_rt=1; mem_to_reg=2'b00;
        @(posedge clk); #1;
        confere("sw: mem_write = 1 e reg_write = 0", mem_write_o===1'b1 && reg_write_o===1'b0);
        confere("sw: usa_rt = 1 (o valor gravado vem de rt)", usa_rt_o===1'b1);

        // --- a bolha ---------------------------------------------------------
        limpa = 1;
        mem_write=1; reg_write=1;        // entradas ativas de proposito
        @(posedge clk); #1;
        confere("BOLHA: reg_write zerado mesmo com entrada em 1", reg_write_o===1'b0);
        confere("BOLHA: mem_write zerado mesmo com entrada em 1", mem_write_o===1'b0);
        confere("BOLHA: usa_rs e usa_rt zerados (nao dispara forwarding)",
                usa_rs_o===1'b0 && usa_rt_o===1'b0);
        limpa = 0;

        // --- carrega um "sll $t1, $a1, 2" ------------------------------------
        rs=0; rt=5; rd=9; shamt=2; funct=6'h00;
        alu_op=2'b10; alu_src_a=1; alu_src_b=0; reg_dst=2'b01;
        mem_write=0; reg_write=1; mem_to_reg=2'b00; usa_rs=0; usa_rt=1;
        @(posedge clk); #1;
        confere("sll: shamt = 2 e alu_src_a = 1", shamt_o===5'd2 && alu_src_a_o===1'b1);
        confere("sll: rd = 9 e reg_dst = 01", rd_o===5'd9 && reg_dst_o===2'b01);

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display(""); $finish;
    end
endmodule
