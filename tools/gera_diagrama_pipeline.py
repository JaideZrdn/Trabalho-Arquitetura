#!/usr/bin/env python3
# Gerador do diagrama do caminho de dados do pipeline.
#   python3 tools/gera_diagrama_pipeline.py
#   rsvg-convert -f pdf caminho_dados_pipeline.svg -o docs/caminho_dados_pipeline.pdf
# Editar aqui e regerar e mais confiavel que mexer no SVG a mao.
"""Gera o diagrama do caminho de dados do MIPS em pipeline, em SVG."""

W, H = 2520, 1340
o = []            # elementos svg

def esc(t): return t.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')

def rect(x,y,w,h,cls='bloco',rx=0):
    o.append(f'<rect class="{cls}" x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}"/>')

def texto(x,y,t,cls='rot',anchor='middle'):
    o.append(f'<text class="{cls}" x="{x}" y="{y}" text-anchor="{anchor}">{esc(t)}</text>')

def arq(x,y,t):   # etiqueta de arquivo .v
    texto(x,y,t,'arq')

def linha(pts, cls='fio', seta=True):
    d = ' '.join(f'{"M" if i==0 else "L"}{x},{y}' for i,(x,y) in enumerate(pts))
    m = ' marker-end="url(#seta)"' if seta else ''
    o.append(f'<path class="{cls}" d="{d}"{m}/>')

def ponto(x,y,cls='no'):
    o.append(f'<circle class="{cls}" cx="{x}" cy="{y}" r="5"/>')

def mux(x,y,w,h,cls='bloco'):
    rect(x,y,w,h,cls,rx=w/2)
    for i,c in enumerate('Mux'):
        texto(x+w/2, y+h/2-14+i*15, c, 'muxl')

def trap(x,y,w,h,label,cls='bloco'):
    """simbolo de somador/ALU com entalhe a esquerda"""
    n = h*0.16
    o.append(f'<path class="{cls}" d="M{x},{y} L{x+w},{y+h*0.22} L{x+w},{y+h*0.78} '
             f'L{x},{y+h} L{x},{y+h/2+n} L{x+w*0.22},{y+h/2} L{x},{y+h/2-n} Z"/>')
    texto(x+w*0.62, y+h/2+6, label, 'rotb')

def elipse(cx,cy,rx,ry,label,cls='ctrl',sub=None,tcls=None):
    o.append(f'<ellipse class="{cls}" cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}"/>')
    t = tcls or ('ctrlt' if cls=='ctrl' else 'novot' if cls=='novo' else 'rotb')
    if sub:
        texto(cx,cy-4,label,t); texto(cx,cy+16,sub,t)
    else:
        texto(cx,cy+6,label,t)

# ---------------- fronteiras de estagio ----------------
REG = [(360,'IF/ID','reg_if_id.v'), (980,'ID/EX','reg_id_ex.v'),
       (1650,'EX/MEM','reg_ex_mem.v'), (2090,'MEM/WB','reg_mem_wb.v')]
ESTAGIOS = [(40,360,'IF — busca'), (360,980,'ID — decodifica e le'),
            (980,1650,'EX — calcula e decide'), (1650,2090,'MEM — memoria'),
            (2090,2480,'WB — escreve')]

TOPO, BASE = 120, 1230

for x0,x1,nome in ESTAGIOS:
    texto((x0+x1)/2, 78, nome, 'estagio')

for x,nome,arquivo in REG:
    rect(x, TOPO, 46, BASE-TOPO, 'pipereg')
    o.append(f'<text class="pipelabel" transform="translate({x+23},{(TOPO+BASE)/2}) rotate(-90)" '
             f'text-anchor="middle">{nome}</text>')
    arq(x+23, BASE+26, arquivo)

# ---------------- IF ----------------
mux(56, 595, 44, 120)                                     # mux do proximo PC
texto(60, 790, 'proximo PC', 'porta', 'start')
rect(138, 600, 50, 110); texto(163, 662, 'PC', 'rotb'); arq(150, 840, 'pc_com_habilita.v')
rect(228, 585, 120, 140); texto(288, 640, 'Memoria de', 'rot'); texto(288, 663, 'instrucoes', 'rot')
arq(288, 790, 'memoria_instrucoes.v')
trap(215, 390, 80, 110, 'Add'); texto(196, 475, '4', 'rot'); arq(255, 530, 'somador.v')

linha([(100,655),(138,655)])                              # mux -> PC
linha([(188,655),(228,655)])                              # PC -> mem instr
ponto(208,655)
linha([(208,655),(208,445),(215,445)], seta=True)         # PC -> Add
linha([(295,445),(330,445),(330,560),(345,560)])          # PC+4 -> IF/ID
ponto(330,445)
linha([(348,655),(360,655)])                              # instr -> IF/ID

