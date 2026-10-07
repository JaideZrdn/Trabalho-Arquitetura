# Processador MIPS Monociclo com Jumps em Verilog

**Relatório da 2ª entrega parcial — 09/10/2026**

Ana Clara Eid Freire (22401684) · Jaide Fernando de Carvalho Zardin (22350981)
· Manuela Lopes Figueira (22400983)

Curso de Engenharia da Computação — Universidade Federal do Amazonas (UFAM)
Arquitetura de Sistemas Digitais e Laboratório

> **Rascunho de trabalho.** A versão final vai no template IEEE. Seções
> marcadas com *(pendente)* ainda não podem ser escritas com honestidade —
> preenchê-las antes de o resultado existir é o que faz um relatório técnico
> perder credibilidade na arguição.

---

## Resumo

Este relatório apresenta o estado da segunda entrega do projeto de
implementação de um processador MIPS em Verilog. O escopo desta etapa é o
caminho de dados monociclo completo, incluindo as instruções de salto
(`j`, `jal`, `jr`), com todos os componentes parametrizados e verificados por
testbench. São descritos o ambiente de desenvolvimento adotado, a arquitetura
do caminho de dados, os módulos implementados, a metodologia de verificação e
as pendências para o fechamento da etapa.

---

## I. Introdução e objetivos desta etapa

A primeira entrega estabeleceu o programa de teste: o procedimento de
ordenação por inserção (`sort`/`swap`) especificado pelo professor, traduzido
para assembly MIPS, codificado em binário por um montador desenvolvido pela
equipe e verificado por execução do binário gerado.

Esta segunda etapa implementa o **hardware que executa esse programa**: o
caminho de dados de um processador MIPS monociclo. Monociclo significa que
cada instrução é concluída em um único ciclo de clock — o sinal atravessa
todos os blocos combinacionais e, no fim do ciclo, o novo valor do PC e,
quando aplicável, o registrador destino ou a memória de dados são gravados.

A consequência dessa escolha é que o período do clock precisa acomodar o
caminho crítico, que é o da instrução `lw`: PC → memória de instruções →
banco de registradores → ALU → memória de dados → banco de registradores. É
exatamente essa limitação que o pipeline da terceira etapa virá resolver.

### Conjunto de instruções implementado

O caminho de dados suporta as doze instruções efetivamente usadas pelo
programa de teste:

| formato | instruções |
|---|---|
| R | `add`, `slt`, `sll`, `jr` |
| I | `addi`, `slti`, `lw`, `sw`, `beq`, `bne` |
| J | `j`, `jal` |

Delimitar o conjunto pelo programa real, em vez de implementar o MIPS
completo, mantém a unidade de controle em doze linhas e torna a verificação
exaustiva viável.

---

## II. Ambiente de desenvolvimento

A equipe trabalha em sistemas operacionais diferentes, o que motivou separar
o fluxo de **verificação** do fluxo de **síntese**:

| etapa | ferramenta | plataforma |
|---|---|---|
| escrita e simulação dos módulos | Icarus Verilog 13.0 | macOS, Linux e Windows |
| visualização de formas de onda | arquivos `.vcd` (GTKWave / Surfer) | qualquer |
| síntese e gravação na FPGA | Intel Quartus Prime *(versão pendente)* | Windows ou Linux |
| controle de versão | Git / GitHub | qualquer |
| gestão | Trello | — |

O Quartus Prime não é publicado para macOS, o que impede que integrantes em
Mac realizem síntese, atribuição de pinos ou gravação da FPGA. A decisão da
equipe foi: **todo o RTL é escrito e validado em simulação, em qualquer
sistema operacional, e apenas a síntese exige Quartus**, executada a partir
dos mesmos arquivos do repositório.

Comando único de verificação, a partir da raiz do repositório:

```bash
make
```

O Makefile descobre os módulos automaticamente: para cada `rtl/<nome>.v`
procura o testbench correspondente em `tb/`, compila, executa e reporta o
número de casos aprovados, encerrando com código de erro se algum falhar.

