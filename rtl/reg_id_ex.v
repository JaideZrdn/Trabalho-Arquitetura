// Registrador de estagio entre a decodificacao (ID) e a execucao (EX).
//
// E o maior dos quatro: alem dos dados lidos, carrega TODOS os sinais de
// controle que ainda nao foram usados. Cada sinal viaja com a instrucao ate
// o estagio onde faz efeito.
//
// Os campos rs, rt, usa_rs e usa_rt existem para a unidade de forwarding:
// ela compara esses registradores com os destinos dos estagios adiante.
//
// limpa = 1 zera APENAS os sinais de controle. Os dados podem continuar,
// porque uma instrucao sem reg_write e sem mem_write nao altera nada — e
// exatamente isso que chamamos de bolha.
`timescale 1ns/1ps

module reg_id_ex #(
    parameter LARGURA = 32
)(
    input  wire               clk,
    input  wire               reset,
    input  wire               limpa,

    // --- dados ---
    input  wire [LARGURA-1:0] pc_plus_4_in,
    input  wire [LARGURA-1:0] dado_1_in,
    input  wire [LARGURA-1:0] dado_2_in,
    input  wire [LARGURA-1:0] imm_in,
    input  wire [4:0]         rs_in,
    input  wire [4:0]         rt_in,
    input  wire [4:0]         rd_in,
    input  wire [4:0]         shamt_in,
    input  wire [5:0]         funct_in,
    input  wire [25:0]        target_in,     // campo do salto, usado no EX

    // --- controle ---
    input  wire [1:0]         alu_op_in,
    input  wire               alu_src_a_in,
    input  wire               alu_src_b_in,
    input  wire [1:0]         reg_dst_in,
    input  wire               mem_write_in,
    input  wire               reg_write_in,
    input  wire [1:0]         mem_to_reg_in,
    input  wire               usa_rs_in,
    input  wire               usa_rt_in,
    // bandeiras de transferencia de controle: viajam ate o EX, onde o sinal
    // zero da ALU existe e a decisao pode finalmente ser tomada
    input  wire               branch_eq_in,
    input  wire               branch_ne_in,
    input  wire               jump_in,
    input  wire               jr_in,
    input  wire               eh_load_in,

    output reg  [LARGURA-1:0] pc_plus_4_out,
    output reg  [LARGURA-1:0] dado_1_out,
    output reg  [LARGURA-1:0] dado_2_out,
    output reg  [LARGURA-1:0] imm_out,
    output reg  [4:0]         rs_out,
    output reg  [4:0]         rt_out,
    output reg  [4:0]         rd_out,
    output reg  [4:0]         shamt_out,
    output reg  [5:0]         funct_out,
    output reg  [25:0]        target_out,

    output reg  [1:0]         alu_op_out,
    output reg                alu_src_a_out,
    output reg                alu_src_b_out,
    output reg  [1:0]         reg_dst_out,
    output reg                mem_write_out,
    output reg                reg_write_out,
    output reg  [1:0]         mem_to_reg_out,
    output reg                usa_rs_out,
    output reg                usa_rt_out,
    output reg                branch_eq_out,
    output reg                branch_ne_out,
    output reg                jump_out,
    output reg                jr_out,
    output reg                eh_load_out
);
    always @(posedge clk or posedge reset) begin
        if (reset || limpa) begin
            // dados zerados por higiene; o que realmente neutraliza a
            // instrucao sao os sinais de escrita em zero
            pc_plus_4_out <= {LARGURA{1'b0}};
            dado_1_out    <= {LARGURA{1'b0}};
            dado_2_out    <= {LARGURA{1'b0}};
            imm_out       <= {LARGURA{1'b0}};
            rs_out        <= 5'd0;
            rt_out        <= 5'd0;
            rd_out        <= 5'd0;
            shamt_out     <= 5'd0;
            funct_out     <= 6'd0;
            target_out    <= 26'd0;

            alu_op_out     <= 2'b00;
            alu_src_a_out  <= 1'b0;
            alu_src_b_out  <= 1'b0;
            reg_dst_out    <= 2'b00;
            mem_write_out  <= 1'b0;   // <- nao escreve na memoria
            reg_write_out  <= 1'b0;   // <- nao escreve em registrador
            mem_to_reg_out <= 2'b00;
            usa_rs_out     <= 1'b0;
            usa_rt_out     <= 1'b0;
            branch_eq_out  <= 1'b0;   // <- a bolha nao desvia
            branch_ne_out  <= 1'b0;
            jump_out       <= 1'b0;
            jr_out         <= 1'b0;
            eh_load_out    <= 1'b0;
        end else begin
            pc_plus_4_out <= pc_plus_4_in;
            dado_1_out    <= dado_1_in;
            dado_2_out    <= dado_2_in;
            imm_out       <= imm_in;
            rs_out        <= rs_in;
            rt_out        <= rt_in;
            rd_out        <= rd_in;
            shamt_out     <= shamt_in;
            funct_out     <= funct_in;
            target_out    <= target_in;

            alu_op_out     <= alu_op_in;
            alu_src_a_out  <= alu_src_a_in;
            alu_src_b_out  <= alu_src_b_in;
            reg_dst_out    <= reg_dst_in;
            mem_write_out  <= mem_write_in;
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            usa_rs_out     <= usa_rs_in;
            usa_rt_out     <= usa_rt_in;
            branch_eq_out  <= branch_eq_in;
            branch_ne_out  <= branch_ne_in;
            jump_out       <= jump_in;
            jr_out         <= jr_in;
            eh_load_out    <= eh_load_in;
        end
    end
endmodule
