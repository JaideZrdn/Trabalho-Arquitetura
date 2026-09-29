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

## Divisão do trabalho

A divisão da 1ª entrega dava à Pessoa C "pipeline, hazards e integração" —
mas esta etapa não tem pipeline nem hazards. Redistribuição para o período
até 09/10:

| Responsável | Blocos |
|---|---|
| **A** — memória e registradores | PC + somador de PC · memória de instruções · banco de registradores 32×32 · extensor de sinal · memória de dados |
| **B** (Ana C. E. Freire) — ULA e controle | ALU parametrizada · ALU control · unidade de controle (12 instruções) · somador de desvio e lógica de branch |
| **C** — jumps, integração e síntese | lógica de `j`/`jal`/`jr` e muxes do PC · muxes de escrita no banco · top-level · testbench do processador completo · projeto Quartus e síntese |

Quem ocupa os papéis A e C precisa ser decidido imediatamente — o relatório
da 1ª entrega deixou isso em aberto "até o início da 2ª etapa", e a etapa
começou.

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

**Tamanho da memória de dados.** O `main` inicializa `$sp` em 1024, e o vetor
de teste ocupa os endereços 0 a 31. A memória de dados precisa ter pelo menos
256 palavras para que a pilha caiba sem colidir com o vetor. Esse número é
requisito do bloco `Memória de dados`, e deve estar na descrição do cartão.

**Parametrização.** A rubrica 4 exige que todos os códigos sejam
parametrizados. Na prática: nenhuma largura literal no corpo dos módulos —
`parameter LARGURA = 32`, `parameter N_REGS = 32`, `parameter PROFUNDIDADE =
256`, e assim por diante.
