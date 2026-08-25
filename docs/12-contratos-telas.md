# Contratos das telas

Este documento transforma o escopo e os fluxos de [Experiência e design](02-experiencia-design.md) em contratos para a camada `presentation`. Cada contrato define rota, dados consumidos, ações emitidas, estados obrigatórios e critérios de aceite. A implementação pode trocar widgets e detalhes visuais, mas não deve alterar estes comportamentos sem atualizar este documento.

O escopo cobre a fundação, a primeira fatia diária e os fluxos do MVP. APIs, Firestore, Storage e Google Calendar são acessados por repositórios; uma tela nunca acessa essas fontes diretamente. Os nomes de campos seguem o [modelo de dados](04-modelo-dados.md).

## 1. Convenções

### 1.1 Navegação principal

Depois da autenticação, o app possui cinco destinos persistentes na barra inferior:

| Destino | Rota-base | Conteúdo |
|---|---|---|
| Hoje | `/app/today` | Resumo diário e ações rápidas |
| Agenda | `/app/calendar` | Calendário, agenda do dia e eventos |
| Bem-estar | `/app/wellbeing` | Água, evacuações e exercícios |
| Finanças | `/app/finance` | Mesada, lançamentos, listas e desejos |
| Cantinho | `/app/corner` | Livros e gratidão |

Configurações ficam acessíveis pelo avatar/ícone de perfil no shell e não ocupam um destino da barra inferior.

### 1.2 Registro de rotas

As rotas abaixo são nomes estáveis para deep links, testes e telemetria técnica. A implementação pode usar `GoRouter` ou outra camada equivalente, desde que preserve os parâmetros e a semântica.

| ID | Rota | Apresentação | Requer autenticação |
|---|---|---|---|
| S01 | `/welcome` | Página | Não |
| S02 | `/auth/sign-in` | Página | Não |
| S03 | `/onboarding` | Página paginada | Sim |
| S04 | `/app` | Shell com destino filho | Sim |
| S05 | `/app/today` | Página | Sim |
| S06 | `/app/wellbeing` | Página | Sim |
| S07 | `/app/wellbeing/water/new` | Sheet | Sim |
| S08 | `/app/wellbeing/bowel/new` | Sheet | Sim |
| S09 | `/app/wellbeing/exercise/new` | Sheet | Sim |
| S10 | `/app/calendar` | Página | Sim |
| S11 | `/app/calendar/connect` | Sheet | Sim |
| S12 | `/app/calendar/event/new` e `/app/calendar/event/:eventId/edit` | Página ou sheet alto | Sim |
| S13 | `/app/finance` | Página | Sim |
| S14 | `/app/finance/transaction/new` e `/app/finance/transaction/:id/edit` | Sheet | Sim |
| S15 | `/app/finance/shopping/:listId` | Página | Sim |
| S16 | `/app/finance/wishlist` | Página | Sim |
| S17 | `/app/finance/wishlist/new` e `/app/finance/wishlist/:id/edit` | Página | Sim |
| S18 | `/app/corner` | Página | Sim |
| S19 | `/app/corner/books` | Página | Sim |
| S20 | `/app/corner/books/new` e `/app/corner/books/:id/edit` | Página ou sheet alto | Sim |
| S21 | `/app/corner/gratitude` | Página | Sim |
| S22 | `/app/corner/gratitude/:localDate/edit` | Página ou sheet alto | Sim |
| S23 | `/app/settings` | Página | Sim |
| S24 | `/app/settings/privacy` | Página | Sim |

`/:id` e `/:eventId` são identificadores externos à UI. A tela não deve inferir a existência de um documento apenas porque a rota possui um ID; o carregamento precisa tratar `not found` como estado explícito.

### 1.3 Estado de tela

Toda tela de leitura expõe um estado de visualização. O domínio mantém o estado de sincronização para persistência e recuperação, mas a interface não exibe um indicador técnico permanente.

