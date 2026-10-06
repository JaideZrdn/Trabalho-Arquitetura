`timescale 1ns / 1ps

module tb_mux_alu_a_scenarios;
    reg [31:0] read_data_1;
    reg [4:0] shamt;
    reg alu_src_a;
    wire [31:0] alu_input_a;

    mux_alu_a dut (
        .read_data_1(read_data_1), 
        .shamt(shamt),
        .alu_src_a(alu_src_a), 
        .alu_input_a(alu_input_a)
    );

    initial begin
        // Configuração dos estímulos de teste
        read_data_1 = 32'd50; // Valor vindo do registrador ($a1 = 50)
        shamt       = 5'd2;   // Valor constante extraído da instrução (sll $t1, $a1, 2)

        // Cabeçalho para o terminal
        $display("=========================================================================================");
        $display("                              TESTBENCH: MUX_ALU_A                                       ");
        $display("=========================================================================================");
        $display("Tempo | alu_src_a | Cenário de Aplicação             | Saída na ALU em Binário (32 bits)");
        $display("-----------------------------------------------------------------------------------------");

        // 1. Instrução Normal (ex: add $t0, $a1, $a2)
        // Deve selecionar o valor vindo do registrador (50)
        alu_src_a = 1'b0; 
        #10;
        $display("%4t  |     %b     | Normal (add/sub) - Deixa reg (50)| %b", $time, alu_src_a, alu_input_a);

        // 2. Instrução de Shift (sll $t1, $a1, 2)
        // Deve selecionar o valor constante 'shamt' com extensão de 27 zeros à esquerda (2)
        alu_src_a = 1'b1; 
        #10;
        $display("%4t  |     %b     | Shift (sll)      - Ejeta shamt (2)| %b", $time, alu_src_a, alu_input_a);

        $display("=========================================================================================");
        $finish;
    end
endmodule