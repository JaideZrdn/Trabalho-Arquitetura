`timescale 1ns/1ps
//  Confere os 16 digitos. Na DE2-115 o display e ATIVO EM NIVEL BAIXO:
//  bit 0 acende o segmento. Inverter isso acende o negativo do numero.
module decodificador_7seg_tb;
    reg  [3:0] digito;
    wire [6:0] segmentos;
    decodificador_7seg dut (.digito(digito), .segmentos(segmentos));

    integer erros = 0, i;
    reg [6:0] esperado [0:15];
    initial begin
        esperado[0]=7'b1000000; esperado[1]=7'b1111001;
        esperado[2]=7'b0100100; esperado[3]=7'b0110000;
        esperado[4]=7'b0011001; esperado[5]=7'b0010010;
        esperado[6]=7'b0000010; esperado[7]=7'b1111000;
        esperado[8]=7'b0000000; esperado[9]=7'b0010000;
        esperado[10]=7'b0001000; esperado[11]=7'b0000011;
        esperado[12]=7'b1000110; esperado[13]=7'b0100001;
        esperado[14]=7'b0000110; esperado[15]=7'b0001110;
    end

    initial begin
        $dumpfile("build/decodificador_7seg_tb.vcd"); $dumpvars(0, decodificador_7seg_tb);
        $display(""); $display("== decodificador_7seg (ativo em nivel baixo) ==");
        for (i = 0; i < 16; i = i + 1) begin
            digito = i[3:0]; #1;
            if (segmentos !== esperado[i]) begin
                $display("  ERRO  digito %0h: obtido %b, esperado %b", i, segmentos, esperado[i]);
                erros = erros + 1;
            end else
                $display("  ok    digito %0h -> %b   (%0d segmento(s) aceso(s))",
                         i, segmentos, 7 - $countones(segmentos));
        end
        // o 8 acende tudo; o 1 acende so dois segmentos
        if ($countones(esperado[8]) != 0) begin
            $display("  ERRO  o digito 8 deveria acender os 7 segmentos"); erros = erros + 1;
        end else $display("  ok    o 8 acende os 7 segmentos (todos os bits em 0)");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display(""); $finish;
    end
endmodule
