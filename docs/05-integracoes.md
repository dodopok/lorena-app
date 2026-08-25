# Integrações

## Identidade

### Decisão

Usar **Sign in with Apple** como identidade principal do app e conectar a conta Google separadamente apenas para a Agenda.

Motivos:

- reduz o acesso da conta Google ao que a integração realmente precisa;
- atende melhor às expectativas de um app exclusivo para iPhone;
- evita acoplar acesso aos dados pessoais à disponibilidade do Google Calendar;
- prepara eventual revisão da App Store, que impõe condições a apps que usam login de terceiros.

No Firebase Authentication, a usuária possui um único `uid`. A credencial Google da Agenda não cria um segundo perfil.

## Google Agenda

### Escopo funcional do MVP

- Conectar/desconectar Google.
- Ler a lista de calendários e eventos selecionados.
- Exibir calendário primário inicialmente.
- Criar, editar e excluir eventos quando houver permissão.
- Usar eventos de dia inteiro, horários, recorrência simples, lembrete e cor.
- Sincronizar incrementalmente e permitir atualização manual.

### OAuth e menor privilégio

Solicitar acesso em etapas:

1. `calendar.calendarlist.readonly` e `calendar.events.readonly` para visualização.
2. `calendar.events` quando a usuária tentar criar ou editar pela primeira vez.

Se a experiência de consentimento incremental for inconsistente no iOS, o spike técnico deve comparar uma autorização única de `calendar.events` com uma alternativa mais restrita: calendário secundário criado pelo app via `calendar.app.created`.

Aplicações públicas que solicitam acesso a dados Google podem precisar de verificação OAuth. Enquanto o app for privado, a conta deve ser configurada explicitamente como test user no projeto Google Cloud.

### Sincronização

- Fazer sincronização completa inicial do intervalo de 6 meses passados a 12 meses futuros.
- Persistir cache local e `syncToken` por calendário.
- Aplicar mudanças incrementais a partir do token.
- Se a API responder `410 Gone`, apagar o token e refazer a sincronização completa.
- Usar `etag`/versão externa antes de sobrescrever uma edição feita fora do app.
- Manter eventos cancelados o suficiente para remover a cópia local.
- Não enviar eventos Google para Firestore.

### Cores

- Consultar a paleta do endpoint `colors`.
- No MVP, atribuir `colorId` a eventos.
- A paleta do aplicativo é independente; cada categoria local mapeia para a opção Google visualmente mais próxima.
- Labels mais novas da Agenda podem ser avaliadas depois de validar suporte consistente nos clientes usados pela usuária.

### Idempotência

- Criar ID de evento compatível com a API antes do primeiro envio quando possível.
- Repetições de uma mesma tentativa usam o mesmo ID/mutation ID.
- Persistir `calendarId`, `eventId` e `etag` no cache.
- Nunca criar um segundo evento apenas porque a resposta da primeira tentativa foi perdida.

### Conflitos

Se um evento mudou no Google depois de ser aberto para edição:

1. não sobrescrever silenciosamente;
2. buscar a versão atual;
3. mostrar um resumo das diferenças relevantes;
4. permitir usar a versão Google ou aplicar a edição da usuária.

Para recorrências, confirmar se a ação afeta esta ocorrência, esta e as próximas ou toda a série.

## Fotos

### Fontes

- Biblioteca de Fotos.
- Câmera, se adicionada posteriormente.
- Imagem extraída de produto, após validação.

### Pipeline

1. Solicitar acesso contextual.
2. Ler a imagem selecionada sem varrer a biblioteca.
3. Corrigir orientação.
4. Remover EXIF/GPS.
5. Redimensionar e comprimir para limites definidos.
6. Gerar thumbnail.
7. Calcular hash para integridade/deduplicação opcional.
8. Fazer upload para caminho privado no Storage.

Falha de upload não pode apagar a entrada ou a cópia local ainda não sincronizada.

## Produtos por link

### Experiência

- Receber URL pela Share Extension ou colagem.
- Mostrar progresso curto e permitir cancelar.
- Apresentar prévia editável.
- Salvar manualmente se nada for detectado.
- Indicar que preço representa o momento em que o item foi salvo.

### Backend de extração

Uma Cloud Function autenticada recebe a URL e executa:

1. normalização e validação;
2. resolução DNS segura;
3. download limitado de HTML;
4. extração de JSON-LD `Product`;
5. fallback para Open Graph/meta tags;
6. sanitização e retorno de dados estruturados;
7. descarte do HTML bruto.

Não executar JavaScript ou realizar login no MVP. TikTok Shop e lojas baseadas em JavaScript podem cair no fallback manual.

### Estado da implementação

O repositório contém `functions/src/index.ts` e `functions/src/extractor.ts`, com callable autenticada `extractLinkMetadata`, parser JSON-LD/Open Graph, fallback manual, limite por usuário, limite de concorrência, timeout, limite de bytes, redirects limitados e resolução DNS fixada após validação. O cliente Flutter chama a função somente quando `LUME_ENABLE_LINK_EXTRACTION=true`. Deploy no projeto `lume-13125`, Emulator Suite, billing/alertas e testes com páginas reais continuam sendo gates operacionais antes de ativar a flag.

### Proteções contra SSRF e abuso

- Aceitar apenas HTTP/HTTPS e preferir HTTPS.
- Bloquear `localhost`, userinfo, IPs privados, loopback, link-local, multicast e endpoints de metadata cloud.
- Restringir portas a 80/443.
- Validar endereços IPv4 e IPv6 após DNS.
- Revalidar cada redirecionamento e limitar a três.
- Proteger contra DNS rebinding.
- Usar timeout, limite de bytes, limite de descompressão e content types permitidos.
- Não enviar cookies, tokens ou headers do dispositivo.
- Aplicar rate limit por usuário e concorrência baixa.
- Não registrar URL completa nem HTML.
- Validar a URL da imagem pelo mesmo pipeline.

### Campos retornados

```json
{
  "canonicalUrl": "https://...",
  "siteHost": "loja.example",
  "title": "Produto",
  "imageUrl": "https://...",
  "priceMinor": 12990,
  "currency": "BRL",
  "source": "json_ld",
  "warnings": []
}
```

Nome, imagem, preço e moeda possuem limites e validação. Dados extraídos nunca são considerados confirmados até a revisão da usuária.

## Notificações locais

- Água: horários/janelas escolhidos pela usuária; evitar alertar se a meta já foi atingida.
- Exercício: lembrete opcional por dias da semana.
- Gratidão: lembrete noturno opcional.
- Finanças: lembrete opcional do recebimento e fechamento do mês.
- Agenda: preferir lembretes do próprio evento Google para não duplicar alertas.

O app explica o benefício antes de solicitar permissão do iOS. Notificações não exibem valor de saldo, descrição de gasto, conteúdo de gratidão ou informação intestinal na tela bloqueada por padrão.

## Exportação

Formato inicial:

```text
lorena-export-YYYY-MM-DD.zip
  profile.json
  water.csv
  bowel.csv
  exercise.csv
  finance/
    periods.csv
    transactions.csv
  shopping/
    lists.json
    wishlist.csv
  books.json
  gratitude.json
  media/
```

O arquivo é gerado sob demanda, possui expiração curta no backend quando necessário e é compartilhado pela share sheet do iOS. A interface alerta que o conteúdo é sensível.

## Integrações adiadas

- HealthKit/Apple Health.
- Apple Watch e widgets.
- Siri Shortcuts/App Intents.
- ISBN/Google Books/Open Library.
- Open Finance.
- Rastreamento automático de preços.
- Compartilhamento familiar.