*(pendente: confirmar a versão exata do Quartus Prime instalada no
laboratório — exigência 1 da rubrica.)*

---

## III. Caminho de dados

### A. Estrutura geral

O caminho de dados segue a organização clássica descrita em [1], seção 4.3,
estendida com o tratamento de saltos descrito na seção 4.4.

```
   ┌──────────────────────────────────────────────────────────────┐
   │                                                              │
   ▼                                                              │
 ┌────┐                                                           │
 │ PC │──┬──► memória de instruções ──► instrução[31:0]            │
 └────┘  │                                   │                    │
         └──► somador (+4) ──────────────────┼──────────┐         │
                                             │          │         │
      ┌──────────────┬───────────────────────┴──┐       │         │
      │              │                          │       │         │
  [31:26] op    [25:21] rs   [20:16] rt   [15:0] imediato         │
      │              │            │             │       │         │
      ▼              ▼            ▼             ▼       │         │
  ┌─────────┐   ┌───────────────────────┐  ┌──────────┐ │         │
  │controle │   │ banco de registradores│  │ extensor │ │         │
  └─────────┘   └───────────────────────┘  │ de sinal │ │         │
      │            │ dado1    │ dado2      └──────────┘ │         │
      │ sinais     │          │                 │       │         │
      │            ▼          ▼                 ▼       │         │
      │       ┌─────────┐  ┌─────────────────────┐      │         │
      │       │mux_alu_a│  │     mux_alu_b       │      │         │
      │       └─────────┘  └─────────────────────┘      │         │
      │            │              │                     │         │
      │            ▼              ▼                     │         │
      │         ┌──────────────────┐                    │         │
      │         │       ALU        │                    │         │
      │         └──────────────────┘                    │         │
      │            │ resultado  │ Zero                  │         │
      │            ▼            └──► lógica de desvio ──┼─────────┤
      │      ┌──────────────┐        + jump_address_calc│      mux_pc
      │      │memória dados │                           │
      │      └──────────────┘                           │
      │            │                                    │
      │            └──►┌───────────────┐◄── ALU         │
      │                │ mux_write_data│◄── pc_plus_4 ◄─┘
      │                └───────────────┘
      │                        │
      └────────────────────────┴──► banco de registradores
                                    (endereço vindo de mux_write_reg)
```

### B. O que as instruções de salto acrescentam

O caminho de dados monociclo básico não contempla `j`, `jal` nem `jr`. Os
acréscimos são pontuais e constituem o foco desta entrega:

| instrução | acréscimo ao caminho de dados |
|---|---|
| `j` | entrada no `mux_pc`; endereço formado por `{PC+4[31:28], target, 2'b00}` no `jump_address_calc` |
| `jal` | entrada `31` no `mux_write_reg` e entrada `pc_plus_4` no `mux_write_data` — a instrução grava em registrador *e* desvia |
| `jr` | entrada no `mux_pc` vinda da primeira saída do banco de registradores |
| `sll` | entrada `shamt` no `mux_alu_a`, já que o deslocamento vem da própria instrução e não de um registrador |

### C. Interface entre controle e caminho de dados

A codificação dos sinais de controle está especificada em
[`docs/contrato-sinais.md`](contrato-sinais.md). Esse documento existe porque
a discordância entre a unidade de controle e os multiplexadores é o único
erro do projeto que **nenhum testbench de módulo isolado consegue detectar**:
cada bloco, verificado sozinho, está correto; o defeito só aparece na
integração.

---

## IV. Módulos implementados

