# Plano da 2ª entrega — MIPS monociclo com jumps

**Prazo:** 09/10/2026, 13:59h. Atraso desconta 2 pontos.
**Escrito em:** 28/09/2026 — 11 dias de janela.

Este documento traduz a rubrica da 2ª entrega em cartões de Trello e divisão
de trabalho. A estrutura do board (quatro listas, cartão por bloco funcional,
checklist de pronto) é a mesma já descrita e justificada na seção V do
relatório da 1ª entrega — o que muda aqui é o conteúdo dos cartões.

## Situação de partida

A 1ª entrega está concluída: assembly traduzido, montador funcionando,
`mem/programa.mif` gerado e verificado por execução do binário. O diretório
`rtl/` ainda não tem nenhum arquivo `.v` — todo o Verilog do processador
começa agora.

## A rubrica, item por item

| # | Exigência | Onde é atendida |
|---|---|---|
| 1 | Configuração do ambiente (Quartus) | cartão `Ambiente Quartus` + seção II do relatório |
| 2 | Caminho de dados completo do MIPS monociclo **com jumps** | 14 cartões de RTL |
| 3 | Todos os componentes testados com testbench | item 3 do checklist de cada cartão + `tb/` |
| 4 | Todos os códigos parametrizados | item 1 do checklist (`parameter` nas larguras) |
| 5 | Vídeo da apresentação no YouTube | cartão `Vídeo da apresentação` |

O item 5 é novidade em relação ao plano da 1ª entrega e não estava previsto
no cronograma original.

**Fora de escopo nesta etapa:** registradores de pipeline, unidade de
forwarding e detecção de hazard. Isso é a 3ª entrega (13/11). Os cartões
correspondentes permanecem no board, em "A Fazer", com data de 13/11.

## Conjunto de instruções a suportar

O datapath precisa executar exatamente as instruções que aparecem em
`mem/programa.asm` — doze, nada além disso:

```
addi 17    sw 15    lw 9     add 6    j 4
slt 2      sll 2    jr 2     jal 2    beq 2
slti 1     bne 1
```

Isso delimita a unidade de controle: é uma tabela de doze linhas.

### O que os jumps acrescentam ao datapath clássico

O caminho de dados monociclo do Patterson não cobre `j`, `jal` nem `jr`. As
diferenças são pontuais e são o que caracteriza esta entrega:

| Instrução | Acréscimo ao datapath |
|---|---|
| `j` | mux na fonte do PC; endereço formado por `{PC+4[31:28], alvo, 2'b00}` |
| `jal` | mux no registrador de escrita (rd / rt / **31**) e no dado escrito (ALU / memória / **PC+4**) |
| `jr` | entrada adicional no mux do PC, vinda da saída 1 do banco de registradores |
| `sll` | mux na entrada A da ALU para injetar `shamt` no lugar do registrador |

## O que é RTL (e por que a pasta se chama assim)

RTL é sigla de *Register Transfer Level* — nível de transferência entre
registradores. É o modo de descrever hardware digital: em vez de desenhar
porta lógica por porta lógica, você declara **o que cada registrador recebe a
cada borda de clock** e **como os sinais combinacionais estão ligados entre
si**. A ferramenta de síntese (Quartus) traduz essa descrição nas portas e
conexões reais que vão existir dentro da FPGA.

A diferença que mais confunde quem vem de C ou Python: **Verilog não é uma
linguagem de programação.** O arquivo não é executado de cima para baixo.
Cada construção descreve um pedaço de circuito que existe o tempo todo, em
paralelo com todos os outros:

```verilog
assign soma = a + b;     // um somador FISICO, permanentemente ligado.
                         // mudou `a`, `soma` muda junto — ninguem "chama" nada

always @(posedge clk)    // um REGISTRADOR: captura o valor na subida do clock
    pc <= proximo_pc;    // e o segura ate a proxima subida
```

Três módulos declarados num projeto são três circuitos funcionando
simultaneamente, não três funções esperando para serem chamadas. É por isso
que a ordem dos arquivos e a ordem das linhas dentro de um `always` combinacional
não mudam o comportamento do hardware.

No repositório a divisão é esta:

| pasta | o que contém | vai para a FPGA? |
|---|---|---|
| `rtl/` | o processador em si — um `.v` por bloco funcional | **sim**, é sintetizado |
| `tb/` | testbenches: circuitos de mentira que aplicam entradas e conferem saídas | não, só simulação |

