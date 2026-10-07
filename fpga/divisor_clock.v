// ============================================================================
//  divisor_clock — transforma os 50 MHz da placa num clock visivel a olho
//
//  POR QUE PRECISA
//  O programa inteiro tem 406 ciclos. A 50 MHz isso leva 8 microssegundos:
//  voce solta o reset e ja acabou, sem nada para ver. Dividindo para ~1 Hz, a
//  execucao leva uns 7 minutos e da para acompanhar o PC andando nos LEDs.
//
//  DIVISOR = quantos ciclos de entrada entre cada TROCA de nivel da saida.
//  O periodo de saida tem duas trocas, entao:
//
//      f_saida = f_entrada / (2 * DIVISOR)
//      50_000_000 / (2 * 25_000_000) = 1 Hz
// ============================================================================
`timescale 1ns/1ps

module divisor_clock #(
    parameter DIVISOR = 25_000_000
)(
    input  wire clk_in,
    input  wire reset,
    output reg  clk_out
);
    reg [31:0] conta;

    always @(posedge clk_in) begin
        if (reset) begin
            conta   <= 32'd0;
            clk_out <= 1'b0;
        end else if (conta == DIVISOR - 1) begin
            conta   <= 32'd0;
            clk_out <= ~clk_out;
        end else begin
            conta <= conta + 32'd1;
        end
    end
endmodule
