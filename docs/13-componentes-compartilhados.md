# Componentes compartilhados

Este documento define os primitives e componentes reutilizáveis que sustentam as telas do Lume. Ele complementa [Experiência e design](02-experiencia-design.md) e os [contratos das telas](12-contratos-telas.md). A intenção é começar a implementação com uma linguagem visual única, estados previsíveis e acessibilidade tratada na origem.

## 1. Limites e regras

### 1.1 Onde cada coisa mora

```text
lib/
  core/
    theme/                 # tokens, tema claro/escuro e tipografia
    widgets/               # componentes deste documento
    accessibility/         # labels e helpers semânticos
    feedback/              # snackbar, undo e erros traduzidos
  features/<feature>/
    presentation/widgets/  # composição específica de uma feature
```

Um componente entra em `core/widgets` quando é usado por pelo menos duas features ou representa um comportamento transversal (estado, formulário, permissão, sincronização). Widgets específicos de um único domínio ficam na feature e podem compor os compartilhados.

### 1.2 Contrato de dependência

- componentes compartilhados recebem dados prontos e callbacks;
- não conhecem Firestore, Storage, Google Calendar, Riverpod ou repositórios;
- não fazem navegação imperativa para rotas de domínio;
- não calculam saldo, total de água ou regras de negócio;
- podem controlar foco, animação, validação visual e estado transitório local;
- eventos de usuário são callbacks nomeados (`onPressed`, `onChanged`, `onRetry`, `onDismiss`);
- cada componente documenta o que acontece quando uma callback é nula.

O widget de feature adapta entidade de domínio para o modelo visual e decide quais ações devem ser possíveis. O componente compartilhado só apresenta e emite intenção.

## 2. Tokens de design

Widgets usam tokens semânticos, nunca hexadecimais espalhados pelo código. Os valores abaixo são a base inicial; contraste e leitura em dispositivo físico são gates antes do TestFlight.

### 2.1 Cor

| Token | Valor inicial | Uso |
|---|---|---|
| `color.background` | `#FFF8FB` | Fundo geral |
| `color.surface` | `#FFFFFF` | Cards, campos e sheets |
| `color.brand` | `#C94F7C` | Ação primária e seleção |
| `color.brandSoft` | `#F4C5D6` | Progresso, fundo tonal e estados suaves |
| `color.brandStrong` | `#7A294B` | Ênfase e texto sobre rosa claro |
| `color.calendar` | `#DCCCF4` | Agenda e livros quando usado como tom de superfície |
| `color.wellbeing` | `#C8E7D3` | Bem-estar e sucesso |
| `color.finance` | `#FFEBC8` | Finanças e destaques |
| `color.text` | `#372A30` | Texto principal |
| `color.textSecondary` | `#6E5A63` | Metadados e ajuda |
| `color.border` | derivada da superfície | Divisores e campos |
| `color.error` | `#B3261E` | Erros reais e ações destrutivas |
| `color.onBrand` | definida por contraste | Texto/ícone sobre ação primária |

Regras:

- status nunca depende apenas de cor; combinar texto, ícone ou forma;
- `color.error` não representa ausência de hábito ou dia sem registro;
- rosa claro não pode ser texto sobre branco;
- superfícies de feature são tonalidades, não substitutos de labels semânticos;
- tema escuro deve preservar o papel do token, não simplesmente inverter hexadecimais.

### 2.2 Espaçamento e dimensões

| Token | Valor |
|---|---:|
| `space.1` | 4 px |
| `space.2` | 8 px |
| `space.3` | 12 px |
| `space.4` | 16 px |
| `space.5` | 20 px |
| `space.6` | 24 px |
| `space.8` | 32 px |
| `touch.minimum` | 44 × 44 pt |
| `content.horizontal` | 20 px no iPhone |
| `card.padding` | 16–20 px |

Não criar valores intermediários sem necessidade. Listas usam espaçamento consistente entre linhas; o tamanho do texto pode aumentar sem cortar o conteúdo.

### 2.3 Forma, tipografia e movimento

| Família | Tokens |
|---|---|
| Cantos | `radius.control = 12`, `radius.card = 20`, `radius.sheet = 24`, `radius.pill = 999` |
| Elevação | `elevation.none`, `elevation.card`, `elevation.modal`; sombras discretas |
| Título | `type.title`, legível em Dynamic Type, sem truncar informação essencial |
| Corpo | `type.body`, `type.bodyEmphasis`, `type.caption` |
| Label | `type.label`, sempre acompanhado de valor ou ação clara |
| Movimento | entrada/saída em 150–300 ms; sem movimento quando “Reduzir Movimento” estiver ativo |

Nunito ou equivalente licenciada pode ser adotada como fonte principal. A escolha final deve ser empacotada e testada em Dynamic Type; nenhum componente depende de uma fonte não instalada para permanecer legível.

