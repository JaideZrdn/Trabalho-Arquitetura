# Relatório técnico — 1ª entrega

Rascunho de trabalho. A versão final vai no template IEEE
(https://www.ieee.org/conferences/publishing/templates.html), colada aqui
perto do prazo — até lá, este arquivo é a única fonte de verdade.

Prazo: 11/09/2026, 13:59h.

---

## 1. Título do projeto

Processador MIPS com Pipeline em Verilog

## 2. Integrantes da equipe

| Nome | Matrícula |
|---|---|
| Ana Clara Eid Freire | 22401684 |
| Jaide Fernando de Carvalho Zardin | 22350981 |
| Manuela Lopes Figueira | 22400983 |

## 3. Contexto, problema e objetivos

> Rascunho — revisem e reescrevam com as próprias palavras antes de submeter;
> isto é um ponto de partida, não o texto final.

Um processador **monociclo** executa cada instrução em um único ciclo de
clock, cuja duração é limitada pelo caminho crítico da instrução mais lenta
(tipicamente `lw`). Isso subutiliza o hardware durante instruções mais
simples e impede aumentar a frequência de operação. O **pipeline** resolve
esse problema dividindo a execução em estágios (IF, ID, EX, MEM, WB) que
processam instruções diferentes simultaneamente: o clock passa a ser
limitado pelo estágio mais lento — não pela instrução mais lenta — e, em
regime estável, uma instrução é concluída por ciclo.

O ganho não é proporcional ao número de estágios porque:

- **hazards de dados, controle e estruturais** forçam bolhas (*stalls*) que
  interrompem esse fluxo ideal;
- os **registradores de pipeline** entre estágios adicionam um overhead fixo
  de tempo a cada ciclo;
- o balanceamento entre estágios raramente é perfeito — o estágio mais lento
  dita o clock de todos os outros.

Este projeto se propõe a implementar, em Verilog, um processador MIPS com
pipeline de 5 estágios, tratando os três tipos de hazard, com todos os
blocos funcionais parametrizados e modularizados. O processador será
embarcado em uma FPGA DE2-115 e validado com o procedimento de ordenação por
inserção (`sort`/`swap`) especificado pelo professor.

**Critério objetivo de sucesso:** o vetor de teste é ordenado corretamente
pelo hardware — o resultado observado na FPGA (ou em simulação, antes da
síntese) confere com a saída esperada do `sort()` em C — com cada bloco
funcional validado isoladamente por testbench antes da integração.

## 4. Plataforma e material

- FPGA: **DE2-115** (Cyclone IV, EP4CE115)
- Software de síntese: Intel Quartus Prime _(confirmar versão instalada no laboratório)_
- Simulador: ModelSim-Altera Starter Edition _(versão bundled com o Quartus)_
- Linguagem: Verilog
- Controle de versão: Git
- Gestão: Trello

## 5. Memória de programa codificada em binário

Fluxo: `mem/programa.asm` → `tools/assembler.py` → `mem/programa.mif`

**Status atual (08/09/2026) — pendente:**

- `swap()` está traduzido e comentado em `mem/programa.asm`.
- `sort()` e `main()` ainda não foram traduzidos (plano de ataque já está
  escrito como comentário no próprio arquivo).
- `tools/assembler.py` tem as tabelas de registradores e opcodes prontas,
  mas as funções de codificação (`campo`, `codifica_r`, `codifica_i`,
  `codifica_j`, `primeira_passagem`, `monta`, `escreve_mif`) ainda não estão
  implementadas — nada gera o `.mif` no momento.

Quando concluído, esta seção deve trazer:

- o código C original (do enunciado);
- a tradução em assembly MIPS, comentada;
- a tabela de codificação: para cada instrução, os campos e os 32 bits;
- explicação dos formatos R e I usados.

## 6. Plano de trabalho

### Divisão por blocos funcionais

Divisão por bloco funcional (em vez de por fase do pipeline) para permitir
que os três trabalhem em paralelo desde o início — dividir por fase criaria
dependência sequencial entre as pessoas.

| Responsável | Blocos |
|---|---|
| **Pessoa A** — Datapath e memória | Banco de registradores · Memória de instruções · Memória de dados · Extensor de sinal · Multiplexadores do datapath |
| **Pessoa B** (Ana Freire) — ULA e controle | ALU parametrizada · Unidade de controle principal · ALU control · Somador de PC / lógica de branch-jump |
| **Pessoa C** — Pipeline, hazards e integração | Registradores de pipeline (IF/ID · ID/EX · EX/MEM · MEM/WB) · Unidade de forwarding · Detecção de hazard (stall) · Integração final + testbench do processador completo |

A e B constroem blocos praticamente independentes entre si, testáveis
isoladamente. C fica com a parte que só existe depois que as peças de A e B
estão prontas — enquanto isso, C adianta o estudo de forwarding/hazards e
monta o testbench do processador monociclo, que não depende do pipeline.

Todos participam da fase de testes e da escrita do relatório.

### Cronograma

| Período | Entregável | Meta |
|---|---|---|
| Até 11/09 | Setup + 1ª entrega | Quartus/Git configurados; FPGA confirmada (DE2-115); relatório e Trello da 1ª entrega |
| 11/09 – 09/10 | Blocos isolados | Assembly e binário do `sort` concluídos; cada bloco implementado e validado com testbench próprio; integração no datapath monociclo na 1ª semana de outubro |
| 09/10 – 13/11 | Pipeline completo | Registradores de estágio, forwarding e stall implementados; `sort` completo validado em simulação com hazards tratados |
| 13/11 – 11/12 | FPGA e fechamento | Síntese e gravação no DE2-115; debug de timing; relatório técnico completo; apresentação final |

## 7. Gerenciamento no Trello

Board: https://trello.com/b/IMyBoCgK/arquitetura-de-sistemas-digitais-mips-sugest%C3%A3o

Listas: `A Fazer` → `Fazendo` → `Em Simulação` → `Concluído`.

- Um cartão por bloco funcional (12 no total), cada um com o critério de
  pronto na descrição: interface definida → Verilog escrito → testbench
  escrito → simulação passa → integrado ao top-level → descrito no
  relatório.
- A lista **"Em Simulação"** é separada de **"Fazendo"** porque marca blocos
  com código já escrito mas ainda não validados — isso evita contar como
  pronto algo que pode quebrar na simulação.
- Cartões de acompanhamento da entrega atual (tradução assembly, montador,
  relatório, apresentação) ficam em "Fazendo" com checklist e prazo.

_(inserir print das listas aqui antes da entrega final)_
