`timescale 1ns/1ps
// Testbench do registrador MEM/WB — o ultimo da fila.
// Carrega as tres origens possiveis do valor gravado: ALU, memoria e PC+4.
module reg_mem_wb_tb;
    reg clk = 0, reset;
    reg  [31:0] pc4, alu, mem;
    reg  [4:0]  destino;
    reg         reg_write;
    reg  [1:0]  mem_to_reg;
    wire [31:0] pc4_o, alu_o, mem_o;
    wire [4:0]  destino_o;
    wire        reg_write_o;
    wire [1:0]  mem_to_reg_o;

    reg_mem_wb #(.LARGURA(32)) dut (
        .clk(clk), .reset(reset),
        .pc_plus_4_in(pc4), .alu_result_in(alu), .mem_read_data_in(mem),
        .destino_in(destino), .reg_write_in(reg_write), .mem_to_reg_in(mem_to_reg),
        .pc_plus_4_out(pc4_o), .alu_result_out(alu_o), .mem_read_data_out(mem_o),
        .destino_out(destino_o), .reg_write_out(reg_write_o), .mem_to_reg_out(mem_to_reg_o)
    );

    always #5 clk = ~clk;
    integer erros = 0;

    task confere(input [80*8:1] nome, input cond);
        begin
            if (!cond) begin $display("  ERRO  %0s", nome); erros = erros + 1; end
            else        $display("  ok    %0s", nome);
        end
    endtask

    initial begin
        $dumpfile("build/reg_mem_wb_tb.vcd"); $dumpvars(0, reg_mem_wb_tb);
        $display(""); $display("== reg_mem_wb ==");

        reset=1; pc4=0; alu=0; mem=0; destino=0; reg_write=0; mem_to_reg=0;
        @(posedge clk); #1;
        confere("reset zera reg_write", reg_write_o===1'b0);
        reset=0;

        // --- resultado da ALU (add) -------------------------------------------
        alu=32'd1040; mem=0; pc4=0; destino=5'd9; reg_write=1; mem_to_reg=2'b00;
        @(posedge clk); #1;
        confere("add: resultado da ALU e destino $t1", alu_o===32'd1040 && destino_o===5'd9);
        confere("add: mem_to_reg = 00 escolhe a ALU no estagio WB", mem_to_reg_o===2'b00);

        // --- dado vindo da memoria (lw) ---------------------------------------
        alu=32'd1000; mem=32'd5; destino=5'd10; mem_to_reg=2'b01;
        @(posedge clk); #1;
        confere("lw: dado 5 lido da memoria chega ao WB", mem_o===32'd5);
        confere("lw: mem_to_reg = 01 escolhe a memoria", mem_to_reg_o===2'b01);

        // --- PC+4 (jal) --------------------------------------------------------
        pc4=32'd248; destino=5'd31; mem_to_reg=2'b10;
        @(posedge clk); #1;
        confere("jal: PC+4 = 248 chegou ao fim do pipeline", pc4_o===32'd248);
        confere("jal: mem_to_reg = 10 e destino = 31", mem_to_reg_o===2'b10 && destino_o===5'd31);

        // --- instrucao que nao escreve ------------------------------------------
        reg_write=0;
        @(posedge clk); #1;
        confere("sw/beq: reg_write = 0 nao grava nada", reg_write_o===1'b0);

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display(""); $finish;
    end
endmodule
