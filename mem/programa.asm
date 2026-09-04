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
        # TODO

sort:
        # TODO

main:
        # TODO: montar um vetor de teste na memória, carregar $a0/$a1,
        #       chamar sort e parar.
