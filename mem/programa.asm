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
# ============================================================================

# --- TODO: tradução para assembly MIPS -------------------------------------
#
# Ordem sugerida de ataque:
#   1. swap  — é a função folha, não chama ninguém. Comece por ela.
#   2. corpo do laço interno
#   3. corpo do laço externo
#   4. prólogo/epílogo de sort (salvar registradores na pilha antes do jal)
#
# Cada linha traduzida deve poder ser justificada: qual construção do C ela
# implementa.

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
        # ESTADO EM 05/09/2026 — nao iniciado. Retomar por aqui.
        #
        # Assinatura: sort(v, n)   v em $a0, n em $a1   |   i em $s0, j em $s1
        #
        # Dois problemas ja identificados, ambos precisam ser resolvidos no prologo:
        #
        #   1. $ra morre.  main faz 'jal sort', gravando o retorno em $ra.
        #      Dentro do laco, 'jal swap' sobrescreve $ra. Sem salvar, o
        #      'jr $ra' final volta para dentro do proprio sort -> laco infinito.
        #      Solucao: pilha (addi $sp,$sp,-N / sw $ra,0($sp) ... lw / addi / jr).
        #
        #   2. n morre.  swap recebe argumentos em $a0 e $a1. Passar j em $a1
        #      destroi n, que o laco externo (i < n) precisa ate o fim.
        #      Solucao: guardar n antes — na pilha, ou num registrador que o
        #      swap comprovadamente nao toca (swap usa apenas $t0, $t1, $t2).
        #
        # Ordem de ataque sugerida:
        #   a) prologo (salvar $ra e n)
        #   b) laco externo:  for (i = 0; i < n; i += 1)
        #        precisa de: addi (i=0, i+=1), slt + beq/bne para a condicao
        #   c) laco interno:  for (j = i-1; j >= 0 && v[j] > v[j+1]; j -= 1)
        #        duas condicoes com && -> dois testes, saida do laco se qualquer
        #        uma falhar. Envolve lw de v[j] e v[j+1] e slt entre eles.
        #   d) corpo do laco interno: colocar v em $a0, j em $a1, jal swap
        #   e) epilogo (restaurar $ra e $sp, jr $ra)
        #
        # Instrucoes ainda nao estudadas e necessarias: addi (formato I com
        # imediato negativo), slt, beq, bne, j.

        # TODO: (a) prologo
        # TODO: (b) laco externo
        # TODO: (c) laco interno
        # TODO: (d) chamada de swap
        # TODO: (e) epilogo

main:
        # TODO: montar um vetor de teste na memória, carregar $a0/$a1,
        #       chamar sort e parar.
