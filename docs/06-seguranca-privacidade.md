# Segurança e privacidade

## Classificação dos dados

| Classe | Exemplos | Sensibilidade |
|---|---|---|
| Saúde e rotina | água, evacuações, exercícios | Alta |
| Financeiro | mesada, gastos, saldo | Alta |
| Diário e mídia | gratidão, fotos, resenhas | Alta |
| Agenda | títulos e horários | Alta |
| Compras | URLs, desejos e preços | Moderada |
| Técnico | versão, falhas e desempenho | Baixa se sanitizado |

O app não é médico nem financeiro regulado, mas os dados merecem proteção equivalente a conteúdo íntimo.

## Modelo de ameaça resumido

### Ameaças prioritárias

- Outro aplicativo/usuário acessar dados no backend.
- Conteúdo aparecer no app switcher ou em notificações.
- Token Google vazar em log ou armazenamento inadequado.
- URL maliciosa atingir rede interna pela função de extração.
- Foto reter localização EXIF.
- Exclusão incompleta deixar arquivos órfãos.
- Telemetria capturar texto, valores, URLs ou eventos.
- Aparelho perdido permitir abertura imediata do aplicativo.

### Controles

- Autenticação e regras por `uid`.
- Face ID opcional e proteção de tela em background.
- Keychain para credenciais.
- Sanitização de logs e Crashlytics.
- Pipeline SSRF descrito em [Integrações](05-integracoes.md).
- Remoção de metadados de imagens.
- Jobs idempotentes de exclusão e auditoria de órfãos.
- App Check com App Attest antes de produção.

## Firebase Security Rules

Princípio: negar tudo e liberar somente recursos explicitamente validados.

Regra conceitual:

```text
match /users/{uid}/{document=**} {
  allow read, write: if request.auth != null
                     && request.auth.uid == uid;
}
```

Na implementação, cada coleção terá validação de:

- campos permitidos;
- tipos;
- limites de tamanho;
- enums;
- datas plausíveis;
- inteiros positivos para água, duração e dinheiro;
- propriedade imutável;
- transições de estado válidas.

Não usar uma regra genérica `request.auth != null` para toda a base. Admin SDK ignora Security Rules; toda Cloud Function deve revalidar autenticação, autorização e entrada.

## Storage Rules

- Caminhos obrigatoriamente dentro de `users/{uid}`.
- Escrita e leitura somente pelo mesmo `uid`.
- Content types de imagem explicitamente permitidos.
- Limite de tamanho aplicado na regra e revalidado no backend.
- Downloads públicos desativados.
- Exportações com expiração e autorização curta.

## App Check

Ativar Firebase App Check com App Attest no ambiente de produção depois que o fluxo de desenvolvimento estiver estável. App Check complementa, mas não substitui, Authentication, Security Rules e validação de backend.

## Credenciais

- Credenciais Google ficam no Keychain e memória do processo.
- Não persistir access/refresh tokens em Firestore, Storage, analytics, crash reports ou arquivos exportados.
- Revogar autorização Google e limpar cache/token ao desconectar.
- Segredos de Cloud Functions ficam no Secret Manager.
- Rotacionar segredos após suspeita de vazamento.

## Privacidade no aparelho

- Cobrir conteúdo ao entrar em background para ocultar snapshots.
- Bloqueio por Face ID configurável.
- Notificações genéricas por padrão.
- Não ler a área de transferência automaticamente; importar apenas após ação.
- Limpar dados temporários e exports locais conforme ciclo documentado.
- Usar seletor limitado de Fotos quando disponível.

## Telemetria

### Permitido

- versão do app e iOS;
- tipo de dispositivo em nível técnico;
- stack trace sanitizado;
- duração de operações sem parâmetros pessoais;
- código de erro categórico;
- estado online/offline.

### Proibido

- texto de gratidão, resenha ou observação;
- valores, descrições ou categorias financeiras;
- título/descrição de eventos;
- URL completa de produtos;
- conteúdo ou nome de fotos;
- tokens, e-mail ou identificadores externos desnecessários.

Analytics de comportamento fica fora do MVP. Crashlytics somente será ativado após filtros e revisão de payloads.

## Retenção

| Dado | Política inicial |
|---|---|
| Registros pessoais | Até exclusão pela usuária |
| Cache Google Agenda | 6 meses anteriores e 12 futuros |
| HTML de produtos | Nunca persistir |
| Jobs de extração | Excluir após 30 dias ou antes |
| Logs técnicos | Até 30 dias |
| Tombstones | 30 dias antes da purga |
| Exports temporários | Horas, não dias |
| Backups | 30–90 dias, conforme custo e restauração |

## Exportação e exclusão

A usuária poderá:

1. exportar todos os dados;
2. desconectar o Google Agenda;
3. apagar conteúdos individuais;
4. apagar todos os dados e a conta pelo próprio app.

Exclusão total cobre:

- Firestore;
- Storage;
- exportações temporárias;
- tokens e cache local;
- jobs de backend;
- credencial Firebase após os dados dependentes.

O fluxo oferece exportação antes da confirmação e exige reautenticação. Eventos criados no Google são propriedade do calendário: ao desconectar/apagar, perguntar separadamente se a usuária quer mantê-los.

## Política de privacidade

Antes de distribuição externa, documentar:

- controlador e contato;
- categorias coletadas;
- finalidade de cada dado;
- provedores Firebase/Google/Apple;
- onde os dados são processados;
- retenção, exportação e exclusão;
- revogação da Agenda;
- ausência de anúncios, rastreamento e venda;
- tratamento de fotos e conteúdo sensível;
- idade mínima aplicável;
- data e histórico de alterações.

Também preencher as respostas de App Privacy no App Store Connect de acordo com o comportamento efetivo do binário, não apenas com a intenção do plano.

## Checklist antes de dados reais

- [ ] Regras Firestore e Storage negam acesso entre usuários.
- [ ] Emulator Suite cobre operações permitidas e negadas.
- [ ] Tokens não aparecem em logs ou crash reports.
- [ ] Face ID e proteção do app switcher foram testados.
- [ ] Imagens perdem EXIF/GPS.
- [ ] Função de URL bloqueia rede privada, redirects e respostas grandes.
- [ ] App Check está habilitado e monitorado em produção.
- [ ] Exclusão remove documentos e objetos órfãos.
- [ ] Exportação contém apenas os dados da usuária autenticada.
- [ ] Política de privacidade corresponde ao app.
- [ ] Backups possuem restauração testada.

