`timescale 1ns/1ps

module tb_mux_forwarding;
    reg [31:0] dado_original, dado_ex_mem, dado_mem_wb;
    reg [1:0] seletor;
    wire [31:0] saida;
    integer testes, erros;

    mux_forwarding #(.WIDTH(32)) dut (
        .dado_original(dado_original),
        .dado_ex_mem(dado_ex_mem),
        .dado_mem_wb(dado_mem_wb),
        .seletor(seletor),
        .saida(saida)
    );

    task verificar;
        input [255:0] descricao;
        input [31:0] esperado;
        begin
            #1;
            testes = testes + 1;
            if (saida !== esperado) begin
                erros = erros + 1;
                $display("FALHOU %0d: %0s | obtido=%h esperado=%h",
                         testes, descricao, saida, esperado);
            end else begin
                $display("OK %0d: %0s", testes, descricao);
            end
        end
    endtask

    initial begin
        testes = 0; erros = 0;
        dado_original = 32'h11111111;
        dado_ex_mem   = 32'h22222222;
        dado_mem_wb   = 32'h33333333;

        seletor = 2'b00;
        verificar("00 - original", 32'h11111111);
        seletor = 2'b10;
        verificar("10 - EX/MEM", 32'h22222222);
        seletor = 2'b01;
        verificar("01 - MEM/WB", 32'h33333333);
        seletor = 2'b11;
        verificar("11 - default original", 32'h11111111);

        dado_original = 32'h00000000;
        dado_ex_mem   = 32'hFFFFFFFF;
        dado_mem_wb   = 32'h80000000;
        seletor = 2'b10;
        verificar("EX/MEM negativo 32 bits", 32'hFFFFFFFF);
        seletor = 2'b01;
        verificar("MEM/WB bit mais alto", 32'h80000000);
        seletor = 2'b00;
        verificar("Original zero", 32'h00000000);

        $display("RESULTADO: %0d testes, %0d erros", testes, erros);
        if (erros != 0) $fatal(1, "Multiplexador reprovado");
        $finish;
    end
endmodule
