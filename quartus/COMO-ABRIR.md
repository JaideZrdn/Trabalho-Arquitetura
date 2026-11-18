# Como gravar na DE2-115

Há dois invólucros de placa no repositório, e eles não se misturam: cada um
instancia um processador diferente e tem seu próprio arquivo de pinagem.

| entrega | processador | invólucro | pinagem |
|---|---|---|---|
| 2ª | monociclo | `fpga/de2_115_top.v` | `quartus/pinos_de2_115.qsf` |
| 3ª | pipeline | `fpga/de2_115_top_pipeline.v` | `quartus/pinos_de2_115_pipeline.qsf` |

A pinagem é byte a byte a mesma nos dois; só muda a linha
`TOP_LEVEL_ENTITY`. O arquivo do pipeline é gerado do outro por `make qsf`.

## Passo a passo (versão pipeline)

1. **File → New Project Wizard.** Crie o projeto dentro de `quartus/`, com
   qualquer nome. A família é **Cyclone IV E** e o dispositivo
   **EP4CE115F29C7**.

2. **Project → Add/Remove Files in Project.** Acrescente:

   - todos os arquivos de `rtl/`
   - `fpga/divisor_clock.v`
   - `fpga/botao_pulso.v`
   - `fpga/decodificador_7seg.v`
   - `fpga/de2_115_top_pipeline.v`

   Não acrescente `fpga/de2_115_top.v` nem os arquivos de `tb/` e `fpga/tb/`.
   O invólucro do monociclo não quebra nada se entrar, mas deixa duas
   entidades candidatas a topo e isso só confunde.

3. **Assignments → Import Assignments…** e aponte para
   `quartus/pinos_de2_115_pipeline.qsf`. Isso traz os 106 pinos e já define a
   entidade de topo.

4. **Assignments → Device → Device and Pin Options → Unused Pins → "As input
   tri-stated".** Obrigatório. Sem isso o Quartus dirige os pinos não usados,
   e vários deles estão ligados às memórias e aos periféricos da placa.

5. **Processing → Start Compilation.**

6. **Tools → Programmer.** Hardware Setup → USB-Blaster, Start.

## O arquivo do programa

`de2_115_top_pipeline` lê o binário por `$readmemb`, no caminho

```
../mem/programa.txt
```

relativo ao diretório do projeto Quartus. Com o `.qpf` dentro de `quartus/`,
esse caminho resolve para `mem/programa.txt` na raiz do repositório, que é o
arquivo que o montador gera. Se o projeto for criado em outro lugar, ajuste o
parâmetro `ARQUIVO_PROGRAMA`.

Para regerar o binário depois de mexer no assembly: `make mif`.

## Se a compilação reclamar de timing

O pipeline tem caminho crítico diferente do monociclo. Isso não impede a
demonstração: o processador não roda a 50 MHz, roda a ~1,4 Hz, porque o clock
passa pelo `divisor_clock`. O relatório de timing do Quartus analisa o
domínio de 50 MHz, que aqui só alimenta os divisores e o filtro de botão.
Avisos de `Fmax` no domínio do processador podem ser lidos como informação,
não como erro.
