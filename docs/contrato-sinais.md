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

## Operação da ALU

Definida em `rtl/alu.v` e decodificada por `rtl/alu_control.v`.

| `alu_op` | significado | de onde vem a operação |
|---|---|---|
| `00` | ADD | `lw`, `sw`, `addi` — cálculo de endereço e soma com imediato |
| `01` | SUB | `beq`, `bne` — a subtração é o que gera o sinal `zero` |
| `10` | ver `funct` | instruções de formato R |
| `11` | SLT | `slti` |

Códigos emitidos pelo `alu_control` para a ALU:

| código | operação |
|---|---|
| `0000` | AND |
| `0001` | OR |
| `0010` | ADD |
| `0110` | SUB |
| `0111` | SLT (comparação com sinal) |
| `1000` | SLL (desloca a entrada B pela quantidade na entrada A) |

O `sll` depende da convenção fixada pelo `mux_alu_a`: o `shamt` entra pela
entrada **A** e o valor do registrador pela entrada **B**. Por isso a operação
é `b << a`, e não o contrário.

## Decisão de desvio

A unidade de controle recebe o sinal `zero` da ALU e resolve o `pc_src`
internamente:

```
pc_src = 01   se   (beq e zero=1)  ou  (bne e zero=0)
pc_src = valor base da instrução, caso contrário
```

Não há laço combinacional: `alu_op` não depende de `zero`; apenas `pc_src`
depende.

## Tabela por instrução

Implementada em `rtl/control_unit.v` e verificada caso a caso em
`tb/control_unit_tb.v`.

| instrução | `pc_src` | `reg_dst` | `mem_to_reg` | `alu_src_a` | `alu_src_b` | `reg_write` | `mem_write` | `alu_op` |
|---|---|---|---|---|---|---|---|---|
| `add` | `00` | `01` | `00` | `0` | `0` | `1` | `0` | `10` |
| `slt` | `00` | `01` | `00` | `0` | `0` | `1` | `0` | `10` |
| `sll` | `00` | `01` | `00` | **`1`** | `0` | `1` | `0` | `10` |
| `jr` | **`11`** | `00` | `00` | `0` | `0` | `0` | `0` | `00` |
| `addi` | `00` | `00` | `00` | `0` | `1` | `1` | `0` | `00` |
| `slti` | `00` | `00` | `00` | `0` | `1` | `1` | `0` | **`11`** |
| `lw` | `00` | `00` | **`01`** | `0` | `1` | `1` | `0` | `00` |
| `sw` | `00` | `00` | `00` | `0` | `1` | **`0`** | **`1`** | `00` |
| `beq` | `01` se `zero=1`, senão `00` | `00` | `00` | `0` | `0` | `0` | `0` | `01` |
| `bne` | `01` se `zero=0`, senão `00` | `00` | `00` | `0` | `0` | `0` | `0` | `01` |
| `j` | **`10`** | `00` | `00` | `0` | `0` | `0` | `0` | `00` |
| `jal` | **`10`** | **`10`** | **`10`** | `0` | `0` | `1` | `0` | `00` |

Onde o valor é indiferente (por exemplo `mem_to_reg` durante um `sw`), a
unidade de controle emite `0` em vez de deixar o sinal solto. Isso evita
propagação de `x` na simulação e torna o comportamento determinístico.

## Pendência de nomenclatura

Os módulos estão em dois idiomas: `banco_registradores`, `memoria_dados`,
`extensor_sinal`, `somador` (português) e `mux_pc`, `mux_write_reg`,
`jump_address_calc` (inglês). O top-level vai instanciar os dois conjuntos e
o relatório vai descrever ambos.

Não quebra nada, mas vale a equipe decidir se padroniza antes da entrega ou
se registra a escolha no relatório como consciente.
