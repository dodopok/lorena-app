# Revisão de UI e UX — 5 de setembro de 2026

## Implementado

- Tema único para o app e os componentes: modo escuro com textos, campos, cards e ações próprios, sem herdar o tema claro.
- Nunito empacotada nos pesos 400, 600 e 700, com licença e origem em `assets/fonts/nunito`.
- Boas-vindas com composição visual própria, apresentação mais curta e rolagem para telas compactas.
- Cabeçalhos com hierarquia mais clara e subtítulos fora da altura fixa da barra; conteúdo limitado a 720 px em telas largas.
- Água com valor e meta visíveis, progresso animado e ícone de confirmação ao atingir a meta.
- Entradas escalonadas na tela Hoje, transições entre abas e feedback de pressão nos cards interativos e ações rápidas. Movimento reduzido respeitado nesses efeitos e nas sheets.
- Abas preservam estado, filtros e rolagem. Destinos são montados na primeira visita e animações ficam suspensas nas abas inativas.
- Atalhos de Hoje selecionam a aba correspondente sem empilhar outro shell.
- “Ver tudo” em Bem-estar abre um histórico completo de água, agrupado por dia, incluindo registros anteriores quando não há água hoje.
- Exclusão e desfazer no histórico usam uma referência estável ao controller, sem depender da linha removida.
- Textos de navegação podem crescer; cards de compromisso e ações rápidas não impõem altura fixa.
- Agenda indisponível explica o estado sem exibir flags de implementação à usuária.

- Editor de gratidão compartilhado entre Hoje e Cantinho, com foto, rascunho por conta e data, recuperação após fechamento e descarte explícito. Editar o texto preserva a imagem original; falhar ao salvar não remove fotos.
- Histórico completo de gratidão com lista sob demanda e edição de registros anteriores à prévia de dez dias.
- Etapas concluídas do onboarding são guardadas antes de avançar. Falhas mantêm a configuração aberta; a conclusão só libera o app depois da persistência e remove o rascunho.
- Rotas específicas abrem o editor ou a coleção correspondente e validam IDs ausentes. A sessão controla a transição após login/onboarding, preservando o destino sem abrir o mesmo editor duas vezes.
- Cancelar o login Apple permanece na tela sem alerta de erro. A versão sem autenticação externa identifica o uso neste aparelho com textos próprios.
- Cabeçalhos de seção se reorganizam em telas estreitas ou com texto ampliado. Seletores usam a largura disponível; o botão de foto mantém rótulo acessível sem forçar texto em uma caixa pequena.
- Textos de ajuda e erro podem ocupar até três linhas, evitando o corte encontrado no onboarding nativo.
- Formulários e telas iniciais permitem rolagem; sheets dispensam o teclado ao arrastar e aguardam a remoção real da rota antes de liberar controllers.
- Calendários, relógios e ações nativas em português brasileiro, com horários em 24 horas.
- Registro manual de água permite data e horário. Erros mantêm o formulário preenchido e a tentativa seguinte não duplica o registro.
- Mesadas e ajustes conservam seu tipo durante a edição; o lançamento é atualizado no mesmo ID e período.
- Agenda preserva intervalos de vários dias, recorrências personalizadas, configuração de lembretes do Google, cor e fuso. A escolha de recorrência gera RRULE válida. A atualização usa PATCH, preservando campos externos que o editor não representa, e envia remoções explícitas dos campos editáveis. Semântica conferida na [referência oficial do Google Calendar](https://developers.google.com/workspace/calendar/api/v3/reference/events/patch).
- Escritas locais de snapshots e rascunhos são ordenadas e verificam a confirmação de armazenamento. Água, gratidão, transações e conclusão do onboarding restauram o estado anterior quando sua escrita falha.

## Validação

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub --reporter expanded`: 127 testes aprovados na execução completa. Após a revisão nativa, os 24 testes de rotas/onboarding passaram novamente com a quebra de linha dos textos de ajuda.
- `dart format --output=none --set-exit-if-changed lib test` e `git diff --check`: sem alterações pendentes de formatação ou erros de whitespace.
- `flutter build ios --simulator --no-codesign`: concluído; fontes e licença confirmadas no bundle de `build/ios/iphonesimulator/Runner.app`.

Os testes em `test/app/experience_test.dart` cobrem atalhos sem duplicação de shell, preservação de busca e rolagem, histórico de dias anteriores e exclusão/desfazer. Hoje e boas-vindas são verificados em 320 × 640 com texto a 160%, nos temas claro e escuro.

Os testes de componentes verificam feedback de pressão sem alterar dimensões e sem escala com Reduzir Movimento, além dos tokens do tema escuro. Foram renderizadas e inspecionadas as telas Hoje, boas-vindas, onboarding, Cantinho e registro manual de água em ambos os temas a 393 × 852, usando as fontes e os ícones locais. Os cabeçalhos tiveram o alinhamento entre título e ação ajustado após a inspeção visual.

Os testes adicionais em `test/app` cobrem rascunhos, perda de armazenamento, fotos preservadas, reabertura do onboarding, cancelamento de login, destino após autenticação, edição de mesada/ajuste, registros antigos e seletores de data/hora em português. Sete formulários de criação são verificados em 320 × 640 com texto a 160% e inset de teclado. O editor da Agenda também é verificado com texto ampliado, usando um gateway em memória; a serialização de eventos e limpeza de campos têm testes separados.

No simulador iOS 26.1 criado para esta revisão (`Lume UI Review`, iPhone 17 Pro), o build local abriu, percorreu boas-vindas/entrada/onboarding e chegou à tela Hoje. O teclado numérico foi conferido na configuração e a adição rápida elevou o total de água de 0 para 200 ml com confirmação de 10%. Nenhuma conta externa foi conectada.

Isso não substitui a validação de VoiceOver, biometria, fotos, OAuth, tráfego real da Agenda e gestos em iPhone físico.

## Ainda precisa ser finalizado

### Produto e fluxos

- Finalizar o isolamento de dados entre sessões/contas e a reconciliação offline: o snapshot local ainda é único, e sair da conta não limpa todas as coleções em memória. Não considerar troca de conta e conflitos remotos validados.
- Completar históricos de evacuação e exercício, o resumo semanal e o reaproveitamento de tipos recentes, conforme S06/S09.
- Estender a recuperação de falhas aos demais comandos de criação/edição/exclusão e fotos de livros/desejos. As correções de rollback acima não representam uma transação global para todas as mutações concorrentes.
- Validar idempotência e recuperação de criação de eventos após perda da resposta de rede, além de conflito por ETag com o Google real.
- Verificar entrada dos deep links pelo iOS. Os testes atuais cobrem o roteamento interno e a apresentação dos destinos.
- Ampliar a revisão de acessibilidade para configurações, listas preenchidas, VoiceOver e ações do sistema em aparelho.

### Integrações e distribuição

Continuam os gates documentados em [Credenciais e integrações](14-credenciais-e-integracoes.md): OAuth iOS da Agenda, deploy e validação integrada da extração de links, associação/assinatura do App Group da Share Extension e testes em aparelho físico. O estado externo desses serviços não foi alterado nem verificado nesta revisão.

Para TestFlight, concluir assinatura, privacidade, metadados e os testes de recuperação e integrações descritos no [roadmap](08-roadmap.md).
