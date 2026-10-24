# Plano da 3ª entrega — MIPS com pipeline

**Prazo:** 13/11/2026, 13:59h. Atraso desconta 2 pontos. Vale 8 pontos.
**Escrito em:** 24/10/2026 — 20 dias de janela.
**Apresentação:** cerca de 10 minutos por equipe.

## Situação de partida

A 2ª entrega está concluída: processador monociclo com saltos, 17 módulos em
`rtl/`, 4 módulos de invólucro em `fpga/`, 21 testbenches com 158 casos
aprovados, programa de ordenação executando corretamente em simulação e na
DE2-115.

Esta etapa **não acrescenta instruções**. O mesmo programa, as mesmas doze
instruções. O que muda é a organização interna do processador.

## A rubrica, item por item

| # | Exigência | Onde é atendida |
|---|---|---|
| 1 | Caminho de dados completo do MIPS **com pipeline** | 7 cartões de RTL novos + 3 de modificação |
| 2 | Todos os componentes testados com testbench | item 3 do checklist de cada cartão |
| 3 | Todos os códigos parametrizados | item 1 do checklist |
| 4 | Vídeo da apresentação no YouTube | cartão próprio |

Mais o relatório técnico e a apresentação de 10 minutos.

## O que muda: de monociclo para pipeline

No monociclo, uma instrução ocupa o processador inteiro durante um ciclo. O
período do clock precisa acomodar a instrução mais lenta — a de leitura de
memória, que atravessa seis blocos em série. Instruções simples desperdiçam o
resto do ciclo.

O pipeline divide a execução em cinco estágios e deixa **cinco instruções
diferentes** em voo ao mesmo tempo, cada uma num estágio:

```
IF   busca a instrução
ID   decodifica e lê registradores
EX   calcula na ALU
MEM  acessa a memória de dados
WB   grava no banco de registradores
```

O clock passa a ser limitado pelo **estágio mais lento**, não pela instrução
mais lenta. Em regime estável, uma instrução é concluída por ciclo.

O preço: instruções que dependem umas das outras passam a colidir, porque uma
ainda não terminou quando a seguinte já precisa do resultado. Resolver essas
colisões é o grosso do trabalho desta etapa.

## Os perigos que o programa de vocês realmente provoca

Esta análise foi feita sobre `mem/programa.asm`. Não é teoria — são as
colisões que vão acontecer de fato.

| tipo | ocorrências | solução necessária |
|---|---|---|
| dependência a **1 instrução** de distância | **20** | forwarding de EX/MEM para EX |
| dependência a **2 instruções** de distância | **8** | forwarding de MEM/WB para EX |
| dependência a **3 instruções** de distância | **13** | banco de registradores *write-first* |
| **load-use** | **2** | **stall de um ciclo** — forwarding não resolve |
| desvios e saltos | **11** | descarte das instruções já buscadas |

### Os dois load-use, por extenso

São os únicos pontos do programa onde o pipeline **tem** que parar:

```
PC= 16   lw  $t0, 4($t1)   ->  sw  $t0, 0($t1)        via $t0
PC=100   lw  $t4, 4($t2)   ->  slt $t0, $t4, $t3      via $t4
```

O dado do `lw` só existe no fim do estágio MEM. A instrução seguinte precisa
dele no início do EX. Nenhum encaminhamento resolve: o valor ainda não foi
lido. A única saída é segurar o pipeline por um ciclo.

### Os onze perigos de controle

```
PC=  0  j main          PC= 84  bne $t0,$zero,exit2   PC=136  j for1tst
PC= 28  jr $ra          PC=108  beq $t0,$zero,exit2   PC=164  jr $ra
PC= 72  beq $t0,$zero   PC=120  jal swap              PC=244  jal sort
PC=128  j for2tst                                     PC=248  j end
```

Quando o desvio é resolvido, instruções erradas já entraram no pipeline.
Precisam ser descartadas.

## Blocos a construir

### Novos — 7 módulos

