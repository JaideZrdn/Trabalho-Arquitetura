# Prompt para gerar o diagrama do caminho de dados — MIPS com pipeline

**Como usar.** Copie tudo que está abaixo da linha divisória e envie para a
ferramenta de geração de imagem, anexando o arquivo
`docs/caminho_dados_mips-2.pdf` como referência de estilo. Esse PDF é o
diagrama do nosso processador monociclo, feito na entrega anterior; a imagem
nova deve ser o mesmo processador reorganizado em cinco estágios.

---

Anexei um diagrama de caminho de dados de um processador MIPS monociclo
(`caminho_dados_mips-2.pdf`). Use-o como referência de estilo visual: fundo
branco, blocos de contorno preto, sinais de controle em azul-claro, blocos
acrescentados pelo projeto em laranja, rótulos em fonte sem serifa e o nome
do arquivo `.v` em fonte monoespaçada menor ao lado de cada bloco.

Preciso de uma imagem nova: **o mesmo processador reorganizado em um pipeline
de cinco estágios**. Mesmo conjunto de instruções, mesmos blocos de cálculo —
o que muda é que agora existem quatro registradores de estágio cortando o
caminho de dados na vertical, e três blocos novos de tratamento de perigos.

## Estrutura geral da figura

Orientação: fluxo da esquerda para a direita. A figura é dividida em cinco
faixas verticais por quatro barras verticais escuras e estreitas, que são os
registradores de estágio. Cada faixa recebe um título no topo:

```
   IF          |  ID           |  EX            |  MEM         |  WB
  busca        | decodificação | execução       | memória      | escrita
               |               |                |              |
          [IF/ID]        [ID/EX]          [EX/MEM]       [MEM/WB]
```

As quatro barras são retângulos altos e estreitos, preenchidos em cinza
escuro, com o rótulo girado 90° (`IF/ID`, `ID/EX`, `EX/MEM`, `MEM/WB`) e, em
monoespaçado menor, o nome do arquivo: `reg_if_id.v`, `reg_id_ex.v`,
`reg_ex_mem.v`, `reg_mem_wb.v`.

Elas atravessam toda a altura da figura. **Todo fio de dados que cruza de um
estágio para o seguinte tem que passar por dentro da barra correspondente** —
isso é o ponto central do desenho.

## Estágio 1 — IF (busca)

Blocos, de cima para baixo:

- **Somador `PC + 4`**: trapézio com entalhe, no alto. Entradas: saída do PC
  e a constante 4. Arquivo: `somador.v`.
- **Mux do próximo PC**: retângulo arredondado vertical, à esquerda do PC,
  com **duas** entradas: (a) `PC + 4`, (b) um fio grosso chamado
  `destino_controle` que vem **do estágio EX**, atravessando a figura da
  direita para a esquerda. Seleção: sinal `tomado`, também vindo do EX.
- **PC**: retângulo estreito vertical. Tem uma entrada de habilitação
  rotulada `habilita`, ligada ao sinal `segura_pc` (negado) que vem do bloco
  de detecção de hazard. Arquivo: `pc_com_habilita.v`.
- **Memória de instruções**: retângulo grande. Entrada: endereço vindo do PC.
  Saída: 32 bits de instrução. Arquivo: `memoria_instrucoes.v`.

Atravessam a barra IF/ID: a instrução de 32 bits e o valor `PC + 4`.

## Estágio 2 — ID (decodificação e leitura dos registradores)

- **Fatiador de campos**: não é um bloco, e sim o fio da instrução saindo da
  barra IF/ID e se abrindo em ramos rotulados:
  `[31:26] opcode`, `[25:21] rs`, `[20:16] rt`, `[15:11] rd`,
  `[10:6] shamt`, `[5:0] funct`, `[15:0] imediato`, `[25:0] target`.
- **Unidade de controle**: retângulo, no alto. Entradas: `opcode` e `funct`.
  Arquivo: `control_unit.v`. Ela produz, em azul-claro, os sinais:
  `reg_dst[1:0]`, `mem_to_reg[1:0]`, `alu_src_a`, `alu_src_b`, `reg_write`,
  `mem_write`, `alu_op[1:0]`, `usa_rs`, `usa_rt`, `branch_eq`, `branch_ne`,
  `jump`, `jr`, `eh_load`.
  **Importante:** desenhe esses sinais entrando na barra ID/EX, não indo
  direto para os blocos. Eles viajam junto com a instrução.
