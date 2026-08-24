# Visão do produto

## Resumo

Lume é um aplicativo pessoal para iPhone que reúne agenda, autocuidado, organização financeira, desejos de compra, leituras e gratidão em um único espaço acolhedor. A proposta não é maximizar produtividade: é reduzir o esforço de se organizar e tornar pequenos registros cotidianos agradáveis.

## Problema

Hoje essas informações tendem a ficar espalhadas entre Google Agenda, notas, aplicativos de água, planilhas, links enviados para si mesma e fotos. Essa fragmentação aumenta a fricção e faz com que registros simples sejam abandonados.

## Proposta de valor

> Um cantinho pessoal, bonito e rápido, onde a usuária acompanha o dia, cuida de si, organiza o dinheiro e guarda aquilo que importa.

## Usuária inicial

- Uma única pessoa, usando o próprio iPhone.
- Possui conta Google e já utiliza o Google Agenda.
- Recebe uma mesada mensal e deseja entender quanto ainda pode gastar.
- Guarda links de produtos de diferentes lojas.
- Valoriza personalização, fotos, rosa e uma experiência afetiva.
- Prefere ações rápidas a formulários extensos.

## Trabalhos a realizar

- Ao abrir o app de manhã, quero entender meu dia sem consultar vários lugares.
- Quando beber água, quero registrar em um toque.
- Quando me exercitar ou evacuar, quero registrar sem constrangimento ou burocracia.
- Quando gastar, quero saber imediatamente quanto ainda resta da mesada.
- Quando encontrar algo interessante em qualquer loja, quero guardar o link com contexto visual.
- Quando terminar um livro, quero guardar a lembrança e o que achei dele.
- No fim do dia, quero registrar algo bom em texto ou foto.

## Princípios do produto

### Delicadeza, não infantilização

Rosa, formas suaves e mensagens acolhedoras devem transmitir personalidade sem parecer um aplicativo infantil.

### Registro em poucos segundos

A ação mais comum de cada módulo deve estar acessível em no máximo dois toques a partir da tela Hoje.

### Sem culpa

O app não deve usar mensagens punitivas, sequências perdidas ou alertas vermelhos para hábitos pessoais. Ausência de registro é neutra.

### Dados pertencem à usuária

Deve ser possível visualizar, exportar e excluir os dados. Conteúdo financeiro e de saúde não será utilizado para publicidade ou telemetria detalhada.

### Offline por padrão

Registros cotidianos devem funcionar sem conexão. Integrações externas podem indicar que aguardam sincronização.

### Crescimento consciente

O desenho inicial atende uma usuária, mas dados e regras serão particionados por `userId` para não bloquear uma futura versão multiusuário.

## Métricas de sucesso do produto

Como o uso é pessoal, métricas devem ser locais ou agregadas e respeitar a privacidade.

- Tempo mediano para registrar água inferior a 3 segundos.
- Tempo mediano para registrar um gasto inferior a 15 segundos.
- Sincronização de eventos sem duplicações observáveis.
- Zero perda de registros após uso offline e reconexão.
- Uso da tela Hoje em pelo menos quatro dias de uma semana de teste.
- Avaliação subjetiva da usuária: “bonito”, “fácil” e “quero continuar usando”.

## Fora do escopo inicial

- Conexão automática com bancos ou Open Finance.
- Pagamentos, transferências ou compra dentro do app.
- Diagnóstico médico ou recomendações clínicas.
- Rede social, ranking ou compartilhamento público.
- Versão para Android, web ou Apple Watch no primeiro lançamento.
- Inteligência artificial para interpretar dados pessoais.
- Rastreamento de preço contínuo em lojas.
- Colaboração em listas ou finanças por duas pessoas.

## Riscos de produto

| Risco | Tratamento |
|---|---|
| Excesso de funcionalidades | Entregar por fatias e manter a tela Hoje simples. |
| Registro virar obrigação | Linguagem neutra, lembretes opcionais e sem punição por falhas. |
| Captura de produto falhar | Sempre oferecer edição manual. |
| Agenda duplicar eventos | Idempotência, IDs externos e testes de sincronização. |
| App parecer “rosa demais” | Rosa como identidade; lavanda, menta e creme como apoio. |
| Dados sensíveis expostos | Regras por usuário, biometria opcional e telemetria sem conteúdo. |
