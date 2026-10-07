`timescale 1ns/1ps
//  Testbench do shift_left_2 — imediatos reais de desvio do programa.
module shift_left_2_tb;
    reg  [31:0] in;
    wire [31:0] out;

    shift_left_2 #(.DATA_WIDTH(32)) dut (.in(in), .out(out));

    integer erros = 0;

    task confere(input [31:0] v, input [31:0] esperado, input [80*8:1] nome);
        begin
            in = v; #1;
            if (out !== esperado) begin
                $display("  ERRO  %0s: %0d << 2 = %0d, esperado %0d",
                         nome, $signed(in), $signed(out), $signed(esperado));
                erros = erros + 1;
            end else
                $display("  ok    %-46s %0d -> %0d", nome, $signed(in), $signed(out));
        end
    endtask

    initial begin
        $dumpfile("build/shift_left_2_tb.vcd"); $dumpvars(0, shift_left_2_tb);
        $display(""); $display("== shift_left_2 ==");
        confere(16,  64,  "beq em PC=72, imediato +16 -> 64 bytes");
        confere(11,  44,  "bne em PC=84, imediato +11 -> 44 bytes");
        confere(5,   20,  "beq em PC=108, imediato +5 -> 20 bytes");
        confere(0,   0,   "imediato 0");
        confere(-1,  -4,  "imediato negativo (desvio para tras)");
        confere(-10, -40, "imediato -10 -> -40 bytes");
        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display(""); $finish;
    end
endmodule
