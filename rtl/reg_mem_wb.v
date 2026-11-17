// Registrador de estagio entre o acesso a memoria (MEM) e a escrita (WB).
//
// O ultimo da fila. Carrega as tres origens possiveis do valor que sera
// gravado — resultado da ALU, dado lido da memoria e PC+4 — mais o endereco
// do registrador destino e a permissao de escrita.
//
// A escolha entre as tres e feita no estagio WB, pelo mesmo mux do dado
// escrito que ja existia no monociclo.
`timescale 1ns/1ps

module reg_mem_wb #(
    parameter LARGURA = 32
)(
    input  wire               clk,
    input  wire               reset,

    input  wire [LARGURA-1:0] pc_plus_4_in,
    input  wire [LARGURA-1:0] alu_result_in,
    input  wire [LARGURA-1:0] mem_read_data_in,
    input  wire [4:0]         destino_in,
    input  wire               reg_write_in,
    input  wire [1:0]         mem_to_reg_in,

    output reg  [LARGURA-1:0] pc_plus_4_out,
    output reg  [LARGURA-1:0] alu_result_out,
    output reg  [LARGURA-1:0] mem_read_data_out,
    output reg  [4:0]         destino_out,
    output reg                reg_write_out,
    output reg  [1:0]         mem_to_reg_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_plus_4_out     <= {LARGURA{1'b0}};
            alu_result_out    <= {LARGURA{1'b0}};
            mem_read_data_out <= {LARGURA{1'b0}};
            destino_out       <= 5'd0;
            reg_write_out     <= 1'b0;
            mem_to_reg_out    <= 2'b00;
        end else begin
            pc_plus_4_out     <= pc_plus_4_in;
            alu_result_out    <= alu_result_in;
            mem_read_data_out <= mem_read_data_in;
            destino_out       <= destino_in;
            reg_write_out     <= reg_write_in;
            mem_to_reg_out    <= mem_to_reg_in;
        end
    end
endmodule
