# ============================================================================
#  Makefile — compila e executa os testbenches do processador MIPS
#
#    make            roda todos os testbenches e imprime um resumo
#    make V=1        o mesmo, mostrando a saida completa de cada testbench
#    make verbose    atalho para `make V=1`
#    make run-alu    roda apenas o testbench do modulo `alu`
#    make run-alu V=1   a saida completa de um modulo so
#    make lint       so confere a sintaxe de todos os modulos de rtl/
#    make mif        regera mem/programa.mif e mem/programa.txt do assembly
#    make clean      apaga build/
#
#  Descobre os modulos sozinho: para cada rtl/<nome>.v procura o testbench em
#  tb/<nome>_tb.v ou tb/tb_<nome>_scenarios.v (as duas convencoes em uso na
#  equipe). Modulo sem testbench e listado como pendente, nao como falha.
#
#  Requer Icarus Verilog:  brew install icarus-verilog  (macOS)
#                          apt install iverilog         (Linux)
# ============================================================================

IVERILOG := iverilog
FLAGS    := -g2012
BUILD    := build
STATUS   := $(BUILD)/status

RTL      := $(wildcard rtl/*.v)
MODULOS  := $(sort $(basename $(notdir $(RTL))))

# caminho do testbench de um modulo, nas duas convencoes de nome
tb_de = $(firstword $(wildcard tb/$(1)_tb.v tb/tb_$(1)_scenarios.v))

COM_TB = $(foreach m,$(MODULOS),$(if $(call tb_de,$(m)),$(m)))
SEM_TB = $(foreach m,$(MODULOS),$(if $(call tb_de,$(m)),,$(m)))

.PHONY: all test verbose lint mif clean
.NOTPARALLEL:

all: test

verbose:
	@$(MAKE) --no-print-directory test V=1

test:
	@rm -rf $(STATUS) && mkdir -p $(STATUS)
	@$(MAKE) --no-print-directory $(addprefix run-,$(COM_TB))
	@echo ""
	@echo "---------------------------------------------------------------"
	@casos=$$(cat $(STATUS)/*.casos 2>/dev/null | awk '{s+=$$1} END {print s+0}'); \
	 falhas=$$(ls $(STATUS)/*.falha 2>/dev/null | wc -l | tr -d ' '); \
	 sem=$$(echo "$(SEM_TB)" | wc -w | tr -d ' '); \
	 echo "$(words $(COM_TB)) modulo(s) com testbench, $$casos caso(s)"; \
	 if [ "$$sem" -gt 0 ]; then echo "$$sem modulo(s) ainda sem testbench: $(SEM_TB)"; fi; \
	 if [ "$$falhas" -gt 0 ]; then echo "$$falhas modulo(s) COM FALHA"; exit 1; \
	 else echo "todos passaram"; fi

run-%: force
	@mkdir -p $(BUILD) $(STATUS)
	@tb="$(call tb_de,$*)"; \
	 if [ -z "$$tb" ]; then printf '  %-10s %s\n' "pendente" "$*  (sem testbench)"; exit 0; fi; \
	 if ! $(IVERILOG) $(FLAGS) -o $(BUILD)/sim_$* rtl/$*.v $$tb 2>$(BUILD)/$*.log; then \
	    printf '  %-10s %-24s %s\n' "COMPILA!" "$*" "veja $(BUILD)/$*.log"; \
	    touch $(STATUS)/$*.falha; exit 0; fi; \
	 saida=$$(./$(BUILD)/sim_$* 2>&1); \
	 casos=$$(printf '%s\n' "$$saida" | grep -c '^  ok'); \
	 if printf '%s\n' "$$saida" | grep -q 'ERRO\|falharam'; then \
	    printf '  %-10s %-24s\n' "FALHOU" "$*"; \
	    printf '%s\n' "$$saida" | grep 'ERRO' | sed 's/^/             /'; \
	    touch $(STATUS)/$*.falha; \
	 elif printf '%s\n' "$$saida" | grep -q 'RESULTADO:'; then \
	    printf '  %-10s %-24s %s casos\n' "ok" "$*" "$$casos"; \
	    echo $$casos > $(STATUS)/$*.casos; \
	 else \
	    printf '  %-10s %-24s %s\n' "ok*" "$*" "(testbench sem auto-verificacao)"; \
	    echo 0 > $(STATUS)/$*.casos; \
	 fi; \
	 if [ -n "$(V)" ]; then \
	    printf '%s\n' "$$saida" | grep -v '^$$' | sed 's/^/           | /'; \
	    echo ""; \
	 fi

lint:
	@erros=0; for m in $(MODULOS); do \
	   if $(IVERILOG) $(FLAGS) -t null rtl/$$m.v 2>$(BUILD)/lint.log; then \
	      printf '  %-10s %s\n' "ok" "$$m"; \
	   else printf '  %-10s %s\n' "ERRO" "$$m"; sed 's/^/             /' $(BUILD)/lint.log; \
	      erros=$$((erros+1)); fi; \
	 done; \
	 echo ""; [ $$erros -eq 0 ] && echo "$(words $(MODULOS)) modulo(s), sintaxe ok" || { echo "$$erros com erro"; exit 1; }

mif:
	@python3 tools/assembler.py mem/programa.asm mem/programa.mif

force:
	@:

clean:
	@rm -rf $(BUILD)
	@echo "build/ removido"