Por isso o testbench pode usar `$display`, `$readmemb` e `#10` (esperar 10
unidades de tempo): são comandos do **simulador**, não existem como hardware.
Se aparecerem dentro de um módulo de `rtl/`, a síntese ignora ou acusa erro.

**Parametrizado** (exigência 4 da rubrica) significa: `parameter LARGURA = 32`
no topo do módulo e `[LARGURA-1:0]` no corpo, em vez de `[31:0]` escrito na
mão em vinte lugares. Mudar a largura do processador passa a ser mudar um
número.

## Divisão do trabalho

A divisão da 1ª entrega dava à Pessoa C "pipeline, hazards e integração" —
mas esta etapa não tem pipeline nem hazards. Redistribuição para o período
até 09/10:

| Responsável | Blocos |
|---|---|
| **A** — memória e registradores | PC + somador de PC · memória de instruções · banco de registradores 32×32 · extensor de sinal · memória de dados |
| **B** (Ana C. E. Freire) — ULA e controle | ALU parametrizada · ALU control · unidade de controle (12 instruções) · somador de desvio e lógica de branch |
| **C** — jumps, integração e síntese | lógica de `j`/`jal`/`jr` e muxes do PC · muxes de escrita no banco · top-level · testbench do processador completo · projeto Quartus e síntese |

### Restrição de plataforma: Quartus não roda em macOS

O Quartus Prime é publicado apenas para Windows e Linux. Não existe versão
para macOS — nem Intel, nem Apple Silicon. Consequência direta para a
divisão: **quem estiver em Mac não consegue sintetizar, atribuir pinos nem
gravar a FPGA.**

Isso não tira ninguém do RTL. Simulação funciona no Mac, e é onde está a
maior parte do trabalho desta entrega (rubricas 2, 3 e 4). Toolchain
verificada em 29/09/2026, em MacBook Apple Silicon:

```bash
brew install icarus-verilog                          # simulador, versão 13.0

iverilog -g2012 -o sim rtl/modulo.v tb/modulo_tb.v   # compila
./sim                                                # roda
```

Validado de ponta a ponta com uma memória de instruções parametrizada lendo
o `mem/programa.txt` gerado pelo nosso montador:

```
  ok   j main:          end=0  -> 00001000000000000000000000101010
  ok   sll $t1,$a1,2:   end=4  -> 00000000000001010100100010000000
  ok   add $t1,$a0,$t1: end=8  -> 00000000100010010100100000100000
  ok   jr $ra:          end=28 -> 00000011111000000000000000001000
  TODOS OS CASOS PASSARAM
```

O Icarus também gera forma de onda: `$dumpfile("nome.vcd")` e `$dumpvars(0,
tb)` no testbench produzem um `.vcd` que abre no GTKWave ou no Surfer.

Fluxo prático da equipe: **todo o RTL é escrito e validado em simulação
(qualquer sistema operacional), e só a síntese exige Quartus** — feita por
quem estiver em Windows ou Linux, a partir dos mesmos arquivos do repositório.

### Papéis fechados

- **Jaide — Pessoa A (memória e registradores) + verificação.** Cartões 1 a
  5 e 16. Todos são RTL puro mais testbench, sem nenhuma dependência de
  Quartus, o que resolve a restrição de plataforma acima. O banco de
  registradores é dependência dos testbenches de quase todo mundo, então
  começar por ele destrava a equipe.
- **Ana Clara — Pessoa B (ULA e controle).** Cartões 6 a 9. Também 100%
  simulável; Quartus só é necessário na integração final.
- **Manuela — Pessoa C (jumps, integração e síntese).** Cartões 10 a 15.
  Este papel **exige Windows ou Linux** por causa dos cartões 14 e 15
  (top-level no Quartus, pinagem e síntese).

Se a Manuela também estiver em macOS, as opções são: usar uma máquina do
laboratório da disciplina, ou instalar o Quartus numa máquina virtual Linux
(UTM ou Parallels). Nesse caso, decidir isso agora — não na semana da
entrega.

## Cartões do Trello

Listas mantidas: `A Fazer` → `Fazendo` → `Em Simulação` → `Concluído`.

### Checklist padrão (idêntico em todo cartão de RTL)