| bloco | função |
|---|---|
| `reg_if_id` | carrega instrução e `PC+4` do estágio IF para o ID |
| `reg_id_ex` | carrega valores lidos, imediato, campos da instrução **e todos os sinais de controle** |
| `reg_ex_mem` | carrega resultado da ALU, valor a gravar e os sinais de controle restantes |
| `reg_mem_wb` | carrega dado lido da memória, resultado da ALU e os sinais de escrita |
| `unidade_forwarding` | compara registradores de origem do EX com os destinos em EX/MEM e MEM/WB |
| `deteccao_hazard` | detecta load-use e congela IF, ID e o PC por um ciclo |
| `controle_flush` | anula as instruções já buscadas quando um desvio ou salto é tomado |

### Modificados — 3 módulos existentes

| módulo | mudança | por quê |
|---|---|---|
| `banco_registradores` | escrita na **primeira metade** do ciclo, leitura na segunda (*write-first*) | resolve as 13 dependências de distância 3 sem forwarding adicional |
| `control_unit` | **deixa de receber o sinal `zero`** | o `zero` nasce no EX; a unidade de controle vive no ID. A decisão do desvio precisa sair de dentro dela |
| `mips_monociclo` → `mips_pipeline` | novo topo, com os registradores de estágio entre os blocos | é a integração |

## A armadilha principal desta etapa

**A unidade de controle de vocês recebe o sinal `zero` da ALU.** Isso
funcionava no monociclo, onde tudo acontece no mesmo ciclo. No pipeline não
funciona: a unidade de controle está no estágio ID e o `zero` só existe no
EX, um ciclo depois.

Há duas saídas, e a escolha precisa ser feita **antes** de escrever qualquer
linha:

**Opção A — resolver o desvio no estágio MEM.** É o caminho do livro na
primeira versão. Mais simples de escrever, mas descarta três instruções a
cada desvio tomado.

**Opção B — resolver o desvio no estágio ID**, com um comparador próprio ali.
Descarta apenas uma instrução, mas exige forwarding adicional para o
comparador e cria um caso novo de stall.

**Recomendação: opção A.** Com 20 dias e uma equipe que já perdeu uma
entrega, a versão simples e correta vale mais que a otimizada e incompleta. O
relatório registra a escolha e cita a opção B como trabalho futuro — isso
conta a favor, não contra.

## Divisão do trabalho

A estratégia é **incremental**: o processador funciona ao fim de cada fase,
só que para um conjunto menor de programas. Assim a integração não cai toda
na última semana.

| Responsável | Blocos |
|---|---|
| **Jaide** | os 4 registradores de pipeline · banco de registradores *write-first* · pipelining dos sinais de controle |
| **Manuela** | unidade de forwarding · top-level do pipeline · projeto Quartus e síntese |
| **Ana Clara** | detecção de hazard e stall · lógica de flush · reestruturação da decisão de desvio |

Todos: testbenches dos próprios blocos, relatório e vídeo.

### Ponto de controle em 31/10

Na 2ª entrega os blocos de uma integrante não foram entregues e precisaram
ser refeitos na véspera. Para não repetir: **em 31/10, qualquer bloco que não
tiver pelo menos a interface definida e o arquivo criado é redistribuído**.
Sete dias de antecedência é o suficiente para absorver; dois não são.

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

### Fase A — pipeline sem tratamento de perigos · até 31/10

1. **Registrador IF/ID** — instrução e `PC+4` · *Jaide*
2. **Registrador ID/EX** — valores lidos, imediato, campos e sinais de controle · *Jaide*
3. **Registrador EX/MEM** — resultado da ALU, valor a gravar, sinais restantes · *Jaide*
4. **Registrador MEM/WB** — dado lido, resultado da ALU, sinais de escrita · *Jaide*
5. **Banco de registradores write-first** — escrita na primeira metade do ciclo · *Jaide*
6. **Decisão de desvio fora da unidade de controle** — mover a resolução para o MEM · *Ana Clara*
7. **Top-level do pipeline** — `mips_pipeline.v`, os cinco estágios ligados · *Manuela*
8. **Testbench de programa sem perigos** — sequência de instruções independentes, para validar a Fase A isolada · *Todos*

### Fase B — forwarding · até 05/11

