# Roteiro da apresentação — 3ª entrega (pipeline)

**Duração:** cerca de 10 minutos, três integrantes.
**Material na tela:** diagrama do caminho de dados e um terminal para rodar
os testes ao vivo.

Cada integrante apresenta os blocos sob sua responsabilidade: o que o bloco
faz, por que ele precisou existir, quais as entradas e quem decide o quê, e o
resultado do testbench.

---

## Abertura — 1 minuto · *qualquer um*

> Na entrega anterior apresentamos o processador MIPS monociclo, com as
> instruções de salto. Ele funcionava, mas tinha uma limitação: o período do
> clock precisava acomodar a instrução mais lenta, a de leitura de memória,
> que atravessa seis blocos em série. Uma instrução simples como uma soma
> desperdiçava o resto do ciclo.
>
> Nesta entrega dividimos a execução em cinco estágios. Cinco instruções
> diferentes ficam em voo ao mesmo tempo, uma em cada estágio, e o clock
> passa a ser limitado pelo estágio mais lento — não pela instrução mais
> lenta.
>
> O conjunto de instruções é o mesmo, o programa de teste é o mesmo. O que
> mudou é a organização interna.
>
> Tudo foi implementado em Verilog, com os módulos parametrizados, e cada
> bloco tem testbench próprio.

**Mostrar os cinco estágios no diagrama:**

```
IF   busca        ID  decodifica e lê      EX  calcula e decide desvios
MEM  acessa memória                        WB  grava no banco
```

---

# PARTE 1 — JAIDE · 3 minutos

**Tema: a estrutura do pipeline — os registradores de estágio.**

## O que eu implementei

| arquivo | função | testbench |
|---|---|---|
| `reg_if_id.v` | entre a busca e a decodificação | 9 casos |
| `reg_id_ex.v` | entre a decodificação e a execução | 13 casos |
| `reg_ex_mem.v` | entre a execução e a memória | 9 casos |
| `reg_mem_wb.v` | entre a memória e a escrita | 8 casos |
| `pc_com_habilita.v` | contador de programa que pode ser congelado | 9 casos |
| `banco_registradores.v` | modo *write-first* acrescentado | 13 casos |

## O que falar

> Dividir o processador em cinco estágios exige um registrador entre cada
> par deles. Esses registradores são o que segura o que a instrução carrega
> consigo enquanto ela caminha pelo pipeline.
>
> E não são só os dados. O ponto que mais confunde é que **os sinais de
> controle também viajam**. A unidade de controle decodifica a instrução lá
> no segundo estágio, mas o sinal que autoriza escrever no banco de
> registradores só age no quinto. Então cada registrador carrega, além dos
> dados, o subconjunto de sinais que ainda não foi usado.

**Mostrar o `reg_id_ex.v`** — é o maior dos quatro, e dá para apontar a
separação entre a parte de dados e a parte de controle.

> O `reg_id_ex` é o maior porque é onde a instrução ainda carrega tudo:
> os dois valores lidos, o imediato estendido, os campos `rs`, `rt`, `rd`,
> `shamt` e `funct`, mais os oito sinais de controle.

### O conceito da bolha

> Cada registrador tem uma entrada de limpeza. Quando ela é acionada, os
> sinais de escrita vão a zero. É isso que chamamos de bolha: a instrução
> continua andando pelo pipeline, atravessa os cinco estágios, mas com as
> duas permissões de escrita desligadas — não altera registrador nem
> memória.
>
> Se qualquer um dos dois sinais escapar, a bolha deixa de ser inofensiva e
> vira uma instrução fantasma. Por isso o testbench do `reg_id_ex` tem um
> caso específico: aciona a limpeza com as entradas de escrita em um, e
> verifica que as saídas saem em zero.

### O banco de registradores

> O banco precisou de uma mudança. No monociclo, uma leitura feita no mesmo
> ciclo de uma escrita vê o valor antigo — e isso estava certo, porque era a
> mesma instrução.
>
> No pipeline não. A instrução que está gravando no quinto estágio é três
> instruções mais velha que a que está lendo no segundo. Analisamos o nosso
> programa e encontramos **treze situações** assim.
>
> A solução foi o modo *write-first*: a leitura enxerga a escrita do mesmo
> ciclo. Mas não dava para simplesmente ligar — no monociclo isso criaria um
> laço combinacional, porque lá a mesma instrução lê e escreve. Então virou
> um parâmetro: desligado no monociclo, ligado no pipeline. Os dois
> processadores continuam no repositório, os dois funcionam.