| módulo | função | tipo | testbench |
|---|---|---|---|
| `pc` | registrador do contador de programa | sequencial | 10 casos |
| `somador` | soma de dois valores; usado em PC+4 e no destino de desvio | combinacional | 9 casos |
| `memoria_instrucoes` | ROM do programa; carrega `mem/programa.txt` | combinacional | 6 casos |
| `banco_registradores` | 32 registradores, duas leituras e uma escrita | misto | 9 casos |
| `extensor_sinal` | estende o imediato de 16 para 32 bits com sinal | combinacional | 12 casos |
| `memoria_dados` | leitura e escrita de palavras, para `lw` e `sw` | misto | 11 casos |
| `mux_alu_b` | seleciona registrador ou imediato na entrada B da ALU | combinacional | 6 casos |
| `mux_alu_a` | seleciona registrador ou `shamt` na entrada A | combinacional | conferência visual |
| `mux_pc` | seleciona PC+4, desvio, salto ou `jr` | combinacional | conferência visual |
| `mux_write_reg` | seleciona `rt`, `rd` ou `$ra` como destino | combinacional | conferência visual |
| `mux_write_data` | seleciona ALU, memória ou PC+4 como dado escrito | combinacional | conferência visual |
| `jump_address_calc` | monta o endereço de salto do formato J | combinacional | conferência visual |
| `alu` | operações aritméticas e lógicas; gera o sinal `zero` | combinacional | 15 casos |
| `alu_control` | decodifica `alu_op` + `funct` na operação da ALU | combinacional | 10 casos |
| `control_unit` | emite todos os sinais de controle a partir do opcode | combinacional | 15 casos |
| `shift_left_2` | multiplica por 4 o imediato do desvio | combinacional | 6 casos |
| **`mips_monociclo`** | **top-level: instancia os dezesseis blocos e liga a fiação** | — | **12 casos** |

### Decisões de projeto que valem registro

**Leitura combinacional, escrita sequencial.** No banco de registradores e na
memória de dados, a leitura não espera borda de clock — o dado precisa estar
disponível ainda dentro do ciclo para a ALU usar. A escrita só ocorre na
subida do clock. Essa assimetria é o que torna o monociclo possível.

**O registrador `$zero` é fiação, não convenção.** A leitura do endereço 0
devolve zero e a escrita no endereço 0 é descartada, por construção. O
programa de teste depende disso: `addi $s0, $zero, 0` e `add $s3, $a0, $zero`
só funcionam porque o hardware garante o valor.

**Profundidade da memória de dados: 256 palavras.** O valor não é arbitrário.
Simulando o binário do programa e registrando todos os endereços de dados
acessados, o maior é 1020, correspondente à palavra 255. O `$sp` inicia em
1024, a pilha ocupa as palavras 251 a 255 e o vetor de teste ocupa 0 a 7,
restando 243 palavras livres entre eles. Memória menor faria a pilha colidir
com o vetor, corrompendo a ordenação sem gerar erro algum.

**Somador separado da ALU.** No monociclo, o cálculo de PC+4, o cálculo do
destino de desvio e a operação da instrução ocorrem no mesmo ciclo. Não é
possível reaproveitar a ALU para os três, o que justifica as duas instâncias
do módulo `somador`.

---

## V. Metodologia de verificação

Cada módulo possui um testbench próprio em `tb/`, que instancia o módulo,
aplica estímulos e compara as saídas com valores esperados, reportando
aprovação ou falha caso a caso.

Duas escolhas metodológicas:

**Os estímulos vêm do programa real.** Os casos de teste não são valores
arbitrários. O testbench do `extensor_sinal` verifica o imediato `-20` do
`addi $sp, $sp, -20`; o do `somador` verifica o destino `140` do
`beq $t0, $zero, exit1` que está no endereço 72; o da `memoria_instrucoes`
compara contra os binários gerados pelo montador da própria equipe. Verificar
contra o programa que o processador vai executar expõe erros que um teste
genérico não alcançaria.

**Os casos incluem as bordas.** O `extensor_sinal` é testado em `0x7FFF` e
`0x8000` — um bit de diferença na entrada que inverte os dezesseis bits
superiores da saída. O `banco_registradores` é testado gravando em `$zero`
para confirmar que a escrita é descartada.

Estado atual da verificação:

```
17 módulos com testbench, 121 casos, todos aprovados
```

Cinco testbenches — os dos multiplexadores e do `jump_address_calc` — imprimem
valor esperado e obtido lado a lado para conferência visual, sem contagem
automática de erros. O Makefile os marca com `ok*` para distinguir dos que se
auto-verificam.

---

