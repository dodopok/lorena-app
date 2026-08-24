# Experiência e design

## Arquitetura de informação

A navegação principal terá cinco destinos:

| Destino | Conteúdo |
|---|---|
| Hoje | Resumo diário e ações rápidas |
| Agenda | Google Agenda e compromissos |
| Bem-estar | Água, evacuações e exercícios |
| Finanças | Mesada, gastos, listas e favoritos |
| Cantinho | Livros e gratidão |

No iPhone, os destinos usam uma barra inferior. Telas de criação aparecem como sheets quando a tarefa é curta e como página quando exige contexto ou edição longa.

## Fluxo inicial

1. Tela de boas-vindas com a proposta do aplicativo.
2. Entrar com Apple para proteger e restaurar os dados do app.
3. Explicar e conectar a conta Google somente quando a usuária escolher ativar a Agenda.
4. Configurar meta de água.
5. Configurar valor e dia da mesada.
6. Escolher lembretes; todos começam desligados até consentimento explícito.
7. Mostrar a tela Hoje com exemplos/estados vazios úteis.

O onboarding pode ser pulado após a autenticação, exceto pelos dados indispensáveis de cada módulo.

## Fluxos prioritários

### Adicionar água

`Hoje → tocar em +300 ml → progresso anima e ação pode ser desfeita`

Não abrir formulário para uma quantidade rápida.

### Registrar evacuação

`Hoje → Registrar → confirmar horário e campos opcionais → Salvar`

O texto e os ícones devem ser discretos e naturais. Não usar humor sem validação da usuária.

### Registrar exercício

`Hoje/Bem-estar → Novo exercício → tipo recente → duração → Salvar`

### Registrar gasto

`Hoje/Finanças → Novo gasto → valor → categoria/descrição → Salvar`

O teclado numérico abre no campo de valor e o saldo projetado aparece antes de confirmar.

### Guardar produto

`Compartilhar no Safari/loja → Lume → prévia carregando → revisar dados → Salvar`

Se a prévia falhar, a URL permanece preenchida e os demais campos ficam editáveis.

### Criar gratidão

`Hoje/Cantinho → Gratidão de hoje → texto e/ou foto → Salvar`

O app salva rascunho local durante a edição.

## Tela Hoje

Ordem inicial:

1. Saudação, data e avatar.
2. Próximo compromisso.
3. Água, com progresso e adição rápida.
4. Ações rápidas: evacuação, exercício e gasto.
5. Saldo da mesada.
6. Gratidão do dia.

O conteúdo deve caber em cards claros, sem transformar a tela em um painel denso. Informações históricas permanecem nos módulos.

## Direção visual

### Personalidade

- acolhedora;
- feminina sem clichês;
- calma;
- tátil;
- organizada sem aparência corporativa.

### Paleta inicial

| Papel | Cor | Uso |
|---|---|---|
| Fundo | `#FFF8FB` | Fundo geral |
| Superfície | `#FFFFFF` | Cards e sheets |
| Rosa principal | `#C94F7C` | Botões e seleção |
| Rosa suave | `#F4C5D6` | Fundos e progresso |
| Rosa profundo | `#7A294B` | Ênfase e texto sobre rosa claro |
| Lavanda | `#DCCCF4` | Livros e agenda |
| Menta | `#C8E7D3` | Bem-estar e sucesso |
| Creme | `#FFEBC8` | Finanças e destaques |
| Texto | `#372A30` | Texto principal |
| Texto secundário | `#6E5A63` | Metadados |
| Erro | `#B3261E` | Erros reais, nunca ausência de hábito |

As combinações finais precisam ser validadas com contraste WCAG. Rosa claro não deve ser usado como cor de texto sobre branco.

### Componentes

- Cantos entre 16 e 24 px em cards e sheets.
- Botões primários sólidos e secundários tonais.
- Sombras muito discretas; hierarquia prioritariamente por cor e espaçamento.
- Ícones consistentes, preferencialmente símbolos do Material adaptados à linguagem do iOS.
- Animações entre 150 e 300 ms, respeitando “Reduzir Movimento”.
- Tipografia principal legível e arredondada; Nunito ou equivalente licenciada e empacotada.

## Conteúdo e tom de voz

### Usar

- “Um copo a mais 💧”
- “Quer guardar algo bom de hoje?”
- “Você ainda tem R$ 320,00 neste mês.”
- “Não conseguimos ler os detalhes desse link. Você pode preenchê-los.”

### Evitar

- “Você falhou na sua meta.”
- “Sequência perdida.”
- “Gasto irresponsável.”
- Diminutivos em excesso.
- Diagnósticos ou conclusões sobre saúde.

## Estados de interface

Toda tela de coleção deve prever:

- primeira utilização, com explicação e ação principal;
- carregamento com esqueleto, sem saltos bruscos;
- conteúdo normal;
- pesquisa/filtro sem resultados;
- indisponibilidade offline da integração externa;
- erro recuperável com “Tentar novamente”;
- sincronização pendente sem bloquear edição;
- permissão negada com caminho para Ajustes;
- exclusão com opção imediata de desfazer quando segura.

## Acessibilidade no iPhone

- Suportar Dynamic Type sem truncar valores essenciais.
- Alvos de toque com pelo menos 44 × 44 pontos.
- Não depender apenas de cor para categoria ou status.
- Fornecer rótulos semânticos para ícones, estrelas, gráficos e progresso.
- Ordenar foco do VoiceOver conforme a leitura visual.
- Respeitar Reduzir Movimento e Aumentar Contraste.
- Usar teclado e tipos de entrada adequados para moeda, duração e notas.
- Garantir que fotos tenham descrição opcional quando isso trouxer valor pessoal.

## Protótipos necessários antes da implementação completa

- Onboarding.
- Hoje nos estados vazio, parcial e completo.
- Adição rápida de água.
- Novo gasto e resumo mensal.
- Agenda mensal e edição de evento.
- Favorito com extração bem-sucedida e falha.
- Biblioteca e detalhe do livro.
- Gratidão com texto e foto.
- Configurações e privacidade.
