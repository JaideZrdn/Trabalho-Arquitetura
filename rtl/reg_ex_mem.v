// Registrador de estagio entre a execucao (EX) e o acesso a memoria (MEM).
//
// A partir daqui a instrucao ja calculou tudo. So restam os sinais de
// escrita, e o endereco do registrador destino, que ja foi resolvido no EX.
//
// O sinal eh_load existe para a unidade de forwarding: quando a instrucao
// em EX/MEM e um lw, o resultado da ALU e um ENDERECO, nao o dado. Encaminhar
// esse valor daria o numero errado. A unidade de hazard e quem resolve, com
// um stall.
//
// Nao tem entrada de stall: quando o pipeline congela, os estagios a frente
// continuam andando normalmente e drenam.
`timescale 1ns/1ps

module reg_ex_mem #(
    parameter LARGURA = 32
)(
    input  wire               clk,
    input  wire               reset,
    input  wire               limpa,

    input  wire [LARGURA-1:0] pc_plus_4_in,     // sobrevive por causa do jal
    input  wire [LARGURA-1:0] alu_result_in,
    input  wire [LARGURA-1:0] dado_2_in,        // valor a gravar num sw
    input  wire [4:0]         destino_in,
    input  wire               mem_write_in,
    input  wire               reg_write_in,
    input  wire [1:0]         mem_to_reg_in,
    input  wire               eh_load_in,

    output reg  [LARGURA-1:0] pc_plus_4_out,
    output reg  [LARGURA-1:0] alu_result_out,
    output reg  [LARGURA-1:0] dado_2_out,
    output reg  [4:0]         destino_out,
    output reg                mem_write_out,
    output reg                reg_write_out,
    output reg  [1:0]         mem_to_reg_out,
    output reg                eh_load_out
);
    always @(posedge clk or posedge reset) begin
        if (reset || limpa) begin
            pc_plus_4_out  <= {LARGURA{1'b0}};
            alu_result_out <= {LARGURA{1'b0}};
            dado_2_out     <= {LARGURA{1'b0}};
            destino_out    <= 5'd0;
            mem_write_out  <= 1'b0;
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 2'b00;
            eh_load_out    <= 1'b0;
        end else begin
            pc_plus_4_out  <= pc_plus_4_in;
            alu_result_out <= alu_result_in;
            dado_2_out     <= dado_2_in;
            destino_out    <= destino_in;
            mem_write_out  <= mem_write_in;
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            eh_load_out    <= eh_load_in;
        end
    end
endmodule
