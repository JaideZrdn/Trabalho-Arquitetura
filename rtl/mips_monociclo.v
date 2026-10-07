// ============================================================================
//  mips_monociclo — top-level do processador
//
//  Instancia os dezesseis blocos e liga os fios. Nao tem logica propria: toda
//  decisao ja esta dentro dos modulos. O que existe aqui e a FIACAO, e os
//  sinais de controle seguem exatamente a codificacao de docs/contrato-sinais.md.
//
//  Uma instrucao por ciclo de clock. No fim de cada ciclo tres coisas podem
//  ser gravadas: o PC (sempre), o banco de registradores (se reg_write) e a
//  memoria de dados (se mem_write). Todo o resto e combinacional e se resolve
//  dentro do mesmo ciclo.
//
//  Campos da instrucao, fatiados uma unica vez e usados por todo mundo:
//
//      [31:26] opcode   [25:21] rs   [20:16] rt
//      [15:11] rd       [10:6] shamt [5:0] funct
//      [15:0]  imediato (formato I)  [25:0] target (formato J)
// ============================================================================
`timescale 1ns/1ps

module mips_monociclo #(
    parameter LARGURA            = 32,
    parameter PROF_INSTRUCOES    = 256,
    parameter PROF_DADOS         = 256,
    parameter ARQUIVO_PROGRAMA   = "mem/programa.txt"
)(
    input  wire               clk,
    input  wire               reset,
    // saidas de observacao: uteis na simulacao e para ligar em LEDs/display
    output wire [LARGURA-1:0] pc_debug,
    output wire [LARGURA-1:0] instrucao_debug
);

    // ---- fios do caminho de dados -----------------------------------------
    wire [LARGURA-1:0] pc_atual, next_pc, pc_plus_4;
    wire [LARGURA-1:0] instrucao;
    wire [LARGURA-1:0] dado_1, dado_2, write_data;
    wire [LARGURA-1:0] imm_extended, imm_shifted;
    wire [LARGURA-1:0] alu_input_a, alu_input_b, alu_result;
    wire [LARGURA-1:0] mem_read_data;
    wire [LARGURA-1:0] branch_target, jump_target;
    wire [4:0]         write_register;
    wire [3:0]         alu_control_sig;
    wire               zero;

    // ---- sinais de controle ------------------------------------------------
    wire [1:0] pc_src, reg_dst, mem_to_reg, alu_op;
    wire       alu_src_a, alu_src_b, reg_write, mem_write;

    // ---- campos da instrucao -----------------------------------------------
    wire [5:0]  opcode = instrucao[31:26];
    wire [4:0]  rs     = instrucao[25:21];
    wire [4:0]  rt     = instrucao[20:16];
    wire [4:0]  rd     = instrucao[15:11];
    wire [4:0]  shamt  = instrucao[10:6];
    wire [5:0]  funct  = instrucao[5:0];
    wire [15:0] imm    = instrucao[15:0];
    wire [25:0] target = instrucao[25:0];

    assign pc_debug        = pc_atual;
    assign instrucao_debug = instrucao;

    // ======================= BUSCA DA INSTRUCAO =============================

    pc #(.LARGURA(LARGURA), .ENDERECO_INICIAL(0)) reg_pc (
        .clk(clk), .reset(reset),
        .proximo_pc(next_pc), .endereco_atual(pc_atual)
    );

    memoria_instrucoes #(
        .LARGURA(LARGURA), .PROFUNDIDADE(PROF_INSTRUCOES),
        .ARQUIVO(ARQUIVO_PROGRAMA)
    ) mem_instr (
        .endereco(pc_atual), .instrucao(instrucao)
    );

    // PC + 4: o endereco da proxima instrucao no caso normal
    somador #(.LARGURA(LARGURA)) soma_pc4 (
        .a(pc_atual), .b({{(LARGURA-3){1'b0}}, 3'd4}), .soma(pc_plus_4)
    );

    // ======================= DECODIFICACAO ==================================

    control_unit controle (
        .opcode(opcode), .funct(funct), .zero(zero),
        .pc_src(pc_src), .reg_dst(reg_dst), .mem_to_reg(mem_to_reg),
        .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .reg_write(reg_write), .mem_write(mem_write), .alu_op(alu_op)
    );

    // destino da escrita: rt (formato I), rd (formato R) ou 31 (jal)
    mux_write_reg #(.REG_WIDTH(5)) mux_reg_dst (
        .rt(rt), .rd(rd), .reg_dst(reg_dst), .write_register(write_register)
    );

    banco_registradores #(.LARGURA(LARGURA), .N_REGS(32)) banco (
        .clk(clk), .escreve_reg(reg_write),
        .reg_leitura_1(rs), .reg_leitura_2(rt),
        .reg_escrita(write_register), .dado_escrita(write_data),
        .dado_1(dado_1), .dado_2(dado_2)
    );

    extensor_sinal #(
        .LARGURA_ENTRADA(16), .LARGURA_SAIDA(LARGURA)
    ) extensor (
        .entrada(imm), .saida(imm_extended)
    );

    // ======================= EXECUCAO =======================================

    // entrada A: registrador, ou o shamt quando a instrucao e sll
    mux_alu_a #(.DATA_WIDTH(LARGURA), .SHAMT_WIDTH(5)) mux_a (
        .read_data_1(dado_1), .shamt(shamt),
        .alu_src_a(alu_src_a), .alu_input_a(alu_input_a)
    );

    // entrada B: registrador, ou o imediato nas instrucoes de formato I
    mux_alu_b #(.DATA_WIDTH(LARGURA)) mux_b (
        .read_data_2(dado_2), .imm_extended(imm_extended),
        .alu_src_b(alu_src_b), .alu_input_b(alu_input_b)
    );

    alu_control ctrl_alu (
        .alu_op(alu_op), .funct(funct), .alu_control(alu_control_sig)
    );

    alu #(.DATA_WIDTH(LARGURA)) ula (
        .a(alu_input_a), .b(alu_input_b), .alu_control(alu_control_sig),
        .result(alu_result), .zero(zero)
    );

    // ======================= MEMORIA ========================================

    // o endereco vem da ALU; o dado escrito e o segundo registrador lido (sw)
    memoria_dados #(
        .LARGURA(LARGURA), .PROFUNDIDADE(PROF_DADOS)
    ) mem_dados (
        .clk(clk), .escreve_mem(mem_write),
        .endereco(alu_result), .dado_escrita(dado_2),
        .dado_leitura(mem_read_data)
    );

    // ======================= ESCRITA NO BANCO ===============================

    mux_write_data #(.DATA_WIDTH(LARGURA)) mux_wd (
        .alu_result(alu_result), .mem_read_data(mem_read_data),
        .pc_plus_4(pc_plus_4), .mem_to_reg(mem_to_reg),
        .write_data(write_data)
    );

    // ======================= PROXIMO PC =====================================

    // destino do desvio: PC+4 + imediato*4 (o imediato conta instrucoes)
    shift_left_2 #(.DATA_WIDTH(LARGURA)) desloca_imm (
        .in(imm_extended), .out(imm_shifted)
    );

    somador #(.LARGURA(LARGURA)) soma_desvio (
        .a(pc_plus_4), .b(imm_shifted), .soma(branch_target)
    );

    // destino do salto: {PC+4[31:28], target, 2'b00}
    jump_address_calc #(
        .DATA_WIDTH(LARGURA), .TARGET_WIDTH(26)
    ) calc_jump (
        .pc_plus_4(pc_plus_4), .target(target), .jump_address(jump_target)
    );

    // o jr salta para o endereco que esta no registrador lido em rs
    mux_pc #(.DATA_WIDTH(LARGURA)) mux_proximo_pc (
        .pc_plus_4(pc_plus_4), .branch_target(branch_target),
        .jump_target(jump_target), .jr_target(dado_1),
        .pc_src(pc_src), .next_pc(next_pc)
    );

endmodule
