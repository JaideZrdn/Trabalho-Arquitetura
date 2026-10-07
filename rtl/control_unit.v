// ============================================================================
//  control_unit — unidade de controle principal
//
//  Le o opcode da instrucao (e o funct, quando e formato R) e emite todos os
//  sinais que comandam o caminho de dados. A codificacao de cada sinal NAO foi
//  escolhida aqui: ela foi fixada pelos multiplexadores e esta registrada em
//  docs/contrato-sinais.md.
//
//      pc_src      00 PC+4   01 desvio   10 salto   11 jr
//      reg_dst     00 rt     01 rd       10 $ra (31)
//      mem_to_reg  00 ALU    01 memoria  10 PC+4
//      alu_src_a    0 read_data_1         1 shamt
//      alu_src_b    0 read_data_2         1 imediato estendido
//      alu_op      00 ADD    01 SUB      10 ver funct   11 SLT
//
//  O sinal `zero` da ALU entra aqui para resolver o desvio: o beq so troca o
//  PC se zero = 1, o bne so troca se zero = 0. Nao ha laco combinacional —
//  alu_op nao depende de zero, apenas pc_src depende.
//
//  Por que o funct tambem entra: `jr` e formato R (opcode 0) como o `add`,
//  mas nao escreve em registrador e desvia o PC. Sem olhar o funct, a unidade
//  de controle nao consegue separar os dois.
// ============================================================================
`timescale 1ns/1ps

module control_unit #(
    parameter OPCODE_WIDTH = 6,
    parameter FUNCT_WIDTH  = 6
)(
    input  wire [OPCODE_WIDTH-1:0] opcode,
    input  wire [FUNCT_WIDTH-1:0]  funct,
    input  wire                    zero,
    output reg  [1:0]              pc_src,
    output reg  [1:0]              reg_dst,
    output reg  [1:0]              mem_to_reg,
    output reg                     alu_src_a,
    output reg                     alu_src_b,
    output reg                     reg_write,
    output reg                     mem_write,
    output reg  [1:0]              alu_op
);
    // opcodes do programa de teste
    localparam OP_RTYPE = 6'h00, OP_J    = 6'h02, OP_JAL  = 6'h03,
               OP_BEQ   = 6'h04, OP_BNE  = 6'h05, OP_ADDI = 6'h08,
               OP_SLTI  = 6'h0a, OP_LW   = 6'h23, OP_SW   = 6'h2b;

    localparam F_JR = 6'h08;

    // intencao de desvio, antes de consultar o sinal zero
    reg branch_eq, branch_ne;
    reg [1:0] pc_src_base;

    always @(*) begin
        // valores seguros por omissao: nao escreve em lugar nenhum, segue em
        // frente. Declarar tudo aqui evita latch e evita sinal indefinido.
        pc_src_base = 2'b00;
        reg_dst     = 2'b00;
        mem_to_reg  = 2'b00;
        alu_src_a   = 1'b0;
        alu_src_b   = 1'b0;
        reg_write   = 1'b0;
        mem_write   = 1'b0;
        alu_op      = 2'b00;
        branch_eq   = 1'b0;
        branch_ne   = 1'b0;

        case (opcode)
            OP_RTYPE: begin
                if (funct == F_JR) begin
                    // jr $ra: so troca o PC, nao escreve nada
                    pc_src_base = 2'b11;
                end else begin
                    // add, slt, sll: destino em rd, resultado da ALU
                    reg_dst   = 2'b01;
                    reg_write = 1'b1;
                    alu_op    = 2'b10;            // a operacao vem do funct
                    // sll pega o deslocamento do campo shamt, nao de rs
                    alu_src_a = (funct == 6'h00) ? 1'b1 : 1'b0;
                end
            end

            OP_ADDI: begin                        // addi $rt, $rs, imm
                reg_dst   = 2'b00;                // destino em rt
                reg_write = 1'b1;
                alu_src_b = 1'b1;                 // segundo operando: imediato
                alu_op    = 2'b00;                // soma
            end

            OP_SLTI: begin                        // slti $rt, $rs, imm
                reg_dst   = 2'b00;
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                alu_op    = 2'b11;                // comparacao com sinal
            end

            OP_LW: begin                          // lw $rt, imm($rs)
                reg_dst    = 2'b00;
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;                // ALU calcula o endereco
                mem_to_reg = 2'b01;               // o dado vem da memoria
                alu_op     = 2'b00;
            end

            OP_SW: begin                          // sw $rt, imm($rs)
                alu_src_b = 1'b1;                 // ALU calcula o endereco
                mem_write = 1'b1;
                alu_op    = 2'b00;
                // reg_write fica 0: sw nao grava em registrador
            end

            OP_BEQ: begin                         // beq $rs, $rt, rotulo
                branch_eq = 1'b1;
                alu_op    = 2'b01;                // subtrai para gerar o zero
            end

            OP_BNE: begin
                branch_ne = 1'b1;
                alu_op    = 2'b01;
            end

            OP_J: begin
                pc_src_base = 2'b10;
            end

            OP_JAL: begin                         // salta E grava o retorno
                pc_src_base = 2'b10;
                reg_dst     = 2'b10;              // destino: registrador 31
                mem_to_reg  = 2'b10;              // dado gravado: PC+4
                reg_write   = 1'b1;
            end

            default: ;                            // mantem os valores seguros
        endcase
    end

    // o desvio so acontece se a condicao for satisfeita
    always @(*) begin
        if ((branch_eq && zero) || (branch_ne && !zero))
            pc_src = 2'b01;
        else
            pc_src = pc_src_base;
    end
endmodule