```text
ViewState<T>
  initial
  loading
  content(data: T, sync: SyncState)
  empty(EmptyModel)
  error(ErrorModel, previousData?)

SyncState
  synced
  pending
  offline
  conflict
  unavailable
```

Regras:

- `loading` aparece apenas antes de existir conteúdo; ao atualizar conteúdo existente, preservar a geometria e evitar banners técnicos;
- `empty` representa ausência válida de dados, não erro;
- `error` sempre oferece uma ação recuperável quando o problema puder ser resolvido pela usuária;
- dados próprios podem ser salvos em `offline` e ficam visíveis imediatamente;
- cache da Agenda pode ser exibido com `offline`, mas eventos não devem parecer recém-sincronizados nem exibir o horário da última atualização;
- `saving` é um estado de operação e pode coexistir com `content`; o botão de confirmar fica protegido contra toque duplicado;
- `pending` não bloqueia edição local e não vira um status persistente na tela, salvo mutações da Agenda no MVP, que exigem conexão;
- uma falha em um card não pode converter a tela inteira em erro quando os demais cards continuam utilizáveis.

### 1.4 Resultado de ações

Toda ação de escrita termina em um destes resultados:

| Resultado | Comportamento |
|---|---|
| `saved` | Atualiza a tela e informa sucesso de forma breve. |
| `savedOffline` | Atualiza a tela; a persistência local continua sem expor um status técnico ao usuário. |
| `undone` | Reverte a mutação e atualiza agregados derivados. |
| `failed` | Mantém dados/rascunho editável e oferece tentativa novamente. |
| `conflict` | Não sobrescreve silenciosamente; mostra decisão necessária. |
| `cancelled` | Fecha ou retorna sem alteração persistida. |

Ao voltar de uma tela de criação/edição, o resultado pode ser `saved`, `deleted` ou `cancelled`. A tela chamadora deve atualizar seu repositório local ou invalidar a consulta correspondente.

## 2. Contratos de telas

### S01 — Boas-vindas

| Item | Contrato |
|---|---|
| Rota | `/welcome` |
| Objetivo | Explicar a proposta do Lume e levar a usuária à autenticação. |
| Entrada | Nenhuma; se houver sessão válida, redirecionar para `/app/today`. |
| Ação principal | `onSignInRequested` → `/auth/sign-in`. |
| Ação secundária | Link para privacidade apenas se já existir uma URL pública; não exigir cadastro para ler a proposta. |

Estados: conteúdo normal; verificação de sessão; erro recuperável de restauração. A tela não solicita Fotos, Notificações, Calendário ou biometria.

Aceite: a proposta fica compreensível sem tutorial; tocar no CTA não cria documento parcial; sessão válida nunca exibe novamente o onboarding.

### S02 — Entrada com Apple

| Item | Contrato |
|---|---|
| Rota | `/auth/sign-in` |
| Objetivo | Criar ou recuperar o mesmo `uid` por Sign in with Apple. |
| Entrada | Resultado do provedor Apple e estado de sessão Firebase. |
| Ação principal | `onAppleSignIn` com estados `idle`, `loading`, `success` e `error`. |
| Saída | Sessão válida → onboarding se necessário, ou `/app/today`. |

Regras de erro:

- cancelamento pela usuária volta a `idle`, sem toast de erro;
- falha de rede permite tentar novamente;
- tokens, códigos e mensagens técnicas não aparecem na UI nem nos logs;
- sair remove estado sensível local, mas não exclui documentos remotos.

Aceite: reiniciar o app restaura a sessão; autenticar uma conta existente não cria um segundo perfil.

### S03 — Onboarding

| Item | Contrato |
|---|---|
| Rota | `/onboarding` |
| Objetivo | Configurar somente preferências úteis para o primeiro uso. |
| Passos | Meta de água; mesada/dia; lembretes; Agenda opcional. |
| Entrada | Preferências existentes ou valores padrão ainda não confirmados. |
| Saída | `onboardingCompleted` → `/app/today`; `onboardingSkipped` quando permitido. |