9. **Unidade de forwarding** — compara `rs` e `rt` do EX com os destinos em EX/MEM e MEM/WB · *Manuela*
10. **Multiplexadores de forwarding nas entradas da ALU** — três entradas cada · *Manuela*
11. **Testbench de forwarding** — os 20 casos de distância 1 e os 8 de distância 2 do programa real · *Manuela*

### Fase C — stall e flush · até 09/11

12. **Unidade de detecção de hazard** — load-use: congela PC, IF/ID e injeta bolha · *Ana Clara*
13. **Lógica de flush** — anula as instruções buscadas após desvio ou salto tomado · *Ana Clara*
14. **Testbench de stall** — os dois load-use reais do programa, em `PC=16` e `PC=100` · *Ana Clara*
15. **Testbench de flush** — os onze desvios e saltos do programa · *Ana Clara*

### Fase D — integração e entrega · até 13/11

16. **Modelo de referência do pipeline em Python** — estende o interpretador existente para contar ciclos com stalls e flushes, prevendo o número exato antes de simular o Verilog · *Jaide*
17. **Testbench do processador completo** — executa `programa.txt` e confere o vetor ordenado **e a contagem de ciclos** contra o modelo · *Todos*
18. **Invólucro DE2-115 adaptado** — o mesmo de antes, apontando para o novo topo · *Manuela*
19. **Síntese e gravação na placa** — comparar o `Fmax` com o do monociclo · *Manuela*
20. **Relatório técnico IEEE — 3ª entrega** · *Todos*
21. **Vídeo da apresentação no YouTube** · *Todos*

### Etiquetas

`pipeline` · `forwarding` · `hazard` · `testbench` · `integração` · `relatório` · `vídeo` · `Quartus`

## Marcos internos

| Data | Meta |
|---|---|
| **31/10** | Fase A completa: pipeline funcionando para programa sem perigos. **Ponto de controle de redistribuição.** |
| **05/11** | Fase B completa: forwarding resolvendo as 28 dependências de distância 1 e 2 |
| **09/11** | Fase C completa: os 2 load-use e os 11 desvios tratados |
| **11/11** | programa completo rodando em simulação, contagem de ciclos batendo com o modelo |
| **12/11** | síntese concluída, vídeo gravado |
| **13/11** | entrega |

## Notas técnicas

**Os sinais de controle também andam pelo pipeline.** É o esquecimento mais
comum. Os sinais gerados no ID precisam acompanhar a instrução até o estágio
onde agem: `alu_op` e os seletores da ALU param no EX; `mem_write` vai até o
MEM; `reg_write` e `mem_to_reg` vão até o WB. Cada registrador de estágio
carrega, além dos dados, o subconjunto de sinais que ainda não foi usado.

**A bolha é um `nop`, não uma pausa.** Quando a detecção de hazard atua, três
coisas acontecem no mesmo ciclo: o PC não avança, o registrador IF/ID não
atualiza, e os sinais de controle que entram no ID/EX são **zerados**. O
terceiro é o que importa — sem ele a instrução repetida executaria duas vezes.

**`jal` no pipeline exige cuidado extra.** Ele grava `PC+4` no registrador 31.
Esse `PC+4` nasce no IF e só é usado no WB — precisa atravessar os quatro
registradores de estágio. É o dado que viaja mais longe no processador.

**`jr` lê um registrador para decidir o PC.** Se o valor vier de uma instrução
recente, há dependência. No programa de vocês os dois `jr` leem `$ra`, escrito
por um `jal` muitas instruções antes — não haverá colisão. Vale documentar
isso no relatório como limitação conhecida, em vez de deixar implícito.

**A contagem de ciclos é a melhor verificação.** No monociclo, a previsão
independente de 404 instruções bateu com os 406 ciclos do hardware, e foi a
evidência mais forte do relatório anterior. Repetir a técnica: o modelo em
Python prevê `404 + 4 (enchimento) + stalls + flushes`; o Verilog tem que
chegar no mesmo número. Se o vetor sair ordenado mas a contagem não bater, há
um perigo sendo tratado errado — e o vetor pode estar certo por acaso.

**Comparar o `Fmax` com o do monociclo.** É o argumento central do pipeline e
está ao alcance: o Quartus reporta os dois. Se o `Fmax` subir, o relatório tem
um resultado quantitativo em vez de uma afirmação teórica.
