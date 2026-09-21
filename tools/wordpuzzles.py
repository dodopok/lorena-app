"""Gera e valida os puzzles do Palavra do dia.

Cada puzzle define uma roda de letras e as palavras da grade. O empacotador
cruza as palavras de verdade (mesma letra no cruzamento, sem palavras
paralelas coladas) e falha alto se algo não fecha — o contrário de escrever
coordenadas à mão e torcer.

    python3 tools/wordpuzzles.py > Lume/Features/Words/WordPuzzleCatalog.swift
"""
import sys
from collections import Counter

# (id, roda, palavras da grade, palavras bônus)
PUZZLES = [
    ("amores","AMORES",["AMORES","MESA","ROSA","REMO","SOMA","MAR"],["MORA","SOME","REMA","MAS","AMO"]),
    ("calor","CALOR",["CALOR","CLARO","ARCO","RALO","COR","LAR"],["CARO","ORA","CAL","ROL"]),
    ("flores","FLORES",["FLORES","FLOR","SELO","ELOS","FOLE","SOL"],["SER","LER","FOR","ROL"]),
    ("caminho","CAMINHO",["CAMINHO","MINHA","NICHO","CHAO","MAO"],["MACHO","MIA","CHA","NAO"]),
    ("vidas","VIDAS",["VIDAS","VIDA","DIAS","VISA","SAI","DIA"],["IDAS","VAI","DAS"]),
    ("livros","LIVROS",["LIVROS","LIVRO","SILO","RIO","SOL","VIR"],["VIRO","VIL","ROL"]),
    ("praia","PRAIA",["PRAIA","PARA","RAIA","ARIA","PAI","IRA"],["RIA","PIA","PAR"]),
    ("jardim","JARDIM",["JARDIM","MIRA","DIA","RIM","DAR"],["MIA","RIA","MAR","IRA"]),
    ("beijos","BEIJOS",["BEIJOS","BEIJO","SEI","BOI","BIS"],["EIS","SOB"]),
    ("caneta","CANETA",["CANETA","CANTA","CENA","NATA","ANTE","ATA"],["CATA","ANTA","ACNE"]),
    ("carinho","CARINHO",["CARINHO","CHORA","NICHO","ARCO","RIO"],["CARO","RICO","CHAO","HORA","CAO","IRA"]),
    ("verdade","VERDADE",["VERDADE","VERDE","REDE","ARDE","VER"],["DEVE","ERA","DAR"]),
    ("janela","JANELA",["JANELA","ANEL","ELA","ALA"],["NELA"]),
    ("musica","MUSICA",["MUSICA","SUMIA","CIMA","CAIS","SAI"],["MIA","SUA","USA"]),
    ("domingo","DOMINGO",["DOMINGO","GNOMO","MODO","INDO","DOM"],["ODIO","DIGO","GOMO"]),
    ("abraco","ABRACO",["ABRACO","BARCO","CABRA","BOCA","ARCO"],["CARO","CAO","BAR","ORA"]),
    ("caderno","CADERNO",["CADERNO","ORDENA","RENDA","CEDRO","DONA"],["CEDO","RODA","CORDA","ONDA"]),
    ("estrela","ESTRELA",["ESTRELA","LESTE","RESTA","TELA","SETA"],["ARTE","REAL","SAL","LAR","ELA"]),
    ("floresta","FLORESTA",["FLORESTA","FLORES","SOLTAR","RESTA","TELA"],["FLOR","SAL","ARTE","ROSA","FORTE"]),
    ("canela","CANELA",["CANELA","LANCE","CENA","ANEL","ALCA"],["ELA","ALA","NELA","CAL"]),
    ("passeio","PASSEIO",["PASSEIO","PASSE","PISO","PAIS","SAPO"],["SEI","PIA","SAI"]),
    ("pipoca","PIPOCA",["PIPOCA","COPA","PICO","PIA","CAI"],["PAI","OCA"]),
    ("noticia","NOTICIA",["NOTICIA","TONICA","CONTA","CANTO","NOTA"],["TIO","CAI","ATO"]),
    ("tarde","TARDE",["TARDE","ARDE","DAR","TER","ERA"],["ATE"]),
    ("bolacha","BOLACHA",["BOLACHA","CALHA","ACHO","CABO","BOLA"],["CHA","OCA","BOCA","ALA"]),
    ("feijoada","FEIJOADA",["FEIJOADA","ODEIA","JOIA","FADA","DIA"],["FEIA"]),
    ("saudade","SAUDADE",["SAUDADE","USADA","SAUDE","SEDA","DAS"],["SUA","USA"]),
    ("marido","MARIDO",["MARIDO","DORMIA","RADIO","MIRA","DOMA"],["DIA","RIM","MAR","DAR","IRA","AMO"]),
    ("cadeira","CADEIRA",["CADEIRA","CEDIA","DICA","CARA","IRA"],["DIA","CAI","ERA","ARDE"]),
    ("relogio","RELOGIO",["RELOGIO","ELOGIO","GIRO","LOGO","OLEO"],["RIO","ROL","LER","EGO"]),
]