## Resultado

```
reg_if_id  9 · reg_id_ex 13 · reg_ex_mem 9 · reg_mem_wb 8
pc_com_habilita 9 · banco_registradores 13      = 61 casos aprovados
```

---

# PARTE 2 — MANUELA · 3 minutos

**Tema: dependências de dados e encaminhamento.**

## O que eu implementei

| arquivo | função | testbench |
|---|---|---|
| `unidade_forwarding.v` | decide de onde vem cada operando da ALU | `tb/tb_unidade_forwarding.v` |
| `mux_forwarding.v` | multiplexador de 3 entradas, uma instância por operando | `tb/tb_mux_forwarding.v` |
| | cenário com o programa real | `tb/tb_forwarding_programa.v` |

## O que falar

> Com cinco instruções em voo ao mesmo tempo, elas começam a colidir. Uma
> instrução pode precisar de um resultado que a anterior ainda não gravou.
>
> Analisamos o nosso programa de ordenação e contamos exatamente quantas
> vezes isso acontece: **vinte** dependências entre instruções consecutivas,
> e mais **oito** entre instruções separadas por uma.

### Como funciona

> A solução é não esperar a gravação. O resultado já existe fisicamente no
> estágio adiante — só não foi gravado ainda. O encaminhamento desvia esse
> valor direto para a entrada da ALU.
>
> A unidade de forwarding compara os registradores que a instrução no
> terceiro estágio vai ler com os destinos das instruções que estão nos
> estágios à frente. Quando encontra coincidência, manda o multiplexador
> escolher o valor encaminhado em vez do que veio do banco.
>
> As entradas dela são: os registradores de origem da instrução em execução,
> mais o destino e a permissão de escrita de cada um dos dois estágios
> seguintes.

### Dois detalhes de projeto

> **Prioridade.** Se os dois estágios à frente escrevem no mesmo registrador,
> o mais recente vence. O valor do estágio mais próximo é o mais atual.
>
> **A exceção do `lw`.** Quando a instrução adiante é uma leitura de memória,
> o que está disponível naquele ponto é o **endereço** calculado pela ALU,
> não o dado — ele só chega no estágio seguinte. Encaminhar daria o número
> errado. Por isso a unidade recebe um sinal que avisa quando a instrução é
> um `lw`, e nesse caso ela não encaminha. Quem resolve esse caso é a
> detecção de hazard, que a Ana vai apresentar.

### A interface

> Como a unidade precisa saber quais registradores a instrução realmente lê,
> acrescentamos dois sinais à unidade de controle — um para cada operando.
> Sem eles, a unidade encaminharia valores para instruções que nem usam
> aquele operando.

---

# PARTE 3 — ANA CLARA · 3 minutos

**Tema: os perigos que o encaminhamento não resolve.**

## O que eu implementei

| arquivo | função | testbench |
|---|---|---|
| `deteccao_hazard.v` | detecta load-use e congela o pipeline | 7 casos |
| `controle_flush.v` | descarta instruções após um desvio tomado | 8 casos |
| `control_unit.v` | reestruturação da decisão de desvio | 15 casos |

## O que falar

### Load-use

> Existe um caso que o encaminhamento não resolve. Quando uma instrução de
> leitura de memória está no terceiro estágio e a instrução seguinte quer o
> dado que ela vai carregar, esse dado ainda não foi lido — ele só existe no
> fim do quarto estágio.
>
> Não há de onde encaminhar. O valor não existe em lugar nenhum do
> processador ainda.
>
> A única saída é parar. No nosso programa isso acontece em dois pontos:

```
PC= 16   lw  $t0, 4($t1)  ->  sw  $t0, 0($t1)
PC=100   lw  $t4, 4($t2)  ->  slt $t0, $t4, $t3
```

> Quando a detecção atua, três coisas acontecem no mesmo ciclo: o contador de
> programa não avança, o primeiro registrador de estágio não atualiza, e o
> segundo recebe uma bolha.
>
> O terceiro é o que importa. Sem ele, a instrução que ficou parada seria
> executada duas vezes.

### Desvios

