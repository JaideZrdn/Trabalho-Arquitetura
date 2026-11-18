# Apresentação — 3ª entrega (pipeline)

**10 minutos, três integrantes.** Diagrama do caminho de dados na tela e um
terminal aberto para rodar os testes.

Cada um mostra os arquivos que fez, diz o que cada módulo faz, e pontua um
detalhe que valeu a pena. No fim, os resultados.

---

## ABERTURA — 1 minuto

> Boa tarde, professor.
>
> Na entrega passada a gente apresentou o MIPS monociclo. Ele funcionava,
> mas tinha um problema: como cada instrução ocupava o processador inteiro
> durante um ciclo, o clock tinha que durar o tempo da instrução mais lenta,
> que é o `lw`. Uma soma simples desperdiçava o resto do ciclo.
>
> Nesta entrega a gente dividiu o processador em cinco estágios. Agora
> cinco instruções rodam ao mesmo tempo, cada uma num estágio diferente, e o
> clock só precisa durar o tempo do estágio mais lento.
>
> As instruções são as mesmas, o programa de teste é o mesmo. O que mudou
> foi a organização por dentro.
>
> A gente dividiu o trabalho em três partes e cada um vai mostrar a sua.

**Apontar os cinco estágios no diagrama enquanto fala.**

---

# PARTE 1 — JAIDE · 3 minutos

> A parte que eu fiz foi a estrutura do pipeline. São esses arquivos:

**Mostrar a pasta `rtl/`:**

```
reg_if_id.v          reg_ex_mem.v        pc_com_habilita.v
reg_id_ex.v          reg_mem_wb.v        banco_registradores.v  (modificado)
```

> Quando você divide o processador em cinco estágios, precisa de um
> registrador entre cada dois. São esses quatro primeiros arquivos.
>
> O `reg_if_id` fica entre a busca e a decodificação. Ele guarda a instrução
> que acabou de ser lida e o endereço da próxima.
>
> O `reg_id_ex` fica entre a decodificação e a execução. É o maior dos
> quatro, porque é onde a instrução ainda carrega tudo: os dois valores
> lidos do banco, o imediato, os campos da instrução e os oito sinais de
> controle.
>
> O `reg_ex_mem` e o `reg_mem_wb` são menores, porque a instrução já gastou
> parte do que carregava.

**Abrir o `reg_id_ex.v` e apontar a separação entre dados e controle.**

> Uma coisa que a gente não tinha percebido no começo: **os sinais de
> controle também têm que viajar**. A unidade de controle decodifica a
> instrução no segundo estágio, mas o sinal que manda gravar no banco de
> registradores só é usado no quinto. Então cada registrador carrega, além
> dos dados, os sinais que ainda não foram usados.

### Um detalhe que vale mostrar

> Cada registrador tem uma entrada de limpeza. Quando ela liga, os sinais de
> escrita vão para zero. Isso é a bolha: a instrução continua andando pelo
> pipeline, mas não grava nada — nem em registrador, nem na memória.
>
> Se um desses dois sinais escapar, a bolha deixa de ser inofensiva. Por
> isso eu pus um teste específico para isso: ligo a limpeza com as entradas
> de escrita em 1 e verifico que as saídas saem em 0.

### A mudança no banco de registradores

> O banco eu não fiz do zero, ele já existia. Mas precisou de uma mudança.
>
> No monociclo, se você lê e escreve no mesmo ciclo, a leitura vê o valor
> antigo. Estava certo, porque era a mesma instrução.
>
> No pipeline não serve. A instrução que está gravando no quinto estágio é
> três instruções mais velha que a que está lendo no segundo. A gente
> analisou o nosso programa e achou **treze situações** assim.
>
> A solução foi fazer a leitura enxergar a escrita do mesmo ciclo. Só que eu
> não podia simplesmente ligar isso, porque no monociclo criaria um laço: lá
> a mesma instrução lê e escreve, então ela leria o próprio resultado como
> entrada. Resolvi com um parâmetro — desligado no monociclo, ligado no
> pipeline. Os dois processadores continuam no repositório e os dois
> funcionam.

**Resultado:** `reg_if_id` 9 · `reg_id_ex` 13 · `reg_ex_mem` 9 ·
`reg_mem_wb` 8 · `pc_com_habilita` 9 · `banco_registradores` 13 →
**61 casos aprovados**.

---

# PARTE 2 — MANUELA · 3 minutos

> A minha parte foi resolver as colisões de dados. São esses arquivos:

```
unidade_forwarding.v     tb/tb_unidade_forwarding.v
mux_forwarding.v         tb/tb_mux_forwarding.v
                         tb/tb_forwarding_programa.v
```

> Com cinco instruções rodando ao mesmo tempo, elas começam a brigar. Uma
> instrução pode precisar de um resultado que a anterior ainda não gravou.
>
> A gente contou quantas vezes isso acontece no nosso programa: **vinte**
> vezes entre instruções seguidas, e mais **oito** entre instruções
> separadas por uma.

