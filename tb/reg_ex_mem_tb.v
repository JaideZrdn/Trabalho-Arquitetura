`timescale 1ns/1ps
// Testbench do registrador EX/MEM.
// Confere tambem o sinal eh_load, que a unidade de forwarding usa para nao
// encaminhar o endereco calculado por um lw como se fosse o dado.
module reg_ex_mem_tb;
    reg clk = 0, reset, limpa;
    reg  [31:0] pc4, alu, d2;
    reg  [4:0]  destino;
    reg         mem_write, reg_write, eh_load;
    reg  [1:0]  mem_to_reg;
    wire [31:0] pc4_o, alu_o, d2_o;
    wire [4:0]  destino_o;
    wire        mem_write_o, reg_write_o, eh_load_o;
    wire [1:0]  mem_to_reg_o;

    reg_ex_mem #(.LARGURA(32)) dut (
        .clk(clk), .reset(reset), .limpa(limpa),
        .pc_plus_4_in(pc4), .alu_result_in(alu), .dado_2_in(d2),
        .destino_in(destino), .mem_write_in(mem_write), .reg_write_in(reg_write),
        .mem_to_reg_in(mem_to_reg), .eh_load_in(eh_load),
        .pc_plus_4_out(pc4_o), .alu_result_out(alu_o), .dado_2_out(d2_o),
        .destino_out(destino_o), .mem_write_out(mem_write_o), .reg_write_out(reg_write_o),
        .mem_to_reg_out(mem_to_reg_o), .eh_load_out(eh_load_o)
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
        $dumpfile("build/reg_ex_mem_tb.vcd"); $dumpvars(0, reg_ex_mem_tb);
        $display(""); $display("== reg_ex_mem ==");

        reset=1; limpa=0; pc4=0; alu=0; d2=0; destino=0;
        mem_write=0; reg_write=0; mem_to_reg=0; eh_load=0;
        @(posedge clk); #1;
        confere("reset zera os sinais de escrita", reg_write_o===1'b0 && mem_write_o===1'b0);
        reset=0;

        // --- um lw: a ALU produziu um ENDERECO, nao um dado ------------------
        pc4=20; alu=1000; d2=0; destino=5'd10;
        mem_write=0; reg_write=1; mem_to_reg=2'b01; eh_load=1;
        @(posedge clk); #1;
        confere("lw: endereco 1000 e destino $t2 carregados", alu_o===32'd1000 && destino_o===5'd10);
        confere("lw: eh_load = 1 avisa o forwarding a nao encaminhar", eh_load_o===1'b1);

        // --- um add: resultado util, pode ser encaminhado --------------------
        alu=1040; destino=5'd9; reg_write=1; mem_to_reg=2'b00; eh_load=0;
        @(posedge clk); #1;
        confere("add: resultado 1040 pronto para encaminhar", alu_o===32'd1040);
        confere("add: eh_load = 0", eh_load_o===1'b0);

        // --- um sw: o valor a gravar vem de dado_2 ---------------------------
        alu=1004; d2=32'd248; destino=5'd0;
        mem_write=1; reg_write=0; eh_load=0;
        @(posedge clk); #1;
        confere("sw: endereco 1004 e dado 248 ($ra na pilha)",
                alu_o===32'd1004 && d2_o===32'd248);
        confere("sw: mem_write = 1 e reg_write = 0", mem_write_o===1'b1 && reg_write_o===1'b0);

        // --- um jal: o PC+4 precisa chegar ate o fim -------------------------
        pc4=248; alu=0; destino=5'd31; reg_write=1; mem_to_reg=2'b10; mem_write=0;
        @(posedge clk); #1;
        confere("jal: PC+4 = 248 e destino = 31 ($ra)", pc4_o===32'd248 && destino_o===5'd31);

        // --- flush ------------------------------------------------------------
        limpa=1; mem_write=1; reg_write=1;
        @(posedge clk); #1;
        confere("flush: escritas canceladas", reg_write_o===1'b0 && mem_write_o===1'b0);

        $display("");
        if (erros == 0) $display("RESULTADO: todos os casos passaram");
        else            $display("RESULTADO: %0d caso(s) falharam", erros);
        $display(""); $finish;
    end
endmodule
