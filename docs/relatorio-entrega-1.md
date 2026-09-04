# Relatório técnico — 1ª entrega

Rascunho de trabalho. A versão final vai no template IEEE
(https://www.ieee.org/conferences/publishing/templates.html).

Prazo: 11/09/2026, 13:59h.

---

## 1. Título do projeto

_(preencher)_

## 2. Integrantes da equipe

_(preencher — nome e matrícula dos 3)_

## 3. Contexto, problema e objetivos

Perguntas a responder aqui — não escrever antes de ter resposta para todas:

- Que problema um processador com pipeline resolve que um monociclo não resolve?
- Por que o ganho não é proporcional ao número de estágios?
- O que exatamente este projeto se propõe a entregar ao fim das 4 apresentações?
- Qual o critério objetivo de sucesso? (o `sort` ordena corretamente na FPGA?)

## 4. Plataforma e material

- FPGA: _(modelo e família — precisa bater com o device configurado no .qsf)_
- Software de síntese: Intel Quartus Prime _(versão)_
- Simulador: _(ModelSim / Questa — versão)_
- Linguagem: Verilog
- Controle de versão: Git
- Gestão: Trello

## 5. Memória de programa codificada em binário

Fluxo: `mem/programa.asm` → `tools/assembler.py` → `mem/programa.mif`

Incluir no relatório:

- o código C original (do enunciado)
- a tradução em assembly MIPS, comentada
- a tabela de codificação: para cada instrução, os campos e os 32 bits
- explicação do formato R e do formato I usados

## 6. Plano de trabalho

Tabela de blocos × responsável × data-alvo, alinhada às 4 apresentações.
Ver a lista de blocos no README do repositório.

## 7. Gerenciamento no Trello

- link do board (visível para o professor)
- print das listas
- justificativa da organização escolhida: por que "Em simulação" é uma lista
  separada de "Fazendo", por que os cartões são por bloco funcional e não por
  estágio do pipeline
