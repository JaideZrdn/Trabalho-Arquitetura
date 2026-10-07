# fpga/ — invólucro de placa (DE2-115)

Nada aqui faz parte do processador. São as peças que existem **só** para
mostrar o resultado numa placa física: converter clock, filtrar botão,
acender display.

O `rtl/mips_monociclo.v` não sabe que existe uma DE2-115 — tem apenas `clk`,
`reset` e portas de observação. Essa separação é proposital: o mesmo
processador roda em simulação, em outra FPGA, ou com outro esquema de
display, sem alterar uma linha.

| arquivo | função |
|---|---|
| `de2_115_top.v` | topo de placa: liga o processador nas chaves, botões, LEDs e displays |
| `divisor_clock.v` | 50 MHz → ~1 Hz, para a execução ser visível a olho |
| `botao_pulso.v` | filtra o repique do botão e gera um pulso limpo por aperto |
| `decodificador_7seg.v` | um dígito hexadecimal em 7 segmentos (ativo em nível **baixo**) |
| `tb/de2_115_top_tb.v` | testbench: confere o dígito aceso em cada posição das chaves |

## Controles na placa

| controle | função |
|---|---|
| `KEY[0]` | reset (ativo em nível baixo) |
| `KEY[1]` | avança uma instrução, no modo passo-a-passo |
| `SW[17]` | `0` = clock automático ~1 Hz · `1` = passo-a-passo |
| `SW[2:0]` | qual posição do vetor mostrar, `v[0]` a `v[7]` |

| mostrador | conteúdo |
|---|---|
| `HEX3..HEX0` | valor de `v[i]`, em hexadecimal |
| `HEX4` | o índice `i` selecionado |
| `HEX7..HEX6` | PC atual (vai até `0xF8` = 248) |
| `LEDR[7:0]` | PC em binário — dá para ver o programa andando |
| `LEDG[0]` | aceso quando o programa terminou |
| `LEDG[8]` | pisca junto com o clock do processador |

## Roteiro de demonstração

1. `SW[17] = 0`. Aperta e solta `KEY[0]`. O programa roda em uns 7 minutos a
   1 Hz; girando `SW[2:0]` dá para ver o vetor sendo ordenado ao vivo.
2. `SW[17] = 1`. Cada aperto de `KEY[1]` avança **uma** instrução, e o PC nos
   LEDs mostra o `beq` voltando e o `jal` saltando.

Para acelerar, reduza o parâmetro `DIVISOR` do `de2_115_top`:
`25_000_000` = 1 Hz, `5_000_000` = 5 Hz, `500_000` = 50 Hz.

## Caminho do programa

O parâmetro `ARQUIVO_PROGRAMA` tem valor padrão `"../mem/programa.txt"`,
relativo ao **diretório do projeto Quartus**. Com o `.qpf` em `quartus/`, o
programa fica um nível acima. Se o projeto for criado em outro lugar, ajuste
o parâmetro.

## Nota de projeto

O clock do processador é derivado — dividido, ou gerado por botão — e
selecionado por um multiplexador. Em projeto industrial isso se faz com
habilitação de clock, não com multiplexador de clock. A 1 Hz, para
demonstração, a simplificação é segura; está registrada aqui de propósito
para não passar por descuido.

O reset do `pc` é **assíncrono** justamente por causa daqui: enquanto o reset
está apertado, o clock derivado pode não ter nenhuma borda, e um reset
síncrono nunca chegaria a agir.
