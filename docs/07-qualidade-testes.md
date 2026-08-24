# Qualidade e testes

## Estratégia

Qualidade será tratada por risco. Cálculos financeiros, perda de dados, sincronização, autenticação e privacidade exigem testes mais fortes que detalhes puramente decorativos.

## Pirâmide de testes

### Unitários

- Cálculo do saldo, rollover e fechamento mensal.
- Conversão entre texto monetário e centavos.
- Geração idempotente da mesada.
- Soma de água e virada da data local.
- Duração e agrupamento de exercícios.
- Validação das entidades e formulários.
- Mapeamento Firestore ↔ domínio.
- Estados dos view models.
- Sanitização de logs.
- Normalização e validação de URLs.
- Parser JSON-LD/Open Graph com fixtures.
- Lógica de retries e conflitos.

### Widget

- Tela Hoje em vazio, parcial, completo, offline e erro.
- Dynamic Type e overflow em cards.
- Adição rápida e desfazer água.
- Formulário monetário e erros.
- Estados de produto extraído/manual.
- Avaliação acessível por estrelas.
- Agenda com diferentes durações e eventos de dia inteiro.
- Permissão negada e caminho para Ajustes.

### Golden

Usar com moderação nos componentes centrais:

- tema claro e escuro;
- tamanhos de texto padrão e grande;
- cards de Hoje;
- estados vazios;
- item financeiro, livro e favorito.

Goldens não substituem testes semânticos e devem tolerar diferenças controladas de renderização.

### Integração

- Sign in with Apple e restauração de sessão.
- Primeiro registro de cada módulo.
- Criar gasto e atualizar saldo.
- Criar gratidão com foto.
- Gravar offline, fechar, abrir e sincronizar.
- Upload falhar e ser retomado.
- Conectar/revogar Google.
- Ler e criar evento em calendário de teste.
- Exportar e excluir conta.

Diálogos nativos, OAuth, Face ID, notificações e seletor de fotos exigem teste em dispositivo real, mesmo quando partes do fluxo são automatizadas.

### Security Rules

Com Firebase Emulator Suite:

- UID A não lê/escreve documentos de UID B.
- Usuário não autenticado não acessa dados.
- Campos desconhecidos, tipos inválidos e limites são recusados.
- Valores negativos e enums inválidos são recusados.
- Upload fora do caminho do UID é recusado.
- MIME/tamanho inválidos são recusados.
- Fluxos legítimos completos são aceitos.

### Backend e segurança

- SSRF contra IPv4/IPv6 privados e metadata endpoints.
- Redirect público → privado.
- DNS rebinding simulado.
- Timeout, resposta comprimida excessiva e HTML enorme.
- Content type falso de imagem.
- JSON-LD malformado, múltiplos produtos e moedas.
- Rate limit e autenticação.
- Logs não contêm URL completa ou HTML.

## Matriz manual no iPhone

Testar no aparelho real da usuária e em pelo menos um simulador de tamanho diferente:

- versão atual do iOS e versão mínima suportada;
- modo claro/escuro;
- texto padrão, grande e máximo de acessibilidade;
- VoiceOver;
- Reduzir Movimento e Aumentar Contraste;
- Wi-Fi, rede móvel, modo avião e conexão instável;
- pouco armazenamento;
- app encerrado durante upload;
- mudança de fuso/data e virada do mês;
- Face ID habilitado, cancelado e indisponível;
- permissão de Fotos limitada/negada;
- permissão de notificações negada;
- token Google expirado ou revogado;
- instalação limpa, atualização e reinstalação.

## Casos financeiros obrigatórios

- Mesada de R$ 500,00 e gasto de R$ 25,99 resultam em R$ 474,01.
- Editar R$ 25,99 para R$ 20,00 não duplica nenhum lançamento.
- Exclusão recalcula saldo.
- Mesada gerada duas vezes para a mesma competência cria uma única entrada.
- Dia 31 em mês curto usa regra documentada para o último dia do mês.
- Rollover positivo e sem rollover produzem saldos esperados.
- Mudança da configuração não altera silenciosamente mês fechado.
- Fuso UTC não move uma despesa noturna para outro dia local.

## Casos de Agenda obrigatórios

- Evento com horário e evento de dia inteiro.
- Mudança externa refletida por sync incremental.
- Token inválido `410` causa sync completa sem duplicar.
- Resposta perdida após criação não gera segundo evento.
- Evento sem permissão de escrita apresenta mensagem correta.
- Recorrência pergunta o alcance da edição/exclusão.
- Revogação Google não quebra outros módulos.

## Acessibilidade como aceite

- Controles essenciais alcançáveis pelo VoiceOver.
- Ordem de foco coerente.
- Botões somente com ícone possuem label.
- Progresso anuncia valor e unidade.
- Estrelas anunciam “N de 5”.
- Status não depende apenas de cor.
- Alvos possuem pelo menos 44 × 44 pontos.
- Nenhuma ação essencial exige somente arrastar.

## Performance e confiabilidade

Metas iniciais, medidas em build release no iPhone da usuária:

- Tela Hoje útil com dados locais em até 1 segundo após o shell do app.
- Toque de adição rápida refletido no próximo frame perceptível.
- Listas permanecem fluidas com 2.000 registros simples.
- Fotos não são decodificadas em resolução total nas listas.
- Nenhuma chamada de rede bloqueia navegação.
- Crash-free durante a semana de beta pessoal.

## Definition of Done

Uma história só está concluída quando:

- critérios de aceite passam;
- estados vazio, loading, erro, offline e permissão foram tratados;
- testes proporcionais ao risco foram adicionados;
- logs não carregam conteúdo pessoal;
- acessibilidade básica foi verificada;
- eventos/analytics novos foram explicitamente revisados;
- documentação e modelo de dados foram atualizados;
- `flutter analyze`, testes e build iOS passam;
- foi validada em aparelho físico quando toca API nativa.

## Gates de entrega

### Alpha pessoal

- fluxos principais funcionais;
- sem perda conhecida de dados;
- regras Firebase testadas;
- backups manuais possíveis;
- calendário pode permanecer atrás de feature flag.

### TestFlight estável

- política de privacidade;
- exportação/exclusão;
- OAuth estável fora do modo Testing de curta duração;
- App Check monitorado;
- todos os itens críticos e altos resolvidos;
- smoke test em build assinado.