# ---------------- ID ----------------
elipse(560, 250, 86, 54, 'Unidade de', 'ctrl', 'controle'); arq(560, 330, 'control_unit.v')
rect(560, 560, 200, 220); texto(660, 600, 'Banco de', 'rot'); texto(660, 623, 'registradores', 'rot')
texto(600, 665, 'le 1', 'porta', 'start'); texto(600, 700, 'le 2', 'porta', 'start')
texto(600, 735, 'escreve', 'porta', 'start')
arq(660, 805, 'banco_registradores.v')
elipse(700, 930, 74, 46, 'Extensor', 'bloco2', 'de sinal', 'rotb2'); arq(700, 1005, 'extensor_sinal.v')

linha([(406,655),(560,655)])                       # instr -> banco
ponto(430,655)
linha([(430,655),(430,250),(474,250)])             # instr -> controle
ponto(460,655)
linha([(460,655),(460,930),(626,930)])             # instr -> extensor
linha([(760,620),(980,620)])                       # dado 1 -> ID/EX
linha([(760,690),(980,690)])                       # dado 2 -> ID/EX
linha([(774,930),(900,930),(900,760),(945,760)])   # imediato -> ID/EX
linha([(646,250),(945,250)])                       # controle -> ID/EX
linha([(406,560),(500,560),(500,215),(945,215)])   # pc+4 -> ID/EX

# ---------------- EX ----------------
mux(1050, 560, 44, 110)   # forward A
mux(1050, 700, 44, 110)   # forward B
arq(1090, 905, 'mux_forwarding.v')
mux(1180, 575, 40, 90)    # alu src a
arq(1200, 690, 'mux_alu_a.v')
mux(1180, 715, 40, 90)
arq(1200, 830, 'mux_alu_b.v')
trap(1270, 560, 130, 230, 'ALU'); arq(1335, 815, 'alu.v')
elipse(1300, 950, 76, 44, 'Controle', 'ctrl', 'da ALU'); arq(1300, 1022, 'alu_control.v')

elipse(1130, 1136, 86, 48, 'Unidade de', 'novo', 'forwarding')
arq(1130, 1230, 'unidade_forwarding.v')

trap(1300, 250, 100, 120, 'Add'); arq(1360, 420, 'somador.v')
elipse(1180, 330, 56, 36, 'x4', 'bloco2', None, 'rotb2'); arq(1150, 410, 'shift_left_2.v')
rect(1420, 150, 150, 90); texto(1495, 185, 'Endereco', 'rot'); texto(1495, 208, 'do salto', 'rot')
arq(1495, 128, 'jump_address_calc.v')
mux(1180, 440, 40, 90); arq(1200, 548, 'mux_write_reg.v')

elipse(1540, 1062, 80, 46, 'Controle', 'novo', 'de flush')
arq(1620, 980, 'controle_flush.v')

linha([(1026,600),(1050,600)])      # id/ex -> fwdA
linha([(1026,740),(1050,740)])      # id/ex -> fwdB
linha([(1094,615),(1180,615)])
linha([(1094,755),(1180,755)])
linha([(1220,620),(1270,620)])
linha([(1220,760),(1270,740)])
linha([(1400,675),(1650,675)])      # resultado -> EX/MEM
ponto(1470,675)
linha([(1220,485),(1650,485)])      # destino -> EX/MEM
linha([(1094,775),(1120,775),(1120,880),(1600,880),(1600,730),(1650,730)])  # dado2 -> EX/MEM

linha([(1026,300),(1180,330)], seta=True)       # imediato -> x4
linha([(1236,330),(1300,310)])                  # x4 -> Add
linha([(1026,215),(1270,215),(1270,278)])       # pc+4 -> Add
linha([(1400,310),(1600,310)])                  # destino do desvio ->
linha([(1026,165),(1420,165)], seta=True)       # target -> calculo do salto
linha([(1570,195),(1600,195)])                  # destino do salto ->
ponto(1600,310); ponto(1600,195)

# zero -> controle de flush
linha([(1400,730),(1415,730),(1415,1050),(1620,1050)], 'fioctrl')
linha([(1026,1050),(1460,1050)], 'fioctrl')     # bandeiras -> flush
linha([(1600,310),(1600,1230),(26,1230),(26,625),(56,625)], 'fiolaranja')  # destino -> mux PC
linha([(1540,1108),(1540,1165),(1600,1165)], 'fiolaranja')
texto(1500, 1200, 'desvio tomado  ->  seleciona o proximo PC', 'laranjat', 'end')

# ---------------- MEM ----------------
rect(1730, 560, 170, 210); texto(1815, 612, 'Memoria', 'rot'); texto(1815, 635, 'de dados', 'rot')
arq(1815, 795, 'memoria_dados.v')
linha([(1696,660),(1730,660)])
linha([(1696,730),(1715,730),(1715,745),(1730,745)])
linha([(1900,640),(2090,640)])        # dado lido -> MEM/WB
linha([(1696,620),(1718,620),(1718,560),(2000,560),(2000,600),(2090,600)])  # alu -> MEM/WB

