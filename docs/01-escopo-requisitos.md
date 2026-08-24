# Escopo e requisitos

## Convenções

- **MVP:** necessário para a primeira versão utilizável.
- **Depois:** incremento planejado, mas não bloqueia o uso inicial.
- **Futuro:** hipótese a validar antes de desenvolver.

## Requisitos transversais

### MVP

- Autenticar no app com Sign in with Apple.
- Manter a sessão entre aberturas do aplicativo.
- Funcionar em português do Brasil, fuso `America/Sao_Paulo` e moeda BRL.
- Permitir registros offline e sincronizá-los posteriormente.
- Exibir claramente estados de carregamento, erro e sincronização pendente.
- Permitir desfazer imediatamente exclusões simples.
- Pedir permissão de fotos, notificações, calendário e biometria apenas quando a função for usada.
- Respeitar tamanho dinâmico de texto, modo claro e áreas seguras do iPhone.
- Disponibilizar exclusão de conta e dados.

## Hoje

### Objetivo

Ser o ponto de entrada diário e permitir ações frequentes sem navegar por formulários.

### MVP

- Saudação adequada ao horário e data atual.
- Próximo compromisso e atalho para a agenda.
- Progresso de água e botões configuráveis de adição rápida.
- Atalhos para evacuação e exercício.
- Saldo restante da mesada do mês.
- Estado da gratidão do dia e chamada para registrar.
- Resumo compacto do dia; cards podem ser reordenados em uma versão posterior.

### Regras

- Falha na Agenda não bloqueia os demais cards.
- Registros adicionados offline aparecem imediatamente.
- O saldo sempre deriva dos lançamentos, nunca de um valor visual armazenado separadamente.

## Agenda

### MVP

- Conectar e desconectar a conta Google da integração de calendário.
- Listar compromissos do calendário primário.
- Visualizar mês e agenda do dia.
- Criar, editar e excluir eventos.
- Suportar título, descrição, início, fim, dia inteiro, recorrência simples, lembrete e cor.
- Abrir o evento no Google Agenda quando necessário.
- Identificar estado sincronizado, pendente ou com conflito.

### Depois

- Selecionar múltiplos calendários visíveis.
- Modo semanal.
- Convidados, localização e links de reunião.
- Categorias próprias mapeadas para cores/labels do Google.

### Restrições

- O app não deve duplicar todos os eventos no Firestore.
- Tokens Google não devem ser persistidos em texto puro.
- A exclusão precisa de confirmação quando o evento for recorrente.

## Água

### MVP

- Definir meta diária em mililitros.
- Adicionar quantidades rápidas, inicialmente 200 ml, 300 ml e 500 ml.
- Informar quantidade personalizada.
- Editar ou excluir um registro.
- Mostrar total e percentual do dia.
- Consultar histórico diário.

### Depois

- Personalizar recipientes favoritos.
- Lembretes em janelas de horário.
- Widget para a tela inicial do iPhone.

## Evacuações

### MVP

- Registrar data e horário, preenchidos com o momento atual.
- Adicionar observação opcional.
- Editar ou excluir o registro.
- Visualizar histórico em lista/calendário.

### Depois

- Escala de Bristol de 1 a 7, explicada visualmente e de forma neutra.
- Campos opcionais de desconforto e esforço.
- Exportação específica para consulta médica.

### Limite de responsabilidade

O módulo registra informações; não diagnostica, interpreta sintomas nem recomenda tratamento.

## Exercícios

### MVP

- Registrar atividade, duração, horário e observação opcional.
- Oferecer tipos recentes e favoritos.
- Editar ou excluir sessões.
- Exibir total de minutos por semana.

### Depois

- Intensidade percebida.
- Integração com Apple Health, após validação da utilidade e do tratamento de dados de saúde.
- Metas semanais opcionais.

## Finanças

### MVP

- Configurar valor da mesada mensal e dia de recebimento.
- Gerar uma entrada de mesada por competência de forma idempotente.
- Registrar receitas e despesas manualmente.
- Informar valor, data, categoria, descrição e observação opcional.
- Editar e excluir lançamentos.
- Mostrar recebido, gasto e saldo do mês.
- Filtrar por mês e categoria.
- Configurar se saldo anterior acumula; padrão inicial a confirmar.
- Armazenar valores como centavos inteiros.

### Depois

- Orçamentos por categoria.
- Anexar comprovante.
- Parcelamento e despesas recorrentes.
- Exportação CSV/PDF.

### Fora do escopo

- Open Finance, leitura de SMS, cartão ou conta bancária.
- Previsão de investimentos.

## Lista de compras

### MVP

- Criar listas nomeadas.
- Adicionar item com nome, quantidade e observação.
- Marcar e desmarcar como comprado.
- Reordenar e excluir itens.
- Preservar itens concluídos até limpeza explícita.

### Depois

- Compartilhamento de lista.
- Transformar favorito em item de compra.
- Agrupamento por mercado/categoria.

## Favoritos e desejos

### MVP

- Colar uma URL ou receber um link pelo menu Compartilhar do iOS.
- Tentar preencher nome, imagem, preço, moeda e loja.
- Permitir revisar e corrigir qualquer campo antes de salvar.
- Salvar mesmo quando a extração falhar.
- Abrir o link original.
- Marcar como desejado, comprado ou arquivado.
- Exibir total conhecido dos itens ativos sem misturar moedas.

### Depois

- Coleções e prioridade.
- Histórico de preço apenas quando houver fonte confiável.
- Alertas de redução de preço.

## Livros

### MVP

- Adicionar título, autor e capa por foto/galeria.
- Definir estado: quero ler, lendo, lido ou abandonado.
- Informar data de conclusão, avaliação de 1 a 5 estrelas e resenha.
- Filtrar e ordenar a biblioteca.
- Editar e excluir livros.

### Depois

- Busca por ISBN em fonte externa.
- Metas anuais e estatísticas.
- Múltiplas leituras do mesmo livro.

## Gratidão

### MVP

- Criar uma entrada por dia com texto, foto ou ambos.
- Editar a entrada do dia.
- Exibir histórico cronológico.
- Visualizar a foto em tela cheia.

### Depois

- Mais de uma entrada por dia.
- Recordações de “neste dia”.
- Exportação como diário.

## Configurações

### MVP

- Perfil Apple e conta Google da Agenda conectada.
- Meta de água e botões rápidos.
- Mesada, dia de recebimento e rollover.
- Calendário padrão.
- Preferências de notificações.
- Bloqueio com Face ID/Touch ID quando disponível.
- Exportar dados.
- Desconectar integração, sair e excluir conta.
