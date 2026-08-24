# Roadmap e entregas

## Estratégia

O MVP 1.0 cobre todos os desejos originais, mas será construído em fatias utilizáveis. A primeira alpha não precisa esperar Agenda e extração automática de produtos.

Estimativas abaixo são relativas e servem para ordem de grandeza. Um desenvolvedor solo em tempo parcial deve recalibrá-las após o spike técnico.

## Fase 0 — Fundação e redução de risco

**Resultado:** esqueleto seguro rodando em iPhone físico.

- Inicializar Flutter/iOS e flavors `dev`/`prod`.
- Configurar o projeto Firebase compartilhado e o modo local com Emulator Suite; dev e prod usam o mesmo backend.
- Implementar Sign in with Apple.
- Provar Google Sign-In + leitura/criação de evento.
- Provar Firestore offline.
- Provar upload privado de foto.
- Provar Face ID e notificação local.
- Criar Security Rules e testes no Emulator Suite.
- Definir design tokens e componentes essenciais.

**Tamanho:** L. **Gate:** todos os spikes funcionam no iPhone da usuária.

## Fase 1 — Primeira fatia diária

**Resultado:** app já útil todos os dias.

- Onboarding mínimo.
- Tela Hoje.
- Água com meta, adição rápida, histórico e desfazer.
- Gratidão em texto.
- Configurações básicas.
- Estados offline/sincronizando.
- Cobertura do app switcher e biometria opcional.

**Tamanho:** M. **Gate:** a usuária usa por sete dias sem perda de dados.

## Fase 2 — Bem-estar e fotos

**Resultado:** autocuidado completo do MVP.

- Evacuações com horário/nota e campos opcionais.
- Exercícios com tipo e duração.
- Resumos semanais simples.
- Fotos na gratidão.
- Fila de uploads e retries.
- Lembretes locais opcionais.

**Tamanho:** M.

## Fase 3 — Finanças

**Resultado:** controle confiável da mesada.

- Configuração da mesada e dia mensal.
- Períodos e rollover.
- Receitas, gastos, ajustes e categorias.
- Saldo e resumo por categoria.
- Filtros e fechamento mensal.
- Lista de compras simples.
- Testes extensivos de moeda, fuso e idempotência.

**Tamanho:** L. **Gate:** dois fechamentos mensais simulados sem divergência.

## Fase 4 — Google Agenda

**Resultado:** compromissos reais dentro do app.

- Consentimento Google separado.
- Seleção de calendários.
- Cache e sincronização incremental.
- Mês e agenda diária.
- Criar/editar/excluir evento online.
- Eventos de dia inteiro, recorrência simples, lembrete e cor.
- Revogação e reautorização.

**Tamanho:** L. **Gate:** zero duplicações nos cenários de retry e reconexão.

## Fase 5 — Cantinho e desejos

**Resultado:** acervo afetivo e de compras completo.

- Biblioteca, capa, status, estrelas e resenha.
- Histórico de gratidão com fotos.
- Favoritos manuais com URL, nome, foto e preço.
- Share Extension para receber links.
- Estados comprado/arquivado e totais conhecidos.

**Tamanho:** L.

## Fase 6 — Links inteligentes e lançamento

**Resultado:** MVP 1.0 polido em TestFlight.

- Cloud Function segura de extração.
- JSON-LD/Open Graph e fallback manual.
- Testes com links reais de TikTok Shop e Mercado Livre.
- Exportação completa e exclusão da conta.
- Política de privacidade e App Privacy.
- App Check em enforcement após monitoramento.
- Testes de acessibilidade, segurança e recuperação.
- Ícone, screenshots e metadados de distribuição.

**Tamanho:** L.

## Depois do MVP

Priorizar somente com evidência de uso:

- widgets/App Intents;
- Apple Health;
- busca por ISBN;
- múltiplas gratidões diárias;
- relatórios financeiros avançados;
- histórico de preços;
- compartilhamento com o marido;
- Android;
- temas personalizados.

## Dependências críticas

| Item | Depende de |
|---|---|
| Dados reais | Auth + Rules + exclusão mínima |
| Fotos | Storage Rules + fila de upload |
| Agenda | OAuth Google + projeto Cloud + aparelho físico |
| Share Extension | App Groups + projeto iOS assinado |
| Extração de links | Functions + billing + controles SSRF |
| TestFlight | Apple Developer + assinatura + privacidade |
| App Store/Unlisted | Review + OAuth pronto para produção |

## Backlog por prioridade

### P0 — bloqueia MVP

- Segurança por UID.
- Autenticação e recuperação de sessão.
- Hoje e registros pedidos.
- Cálculo financeiro correto.
- Agenda sem duplicações.
- Edição manual de favoritos.
- Exportação/exclusão.
- Acessibilidade essencial.

### P1 — importante

- Extração automática de links.
- Lembretes configuráveis.
- Face ID.
- Fotos e thumbnails.
- Filtros e resumos.
- Share Extension.

### P2 — refinamento

- Personalização/reordenação de cards.
- Widgets e atalhos.
- Estatísticas avançadas.
- Apple Health.
- Novos temas.

## Critério de sucesso da beta

Depois de quatro semanas de uso real:

- a usuária escolhe continuar usando espontaneamente;
- os registros mais frequentes continuam rápidos;
- não houve perda ou duplicação de dados;
- notificações não são percebidas como incômodas;
- saldo mensal confere com os lançamentos;
- a estética é aprovada sem pedidos de reformulação estrutural;
- os módulos pouco usados podem ser simplificados antes de novas funções.
