# Processador MIPS com pipeline em Verilog

Projeto da disciplina de Arquitetura de Sistemas Digitais e Laboratório — UFAM.
Implementação em Verilog de um processador MIPS com pipeline, tratando perigos
(*hazards*) de dados, de controle e estruturais, embarcado em FPGA via Quartus.

Referência de projeto: Patterson & Hennessy, *Computer Organization and Design*,
4ª edição revisada.

## Equipe

| Nome | Matrícula | Blocos sob responsabilidade |
|---|---|---|
| Ana Clara Eid Freire | 22401684 | Pessoa B — ULA e controle |
| Jaide Fernando de Carvalho Zardin | 22350981 | _(a decidir — Pessoa A ou C)_ |
| Manuela Lopes Figueira | 22400983 | _(a decidir — Pessoa A ou C)_ |

Divisão por bloco funcional (não por fase do pipeline), pra permitir trabalho
em paralelo desde o início:

- **Pessoa A — Datapath e memória:** banco de registradores · memória de
  instruções · memória de dados · extensor de sinal · multiplexadores do
  datapath
- **Pessoa B — ULA e controle:** ALU parametrizada · unidade de controle
  principal · ALU control · somador de PC / lógica de branch-jump
- **Pessoa C — Pipeline, hazards e integração:** registradores de pipeline ·
  unidade de forwarding · detecção de hazard (stall) · integração final +
  testbench do processador completo

Todos participam da fase de testes e da escrita do relatório.

## Estrutura do repositório

```
rtl/        blocos funcionais em Verilog — um arquivo por bloco
tb/         testbenches, um por bloco de rtl/
mem/        programa.asm  →  programa.mif   (memória de programa, item 5)
tools/      assembler.py — monta o .mif a partir do .asm
quartus/    .qpf / .qsf / .sdc — projeto Quartus
docs/       relatório técnico (template IEEE) e diagramas
```

## Programa de teste

O processador é validado com o procedimento de ordenação por inserção
(`sort` chamando `swap`) definido na especificação do trabalho.

Convenção de registradores fixada pelo enunciado:

| Variável | Registrador |
|---|---|
| `v` (vetor) | `$a0` |
| `n` (tamanho) | `$a1` |
| `i` | `$s0` |
| `j` | `$s1` |

Fluxo até a memória de programa:

```
mem/programa.asm  --[ tools/assembler.py ]-->  mem/programa.mif  -->  memória de instrução (rtl/)
```

O `.mif` é **gerado**, nunca editado à mão. Alterou o `.asm`, roda o montador e
commita os dois juntos.

**Status (08/09/2026):** `mem/programa.asm` está completo — `swap()`,
`sort()` e `main()` traduzidos, incluindo o salto de entrada `j main` no
endereço 0 (sem ele o processador cairia dentro de `swap()` no boot, já que
o PC começa em 0 e executa a primeira instrução física do arquivo, não um
rótulo). Validado por simulação de execução instrução-a-instrução a partir
do endereço 0: o vetor de teste termina ordenado corretamente.
`tools/assembler.py` **ainda não está implementado** — sem ele não é
possível gerar o `.mif`.

## Blocos funcionais

Cada bloco é um cartão no Trello e um par `rtl/<bloco>.v` + `tb/<bloco>_tb.v`.

**Caminho de dados**

- PC + somador de PC — Pessoa B
- Memória de instrução — Pessoa A
- Banco de registradores — Pessoa A
- Extensor de sinal — Pessoa A
- ALU + ALU control — Pessoa B
- Memória de dados — Pessoa A
- Multiplexador de escrita — Pessoa A
- Multiplexador de forwarding — Pessoa C _(fica junto da unidade de
  forwarding; confirmar com quem pegar essa frente)_

**Registradores de pipeline**

- IF/ID · ID/EX · EX/MEM · MEM/WB — Pessoa C

**Controle e hazards**

- Unidade de controle — Pessoa B
- Unidade de forwarding — Pessoa C
- Unidade de detecção de hazard (stall) — Pessoa C
- Tratamento de hazard de controle (branch) — Pessoa C _(fronteira com o
  somador de PC/branch da Pessoa B; acertar a interface entre os dois)_

Todos os blocos devem ser parametrizados (larguras via `parameter`), conforme
exige o enunciado.

## Critério de pronto

Um bloco só sai de "Fazendo" quando:

- [ ] interface definida (portas e larguras parametrizadas)
- [ ] Verilog escrito
- [ ] testbench escrito
- [ ] simulação passa
- [ ] integrado ao top-level
- [ ] descrito no relatório

O último item é o que costuma ser esquecido. O relatório pede a descrição de
todos os blocos **e** dos testes de cada um — escrever no fim significa
reconstruir de memória e perder ponto.

## Trabalhando com Quartus e git

Três regras que evitam a maior parte da dor:

1. **Uma pessoa é dona do `.qsf`.** O Quartus reescreve e reordena esse arquivo
   sozinho ao salvar, e merge automático nele produz projeto que não abre.
   Os outros integrantes editam apenas arquivos em `rtl/` e `tb/`.
2. **Caminhos no `.qsf` têm que ser relativos.** Se aparecer algo como
   `C:/Users/fulano/...` numa linha `set_global_assignment -name VERILOG_FILE`,
   o projeto não abre na máquina dos outros dois.
3. **Feche o Quartus antes de `git pull` ou `git checkout`.** Com o projeto
   aberto a ferramenta segura lock nos arquivos e o merge sai sujo.

Nada dentro de `db/`, `incremental_db/`, `output_files/` ou `simulation/` é
versionado — é tudo gerado e pesa centenas de MB.

## Plano de trabalho

Apresentações parciais definidas no enunciado:

| Entrega | Data | Escopo previsto |
|---|---|---|
| 1ª | 11/09/2026 | Contexto, plataforma, memória de programa, plano, Trello |
| 2ª | 09/10/2026 | Datapath monociclo rodando em simulação, executando ao menos uma instrução de cada formato (R, I, J) |
| 3ª | 13/11/2026 | Pipeline completo em simulação, com os três tipos de hazard tratados e o `sort` completo validado |
| 4ª | 11/12/2026 | Processador sintetizado e testado na DE2-115; relatório técnico completo; apresentação final |

## Primeira entrega — checklist

Itens exigidos, conforme enunciado da apresentação:

- [x] 1. Título do projeto
- [x] 2. Nome dos integrantes
- [ ] 3. Contexto, problema e objetivos — rascunho pronto em `docs/relatorio-entrega-1.md`, falta revisar com as próprias palavras
- [ ] 4. Plataforma e material necessário — FPGA (DE2-115) e simulador (ModelSim-Altera) definidos; falta confirmar versão do Quartus do laboratório
- [ ] 5. Memória de programa codificada em binário — assembly completo e validado por simulação; falta implementar `tools/assembler.py` pra gerar o `.mif`
- [ ] 6. Plano de trabalho — cronograma e divisão por bloco prontos; falta decidir quem é Pessoa A e Pessoa C
- [ ] 7. Gerenciamento do projeto no Trello — board criado (link no relatório); falta print das listas

Prazo: **11/09/2026, 13:59h.** Atraso desconta 2 pontos por dia.