Cada passo persiste um rascunho local antes de avançar. A conexão Google nunca é iniciada automaticamente. Notificações só são solicitadas após ativar um lembrete. O passo de Agenda pode ser pulado sem degradar os demais módulos.

Estados: carregando preferências; editando; salvando; erro com opção de continuar sem a preferência não essencial.

Aceite: fechar e reabrir não perde os passos concluídos; valores inválidos não avançam; o primeiro acesso termina em uma tela Hoje utilizável, mesmo sem Google ou notificações.

### S04 — Shell autenticado

| Item | Contrato |
|---|---|
| Rota | `/app` com destino filho |
| Responsabilidade | Guardar autenticação, biometria, barra inferior e cobertura de background. |
| Destinos | Hoje, Agenda, Bem-estar, Finanças e Cantinho. |
| Entradas externas | Deep link de favorito, livro ou evento; resultado de reautenticação. |
| Ações | Trocar destino; abrir configurações; bloquear/desbloquear; tratar logout. |

O shell não carrega dados de domínio. Ele só coordena os estados globais e preserva a rota selecionada. A barra inferior não deve desaparecer ao abrir um sheet curto; formulários longos usam página.

Estados: autenticando; desbloqueando por biometria; conteúdo; bloqueado; sessão expirada; erro de restauração. Ao entrar em background, cobrir conteúdo sensível antes do snapshot do sistema.

Aceite: falha em um destino não derruba os demais; Dynamic Type grande não oculta a navegação; deep links inválidos retornam a um destino seguro com mensagem curta.

### S05 — Hoje

| Item | Contrato |
|---|---|
| Rota | `/app/today` |
| Objetivo | Ser o resumo diário e o caminho mais curto para registros frequentes. |
| Dados | Relógio/localDate; perfil; próximo evento em cache; soma de água; período financeiro; gratidão do dia. |
| Ordem | Saudação/data; próximo compromisso; água; ações rápidas; saldo; gratidão. |
| Ações | Abrir Agenda; água rápida; evacuação; exercício; gasto; gratidão; configurações. |

Cada card possui carregamento, conteúdo, vazio e erro próprios. O card de Agenda pode mostrar “Conectar Agenda” ou “Indisponível offline” sem bloquear água, saldo ou gratidão. O total de água é derivado dos logs de `localDate`; o saldo é derivado dos lançamentos.

Aceite: uma adição rápida de água aparece sem aguardar rede; uma falha de Agenda não impede ações rápidas; primeiro uso mostra CTA úteis em vez de cards vazios sem explicação; o valor de saldo identifica mês e moeda.

### S06 — Bem-estar

| Item | Contrato |
|---|---|
| Rota | `/app/wellbeing` |
| Objetivo | Reunir água, evacuações e exercícios sem usar linguagem de cobrança. |
| Dados | Meta/total de água; logs recentes de evacuação; minutos e sessões da semana. |
| Ações | Adicionar água; novo registro de evacuação; novo exercício; abrir histórico/editar/excluir. |
| Período padrão | Hoje para água e evacuação; semana local para exercício. |

Estados: conteúdo parcial é válido; dias sem exercício são neutros; ausência de evacuação não é erro. O módulo não diagnostica, recomenda tratamento ou transforma sequência em pontuação.

Aceite: totais respeitam `America/Sao_Paulo`; cards de água, evacuação e exercício podem falhar isoladamente; ações de criação abrem o formulário já com data/hora adequadas.

### S07 — Registro de água

| Item | Contrato |
|---|---|
| Rota | `/app/wellbeing/water/new` |
| Apresentação | Sheet curto; o caminho rápido não abre este formulário para quantidades predefinidas. |
| Entrada | `amountMl?`, `occurredAt?`, `source` (`quick_action` ou `manual`). |
| Campos | Quantidade em ml, obrigatória, inteira e positiva; horário editável no modo manual. |
| Ações | `onAmountSelected`, `onSave`, `onCancel`, `onUndo`. |
| Persistência | `water_logs`; escrita offline imediata. |

