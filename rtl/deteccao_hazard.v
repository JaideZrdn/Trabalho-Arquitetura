// Detecta o perigo de load-use e segura o pipeline por um ciclo.
//
// O caso: um lw esta no estagio EX e a instrucao logo atras, no ID, quer
// usar o registrador que ele vai carregar. O dado so existe no fim do MEM,
// um ciclo depois do que a instrucao seguinte precisa. Nenhum encaminhamento
// resolve — o valor ainda nao foi lido da memoria.
//
// No programa da equipe isto acontece em dois pontos:
//     PC= 16   lw  $t0, 4($t1)  ->  sw  $t0, 0($t1)
//     PC=100   lw  $t4, 4($t2)  ->  slt $t0, $t4, $t3
//
// Quando detecta, tres coisas no mesmo ciclo:
//   - o PC nao avanca            (a mesma instrucao sera buscada de novo)
//   - o IF/ID nao atualiza       (a instrucao no ID fica onde esta)
//   - o ID/EX recebe uma bolha   (sinais de escrita zerados)
//
// O terceiro e o que importa. Sem ele, a instrucao repetida executaria duas
// vezes e alteraria o estado do processador.
`timescale 1ns/1ps

module deteccao_hazard #(
    parameter REG_BITS = 5
)(
    input  wire                 id_ex_eh_load,
    input  wire [REG_BITS-1:0]  id_ex_destino,   // registrador que o lw carrega
    input  wire [REG_BITS-1:0]  if_id_rs,
    input  wire [REG_BITS-1:0]  if_id_rt,
    input  wire                 if_id_usa_rs,
    input  wire                 if_id_usa_rt,
    output wire                 segura_pc,
    output wire                 segura_if_id,
    output wire                 bolha_id_ex
);
    wire colide_rs = if_id_usa_rs && (if_id_rs == id_ex_destino);
    wire colide_rt = if_id_usa_rt && (if_id_rt == id_ex_destino);

    wire parar = id_ex_eh_load &&
                 (id_ex_destino != {REG_BITS{1'b0}}) &&
                 (colide_rs || colide_rt);

    assign segura_pc    = parar;
    assign segura_if_id = parar;
    assign bolha_id_ex  = parar;
endmodule
