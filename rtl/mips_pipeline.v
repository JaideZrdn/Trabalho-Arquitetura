// ============================================================================
//  mips_pipeline — processador MIPS de 5 estagios
//
//  Mesmo conjunto de instrucoes do monociclo. O que muda e a organizacao: a
//  execucao e dividida em cinco etapas e cinco instrucoes diferentes ficam
//  em voo ao mesmo tempo, uma em cada estagio.
//
//      IF   busca a instrucao
//      ID   decodifica e le os registradores
//      EX   calcula na ALU e decide os desvios
//      MEM  acessa a memoria de dados
//      WB   grava no banco de registradores
//
//  Entre cada par de estagios ha um registrador que segura o que a instrucao
//  carrega consigo — dados e os sinais de controle que ainda nao agiram.
//
//  TRES PERIGOS SAO TRATADOS AQUI:
//
//  1. Dependencia de dados resolvida por encaminhamento. Quando uma
//     instrucao precisa de um resultado que ainda nao foi gravado, o valor e
//     desviado direto do estagio onde ele ja existe. A unidade de forwarding
//     decide; dois multiplexadores de 3 entradas aplicam.
//
//  2. Load-use, que o encaminhamento nao resolve. Se um lw esta no EX e a
//     instrucao seguinte quer o dado, ele ainda nao foi lido da memoria. A
//     deteccao de hazard segura o pipeline por um ciclo.
//
//  3. Transferencia de controle. A decisao sai no EX, quando a ALU produz o
//     sinal zero. Duas instrucoes ja entraram ate la e sao descartadas.
//
//  O banco de registradores roda em modo write-first (BYPASS = 1): a escrita
//  do estagio WB e enxergada pela leitura do ID no mesmo ciclo. Sem isso,
//  dependencias a tres instrucoes de distancia leriam o valor antigo.
// ============================================================================
`timescale 1ns/1ps

module mips_pipeline #(
    parameter LARGURA          = 32,
    parameter PROF_INSTRUCOES  = 256,
    parameter PROF_DADOS       = 256,
    parameter ARQUIVO_PROGRAMA = "mem/programa.txt"
)(
    input  wire               clk,
    input  wire               reset,
    input  wire [LARGURA-1:0] endereco_debug,
    output wire [LARGURA-1:0] dado_debug,
    output wire [LARGURA-1:0] pc_debug,
    output wire [LARGURA-1:0] instrucao_debug
);

    // =====================================================================
    //  IF — busca da instrucao
    // =====================================================================
    wire [LARGURA-1:0] pc_atual, pc_plus_4, proximo_pc;
    wire [LARGURA-1:0] instrucao_if;

    wire segura_pc, segura_if_id, bolha_id_ex;
    wire tomado, limpa_if_id, limpa_id_ex;
    wire [LARGURA-1:0] destino_controle;

    // o PC so congela no stall de load-use
    wire pc_habilita = ~segura_pc;

    assign proximo_pc = tomado ? destino_controle : pc_plus_4;

    pc_com_habilita #(.LARGURA(LARGURA)) reg_pc (
        .clk(clk), .reset(reset), .habilita(pc_habilita),
        .proximo_pc(proximo_pc), .endereco_atual(pc_atual)
    );

    memoria_instrucoes #(
        .LARGURA(LARGURA), .PROFUNDIDADE(PROF_INSTRUCOES),
        .ARQUIVO(ARQUIVO_PROGRAMA)
    ) mem_instr (.endereco(pc_atual), .instrucao(instrucao_if));

    somador #(.LARGURA(LARGURA)) soma_pc4 (
        .a(pc_atual), .b({{(LARGURA-3){1'b0}}, 3'd4}), .soma(pc_plus_4)
    );

    assign pc_debug        = pc_atual;
    assign instrucao_debug = instrucao_if;

    // =====================================================================
    //  IF/ID
    // =====================================================================
    wire [LARGURA-1:0] id_instrucao, id_pc_plus_4;

    reg_if_id #(.LARGURA(LARGURA)) if_id (
        .clk(clk), .reset(reset),
        .habilita(~segura_if_id), .limpa(limpa_if_id),
        .instrucao_in(instrucao_if), .pc_plus_4_in(pc_plus_4),
        .instrucao_out(id_instrucao), .pc_plus_4_out(id_pc_plus_4)
    );

    // =====================================================================
    //  ID — decodificacao e leitura dos registradores
    // =====================================================================
    wire [5:0]  id_opcode = id_instrucao[31:26];
    wire [4:0]  id_rs     = id_instrucao[25:21];
    wire [4:0]  id_rt     = id_instrucao[20:16];
    wire [4:0]  id_rd     = id_instrucao[15:11];
    wire [4:0]  id_shamt  = id_instrucao[10:6];
    wire [5:0]  id_funct  = id_instrucao[5:0];
    wire [15:0] id_imm    = id_instrucao[15:0];
    wire [25:0] id_target = id_instrucao[25:0];

    wire [1:0] id_reg_dst, id_mem_to_reg, id_alu_op;
    wire id_alu_src_a, id_alu_src_b, id_reg_write, id_mem_write;
    wire id_usa_rs, id_usa_rt, id_branch_eq, id_branch_ne, id_jump, id_jr, id_eh_load;

    control_unit controle (
        .opcode(id_opcode), .funct(id_funct),
        .zero(1'b0),                  // nao usado no pipeline
        .pc_src(),                    // idem: a decisao e tomada no EX
        .reg_dst(id_reg_dst), .mem_to_reg(id_mem_to_reg),
        .alu_src_a(id_alu_src_a), .alu_src_b(id_alu_src_b),
        .reg_write(id_reg_write), .mem_write(id_mem_write), .alu_op(id_alu_op),
        .usa_rs(id_usa_rs), .usa_rt(id_usa_rt),
        .branch_eq(id_branch_eq), .branch_ne(id_branch_ne),
        .jump(id_jump), .jr(id_jr), .eh_load(id_eh_load)
    );

    wire [LARGURA-1:0] id_dado_1, id_dado_2, id_imm_estendido;
    wire [LARGURA-1:0] wb_dado_escrita;
    wire [4:0]         wb_destino;
    wire               wb_reg_write;

    banco_registradores #(
        .LARGURA(LARGURA), .N_REGS(32), .BYPASS(1)
    ) banco (
        .clk(clk), .escreve_reg(wb_reg_write),
        .reg_leitura_1(id_rs), .reg_leitura_2(id_rt),
        .reg_escrita(wb_destino), .dado_escrita(wb_dado_escrita),
        .dado_1(id_dado_1), .dado_2(id_dado_2)
    );

    extensor_sinal #(.LARGURA_ENTRADA(16), .LARGURA_SAIDA(LARGURA)) extensor (
        .entrada(id_imm), .saida(id_imm_estendido)
    );

    // numa bolha os sinais de controle precisam entrar zerados
    wire anula_id_ex = bolha_id_ex | limpa_id_ex;

    // =====================================================================
    //  ID/EX
    // =====================================================================
    wire [LARGURA-1:0] ex_pc_plus_4, ex_dado_1, ex_dado_2, ex_imm;
    wire [4:0]  ex_rs, ex_rt, ex_rd, ex_shamt;
    wire [5:0]  ex_funct;
    wire [25:0] ex_target;
    wire [1:0]  ex_alu_op, ex_reg_dst, ex_mem_to_reg;
    wire ex_alu_src_a, ex_alu_src_b, ex_mem_write, ex_reg_write;
    wire ex_usa_rs, ex_usa_rt, ex_branch_eq, ex_branch_ne, ex_jump, ex_jr, ex_eh_load;

    reg_id_ex #(.LARGURA(LARGURA)) id_ex (
        .clk(clk), .reset(reset), .limpa(anula_id_ex),
        .pc_plus_4_in(id_pc_plus_4), .dado_1_in(id_dado_1), .dado_2_in(id_dado_2),
        .imm_in(id_imm_estendido), .rs_in(id_rs), .rt_in(id_rt), .rd_in(id_rd),
        .shamt_in(id_shamt), .funct_in(id_funct), .target_in(id_target),
        .alu_op_in(id_alu_op), .alu_src_a_in(id_alu_src_a), .alu_src_b_in(id_alu_src_b),
        .reg_dst_in(id_reg_dst), .mem_write_in(id_mem_write), .reg_write_in(id_reg_write),
        .mem_to_reg_in(id_mem_to_reg), .usa_rs_in(id_usa_rs), .usa_rt_in(id_usa_rt),
        .branch_eq_in(id_branch_eq), .branch_ne_in(id_branch_ne),
        .jump_in(id_jump), .jr_in(id_jr), .eh_load_in(id_eh_load),
        .pc_plus_4_out(ex_pc_plus_4), .dado_1_out(ex_dado_1), .dado_2_out(ex_dado_2),
        .imm_out(ex_imm), .rs_out(ex_rs), .rt_out(ex_rt), .rd_out(ex_rd),
        .shamt_out(ex_shamt), .funct_out(ex_funct), .target_out(ex_target),
        .alu_op_out(ex_alu_op), .alu_src_a_out(ex_alu_src_a), .alu_src_b_out(ex_alu_src_b),
        .reg_dst_out(ex_reg_dst), .mem_write_out(ex_mem_write), .reg_write_out(ex_reg_write),
        .mem_to_reg_out(ex_mem_to_reg), .usa_rs_out(ex_usa_rs), .usa_rt_out(ex_usa_rt),
        .branch_eq_out(ex_branch_eq), .branch_ne_out(ex_branch_ne),
        .jump_out(ex_jump), .jr_out(ex_jr), .eh_load_out(ex_eh_load)
    );

    // =====================================================================
    //  EX — calculo, encaminhamento e decisao dos desvios
    // =====================================================================
    wire [LARGURA-1:0] mem_alu_result, mem_dado_2;
    wire [4:0]         mem_destino;
    wire               mem_reg_write, mem_eh_load;
    wire [1:0]         forward_a, forward_b;

    unidade_forwarding #(.REG_BITS(5)) forwarding (
        .id_ex_rs(ex_rs), .id_ex_rt(ex_rt),
        .id_ex_usa_rs(ex_usa_rs), .id_ex_usa_rt(ex_usa_rt),
        .ex_mem_destino(mem_destino), .ex_mem_reg_write(mem_reg_write),
        .ex_mem_eh_load(mem_eh_load),
        .mem_wb_destino(wb_destino), .mem_wb_reg_write(wb_reg_write),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    wire [LARGURA-1:0] ex_operando_a, ex_operando_b;

    mux_forwarding #(.WIDTH(LARGURA)) fwd_a (
        .dado_original(ex_dado_1), .dado_ex_mem(mem_alu_result),
        .dado_mem_wb(wb_dado_escrita), .seletor(forward_a), .saida(ex_operando_a)
    );

    mux_forwarding #(.WIDTH(LARGURA)) fwd_b (
        .dado_original(ex_dado_2), .dado_ex_mem(mem_alu_result),
        .dado_mem_wb(wb_dado_escrita), .seletor(forward_b), .saida(ex_operando_b)
    );

    wire [LARGURA-1:0] ex_entrada_a, ex_entrada_b, ex_alu_result;
    wire [3:0] ex_alu_control;
    wire ex_zero;

    mux_alu_a #(.DATA_WIDTH(LARGURA), .SHAMT_WIDTH(5)) mux_a (
        .read_data_1(ex_operando_a), .shamt(ex_shamt),
        .alu_src_a(ex_alu_src_a), .alu_input_a(ex_entrada_a)
    );

    mux_alu_b #(.DATA_WIDTH(LARGURA)) mux_b (
        .read_data_2(ex_operando_b), .imm_extended(ex_imm),
        .alu_src_b(ex_alu_src_b), .alu_input_b(ex_entrada_b)
    );

    alu_control ctrl_alu (
        .alu_op(ex_alu_op), .funct(ex_funct), .alu_control(ex_alu_control)
    );

    alu #(.DATA_WIDTH(LARGURA)) ula (
        .a(ex_entrada_a), .b(ex_entrada_b), .alu_control(ex_alu_control),
        .result(ex_alu_result), .zero(ex_zero)
    );

    wire [4:0] ex_destino;
    mux_write_reg #(.REG_WIDTH(5)) mux_destino (
        .rt(ex_rt), .rd(ex_rd), .reg_dst(ex_reg_dst), .write_register(ex_destino)
    );

    // --- os tres destinos possiveis de uma transferencia de controle -------
    wire [LARGURA-1:0] ex_imm_x4, ex_destino_desvio, ex_destino_salto;

    shift_left_2 #(.DATA_WIDTH(LARGURA)) desloca (.in(ex_imm), .out(ex_imm_x4));

    somador #(.LARGURA(LARGURA)) soma_desvio (
        .a(ex_pc_plus_4), .b(ex_imm_x4), .soma(ex_destino_desvio)
    );

    jump_address_calc #(.DATA_WIDTH(LARGURA), .TARGET_WIDTH(26)) calc_salto (
        .pc_plus_4(ex_pc_plus_4), .target(ex_target), .jump_address(ex_destino_salto)
    );

    controle_flush flush (
        .branch_eq(ex_branch_eq), .branch_ne(ex_branch_ne),
        .jump(ex_jump), .jr(ex_jr), .zero(ex_zero),
        .tomado(tomado), .limpa_if_id(limpa_if_id), .limpa_id_ex(limpa_id_ex)
    );

    // o jr usa o valor ja encaminhado, para o caso de o registrador ter sido
    // escrito por uma instrucao recente
    assign destino_controle = ex_jr   ? ex_operando_a
                            : ex_jump ? ex_destino_salto
                                      : ex_destino_desvio;

    // =====================================================================
    //  deteccao de load-use — olha o EX e o ID ao mesmo tempo
    // =====================================================================
    deteccao_hazard #(.REG_BITS(5)) hazard (
        .id_ex_eh_load(ex_eh_load), .id_ex_destino(ex_destino),
        .if_id_rs(id_rs), .if_id_rt(id_rt),
        .if_id_usa_rs(id_usa_rs), .if_id_usa_rt(id_usa_rt),
        .segura_pc(segura_pc), .segura_if_id(segura_if_id),
        .bolha_id_ex(bolha_id_ex)
    );

    // =====================================================================
    //  EX/MEM
    // =====================================================================
    wire [LARGURA-1:0] mem_pc_plus_4;
    wire [1:0]         mem_mem_to_reg;
    wire               mem_mem_write;

    reg_ex_mem #(.LARGURA(LARGURA)) ex_mem (
        .clk(clk), .reset(reset), .limpa(1'b0),
        .pc_plus_4_in(ex_pc_plus_4), .alu_result_in(ex_alu_result),
        .dado_2_in(ex_operando_b), .destino_in(ex_destino),
        .mem_write_in(ex_mem_write), .reg_write_in(ex_reg_write),
        .mem_to_reg_in(ex_mem_to_reg), .eh_load_in(ex_eh_load),
        .pc_plus_4_out(mem_pc_plus_4), .alu_result_out(mem_alu_result),
        .dado_2_out(mem_dado_2), .destino_out(mem_destino),
        .mem_write_out(mem_mem_write), .reg_write_out(mem_reg_write),
        .mem_to_reg_out(mem_mem_to_reg), .eh_load_out(mem_eh_load)
    );

    // =====================================================================
    //  MEM — acesso a memoria de dados
    // =====================================================================
    wire [LARGURA-1:0] mem_dado_lido;

    memoria_dados #(.LARGURA(LARGURA), .PROFUNDIDADE(PROF_DADOS)) mem_dados (
        .clk(clk), .escreve_mem(mem_mem_write),
        .endereco(mem_alu_result), .dado_escrita(mem_dado_2),
        .dado_leitura(mem_dado_lido),
        .endereco_debug(endereco_debug), .dado_debug(dado_debug)
    );

    // =====================================================================
    //  MEM/WB
    // =====================================================================
    wire [LARGURA-1:0] wb_pc_plus_4, wb_alu_result, wb_dado_lido;
    wire [1:0]         wb_mem_to_reg;

    reg_mem_wb #(.LARGURA(LARGURA)) mem_wb (
        .clk(clk), .reset(reset),
        .pc_plus_4_in(mem_pc_plus_4), .alu_result_in(mem_alu_result),
        .mem_read_data_in(mem_dado_lido), .destino_in(mem_destino),
        .reg_write_in(mem_reg_write), .mem_to_reg_in(mem_mem_to_reg),
        .pc_plus_4_out(wb_pc_plus_4), .alu_result_out(wb_alu_result),
        .mem_read_data_out(wb_dado_lido), .destino_out(wb_destino),
        .reg_write_out(wb_reg_write), .mem_to_reg_out(wb_mem_to_reg)
    );

    // =====================================================================
    //  WB — escolhe o valor e grava
    // =====================================================================
    mux_write_data #(.DATA_WIDTH(LARGURA)) mux_wd (
        .alu_result(wb_alu_result), .mem_read_data(wb_dado_lido),
        .pc_plus_4(wb_pc_plus_4), .mem_to_reg(wb_mem_to_reg),
        .write_data(wb_dado_escrita)
    );

endmodule
