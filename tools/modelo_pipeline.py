#!/usr/bin/env python3
"""
Modelo de referencia do pipeline, em Python.

Executa o binario de mem/programa.mif instrucao por instrucao e conta quantos
ciclos o pipeline de 5 estagios levaria, somando:

    1 ciclo por instrucao executada
    4 ciclos de enchimento do pipeline
    2 ciclos por transferencia de controle TOMADA  (desvio resolvido no EX)
    1 ciclo por load-use                           (stall de um ciclo)

Serve para conferir o numero que o Verilog produz. Se o vetor sair ordenado
mas a contagem nao bater, algum perigo esta sendo tratado errado — e o
resultado certo foi coincidencia.

    python3 tools/modelo_pipeline.py
"""
import re
import collections

PALAVRAS = [int(m.group(1), 2)
            for l in open('mem/programa.mif')
            if (m := re.match(r'\s*[0-9A-F]+\s*:\s*([01]{32});', l))]


def s16(v): return v - (1 << 16) if v & 0x8000 else v
def s32(v):
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v & 0x80000000 else v


def executa():
    R = [0] * 32
    MEM = collections.defaultdict(int)
    pc = 0
    instrucoes = tomados = stalls = 0
    anterior = None          # (destino, eh_load) da instrucao anterior
    # ciclo da ultima escrita arquitetural (registrador != 0, ou memoria).
    # E esse o ponto em que o testbench do Verilog para de contar.
    ultima_escrita = 0

    while instrucoes < 100000:
        w = PALAVRAS[pc // 4]
        op = w >> 26
        rs, rt, rd = (w >> 21) & 31, (w >> 16) & 31, (w >> 11) & 31
        sh, fn = (w >> 6) & 31, w & 63
        imm, alvo = s16(w & 0xFFFF), (w & 0x3FFFFFF) * 4
        nxt, tomou = pc + 4, False

        # quais registradores esta instrucao le
        if op == 0:
            le = [] if fn == 0x08 else ([rt] if fn == 0x00 else [rs, rt])
            if fn == 0x08: le = [rs]
        elif op in (0x04, 0x05, 0x2b): le = [rs, rt]
        elif op in (0x08, 0x0a, 0x23): le = [rs]
        else:                          le = []

        # load-use: a instrucao anterior era um lw cujo destino eu leio
        if anterior and anterior[1] and anterior[0] != 0 and anterior[0] in le:
            stalls += 1

        if op == 0:
            if   fn == 0x20: R[rd] = s32(R[rs] + R[rt]); destino, load = rd, False
            elif fn == 0x2a: R[rd] = 1 if R[rs] < R[rt] else 0; destino, load = rd, False
            elif fn == 0x00: R[rd] = s32(R[rt] << sh); destino, load = rd, False
            elif fn == 0x08: nxt, tomou = R[rs], True; destino, load = 0, False
            else:            destino, load = 0, False
        elif op == 0x08: R[rt] = s32(R[rs] + imm); destino, load = rt, False
        elif op == 0x0a: R[rt] = 1 if R[rs] < imm else 0; destino, load = rt, False
        elif op == 0x23:
            e = R[rs] + imm; R[rt] = MEM[e]; destino, load = rt, True
        elif op == 0x2b:
            e = R[rs] + imm; MEM[e] = R[rt]; destino, load = 0, False
        elif op == 0x04:
            if R[rs] == R[rt]: nxt, tomou = pc + 4 + imm * 4, True
            destino, load = 0, False
        elif op == 0x05:
            if R[rs] != R[rt]: nxt, tomou = pc + 4 + imm * 4, True
            destino, load = 0, False
        elif op == 0x02:
            if alvo == pc:
                instrucoes += 1
                tomados += 1
                break
            nxt, tomou = alvo, True; destino, load = 0, False
        elif op == 0x03:
            R[31] = pc + 4; nxt, tomou = alvo, True; destino, load = 31, False
        else:
            destino, load = 0, False

        R[0] = 0
        instrucoes += 1
        if tomou: tomados += 1

        # posicao, em ciclos, desta instrucao
        ciclo_atual = instrucoes + 4 + 2 * tomados + stalls
        escreve_reg = destino != 0
        escreve_mem = (op == 0x2b)
        if escreve_reg or escreve_mem:
            ultima_escrita = ciclo_atual

        anterior = (destino, load)
        pc = nxt

    return (instrucoes, tomados, stalls, ultima_escrita,
            [MEM[i] for i in range(0, 32, 4)])


if __name__ == '__main__':
    n, tomados, stalls, ultima_escrita, vetor = executa()
    enchimento = 4
    total = n + enchimento + 2 * tomados + stalls

    print()
    print("  modelo de referencia do pipeline de 5 estagios")
    print("  " + "-" * 52)
    print(f"  instrucoes executadas                      {n:>6}")
    print(f"  enchimento do pipeline                     {enchimento:>6}")
    print(f"  transferencias de controle tomadas  x2     {2*tomados:>6}   ({tomados} desvios)")
    print(f"  stalls de load-use                  x1     {stalls:>6}")
    print("  " + "-" * 52)
    print(f"  ciclos previstos                           {total:>6}")
    print()
    print(f"  vetor final: {vetor}")
    print(f"  ordenado: {'sim' if vetor == sorted(vetor) else 'NAO'}")
    print()
    print(f"  ciclo da ultima escrita arquitetural       {ultima_escrita:>6}"
          f"   <- e o que o testbench mede")
    print()
    print(f"  monociclo: {n + 2} ciclos   |   pipeline: {total} ciclos"
          f"   |   razao: {total/(n+2):.3f}")
    print()
