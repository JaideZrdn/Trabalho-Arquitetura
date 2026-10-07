`timescale 1ns/1ps
//  Testbench do alu_control — cobre os quatro valores de alu_op.
module alu_control_tb;
    reg  [1:0] alu_op;
    reg  [5:0] funct;
    wire [3:0] alu_control;

    alu_control dut (.alu_op(alu_op), .funct(funct), .alu_control(alu_control));

    localparam OP_AND=4'b0000, OP_OR=4'b0001, OP_ADD=4'b0010,
               OP_SUB=4'b0110, OP_SLT=4'b0111, OP_SLL=4'b1000;

    integer erros = 0;

    task confere(input [1:0] op, input [5:0] f, input [3:0] esperado,
                 input [80*8:1] nome);
        begin
            alu_op = op; funct = f; #1;
            if (alu_control !== esperado) begin
                $display("  ERRO  %0s: obtido=%b esperado=%b", nome, alu_control, esperado);
                erros = erros + 1;
            end else
                $display("  ok    %-46s -> %b", nome, alu_control);
        end
    endtask

    initial begin
        $dumpfile("build/alu_control_tb.vcd"); $dumpvars(0, alu_control_tb);
        $display(""); $display("== alu_control ==");

        confere(2'b00, 6'h00, OP_ADD, "alu_op=00 (lw/sw/addi) -> ADD");
        confere(2'b01, 6'h00, OP_SUB, "alu_op=01 (beq/bne) -> SUB");
        confere(2'b11, 6'h00, OP_SLT, "alu_op=11 (slti) -> SLT");

        confere(2'b10, 6'h20, OP_ADD, "formato R, funct 0x20 -> ADD");
        confere(2'b10, 6'h2a, OP_SLT, "formato R, funct 0x2a -> SLT");
        confere(2'b10, 6'h00, OP_SLL, "formato R, funct 0x00 -> SLL");
        confere(2'b10, 6'h22, OP_SUB, "formato R, funct 0x22 -> SUB");
        confere(2'b10, 6'h24, OP_AND, "formato R, funct 0x24 -> AND");
        confere(2'b10, 6'h25, OP_OR,  "formato R, funct 0x25 -> OR");

        // o funct so e consultado quando alu_op = 10
        confere(2'b00, 6'h2a, OP_ADD, "funct ignorado quando alu_op=00");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display(""); $finish;
    end
endmodule
