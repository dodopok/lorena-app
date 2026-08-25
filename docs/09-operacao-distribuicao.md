# Operação e distribuição

## Estratégia inicial

Como há uma única usuária em iPhone, a sequência recomendada é:

1. instalar builds de desenvolvimento no aparelho cadastrado durante o spike;
2. usar TestFlight para a alpha/beta recorrente;
3. avaliar App Store pública ou distribuição unlisted quando o app estiver estável.

TestFlight evita reinstalações manuais frequentes, mas builds expiram após 90 dias. Testers externos passam pelo fluxo de Beta App Review; testers internos precisam ser usuários do App Store Connect.

## Contas e ativos necessários

- Apple Developer Program ativo.
- App Store Connect com app, bundle ID e capabilities.
- Um único projeto Firebase compartilhado por dev/prod (`lume-13125`), incluindo Authentication, Firestore, Storage, Functions, App Check e Crashlytics.
- Um projeto Google Cloud compartilhado por dev/prod (`lume-app-506521` — “Lume App”), com Calendar API e OAuth consent screen.
- E-mail e URL para suporte/privacidade.
- Domínio simples para política de privacidade, se houver distribuição revisada.

## Bundle IDs e ambientes

Por decisão do projeto, dev e prod usarão o mesmo App ID/bundle ID iOS:

```text
com.dodopok.lume
```

O binário seleciona o perfil por configuração de build (flags, rótulo visual e integrações locais), mas dev e prod apontam para o mesmo backend e não podem ser instalados lado a lado no mesmo aparelho. A versão dev deve deixar claro que é um build de teste e que compartilha dados com prod; o modo local é o ambiente para dados fictícios. A equipe deve validar cuidadosamente que o build carregou a configuração pública compartilhada antes de autenticar.

O mesmo App ID também implica compartilhar capabilities e a identidade de assinatura Apple. Firebase, Storage, dados e Google Cloud serão compartilhados por dev e prod. O Firebase é `lume-13125`; o projeto Google da Agenda é `lume-app-506521` (“Lume App”). Dentro do projeto Google, usar client IDs/redirects distintos somente quando necessário e controlar os escopos, contas de teste e configuração selecionada no build. Como não há isolamento de backend entre os builds, testes destrutivos devem usar o modo `local` com emuladores ou registros claramente marcados.

## OAuth Google

O modo Testing do Google é adequado ao spike, mas pode produzir autorizações de curta duração para escopos sensíveis. Para uso diário estável:

- configurar consent screen corretamente;
- usar menor conjunto de escopos;
- adicionar a conta como test user enquanto aplicável;
- preparar o app para estado Production;
- cumprir verificação caso o Google a exija para a configuração/distribuição escolhida;
- oferecer página de privacidade e explicar revogação/exclusão.

Não prometer uma conexão permanente com Agenda até validar o fluxo no projeto Google/Firebase compartilhado real.

## CI/CD

Pipeline mínimo por pull request:

1. format check;
2. `npm --prefix functions test`;
3. `flutter analyze`;
4. testes unitários e de widgets;
5. testes de Security Rules;
6. build iOS sem assinatura quando aplicável;
7. verificação de segredos/arquivos proibidos.

Pipeline de release:

1. tag/versionamento;
2. testes completos;
3. build assinado com secrets do CI;
4. upload para TestFlight;
5. release notes sem dados pessoais;
6. smoke test no build distribuído;
7. promoção manual.

Nenhuma entrega em produção é automática no MVP.

## Versionamento

- Semantic Versioning para comunicação do projeto.
- Build number sempre crescente para App Store Connect.
- Migrações de schema identificadas e compatíveis com rollback de app quando possível.
- Feature flags locais para Agenda, extração e funções ainda experimentais.

## Observabilidade operacional

Painel mínimo:

- crashes e regressões por versão;
- erros de autenticação por código, sem e-mail;
- falhas de sincronização Firestore;
- falhas de upload;
- Calendar API por status HTTP categórico;
- extração de links: sucesso/fallback/timeout, sem URL completa;
- custos e cotas de Firestore, Storage e Functions.

Configurar alertas de orçamento no Google Cloud/Firebase antes de ativar Functions e Storage em produção.

## Backup e recuperação

- Habilitar backup/PITR quando dados reais justificarem o plano de cobrança.
- Manter retenção de 30–90 dias conforme custo.
- Documentar restauração em projeto isolado.
- Testar restauração antes do TestFlight estável e periodicamente.
- A exportação da usuária complementa, mas não substitui, backup operacional.

Runbook de perda percebida:

1. colocar novas escritas de manutenção em pausa, se necessário;
2. confirmar UID, ambiente e período afetado;
3. verificar cache/local e tombstones;
4. restaurar em ambiente separado;
5. comparar e recuperar apenas documentos necessários;
6. registrar causa sem copiar conteúdo pessoal para tickets/logs.

## Suporte pessoal

Mesmo com uma usuária, oferecer em Configurações:

- versão/build;
- estado de sincronização;
- última sincronização da Agenda;
- tentar novamente uploads pendentes;
- exportar diagnóstico sanitizado;
- contato de suporte;
- política de privacidade;
- exportar e excluir dados.

## Checklist TestFlight

- [ ] Ícone e launch screen finais ou claramente beta.
- [ ] Sign in with Apple funcionando no build distribuído.
- [ ] Conta Google e redirect URI de produção configurados.
- [ ] Textos de permissão claros em português.
- [ ] Política de privacidade acessível.
- [ ] Exportação e exclusão testadas.
- [ ] App Privacy preenchido conforme SDKs reais.
- [ ] Crashlytics sanitizado.
- [ ] Regras Firebase e Storage publicadas/testadas.
- [ ] App Check configurado sem bloquear o build por engano.
- [ ] Modo avião e reconexão testados.
- [ ] Backup e restauração validados.
- [ ] Notas do beta explicam limitações conhecidas.

## Critério para publicação mais ampla

- Quatro semanas de beta pessoal estável.
- Nenhum bug crítico aberto.
- Fluxos Google fora de modo temporário de desenvolvimento.
- Política de privacidade revisada.
- Dados declarados corretamente no App Store Connect.
- Conta e exclusão cumprem as diretrizes Apple vigentes.
- Custos monitorados e limitados.
- Canal de suporte definido.
