# Credenciais e integrações

Guia operacional para criar, configurar e validar as contas e credenciais do Lume. Ele complementa [Arquitetura técnica](03-arquitetura-tecnica.md), [Integrações](05-integracoes.md), [Segurança e privacidade](06-seguranca-privacidade.md) e [Operação e distribuição](09-operacao-distribuicao.md).

O princípio deste documento é simples: uma credencial que dá acesso a dados ou que pode gerar custo nunca deve ser embutida no aplicativo, em um commit ou em um ticket. Arquivos de configuração públicos do Firebase podem estar no binário; eles identificam um projeto, mas não substituem Authentication, Security Rules, App Check ou autorização de backend.

## 1. Ambientes, nomenclatura e inventário

Manter três perfis operacionais. `local` é isolado por emuladores/mocks; `dev` e `prod` são builds diferentes sobre o mesmo backend compartilhado e o mesmo app/bundle ID:

| Ambiente | Uso | Dados permitidos | Identificadores sugeridos |
|---|---|---|---|
| `local` | Emuladores, mocks e desenvolvimento | Dados fictícios | bundle real, com Firebase Emulator/config local |
| `dev` | Teste em aparelho e eventualmente TestFlight interno | Mesmos dados do backend compartilhado; testes destrutivos só no modo `local` | bundle ID compartilhado |
| `prod` | Dados reais e distribuição privada | Dados reais da usuária | bundle ID compartilhado |

O mesmo bundle ID não permite prometer instalação lado a lado: instalar um build dev, um build TestFlight ou um build prod pode substituir/sobrescrever a instalação existente e os dados locais/cache do app. A equipe deve selecionar explicitamente o ambiente no build/configuração e assumir que a usuária não poderá manter os dois ambientes abertos no mesmo aparelho. Por decisão do projeto, dev e prod usam o mesmo projeto Firebase `lume-13125`, o mesmo bucket, a mesma base e os mesmos dados, além do mesmo projeto Google Cloud `lume-app-506521` para a Agenda; não existe isolamento de backend entre os builds. O modo `local` deve usar emuladores/mocks para testes destrutivos. O App ID Apple e o bundle também são compartilhados.

Antes de começar, registrar em um inventário privado:

- proprietário e responsáveis por Apple Developer, App Store Connect, Google Cloud e Firebase;
- projetos compartilhados, regiões e conta de cobrança de cada serviço;
- bundle ID compartilhado, Team ID, Firebase App ID, project ID, bucket e OAuth client IDs;
- mecanismo de seleção do perfil no build, como schemes/configurations; o arquivo público Firebase é compartilhado por `dev` e `prod`;
- data de criação, validade/rotação e responsável por cada segredo;
- procedimento de revogação, sem copiar o valor secreto para o inventário.

O inventário deve guardar nomes e identificadores públicos, não tokens, chaves privadas, códigos de recuperação ou arquivos `.p8`/`.json`.

## 2. Apple Sign in e Firebase Authentication

### Registro já criado neste projeto

- App ID: `com.dodopok.lume`
- Nome exibido: `Lume - Personal App`
- Team ID: `R573HPN65Q`
- Key ID de Sign in with Apple: `8ACCN2N8J6`
- Capability **Sign In with Apple**: habilitada no App ID
- A chave privada `.p8` foi baixada localmente; ela deve ser movida para o cofre/secret store usado pelo Firebase ou CI e nunca entrar no repositório.

O Key ID acima identifica a chave, mas não é a chave privada. Para configurar o Firebase, ainda é necessário cadastrar o Team ID, o Key ID, o Service ID se o fluxo exigir e o conteúdo do `.p8` diretamente no painel/cofre autorizado. Para TestFlight/App Store Connect, criar uma API key separada: não reutilizar esta chave de Sign in with Apple.

### Criar e configurar