## 3. Vocabulário de estados

Os mesmos nomes aparecem nos contratos de tela, nos view models e nos testes de widget.

### 3.1 Estados de conteúdo

| Estado | Uso visual |
|---|---|
| `initial` | Shell ainda não pronto; não mostrar erro antes de tentar carregar |
| `loading` | Skeleton ou indicador contextual, sem layout saltando |
| `content` | Dados disponíveis; pode ter `syncState` |
| `empty` | Ausência válida, explicação curta e ação principal |
| `offline` | Conteúdo local/cached com indicação de última atualização |
| `error` | Falha recuperável ou explicação de bloqueio |
| `permission` | Acesso negado e caminho contextual para Ajustes |
| `conflict` | Duas versões exigem decisão da usuária |

### 3.2 Estados de operação

| Estado | Regra |
|---|---|
| `idle` | Ação disponível |
| `saving` | Desabilitar confirmação duplicada, manter rascunho |
| `saved` | Feedback breve; retornar/invalidate conforme o contrato |
| `pending` | Salvo localmente, aguardando sincronização |
| `failed` | Mostrar erro próximo da ação e retry |
| `undoAvailable` | Mostrar `UndoBar` por janela curta |

`loading` não é usado como texto em botões. Botões entram em `saving` com indicador e label acessível equivalente, como “Salvando”.

## 4. Catálogo de componentes

### 4.1 `LumeScaffold`

| Campo | Contrato |
|---|---|
| Entradas | `title?`, `child`, `actions`, `bottomNavigation?`, `safeArea`, `scrollable` |
| Eventos | `onBack`, `onProfile`, `onDestinationChanged` quando aplicável |
| Responsabilidade | Safe area, fundo, título, foco inicial e estrutura de página |
| Não faz | Carregar dados, decidir rota de negócio ou mostrar snackbar automaticamente |

Com `bottomNavigation`, preservar a barra ao abrir sheets curtos. Títulos devem continuar compreensíveis em fonte grande. Quando `onBack` for nulo, usar o comportamento padrão da navegação.

### 4.2 `LumeBottomNavigation`

Destinos fixos: Hoje, Agenda, Bem-estar, Finanças e Cantinho. Cada item possui ícone, label visível/semântico e estado selecionado. Não usar apenas cor para indicar seleção.

Contrato:

- `currentDestination` é obrigatório;
- `onDestinationSelected(destination)` é o único evento de troca;
- destino desabilitado não deve aparecer no MVP; integração opcional mostra estado na tela, não trava a aba;
- alvo de toque mínimo de 44 × 44 pt;
- VoiceOver anuncia “Hoje, aba selecionada” ou equivalente;
- não reexecutar carregamento destrutivo ao tocar duas vezes no destino atual.

### 4.3 `LumeCard`

| Campo | Contrato |
|---|---|
| Entradas | `tone`, `child`, `padding?`, `semanticLabel?`, `onTap?`, `isEnabled` |
| Tons | `neutral`, `wellbeing`, `finance`, `calendar`, `corner`, `danger` |
| Eventos | `onTap`, opcional |
| Estados | normal, pressionado, desabilitado, loading via filho |

Se `onTap` existir, tornar o card inteiro acionável sem criar um segundo botão invisível. Ações secundárias ficam em controles internos com labels próprias. Não aplicar sombra forte nem depender da superfície colorida para transmitir o significado.

### 4.4 `LumeSectionHeader`

Recebe `title`, `subtitle?`, `actionLabel?` e `onAction?`. O título deve ser uma única região semântica; a ação precisa indicar o destino (“Ver histórico”, não apenas “Mais”). Se não houver ação, não reservar espaço vazio.

### 4.5 `LumeQuickAction`

Usado em Hoje e ações frequentes.

| Campo | Contrato |
|---|---|
| Entradas | `icon`, `label`, `value?`, `tone`, `isLoading?`, `isEnabled` |
| Evento | `onPressed` |
| Semântica | Label + valor + estado; por exemplo, “Adicionar 300 mililitros de água” |
| Tamanho | Alvo mínimo 44 × 44 pt; não exigir gesto de arrastar |

Para água, tocar uma ação predefinida salva diretamente; o componente não abre formulário nem calcula o total.

### 4.6 `LumeProgressCard`

Recebe `label`, `value`, `max?`, `unit`, `supportingText?`, `tone`, `action?` e `status`. Exibe valor textual e unidade além da barra/anel.

- progresso acima da meta continua legível e não vira erro;
- `max` zero ou ausente usa estado sem meta, nunca divisão inválida;
- VoiceOver anuncia valor, unidade e máximo, quando existir;
- animação é opcional e respeita Reduzir Movimento;
- `onAction` fica visível como botão separado quando a ação for importante.

