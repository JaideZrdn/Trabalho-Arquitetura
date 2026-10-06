`timescale 1ns / 1ps

module tb_mux_write_data;
    reg [31:0] alu_result;
    reg [31:0] mem_read_data;
    reg [31:0] pc_plus_4;
    reg [1:0] mem_to_reg;
    
    wire [31:0] write_data;

    mux_write_data #( .DATA_WIDTH(32) ) dut (
        .alu_result(alu_result),
        .mem_read_data(mem_read_data),
        .pc_plus_4(pc_plus_4),
        .mem_to_reg(mem_to_reg),
        .write_data(write_data)
    );

    initial begin
        $display("Tempo | mem_to_reg | write_data");
        $monitor("%4t  |     %b     | %b", $time, mem_to_reg, write_data);

        // Valores convertidos de hexadecimal para binário (32 bits)
        alu_result    = 32'b1010_1010_1010_1010_1011_1011_1011_1011; // 0xAAAABBBB
        mem_read_data = 32'b0001_0010_0011_0100_0101_0110_0111_1000; // 0x12345678
        pc_plus_4     = 32'b0000_0000_0000_0000_0000_0000_0100_0000; // 0x00000040

        mem_to_reg = 2'b00; #10; // Testa ALU (Instruções Tipo R)
        mem_to_reg = 2'b01; #10; // Testa Memória (lw)
        mem_to_reg = 2'b10; #10; // Testa PC+4 (jal)
        mem_to_reg = 2'b11; #10; // Testa default (Deve retornar 0)
        
        $finish;
    end
endmodule