## VI. Parametrização

Todos os módulos são parametrizados: nenhuma largura literal aparece no corpo
dos blocos. As larguras derivam de `parameter` declarados no cabeçalho
(`LARGURA`, `DATA_WIDTH`, `N_REGS`, `PROFUNDIDADE`, `SHAMT_WIDTH`).

Quando aplicável, os testbenches instanciam o **mesmo módulo duas vezes com
larguras diferentes**, demonstrando que o parâmetro controla efetivamente o
hardware gerado e não é apenas declarativo. O testbench do `extensor_sinal`
verifica as configurações 16→32 e 8→32; o do `somador`, 32 e 16 bits; o do
`pc`, 32 bits com início em 0 e 16 bits com início em `0x0100`.

Uma exceção conhecida: em `jump_address_calc`, os valores `4` e `2` da
concatenação são fixos, embora `TARGET_WIDTH` seja parâmetro. Os três valores
não são independentes — decorrem da definição do formato J do MIPS — e a
documentação do módulo deve registrar isso.

---

## VII. Estado atual e pendências

**Concluído:** dezessete módulos implementados, incluindo o top-level; todos
com testbench aprovado, somando 121 casos; contrato de sinais de controle
documentado e verificado instrução a instrução; processador completo
executando o programa de ordenação corretamente em simulação; ambiente de
simulação funcionando nas três máquinas da equipe.

**Pendente:**

| item | responsável | rubrica |
|---|---|---|
| Projeto Quartus, versão confirmada e síntese na DE2-115 | C | 1 |
| Vídeo da apresentação no YouTube | equipe | 5 |
| Converter os cinco testbenches de conferência visual em auto-verificáveis | C | 3 |

## VIII. Resultados

O processador completo foi integrado e executa o programa de ordenação em
simulação. O testbench `tb/mips_monociclo_tb.v` carrega `mem/programa.txt` na
memória de instruções, libera o reset e deixa o processador executar até
parar sozinho no laço `j end`, conferindo em seguida o conteúdo da memória de
dados.

```
== processador completo executando mem/programa.txt ==
   vetor inicial : 5 3 8 1 9 2 7 4
  ok    reset: PC = 0
  ok    parou no halt depois de 406 ciclos, PC = 248
   vetor final   : 1 2 3 4 5 7 8 9
   esperado      : 1 2 3 4 5 7 8 9
  ok    $sp restaurado em 1024 ao final do sort
  ok    $zero permanece 0
RESULTADO: todos os casos passaram
```

Três observações sobre o resultado:

**O vetor é ordenado corretamente**, satisfazendo o critério objetivo de
sucesso definido no relatório da primeira entrega.

**A contagem de ciclos confere com a previsão.** Antes de o hardware existir,
o binário gerado pelo montador foi executado por um interpretador que
reproduz o ciclo de busca-decodificação-execução, resultando em 404
instruções. O processador em Verilog parou em 406 ciclos — as duas unidades
adicionais correspondem ao ciclo de reset e ao ciclo em que a repetição do PC
é detectada. A coincidência entre as duas contagens, obtidas por caminhos
independentes, é evidência forte de que o caminho de dados executa exatamente
o programa especificado.

**O estado da máquina ao final está consistente.** O `$sp` retorna a 1024,
confirmando que o epílogo de `sort()` restaurou a pilha corretamente, e o
`$zero` permanece nulo, confirmando que a proteção por hardware do registrador
0 resistiu a todas as instruções executadas.

A verificação do processador completo é qualitativamente diferente da
verificação dos módulos isolados: os testbenches de módulo provam que cada
peça funciona sozinha, enquanto este prova que a **fiação entre elas** está
correta. Um único sinal trocado no top-level produziria um vetor desordenado,
mesmo com todos os módulos individualmente aprovados.

---

## Referências

[1] D. A. Patterson e J. L. Hennessy, *Computer Organization and Design — The
Hardware/Software Interface*, 4ª edição revisada. Morgan Kaufmann / Academic
Press, 2012. Capítulo 4, seções 4.1 a 4.4.
