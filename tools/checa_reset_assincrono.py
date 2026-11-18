#!/usr/bin/env python3
"""Confere que todo bloco com reset assincrono tem a forma que a sintese exige.

POR QUE ESTE SCRIPT EXISTE

O Icarus Verilog aceita isto:

    always @(posedge clk or posedge reset)
        if (reset || limpa) ...

e simula exatamente como a gente espera. O Quartus recusa:

    Error (10200): Verilog HDL Conditional Statement error: cannot match
    operand(s) in the condition to the corresponding edges in the enclosing
    event control of the always construct

A regra da sintese e que a primeira condicao de um bloco com reset assincrono
teste EXATAMENTE o sinal que esta na lista de sensibilidade, sozinho. Um
sinal sincrono junto na mesma condicao impede o reconhecimento do flip-flop.

Como o erro so aparece no Quartus, que roda em outra maquina, este teste
reproduz a regra aqui. Uso:

    python3 tools/checa_reset_assincrono.py rtl/*.v fpga/*.v
"""
import re
import sys

# always @(posedge a or posedge b)  ->  captura o segundo sinal (o reset)
CABECALHO = re.compile(
    r'always\s*@\s*\(\s*(?:pos|neg)edge\s+\w+\s+or\s+(?:pos|neg)edge\s+(\w+)\s*\)'
)
INICIO_IF = re.compile(r'^\s*if\s*\(')


def condicao_do_if(linha):
    """Devolve o texto entre os parenteses do `if`, ou None se a linha nao
    comeca com um `if`. Conta parenteses em vez de usar expressao regular,
    para nao se perder em condicoes como `if ((a && b) || c)`."""
    if not INICIO_IF.match(linha):
        return None
    inicio = linha.index('(')
    nivel = 0
    for k in range(inicio, len(linha)):
        if linha[k] == '(':
            nivel += 1
        elif linha[k] == ')':
            nivel -= 1
            if nivel == 0:
                return linha[inicio + 1:k].strip()
    return None            # parenteses abertos em varias linhas


def verifica(caminho):
    linhas = open(caminho, encoding='utf-8').read().splitlines()
    problemas = []

    for i, linha in enumerate(linhas):
        m = CABECALHO.search(linha)
        if not m:
            continue
        reset = m.group(1)

        # procura o primeiro `if` depois do cabecalho, pulando comentarios
        for j in range(i + 1, min(i + 20, len(linhas))):
            texto = linhas[j].strip()
            if not texto or texto.startswith('//'):
                continue
            cond = condicao_do_if(linhas[j])
            if cond is None:
                problemas.append(
                    (j + 1, f'bloco com reset assincrono `{reset}` nao comeca com um `if`')
                )
            elif cond != reset:
                problemas.append(
                    (j + 1,
                     f'condicao e `{cond}`, deveria ser apenas `{reset}`. '
                     f'Sinais sincronos vao num `else if` separado.')
                )
            break

    return problemas


def main(argv):
    if len(argv) < 2:
        print('uso: checa_reset_assincrono.py <arquivo.v> ...', file=sys.stderr)
        return 2

    total = 0
    for caminho in argv[1:]:
        for linha, msg in verifica(caminho):
            print(f'  {caminho}:{linha}: {msg}')
            total += 1

    if total:
        print(f'  {total} bloco(s) que o Quartus vai recusar')
        return 1

    print(f'  {len(argv) - 1} arquivo(s): resets assincronos na forma que a sintese aceita')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