Quantidades rápidas iniciais: 200, 300 e 500 ml, vindas de preferências. Se a usuária informar valor personalizado, validar antes de salvar e manter o rascunho em caso de erro.

Aceite: salvar atualiza total e percentual; fechar sem salvar não cria log; desfazer remove exatamente o log criado; o horário convertido para `localDate` não muda por UTC.

### S08 — Registro de evacuação

| Item | Contrato |
|---|---|
| Rota | `/app/wellbeing/bowel/new` |
| Apresentação | Sheet curto, discreto e sem humor. |
| Entrada | `logId?` para edição; `occurredAt` preenchido com o momento atual na criação. |
| Campos | Data/hora obrigatória; Bristol 1–7 opcional; conforto opcional; observação opcional. |
| Ações | Salvar, excluir no modo edição, cancelar, desfazer exclusão. |
| Persistência | `bowel_logs`; escrita offline imediata. |

O formulário pode ocultar campos opcionais atrás de “Adicionar detalhes”. Textos devem permanecer descritivos e neutros.

Aceite: horário pode ser corrigido; nenhum valor fora de 1–7 é aceito; exclusão simples pode ser desfeita; nenhuma mensagem interpreta sintoma.

### S09 — Registro de exercício

| Item | Contrato |
|---|---|
| Rota | `/app/wellbeing/exercise/new` |
| Apresentação | Sheet alto ou página quando houver teclado aberto e notas extensas. |
| Entrada | `sessionId?` para edição; tipos recentes/favoritos. |
| Campos | Tipo obrigatório; duração inteira positiva obrigatória; início preenchido; intensidade e observação opcionais. |
| Ações | Salvar, excluir, cancelar, repetir tipo recente. |
| Persistência | `exercise_sessions`; escrita offline imediata. |

Aceite: tipos recentes reduzem digitação; duração inválida não salva; total semanal soma minutos sem contar duas vezes; dias sem registro não recebem estado de falha.

### S10 — Agenda

| Item | Contrato |
|---|---|
| Rota | `/app/calendar` |
| Objetivo | Exibir o calendário Google conectado sem duplicar eventos em Firestore. |
| Modos | Mês e agenda diária; dia atual é o padrão. |
| Dados | Calendários selecionados, eventos em cache SQLite, `syncState`, último sync e permissões. |
| Ações | Trocar mês/dia; sincronizar; conectar; abrir evento; criar evento; abrir Google Agenda. |

Sem conexão, mostrar o cache com marcação clara de “última atualização”. Sem cache, mostrar CTA de conexão ou estado indisponível. `410 Gone` do Calendar API não aparece como erro técnico: o repositório refaz sync completo.

Aceite: eventos de dia inteiro têm tratamento próprio; cores vêm do calendário/`colorId`; sincronização incremental não duplica; revogar Google não afeta outros destinos.

### S11 — Conexão Google

| Item | Contrato |
|---|---|
| Rota | `/app/calendar/connect` |
| Apresentação | Sheet contextual iniciado pela Agenda ou Configurações. |
| Entrada | Estado atual da integração e escopos disponíveis. |
| Ações | Conectar somente leitura; autorizar escrita quando necessário; desconectar; abrir Ajustes/Google quando aplicável. |
| Saída | Integração conectada, revogada ou cancelada; invalidar cache quando necessário. |

Explicar que esta é uma autorização separada da conta Apple e quais dados serão acessados. Pedir o menor escopo possível. Ao revogar, limpar tokens do armazenamento seguro e cache local sem apagar dados próprios.

Aceite: recusar mantém o app utilizável; token expirado oferece reautorização; a tela nunca exibe token ou escopo como jargão sem explicação.

### S12 — Editor de evento

| Item | Contrato |
|---|---|
| Rota | `/app/calendar/event/new` ou `/app/calendar/event/:eventId/edit` |
| Apresentação | Página ou sheet alto; edição exige conexão no MVP. |
| Campos | Título obrigatório; descrição; início/fim; dia inteiro; recorrência simples; lembrete; cor; calendário. |
| Ações | Salvar, excluir, cancelar, abrir no Google, escolher alcance de recorrência. |
| Estados | Rascunho local; salvando; sem permissão; conflito; falha de rede; salvo. |

