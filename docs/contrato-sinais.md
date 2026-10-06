# Contrato de sinais de controle

**Para que serve este documento:** os multiplexadores já implementados
*fixaram* a codificação dos sinais de controle. A unidade de controle precisa
emitir exatamente estes valores. Se as duas pontas discordarem, o processador
sintetiza, roda e produz resultado errado — e nenhum testbench de módulo
isolado detecta isso, porque cada módulo, sozinho, está correto.

Este é o único ponto do projeto em que um mal-entendido entre duas pessoas
vira um bug invisível. Por isso está escrito.

Os valores abaixo foram **lidos do código já commitado**, não decididos aqui.

## Sinais que selecionam caminho

| sinal | bits | valor | seleciona | módulo que consome |
|---|---|---|---|---|
| `pc_src` | 2 | `00` | `pc_plus_4` | `mux_pc` |
| | | `01` | `branch_target` | |
| | | `10` | `jump_target` | |
| | | `11` | `jr_target` | |
| `reg_dst` | 2 | `00` | campo `rt` da instrução | `mux_write_reg` |
| | | `01` | campo `rd` | |
| | | `10` | registrador 31 (`$ra`) | |
| `mem_to_reg` | 2 | `00` | resultado da ALU | `mux_write_data` |
| | | `01` | dado lido da memória | |
| | | `10` | `pc_plus_4` (para o `jal`) | |
| `alu_src_a` | 1 | `0` | `read_data_1` | `mux_alu_a` |
| | | `1` | `shamt` estendido com zeros | |
| `alu_src_b` | 1 | `0` | `read_data_2` | `mux_alu_b` |
| | | `1` | imediato estendido | |

## Sinais que habilitam escrita

| sinal | bits | efeito | módulo que consome |
|---|---|---|---|
| `escreve_reg` | 1 | `1` grava no banco de registradores na subida do clock | `banco_registradores` |
| `escreve_mem` | 1 | `1` grava na memória de dados na subida do clock | `memoria_dados` |

Nos dois casos, `0` significa "este ciclo não escreve". O banco de
registradores ignora escrita no registrador 0 mesmo com `escreve_reg = 1`.

## Ainda a definir — unidade de controle e ALU control (Pessoa B)

Estes sinais ainda não existem em código, então a codificação é livre. Assim
que forem escritos, acrescentar aqui:

- operação da ALU (`alu_control`): quais códigos para somar, subtrair, AND,
  OR e `slt`
- seleção de desvio: como distinguir `beq` de `bne` a partir do sinal `Zero`
  da ALU, e como isso vira `pc_src = 01`

## Tabela por instrução — a preencher

As doze instruções do `mem/programa.asm`. O preenchimento é decisão da
unidade de controle (cartão 8) e vai aqui quando estiver definido.

| instrução | `pc_src` | `reg_dst` | `mem_to_reg` | `alu_src_a` | `alu_src_b` | `escreve_reg` | `escreve_mem` |
|---|---|---|---|---|---|---|---|
| `add` | | | | | | | |
| `slt` | | | | | | | |
| `sll` | | | | | | | |
| `jr` | | | | | | | |
| `addi` | | | | | | | |
| `slti` | | | | | | | |
| `lw` | | | | | | | |
| `sw` | | | | | | | |
| `beq` | | | | | | | |
| `bne` | | | | | | | |
| `j` | | | | | | | |
| `jal` | | | | | | | |

Três linhas que costumam ser preenchidas errado, como alerta:

- **`sw`** não grava em registrador: `escreve_reg = 0`. O valor de `mem_to_reg`
  é indiferente, mas vale fixar `00` para não deixar sinal solto.
- **`jal`** grava em registrador **e** salta: `escreve_reg = 1`,
  `reg_dst = 10`, `mem_to_reg = 10`, `pc_src = 10`.
- **`jr`** não grava nada: só `pc_src = 11`.

## Pendência de nomenclatura

Os módulos estão em dois idiomas: `banco_registradores`, `memoria_dados`,
`extensor_sinal`, `somador` (português) e `mux_pc`, `mux_write_reg`,
`jump_address_calc` (inglês). O top-level vai instanciar os dois conjuntos e
o relatório vai descrever ambos.

Não quebra nada, mas vale a equipe decidir se padroniza antes da entrega ou
se registra a escolha no relatório como consciente.
