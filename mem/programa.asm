# ============================================================================
#  Programa de teste do processador — ordenação por inserção
#  Fonte: enunciado do trabalho (sort + swap em C)
#
#  Convenção fixada pelo enunciado:
#      v  -> $a0        n  -> $a1        i  -> $s0        j  -> $s1
#
#  Original em C:
#
#    void sort (int v[], int n) {
#      int i, j;
#      for (i = 0; i < n; i += 1) {
#        for (j = i - 1; j >= 0 && v[j] > v[j + 1]; j -= 1) {
#          swap(v, j);
#        }
#      }
#    }
#
#    void swap (int v[], int k) {
#      int temp;
#      temp   = v[k];
#      v[k]   = v[k+1];
#      v[k+1] = temp;
#    }
#
#  Nota: o assembler.py deste repositorio ainda nao expande pseudo-instrucoes
#  (li, move, ble, etc.) — so reconhece as instrucoes reais que estao em
#  REGS/FUNCT/OPCODE. Por isso "i = 0" vira "addi $s0,$zero,0" e nao "li",
#  e copiar registrador vira "add $rd,$rs,$zero" e nao "move".
# ============================================================================

        # Ponto de entrada: o PC do processador comeca em 0, e o hardware
        # executa a PRIMEIRA instrucao fisica do arquivo, nao um rotulo.
        # Sem este salto, a execucao cairia dentro de swap() antes de main()
        # rodar (bug real, encontrado simulando o boot a partir do endereco 0).
        j    main

swap:
        # Corpo traduzido em 05/09/2026.
        # Argumentos: v em $a0, k em $a1  (convencao MIPS: 1o arg $a0, 2o arg $a1)
        # $a0 e $a1 nao sao alterados — sort ainda precisa deles apos a chamada.
        sll  $t1, $a1, 2      # $t1 = k * 4   (deslocar 2 a esquerda = multiplicar por 4)
        add  $t1, $a0, $t1    # $t1 = v + k*4 = endereco de v[k]
        lw   $t2, 0($t1)      # $t2 = v[k]      -> temp
        lw   $t0, 4($t1)      # $t0 = v[k+1]    (int ocupa 4 bytes)
        sw   $t0, 0($t1)      # v[k]   = $t0    -> v[k] = v[k+1]
        sw   $t2, 4($t1)      # v[k+1] = $t2    -> v[k+1] = temp
        jr   $ra              # volta para a instrucao seguinte ao jal que chamou

sort:
        # Traduzido em 08/09/2026.
        #
        # Assinatura: sort(v, n)   v em $a0, n em $a1   |   i em $s0, j em $s1
        #
        # Prologo resolve os dois problemas identificados antes:
        #   1. $ra morre com o 'jal swap' de dentro do laco -> salvar na pilha.
        #   2. n e v morrem porque swap usa $a0/$a1 -> copiar para $s2 (n) e
        #      $s3 (v), que o swap comprovadamente nao toca (usa so $t0-$t2).
        # $s0 (i) e $s1 (j) tambem precisam ser salvos, ja que pertencem ao
        # chamador (convencao MIPS: $s0-$s7 sao "saved registers").
        addi $sp, $sp, -20    # abre 5 palavras na pilha (ra, s0, s1, s2, s3)
        sw   $ra, 16($sp)
        sw   $s3, 12($sp)
        sw   $s2, 8($sp)
        sw   $s1, 4($sp)
        sw   $s0, 0($sp)

        add  $s3, $a0, $zero  # $s3 = v   (copia; add com $zero faz vez de 'move')
        add  $s2, $a1, $zero  # $s2 = n
        addi $s0, $zero, 0    # i = 0

for1tst:
        slt  $t0, $s0, $s2    # $t0 = (i < n) ? 1 : 0
        beq  $t0, $zero, exit1 # if (i >= n) sai do laco externo

        addi $s1, $s0, -1     # j = i - 1

for2tst:
        # condicao composta (j >= 0) && (v[j] > v[j+1]): duas checagens,
        # qualquer uma que falhar sai do laco interno (exit2)
        slti $t0, $s1, 0      # $t0 = (j < 0) ? 1 : 0
        bne  $t0, $zero, exit2 # if (j < 0) sai do laco interno

        sll  $t1, $s1, 2      # $t1 = j * 4
        add  $t2, $s3, $t1    # $t2 = v + j*4 = endereco de v[j]
        lw   $t3, 0($t2)      # $t3 = v[j]
        lw   $t4, 4($t2)      # $t4 = v[j+1]
        slt  $t0, $t4, $t3    # $t0 = (v[j+1] < v[j]) ? 1 : 0  <=> v[j] > v[j+1]
        beq  $t0, $zero, exit2 # if (v[j] <= v[j+1]) sai do laco interno

        add  $a0, $s3, $zero  # 1o parametro de swap: v
        add  $a1, $s1, $zero  # 2o parametro de swap: j
        jal  swap

        addi $s1, $s1, -1     # j -= 1
        j    for2tst

exit2:
        addi $s0, $s0, 1      # i += 1
        j    for1tst

exit1:
        # epilogo: restaura tudo na ordem inversa do prologo e retorna
        lw   $s0, 0($sp)
        lw   $s1, 4($sp)
        lw   $s2, 8($sp)
        lw   $s3, 12($sp)
        lw   $ra, 16($sp)
        addi $sp, $sp, 20

        jr   $ra

main:
        # Monta um vetor de teste v[] = {5, 3, 8, 1, 9, 2, 7, 4} na memoria de
        # dados a partir do endereco 0, chama sort(v, n) e para em laco infinito.
        #
        # ATENCAO: o endereco-base 0 assume que a memoria de dados comeca em 0
        # e e independente da memoria de instrucoes (esquema tipico de MIPS
        # academico com bancos separados). Confirmem isso com quem for
        # implementar o bloco de memoria de dados — se o endereçamento for
        # diferente, so muda o valor do primeiro addi abaixo.
        addi $sp, $zero, 1024
        addi $a0, $zero, 0    # $a0 = endereco-base do vetor

        addi $t0, $zero, 5
        sw   $t0, 0($a0)      # v[0] = 5
        addi $t0, $zero, 3
        sw   $t0, 4($a0)      # v[1] = 3
        addi $t0, $zero, 8
        sw   $t0, 8($a0)      # v[2] = 8
        addi $t0, $zero, 1
        sw   $t0, 12($a0)     # v[3] = 1
        addi $t0, $zero, 9
        sw   $t0, 16($a0)     # v[4] = 9
        addi $t0, $zero, 2
        sw   $t0, 20($a0)     # v[5] = 2
        addi $t0, $zero, 7
        sw   $t0, 24($a0)     # v[6] = 7
        addi $t0, $zero, 4
        sw   $t0, 28($a0)     # v[7] = 4

        addi $a1, $zero, 8    # n = 8

        jal  sort             # sort(v, n) -> v fica ordenado em memoria

end:
        j    end              # laco infinito — MIPS puro nao tem instrucao de halt
