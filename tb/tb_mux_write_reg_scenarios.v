`timescale 1ns / 1ps

module tb_mux_write_reg_scenarios;
    reg [4:0] rt;
    reg [4:0] rd;
    reg [1:0] reg_dst;
    wire [4:0] write_reg_out;

    // A porta foi corrigida de .write_reg para .write_register
    mux_write_reg #( .REG_WIDTH(5) ) dut (
        .rt(rt), 
        .rd(rd), 
        .reg_dst(reg_dst), 
        .write_register(write_reg_out) 
    );

    initial begin
        $display("Tempo | reg_dst | write_register (Destino)");
        $monitor("%4t  |    %b   | %b", $time, reg_dst, write_reg_out);

        // Valores convertidos para binário de 5 bits
        rt = 5'b01000; // Registrador 8 ($t0)
        rd = 5'b01001; // Registrador 9 ($t1)

        // 1. Instrução Tipo I (lw $t0) -> Deve escolher rt (01000)
        reg_dst = 2'b00; #10;
        
        // 2. Instrução Tipo R (sll $t1) -> Deve escolher rd (01001)
        reg_dst = 2'b01; #10;
        
        // 3. Instrução JAL -> Deve forçar a escrita no $ra (11111 = 31)
        reg_dst = 2'b10; #10;
        
        $finish;
    end
endmodule