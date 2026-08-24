# Backlog e critérios de aceite

Este arquivo transforma o escopo em épicos e histórias rastreáveis. Critérios transversais da [Definition of Done](07-qualidade-testes.md#definition-of-done) valem para todas as histórias. As superfícies e estados de UI correspondentes estão nos [contratos das telas](12-contratos-telas.md).

## E0 — Fundação

### E0.1 — Conta Apple

Como usuária, quero entrar com Apple para recuperar meus dados com segurança.

- Login cria ou recupera o mesmo `uid`.
- Cancelamento não trava o app em loading.
- Sessão é restaurada após reinício.
- Sair remove estado sensível local sem excluir dados remotos.
- Erros não exibem tokens ou mensagens técnicas cruas.

### E0.2 — Uso offline

Como usuária, quero registrar sem internet para não perder o momento.

- Água, evacuação, exercício, gasto, livro e gratidão salvam em modo avião.
- A UI reflete a escrita imediatamente.
- Após encerrar/reabrir, o dado permanece visível.
- Ao reconectar, sincroniza sem duplicar.
- Falha é recuperável e claramente indicada.

### E0.3 — Proteção do app

- Face ID pode ser ativado/desativado.
- Conteúdo é coberto no app switcher.
- Cancelar biometria não revela conteúdo.
- Existe recuperação compatível com a segurança do aparelho.

## E1 — Hoje

### E1.1 — Resumo diário

- Mostra data, próximo evento, água, ações rápidas, saldo e gratidão.
- Falha de um card não impede os outros.
- Primeiro uso apresenta ações úteis.
- Tamanho grande de texto não oculta valores essenciais.

### E1.2 — Ações rápidas

- Água predefinida exige um toque no card/ação visível.
- Evacuação, exercício e gasto abrem direto no formulário correspondente.
- Feedback confirma a ação e permite desfazer quando seguro.

## E2 — Bem-estar

### E2.1 — Água

- Meta diária e quantidades rápidas são configuráveis.
- Quantidade precisa ser inteira e positiva.
- Total deriva dos logs do `localDate`.
- Editar/excluir atualiza o progresso.
- Virada do dia respeita `America/Sao_Paulo`.

### E2.2 — Evacuação

- Horário atual vem preenchido e pode ser editado.
- Observação e classificações são opcionais.
- Escala, se ativa, aceita apenas 1–7.
- Nenhum texto oferece diagnóstico.

### E2.3 — Exercício

- Tipo e duração são obrigatórios.
- Tipos recentes reduzem digitação.
- Histórico semanal soma minutos corretamente.
- Dias sem registro não são tratados como falha.

## E3 — Finanças

### E3.1 — Mesada

- Valor é persistido em centavos.
- Competência mensal é criada uma única vez.
- Regra para dia inexistente no mês usa o último dia.
- Alterar padrão não modifica período fechado sem confirmação.

### E3.2 — Gastos

- Valor é o primeiro campo e abre teclado numérico.
- Descrição e categoria são claras.
- Saldo é recalculado após criar, editar e excluir.
- Retry de criação não duplica o gasto.

### E3.3 — Rollover

- A usuária escolhe `não acumular` ou `acumular saldo positivo`.
- Saldo negativo não acumula no MVP.
- O resumo explica o valor trazido do mês anterior.
- Fechamento pode ser reproduzido pelos lançamentos.

### E3.4 — Lista de compras

- Item pode existir sem preço.
- Marcar comprado não exclui imediatamente.
- Itens podem ser reordenados.
- Limpeza de concluídos exige confirmação/desfazer.

## E4 — Agenda

### E4.1 — Conectar Google

- Integração é opcional e separada da conta Apple.
- Consentimento explica quais dados serão acessados.
- Revogar remove token/cache sem afetar dados próprios.
- Recusa mantém o restante do app utilizável.

### E4.2 — Visualizar eventos

- Calendários selecionados e suas cores aparecem.
- Mês e lista diária lidam com eventos de dia inteiro.
- Cache é identificado quando offline.
- Sync incremental não cria duplicatas.

### E4.3 — Editar agenda

- Criar exige início e fim válidos.
- Evento recorrente confirma alcance da mudança.
- Sem conexão preserva o rascunho em vez de prometer envio.
- Sem permissão de escrita explica como resolver.
- Resposta perdida e retry mantêm um único evento.

## E5 — Favoritos

### E5.1 — Cadastro manual

- URL válida é suficiente para começar.
- Nome, foto e preço podem ser preenchidos/corrigidos.
- Preço desconhecido permanece nulo, não zero.
- Link abre fora do app com confirmação normal do sistema.

### E5.2 — Compartilhar link

- Lume aparece no menu Compartilhar do iOS para URLs.
- Ao abrir, a URL permanece disponível mesmo offline.
- Conteúdo não suportado mostra erro sem fechar o app.

### E5.3 — Extração automática

- Somente usuária autenticada solicita extração.
- Resultado é marcado como não confirmado.
- Falha sempre permite cadastro manual.
- Backend bloqueia os cenários SSRF documentados.
- TikTok/Mercado Livre sem dados acessíveis não bloqueiam o fluxo.

## E6 — Livros

- Livro pode ser salvo sem capa/autor.
- Status aceita quero ler, lendo, lido e abandonado.
- Nota aceita somente 1–5 quando preenchida.
- Resenha preserva quebras de linha.
- Busca por título/autor funciona localmente nos itens carregados.
- Excluir livro trata também a capa sem deixar objeto órfão.

## E7 — Gratidão

- Entrada aceita texto, foto ou ambos, nunca vazia.
- MVP possui no máximo uma entrada por data.
- Rascunho não é perdido durante seleção de foto.
- Histórico ordena por data local.
- Excluir remove as fotos associadas após período recuperável.

## E8 — Privacidade e portabilidade

### E8.1 — Exportar

- Export inclui todos os módulos e mídia própria.
- Valores e datas têm formato documentado.
- Arquivo pertence apenas ao UID autenticado.
- Temporários expiram e são removidos.

### E8.2 — Excluir conta

- Fluxo inicia dentro do app.
- Oferece exportação antes da exclusão.
- Exige reautenticação e confirmação clara.
- Apaga Firestore, Storage, jobs, tokens e cache.
- Trata separadamente a decisão sobre eventos Google existentes.

## Bugs por severidade

- **Crítico:** perda/vazamento de dados, saldo incorreto, conta inacessível, evento duplicado em massa.
- **Alto:** fluxo principal indisponível, upload sem recuperação, exclusão incompleta, acessibilidade impeditiva.
- **Médio:** erro com contorno simples, layout quebrado em configuração menos comum.
- **Baixo:** detalhe visual ou texto sem impacto funcional.

Bugs críticos e altos bloqueiam TestFlight estável.