def formable(word, letters):
    have, need = Counter(letters), Counter(word)
    return all(have[ch] >= n for ch, n in need.items())


def try_place(grid, word, r, c, dr, dc):
    """Nº de cruzamentos se a colocação for legal, senão None."""
    crossings = 0
    if (r - dr, c - dc) in grid or (r + dr * len(word), c + dc * len(word)) in grid:
        return None
    for i, ch in enumerate(word):
        rr, cc = r + dr * i, c + dc * i
        cur = grid.get((rr, cc))
        if cur is not None:
            if cur != ch:
                return None          # cruzamento com letra diferente: rejeita
            crossings += 1
        else:
            pr, pc = dc, dr          # vizinhos perpendiculares precisam estar vazios
            if (rr + pr, cc + pc) in grid or (rr - pr, cc - pc) in grid:
                return None
    return crossings


def pack(words, spilled):
    grid, placed = {}, []
    for i, ch in enumerate(words[0]):
        grid[(0, i)] = ch
    placed.append({"word": words[0], "row": 0, "col": 0, "vertical": False})

    for word in words[1:]:
        best = None
        for (gr, gc), gch in list(grid.items()):
            for i, ch in enumerate(word):
                if ch != gch:
                    continue
                for dr, dc in ((1, 0), (0, 1)):
                    r, c = gr - dr * i, gc - dc * i
                    cross = try_place(grid, word, r, c, dr, dc)
                    if cross is None or cross < 1:
                        continue
                    cells = [(r + dr * k, c + dc * k) for k in range(len(word))]
                    rows = [p[0] for p in list(grid) + cells]
                    cols = [p[1] for p in list(grid) + cells]
                    span = (max(rows) - min(rows) + 1) * (max(cols) - min(cols) + 1)
                    if best is None or (span, -cross) < best[0]:
                        best = ((span, -cross), r, c, dr, dc, cells)
        if best is None:
            spilled.append(word)
            continue
        _, r, c, dr, dc, cells = best
        for k, ch in enumerate(word):
            grid[cells[k]] = ch
        placed.append({"word": word, "row": r, "col": c, "vertical": bool(dr)})
    return grid, placed


def build():
    out, problems = [], []
    for pid, letters, words, bonus in PUZZLES:
        for w in words + bonus:
            if not formable(w, letters):
                problems.append(f"{pid}: '{w}' não sai das letras {letters}")
        spilled = []
        grid, placed = pack(sorted(set(words), key=len, reverse=True), spilled)
        bonus = sorted(set(bonus) | set(spilled), key=lambda w: (-len(w), w))
        if len(placed) < 4:
            problems.append(f"{pid}: só {len(placed)} palavras na grade")
        minr = min(r for r, _ in grid)
        minc = min(c for _, c in grid)
        for p in placed:
            p["row"] -= minr
            p["col"] -= minc
        out.append({
            "id": pid,
            "letters": list(letters),
            "w": max(c for _, c in grid) - minc + 1,
            "h": max(r for r, _ in grid) - minr + 1,
            "words": placed,
            "bonus": bonus,
            "spilled": spilled,
        })
    return out, problems


def swift(puzzles):
    lines = [
        "// Gerado por tools/wordpuzzles.py — não edite à mão.",
        "// As coordenadas saem de um empacotador que valida cada cruzamento;",
        "// para adicionar dias, edite o script e rode-o de novo.",
        "",
        "enum WordPuzzleCatalog {",
        "    static let puzzles: [WordPuzzle] = [",
    ]
    for p in puzzles:
        letters = ", ".join('"%s"' % c for c in p["letters"])
        lines.append('        WordPuzzle(')
        lines.append('            id: "%s",' % p["id"])
        lines.append('            letters: [%s],' % letters)
        lines.append('            width: %d, height: %d,' % (p["w"], p["h"]))
        lines.append('            entries: [')
        for e in p["words"]:
            lines.append('                WordPuzzle.Entry(word: "%s", row: %d, column: %d, isVertical: %s),'
                         % (e["word"], e["row"], e["col"], "true" if e["vertical"] else "false"))
        lines.append('            ],')
        lines.append('            bonus: [%s]' % ", ".join('"%s"' % b for b in p["bonus"]))
        lines.append('        ),')
    lines += ["    ]", "}", ""]
    return "\n".join(lines)


puzzles, problems = build()
if problems:
    sys.stderr.write("PROBLEMAS:\n  " + "\n  ".join(problems) + "\n")
    sys.exit(1)
for p in puzzles:
    sys.stderr.write("%-9s %dx%d  %d palavras, %d bônus%s\n" % (
        p["id"], p["w"], p["h"], len(p["words"]), len(p["bonus"]),
        "  (sobrou: %s)" % ",".join(p["spilled"]) if p["spilled"] else ""))
sys.stdout.write(swift(puzzles))
