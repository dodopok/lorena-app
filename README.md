# Lume

Aplicativo pessoal para iPhone, planejado em Flutter, que reúne agenda, autocuidado, finanças, leituras, desejos e gratidão em um único espaço acolhedor.

> **Status:** planejamento. O nome público definitivo e o ícone ainda estão em refinamento; “Lume” é o nome de trabalho usado neste repositório. O projeto Flutter ainda não foi inicializado.

## Visão rápida

O Lume quer reduzir a fricção de pequenos registros cotidianos. A tela **Hoje** será o ponto de entrada para consultar o dia, adicionar água, registrar autocuidado, acompanhar a mesada e guardar uma gratidão. Os módulos mais completos ficam disponíveis na navegação principal, sem transformar o aplicativo em um painel de produtividade.

Princípios do produto:

- registros rápidos, com as ações frequentes acessíveis em até dois toques;
- funcionamento offline para os dados próprios, com sincronização posterior;
- linguagem acolhedora e sem culpa;
- privacidade por padrão, com exportação e exclusão dos dados;
- identidade delicada, predominantemente rosa, sem infantilizar a experiência.

## Escopo do MVP

- **Hoje:** resumo diário, próximo compromisso, progresso de água, ações rápidas, saldo mensal e gratidão do dia;
- **Agenda:** conexão opcional com o Google Agenda para visualizar e editar compromissos;
- **Bem-estar:** água, evacuações e exercícios registrados manualmente;
- **Finanças:** mesada, receitas, despesas, categorias, saldo mensal e lista de compras;
- **Favoritos e desejos:** links de produtos, revisão manual, imagem, preço e estados comprado/arquivado;
- **Livros:** biblioteca, capa, status de leitura, avaliação e resenha;
- **Gratidão:** uma entrada diária com texto, foto ou ambos;
- **Conta e privacidade:** Sign in with Apple, bloqueio biométrico opcional, uso offline, exportação e exclusão.

Integrações como HealthKit, Open Finance, pagamentos, Apple Watch, Android, colaboração entre usuários e rastreamento contínuo de preços ficam fora do primeiro lançamento.

## Decisões atuais

| Tema | Escolha |
|---|---|
| Plataforma inicial | iPhone |
| Aplicativo | Flutter/Dart |
| Conta do app | Sign in with Apple via Firebase Authentication |
| Agenda | Conta Google separada e opcional |
| Backend | Firebase Authentication, Firestore, Storage e Functions pontuais |
| Offline | Persistência offline do Firestore para dados próprios |
| Cache operacional | SQLite/Drift para Agenda, rascunhos e fila de fotos |
| Idioma e localização | Português do Brasil, `America/Sao_Paulo` e BRL |
| Distribuição inicial | Builds privadas e TestFlight |

## Documentação

O [plano completo do produto](docs/README.md) é a fonte de verdade para escopo, arquitetura e execução.

### Produto

- [Visão do produto](docs/00-visao-produto.md)
- [Escopo e requisitos](docs/01-escopo-requisitos.md)
- [Experiência e design](docs/02-experiencia-design.md)
- [Roadmap e entregas](docs/08-roadmap.md)
- [Backlog e critérios de aceite](docs/10-backlog-aceite.md)

### Engenharia

- [Arquitetura técnica](docs/03-arquitetura-tecnica.md)
- [Modelo de dados](docs/04-modelo-dados.md)
- [Integrações](docs/05-integracoes.md)
- [Segurança e privacidade](docs/06-seguranca-privacidade.md)
- [Qualidade e testes](docs/07-qualidade-testes.md)

### Operação

- [Operação e distribuição](docs/09-operacao-distribuicao.md)
- [Referências oficiais](docs/11-referencias.md)
- [Decisões arquiteturais (ADRs)](docs/adr/README.md)

## Roadmap resumido

1. **Fundação:** inicializar Flutter/iOS, ambientes Firebase, autenticação, offline, fotos, biometria e design system.
2. **Primeira fatia diária:** onboarding, tela Hoje, água, gratidão em texto e configurações básicas.
3. **Bem-estar:** evacuações, exercícios, fotos e lembretes locais opcionais.
4. **Finanças:** mesada, lançamentos, rollover, saldo e lista de compras.
5. **Google Agenda:** calendários, cache, sincronização incremental e edição de eventos.
6. **Cantinho e lançamento:** livros, favoritos, Share Extension, extração segura de links, portabilidade e TestFlight.

Consulte o [roadmap detalhado](docs/08-roadmap.md) e os [critérios de aceite](docs/10-backlog-aceite.md) antes de iniciar uma entrega.

## Estado do repositório

Neste momento, o repositório contém a documentação de discovery e planejamento. Ainda não há `pubspec.yaml`, código em `lib/`, configuração Firebase ou pipeline de CI/CD.

A implementação deve começar pela Fase 0, com os spikes descritos em [Arquitetura técnica](docs/03-arquitetura-tecnica.md#decisoes-que-exigem-spike-tecnico) e os gates de segurança descritos em [Segurança e privacidade](docs/06-seguranca-privacidade.md).

## Critério de sucesso da beta

Após quatro semanas de uso real, a usuária deve conseguir continuar usando o Lume espontaneamente, sem perda ou duplicação de dados, com registros frequentes rápidos, saldo mensal confiável, notificações não invasivas e uma experiência visual aprovada sem reformulação estrutural.
