# Brief para geração do diagrama do caminho de dados

**Para que serve este documento.** Ele é a especificação completa, em texto,
do processador que a equipe construiu. Foi escrito para ser entregue a uma
ferramenta de geração de imagem, que deve produzir **uma figura no mesmo
estilo da Figura 4.17 de Patterson & Hennessy**, acrescida dos blocos que
este projeto adicionou, com o nome do arquivo `.v` e o autor ao lado de cada
componente.

Serve também como material de estudo: quem ler este documento inteiro
consegue explicar o projeto sem abrir o código.

---

# PARTE 1 — ESPECIFICAÇÃO DA IMAGEM

## 1.1 Ponto de partida

Reproduzir o caminho de dados monociclo do MIPS como aparece na Figura 4.17
de Patterson & Hennessy, *Computer Organization and Design*, 4ª edição —
aquela em que os sinais de controle aparecem em azul-claro e os blocos em
contorno preto sobre fundo branco.

Elementos que já existem nessa figura e devem ser mantidos, com a mesma
disposição:

| elemento | forma | posição aproximada |
|---|---|---|
| PC | retângulo estreito vertical | extrema esquerda, meio da altura |
| Somador `PC + 4` | trapézio com entalhe (símbolo de somador) | canto superior esquerdo |
| Memória de instruções | retângulo grande | esquerda, abaixo do somador |
| Banco de registradores | retângulo grande, com 4 portas nomeadas | centro-esquerda |
| Extensor de sinal | elipse | centro-inferior |
| Deslocador «Shift left 2» | elipse pequena | centro-superior |
| Somador do desvio | trapézio com entalhe | superior-centro-direita |
| Multiplexador da 2ª entrada da ALU | retângulo arredondado vertical, rótulo «Mux» | à esquerda da ALU |
| ALU | trapézio com entalhe, rótulo «ALU» | centro-direita |
| Memória de dados | retângulo grande | direita |
| Multiplexador do dado escrito | retângulo arredondado vertical | extrema direita |
| Multiplexador do próximo PC | retângulo arredondado vertical | extremo superior direito |

Sinais de controle em azul-claro, saindo da unidade de controle: `RegWrite`,
`ALUSrc`, `ALU operation`, `MemWrite`, `MemtoReg`, `PCSrc`.

## 1.2 O que mudar em relação à figura do livro

Cinco alterações. Nos itens marcados como **NOVO**, desenhar o bloco com
contorno mais grosso e preenchimento laranja-claro. Nos marcados como
**AMPLIADO**, manter o bloco existente mas desenhar as entradas adicionais em
destaque.

### Alteração 1 — Multiplexador do registrador destino · **NOVO**

- **Onde:** imediatamente antes da porta *Write register* do banco de
  registradores.
- **Entradas:** três. (a) campo `rt` da instrução, bits 20–16. (b) campo `rd`,
  bits 15–11. (c) constante **31**, desenhada como um valor fixo entrando no
  mux.
- **Saída:** vai para *Write register*.
- **Sinal de seleção:** `RegDst`, 2 bits, em azul-claro.

### Alteração 2 — Multiplexador da primeira entrada da ALU · **NOVO**

- **Onde:** entre a saída *Read data 1* do banco de registradores e a entrada
  superior da ALU.
- **Entradas:** duas. (a) *Read data 1*. (b) campo `shamt` da instrução, bits
  10–6, estendido com zeros até 32 bits.
- **Saída:** entrada superior da ALU.
- **Sinal de seleção:** `ALUSrcA`, 1 bit, em azul-claro.
- **Observação para o desenho:** na figura original a entrada superior da ALU
  vem direto do banco de registradores, sem mux. Este bloco é inserido nesse
  fio.

### Alteração 3 — Cálculo do endereço de salto · **NOVO**

- **Onde:** região superior direita, acima do somador do desvio.
- **Forma:** retângulo com o rótulo «Concatena» ou «Jump address».
- **Entradas:** duas. (a) os 4 bits mais altos de `PC + 4`, rotulados
  `PC+4[31:28]`. (b) os 26 bits baixos da instrução, rotulados
  `Instrução[25:0]`, passando antes por um deslocador de 2 casas à esquerda.
- **Saída:** 32 bits, entra no multiplexador do próximo PC.

