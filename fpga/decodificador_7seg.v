// ============================================================================
//  decodificador_7seg — um digito hexadecimal num display de 7 segmentos
//
//  ATENCAO: na DE2-115 os displays sao ATIVOS EM NIVEL BAIXO. Um bit 0 ACENDE
//  o segmento. Inverter isso e o erro mais comum de quem usa a placa pela
//  primeira vez — os displays acendem o negativo do numero e parece defeito.
//
//  Ordem dos bits: saida[0] = segmento a (topo), seguindo no sentido horario
//  ate saida[5] = f, e saida[6] = g (barra do meio).
//
//          aaaa
//         f    b
//         f    b
//          gggg
//         e    c
//         e    c
//          dddd
// ============================================================================
`timescale 1ns/1ps

module decodificador_7seg (
    input  wire [3:0] digito,
    output reg  [6:0] segmentos     // ativo em nivel baixo
);
    always @(*) begin
        case (digito)                 //        gfedcba
            4'h0: segmentos = 7'b1000000;
            4'h1: segmentos = 7'b1111001;
            4'h2: segmentos = 7'b0100100;
            4'h3: segmentos = 7'b0110000;
            4'h4: segmentos = 7'b0011001;
            4'h5: segmentos = 7'b0010010;
            4'h6: segmentos = 7'b0000010;
            4'h7: segmentos = 7'b1111000;
            4'h8: segmentos = 7'b0000000;
            4'h9: segmentos = 7'b0010000;
            4'hA: segmentos = 7'b0001000;
            4'hB: segmentos = 7'b0000011;
            4'hC: segmentos = 7'b1000110;
            4'hD: segmentos = 7'b0100001;
            4'hE: segmentos = 7'b0000110;
            4'hF: segmentos = 7'b0001110;
            default: segmentos = 7'b1111111;   // tudo apagado
        endcase
    end
endmodule