Início e fim devem ser válidos; eventos de dia inteiro usam data civil e não duração de 24 horas. Em recorrência, perguntar “esta ocorrência”, “esta e próximas” ou “toda a série”. Se a resposta da API for perdida, repetir com o mesmo ID/mutation ID.

Aceite: sem conexão, preservar o rascunho e explicar que o envio aguarda rede; sem permissão de escrita, oferecer leitura/abrir Google; conflito nunca sobrescreve silenciosamente.

### S13 — Finanças

| Item | Contrato |
|---|---|
| Rota | `/app/finance` |
| Objetivo | Mostrar o período financeiro e oferecer lançamentos confiáveis. |
| Dados | Período `YYYY-MM`, recebido, gasto, saldo, rollover, categorias, transações e listas/desejos resumidos. |
| Filtros | Mês e categoria; moeda fixa BRL no MVP. |
| Ações | Novo gasto/receita; editar/excluir; configurar mesada; abrir lista; abrir desejos. |

O resumo deriva de `allowance_periods` e `transactions`; nunca persistir um saldo visual como fonte de verdade. Ao trocar mês, indicar período fechado e não alterar dados.

Aceite: R$ 500,00 menos R$ 25,99 resulta em R$ 474,01; editar e excluir recalculam; geração duplicada da mesada não duplica lançamento; saldo negativo e rollover seguem a configuração documentada.

### S14 — Editor de transação

| Item | Contrato |
|---|---|
| Rota | `/app/finance/transaction/new` ou `/app/finance/transaction/:id/edit` |
| Apresentação | Sheet curto, com valor como primeiro campo. |
| Campos | Tipo; valor positivo em centavos; data; categoria; descrição; observação; comprovante futuro. |
| Ações | Salvar, excluir no modo edição, cancelar, desfazer exclusão. |
| Validações | Valor obrigatório e positivo; data no período escolhido; moeda BRL; categoria válida quando exigida. |

Abrir teclado numérico para valor e exibir saldo projetado antes de confirmar. Criar com retry deve ser idempotente; nenhuma operação deve usar `double`.

Aceite: erro mantém o valor editável; salvar offline atualiza a lista e marca pendência; alteração de mês fechado exige confirmação explícita; exclusão recalcula o resumo.

### S15 — Lista de compras

| Item | Contrato |
|---|---|
| Rota | `/app/finance/shopping/:listId` |
| Objetivo | Manter itens acionáveis sem apagar concluídos automaticamente. |
| Dados | Lista e itens ordenados por `position`, separados em pendentes/concluídos. |
| Ações | Adicionar item; marcar/desmarcar; reordenar; editar; excluir; limpar concluídos com confirmação. |
| Campos do item | Nome obrigatório; quantidade; observação; preço estimado opcional. |

Marcar comprado é uma mutação reversível e não remove o item. Reordenar usa uma operação local estável e persiste `position` depois.

Aceite: item sem preço é válido; itens concluídos permanecem; limpeza oferece confirmação e desfazer quando possível; modo offline reflete a ação local.

### S16 — Desejos e favoritos

| Item | Contrato |
|---|---|
| Rota | `/app/finance/wishlist` |
| Objetivo | Listar links guardados e diferenciar desejado, comprado e arquivado. |
| Dados | `wishlist_items`, filtros por status/coleção e total conhecido apenas em moeda compatível. |
| Ações | Novo item; receber link; editar; marcar comprado/arquivado; abrir URL; excluir. |
| Vazio | CTA para colar URL e instrução para usar a Share Extension. |

Preço ausente não é zero. Totais misturando moedas ficam ocultos ou separados por código. Abrir uma URL usa o comportamento seguro do sistema.

Aceite: URL sozinha permite salvar; falha de extração não bloqueia cadastro manual; item comprado não desaparece; status e preço permanecem editáveis.

### S17 — Editor de desejo e prévia de link