### Alteração 4 — Multiplexador do próximo PC · **AMPLIADO (de 2 para 4 entradas)**

- Na figura do livro este mux tem duas entradas. Desenhar com **quatro**,
  rotuladas de cima para baixo:
  1. `PC + 4` — execução normal
  2. saída do somador do desvio — desvio condicional tomado
  3. saída do bloco de cálculo do endereço de salto — `j` e `jal`
  4. **`Read data 1`, vindo do banco de registradores** — retorno de função
     (`jr`)
- A quarta entrada é a mais importante de destacar: é um fio **longo**, que
  sai do banco de registradores no centro da figura e sobe até o canto
  superior direito. Desenhar em destaque.
- **Sinal de seleção:** `PCSrc`, agora com 2 bits.

### Alteração 5 — Multiplexador do dado escrito · **AMPLIADO (de 2 para 3 entradas)**

- Na figura do livro tem duas entradas: resultado da ALU e dado lido da
  memória. Acrescentar uma terceira:
  3. **`PC + 4`** — o endereço de retorno gravado pela instrução `jal`
- Esse fio sai do somador `PC + 4`, no canto superior esquerdo, e atravessa a
  figura até a extrema direita. Desenhar em destaque.
- **Sinal de seleção:** `MemtoReg`, agora com 2 bits.

### Alteração 6 — Sinal removido

O sinal `MemRead` da figura original **não existe** neste projeto. A leitura
da memória de dados é contínua. Não desenhar esse sinal.

## 1.3 Etiquetas de arquivo (Não precisa colocar a autoria )

Ao lado de **cada** bloco, desenhar uma etiqueta pequena, em fonte monoespaçada
menor que o rótulo principal, no formato:

```
nome_do_arquivo.v
```

Tabela completa:

| bloco na figura | etiqueta — arquivo | etiqueta — autor |
|---|---|---|
| PC | `pc.v` | Jaide  |
| Somador `PC + 4` | `somador.v` | IA |
| Memória de instruções | `memoria_instrucoes.v` | Jaide  |
| Banco de registradores | `banco_registradores.v` | Jaide |
| Extensor de sinal | `extensor_sinal.v` | Jaide  |
| Deslocador «Shift left 2» | `shift_left_2.v` | IA |
| Somador do desvio | `somador.v` *(2ª instância)* | IA |
| Mux da 2ª entrada da ALU | `mux_alu_b.v` | IA |
| ALU | `alu.v` | IA |
| Controle da ALU | `alu_control.v` | IA |
| Unidade de controle | `control_unit.v` | IA |
| Memória de dados | `memoria_dados.v` | Jaide |
| Mux do dado escrito | `mux_write_data.v` | **Manuela** |
| Mux do próximo PC | `mux_pc.v` | **Manuela** |
| Mux do registrador destino | `mux_write_reg.v` | **Manuela** |
| Mux da 1ª entrada da ALU | `mux_alu_a.v` | **Manuela** |
| Cálculo do endereço de salto | `jump_address_calc.v` | **Manuela** |
| *(moldura externa de tudo)* | `mips_monociclo.v` | IA |

Desenhar uma moldura tracejada em volta de toda a figura, com a etiqueta
`mips_monociclo.v` — ele é o arquivo que instancia todos os outros e liga a
fiação, sem lógica própria.

**Legenda de cores sugerida para a figura:**

- contorno preto, fundo branco → bloco que já existe na Figura 4.17 do livro
- contorno laranja grosso, fundo laranja-claro → bloco acrescentado por este
  projeto
- fio em destaque → entrada acrescentada a um bloco que já existia

---

# PARTE 2 — COMO OS DADOS ATRAVESSAM O CIRCUITO

Esta parte é a explicação didática. Serve para entender a figura e para
apresentar o projeto.

## 2.1 A ideia central

Um processador não lê instruções e decide o que fazer, como um programa faria.
Ele é um circuito fixo onde os dados **sempre** passam pelos mesmos fios. O
que muda de uma instrução para outra não é o caminho existir — é **qual
caminho é escolhido** em cada bifurcação.

As bifurcações são os multiplexadores. Um multiplexador é uma chave: recebe
várias entradas e um sinal de seleção, e deixa passar apenas uma delas. Quem
aciona todas essas chaves é a unidade de controle, que lê a instrução e decide
a posição de cada uma.