1. No [Apple Developer](https://developer.apple.com/account/), confirmar a equipe no Apple Developer Program e criar um único App ID para o bundle compartilhado.
2. Habilitar **Sign in with Apple** nesse App ID. Apple Sign in usa a mesma credencial Apple no projeto Firebase compartilhado.
3. No Firebase Console, usar o projeto compartilhado `lume-13125` e adicionar um único app iOS com o bundle ID `com.dodopok.lume`. O mesmo `GoogleService-Info.plist` público identifica o projeto em dev e prod; o modo `local` usa emuladores/mocks e não deve escrever nesse backend. O handler de autenticação é `https://lume-13125.firebaseapp.com/__/auth/handler`.
4. Em **Authentication > Sign-in method**, ativar Apple.
5. No Apple Developer, criar uma chave de Sign in with Apple com acesso ao serviço, anotar `Team ID` e `Key ID` e baixar o `.p8` uma única vez.
6. Cadastrar no Firebase os valores pedidos pelo provedor Apple: `Team ID`, `Key ID`, `Service ID` quando aplicável e a chave privada `.p8`.
7. No Xcode/Runner, habilitar a capability **Sign In with Apple**. Conferir o entitlement no build `dev` e `prod`.
8. Testar o primeiro login, restauração de sessão, cancelamento, e-mail privado da Apple e exclusão da conta.

O `uid` do Firebase é a identidade do Lume. A conta Google usada para Agenda nunca deve criar outro perfil ou substituir o vínculo Apple.

### Valores que devem existir

- `APPLE_TEAM_ID`: identificador público da equipe Apple.
- `APPLE_KEY_ID`: identificador público da chave.
- `APPLE_SERVICE_ID`: somente se o fluxo configurado exigir Services ID.
- `APPLE_PRIVATE_KEY`: conteúdo da chave `.p8`, somente no Firebase/Secret Manager ou no cofre do CI que executar a configuração.
- bundle ID compartilhado e Team ID; Firebase App ID `1:980338934048:ios:e7b42996cde98f0bba5745`, project ID `lume-13125` e arquivo de configuração compartilhados.

### Onde não armazenar

- nunca em `lib/`, `Info.plist`, `GoogleService-Info.plist`, `.env` commitado, logs, Firestore ou Crashlytics;
- nunca no binário Flutter, no App Store Connect ou em uma issue;
- nunca compartilhar o `.p8` por e-mail ou chat.

O arquivo `.p8` deve ser tratado como uma senha de alto impacto. Se vazar, revogar a chave no Apple Developer e criar outra.

### Checklist dev/prod

- **Dev:** Apple App ID, bundle e Firebase compartilhados; conta de teste; e-mail privado validado; fluxo de apagar/reautorizar testado sem usar o build para exclusão destrutiva.
- **Prod:** mesmo App ID/bundle e a mesma credencial Apple cadastrada no Firebase compartilhado; política de privacidade e exclusão prontas; reautenticação validada.
- **Ambos:** redirect/nonce verificados, sem log de `identityToken`, sessão restaurada após reinício e erro humano quando a conta é cancelada.

### Critérios de validação

- login bem-sucedido cria exatamente um `uid` Firebase;
- segundo login da mesma conta restaura o mesmo `uid`;
- conta Apple com Hide My Email funciona sem exibir o endereço em logs;
- token inválido, nonce inválido e cancelamento são recusados sem criar perfil parcial;
- apagar a conta exige reautenticação e remove os dados descritos em [Segurança e privacidade](06-seguranca-privacidade.md).

## 3. Google Calendar OAuth

### Criar e configurar

1. No [Google Cloud Console](https://console.cloud.google.com/), usar o projeto Google Cloud compartilhado `lume-app-506521` (“Lume App”) por `dev` e `prod`. Ele é separado do projeto Firebase `lume-13125`, mas ambos são únicos para os dois builds.
2. Ativar **Google Calendar API** nesse projeto.
3. Configurar uma única tela de consentimento OAuth com nome do app, e-mail de suporte, contato do desenvolvedor, domínios autorizados e link de privacidade.
4. Enquanto estiver em modo `Testing`, cadastrar a conta Google de desenvolvimento como **test user**; revisar a lista antes de distribuir qualquer build.
5. Criar o OAuth client iOS no projeto compartilhado usando o mesmo bundle ID e Team ID. Conferir o `REVERSED_CLIENT_ID`/URL scheme selecionado pelo build. Se for útil para reduzir risco operacional, criar clients iOS/Web distintos dentro do mesmo projeto e nomeá-los explicitamente por ambiente.
6. Se houver troca de código em backend, criar OAuth client Web no mesmo projeto e cadastrar apenas os redirect URIs exatos. Não reutilizar client secret no app.
7. Usar escopos mínimos e incrementais:
   - leitura: `calendar.calendarlist.readonly` e `calendar.events.readonly`;
   - escrita somente quando a usuária tentar criar/editar: `calendar.events`.
8. Configurar consentimento, verificação de escopos sensíveis e publicação apenas quando o fluxo estiver estável.

O Google OAuth é uma autorização para Agenda, não o login principal do Lume. Tokens devem permanecer no Keychain/memória do processo ou no mecanismo seguro do backend quando o backend for necessário.

### Registro já informado

- Projeto Google Cloud: `lume-app-506521` — **Lume App**.
- Projeto Firebase: `lume-13125`; domínio de autenticação `lume-13125.firebaseapp.com`.
- OAuth client iOS confirmado para a Agenda: `1018427269031-btmqjfbld86lqsfpr0aivec1vj8bbn8d.apps.googleusercontent.com`.
- Reversed client ID registrado no target iOS: `com.googleusercontent.apps.1018427269031-btmqjfbld86lqsfpr0aivec1vj8bbn8d`.
- OAuth client Web usado como `serverClientId`: `1018427269031-d002niqglh23u9omq8urmee091gqotca.apps.googleusercontent.com`. Ele não deve ser usado como URL scheme no iOS.
- OAuth client iOS presente no `GoogleService-Info.plist`: `980338934048-d1ijkl2g5e2o1u28bo2ihtnbfi04a5vk.apps.googleusercontent.com`, com reversed client ID `com.googleusercontent.apps.980338934048-d1ijkl2g5e2o1u28bo2ihtnbfi04a5vk`.
- O client iOS acima foi gerado para o Firebase `lume-13125`; ele não deve ser presumido como client da Agenda no Google Cloud `lume-app-506521`.
- O client iOS da Agenda usa o bundle `com.dodopok.lume` e o reversed client ID acima no target iOS. O client Web é enviado somente como `serverClientId`, para que o token possa ser aceito pelo backend quando necessário.
- O arquivo JSON de client secret recebido localmente contém material sensível: não copiar para o repositório, não embutir no Flutter e não compartilhar em tickets.

### Valores que devem existir

- `GOOGLE_CLOUD_PROJECT_ID=lume-app-506521`, compartilhado por `dev` e `prod`;
- `FIREBASE_PROJECT_ID=lume-13125`, compartilhado por `dev` e `prod`;
- OAuth iOS client ID do projeto `lume-app-506521`: `1018427269031-btmqjfbld86lqsfpr0aivec1vj8bbn8d.apps.googleusercontent.com`;
- OAuth Web client ID do mesmo projeto, usado somente como `serverClientId`: `1018427269031-d002niqglh23u9omq8urmee091gqotca.apps.googleusercontent.com`;
- `REVERSED_CLIENT_ID`/URL scheme do client iOS no target iOS correspondente;
- OAuth Web client secret somente se houver fluxo backend;
- lista de test users no modo `Testing`;
- escopos aprovados e calendário(s) habilitado(s).

No código, a Agenda usa por padrão o client iOS público confirmado. Um build
que precise desligar a integração pode passar `LUME_ENABLE_CALENDAR=false`; o
client também pode ser sobrescrito por `--dart-define`, por exemplo:

```text
LUME_ENABLE_CALENDAR=false
LUME_GOOGLE_IOS_CLIENT_ID=<client-id-ios-do-projeto-lume-app-506521>
LUME_GOOGLE_WEB_CLIENT_ID=<client-id-web-do-projeto-lume-app-506521>
```

O client iOS `1018427269031-btmqjfbld86lqsfpr0aivec1vj8bbn8d.apps.googleusercontent.com`
está registrado para a Agenda e o URL scheme correspondente está no target iOS.
O client Web `1018427269031-d002niqglh23u9omq8urmee091gqotca.apps.googleusercontent.com`
é usado apenas como `serverClientId`; ele não pode aparecer como custom scheme.
A conexão só inicia quando a usuária toca em “Conectar Google Agenda”.

### Onde não armazenar

- nunca incluir `client_secret` ou refresh token no Flutter, plist, Firestore, Storage, analytics ou Crashlytics;
- não imprimir access token, refresh token, authorization code, e-mail ou URL completa;
- não colocar um OAuth client ou URL scheme diferente do escolhido para o build; todos pertencem ao mesmo projeto Google, mas ainda precisam corresponder ao target/configuração correta;
- não usar client secret como se fosse segredo de um client iOS: o app nativo não é um local seguro para segredo.

### Checklist dev/prod

- **Dev:** projeto Google compartilhado; conta de teste; escopos de leitura testados antes de escrita; modo `local` reservado aos emuladores.
- **Prod:** o mesmo projeto/client aprovado e registrado com o mesmo bundle; consent screen revisada; verificação Google concluída se exigida; procedimento de revogação pronto.
- **Ambos:** `syncToken` e `etag` ficam no cache operacional, nunca no Firestore; `410 Gone` refaz sync completa; revogar Google não encerra a conta Apple.

### Critérios de validação

- sem conexão com Google, o restante do app continua utilizável;
- leitura inicial cobre seis meses passados e doze futuros;
- evento de dia inteiro não recebe horário fictício;
- criação repetida após resposta perdida não duplica evento;
- token expirado/revogado leva à reconexão, sem loop de login;
- nenhum dado de evento ou token aparece em logs/Crashlytics.

## 4. Firebase, Firestore e Storage

### Criar e configurar

1. Usar o projeto Firebase compartilhado `lume-13125`, com cobrança habilitada somente na conta responsável e alertas de orçamento configurados.
2. Adicionar nesse projeto um único app iOS com o bundle ID compartilhado e gerar o arquivo público `GoogleService-Info.plist`. Dev e prod usam a mesma configuração; o modo `local` aponta para o Emulator Suite.
3. Habilitar Authentication, Firestore, Storage, App Check e Crashlytics conforme as seções abaixo.
4. Publicar regras Firestore e Storage com princípio **deny by default**. Validar `uid`, tipos, enums, limites, propriedade imutável e caminho `users/{uid}`.
5. Definir região e retenção antes de armazenar dados reais. Não trocar região ou bucket de produção informalmente.
6. Para fotos, usar caminho privado por usuário, permitir somente MIME/tamanho previstos e remover EXIF/GPS no dispositivo antes do upload.

Não existe uma “chave secreta do Storage” para colocar no app. O SDK usa a configuração pública do Firebase, Authentication, App Check e regras.

### Valores que devem existir

- Firebase `projectId`, `appId`, `storageBucket`, `apiKey` e `messagingSenderId` no arquivo gerado do projeto compartilhado;
- IDs e região do Firestore/Storage;
- limites de upload, MIME types e retenção documentados;
- credencial de Admin SDK somente para backend/CI, nunca no app.

### Onde não armazenar

- não usar `serviceAccountKey.json` em Flutter, repositório ou artifact distribuído;
- não tornar bucket público para simplificar imagem;
- não colocar regras permissivas permanentes como `allow read, write: if request.auth != null`;
- não usar o backend compartilhado para testes destrutivos; usar emuladores e dados fictícios no modo `local`.

### Checklist dev/prod

- **Local:** Emulator Suite para Rules; dados fictícios; testes de UID A/B e usuário anônimo.
- **Dev/prod:** mesmas regras publicadas e revisadas; bucket privado; alertas de orçamento; backup/PITR conforme plano; teste de exclusão e objetos órfãos. Builds de teste devem usar dados reversíveis ou claramente marcados.
- **Ambos:** uploads pendentes sobrevivem a reinício; falha de upload não apaga cópia local; leitura fora do UID é negada.

### Critérios de validação

- usuário não autenticado e UID diferente não acessam documentos/arquivos;
- campos desconhecidos, tipos inválidos, tamanhos excessivos e caminhos fora do usuário são recusados;
- download público retorna negado;
- upload válido é retomável e o registro mantém `pending`, `uploaded` ou `failed` corretamente;
- exportação contém somente dados do `uid` autenticado.

## 5. Cloud Functions e proteção SSRF

### Estado no repositório

O scaffold executável está em `functions/`, com a função `extractLinkMetadata`, parser JSON-LD/Open Graph, fallback manual, autenticação Firebase, rate limit em memória, concorrência limitada, redirects revalidados, DNS pinning, bloqueio de redes privadas/metadata, limite de resposta e testes Node. O app Flutter só cria o cliente quando `LUME_ENABLE_LINK_EXTRACTION=true`; o endpoint padrão aponta para `us-central1` do projeto compartilhado, mas o deploy não é feito automaticamente.

### Criar e configurar

1. Habilitar Cloud Functions apenas no projeto em que a função for necessária e selecionar uma região próxima da base de usuários.
2. Criar conta de serviço com menor privilégio; separar deploy de leitura/execução quando possível.
3. Armazenar chaves de terceiros e parâmetros sensíveis no **Google Secret Manager**. Associar cada secret somente à função que precisa dele.
4. Exigir autenticação Firebase na função de extração. Revalidar `uid`, autorização, método, tamanho e formato no backend; Admin SDK não respeita Firestore Rules automaticamente.
5. Configurar timeout, memória, concorrência, limite de bytes, limite de descompressão, rate limit por usuário e alertas de custo.
6. Para SSRF, aceitar somente `http`/`https`, portas 80/443, sem userinfo; resolver DNS e bloquear loopback, localhost, privado, link-local, multicast e metadata cloud em IPv4 e IPv6.
7. Revalidar cada redirect, limitar a três, proteger contra DNS rebinding, validar `Content-Type`, limitar HTML e descartar o conteúdo bruto após a resposta.
8. Não executar JavaScript, não enviar cookies/headers do dispositivo e não acessar páginas autenticadas no MVP.

### Valores que devem existir

- `FUNCTIONS_REGION`;
- nomes dos secrets no Secret Manager, nunca seus valores em documentação;
- limites de timeout, bytes, redirects e concorrência;
- domínios/portas permitidos, se houver allowlist por recurso;
- URL pública da função somente como configuração não sensível do ambiente.

### Onde não armazenar

- não armazenar secrets em `functions.config`, `.env` commitado, `firebase.json`, app Flutter, Firestore ou logs;
- não registrar URL completa, HTML, cookies, authorization headers ou resposta bruta;
- não confiar em validação feita somente no cliente;
- não permitir que um redirect contorne a validação inicial.

### Checklist dev/prod

- **Dev:** Emulator Suite/mocks; endpoints controlados; testes de SSRF com redes privadas e metadata; limite de custo baixo.
- **Prod:** Secret Manager; service account mínima; App Check e Authentication verificados; rate limit/alertas; logs redigidos.
- **Ambos:** resposta só contém campos estruturados (`canonicalUrl`, `siteHost`, `title`, `imageUrl`, `priceMinor`, `currency`, `source`, `warnings`); HTML nunca persiste.

### Critérios de validação

- localhost, IPv4/IPv6 privados, metadata, portas não permitidas e redirects para rede privada são bloqueados;
- DNS rebinding e respostas comprimidas/maiores que o limite não derrubam a função;
- usuário não autenticado, payload grande e rate limit excedido recebem erro categorizado;
- função não vaza URL, HTML, token ou cabeçalho em logs;
- parser não considera dados extraídos confirmados sem revisão da usuária.

## 6. Capabilities e configuração iOS

Cada capability precisa ser habilitada no App ID correto e no target correspondente. Depois de alterar uma capability, gerar um build assinado e conferir os entitlements no arquivo final; não basta marcar uma caixa no Xcode.

### Push Notifications e APNs

O MVP usa notificações locais e não precisa de push remoto. Só habilitar **Push Notifications**, criar APNs key/certificado e configurar Firebase Cloud Messaging se existir um requisito real de push remoto.

- **Onde criar:** Apple Developer > Certificates, Identifiers & Profiles > Keys; capability no App ID/target; Firebase Messaging somente se adotado.
- **Valores:** Team ID, Key ID, `.p8`, bundle ID, environment sandbox/production e `aps-environment` no entitlement.
- **Não armazenar:** `.p8`, token APNs, device token ou service account no app, Firestore, logs ou repositório.
- **Dev/prod:** usar sandbox/dev e device token de teste no build dev; APNs production no build distribuído; a separação é feita pelo entitlement/build e pelo servidor, não por bundle ID; nunca enviar texto íntimo.
- **Validação:** permissão contextual; negação não quebra o app; lembrete local agenda/reagenda; push remoto, se existir, é recebido pelo mesmo bundle e roteado para o ambiente correto sem misturar tokens/dados.

### Photos

- **Onde criar:** capability/uso do target iOS e chaves de privacidade em `Info.plist` geradas pelo projeto Flutter.
- **Valores:** descrição clara para `NSPhotoLibraryUsageDescription`; usar seletor limitado quando possível; camera só se o produto realmente adicionar câmera.
- **Não armazenar:** fotos originais ou EXIF/GPS em logs; não pedir acesso amplo ao abrir o app.
- **Dev/prod:** testar acesso limitado, negado e revogado; mesma descrição em ambos, ajustada ao uso real.
- **Validação:** seleção contextual funciona; orientação é corrigida; EXIF/GPS é removido antes do upload; cópia local sobrevive a falha.

### Face ID

- **Onde criar:** capability/entitlement e `NSFaceIDUsageDescription` no target iOS.
- **Valores:** texto que explica que Face ID protege a abertura do Lume; política de fallback para código do aparelho.
- **Não armazenar:** biometria, template facial ou resultado sensível; guardar somente preferência e estado mínimo no Keychain.
- **Dev/prod:** testar sucesso, cancelamento, indisponibilidade, aparelho sem biometria e retorno do background.
- **Validação:** Face ID não substitui Firebase Auth; conteúdo não aparece no app switcher; fallback é seguro e não desativa a proteção silenciosamente.

### App Groups e Share Extension

- **Onde criar:** Apple Developer > Identifiers > App Groups; associar ao App ID principal `com.dodopok.lume` e ao target da Share Extension; o target nativo já está no projeto iOS.
- **Valores deste projeto:** App Group `group.com.dodopok.lume`; bundle ID da extensão `com.dodopok.lume.ShareExtension`; callback `lume://share`; target Xcode `ShareExtension`. O Runner e a extensão já declaram o mesmo entitlement e o Flutter consome o payload de uso único.
- **Não armazenar:** tokens Google, cookies ou conteúdo permanente de usuário em `UserDefaults` compartilhado; não usar App Group como cofre.
- **Dev/prod:** o grupo e os bundle IDs são compartilhados, assim como Firebase e Google; namespacear arquivos/chaves pelo ambiente e limpar dados ao trocar build. A extensão aceita URL/texto, salva somente uma URL `http(s)` por vez e o app valida novamente antes de abrir o editor de desejos.
- **Configuração externa pendente:** criar o App Group acima, habilitar **App Groups** nos dois App IDs/targets, registrar `com.dodopok.lume.ShareExtension` e regenerar provisioning profiles. Sem isso, o código compila localmente, mas a instalação assinada não terá comunicação entre extensão e app.
- **Validação:** Safari compartilha uma URL; extensão salva payload mínimo; o app abre Finanças > Desejos com URL e domínio pré-preenchidos; cancelamento, URL malformada e ausência de entitlement não travam nem fazem request direto.

## 7. Notificações locais

### Criar e configurar

- **Onde criar:** configuração do target iOS e API local de notificações usada pelo app; não criar servidor/push no MVP.
- **Valores:** categorias, identificadores determinísticos, janelas e fuso local; preferências começam desligadas.
- **Não armazenar:** conteúdo íntimo em payload exibido na tela bloqueada; não salvar token APNs se não houver push.
- **Dev/prod:** pedir permissão somente após ativar lembrete; testar fuso, virada do dia, alteração de meta e permissão negada.
- **Validação:** notificações são genéricas por padrão (“Você tem um lembrete no Lume”), não duplicam lembretes da Agenda e são canceladas/reagendadas ao mudar preferências.

Se push remoto for aprovado posteriormente, adicionar uma seção de arquitetura própria para token rotation, consentimento, APNs, FCM, tópicos e redaction antes de implementá-lo.

## 8. Firebase App Check com App Attest

### Criar e configurar

1. No Firebase Console, abrir **App Check** no projeto compartilhado e registrar o app iOS.
2. Selecionar **App Attest** para produção, com fallback DeviceCheck somente se a compatibilidade mínima exigir.
3. Durante desenvolvimento local, usar o provider de debug e registrar tokens de debug somente durante a sessão de emulador/teste; nunca aceitar token de debug como prova de produção.
4. Monitorar métricas primeiro; ativar enforcement por produto de forma gradual, começando por backend/Storage sensível após os builds válidos estarem comprovados.
5. Manter Authentication, Rules e validação de entrada mesmo com App Check: App Check é defesa adicional, não autorização.

### Valores e armazenamento

- `FIREBASE_PROJECT_ID=lume-13125`, `FIREBASE_APP_ID=1:980338934048:ios:e7b42996cde98f0bba5745` e configuração pública do projeto compartilhado;
- debug App Check token somente em Keychain/secret local/CI protegido;
- nenhuma chave App Check privada no binário ou commit;
- projeto e bundle corretos no Console.

### Checklist e validação

- **Dev/local:** debug provider funciona no aparelho/simulador autorizado sem ser aceito como prova de produção.
- **Prod:** App Attest registra o app; enforcement é ativado somente depois de observar tráfego válido.
- Requisição sem App Check, com token inválido ou de outro ambiente é recusada conforme a política, sem expor dados.
- Desinstalação/reinstalação e atualização não deixam o app preso em loop irrecuperável.

## 9. Crashlytics e observabilidade

### Criar e configurar

1. Habilitar Crashlytics no projeto Firebase compartilhado e adicionar o app iOS `com.dodopok.lume`.
2. Integrar somente depois de definir redaction; revisar breadcrumbs, custom keys, user identifiers e mensagens de erro.
3. Configurar upload de dSYM no build de release/TestFlight para símbolos legíveis.
4. Distinguir builds por versão, flavor/flag e chave técnica redigida nos dashboards; não coletar analytics de comportamento no MVP sem decisão específica.

### Valores e armazenamento

- Firebase App ID e arquivo público compartilhado;
- credencial de upload de dSYM ou service account somente no CI secret store, com menor privilégio;
- nenhuma chave de CI, dSYM privado ou token de upload no app/repositório.

### Checklist e validação

- **Dev:** evento de teste aparece no projeto compartilhado, identificado como teste, e contém somente dados técnicos.
- **Prod:** dSYM está disponível; alertas por versão/build configurados; retenção definida; acesso ao painel restrito.
- **Ambos:** não enviar texto de gratidão, valores, URLs completas, títulos de eventos, fotos, e-mail ou tokens.
- Forçar crash controlado em build de teste e confirmar símbolo, ambiente e versão; remover o caso de teste antes do release.

## 10. TestFlight e App Store Connect

### Criar e configurar

1. Manter Apple Developer Program ativo.
2. No App Store Connect, criar um único app com o bundle ID compartilhado; cadastrar nome, SKU, categoria, classificação etária, contato, política de privacidade e informações de App Privacy.
3. Criar grupo de testers internos e, quando necessário, externos; testers externos passam por Beta App Review.
4. Configurar certificados, provisioning profiles e signing no CI. Preferir App Store Connect API key para upload automatizado.
5. Criar API key no App Store Connect com papel mínimo necessário, guardar `Issuer ID`, `Key ID` e arquivo `.p8` no cofre do CI.
6. Manter build number crescente; o pipeline deve executar format, analyze, testes, Rules tests, build assinado e smoke test antes do upload.

### Onde não armazenar

- não guardar API key `.p8`, certificados privados ou provisioning profiles no git, no app ou em artifacts públicos;
- não colocar credenciais de assinatura em screenshot, issue ou `.env` commitado;
- não distribuir build dev como se fosse prod;
- não declarar dados/SDKs no App Privacy sem conferir o comportamento real do binário.

### Checklist dev/prod

- **Dev/TestFlight interno:** bundle compartilhado, Firebase compartilhado, configuração OAuth de teste no projeto Google compartilhado, grupo interno e release notes com limitações; avisar que instalar este build pode substituir o app prod e acessar os mesmos dados.
- **Prod/TestFlight:** mesmo bundle, Firebase compartilhado, configuração OAuth aprovada no mesmo projeto Google, App Check/Crashlytics compartilhados, política acessível, exportação/exclusão e build assinado.
- **Ambos:** smoke test em aparelho real, modo avião, permissões, Apple login, Agenda, Face ID e upload.

### Critérios de validação

- archive assinado instala no aparelho e identifica visualmente o ambiente correto; não existe expectativa de instalação lado a lado;
- login Apple, OAuth Google e Firebase funcionam no build distribuído, não apenas no debug;
- build/config seleciona o `GoogleService-Info.plist`, OAuth client, URL scheme, entitlements e endpoint corretos; o bundle ID compartilhado é intencional;
- upload para TestFlight ocorre sem imprimir segredo no CI;
- build number é crescente e o dSYM correspondente chega ao Crashlytics.

## 11. Segredos locais e CI

### Classificação

**Públicos no app, compartilhados:** Firebase config gerado, Firebase App ID, `lume-13125`, `lume-app-506521`, OAuth client ID iOS, bundle ID e URL scheme.

**Secretos:** Apple `.p8`, OAuth Web client secret, refresh/access tokens, APNs `.p8`, App Store Connect API key `.p8`, service account, Secret Manager values, App Check debug token e credenciais de assinatura.

### Armazenamento recomendado

- **Local:** Keychain/secure storage do sistema, `firebase emulators:start`, arquivos ignorados e cofre de senhas; usar `.env.example` apenas com nomes e placeholders.
- **CI:** secret manager nativo do provedor, ambientes protegidos, revisão obrigatória para prod, logs mascarados e acesso por job mínimo.
- **Backend:** Google Secret Manager com IAM por função.
- **Apple:** Developer/App Store Connect somente para cadastro; cópias de chaves privadas ficam no cofre autorizado ou CI, nunca no repositório.

### Onde não armazenar

- git, pull request, issue, chat, wiki pública, arquivo exportado, Firestore, Storage, Crashlytics, analytics, `Info.plist`, assets ou código Dart;
- variáveis de ambiente impressas pelo pipeline;
- artifacts de build não protegidos;
- backups sem criptografia e sem política de retenção.

### Checklist dev/prod

- **Dev/local:** credenciais de baixo privilégio; emuladores e contas de teste; debug tokens não aceitos como prova de produção; `.gitignore` revisado; pre-commit/CI procura padrões de segredo.
- **Prod:** aprovação manual; secrets com menor privilégio e rotação documentada; logs mascarados; acesso limitado; backup e revogação testados.
- **Ambos:** nenhum segredo aparece em `git diff`, `flutter build --verbose`, logs de teste ou Crashlytics; expiração/rotação tem responsável.

### Critérios de validação

- busca automatizada por `.p8`, `serviceAccount`, `client_secret`, tokens e chaves privadas não encontra valores reais;
- build sem secrets proibidos ainda contém somente configurações públicas necessárias;
- revogar uma credencial interrompe apenas a integração correspondente e existe caminho de recuperação;
- um job sem permissão de prod não consegue publicar Functions, regras, Storage ou TestFlight;
- incidente de vazamento tem procedimento: revogar, rotacionar, invalidar sessões/tokens, verificar logs e documentar sem reproduzir o segredo.

## 12. Gate final antes de dados reais

- [ ] Apple Developer, App Store Connect, Firebase e Google Cloud têm responsáveis definidos.
- [ ] `dev` e `prod` apontam conscientemente para o mesmo Firebase `lume-13125` e Google Cloud `lume-app-506521`, bucket, dados e configuração pública; o modo `local` é o único isolado por emuladores.
- [ ] O build seleciona o ambiente antes de compilar e mostra claramente `dev` ou `prod`.
- [ ] Está documentado que instalar um build pode sobrescrever o outro e que dados locais/cache não devem ser usados para separar ambientes.
- [ ] Sign in with Apple restaura sessão e exclusão foi testada.
- [ ] Google Calendar usa menor privilégio, test user em dev e consent screen revisada.
- [ ] Firestore/Storage negam acesso entre UIDs e não há bucket público.
- [ ] Cloud Functions têm Secret Manager, IAM mínimo e testes SSRF aprovados.
- [ ] Push remoto está explicitamente adiado ou APNs/FCM foi configurado e validado.
- [ ] Photos, Face ID, App Groups e Share Extension foram testados em aparelho real.
- [ ] Notificações locais são genéricas, consentidas e reagendáveis.
- [ ] App Check App Attest está monitorado antes do enforcement em prod.
- [ ] Crashlytics está com redaction, símbolos e identificação clara do build dentro do projeto compartilhado.
- [ ] TestFlight usa signing/API key protegidos e build number crescente.
- [ ] Busca de segredos, `flutter analyze`, testes, Rules tests e smoke test passaram.
- [ ] Política de privacidade e App Privacy refletem o binário efetivamente distribuído.

As URLs oficiais e a necessidade de reconferir regras de plataforma estão reunidas em [Referências oficiais](11-referencias.md). Antes de cada release, revisar os painéis Apple, Firebase e Google, porque telas de configuração, requisitos de verificação e capabilities podem mudar.