```
[ ] interface definida (portas e larguras via parameter)
[ ] Verilog escrito
[ ] testbench escrito
[ ] simulação aprovada
[ ] integrado ao top-level
[ ] descrito no relatório
```

Os itens 1 e 4 cobrem diretamente as rubricas 4 e 3. Vale deixar isso escrito
na descrição do cartão: o board deve mostrar que foi montado a partir da
rubrica, não por hábito.

### Cartões de RTL

Responsável A — `rtl/`:

1. `PC + somador de PC+4`
2. `Memória de instruções` — carrega `mem/programa.txt` via `$readmemb`
3. `Banco de registradores 32x32` — duas leituras, uma escrita, `$zero` fixo em 0
4. `Extensor de sinal 16 -> 32`
5. `Memória de dados` — ver nota sobre a pilha, abaixo

Responsável B — `rtl/`:

6. `ALU parametrizada` — add, sub, and, or, slt
7. `ALU control` — decodifica funct + ALUOp
8. `Unidade de controle` — as 12 instruções
9. `Somador de desvio + lógica de branch` — `PC+4 + imediato*4`, AND com Zero

Responsável C — `rtl/` e `quartus/`:

10. `Lógica de jump` — `{PC+4[31:28], alvo, 2'b00}` e mux do PC
11. `Suporte a jal` — mux de registrador de escrita e de dado de escrita
12. `Suporte a jr` — entrada do mux do PC vinda do banco de registradores
13. `Mux da entrada A da ALU para sll (shamt)`
14. `Top-level do monociclo` — integração de tudo

### Cartões que não são RTL

15. `Ambiente Quartus configurado nas 3 máquinas` — registrar a versão exata; a
    seção II do relatório da 1ª entrega ainda diz "versão a confirmar"
16. `Testbench do processador completo` — executa `mem/programa.txt` e confere o
    vetor ordenado em memória
17. `Vídeo da apresentação no YouTube`
18. `Relatório técnico IEEE — 2ª entrega`

### Cartões movidos para a 3ª etapa

Permanecem em `A Fazer`, com data 13/11: registradores de pipeline
(IF/ID, ID/EX, EX/MEM, MEM/WB), unidade de forwarding, detecção de hazard e
tratamento de hazard de controle.

### Etiquetas

`RTL` · `testbench` · `integração` · `relatório` · `vídeo` · `Quartus`

## Marcos internos

Datas antes do prazo real, para que a integração não caia na véspera:

| Data | Meta |
|---|---|
| 02/10 | todos os módulos isolados escritos, com testbench passando |
| 05/10 | top-level integrado, executando `programa.txt` em simulação |
| 07/10 | síntese no Quartus concluída; vídeo gravado |
| 09/10 | entrega |

## Notas técnicas

**Dois formatos da mesma memória.** `tools/assembler.py` gera
`mem/programa.mif` e `mem/programa.txt` a partir do mesmo assembly. O `.mif`
é o formato da IP de memória do Quartus; o `.txt` é uma palavra binária por
linha, que é o que `$readmemb` entende no testbench. São os mesmos 63 bits ×
63 linhas em embalagens diferentes — alterou o `.asm`, rode o montador e
commite os três arquivos juntos.

**Memória não preenchida lê `x`, não zero.** O `$readmemb` carrega apenas as
63 palavras do programa; o resto do array fica em `x` (indefinido) na
simulação. Se o PC passar do fim do programa, a instrução lida vira
`xxxxxxxx...` e o X se espalha por todo o datapath — todos os sinais viram
`x` e o testbench não mostra nada útil. O `j end` no final do `programa.asm`
existe justamente para o PC nunca chegar lá. O aviso do Icarus
`Not enough words in the file for the requested range [0:255]` é esperado e
não é erro.

**Tamanho da memória de dados.** O `main` inicializa `$sp` em 1024, e o vetor
de teste ocupa os endereços 0 a 31. A memória de dados precisa ter pelo menos
256 palavras para que a pilha caiba sem colidir com o vetor. Esse número é
requisito do bloco `Memória de dados`, e deve estar na descrição do cartão.

**Parametrização.** A rubrica 4 exige que todos os códigos sejam
parametrizados. Na prática: nenhuma largura literal no corpo dos módulos —
`parameter LARGURA = 32`, `parameter N_REGS = 32`, `parameter PROFUNDIDADE =
256`, e assim por diante.