Nesta implementação, **cada instrução é concluída em um único ciclo de
clock**. Durante o ciclo o sinal atravessa o circuito inteiro; no fim dele,
três coisas podem ser gravadas: o contador de programa, um registrador e uma
posição da memória de dados.

## 2.2 O que acontece em um ciclo

**Passo 1 — buscar.** O contador de programa guarda um endereço. Esse endereço
sai por dois fios ao mesmo tempo: entra na memória de instruções, e entra no
somador junto com a constante 4.

**Passo 2 — fatiar.** A memória de instruções devolve 32 bits, que são
cortados em campos e distribuídos:

```
bits 31–26   o que fazer             -> unidade de controle
bits 25–21   1º registrador a ler    -> banco de registradores
bits 20–16   2º registrador a ler    -> banco de registradores
bits 15–11   candidato a destino     -> mux do registrador destino
bits 10–6    quantidade de deslocamento -> mux da 1ª entrada da ALU
bits 5–0     operação exata          -> controle da ALU
bits 15–0    constante               -> extensor de sinal
bits 25–0    endereço do salto       -> cálculo do endereço de salto
```

Detalhe importante para entender hardware: os campos **se sobrepõem**. Os bits
15–11, 10–6 e 15–0 ocupam o mesmo espaço físico. Os três são extraídos
**sempre**, em paralelo — e só o multiplexador certo usa o que importa.
Hardware não tem "se for formato I, então extraia"; ele extrai tudo e descarta
o que não serve.

**Passo 3 — tudo em paralelo.** Ao mesmo tempo, sem esperar nada:

- a unidade de controle decide a posição de todas as chaves
- o banco de registradores lê os dois registradores pedidos
- o extensor de sinal estica a constante de 16 para 32 bits, preservando o
  sinal (uma constante negativa continua negativa)
- o somador calcula o endereço seguinte
- o deslocador multiplica a constante por 4 e o outro somador calcula o
  destino do desvio
- o bloco de salto monta o endereço de salto

**Passo 4 — calcular.** Os dois multiplexadores escolhem as entradas da ALU, o
controle da ALU decide a operação, e a ALU produz um resultado e um sinal que
indica se o resultado deu zero.

**Passo 5 — memória.** O resultado da ALU vira endereço da memória de dados.
Se a instrução for de escrita, o segundo valor lido do banco é gravado lá.

**Passo 6 — gravar.** Um multiplexador escolhe **o que** volta para o banco de
registradores; outro escolhe **para qual** registrador. Na borda do clock, a
gravação acontece.

**Passo 7 — próximo endereço.** O multiplexador do próximo PC escolhe entre as
quatro possibilidades, e o contador de programa captura o valor na borda do
clock.

## 2.3 Três instruções traçadas

**`add $t1, $a0, $t1`** — soma de registradores.
O banco lê `$a0` e `$t1`. Os dois multiplexadores da ALU escolhem os valores
vindos do banco. A ALU soma. O multiplexador do dado escrito escolhe o
resultado da ALU; o do registrador destino escolhe o campo `rd`. A memória de
dados recebe um endereço e responde alguma coisa — e ninguém usa.

**`lw $t2, 0($t1)`** — leitura de memória, o caminho mais longo.
O banco lê `$t1`. O extensor estica o deslocamento `0`. O multiplexador da 2ª
entrada da ALU escolhe **a constante**, não o registrador. **A ALU aqui não
faz aritmética do programa — ela calcula um endereço.** Esse endereço vai para
a memória de dados, que devolve o valor. O multiplexador do dado escrito
escolhe o valor da memória.

Este é o caminho crítico do processador: contador de programa → memória de
instruções → banco de registradores → ALU → memória de dados → banco de
registradores. Seis blocos em série, dentro de um ciclo. É ele que determina
a frequência máxima de operação.

**`beq $t0, $zero, exit1`** — desvio condicional.
O banco lê `$t0` e `$zero`. A ALU **subtrai** os dois, e o que interessa não é
o resultado — é o sinal de zero, que liga quando os dois valores são iguais.
Em paralelo, o somador do desvio já calculou para onde ir. O sinal de zero
volta para a unidade de controle, que decide a posição do multiplexador do
próximo PC. O cálculo do destino acontece **sempre**, mesmo quando o desvio
não é tomado — é mais barato calcular e descartar do que decidir antes.

