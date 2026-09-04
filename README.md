# Processador MIPS com pipeline em Verilog

Projeto da disciplina de Arquitetura de Sistemas Digitais e Laboratório — UFAM.
Implementação em Verilog de um processador MIPS com pipeline, tratando perigos
(*hazards*) de dados, de controle e estruturais, embarcado em FPGA via Quartus.

Referência de projeto: Patterson & Hennessy, *Computer Organization and Design*,
4ª edição revisada.

## Equipe

| Nome | Matrícula | Blocos sob responsabilidade |
|---|---|---|
| _(preencher)_ | | |
| _(preencher)_ | | |
| _(preencher)_ | | |

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

## Blocos funcionais

Cada bloco é um cartão no Trello e um par `rtl/<bloco>.v` + `tb/<bloco>_tb.v`.

**Caminho de dados**

- PC + somador de PC
- Memória de instrução
- Banco de registradores
- Extensor de sinal
- ALU + ALU control
- Memória de dados
- Multiplexadores de escrita e de forwarding

**Registradores de pipeline**

- IF/ID · ID/EX · EX/MEM · MEM/WB

**Controle e hazards**

- Unidade de controle
- Unidade de forwarding
- Unidade de detecção de hazard (stall)
- Tratamento de hazard de controle (branch)

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
| 2ª | 09/10/2026 | _(preencher)_ |
| 3ª | 13/11/2026 | _(preencher)_ |
| 4ª | 11/12/2026 | _(preencher)_ |

## Primeira entrega — checklist

Itens exigidos, conforme enunciado da apresentação:

- [ ] 1. Título do projeto
- [ ] 2. Nome dos integrantes
- [ ] 3. Contexto, problema e objetivos
- [ ] 4. Plataforma e material necessário
- [ ] 5. Memória de programa codificada em binário
- [ ] 6. Plano de trabalho
- [ ] 7. Gerenciamento do projeto no Trello

Prazo: **11/09/2026, 13:59h.** Atraso desconta 2 pontos por dia.
