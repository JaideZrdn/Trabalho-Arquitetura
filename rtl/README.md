# rtl/ — o processador

Um arquivo `.v` por bloco funcional, com o testbench correspondente em `tb/`
(mesmo nome, sufixo `_tb`). O que está aqui é sintetizado e vai para a FPGA;
o que está em `tb/` só existe dentro do simulador.

Todos os módulos são parametrizados (`parameter LARGURA = 32`, etc.) — sem
largura literal no corpo. É exigência 4 da rubrica da 2ª entrega.

## Como compilar e simular

```bash
iverilog -g2012 -o build/sim rtl/<modulo>.v tb/<modulo>_tb.v
./build/sim
```

Funciona em macOS, Linux e Windows (`brew install icarus-verilog` no Mac). O
Quartus só é necessário para a síntese final, não para escrever nem validar
os módulos.

## Blocos da Pessoa A — memória e registradores (Jaide)

Ordem recomendada: do menor para o maior, porque o primeiro serve para
aprender o ciclo de trabalho sem que a lógica atrapalhe.

| # | módulo | objetivo | tipo | estado |
|---|---|---|---|---|
| 1 | `extensor_sinal` | esticar o imediato de 16 para 32 bits preservando o valor com sinal | combinacional | **pronto** |
| 2 | `pc` | guardar o endereço da instrução atual e atualizá-lo a cada ciclo | **sequencial** | a fazer |
| 3 | `banco_registradores` | armazenar os 32 registradores; duas leituras e uma escrita por ciclo; `$zero` sempre 0 | sequencial na escrita, combinacional na leitura | a fazer |
| 4 | `memoria_instrucoes` | entregar a instrução de 32 bits do endereço apontado pelo PC; carrega `mem/programa.txt` | combinacional (ROM) | a fazer |
| 5 | `memoria_dados` | ler e escrever palavras de 32 bits; usada por `lw` e `sw` | sequencial na escrita | a fazer |

**Requisito do módulo 5:** a memória de dados precisa de no mínimo 256
palavras. O `main` do programa inicializa `$sp` em 1024 e o vetor de teste
ocupa os endereços 0 a 31 — memória menor faz a pilha colidir com o vetor.

## Blocos das outras pessoas

- **Pessoa B (Ana):** ALU parametrizada, ALU control, unidade de controle,
  somador de desvio e lógica de branch.
- **Pessoa C (Manuela):** lógica de `j`/`jal`/`jr` e muxes do PC, top-level,
  projeto Quartus e síntese.

Plano completo, cartões do Trello e explicação do que é RTL:
[`docs/plano-entrega-2.md`](../docs/plano-entrega-2.md).
