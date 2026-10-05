#!/usr/bin/env bash
# Compila e executa o testbench de cada modulo de rtl/ que tenha um par em tb/.
# Rodar a partir da raiz do repositorio:   ./tools/roda_testes.sh
set -uo pipefail

mkdir -p build
total=0; falhas=0

for modulo in rtl/*.v; do
    nome=$(basename "$modulo" .v)
    tb="tb/${nome}_tb.v"
    [ -f "$tb" ] || { echo "  -- $nome: sem testbench, pulando"; continue; }

    total=$((total + 1))
    if ! iverilog -g2012 -o "build/sim_$nome" "$modulo" "$tb" 2>"build/$nome.log"; then
        echo "  FALHOU (compilacao)  $nome  -> build/$nome.log"
        falhas=$((falhas + 1)); continue
    fi

    saida=$("./build/sim_$nome" 2>&1)
    if echo "$saida" | grep -q "todos os casos passaram"; then
        casos=$(echo "$saida" | grep -c '^  ok')
        printf '  ok      %-24s %s casos\n' "$nome" "$casos"
    else
        echo "  FALHOU  $nome"
        echo "$saida" | sed 's/^/          /'
        falhas=$((falhas + 1))
    fi
done

echo
if [ "$falhas" -eq 0 ]; then
    echo "$total modulo(s), todos passaram"
else
    echo "$total modulo(s), $falhas com falha"
    exit 1
fi
