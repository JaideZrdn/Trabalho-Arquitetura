// Unidade de forwarding para pipeline MIPS de 5 estagios.
// 00: usa operando original de ID/EX
// 10: encaminha resultado disponivel em EX/MEM
// 01: encaminha dado FINAL de escrita de MEM/WB
// 11: nao utilizado
//
// EX/MEM tem prioridade sobre MEM/WB.
// Em load-use, ex_mem_eh_load impede encaminhar endereco como dado.
// A unidade de hazard deve inserir um stall nesse caso.
module unidade_forwarding #(
    parameter REG_BITS = 5
)(
    input  wire [REG_BITS-1:0] id_ex_rs,
    input  wire [REG_BITS-1:0] id_ex_rt,
    input  wire                id_ex_usa_rs,
    input  wire                id_ex_usa_rt,

    input  wire [REG_BITS-1:0] ex_mem_destino,
    input  wire                ex_mem_reg_write,
    input  wire                ex_mem_eh_load,

    input  wire [REG_BITS-1:0] mem_wb_destino,
    input  wire                mem_wb_reg_write,

    output reg  [1:0]         forward_a,
    output reg  [1:0]         forward_b
);
    always @(*) begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        // Fonte RS: resultado mais recente tem prioridade.
        if (id_ex_usa_rs && id_ex_rs != {REG_BITS{1'b0}}) begin
            if (ex_mem_reg_write &&
                ex_mem_destino != {REG_BITS{1'b0}} &&
                ex_mem_destino == id_ex_rs) begin
                // Um lw ainda nao disponibiliza seu dado em EX/MEM.
                // Nao recorrer a MEM/WB: ali poderia haver um valor antigo.
                if (!ex_mem_eh_load)
                    forward_a = 2'b10;
            end else if (mem_wb_reg_write &&
                         mem_wb_destino != {REG_BITS{1'b0}} &&
                         mem_wb_destino == id_ex_rs) begin
                forward_a = 2'b01;
            end
        end

        // Fonte RT: tambem usada como dado a gravar por SW.
        if (id_ex_usa_rt && id_ex_rt != {REG_BITS{1'b0}}) begin
            if (ex_mem_reg_write &&
                ex_mem_destino != {REG_BITS{1'b0}} &&
                ex_mem_destino == id_ex_rt) begin
                if (!ex_mem_eh_load)
                    forward_b = 2'b10;
            end else if (mem_wb_reg_write &&
                         mem_wb_destino != {REG_BITS{1'b0}} &&
                         mem_wb_destino == id_ex_rt) begin
                forward_b = 2'b01;
            end
        end
    end
endmodule
