# Lume

Aplicativo pessoal para iPhone, nativo em Swift/SwiftUI, que reúne agenda, autocuidado, finanças, leituras, desejos e gratidão em um único espaço acolhedor.

> **Status:** reescrita nativa completa da proposta original (que era em Flutter — ver histórico do git para essa versão). Todos os módulos abaixo existem como telas reais; nada foi validado em dispositivo físico ainda porque foi escrito sem acesso a um Mac/Xcode. Veja [SETUP.md](SETUP.md) para gerar o projeto e rodar.

## Visão rápida

O Lume reduz a fricção de pequenos registros cotidianos. A tela **Hoje** é o ponto de entrada: próximo compromisso, água, ações rápidas de um toque e o quanto ainda está disponível até a próxima mesada. Os módulos mais completos ficam nas outras quatro abas, sem virar painel de produtividade.

Princípios do produto:

- registros rápidos, com as ações frequentes acessíveis em até dois toques;
- tudo funciona offline — os dados ficam no aparelho até ela escolher sincronizar;
- linguagem acolhedora e sem culpa (o Banheiro é só contagem, por exemplo — nada de escala, nada de observação);
- privacidade por padrão: Face ID opcional, exportação e exclusão de dados a qualquer momento;
- identidade tátil e quente — rosa queimado sobre papel morno, Liquid Glass, sem infantilizar.

## Módulos

- **Hoje** — saudação, próximo compromisso, água (com log de um toque), grade "um toque" (Banheiro/Exercício/Gasto) e o saldo disponível até a mesada;
- **Agenda** — visão dia/semana/mês, categorias coloridas, lembrete de anotar gasto após um compromisso, e leitura (somente leitura) dos eventos do Calendário do iPhone via EventKit — inclui contas Google já configuradas no aparelho, sem OAuth próprio;
- **Bem-estar** — água, banheiro (contagem semanal) e exercícios num só lugar;
- **Finanças** — saldo disponível, categorias, lista de gastos por dia, lançamento rápido, lista de compras e adições avulsas de dinheiro;
- **Cantinho** — três abas: Gratidão (texto + foto, rascunho salvo automaticamente), Livros (biblioteca com progresso de leitura, busca via Google Books) e Filmes/Séries (status assistindo/assistido/quero assistir);
- **Desejos** — colar um link de produto e deixar nome, preço e imagem se preencherem sozinhos (LinkPresentation + leitura best-effort da página), com aviso de queda de preço;
- **Compartilhar** (Share Extension) — mandar um link de outro app direto para os Desejos do Lume;
- **Ajustes** — perfil, metas (água/mesada), lembretes, Face ID, exportação de dados em JSON e apagar tudo;
- **Tela bloqueada** — Live Activity/Dynamic Island da água, com "+300" funcionando direto da ilha dinâmica.

Fora de escopo por enquanto: sincronização entre aparelhos/iCloud, notificações push, Apple Watch, Android.

## Decisões técnicas

| Tema | Escolha |
|---|---|
| Plataforma | iPhone, iOS 26+ |
| Aplicativo | Swift 6 / SwiftUI nativo, sem framework cross-platform |
| UI | Liquid Glass real (`.glassEffect`) para chrome/controles; `Material` para cards de conteúdo |
| Dados | SwiftData, armazenado no App Group local (`group.com.dodopok.lume`) |
| Conta | Sign in with Apple opcional — "usar só neste iPhone" é o caminho padrão |
| Agenda | EventKit (Calendário do iPhone), leitura apenas — nenhum backend próprio |
| Backend | Nenhum. Tudo local; exportação manual em JSON quando ela quiser uma cópia |
| Notificações | Locais (UserNotifications), sem push |
| Live Activity | ActivityKit, atualizada também por um App Intent rodando na Dynamic Island |
| Idioma | Português do Brasil fixo (sem i18n) |
| Projeto Xcode | Gerado via [XcodeGen](https://github.com/yonaskolb/XcodeGen) a partir de `project.yml` |

## Estrutura

```
project.yml       — spec do XcodeGen (fonte da verdade do projeto Xcode)
Lume.xcodeproj/    — projeto gerado (regenerável com `xcodegen generate`)
Lume/              — app target: Features/, Design/, Services/, App/
LumeWidgets/       — extensão de widget: Live Activity + Dynamic Island
LumeShare/         — Share Extension (mandar links pro Lume de outros apps)
Shared/            — modelos SwiftData e utilitários compilados nos três alvos
SETUP.md           — como gerar o projeto e rodar
```

## Rodando o projeto

Veja [SETUP.md](SETUP.md) — resumo: `brew install xcodegen`, `xcodegen generate`, abrir `Lume.xcodeproj`, ajustar o Team em cada target e rodar.