### 4.7 `LumeMoneySummaryCard`

Recebe `periodLabel`, `balanceMinor`, `currency`, `incomeMinor?`, `expenseMinor?`, `rolloverMinor?`, `tone` e `onTap?`.

- formatar a partir de centavos e código de moeda, nunca de `double`;
- mostrar “Saldo de [mês]” e a moeda no valor ou label;
- valor negativo usa texto/ícone/label, não apenas vermelho;
- loading preserva a altura do card;
- não recebe um saldo calculado pela UI: o view model entrega o agregado do repositório.

### 4.8 `LumeEventCard`

Recebe evento normalizado (`title`, `start`, `end`, `isAllDay`, `calendarLabel`, `color`, `syncState`) e `onTap?`.

Eventos de dia inteiro não exibem horário fictício. A cor precisa vir acompanhada do nome do calendário ou de outro texto. Cache offline exibe “Atualizado em [data/hora]” em região de suporte, sem alarmar.

### 4.9 `LumeCollectionRow`

Primitivo para livro, transação, favorito, item de lista e registro de bem-estar.

Entradas: `leading`, `title`, `subtitle?`, `trailing?`, `statusLabel?`, `thumbnail?`, `onTap?`, `onLongPress?`. O conteúdo principal permanece acessível quando thumbnail falha. Swipe actions não podem ser a única forma de editar/excluir; oferecer menu ou botão visível.

### 4.10 `LumeEmptyState`

Recebe `illustration?`, `title`, `description`, `primaryAction`, `secondaryAction?`. Deve explicar o estado e oferecer uma ação útil.

- não usar linguagem de falha para ausência de hábitos;
- uma lista vazia mostra o que pode ser criado;
- CTA desabilitado explica por quê;
- não incluir ilustração que empurre o CTA essencial para fora da tela em fonte grande.

### 4.11 `LumeLoadingState`

Oferece `variant`: `screen`, `card`, `row`, `button`. Skeleton preserva a geometria aproximada do conteúdo e tem label semântico “Carregando”. Para operações rápidas, preferir progresso no controle acionado a cobrir a tela inteira.

### 4.12 `LumeErrorState`

Recebe `title`, `description`, `errorKind`, `onRetry?`, `onOpenSettings?`, `isBlocking`.

Mapear erros técnicos para mensagens humanas. Se `onRetry` for nulo, não renderizar botão vazio. Erros de permissão oferecem Ajustes; erro de Agenda pode permanecer dentro do card; não mostrar stack trace, token ou URL completa.

### 4.13 `LumeSyncIndicator`

Exibe `synced`, `pending`, `offline`, `conflict` ou `unavailable` com ícone e texto.

- `pending`: “Salvo neste aparelho; sincronizando quando houver conexão”;
- `offline`: “Sem conexão. Mostrando dados salvos em [data/hora]”;
- `conflict`: “Este item mudou fora do app. Revisar”;
- `synced`: pode ser discreto e não ocupar espaço permanente;
- nunca afirmar “sincronizado” apenas porque a escrita local terminou.

O indicador pode ser inline, no card ou em banner global. A escolha depende da superfície; a semântica deve permanecer igual.

### 4.14 `LumeButton`

Variantes: `primary`, `tonal`, `secondary`, `text`, `destructive`, `icon`. Todas recebem `label`, `onPressed?`, `isLoading`, `isEnabled`, `leadingIcon?` e `semanticLabel?`.

- altura/alvo mínimo de 44 × 44 pt;
- `isLoading` desabilita nova execução e anuncia “Salvando” ou label equivalente;
- `destructive` só aparece depois de contexto e confirmação quando necessário;
- botão somente com ícone exige `semanticLabel`;
- primary é reservado à ação principal da superfície; não usar vários primários concorrentes.

### 4.15 Campos de formulário

Todos os campos seguem label persistente, valor, ajuda, erro, foco e estado disabled. Placeholder não substitui label.

| Componente | Valor emitido | Regras |
|---|---|---|
| `LumeTextField` | `String` | maxLength quando definido; preservar quebras quando o campo for nota/resenha |
| `LumeNumberField` | `int`/`decimal` normalizado | teclado numérico, unidade explícita, sem aceitar sinal quando inválido |
| `LumeMoneyField` | `amountMinor` | moeda visível, sem `double`, valor positivo conforme o formulário |
| `LumeDateTimeField` | instante local | converter apenas no repositório; mostrar data/hora local |
| `LumeSelectField` | enum/ID | opções com label e estado selecionado acessível |
| `LumeSearchField` | `String` | ação de limpar, label e estado sem resultados |

Ao validar, focar o primeiro campo inválido e anunciar o erro. Não apagar o restante do formulário quando uma validação falhar.

### 4.16 `LumeChoiceGroup`