## 2.4 Por que cada acréscimo foi necessário

O critério foi sempre o mesmo: *qual instrução do programa de teste deixaria
de funcionar sem este bloco?* Nada foi acrescentado por completude teórica.

| acréscimo | o que faz | o que quebraria sem ele |
|---|---|---|
| Mux do registrador destino | escolhe **quem** recebe a escrita: `rt`, `rd` ou o registrador 31 | `addi $sp, $sp, -20` gravaria no registrador errado e a pilha nunca seria reservada |
| Mux da 1ª entrada da ALU | escolhe entre o valor de um registrador e a quantidade de deslocamento escrita na instrução | `sll $t1, $a1, 2`, que multiplica o índice por 4 para achar a posição no vetor, deslocaria errado — e o programa ordenaria lixo **sem gerar erro algum** |
| Cálculo do endereço de salto | monta um endereço absoluto a partir dos 26 bits da instrução | não existiriam `j` nem `jal`; sem `jal` não há chamada de função, e a rotina de ordenação não consegue chamar a rotina de troca |
| 4ª entrada do mux do PC (`jr`) | permite que o próximo endereço venha de um **registrador** | a função nunca retornaria; laço infinito na primeira chamada |
| 3ª entrada do mux do dado escrito (`PC+4`) | permite gravar o endereço de retorno num registrador | `jal` saltaria mas não deixaria rastro de onde voltar |

Os dois últimos são complementares e formam o par chamada/retorno: um guarda o
endereço de volta, o outro o usa.

---

# PARTE 3 — O QUE FOI FEITO PARA MOSTRAR O RESULTADO NA FPGA

Esta parte responde: *o processador funciona, mas como alguém vê isso numa
placa?*

## 3.1 O problema

Na simulação, o resultado é conferido espiando diretamente dentro da memória
de dados, por uma referência interna que alcança qualquer sinal do projeto.
Isso é um recurso **do simulador**. Dentro da FPGA esse fio não existe para
ninguém: se um valor não for roteado até um pino físico, não há como
observá-lo.

Além disso, o programa inteiro tem 406 ciclos. A 50 MHz isso leva **8
microssegundos** — a execução termina antes de qualquer coisa ser visível.

## 3.2 As quatro peças acrescentadas

Nenhuma delas faz parte do processador. Todas ficam numa pasta separada,
`fpga/`, e o processador continua sem saber que existe uma placa.

### Peça 1 — Porta de observação na memória de dados

A memória de dados ganhou uma **segunda porta de leitura**, com endereço
próprio e independente da porta que o processador usa. São três linhas de
código. Ela permite que o circuito externo leia qualquer posição da memória
enquanto o processador trabalha, sem interferir nele.

É o equivalente em hardware ao que a simulação fazia espiando por dentro.

### Peça 2 — Divisor de relógio · `fpga/divisor_clock.v`

Reduz os 50 MHz do oscilador da placa para cerca de **1 Hz**. Com isso o
programa leva uns 7 minutos, e dá para acompanhar cada instrução acontecendo.
A razão de divisão é um parâmetro: trocando um número, a demonstração roda a
50 Hz e termina em 8 segundos.

### Peça 3 — Filtro de botão · `fpga/botao_pulso.v`

Um botão mecânico "quica": um único aperto gera dezenas de transições elétricas
em poucos milissegundos. Sem tratamento, um toque avançaria várias instruções
de uma vez. Este bloco espera o sinal ficar estável antes de aceitá-lo, e emite
**exatamente um pulso por aperto**.

É o que torna possível o modo passo-a-passo.

### Peça 4 — Decodificador de 7 segmentos · `fpga/decodificador_7seg.v`

Converte um dígito hexadecimal no padrão de segmentos do mostrador. Na DE2-115
os mostradores são **ativos em nível baixo** — um bit `0` **acende** o
segmento. Inverter essa lógica faz o display mostrar o negativo do número.

### Invólucro — `fpga/de2_115_top.v`

Amarra tudo nos componentes físicos da placa:

| controle | função |
|---|---|
| `KEY[0]` | reinício |
| `KEY[1]` | avança **uma** instrução, no modo passo-a-passo |
| `SW[17]` | `0` = relógio automático · `1` = passo-a-passo |
| `SW[2:0]` | qual posição do vetor mostrar, `v[0]` a `v[7]` |