- **Banco de registradores**: retângulo grande, com as portas nomeadas
  `Read register 1`, `Read register 2`, `Write register`, `Write data`,
  `Read data 1`, `Read data 2`. Arquivo: `banco_registradores.v`.
  Rótulo adicional em laranja ao lado dele: **`BYPASS = 1 (write-first)`**.
  As três entradas de escrita (`Write register`, `Write data`, `RegWrite`)
  vêm por fios longos **do estágio WB**, atravessando a figura de volta da
  direita para a esquerda.
- **Extensor de sinal**: elipse. Entrada: `[15:0]`. Saída: 32 bits.
  Arquivo: `extensor_sinal.v`.

Atravessam a barra ID/EX: `PC+4`, `Read data 1`, `Read data 2`, imediato
estendido, `rs`, `rt`, `rd`, `shamt`, `funct`, `target[25:0]` e os catorze
sinais de controle. É a barra mais larga das quatro, justamente por isso.

A barra ID/EX tem uma entrada extra rotulada `limpa`, ligada a um OU de dois
sinais: `bolha_id_ex` (da detecção de hazard) e `limpa_id_ex` (do controle de
flush). Desenhe essa entrada em laranja.

## Estágio 3 — EX (execução) — é o estágio mais cheio

### Caminho de cálculo

- **Dois multiplexadores de encaminhamento**, um para cada operando, logo
  depois da barra ID/EX. Retângulos arredondados verticais, em laranja,
  com **três** entradas cada:
  1. o valor original vindo de ID/EX
  2. `alu_result` vindo da barra **EX/MEM** (fio de retorno, da direita para
     a esquerda)
  3. o dado final de escrita vindo da barra **MEM/WB** (fio de retorno mais
     longo, também da direita para a esquerda)

  Seleção: `forward_a[1:0]` e `forward_b[1:0]`. Arquivo: `mux_forwarding.v`.
  Esses dois fios de retorno são o elemento visualmente mais importante do
  diagrama depois das barras — desenhe-os com destaque.

- **Unidade de forwarding**: retângulo laranja, abaixo dos dois muxes.
  Arquivo: `unidade_forwarding.v`. Entradas: `rs` e `rt` de ID/EX, `usa_rs`,
  `usa_rt`, mais `destino` / `reg_write` / `eh_load` de EX/MEM e
  `destino` / `reg_write` de MEM/WB. Saídas: `forward_a` e `forward_b`.

- **Mux da 1ª entrada da ALU**: retângulo arredondado vertical. Entradas: a
  saída do mux de encaminhamento A, e o campo `shamt` estendido com zeros.
  Seleção: `alu_src_a`. Arquivo: `mux_alu_a.v`.
- **Mux da 2ª entrada da ALU**: idem. Entradas: a saída do mux de
  encaminhamento B, e o imediato estendido. Seleção: `alu_src_b`.
  Arquivo: `mux_alu_b.v`.
- **Controle da ALU**: retângulo pequeno. Entradas: `alu_op[1:0]` e
  `funct[5:0]`. Saída: `alu_control[3:0]`. Arquivo: `alu_control.v`.
- **ALU**: trapézio com entalhe, rótulo `ALU`. Duas saídas: `result` e
  `zero`. Arquivo: `alu.v`.
- **Mux do registrador destino**: retângulo arredondado vertical, com três
  entradas (`rt`, `rd`, constante `31`). Seleção: `reg_dst[1:0]`.
  Arquivo: `mux_write_reg.v`.
  **Observação:** no diagrama monociclo em anexo este bloco aparece junto ao
  banco de registradores. Aqui ele está no estágio EX — desenhe-o nesta
  faixa, não na faixa ID.

### Caminho das transferências de controle

Todo ele fica neste estágio, na parte de baixo da faixa:

- **Deslocador «Shift left 2»**: elipse pequena. Entrada: imediato estendido.
  Arquivo: `shift_left_2.v`.
- **Somador do desvio**: trapézio com entalhe. Entradas: `PC+4` de ID/EX e a
  saída do deslocador. Saída: `destino_desvio`. Arquivo: `somador.v`.
