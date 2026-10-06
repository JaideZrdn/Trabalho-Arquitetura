`timescale 1ns / 1ps

module tb_mux_pc_scenarios;
    reg [31:0] pc_plus_4;
    reg [31:0] branch_target;
    reg [31:0] jump_target;
    reg [31:0] jr_target;
    reg [1:0] pc_src;
    wire [31:0] next_pc;

    mux_pc #( .DATA_WIDTH(32), .SEL_WIDTH(2) ) dut (
        .pc_plus_4(pc_plus_4), .branch_target(branch_target),
        .jump_target(jump_target), .jr_target(jr_target),
        .pc_src(pc_src), .next_pc(next_pc)
    );

    initial begin
        $display("Cenario de Fluxo | Esperado                                 | Obtido");
        
        // Valores reais convertidos para binário (32 bits)
        pc_plus_4     = 32'b0000_0000_0100_0000_0000_0000_0100_0100; // 0x00400044
        branch_target = 32'b0000_0000_0100_0000_0000_0000_1000_0000; // 0x00400080
        jump_target   = 32'b0000_0000_0100_0000_0001_0000_0000_0000; // 0x00401000
        jr_target     = 32'b0000_0000_0100_0000_0000_0000_0010_1000; // 0x00400028

        // 1. Execução normal (add, sll, lw)
        pc_src = 2'b00; #10; 
        $display("Normal (PC+4)    | %b | %b", pc_plus_4, next_pc);

        // 2. beq $t0, $zero, for2tst
        pc_src = 2'b01; #10;
        $display("Branch (for2tst) | %b | %b", branch_target, next_pc);

        // 3. jal swap
        pc_src = 2'b10; #10;
        $display("Jump (jal swap)  | %b | %b", jump_target, next_pc);

        // 4. jr $ra (Fim do swap)
        pc_src = 2'b11; #10;
        $display("JR (Volta p/main)| %b | %b", jr_target, next_pc);
        
        $finish;
    end
endmodule