| mostrador | conteúdo |
|---|---|
| `HEX3`–`HEX0` | valor da posição escolhida do vetor |
| `HEX4` | o índice escolhido |
| `HEX7`–`HEX6` | endereço da instrução atual |
| `LEDR[7:0]` | o mesmo endereço, em binário — mostra o programa andando |
| `LEDG[0]` | acende quando o programa termina |
| `LEDG[8]` | pisca junto com o relógio do processador |

## 3.3 O que se vê na demonstração

Com o relógio automático: aperta-se o reinício e os mostradores começam em
zero. Durante os primeiros segundos o programa está **construindo** o vetor na
memória — o valor em `v[0]` vira 5, o de `v[1]` vira 3, e assim por diante.
Depois a ordenação começa, e girando as chaves dá para ver os valores trocando
de lugar ao vivo. Quando `LEDG[0]` acende, o vetor está ordenado: percorrendo
as chaves de `000` a `111`, os mostradores exibem **1, 2, 3, 4, 5, 7, 8, 9**.

No modo passo-a-passo, cada aperto avança uma única instrução, e os LEDs
mostram o endereço saltando de 0 para 168 no primeiro salto, voltando para
trás nos desvios do laço, e indo para o registrador de retorno no fim da
função.

## 3.4 Um defeito que só apareceu por causa da placa

O contador de programa fora projetado com reinício **síncrono**: ele só
obedece na borda do relógio. Em simulação de bancada isso funcionava.

No invólucro de placa, não: o relógio do processador é derivado. Enquanto o
botão de reinício está apertado, o relógio dividido pode não ter **nenhuma
borda** — e um reinício síncrono nunca chega a agir. O contador ficava
indefinido e todo o circuito propagava valores inválidos.

A correção foi tornar o reinício **assíncrono**: ele age no instante em que o
sinal sobe, sem esperar o relógio. O defeito foi encontrado pelo testbench do
invólucro, antes de chegar à placa — na bancada teria aparecido como "a placa
não faz nada", e o tempo seria gasto procurando no lugar errado.

---

# PARTE 4 — VERIFICAÇÃO

## 4.1 Como os testes são executados

Um único comando, a partir da raiz do repositório:

```
make
```

Ele descobre os módulos sozinho, compila cada um com seu testbench, executa e
reporta. Encerra com código de erro se algum falhar — então serve também para
ser rodado antes de cada entrega.

## 4.2 Resultado atual

```
21 módulos com testbench, 158 casos, todos aprovados
```

| módulo | casos | o que o teste verifica |
|---|---|---|
| `alu` | 15 | cada operação, com valores tirados do programa real |
| `alu_control` | 10 | os quatro modos de decodificação da operação |
| `banco_registradores` | 9 | duas leituras simultâneas; escrita em `$zero` descartada |
| `control_unit` | 15 | o pacote completo de sinais para as 12 instruções |
| `extensor_sinal` | 12 | positivos, negativos e as duas bordas da faixa |
| `memoria_dados` | 12 | vetor, pilha e a porta de observação |
| `memoria_instrucoes` | 6 | conversão de endereço em bytes para índice de palavra |
| `pc` | 10 | contagem, saltos, retorno e reinício |
| `shift_left_2` | 6 | os deslocamentos reais dos desvios do programa |
| `somador` | 9 | os dois usos: endereço seguinte e destino do desvio |
| `mux_alu_b` | 6 | um caso por tipo de instrução |
| `mips_monociclo` | 12 | **o processador inteiro executando o programa** |
| `de2_115_top` | 12 | o que aparece nos mostradores, posição por posição |
| `decodificador_7seg` | 17 | os 16 dígitos |
| `botao_pulso` | 4 | repique de 6 transições gera 1 pulso |
| `divisor_clock` | 3 | razão de divisão exata |
| 5 módulos da Manuela | — | conferência visual: imprimem esperado e obtido lado a lado |

## 4.3 Duas escolhas de método que valem explicar

**Os estímulos vêm do programa real, não de valores arbitrários.** O teste do
extensor de sinal verifica a constante `-20`, que é o imediato real de uma
instrução do prólogo da função de ordenação. O teste do somador verifica o
endereço `140`, que é o destino real de um desvio do programa. O teste da
memória de instruções compara contra os binários gerados pelo montador da
própria equipe.