### O que o módulo faz

> A ideia é não esperar a gravação. O resultado já existe lá na frente, só
> não foi gravado ainda. Então em vez de esperar, a gente desvia o valor
> direto para a entrada da ALU.
>
> O `unidade_forwarding` é quem decide. Ele compara os registradores que a
> instrução vai ler com os destinos das instruções que estão nos estágios
> adiante. Se bater, ele manda o multiplexador pegar o valor encaminhado em
> vez do que veio do banco.
>
> O `mux_forwarding` é esse multiplexador. Ele tem três entradas: o valor
> original, o do estágio de memória e o do estágio de escrita. Instanciei
> dois, um para cada operando da ALU.

### Dois detalhes

> **Primeiro: prioridade.** Se os dois estágios adiante escrevem no mesmo
> registrador, vence o mais próximo, porque é o mais recente.
>
> **Segundo, e esse é o mais interessante: o `lw` é uma exceção.** Quando a
> instrução adiante é um `lw`, o que está disponível ali é o **endereço**
> que a ALU calculou, não o dado — o dado só chega no estágio seguinte. Se
> eu encaminhasse, ia mandar o endereço no lugar do valor.
>
> Por isso o módulo recebe um sinal avisando quando a instrução é um `lw`, e
> nesse caso ele não encaminha. Esse caso quem resolve é a Ana, com o stall.

### Uma coisa que a gente teve que acrescentar

> O módulo precisa saber quais registradores a instrução realmente lê. Um
> `addi`, por exemplo, lê só um. Então a gente acrescentou dois sinais novos
> na unidade de controle, um para cada operando. Sem isso, o forwarding
> encaminharia valores para instruções que nem usam aquele operando.

---

# PARTE 3 — ANA CLARA · 3 minutos

> A minha parte foram os dois casos que o forwarding não resolve. São esses
> arquivos:

```
deteccao_hazard.v     controle_flush.v     control_unit.v  (modificado)
```

### O primeiro caso: load-use

> Tem uma situação em que não dá para encaminhar. Quando um `lw` está no
> terceiro estágio e a instrução seguinte quer o dado que ele vai carregar,
> esse dado ainda não foi lido. Ele só existe no fim do quarto estágio.
>
> Não tem de onde encaminhar. O valor não existe em lugar nenhum ainda.
>
> A única saída é parar o pipeline por um ciclo. No nosso programa isso
> acontece em dois pontos:

```
PC= 16   lw  $t0, 4($t1)  ->  sw  $t0, 0($t1)
PC=100   lw  $t4, 4($t2)  ->  slt $t0, $t4, $t3
```

> O `deteccao_hazard` é quem percebe isso. Quando ele detecta, três coisas
> acontecem ao mesmo tempo: o PC não avança, o primeiro registrador não
> atualiza, e o segundo recebe uma bolha.
>
> A terceira é a que importa. Sem ela a instrução que ficou parada
> executaria duas vezes.

### O segundo caso: desvios

> O outro problema é que, enquanto o processador não sabe se um desvio vai
> ser tomado, ele continua buscando as instruções seguintes. Quando a
> resposta sai, essas instruções já entraram no pipeline e têm que ser
> jogadas fora. Quem faz isso é o `controle_flush`.
>
> Aqui a gente teve que tomar uma decisão de projeto, e eu mexi na unidade
> de controle por causa dela.
>
> No monociclo, a unidade de controle recebia o sinal de igualdade da ALU e
> decidia o desvio ali mesmo. No pipeline isso não funciona: a unidade de
> controle está no segundo estágio e o sinal da ALU só existe no terceiro.
>
> A gente tinha duas opções. Resolver o desvio no quarto estágio, que é como
> o livro faz na primeira versão, ou resolver no terceiro. **A gente
> escolheu o terceiro**, porque é ali que o sinal da ALU nasce. No quarto, a
> gente jogaria fora três instruções por desvio. No terceiro, só duas.
>
> Então a unidade de controle parou de decidir. Agora ela só sinaliza a
> intenção: se é um `beq`, um `bne`, um salto ou um retorno de função. Essas
> bandeiras viajam com a instrução até o terceiro estágio, e lá o
> `controle_flush` junta a intenção com o resultado da comparação e decide.
>
> No nosso programa são **onze** instruções que mexem no fluxo.

**Resultado:** `deteccao_hazard` 7 · `controle_flush` 8 · `control_unit` 15
→ **30 casos aprovados**.

---

# FECHAMENTO — 2 minutos

## Rodar na frente dele

```bash
make
```

> Todos os módulos têm testbench. São trinta e dois módulos e duzentos e
> cinquenta e sete casos, todos passando.

```bash
make run-mips_pipeline V=1
```

> E aqui é o processador completo rodando o programa de ordenação.

```
vetor inicial : 5 3 8 1 9 2 7 4
vetor final   : 1 2 3 4 5 7 8 9
$sp restaurado em 1024
$zero permanece 0
```

