`timescale 1ns/1ps

// Testa os 20 pares de distancia 1 e os 8 pares de distancia 2
// encontrados nos enderecos 00..3E do programa MIPS fornecido.
// Este teste varre o ROM como sequencia ESTATICA: nao executa desvios,
// stalls nem o processador inteiro. Os casos de load-use exigem hazard.
module tb_forwarding_programa;
    reg [31:0] rom [0:255];
    reg [4:0] id_ex_rs, id_ex_rt;
    reg id_ex_usa_rs, id_ex_usa_rt;
    reg [4:0] ex_mem_destino, mem_wb_destino;
    reg ex_mem_reg_write, ex_mem_eh_load, mem_wb_reg_write;
    wire [1:0] forward_a, forward_b;

    reg [31:0] original_a, original_b, dado_ex_mem, dado_mem_wb;
    wire [31:0] dado_a, dado_b;
    reg [1:0] esperado_a, esperado_b;
    reg [31:0] valor_esperado_a, valor_esperado_b;
    reg dep1, dep2;
    integer i, erros, checagens, distancia_1, distancia_2, load_use;

    unidade_forwarding dut (
        .id_ex_rs(id_ex_rs), .id_ex_rt(id_ex_rt),
        .id_ex_usa_rs(id_ex_usa_rs), .id_ex_usa_rt(id_ex_usa_rt),
        .ex_mem_destino(ex_mem_destino),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_eh_load(ex_mem_eh_load),
        .mem_wb_destino(mem_wb_destino),
        .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    mux_forwarding #(.WIDTH(32)) mux_a (
        .dado_original(original_a), .dado_ex_mem(dado_ex_mem),
        .dado_mem_wb(dado_mem_wb), .seletor(forward_a), .saida(dado_a)
    );

    mux_forwarding #(.WIDTH(32)) mux_b (
        .dado_original(original_b), .dado_ex_mem(dado_ex_mem),
        .dado_mem_wb(dado_mem_wb), .seletor(forward_b), .saida(dado_b)
    );

    function [4:0] destino;
        input [31:0] instr;
        reg [5:0] op, func;
        begin
            op = instr[31:26];
            func = instr[5:0];
            destino = 5'd0;
            case (op)
                6'h00: begin
                    if (instr != 0 && (func == 6'h00 ||
                                       func == 6'h20 || func == 6'h2A))
                        destino = instr[15:11]; // sll, add, slt
                end
                6'h03: destino = 5'd31; // jal: $ra
                6'h08, 6'h0A, 6'h23: destino = instr[20:16]; // addi, slti, lw
                default: destino = 5'd0;
            endcase
        end
    endfunction

    function usa_rs;
        input [31:0] instr;
        reg [5:0] op, func;
        begin
            op = instr[31:26];
            func = instr[5:0];
            usa_rs = 1'b0;
            case (op)
                6'h00: usa_rs = (func == 6'h20 || func == 6'h2A ||
                                 func == 6'h08); // add, slt, jr
                6'h04, 6'h05, 6'h08, 6'h0A, 6'h23, 6'h2B:
                    usa_rs = 1'b1; // beq, bne, addi, slti, lw, sw
                default: usa_rs = 1'b0;
            endcase
        end
    endfunction

    function usa_rt;
        input [31:0] instr;
        reg [5:0] op, func;
        begin
            op = instr[31:26];
            func = instr[5:0];
            usa_rt = 1'b0;
            case (op)
                6'h00: usa_rt = (instr != 0 &&
                                 (func == 6'h00 || func == 6'h20 ||
                                  func == 6'h2A)); // sll, add, slt
                6'h04, 6'h05, 6'h2B: usa_rt = 1'b1; // beq, bne, sw
                default: usa_rt = 1'b0;
            endcase
        end
    endfunction

    function eh_load;
        input [31:0] instr;
        begin
            eh_load = (instr[31:26] == 6'h23);
        end
    endfunction

    // Referencia independente de selecao, por operando.
    function [1:0] selecao_esperada;
        input [4:0] fonte, destino_recente, destino_antigo;
        input usada, escreve_recente, carga_recente, escreve_antigo;
        begin
            selecao_esperada = 2'b00;
            if (usada && fonte != 0) begin
                if (escreve_recente && destino_recente != 0 &&
                    fonte == destino_recente) begin
                    if (!carga_recente)
                        selecao_esperada = 2'b10;
                    // Caso contrario: falta dado; stall sera necessario.
                end else if (escreve_antigo && destino_antigo != 0 &&
                             fonte == destino_antigo) begin
                    selecao_esperada = 2'b01;
                end
            end
        end
    endfunction

    function [31:0] valor_esperado;
        input [1:0] selecao;
        input [31:0] original, recente, antigo;
        begin
            case (selecao)
                2'b10: valor_esperado = recente;
                2'b01: valor_esperado = antigo;
                default: valor_esperado = original;
            endcase
        end
    endfunction

    task conferir;
        input [255:0] rotulo;
        begin
            #1;
            checagens = checagens + 1;
            if (forward_a !== esperado_a || forward_b !== esperado_b ||
                dado_a !== valor_esperado_a || dado_b !== valor_esperado_b) begin
                erros = erros + 1;
                $display("FALHOU %0s: A=%b/%b, B=%b/%b, dadoA=%h/%h, dadoB=%h/%h",
                         rotulo, forward_a, esperado_a,
                         forward_b, esperado_b,
                         dado_a, valor_esperado_a, dado_b, valor_esperado_b);
            end
        end
    endtask

    initial begin
        $readmemb("mem/programa.txt", rom);
        checagens = 0; erros = 0;
        distancia_1 = 0; distancia_2 = 0; load_use = 0;

        for (i = 0; i < 63; i = i + 1) begin
            // Consumidora em EX. Produtoras a 1 e 2 posicoes anteriores.
            id_ex_rs = rom[i][25:21];
            id_ex_rt = rom[i][20:16];
            id_ex_usa_rs = usa_rs(rom[i]);
            id_ex_usa_rt = usa_rt(rom[i]);

            ex_mem_destino = 0; ex_mem_eh_load = 0;
            mem_wb_destino = 0;
            if (i >= 1) begin
                ex_mem_destino = destino(rom[i-1]);
                ex_mem_eh_load = eh_load(rom[i-1]);
            end
            if (i >= 2)
                mem_wb_destino = destino(rom[i-2]);
            ex_mem_reg_write = (ex_mem_destino != 0);
            mem_wb_reg_write = (mem_wb_destino != 0);

            dep1 = ex_mem_reg_write && (
                (id_ex_usa_rs && ex_mem_destino == id_ex_rs) ||
                (id_ex_usa_rt && ex_mem_destino == id_ex_rt));
            dep2 = mem_wb_reg_write && (
                (id_ex_usa_rs && mem_wb_destino == id_ex_rs) ||
                (id_ex_usa_rt && mem_wb_destino == id_ex_rt));

            if (dep1) begin
                distancia_1 = distancia_1 + 1;
                if (ex_mem_eh_load) load_use = load_use + 1;
                $display("RAW d1: produtor=%02h consumidor=%02h %s",
                         i-1, i, ex_mem_eh_load ? "(STALL)" : "");
            end
            if (dep2) begin
                distancia_2 = distancia_2 + 1;
                $display("RAW d2: produtor=%02h consumidor=%02h", i-2, i);
            end

            // Os tres caminhos usam padroes de dados diferentes.
            original_a = 32'h11110000 + i;
            original_b = 32'hAAAA0000 + i;
            dado_ex_mem = 32'h22220000 + i;
            dado_mem_wb = 32'h33330000 + i;

            esperado_a = selecao_esperada(
                id_ex_rs, ex_mem_destino, mem_wb_destino,
                id_ex_usa_rs, ex_mem_reg_write, ex_mem_eh_load,
                mem_wb_reg_write);
            esperado_b = selecao_esperada(
                id_ex_rt, ex_mem_destino, mem_wb_destino,
                id_ex_usa_rt, ex_mem_reg_write, ex_mem_eh_load,
                mem_wb_reg_write);
            valor_esperado_a = valor_esperado(
                esperado_a, original_a, dado_ex_mem, dado_mem_wb);
            valor_esperado_b = valor_esperado(
                esperado_b, original_b, dado_ex_mem, dado_mem_wb);
            conferir("Varredura da ROM");

            // Verificacoes criticas com enderecos do programa.
            if (i == 'h03 && forward_a !== 2'b10) begin
                erros = erros + 1;
                $display("FALHOU prioridade em PC=12: EX/MEM deve vencer");
            end
            if (i == 'h1A && (forward_a !== 2'b00 ||
                              forward_b !== 2'b01)) begin
                erros = erros + 1;
                $display("FALHOU PC=104: lw t4 exige stall; t3 vem de WB");
            end
            if (i == 'h29 && forward_a !== 2'b01) begin
                erros = erros + 1;
                $display("FALHOU PC=164: lw ra -> jr ra, distancia 2");
            end
            if (i == 'h2D && (forward_a !== 2'b01 ||
                              forward_b !== 2'b10)) begin
                erros = erros + 1;
                $display("FALHOU PC=180: SW precisa A de WB e B de EX/MEM");
            end
        end

        // Depois de UM stall: produtor lw avanca para MEM/WB,
        // a instrucao consumidora chega ao EX e pode encaminhar.
        // PC 16 (lw t0) -> PC 20 (sw t0): RT eh dado de escrita.
        id_ex_rs = 5'd9; id_ex_rt = 5'd8;
        id_ex_usa_rs = 1; id_ex_usa_rt = 1;
        ex_mem_destino = 0; ex_mem_reg_write = 0; ex_mem_eh_load = 0;
        mem_wb_destino = 5'd8; mem_wb_reg_write = 1;
        original_a = 32'h00000064;
        original_b = 32'hDEADBEEF;
        dado_mem_wb = 32'h12345678;
        esperado_a = 2'b00; esperado_b = 2'b01;
        valor_esperado_a = original_a;
        valor_esperado_b = dado_mem_wb;
        conferir("Depois do stall PC=16 -> PC=20");

        // PC 100 (lw t4) -> PC 104 (slt t0,t4,t3).
        // t3 ja foi gravado; t4 vem de MEM/WB.
        id_ex_rs = 5'd12; id_ex_rt = 5'd11;
        id_ex_usa_rs = 1; id_ex_usa_rt = 1;
        ex_mem_destino = 0; ex_mem_reg_write = 0; ex_mem_eh_load = 0;
        mem_wb_destino = 5'd12; mem_wb_reg_write = 1;
        original_a = 32'h11111111;
        original_b = 32'h00000005;
        dado_mem_wb = 32'h00000003;
        esperado_a = 2'b01; esperado_b = 2'b00;
        valor_esperado_a = dado_mem_wb;
        valor_esperado_b = original_b;
        conferir("Depois do stall PC=100 -> PC=104");

        if (distancia_1 != 20 || distancia_2 != 8 || load_use != 2) begin
            erros = erros + 1;
            $display("CONTAGEM INCORRETA: d1=%0d (20), d2=%0d (8), load-use=%0d (2)",
                     distancia_1, distancia_2, load_use);
        end
        $display("--------------------------------------------------");
        $display("Dependencias d1=%0d, d2=%0d, load-use=%0d",
                 distancia_1, distancia_2, load_use);
        $display("Checagens=%0d, erros=%0d", checagens, erros);
        if (erros != 0) $fatal(1, "Forwarding do programa reprovado");
        $display("PASSOU: verificacao estatica do programa MIPS");
        $finish;
    end
endmodule