> O outro perigo é de controle. Enquanto o processador não sabe se um desvio
> vai ser tomado, ele continua buscando as instruções seguintes. Quando a
> decisão sai, essas instruções já estão dentro do pipeline.
>
> Aqui tomamos uma decisão de projeto. A unidade de controle do monociclo
> recebia o sinal de igualdade da ALU para decidir o desvio — isso não
> sobrevive ao pipeline, porque a unidade de controle está no segundo estágio
> e o sinal da ALU só existe no terceiro.
>
> Tínhamos duas opções: resolver o desvio no quarto estágio, como a primeira
> versão do livro, ou no terceiro. Escolhemos o **terceiro**, porque é ali
> que o sinal da ALU nasce. Resolver no quarto descartaria três instruções a
> cada desvio; no terceiro, apenas duas.
>
> A unidade de controle deixou de decidir e passou a apenas sinalizar a
> intenção — se é um `beq`, um `bne`, um salto ou um retorno de função. Essas
> bandeiras viajam com a instrução até o terceiro estágio, e lá o bloco de
> flush combina a intenção com o resultado da comparação.
>
> No nosso programa há **onze** instruções de transferência de controle.

## Resultado

```
deteccao_hazard 7 · controle_flush 8 · control_unit 15   = 30 casos aprovados
```

---

# FECHAMENTO — RESULTADOS · 2 minutos · *qualquer um*

## Rodar ao vivo

```bash
make
```

> Trinta e um módulos, duzentos e trinta e sete casos, todos aprovados.

```bash
make run-mips_pipeline V=1
```

> E este é o processador completo executando o programa de ordenação.

```
vetor inicial : 5 3 8 1 9 2 7 4
vetor final   : 1 2 3 4 5 7 8 9
$sp restaurado em 1024
$zero permanece 0
```

## O número que importa

> Mas o resultado mais interessante não é o vetor ordenado — é a contagem de
> ciclos.
>
> O monociclo levava **406 ciclos**. O pipeline leva **562**.
>
> O pipeline é mais lento em ciclos. Isso é esperado, e é o ponto que vale
> explicar: o ganho do pipeline não está em executar menos ciclos. Está em
> cada ciclo ser **mais curto**. No monociclo o período precisa acomodar a
> instrução mais lenta, que atravessa seis blocos em série. No pipeline,
> apenas o estágio mais lento.
>
> A razão entre os dois é **1,38**. Ou seja: o pipeline compensa se o seu
> clock puder ser mais que 38% mais rápido — o que é folgado, porque
> dividimos um caminho de seis blocos em cinco pedaços.

## A verificação que dá confiança

> Para garantir que o resultado não foi coincidência, escrevemos um modelo
> do pipeline em Python, independente do Verilog. Ele executa o mesmo binário
> e prevê a contagem de ciclos somando as penalidades:

```
instruções executadas                      406
enchimento do pipeline                       4
transferências de controle tomadas  x2     126
stalls de load-use                  x1      33
-------------------------------------------------
previsto                                   563
medido no Verilog                          562
```

> Um ciclo de diferença, que é convenção de contagem.
>
> Isso é mais forte que o vetor sair ordenado. Se houvesse um perigo sendo
> tratado errado, o vetor até poderia sair certo por coincidência — mas o
> número de stalls e de descartes não bateria.

## Honestidade sobre o que ficou

> Uma limitação conhecida: a instrução de retorno de função lê um registrador
> para decidir o endereço. Se esse registrador tivesse sido escrito por uma
> instrução muito recente, haveria uma dependência que o nosso projeto não
> trata. No nosso programa isso não ocorre — os dois retornos leem um
> registrador escrito muitas instruções antes. Está documentado no relatório.

---

## Perguntas prováveis e respostas

**"Por que o pipeline gasta mais ciclos?"**
Porque acrescenta penalidades: dois ciclos por desvio tomado e um por
load-use. O ganho é no período do clock, não na contagem de ciclos.

**"Por que vocês resolveram o desvio no terceiro estágio e não no quarto?"**
Porque o sinal de igualdade nasce na ALU, que está no terceiro. Resolver ali
descarta duas instruções em vez de três. Resolver no segundo descartaria
apenas uma, mas exigiria um comparador dedicado e encaminhamento adicional —
registramos como trabalho futuro.

**"O que acontece se o encaminhamento e o stall forem necessários ao mesmo
tempo?"**
A detecção tem prioridade. O registrador entre a busca e a decodificação
segura o valor em vez de descartá-lo, porque segurar é recuperável e
descartar não é.

**"Como vocês sabem que a bolha não altera nada?"**
O testbench do registrador aciona a limpeza com as entradas de escrita
ligadas e verifica que as saídas saem desligadas. São dois casos específicos
para isso.

**"Os módulos estão parametrizados?"**
Sim, todos. As larguras vêm de `parameter`, não de números escritos no corpo.
Vários testbenches instanciam o mesmo módulo duas vezes com larguras
diferentes para demonstrar.