Para status de livro, tipo de transação, intensidade e modos de rollover. Recebe opções com `id`, `label`, `description?`, `isEnabled` e `selectedId`.

Usar radio/segmented control quando há seleção única; chips quando a opção pode ser alternada ou filtrada. O valor selecionado é anunciado sem depender de cor. Não usar `ChoiceGroup` para ações que salvam imediatamente sem confirmação clara.

### 4.17 `LumeRatingInput`

Recebe `value?`, `max = 5`, `onChanged`, `readOnly?`. Cada estrela tem label “N de 5”; valor vazio é distinto de zero. Suportar toque e acessibilidade sem exigir arrastar.

### 4.18 `LumePhotoPicker`

Recebe `items`, `maxItems?`, `onAdd`, `onRemove`, `onRetry`, `permissionState`.

- solicita Fotos apenas após ação contextual;
- mostra cópia local imediatamente;
- diferencia `local`, `pending`, `uploaded` e `failed`;
- remoção pede confirmação quando a mídia já está sincronizada e não há desfazer seguro;
- thumbnail possui descrição ou label “Foto [posição]”; botão de remover é separado;
- nunca depende de nome original do arquivo.

### 4.19 `LumeSheet`

Usado para tarefas curtas. Recebe `title`, `child`, `primaryAction`, `secondaryAction?`, `isDirty`, `onDismiss`.

Se `isDirty`, tentar fechar solicita confirmação ou preserva rascunho conforme o contrato da tela. O teclado não deve cobrir o botão principal; o conteúdo é rolável e a ação permanece alcançável em Dynamic Type grande.

### 4.20 `LumeUndoBar`

Recebe `message`, `onUndo`, `duration`, `onExpired?`. É usado para água, exclusões simples, marcar item e outras ações reversíveis.

- não desfazer uma operação já confirmada externamente sem contrato explícito;
- anunciar a mensagem e a ação ao leitor de tela;
- expiração remove apenas a oportunidade de desfazer, não o dado;
- várias operações precisam de `operationId` para não desfazer o item errado.

### 4.21 `LumePermissionCallout`

Recebe `permission`, `title`, `description`, `onRequest`, `onOpenSettings`, `isPermanentlyDenied`.

Explicar o benefício antes do sistema pedir acesso. Se negado, não repetir o prompt automaticamente; orientar Ajustes. Não renderizar um callout de permissão para dados que não exigem autorização do sistema.

### 4.22 `LumeConfirmDialog`

Recebe `title`, `description`, `confirmLabel`, `cancelLabel`, `isDestructive`, `onConfirm`. Usar para exclusão de período, evento recorrente, conta e limpeza de concluídos. O texto deve descrever consequência concreta e não usar culpa.

### 4.23 `LumePhotoViewer`

Visualização em tela cheia para fotos de gratidão, livros e desejos. Recebe lista, índice inicial, labels e `onClose`. Deve suportar zoom padrão do sistema, VoiceOver para fechar/navegar e imagem placeholder quando o upload falhar. Não expõe URL interna do Storage.

## 5. Acessibilidade obrigatória

Todo componente compartilhado precisa ser verificado em:

- Dynamic Type padrão, grande e máximo suportado;
- VoiceOver, com ordem de foco equivalente à ordem visual;
- alvos de toque de pelo menos 44 × 44 pt;
- modo claro/escuro;
- Aumentar Contraste e Reduzir Movimento;
- estado disabled, loading, erro e vazio;
- uso sem cor como único canal de informação;
- teclado apropriado para moeda, quantidade, duração e texto;
- labels de unidade: ml, minutos, reais, data e horário.

Progresso, estrelas, status de sincronização e thumbnails sempre têm uma representação textual/semântica. Componentes não podem exigir swipe, drag ou gesto fino para uma ação essencial.

## 6. Testes de componentes

Cada componente compartilhado deve ter testes de widget para:

1. renderização normal e callback principal;
2. loading/disabled sem callback duplicado;
3. erro, retry e permissão quando aplicável;
4. texto grande sem overflow;
5. semantics/labels essenciais;
6. modo escuro e tonalidade principal quando o componente usa cor;
7. Reduzir Movimento para componentes animados.

Goldens ficam restritos a `LumeCard`, Today cards, estados vazios, item financeiro, livro e favorito, conforme [Qualidade e testes](07-qualidade-testes.md). O teste semântico não é substituído pelo golden.

## 7. Critério de pronto para um componente

Um componente compartilhado só entra na primeira implementação quando:

- sua API e responsabilidade estão documentadas;
- não possui dependência de domínio ou infraestrutura;
- todos os estados listados têm aparência e semântica definidas;
- callbacks não podem executar duas vezes por toque/submit;
- acessibilidade básica foi testada;
- existe teste de widget proporcional ao risco;
- pelo menos uma tela real o utiliza sem duplicar lógica visual.
