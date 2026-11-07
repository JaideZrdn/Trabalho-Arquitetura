// Multiplexador 3:1 de dados para o forwarding.
// Instanciar DUAS vezes no estagio EX: uma para RS e outra para RT.
// O valor de RT encaminhado deve servir tambem ao dado de SW.
module mux_forwarding #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] dado_original,
    input  wire [WIDTH-1:0] dado_ex_mem,
    input  wire [WIDTH-1:0] dado_mem_wb,
    input  wire [1:0]       seletor,
    output reg  [WIDTH-1:0] saida
);
    always @(*) begin
        case (seletor)
            2'b00: saida = dado_original;
            2'b10: saida = dado_ex_mem;
            2'b01: saida = dado_mem_wb;
            default: saida = dado_original;
        endcase
    end
endmodule
