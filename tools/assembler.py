#!/usr/bin/env python3
"""
Montador MIPS -> memória de programa (.mif) para o projeto de Arquitetura.

    uso:  python3 tools/assembler.py mem/programa.asm mem/programa.mif

ESTE ARQUIVO ESTÁ PROPOSITALMENTE INCOMPLETO.

Ele é o item 5 do trabalho: é o montador que transforma o assembly na memória
de programa em binário. Implementá-lo é o que garante que a codificação foi
entendida — e evita errar bits à mão em dezenas de instruções.

As tabelas de consulta abaixo já estão preenchidas: são dados, não raciocínio.
O que falta são as funções de codificação, marcadas com TODO.

Referência dos formatos (Patterson & Hennessy, cap. 2):

    Formato R   op(6)  rs(5)  rt(5)  rd(5)  shamt(5)  funct(6)
    Formato I   op(6)  rs(5)  rt(5)  imediato(16)
    Formato J   op(6)  endereço(26)
"""

import sys
import re

# --- tabelas de consulta ----------------------------------------------------

REGS = {
    '$zero': 0, '$at': 1,
    '$v0': 2, '$v1': 3,
    '$a0': 4, '$a1': 5, '$a2': 6, '$a3': 7,
    '$t0': 8, '$t1': 9, '$t2': 10, '$t3': 11,
    '$t4': 12, '$t5': 13, '$t6': 14, '$t7': 15,
    '$s0': 16, '$s1': 17, '$s2': 18, '$s3': 19,
    '$s4': 20, '$s5': 21, '$s6': 22, '$s7': 23,
    '$t8': 24, '$t9': 25,
    '$k0': 26, '$k1': 27,
    '$gp': 28, '$sp': 29, '$fp': 30, '$ra': 31,
}

# formato R: op é sempre 0, o funct desempata
FUNCT = {
    'add': 0x20, 'addu': 0x21, 'sub': 0x22, 'subu': 0x23,
    'and': 0x24, 'or': 0x25, 'xor': 0x26, 'nor': 0x27,
    'slt': 0x2a, 'sltu': 0x2b,
    'sll': 0x00, 'srl': 0x02, 'sra': 0x03,
    'jr':  0x08,
}

# formato I e J: cada instrução tem seu próprio op
OPCODE = {
    'addi': 0x08, 'addiu': 0x09, 'andi': 0x0c, 'ori': 0x0d,
    'slti': 0x0a, 'lui': 0x0f,
    'lw': 0x23, 'sw': 0x2b,
    'beq': 0x04, 'bne': 0x05,
    'j': 0x02, 'jal': 0x03,
}


# --- codificação ------------------------------------------------------------

def campo(valor: int, bits: int) -> str:
    """Escreve `valor` em exatamente `bits` bits, completando com zeros.

    É a operação que todo o resto usa. Precisa tratar valor negativo em
    complemento de dois (o imediato de beq/addi pode ser negativo).
    """
    original = valor
    resultado: str = ""

    if valor < 0:
        valor = (1 << bits) + valor  # complemento de dois

    while valor > 0:
        resultado += str(valor % 2)
        valor //= 2

    resultado = resultado[::-1]  # inverter a string
    # Preencher com zeros à esquerda se necessário
    while len(resultado) < bits:
        resultado = "0" + resultado

    if len(resultado) > bits:
        raise ValueError(
            f"valor {original} nao cabe em {bits} bits "
            f"(precisaria de {len(resultado)})"
        )

    return resultado


def codifica_r(mnem: str, args: list) -> str:
    """Formato R -> string de 32 bits.

        op(6)  rs(5)  rt(5)  rd(5)  shamt(5)  funct(6)

    Tres formas de escrita caem no formato R, e cada uma preenche os campos
    de um jeito diferente. O op e sempre 0: e o funct que desempata.
    """
    if mnem == 'jr':                        # jr $rs
        rs, rt, rd, shamt = REGS[args[0]], 0, 0, 0
    elif mnem in ('sll', 'srl', 'sra'):     # sll $rd, $rt, shamt (nao tem rs)
        rs, rt, rd, shamt = 0, REGS[args[1]], REGS[args[0]], int(args[2])
    else:                                   # add $rd, $rs, $rt
        rs, rt, rd, shamt = REGS[args[1]], REGS[args[2]], REGS[args[0]], 0

    return (campo(0, 6) + campo(rs, 5) + campo(rt, 5)
            + campo(rd, 5) + campo(shamt, 5) + campo(FUNCT[mnem], 6))


