`timescale 1ns/1ps

module tb_unidade_forwarding;
    reg [4:0] id_ex_rs, id_ex_rt;
    reg id_ex_usa_rs, id_ex_usa_rt;
    reg [4:0] ex_mem_destino, mem_wb_destino;
    reg ex_mem_reg_write, ex_mem_eh_load, mem_wb_reg_write;
    wire [1:0] forward_a, forward_b;
    integer testes, erros;

    unidade_forwarding #(.REG_BITS(5)) dut (
        .id_ex_rs(id_ex_rs),
        .id_ex_rt(id_ex_rt),
        .id_ex_usa_rs(id_ex_usa_rs),
        .id_ex_usa_rt(id_ex_usa_rt),
        .ex_mem_destino(ex_mem_destino),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_eh_load(ex_mem_eh_load),
        .mem_wb_destino(mem_wb_destino),
        .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    task limpar;
        begin
            id_ex_rs = 0; id_ex_rt = 0;
            id_ex_usa_rs = 0; id_ex_usa_rt = 0;
            ex_mem_destino = 0; mem_wb_destino = 0;
            ex_mem_reg_write = 0; ex_mem_eh_load = 0;
            mem_wb_reg_write = 0;
        end
    endtask

    task verificar;
        input [255:0] descricao;
        input [1:0] esperado_a, esperado_b;
        begin
            #1;
            testes = testes + 1;
            if (forward_a !== esperado_a || forward_b !== esperado_b) begin
                erros = erros + 1;
                $display("FALHOU %0d: %0s | A=%b (esp %b), B=%b (esp %b)",
                         testes, descricao, forward_a, esperado_a,
                         forward_b, esperado_b);
            end else begin
                $display("OK %0d: %0s", testes, descricao);
            end
        end
    endtask

    initial begin
        testes = 0; erros = 0;
        limpar();
        id_ex_rs = 5'd8; id_ex_rt = 5'd9;
        id_ex_usa_rs = 1; id_ex_usa_rt = 1;
        verificar("Sem dependencia", 2'b00, 2'b00);

        limpar();
        id_ex_rs = 5'd8; id_ex_usa_rs = 1;
        ex_mem_destino = 5'd8; ex_mem_reg_write = 1;
        verificar("Distancia 1 em RS", 2'b10, 2'b00);

        limpar();
        id_ex_rt = 5'd9; id_ex_usa_rt = 1;
        ex_mem_destino = 5'd9; ex_mem_reg_write = 1;
        verificar("Distancia 1 em RT", 2'b00, 2'b10);

        limpar();
        id_ex_rs = 5'd8; id_ex_usa_rs = 1;
        mem_wb_destino = 5'd8; mem_wb_reg_write = 1;
        verificar("Distancia 2 em RS", 2'b01, 2'b00);

        limpar();
        id_ex_rt = 5'd9; id_ex_usa_rt = 1;
        mem_wb_destino = 5'd9; mem_wb_reg_write = 1;
        verificar("Distancia 2 em RT", 2'b00, 2'b01);

        limpar();
        id_ex_rs = 5'd8; id_ex_rt = 5'd9;
        id_ex_usa_rs = 1; id_ex_usa_rt = 1;
        ex_mem_destino = 5'd8; ex_mem_reg_write = 1;
        mem_wb_destino = 5'd9; mem_wb_reg_write = 1;
        verificar("EX/MEM em A, MEM/WB em B", 2'b10, 2'b01);

        limpar();
        id_ex_rs = 5'd8; id_ex_usa_rs = 1;
        ex_mem_destino = 5'd8; ex_mem_reg_write = 1;
        mem_wb_destino = 5'd8; mem_wb_reg_write = 1;
        verificar("Prioridade: EX/MEM vence em A", 2'b10, 2'b00);

        limpar();
        id_ex_rt = 5'd8; id_ex_usa_rt = 1;
        ex_mem_destino = 5'd8; ex_mem_reg_write = 1;
        mem_wb_destino = 5'd8; mem_wb_reg_write = 1;
        verificar("Prioridade: EX/MEM vence em B", 2'b00, 2'b10);

        limpar();
        id_ex_rs = 0; id_ex_usa_rs = 1;
        ex_mem_destino = 0; ex_mem_reg_write = 1;
        mem_wb_destino = 0; mem_wb_reg_write = 1;
        verificar("Registrador zero nunca encaminha", 2'b00, 2'b00);

        limpar();
        id_ex_rs = 5'd8; id_ex_rt = 5'd9;
        id_ex_usa_rs = 1; id_ex_usa_rt = 1;
        ex_mem_destino = 5'd8; mem_wb_destino = 5'd9;
        verificar("RegWrite desabilitado", 2'b00, 2'b00);

        limpar();
        id_ex_rs = 5'd8; id_ex_usa_rs = 1;
        ex_mem_destino = 5'd8; ex_mem_reg_write = 1;
        ex_mem_eh_load = 1;
        verificar("Load-use: EX/MEM indisponivel", 2'b00, 2'b00);

        limpar();
        id_ex_rs = 5'd8; id_ex_usa_rs = 1;
        ex_mem_destino = 5'd8; ex_mem_reg_write = 1;
        ex_mem_eh_load = 1;
        mem_wb_destino = 5'd8; mem_wb_reg_write = 1;
        verificar("Load recente bloqueia WB antigo", 2'b00, 2'b00);

        limpar();
        id_ex_rs = 5'd8; id_ex_rt = 5'd9;
        id_ex_usa_rs = 0; id_ex_usa_rt = 0;
        ex_mem_destino = 5'd8; ex_mem_reg_write = 1;
        mem_wb_destino = 5'd9; mem_wb_reg_write = 1;
        verificar("Origens nao utilizadas", 2'b00, 2'b00);

        limpar();
        // SLL usa RT como dado, nao usa RS.
        id_ex_rt = 5'd9; id_ex_usa_rt = 1;
        ex_mem_destino = 5'd9; ex_mem_reg_write = 1;
        verificar("SLL encaminha RT", 2'b00, 2'b10);

        limpar();
        // SW usa RT como DADO DA MEMORIA, nao como entrada aritmetica.
        id_ex_rs = 5'd4; id_ex_rt = 5'd8;
        id_ex_usa_rs = 1; id_ex_usa_rt = 1;
        ex_mem_destino = 5'd8; ex_mem_reg_write = 1;
        verificar("ADDI para SW (dado)", 2'b00, 2'b10);

        limpar();
        // LW de distancia 2: dado ja chegou ao MEM/WB.
        id_ex_rs = 5'd12; id_ex_usa_rs = 1;
        mem_wb_destino = 5'd12; mem_wb_reg_write = 1;
        verificar("LW para SLT (distancia 2)", 2'b01, 2'b00);

        limpar();
        // JAL escreve no registrador $ra = 31.
        id_ex_rs = 5'd31; id_ex_usa_rs = 1;
        mem_wb_destino = 5'd31; mem_wb_reg_write = 1;
        verificar("JAL para JR via MEM/WB", 2'b01, 2'b00);

        limpar();
        id_ex_rs = 5'd31; id_ex_usa_rs = 1;
        ex_mem_destino = 5'd31; ex_mem_reg_write = 1;
        verificar("JAL como produtor EX/MEM", 2'b10, 2'b00);

        $display("RESULTADO: %0d testes, %0d erros", testes, erros);
        if (erros != 0) $fatal(1, "Unidade de forwarding reprovada");
        $finish;
    end
endmodule