# ---------------- WB ----------------
mux(2200, 580, 46, 130); arq(2223, 730, 'mux_write_data.v')
linha([(2136,620),(2200,620)])
linha([(2246,645),(2380,645),(2380,1300),(520,1300),(520,760),(560,760)], 'fio')
texto(1200, 1292, 'valor gravado volta ao banco de registradores', 'rot2')

# forwarding: entradas
linha([(1216,1136),(1470,1136),(1470,700)], 'fiotrac', seta=True)
linha([(1044,1136),(1000,1136),(1000,840)], 'fiotrac', seta=True)
linha([(1130,1088),(1130,1000)], 'fiotrac', seta=True)

# ---------------- deteccao de hazard ----------------
elipse(800, 160, 88, 48, 'Deteccao de', 'novo', 'hazard')
arq(800, 108, 'deteccao_hazard.v')
linha([(888,160),(1005,160)], 'fiotrac')
linha([(712,140),(336,140),(336,600)], 'fiolaranja')   # segura IF/ID
linha([(336,300),(78,300),(78,595)], 'fiolaranja')     # segura o PC
texto(200, 288, 'segura o PC e o IF/ID', 'laranjat')


# ---------------- legenda ----------------
LX, LY = 1760, 900
rect(LX, LY, 540, 230, 'bloco')
texto(LX+24, LY+34, 'Legenda', 'legtb', 'start')
o.append(f'<rect class="bloco" x="{LX+24}" y="{LY+56}" width="34" height="22"/>')
texto(LX+72, LY+74, 'bloco que ja existia no monociclo', 'legt', 'start')
o.append(f'<rect class="novo" x="{LX+24}" y="{LY+96}" width="34" height="22"/>')
texto(LX+72, LY+114, 'bloco acrescentado pelo pipeline', 'legt', 'start')
o.append(f'<rect class="pipereg" x="{LX+24}" y="{LY+136}" width="34" height="22"/>')
texto(LX+72, LY+154, 'registrador de estagio', 'legt', 'start')
o.append(f'<path class="fiotrac" d="M{LX+24},{LY+187} L{LX+58},{LY+187}"/>')
texto(LX+72, LY+193, 'sinal de forwarding / hazard', 'legt', 'start')
o.append(f'<path class="fioctrl" d="M{LX+300},{LY+187} L{LX+334},{LY+187}"/>')
texto(LX+348, LY+193, 'sinal de controle', 'legt', 'start')
texto(LX+348, LY+74, 'arquivo.v   modulo Verilog', 'arq', 'start')

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<defs>
  <marker id="seta" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
    <path d="M0,1 L9,5 L0,9 z" fill="#222"/>
  </marker>
</defs>
<style>
  text {{ font-family: Helvetica, Arial, sans-serif; }}
  .bloco  {{ fill:#fff; stroke:#222; stroke-width:2.4; }}
  .bloco2 {{ fill:#fff; stroke:#222; stroke-width:2.4; }}
  .ctrl   {{ fill:#fff; stroke:#1c7ed6; stroke-width:2.4; }}
  .novo   {{ fill:#ffe8cc; stroke:#d9480f; stroke-width:3.4; }}
  .pipereg{{ fill:#fff4e6; stroke:#d9480f; stroke-width:3.4; }}
  .fio    {{ fill:none; stroke:#222; stroke-width:2.2; }}
  .fioctrl{{ fill:none; stroke:#1c7ed6; stroke-width:2.2; }}
  .fiolaranja {{ fill:none; stroke:#d9480f; stroke-width:3; }}
  .fiotrac {{ fill:none; stroke:#d9480f; stroke-width:2.2; stroke-dasharray:7 5; }}
  .no     {{ fill:#222; }}
  .rot    {{ font-size:19px; fill:#111; }}
  .rotb   {{ font-size:21px; font-weight:bold; fill:#111; }}
  .porta  {{ font-size:15px; fill:#444; }}
  .muxl   {{ font-size:13px; font-weight:bold; fill:#111; }}
  .ctrlt  {{ font-size:17px; font-weight:bold; fill:#1c7ed6; }}
  .novo + text, .ctrlt {{ }}
  .arq    {{ font-size:14px; font-family:Menlo,monospace; fill:#777; }}
  .estagio{{ font-size:23px; font-weight:bold; fill:#555; }}
  .pipelabel {{ font-size:17px; font-weight:bold; fill:#d9480f; }}
  .novot  {{ font-size:17px; font-weight:bold; fill:#d9480f; }}
  .rotb2  {{ font-size:19px; font-weight:bold; fill:#111; }}
  .legt   {{ font-size:16px; fill:#333; }}
  .legtb  {{ font-size:17px; font-weight:bold; fill:#111; }}
  .laranjat {{ font-size:15px; font-weight:bold; fill:#d9480f; }}
  .rot2   {{ font-size:16px; fill:#555; }}
</style>
<rect width="100%" height="100%" fill="#fff"/>
{chr(10).join(o)}
</svg>'''
open('pipeline.svg','w').write(svg)
print('pipeline.svg gerado')