| Item | Contrato |
|---|---|
| Rota | `/app/finance/wishlist/new` ou `/app/finance/wishlist/:id/edit` |
| Entrada | URL colada, URL recebida pela Share Extension ou item existente. |
| Prévia | `loading`, `success`, `partial`, `failed`, `cancelled`; resultado sempre marcado como não confirmado até revisão. |
| Campos | URL obrigatória; nome; imagem; preço; moeda; loja; status; coleção/prioridade posteriores. |
| Ações | Buscar prévia; cancelar busca; salvar manualmente; abrir URL; escolher foto; excluir. |

Offline, manter a URL e permitir preencher tudo manualmente. A Cloud Function não é chamada pela UI diretamente. Avisos de extração não impedem salvar.

Aceite: URL permanece após timeout; TikTok/Mercado Livre podem cair em manual; imagem/preço não confirmados são editáveis; somente usuária autenticada solicita extração.

### S18 — Cantinho

| Item | Contrato |
|---|---|
| Rota | `/app/corner` |
| Objetivo | Entrada afetiva para livros e gratidão. |
| Dados | Livro recente/em destaque e estado da gratidão do dia; contagens são auxiliares. |
| Ações | Abrir livros; abrir gratidão; criar gratidão do dia. |

O vazio deve convidar a guardar uma lembrança, sem ranking, sequência perdida ou cobrança. Falha de fotos não deve esconder texto já salvo.

### S19 — Biblioteca de livros

| Item | Contrato |
|---|---|
| Rota | `/app/corner/books` |
| Dados | Livros carregados localmente, status, filtros e ordenação. |
| Filtros | Quero ler, lendo, lido, abandonado; busca local por título/autor. |
| Ações | Adicionar; editar; abrir detalhe; alterar status; excluir. |
| Vazio | Explicação curta e CTA “Adicionar livro”. |

Capa e autor são opcionais. A lista usa thumbnail, não imagem original. Excluir pede confirmação quando houver capa própria e oferece desfazer quando seguro.

Aceite: busca funciona nos itens carregados; status é explícito; texto grande não corta título essencial; ausência de capa não gera placeholder enganoso.

### S20 — Editor/detalhe do livro

| Item | Contrato |
|---|---|
| Rotas | `/app/corner/books/new`, `/app/corner/books/:id/edit` |
| Campos | Título obrigatório; autor; capa; status; início; conclusão; avaliação 1–5; resenha; ISBN futuro. |
| Ações | Salvar; selecionar/remover capa; alterar status; excluir; cancelar. |
| Regras | Avaliação só aceita 1–5; resenha preserva quebras; capa pode ficar pendente de upload. |

Marcar como lido sugere data de conclusão, mas não a impõe. Falha de upload mantém a cópia local e o rascunho.

Aceite: livro sem capa/autor salva; avaliação acessível anuncia “N de 5”; editar não cria segundo livro; exclusão remove ou agenda remoção da capa associada.

### S21 — Gratidão

| Item | Contrato |
|---|---|
| Rota | `/app/corner/gratitude` |
| Dados | Entradas ordenadas por `localDate`, thumbnails e estado de upload. |
| Ações | Abrir entrada; editar; criar entrada do dia; visualizar foto em tela cheia. |
| Regra MVP | No máximo uma entrada por `localDate`; texto não vazio ou ao menos uma imagem. |

O histórico é cronológico e neutro. O dia sem entrada possui CTA, não alerta de falha.

Aceite: foto e texto podem ser combinados; rascunho local sobrevive à seleção de foto; excluir respeita período recuperável; imagens não carregam resolução original na lista.

### S22 — Editor de gratidão

| Item | Contrato |
|---|---|
| Rota | `/app/corner/gratitude/:localDate/edit` |
| Campos | Texto opcional; zero ou mais fotos; `localDate` imutável após criação no MVP. |
| Ações | Salvar; adicionar/remover foto; cancelar; excluir; desfazer exclusão. |
| Estado de mídia | `local`, `pending`, `uploaded`, `failed`, `removed`. |

