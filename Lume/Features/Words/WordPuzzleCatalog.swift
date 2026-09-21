// Gerado por tools/wordpuzzles.py — não edite à mão.
// As coordenadas saem de um empacotador que valida cada cruzamento;
// para adicionar dias, edite o script e rode-o de novo.

enum WordPuzzleCatalog {
    static let puzzles: [WordPuzzle] = [
        WordPuzzle(
            id: "amores",
            letters: ["A", "M", "O", "R", "E", "S"],
            width: 8, height: 6,
            entries: [
                WordPuzzle.Entry(word: "AMORES", row: 3, column: 2, isVertical: false),
                WordPuzzle.Entry(word: "MESA", row: 0, column: 2, isVertical: true),
                WordPuzzle.Entry(word: "SOMA", row: 0, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "REMO", row: 2, column: 6, isVertical: true),
                WordPuzzle.Entry(word: "ROSA", row: 2, column: 4, isVertical: true),
            ],
            bonus: ["MORA", "REMA", "SOME", "AMO", "MAR", "MAS"]
        ),
        WordPuzzle(
            id: "calor",
            letters: ["C", "A", "L", "O", "R"],
            width: 5, height: 8,
            entries: [
                WordPuzzle.Entry(word: "CLARO", row: 3, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "CALOR", row: 3, column: 0, isVertical: true),
                WordPuzzle.Entry(word: "ARCO", row: 3, column: 2, isVertical: true),
                WordPuzzle.Entry(word: "RALO", row: 0, column: 4, isVertical: true),
                WordPuzzle.Entry(word: "COR", row: 5, column: 2, isVertical: false),
                WordPuzzle.Entry(word: "LAR", row: 0, column: 2, isVertical: false),
            ],
            bonus: ["CARO", "CAL", "ORA", "ROL"]
        ),
        WordPuzzle(
            id: "flores",
            letters: ["F", "L", "O", "R", "E", "S"],
            width: 8, height: 6,
            entries: [
                WordPuzzle.Entry(word: "FLORES", row: 2, column: 1, isVertical: false),
                WordPuzzle.Entry(word: "FOLE", row: 2, column: 1, isVertical: true),
                WordPuzzle.Entry(word: "FLOR", row: 4, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "SELO", row: 2, column: 6, isVertical: true),
                WordPuzzle.Entry(word: "ELOS", row: 5, column: 4, isVertical: false),
                WordPuzzle.Entry(word: "SOL", row: 0, column: 2, isVertical: true),
            ],
            bonus: ["FOR", "LER", "ROL", "SER"]
        ),
        WordPuzzle(
            id: "caminho",
            letters: ["C", "A", "M", "I", "N", "H", "O"],
            width: 10, height: 5,
            entries: [
                WordPuzzle.Entry(word: "CAMINHO", row: 4, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "MINHA", row: 0, column: 1, isVertical: true),
                WordPuzzle.Entry(word: "NICHO", row: 0, column: 6, isVertical: true),
                WordPuzzle.Entry(word: "CHAO", row: 2, column: 6, isVertical: false),
                WordPuzzle.Entry(word: "MAO", row: 0, column: 1, isVertical: false),
            ],
            bonus: ["MACHO", "CHA", "MIA", "NAO"]
        ),
        WordPuzzle(
            id: "vidas",
            letters: ["V", "I", "D", "A", "S"],
            width: 5, height: 6,
            entries: [
                WordPuzzle.Entry(word: "VIDAS", row: 2, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "VIDA", row: 2, column: 0, isVertical: true),
                WordPuzzle.Entry(word: "DIAS", row: 2, column: 2, isVertical: true),
                WordPuzzle.Entry(word: "VISA", row: 0, column: 4, isVertical: true),
                WordPuzzle.Entry(word: "SAI", row: 0, column: 1, isVertical: true),
                WordPuzzle.Entry(word: "DIA", row: 4, column: 0, isVertical: false),
            ],
            bonus: ["IDAS", "DAS", "VAI"]
        ),
        WordPuzzle(
            id: "livros",
            letters: ["L", "I", "V", "R", "O", "S"],
            width: 6, height: 7,
            entries: [
                WordPuzzle.Entry(word: "LIVROS", row: 2, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "LIVRO", row: 2, column: 0, isVertical: true),
                WordPuzzle.Entry(word: "SILO", row: 2, column: 5, isVertical: true),
                WordPuzzle.Entry(word: "SOL", row: 4, column: 3, isVertical: false),
                WordPuzzle.Entry(word: "RIO", row: 5, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "VIR", row: 0, column: 3, isVertical: true),
            ],
            bonus: ["VIRO", "ROL", "VIL"]
        ),
        WordPuzzle(
            id: "praia",
            letters: ["P", "R", "A", "I", "A"],
            width: 7, height: 5,
            entries: [
                WordPuzzle.Entry(word: "PRAIA", row: 1, column: 2, isVertical: false),
                WordPuzzle.Entry(word: "PARA", row: 1, column: 2, isVertical: true),
                WordPuzzle.Entry(word: "RAIA", row: 3, column: 2, isVertical: false),
                WordPuzzle.Entry(word: "ARIA", row: 1, column: 4, isVertical: true),
                WordPuzzle.Entry(word: "PAI", row: 0, column: 6, isVertical: true),
                WordPuzzle.Entry(word: "IRA", row: 2, column: 0, isVertical: false),
            ],
            bonus: ["PAR", "PIA", "RIA"]
        ),
        WordPuzzle(
            id: "jardim",
            letters: ["J", "A", "R", "D", "I", "M"],
            width: 6, height: 6,
            entries: [
                WordPuzzle.Entry(word: "JARDIM", row: 3, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "MIRA", row: 0, column: 1, isVertical: true),
                WordPuzzle.Entry(word: "DAR", row: 3, column: 3, isVertical: true),
                WordPuzzle.Entry(word: "RIM", row: 1, column: 5, isVertical: true),
                WordPuzzle.Entry(word: "DIA", row: 1, column: 0, isVertical: false),
            ],
            bonus: ["IRA", "MAR", "MIA", "RIA"]
        ),
        WordPuzzle(
            id: "beijos",
            letters: ["B", "E", "I", "J", "O", "S"],
            width: 7, height: 5,
            entries: [
                WordPuzzle.Entry(word: "BEIJOS", row: 0, column: 1, isVertical: false),
                WordPuzzle.Entry(word: "BEIJO", row: 0, column: 1, isVertical: true),
                WordPuzzle.Entry(word: "BOI", row: 4, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "BIS", row: 2, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "SEI", row: 0, column: 6, isVertical: true),
            ],
            bonus: ["EIS", "SOB"]
        ),
        WordPuzzle(
            id: "caneta",
            letters: ["C", "A", "N", "E", "T", "A"],
            width: 6, height: 6,
            entries: [
                WordPuzzle.Entry(word: "CANETA", row: 1, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "CANTA", row: 1, column: 0, isVertical: true),
                WordPuzzle.Entry(word: "CENA", row: 0, column: 3, isVertical: true),
                WordPuzzle.Entry(word: "NATA", row: 3, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "ANTE", row: 1, column: 5, isVertical: true),
                WordPuzzle.Entry(word: "ATA", row: 5, column: 0, isVertical: false),
            ],
            bonus: ["ACNE", "ANTA", "CATA"]
        ),
        WordPuzzle(
            id: "carinho",
            letters: ["C", "A", "R", "I", "N", "H", "O"],
            width: 9, height: 5,
            entries: [
                WordPuzzle.Entry(word: "CARINHO", row: 2, column: 2, isVertical: false),
                WordPuzzle.Entry(word: "NICHO", row: 0, column: 2, isVertical: true),
                WordPuzzle.Entry(word: "CHORA", row: 0, column: 8, isVertical: true),
                WordPuzzle.Entry(word: "ARCO", row: 1, column: 4, isVertical: true),
                WordPuzzle.Entry(word: "RIO", row: 4, column: 0, isVertical: false),
            ],
            bonus: ["CARO", "CHAO", "HORA", "RICO", "CAO", "IRA"]
        ),
        WordPuzzle(
            id: "verdade",
            letters: ["V", "E", "R", "D", "A", "D", "E"],
            width: 8, height: 5,
            entries: [
                WordPuzzle.Entry(word: "VERDADE", row: 0, column: 1, isVertical: false),
                WordPuzzle.Entry(word: "VERDE", row: 0, column: 1, isVertical: true),
                WordPuzzle.Entry(word: "REDE", row: 0, column: 3, isVertical: true),
                WordPuzzle.Entry(word: "ARDE", row: 0, column: 5, isVertical: true),
                WordPuzzle.Entry(word: "VER", row: 4, column: 0, isVertical: false),
            ],
            bonus: ["DEVE", "DAR", "ERA"]
        ),
        WordPuzzle(
            id: "janela",
            letters: ["J", "A", "N", "E", "L", "A"],
            width: 6, height: 4,
            entries: [
                WordPuzzle.Entry(word: "JANELA", row: 0, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "ANEL", row: 0, column: 1, isVertical: true),
                WordPuzzle.Entry(word: "ELA", row: 0, column: 3, isVertical: true),
                WordPuzzle.Entry(word: "ALA", row: 0, column: 5, isVertical: true),
            ],
            bonus: ["NELA"]
        ),
        WordPuzzle(
            id: "musica",
            letters: ["M", "U", "S", "I", "C", "A"],
            width: 8, height: 5,
            entries: [
                WordPuzzle.Entry(word: "MUSICA", row: 2, column: 1, isVertical: false),
                WordPuzzle.Entry(word: "SUMIA", row: 0, column: 1, isVertical: true),
                WordPuzzle.Entry(word: "CAIS", row: 0, column: 4, isVertical: true),
                WordPuzzle.Entry(word: "CIMA", row: 0, column: 4, isVertical: false),
                WordPuzzle.Entry(word: "SAI", row: 4, column: 0, isVertical: false),
            ],
            bonus: ["MIA", "SUA", "USA"]
        ),
        WordPuzzle(
            id: "domingo",
            letters: ["D", "O", "M", "I", "N", "G", "O"],
            width: 7, height: 5,
            entries: [
                WordPuzzle.Entry(word: "DOMINGO", row: 2, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "GNOMO", row: 0, column: 1, isVertical: true),
                WordPuzzle.Entry(word: "INDO", row: 1, column: 4, isVertical: true),
                WordPuzzle.Entry(word: "MODO", row: 1, column: 6, isVertical: true),
                WordPuzzle.Entry(word: "DOM", row: 4, column: 0, isVertical: false),
            ],
            bonus: ["DIGO", "GOMO", "ODIO"]
        ),
        WordPuzzle(
            id: "abraco",
            letters: ["A", "B", "R", "A", "C", "O"],
            width: 6, height: 5,
            entries: [
                WordPuzzle.Entry(word: "ABRACO", row: 1, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "CABRA", row: 0, column: 0, isVertical: true),
                WordPuzzle.Entry(word: "BARCO", row: 0, column: 3, isVertical: true),
                WordPuzzle.Entry(word: "BOCA", row: 0, column: 5, isVertical: true),
                WordPuzzle.Entry(word: "ARCO", row: 4, column: 0, isVertical: false),
            ],
            bonus: ["CARO", "BAR", "CAO", "ORA"]
        ),
        WordPuzzle(
            id: "caderno",
            letters: ["C", "A", "D", "E", "R", "N", "O"],
            width: 7, height: 6,
            entries: [
                WordPuzzle.Entry(word: "CADERNO", row: 5, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "ORDENA", row: 0, column: 1, isVertical: true),
                WordPuzzle.Entry(word: "CEDRO", row: 1, column: 6, isVertical: true),
                WordPuzzle.Entry(word: "RENDA", row: 3, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "DONA", row: 0, column: 0, isVertical: false),
            ],
            bonus: ["CORDA", "CEDO", "ONDA", "RODA"]
        ),
        WordPuzzle(
            id: "estrela",
            letters: ["E", "S", "T", "R", "E", "L", "A"],
            width: 7, height: 7,
            entries: [
                WordPuzzle.Entry(word: "ESTRELA", row: 3, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "LESTE", row: 2, column: 0, isVertical: true),
                WordPuzzle.Entry(word: "RESTA", row: 2, column: 4, isVertical: true),
                WordPuzzle.Entry(word: "SETA", row: 5, column: 2, isVertical: false),
                WordPuzzle.Entry(word: "TELA", row: 0, column: 6, isVertical: true),
            ],
            bonus: ["ARTE", "REAL", "ELA", "LAR", "SAL"]
        ),
        WordPuzzle(
            id: "floresta",
            letters: ["F", "L", "O", "R", "E", "S", "T", "A"],
            width: 8, height: 7,
            entries: [
                WordPuzzle.Entry(word: "FLORESTA", row: 3, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "SOLTAR", row: 1, column: 1, isVertical: true),
                WordPuzzle.Entry(word: "FLORES", row: 0, column: 3, isVertical: true),
                WordPuzzle.Entry(word: "RESTA", row: 1, column: 5, isVertical: true),
                WordPuzzle.Entry(word: "TELA", row: 0, column: 7, isVertical: true),
            ],
            bonus: ["FORTE", "ARTE", "FLOR", "ROSA", "SAL"]
        ),
        WordPuzzle(
            id: "canela",
            letters: ["C", "A", "N", "E", "L", "A"],
            width: 6, height: 7,
            entries: [
                WordPuzzle.Entry(word: "CANELA", row: 3, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "LANCE", row: 0, column: 0, isVertical: true),
                WordPuzzle.Entry(word: "CENA", row: 1, column: 2, isVertical: true),
                WordPuzzle.Entry(word: "ALCA", row: 1, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "ANEL", row: 3, column: 5, isVertical: true),
            ],
            bonus: ["NELA", "ALA", "CAL", "ELA"]
        ),
        WordPuzzle(
            id: "passeio",
            letters: ["P", "A", "S", "S", "E", "I", "O"],
            width: 7, height: 8,
            entries: [
                WordPuzzle.Entry(word: "PASSEIO", row: 3, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "PASSE", row: 3, column: 0, isVertical: true),
                WordPuzzle.Entry(word: "PISO", row: 2, column: 5, isVertical: true),
                WordPuzzle.Entry(word: "PAIS", row: 0, column: 2, isVertical: true),
                WordPuzzle.Entry(word: "SAPO", row: 3, column: 3, isVertical: true),
            ],
            bonus: ["PIA", "SAI", "SEI"]
        ),
        WordPuzzle(
            id: "pipoca",
            letters: ["P", "I", "P", "O", "C", "A"],
            width: 7, height: 4,
            entries: [
                WordPuzzle.Entry(word: "PIPOCA", row: 2, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "COPA", row: 0, column: 0, isVertical: true),
                WordPuzzle.Entry(word: "PICO", row: 0, column: 4, isVertical: true),
                WordPuzzle.Entry(word: "PIA", row: 0, column: 4, isVertical: false),
                WordPuzzle.Entry(word: "CAI", row: 0, column: 0, isVertical: false),
            ],
            bonus: ["OCA", "PAI"]
        ),
        WordPuzzle(
            id: "noticia",
            letters: ["N", "O", "T", "I", "C", "I", "A"],
            width: 9, height: 6,
            entries: [
                WordPuzzle.Entry(word: "NOTICIA", row: 2, column: 2, isVertical: false),
                WordPuzzle.Entry(word: "TONICA", row: 0, column: 2, isVertical: true),
                WordPuzzle.Entry(word: "CANTO", row: 1, column: 8, isVertical: true),
                WordPuzzle.Entry(word: "CONTA", row: 4, column: 2, isVertical: false),
                WordPuzzle.Entry(word: "NOTA", row: 0, column: 0, isVertical: false),
            ],
            bonus: ["ATO", "CAI", "TIO"]
        ),
        WordPuzzle(
            id: "tarde",
            letters: ["T", "A", "R", "D", "E"],
            width: 5, height: 4,
            entries: [
                WordPuzzle.Entry(word: "TARDE", row: 0, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "ARDE", row: 0, column: 1, isVertical: true),
                WordPuzzle.Entry(word: "DAR", row: 0, column: 3, isVertical: true),
                WordPuzzle.Entry(word: "TER", row: 3, column: 0, isVertical: false),
            ],
            bonus: ["ATE", "ERA"]
        ),
        WordPuzzle(
            id: "bolacha",
            letters: ["B", "O", "L", "A", "C", "H", "A"],
            width: 8, height: 5,
            entries: [
                WordPuzzle.Entry(word: "BOLACHA", row: 2, column: 1, isVertical: false),
                WordPuzzle.Entry(word: "CALHA", row: 0, column: 3, isVertical: true),
                WordPuzzle.Entry(word: "ACHO", row: 1, column: 5, isVertical: true),
                WordPuzzle.Entry(word: "BOLA", row: 4, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "CABO", row: 1, column: 7, isVertical: true),
            ],
            bonus: ["BOCA", "ALA", "CHA", "OCA"]
        ),
        WordPuzzle(
            id: "feijoada",
            letters: ["F", "E", "I", "J", "O", "A", "D", "A"],
            width: 8, height: 5,
            entries: [
                WordPuzzle.Entry(word: "FEIJOADA", row: 2, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "ODEIA", row: 0, column: 1, isVertical: true),
                WordPuzzle.Entry(word: "FADA", row: 1, column: 5, isVertical: true),
                WordPuzzle.Entry(word: "JOIA", row: 0, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "DIA", row: 0, column: 7, isVertical: true),
            ],
            bonus: ["FEIA"]
        ),
        WordPuzzle(
            id: "saudade",
            letters: ["S", "A", "U", "D", "A", "D", "E"],
            width: 7, height: 5,
            entries: [
                WordPuzzle.Entry(word: "SAUDADE", row: 1, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "USADA", row: 0, column: 0, isVertical: true),
                WordPuzzle.Entry(word: "SAUDE", row: 0, column: 4, isVertical: true),
                WordPuzzle.Entry(word: "SEDA", row: 0, column: 6, isVertical: true),
                WordPuzzle.Entry(word: "DAS", row: 3, column: 0, isVertical: false),
            ],
            bonus: ["SUA", "USA"]
        ),
        WordPuzzle(
            id: "marido",
            letters: ["M", "A", "R", "I", "D", "O"],
            width: 9, height: 6,
            entries: [
                WordPuzzle.Entry(word: "MARIDO", row: 3, column: 3, isVertical: false),
                WordPuzzle.Entry(word: "DORMIA", row: 0, column: 3, isVertical: true),
                WordPuzzle.Entry(word: "RADIO", row: 0, column: 6, isVertical: true),
                WordPuzzle.Entry(word: "MIRA", row: 5, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "DOMA", row: 2, column: 8, isVertical: true),
            ],
            bonus: ["AMO", "DAR", "DIA", "IRA", "MAR", "RIM"]
        ),
        WordPuzzle(
            id: "cadeira",
            letters: ["C", "A", "D", "E", "I", "R", "A"],
            width: 7, height: 5,
            entries: [
                WordPuzzle.Entry(word: "CADEIRA", row: 0, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "CEDIA", row: 0, column: 0, isVertical: true),
                WordPuzzle.Entry(word: "DICA", row: 0, column: 2, isVertical: true),
                WordPuzzle.Entry(word: "CARA", row: 2, column: 2, isVertical: false),
                WordPuzzle.Entry(word: "IRA", row: 3, column: 0, isVertical: false),
            ],
            bonus: ["ARDE", "CAI", "DIA", "ERA"]
        ),
        WordPuzzle(
            id: "relogio",
            letters: ["R", "E", "L", "O", "G", "I", "O"],
            width: 7, height: 6,
            entries: [
                WordPuzzle.Entry(word: "RELOGIO", row: 0, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "ELOGIO", row: 0, column: 1, isVertical: true),
                WordPuzzle.Entry(word: "LOGO", row: 2, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "GIRO", row: 4, column: 0, isVertical: false),
                WordPuzzle.Entry(word: "OLEO", row: 0, column: 6, isVertical: true),
            ],
            bonus: ["EGO", "LER", "RIO", "ROL"]
        ),
    ]
}