def codifica_i(mnem: str, args: list, pc: int, rotulos: dict) -> str:
    """Formato I -> string de 32 bits.

        op(6)  rs(5)  rt(5)  imediato(16)

    Cuidado com a posicao dos registradores: no addi o args[0] e o destino
    (rt); no beq o args[0] e o rs. Mesma posicao no texto, campo diferente.

    O imediato do beq/bne e relativo ao PC e contado em INSTRUCOES, nao em
    bytes: `(alvo - (pc + 4)) // 4`. O `pc + 4` porque o hardware ja
    incrementou o PC quando o desvio e resolvido; o `// 4` porque contar
    instrucoes multiplica por 4 o alcance do campo.
    """
    if mnem in ('beq', 'bne'):              # beq $rs, $rt, rotulo
        rs, rt = REGS[args[0]], REGS[args[1]]
        imm = (rotulos[args[2]] - (pc + 4)) // 4
    elif mnem in ('lw', 'sw'):              # lw $rt, imm($rs)
        rt = REGS[args[0]]
        deslocamento, base = args[1].split('(')
        imm, rs = int(deslocamento), REGS[base.rstrip(')')]
    else:                                   # addi $rt, $rs, imm
        rt, rs, imm = REGS[args[0]], REGS[args[1]], int(args[2])

    if not -32768 <= imm <= 32767:      # 16 bits com sinal
        raise ValueError(f"{mnem}: imediato {imm} nao cabe em 16 bits com sinal")

    return campo(OPCODE[mnem], 6) + campo(rs, 5) + campo(rt, 5) + campo(imm, 16)


def codifica_j(mnem: str, args: list, rotulos: dict) -> str:
    """Formato J (j/jal) -> string de 32 bits.

        op(6)  endereco(26)

    O campo guarda o endereco alvo dividido por 4. Toda instrucao esta
    alinhada em 4 bytes, entao os dois bits de baixo sao sempre zero e
    guarda-los seria desperdicio — o hardware os recoloca no salto.
    """
    return campo(OPCODE[mnem], 6) + campo(rotulos[args[0]] // 4, 26)


# --- leitura do .asm --------------------------------------------------------

def limpa(linha: str) -> str:
    """Remove comentário (#) e espaço nas pontas."""
    return linha.split('#')[0].strip()


def primeira_passagem(linhas: list) -> dict:
    """Percorre o arquivo só para mapear rótulo -> endereço.

    Duas passagens são necessárias porque um `beq` pode saltar para um rótulo
    que aparece depois dele no arquivo. Na primeira passagem ainda não se sabe
    o endereço; na segunda, sim.
    """
    rotulos, endereco = {}, 0
    for linha in linhas:
        linha = limpa(linha)
        while ':' in linha:                 # "sort:" ou "sort: addi ..."
            rotulo, _, resto = linha.partition(':')
            rotulos[rotulo.strip()] = endereco
            linha = resto.strip()
        if linha:                           # sobrou instrucao nesta linha
            endereco += 4
    return rotulos


def monta(caminho_asm: str) -> list:
    """Retorna a lista de palavras de 32 bits do programa."""
    linhas = open(caminho_asm, encoding='utf-8').readlines()
    rotulos = primeira_passagem(linhas)

    palavras, pc = [], 0
    for linha in linhas:
        linha = limpa(linha)
        while ':' in linha:
            linha = linha.partition(':')[2].strip()
        if not linha:
            continue

        mnem, _, resto = linha.partition(' ')
        mnem = mnem.lower()
        args = [a.strip() for a in resto.split(',') if a.strip()]

        if mnem in FUNCT:                   # formato R (inclui jr)
            palavras.append(codifica_r(mnem, args))
        elif mnem in ('j', 'jal'):          # formato J
            palavras.append(codifica_j(mnem, args, rotulos))
        elif mnem in OPCODE:                # formato I
            palavras.append(codifica_i(mnem, args, pc, rotulos))
        else:
            raise ValueError(f"instrucao desconhecida: {mnem!r}")
        pc += 4

    return palavras


# --- saída .mif -------------------------------------------------------------

def escreve_mif(palavras: list, caminho: str, profundidade: int = 256) -> None:
    """Formato Memory Initialization File, lido pelo Quartus.

    Estrutura:

        DEPTH = 256;
        WIDTH = 32;
        ADDRESS_RADIX = HEX;
        DATA_RADIX = BIN;
        CONTENT BEGIN
            00 : 00000010000100010100000000100000;
            ...
            [0A..FF] : 00000000000000000000000000000000;
        END;
    """
    if len(palavras) > profundidade:
        raise ValueError(
            f"{len(palavras)} instrucoes nao cabem em memoria de "
            f"{profundidade} palavras"
        )

    with open(caminho, 'w', encoding='utf-8') as saida:
        saida.write(f"DEPTH = {profundidade};\n")
        saida.write("WIDTH = 32;\n")
        saida.write("ADDRESS_RADIX = HEX;\n")
        saida.write("DATA_RADIX = BIN;\n")
        saida.write("CONTENT BEGIN\n")
        for endereco, bits in enumerate(palavras):
            saida.write(f"    {endereco:02X} : {bits};\n")
        if len(palavras) < profundidade:    # resto da memoria zerado
            saida.write(f"    [{len(palavras):02X}..{profundidade - 1:02X}] : "
                        f"{'0' * 32};\n")
        saida.write("END;\n")


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__.strip().splitlines()[2])
        return 1
    palavras = monta(sys.argv[1])
    escreve_mif(palavras, sys.argv[2])
    print(f"{len(palavras)} instruções -> {sys.argv[2]}")
    return 0


if __name__ == '__main__':
    sys.exit(main())
