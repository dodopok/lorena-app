# Plano do produto Lume

Este diretório é a fonte de verdade para o planejamento do aplicativo. O plano parte das seguintes decisões confirmadas:

- aplicativo pessoal, inicialmente para uma única usuária;
- uso principal em iPhone;
- implementação em Flutter;
- identidade visual delicada, acolhedora e predominantemente rosa;
- registros rápidos, funcionamento offline e sincronização segura;
- integração real com o Google Agenda, sem substituir o aplicativo do Google.

## Como ler

1. [Visão do produto](00-visao-produto.md)
2. [Escopo e requisitos](01-escopo-requisitos.md)
3. [Experiência e design](02-experiencia-design.md)
4. [Arquitetura técnica](03-arquitetura-tecnica.md)
5. [Modelo de dados](04-modelo-dados.md)
6. [Integrações](05-integracoes.md)
7. [Segurança e privacidade](06-seguranca-privacidade.md)
8. [Qualidade e testes](07-qualidade-testes.md)
9. [Roadmap e entregas](08-roadmap.md)
10. [Operação e distribuição](09-operacao-distribuicao.md)
11. [Backlog e critérios de aceite](10-backlog-aceite.md)
12. [Contratos das telas](12-contratos-telas.md)
13. [Componentes compartilhados](13-componentes-compartilhados.md)
14. [Decisões arquiteturais](adr/README.md)
15. [Referências oficiais](11-referencias.md)

## Status

O produto está na fase de planejamento. O repositório ainda não possui um projeto Flutter inicializado.

## Decisões já tomadas

| Decisão | Escolha |
|---|---|
| Plataforma inicial | iPhone |
| Framework | Flutter |
| Público inicial | Uma única usuária |
| Conta do app | Sign in with Apple |
| Integração de agenda | Conta Google separada |
| Persistência em nuvem | Firebase |
| Estratégia de uso | Offline-first com sincronização |
| Distribuição inicial | Instalação privada/TestFlight |
| Moeda inicial | Real brasileiro (BRL) |
| Idioma inicial | Português do Brasil |

## Questões que podem esperar até o refinamento

- nome público definitivo e ícone do aplicativo;
- valor padrão da meta diária de água;
- se o saldo da mesada acumula entre meses por padrão;
- quais calendários Google devem aparecer inicialmente;
- frequência e horários dos lembretes;
- uso de escala de Bristol no registro de evacuações;
- futura inclusão de outro usuário ou compartilhamento de dados.

Nenhuma dessas questões impede o início da fundação, do design system ou do protótipo navegável.