- **Cálculo do endereço de salto**: retângulo rotulado «Concatena». Entradas:
  `PC+4[31:28]` e `target[25:0]` deslocado 2 à esquerda. Saída:
  `destino_salto`. Arquivo: `jump_address_calc.v`.
- **Controle de flush**: retângulo laranja. Entradas: `branch_eq`,
  `branch_ne`, `jump`, `jr` (vindos de ID/EX) e `zero` (vindo da ALU).
  Saídas: `tomado`, `limpa_if_id`, `limpa_id_ex`.
  Arquivo: `controle_flush.v`.
- **Mux de três entradas do destino**: retângulo arredondado vertical.
  Entradas: `destino_desvio`, `destino_salto` e a **saída do mux de
  encaminhamento A** (esse é o caso do `jr`, que lê um registrador para saber
  o endereço de volta). Saída: `destino_controle`, que é o fio grosso que
  volta até o mux do PC no estágio IF.
- **Detecção de hazard**: retângulo laranja, na base da faixa, mas
  posicionado junto à divisa com o estágio ID, porque ele olha os dois ao
  mesmo tempo. Arquivo: `deteccao_hazard.v`.
  Entradas: `eh_load` e `destino` de ID/EX (ou seja, do estágio EX), e
  `rs`, `rt`, `usa_rs`, `usa_rt` de IF/ID (do estágio ID).
  Três saídas, em laranja, que vão para três lugares diferentes:
  - `segura_pc` → entrada de habilitação do PC
  - `segura_if_id` → entrada de habilitação da barra IF/ID
  - `bolha_id_ex` → entrada `limpa` da barra ID/EX

Atravessam a barra EX/MEM: `PC+4`, `alu_result`, o segundo operando já
encaminhado (o dado que o `sw` grava), o registrador destino, e os sinais
`mem_write`, `reg_write`, `mem_to_reg[1:0]`, `eh_load`.

## Estágio 4 — MEM (memória)

- **Memória de dados**: retângulo grande. Entrada de endereço: `alu_result`.
  Entrada de dado: o segundo operando. Saída: `dado_leitura`.
  Arquivo: `memoria_dados.v`. Controle: `mem_write`.
  Desenhe também a segunda porta de leitura, rotulada
  `endereco_debug` / `dado_debug`, saindo pela borda inferior da figura —
  é a porta de observação usada na FPGA.

Atravessam a barra MEM/WB: `PC+4`, `alu_result`, o dado lido da memória, o
registrador destino, `reg_write` e `mem_to_reg[1:0]`.

## Estágio 5 — WB (escrita)

- **Mux do dado escrito**: retângulo arredondado vertical, com **três**
  entradas: `alu_result`, dado lido da memória, e `PC+4` (o endereço de
  retorno gravado pelo `jal`). Seleção: `mem_to_reg[1:0]`.
  Arquivo: `mux_write_data.v`.

A saída dele e o registrador destino voltam, por fios longos da direita para
a esquerda, até as portas de escrita do banco de registradores no estágio ID.

## Sinais que NÃO devem aparecer

- Não existe sinal `MemRead` — a leitura da memória de dados é contínua.
- A unidade de controle **não** recebe o sinal `zero` e **não** produz
  `PCSrc`. No pipeline a decisão de desvio saiu da unidade de controle e
  passou para o controle de flush, no estágio EX. Se o diagrama em anexo
  mostra esse fio, remova-o.

## Legenda que a figura deve ter, num canto

- contorno preto, fundo branco → bloco que já existia no monociclo
- contorno laranja grosso, fundo laranja-claro → bloco acrescentado nesta
  entrega para tratar perigos
- barra cinza vertical → registrador de estágio
- fio azul-claro → sinal de controle
- fio laranja → sinal de stall ou de flush
- fio grosso preto da direita para a esquerda → caminho de retorno
  (encaminhamento, escrita no banco, ou destino do desvio)

Moldura tracejada em volta de toda a figura, com a etiqueta
`mips_pipeline.v`.

## Formato

Imagem única, horizontal, proporção aproximada 16:9, resolução alta o
suficiente para projetar numa apresentação e ainda ler os nomes dos arquivos.
Prefira clareza a enfeite: nenhuma sombra, nenhum gradiente, nenhum ícone.