Salvar pode acontecer offline. Ao sair durante seleção de foto, preservar rascunho e cópia local. Remover imagem não deve apagar a entrada se ainda houver texto ou outra imagem.

Aceite: entrada vazia é recusada; uma nova gravação no mesmo dia edita a existente; falha de upload tem retry; o leitor de tela identifica cada foto e ação de remoção.

### S23 — Configurações

| Item | Contrato |
|---|---|
| Rota | `/app/settings` |
| Seções | Perfil Apple; Google Agenda; água; mesada; calendário; notificações; biometria; privacidade. |
| Ações | Editar preferências; conectar/desconectar Google; ativar permissões contextuais; exportar; excluir; sair. |
| Estado | Preferências carregadas do documento `settings/preferences`; salvamento por seção. |

Alterar a preferência padrão de mesada não modifica período fechado sem confirmação. Permissões negadas apontam para Ajustes e não ficam em loop de solicitação.

Aceite: sair não exclui dados remotos; o cache da Agenda permanece disponível conforme a conexão; Face ID pode ser ativado/desativado; todos os controles têm label e valor atual.

### S24 — Privacidade, exportação e exclusão

| Item | Contrato |
|---|---|
| Rota | `/app/settings/privacy` |
| Ações | Exportar dados; desconectar Google; excluir conta; consultar política de privacidade. |
| Exportação | Mostrar escopo, sensibilidade, progresso, expiração e share sheet. |
| Exclusão | Oferecer exportação antes; exigir reautenticação; confirmação explícita; estado de processamento. |

Excluir remove Firestore, Storage, jobs, tokens e cache conforme [Segurança e privacidade](06-seguranca-privacidade.md). Eventos Google são tratados em decisão separada: manter ou remover no próprio Google, com explicação de propriedade.

Aceite: usuário não autenticado não acessa a tela; cancelar reautenticação não apaga nada; falha de exportação mantém dados; sucesso de exclusão encerra a sessão e volta à entrada.

## 3. Contrato de comunicação entre tela e domínio

View models/controllers devem receber dependências por injeção e expor apenas modelos de UI. A tela pode emitir intenções como:

```text
load()
refresh()
submit(form)
delete(id)
undo(operationId)
retry(operationId)
open(route, parameters)
requestPermission(permission)
```

O controller transforma respostas de repositório em `ViewState` e `OperationResult`. Não expor `FirebaseException`, `GoogleApiException` ou DTO de rede diretamente no widget. Mensagens para a usuária devem ser traduzidas por um catálogo de erros estável.

### 3.1 Invalidação mínima após escrita

| Origem | Invalidar/atualizar |
|---|---|
| Água | card Hoje, card Bem-estar, histórico do dia |
| Evacuação | card Bem-estar, histórico |
| Exercício | minutos da semana, histórico |
| Transação | resumo financeiro, lista do período, card Hoje |
| Lista de compras | lista e contador do resumo financeiro |
| Desejo | lista, totais por moeda e card de resumo |
| Livro | biblioteca, Cantinho e detalhe aberto |
| Gratidão | card Hoje, histórico e Cantinho |
| Agenda | cache, próximo evento Hoje e lista/mês |

### 3.2 Primeira fatia de implementação

Para começar a codificar com risco baixo, implementar nesta ordem:

1. S04 shell, S01–S03 sessão/onboarding e S05 Hoje com dados falsos tipados;
2. componentes de estado, cards e formulários descritos em [Componentes compartilhados](13-componentes-compartilhados.md);
3. S07 água e S22 gratidão, com persistência offline;
4. S06 bem-estar e S09 exercício;
5. S13 finanças e S14 transação;
6. Agenda, links, livros e portabilidade conforme os gates do roadmap.

Uma tela só pode ser considerada pronta quando seu contrato, estados de erro/offline, critérios de aceite e testes proporcionais estiverem presentes. A [Definition of Done](07-qualidade-testes.md#definition-of-done) continua sendo obrigatória.
