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
    raise NotImplementedError("TODO: implementar")


def codifica_r(mnem: str, args: list) -> int:
    """add/sub/and/or/slt/... -> 32 bits.

    Cuidado: a ordem no assembly é  rd, rs, rt.
    A ordem nos campos é           rs, rt, rd.
    As instruções de shift (sll/srl) fogem do padrão: usam shamt e não rs.
    """
    raise NotImplementedError("TODO: implementar")


def codifica_i(mnem: str, args: list, pc: int, rotulos: dict) -> int:
    """addi/lw/sw/beq/... -> 32 bits.

    lw/sw têm sintaxe própria:  lw $t0, 8($a0)
    beq/bne têm imediato relativo ao PC, não absoluto: o valor gravado é
    quantas *instruções* pular a partir da próxima. Descobrir a fórmula exata
    é parte do trabalho.
    """
    raise NotImplementedError("TODO: implementar")


def codifica_j(mnem: str, args: list, rotulos: dict) -> int:
    """j/jal -> 32 bits."""
    raise NotImplementedError("TODO: implementar")


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
    raise NotImplementedError("TODO: implementar")


def monta(caminho_asm: str) -> list:
    """Retorna a lista de palavras de 32 bits do programa."""
    raise NotImplementedError("TODO: implementar")


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
    raise NotImplementedError("TODO: implementar")


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
