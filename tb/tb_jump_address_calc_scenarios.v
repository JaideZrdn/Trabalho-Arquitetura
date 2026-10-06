`timescale 1ns / 1ps

module tb_jump_address_calc_scenarios;
    reg [31:0] pc_plus_4;
    reg [25:0] target;
    wire [31:0] jump_addr_out;

    jump_address_calc dut (
        .pc_plus_4(pc_plus_4), 
        .target(target), 
        .jump_address(jump_addr_out) // Corrigido aqui: de .jump_addr para .jump_address
    );

    initial begin
        // 0x00400044 convertido para binário (32 bits). Bits [31:28] são 4'b0000.
        pc_plus_4 = 32'b0000_0000_0100_0000_0000_0000_0100_0100; 
        
        // 0x00401000 >> 2 vira 0x0100400 (26 bits). Convertido para binário:
        target = 26'b00_0001_0000_0000_0100_0000_0000;

        $display("=========================================================================================");
        $display("                          TESTBENCH: JUMP_ADDRESS_CALC                                   ");
        $display("=========================================================================================");
        $display("PC+4 (Entrada)                      | %b", pc_plus_4);
        $display("Target (26 bits extraídos)          |       %b", target);
        
        #10;
        
        $display("-----------------------------------------------------------------------------------------");
        $display("Endereço reconstituído (swap)       | %b", jump_addr_out);
        $display("=========================================================================================");
        
        $finish;
    end
endmodule