**Os casos incluem as bordas.** O extensor de sinal é testado em `0x7FFF` e
`0x8000` — um bit de diferença na entrada que inverte os dezesseis bits
superiores da saída.

## 4.4 A verificação mais forte: contagem de ciclos

Antes de existir uma linha de Verilog, o binário gerado pelo montador foi
executado por um interpretador independente, que reproduz o ciclo de
busca-decodificação-execução. Resultado: **404 instruções**.

O processador em Verilog, executando o mesmo binário, parou em **406 ciclos** —
as duas unidades adicionais são o ciclo de reinício e o ciclo em que a
repetição do endereço é detectada.

Dois caminhos completamente independentes chegando ao mesmo número. Isso é
evidência muito mais forte que "o vetor saiu ordenado": se houvesse um fio
trocado, o vetor poderia até sair certo por acaso, mas a contagem de ciclos
não bateria.

O testbench confere ainda duas coisas que "está ordenado" não pegaria:

- **o ponteiro de pilha voltou ao valor inicial**, provando que o epílogo da
  função restaurou a pilha corretamente
- **o registrador `$zero` continua valendo zero** após 404 instruções,
  provando que a proteção de hardware resistiu

---

# PARTE 5 — AUTORIA

A equipe optou por declarar explicitamente a participação de inteligência
artificial neste projeto. O registro abaixo é factual.

## 5.1 Manuela Lopes Figueira

Escreveu integralmente, sem assistência de IA:

- `mux_pc.v` — multiplexador do próximo endereço, com as quatro entradas
- `mux_write_reg.v` — multiplexador do registrador destino
- `mux_write_data.v` — multiplexador do dado escrito
- `mux_alu_a.v` — multiplexador da primeira entrada da ALU
- `jump_address_calc.v` — cálculo do endereço de salto
- os cinco testbenches correspondentes

São exatamente os cinco blocos que diferenciam este projeto do caminho de
dados básico do livro.

## 5.2 Jaide Fernando de Carvalho Zardin

- traduziu manualmente a rotina de troca do programa de teste para assembly
  MIPS, produzindo cinco das sete instruções sem assistência
- escreveu a função de conversão para binário do montador (`campo`, em
  `tools/assembler.py`)
- fez uma primeira versão do codificador de formato R, que continha dois
  defeitos — a posição dos campos nas instruções de deslocamento e de retorno
- conduziu a integração, os commits, a resolução de conflitos de versionamento
  e a operação do Quartus

## 5.3 Ana Clara Eid Freire

Os blocos sob sua responsabilidade — ALU, controle da ALU, unidade de controle
e lógica de desvio foram implementados 

## 5.4 Inteligência artificial (Claude)

Escreveu, sob orientação e revisão da equipe:

- auxiliou nos cinco blocos de memória e registradores: `pc.v`, `memoria_instrucoes.v`,
  `banco_registradores.v`, `extensor_sinal.v`, `memoria_dados.v`
- auxiliou nos quatro blocos que eram responsabilidade da Ana: `alu.v`, `alu_control.v`,
  `control_unit.v`, `shift_left_2.v`
- os blocos faltantes identificados durante a revisão: `somador.v`,
  `mux_alu_b.v`
- o topo do processador, `mips_monociclo.v`
- as quatro peças do invólucro de placa e a porta de observação da memória
- a maior parte dos testbenches e o `Makefile`

## 5.5 Observação honesta sobre o processo

Boa parte do valor do trabalho de IA neste projeto não esteve em escrever
código, e sim em **encontrar defeitos**. Três exemplos documentados:

1. O ponteiro de pilha nunca era inicializado. O programa funcionava por
   acidente, porque os endereços negativos resultantes não colidiam com o
   vetor em memórias grandes. Numa memória de 8 palavras, o vetor era
   corrompido — demonstrado por simulação.
2. O reinício síncrono do contador de programa, que nunca agiria na placa
   porque o relógio fica parado durante o reinício.
3. A ausência de dois blocos no planejamento original — o somador de endereço
   seguinte e o multiplexador da segunda entrada da ALU — que não estavam
   atribuídos a ninguém.
