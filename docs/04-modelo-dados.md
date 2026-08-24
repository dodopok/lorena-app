# Modelo de dados

## Convenções gerais

- Todos os documentos pessoais ficam sob `/users/{userId}`.
- IDs são gerados no cliente, exceto IDs determinísticos indicados.
- Instantes usam timestamp UTC.
- Datas civis usadas para agrupamento também possuem `localDate` no formato `YYYY-MM-DD`.
- Valores monetários usam `amountMinor` inteiro e `currency = "BRL"`.
- Campos opcionais ausentes não devem ser gravados como strings vazias.
- Documentos editáveis possuem `createdAt`, `updatedAt` e `schemaVersion`.

## Estrutura Firestore

```text
users/{uid}
  settings/preferences
  water_logs/{logId}
  bowel_logs/{logId}
  exercise_sessions/{sessionId}
  allowance_periods/{yyyy-mm}
  transactions/{transactionId}
  shopping_lists/{listId}
    items/{itemId}
  wishlist_items/{itemId}
  books/{bookId}
  gratitude_entries/{entryId}
  integrations/google_calendar
  exports/{exportId}
```

## Perfil e preferências

`users/{uid}`:

```text
displayName, email, photoUrl
locale, timeZone, currency
createdAt, updatedAt, schemaVersion
```

`settings/preferences`:

```text
waterGoalMl
quickWaterAmountsMl[]
allowanceAmountMinor
allowanceDayOfMonth
allowanceRolloverMode: none | positive_only
biometricLockEnabled
notificationPreferences{}
calendarPreferences{}
```

## Água

`water_logs/{logId}`:

```text
amountMl: int > 0
occurredAt: timestamp
localDate: YYYY-MM-DD
source: manual | quick_action | widget
createdAt, updatedAt
```

O total diário é a soma dos logs; não armazenar o progresso como verdade independente.

## Evacuações

`bowel_logs/{logId}`:

```text
occurredAt
localDate
bristolType?: 1..7
comfort?: comfortable | neutral | uncomfortable
note?: string
createdAt, updatedAt
```

Campos de classificação permanecem opcionais. Nenhuma classificação gera diagnóstico.

## Exercícios

`exercise_sessions/{sessionId}`:

```text
activityType
customActivityName?
startedAt
localDate
durationMinutes: int > 0
intensity?: light | moderate | intense
note?
createdAt, updatedAt
```

## Mesada e períodos financeiros

`allowance_periods/{yyyy-mm}` usa a competência como ID:

```text
period: YYYY-MM
allowanceAmountMinor
rolloverMinor
adjustmentMinor
currency
startsOn, endsOn
status: open | closed
createdAt, updatedAt
```

O fechamento congela os parâmetros usados naquele mês. Alterar a mesada padrão afeta somente períodos futuros, salvo confirmação explícita. Ao abrir o período, o app cria uma transação de mesada com ID determinístico `allowance_YYYY-MM`.

## Transações

`transactions/{transactionId}`:

```text
type: allowance | income | expense | adjustment
amountMinor: int > 0
currency
occurredAt
localDate
period: YYYY-MM
categoryId
description
note?
source: manual | allowance_generation
receiptImage?
createdAt, updatedAt, deletedAt?
```

Saldo do período:

```text
rollover + mesada + receitas + ajustes positivos
- despesas - ajustes negativos
```

A direção de cada valor vem de `type`; `amountMinor` permanece positivo. A mesada aparece uma única vez no livro de transações; o valor copiado no período é uma configuração/auditoria e não é somado novamente.

## Lista de compras

`shopping_lists/{listId}`:

```text
name
archivedAt?
createdAt, updatedAt
```

`shopping_lists/{listId}/items/{itemId}`:

```text
name
quantity: decimal/string normalizado conforme UI
note?
estimatedPriceMinor?
currency?
wishlistItemId?
isChecked
position
createdAt, updatedAt, checkedAt?
```

## Favoritos

`wishlist_items/{itemId}`:

```text
originalUrl
canonicalUrl?
siteHost
title
image{}
priceMinor?
currency?
status: wanted | purchased | archived
collection?
priority?
metadataSource: json_ld | open_graph | manual
metadataFetchedAt?
createdAt, updatedAt, purchasedAt?
```

Preço ausente é diferente de preço zero. A imagem pode apontar para uma URL externa e, após confirmação, para cópia própria no Storage.

## Livros

`books/{bookId}`:

```text
title
author?
coverImage?
status: want_to_read | reading | read | abandoned
startedOn?
finishedOn?
rating?: 1..5
review?
isbn?
createdAt, updatedAt
```

Regras:

- capa é opcional;
- avaliação e resenha podem existir nos estados `read` e `abandoned`;
- marcar como lido sugere, mas não obriga, uma data de conclusão.

## Gratidão

`gratitude_entries/{entryId}`:

```text
localDate
text?
images[]
createdAt, updatedAt
```

No MVP, o ID pode ser o próprio `YYYY-MM-DD`, garantindo uma entrada por dia. Deve existir texto não vazio ou ao menos uma imagem.

## Referência da Agenda

Eventos do Google não serão copiados para Firestore como dados pessoais permanentes. O cache operacional SQLite contém:

```text
calendarId
eventId
etag
title
start, end
isAllDay
colorId/labelId
updatedAtGoogle
lastFetchedAt
```

O app armazena apenas preferências da integração em `integrations/google_calendar`, nunca access tokens.

## Storage

```text
users/{uid}/gratitude/{entryId}/{imageId}.jpg
users/{uid}/books/{bookId}/{imageId}.jpg
users/{uid}/wishlist/{itemId}/{imageId}.jpg
users/{uid}/receipts/{transactionId}/{imageId}.jpg
users/{uid}/exports/{exportId}.zip
```

Cada objeto possui `contentType`, tamanho máximo validado e metadados mínimos. Nomes originais enviados pelo usuário não são usados como caminho.

## Índices previstos

- água por `localDate, occurredAt`;
- evacuações por `localDate, occurredAt`;
- exercícios por `localDate, startedAt`;
- transações por `period, occurredAt` e `period, categoryId`;
- favoritos por `status, createdAt`;
- livros por `status, updatedAt`;
- gratidão por `localDate`.

Os índices finais serão gerados a partir das consultas reais e versionados com o projeto Firebase.

## Migrações

- Todo documento relevante possui `schemaVersion`.
- Leitores devem aceitar a versão anterior durante uma migração.
- Migrações destrutivas são evitadas; novos campos começam opcionais.
- Funções de backfill são idempotentes e testadas no ambiente dev.
- Antes de migrar produção, gerar exportação recuperável.