> Além do vetor, a gente confere mais duas coisas: que o ponteiro de pilha
> voltou ao valor inicial, o que prova que o epílogo da função restaurou
> tudo, e que o registrador zero continua zero depois de quatrocentas
> instruções.

## O número que a gente acha mais interessante

> O monociclo levava **406 ciclos**. O pipeline leva **563**.
>
> Ou seja, em número de ciclos o pipeline é pior. E isso é esperado — o
> ganho dele não é esse. O ganho é que cada ciclo pode ser **mais curto**.
> No monociclo o clock tem que durar o caminho do `lw`, que atravessa seis
> blocos em série. No pipeline, só o estágio mais lento.
>
> A razão entre os dois é **1,39**. Então o pipeline compensa se o clock
> puder ser 39% mais rápido, o que é bastante folgado para um caminho que a
> gente dividiu em cinco pedaços.

## Como a gente sabe que não foi sorte

> Para não depender só do vetor sair ordenado, a gente escreveu um modelo do
> pipeline em Python, separado do Verilog. Ele roda o mesmo binário e prevê
> quantos ciclos deveria levar, somando as penalidades:

```
instruções executadas                      406
enchimento do pipeline                       4
desvios tomados                     x2     126
stalls de load-use                  x1      33
-------------------------------------------------
previsto                                   563
medido no Verilog                          563
```

> O número bate exato.
>
> Isso é mais forte que o vetor ordenado. Se a gente estivesse tratando
> algum perigo errado, o vetor até poderia sair certo por coincidência — mas
> o número de stalls e de descartes não ia bater.
>
> E vale contar como a gente chegou nesse número: o testbench do processador
> dizia 562, um a menos. A diferença não era do projeto, era do testbench —
> ele lia os sinais **depois** da borda de clock, quando eles já valem para o
> ciclo seguinte. Passando a ler antes da borda, deu 563 e fechou com o
> modelo. Quem apontou o erro foi o contador que a gente pôs na placa, que
> mostrava 563 desde o começo.

## O que a gente sabe que ficou faltando

> Uma limitação que a gente conhece: o `jr` lê um registrador para decidir o
> endereço de volta. Se esse registrador tivesse sido escrito por uma
> instrução muito recente, haveria uma dependência que o nosso projeto não
> trata. No nosso programa isso não acontece, porque os dois `jr` leem o
> `$ra`, que foi escrito muito antes. Está registrado no relatório.

---

## Se ele perguntar

**"Por que o pipeline gasta mais ciclos?"**
> Porque ele acrescenta penalidade: dois ciclos por desvio tomado e um por
> load-use. O ganho está no período do clock, não na contagem.

**"Por que vocês resolveram o desvio no terceiro estágio?"**
> Porque é onde o sinal da ALU nasce. No quarto a gente jogaria fora três
> instruções, no terceiro só duas. Dava para resolver no segundo e jogar
> fora só uma, mas aí precisaria de um comparador próprio e mais
> encaminhamento. A gente deixou registrado como melhoria possível.

**"E se precisar parar e encaminhar ao mesmo tempo?"**
> O stall tem prioridade. O registrador segura o valor em vez de descartar,
> porque segurar dá para desfazer e descartar não.

**"Como vocês sabem que a bolha não altera nada?"**
> Tem um teste para isso. A gente liga a limpeza com os sinais de escrita em
> 1 e verifica que saem em 0.

**"Está tudo parametrizado?"**
> Está. As larguras vêm de `parameter`, não tem número escrito no meio do
> código. Em vários testbenches a gente instancia o mesmo módulo duas vezes
> com larguras diferentes para mostrar que funciona.

**"Isso roda na FPGA?"**
> Roda. A gente fez um invólucro de placa para o pipeline também,
> `fpga/de2_115_top_pipeline.v`, com a pinagem em
> `quartus/pinos_de2_115_pipeline.qsf`. Se o senhor quiser mexer, os
> controles estão em `quartus/COMO-ABRIR.md`.

**"O que eu vejo na placa?"**
> O mesmo do monociclo, mais três coisas que só existem no pipeline. `SW[15]`
> escolhe a velocidade: devagar leva os mesmos 6 minutos e 46 da entrega
> passada, rápido termina em 51 segundos. `SW[16]` troca os displays do valor
> do vetor para o contador de ciclos, que para em 0x233, que é 563. E três
> LEDs verdes acendem no ciclo em que cada perigo acontece: `LEDG[1]` o
> stall, `LEDG[2]` o descarte de desvio, `LEDG[3]` o encaminhamento.
>
> No modo passo-a-passo, `SW[17]`, dá para ver o custo do desvio contando os
> apertos. O primeiro `j main` leva três apertos para o PC sair de 0 e ir
> para 168: nos dois primeiros o PC vai para 4 e 8, que são as instruções
> buscadas por engano e descartadas depois. No monociclo era um aperto só.
