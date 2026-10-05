# Bar do Mocochovisk

Aplicativo Flutter de controle financeiro, com interface Cupertino em português
do Brasil e backend Supabase. **Entrega atual: etapa 1 de 7.** A implementação
para aqui para validação, conforme solicitado.

## O que funciona nesta etapa

- Cadastro com confirmação por e-mail, login, recuperação e definição de nova
  senha via Supabase Auth; sessão persistente e saída do dispositivo atual.
- Navegação protegida com cinco abas: Início, Extrato, Produtos, Fornecedores
  e Mais. Cada aba mantém sua própria pilha; páginas usam transições Cupertino.
- Tema claro/escuro acompanhando o sistema, listas agrupadas, títulos grandes,
  barras translúcidas, fonte de sistema no iOS e Inter embarcada nas demais
  plataformas, leitura com fonte ampliada e feedback tátil.
- Configuração por `--dart-define`, estados de inicialização, erros em português,
  formulários validados e bloqueio de envios duplicados.
- Projetos Android, iOS e web, testes de autenticação, navegação e configuração.

As áreas financeiras mostram apenas a indicação dos recursos previstos. Não há
saldos, fornecedores, produtos nem transações fictícias. Os únicos fakes estão
nos testes, isolados do aplicativo.

## Pré-requisitos

- Flutter **3.47.5 stable**, Dart **3.13.4** (versão fixada em `.fvmrc`).
- Android: Android Studio, Android SDK, JDK 17 ou posterior compatível e um
  dispositivo/emulador. Confira o ambiente com `flutter doctor -v`.
- iOS: macOS, Xcode e as ferramentas de dependências indicadas por `flutter doctor`.
  Compilação/assinatura de iOS precisa de macOS.
- Web: Chrome para desenvolvimento.
- Projeto Supabase com Auth por e-mail habilitado.

Nesta pasta foi instalado um SDK isolado em `.tooling/flutter`, ignorado pelo
Git. O script abaixo o escolhe antes do SDK global, que pode estar desatualizado:

```powershell
.\scripts\flutter.ps1 --version
.\scripts\flutter.ps1 pub get
```

Em outro computador, instale a versão indicada, ou use `fvm install` e
`fvm flutter` no lugar de `flutter`. O SDK em `.tooling` não faz parte da entrega
versionada. O `pubspec.lock` deve ser mantido para builds reproduzíveis.

## Configurar o Supabase

1. Crie um projeto em [supabase.com/dashboard](https://supabase.com/dashboard).
2. Copie a URL do projeto e a chave pública **publishable**. A chave **anon**
   legada também é aceita. Não use `secret` ou `service_role` no app.
3. Ative o provedor Email em Authentication e mantenha confirmação de e-mail.
   Alinhe o mínimo de senha do painel com o mínimo de 8 caracteres do app.
4. Configure SMTP para o envio real dos e-mails. O serviço padrão do Supabase
   restringe destinatários e quantidade de envios.
5. Em Authentication → URL Configuration, adicione às Redirect URLs:
   `br.com.mocochovisk.app://login-callback` e, para testes web,
   `http://localhost:3000/`. Para publicar web, adicione sua URL HTTPS exata.
6. Preserve `{{ .ConfirmationURL }}` nos templates de confirmação e recuperação.

Veja os detalhes e referências oficiais em [supabase/README.md](supabase/README.md).
Nenhuma migration é necessária para testar Auth isoladamente. O schema inicial,
RLS, views, funções e categorias padrão estão em
`supabase/migrations/001_init.sql`; consulte [supabase/README.md](supabase/README.md)
para aplicá-la ao projeto.

### Android / iOS

```powershell
Copy-Item config/supabase.example.json config/supabase.json
```

Edite `config/supabase.json` com os dados reais do projeto:

```json
{
  "SUPABASE_URL": "https://SEU-PROJETO.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "SUA-CHAVE-PUBLICAVEL",
  "AUTH_REDIRECT_URL": "br.com.mocochovisk.app://login-callback"
}
```

```powershell
.\scripts\flutter.ps1 devices
.\scripts\flutter.ps1 run --dart-define-from-file=config/supabase.json
```

Com o SDK correto no PATH, o equivalente em qualquer plataforma é:

```sh
flutter pub get
flutter run --dart-define-from-file=config/supabase.json
```

### Navegador

```powershell
Copy-Item config/supabase.web.example.json config/supabase.web.json
# Preencha a URL e a chave em config/supabase.web.json.
.\scripts\flutter.ps1 run -d chrome --web-port=3000 --dart-define-from-file=config/supabase.web.json
```

Use `http://localhost:3000/` como `AUTH_REDIRECT_URL` nesse arquivo. Na publicação,
use o endereço HTTPS em que o app será servido. Se não informar essa variável,
o app usa a URL base do navegador na web e o callback registrado no mobile.
`SUPABASE_ANON_KEY` é um alias aceito quando `SUPABASE_PUBLISHABLE_KEY` não existe.

O aplicativo abre uma orientação de configuração se faltarem variáveis; não
substitui uma conexão ausente por dados locais. Não há credenciais no repositório.
Os JSONs reais são ignorados pelo Git. Variáveis `dart-define` entram no binário:
portanto só devem conter a URL e a chave pública do cliente.

## Validação desta etapa

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub
flutter build apk --debug --no-pub
```

No Windows desta entrega, use `.\scripts\flutter.ps1` para os comandos Flutter e
`.\.tooling\flutter\bin\cache\dart-sdk\bin\dart.exe` para o comando Dart.

Verificado nesta entrega: `flutter analyze` sem issues, formatação sem mudanças
e **47 testes aprovados** na execução com captura visual habilitada (46 testes
de comportamento mais a captura opcional). Para gerar as mesmas prévias:

```sh
flutter test --no-pub --dart-define=CAPTURE_PREVIEWS=true
```

As imagens são gravadas em `build/previews/login-light.png`, `login-dark.png`
e `home-dark.png`. São capturas das telas reais renderizadas nos testes; não
incluem valores financeiros simulados. A suíte normal pula somente a captura.

Os builds web e Android debug foram compilados com sucesso. Artefatos locais:
`build/web/` e `build/app/outputs/flutter-apk/app-debug.apk`. Eles foram gerados
sem credenciais para validar a compilação e abrem a orientação de configuração;
gere novamente com `--dart-define-from-file` para acessar seu Supabase.
Auth/e-mails contra um projeto Supabase real não foram exercitados nesta entrega,
pois não foram fornecidas URL/chave. O projeto iOS está incluído, mas sua
compilação não foi executada no Windows.

Checklist manual com um projeto Supabase real:

1. Crie uma conta, abra a confirmação no mesmo dispositivo e entre com a senha.
2. Feche/reabra o aplicativo e confirme que a sessão foi mantida.
3. Navegue nas cinco abas; em Mais, abra Ingredientes/Sobre e volte, inclusive
   com o gesto de borda no iOS. Mude a aparência do sistema e amplie a fonte.
4. Saia da conta. Confira validação de campos, credenciais incorretas e erro
   de rede sem deixar o botão preso em carregamento.
5. Solicite recuperação, abra o link no mesmo dispositivo/perfil de navegador,
   defina a senha e entre com ela. Confira links expirados e nova solicitação.

O fluxo usa PKCE: abrir o e-mail em outro dispositivo ou outro perfil do navegador
não tem o verificador que iniciou a operação. O app apresenta erro e permite
solicitar um novo link. Confirmação e recuperação reais dependem da configuração
de e-mail e do projeto Supabase; testes automatizados usam repositórios de teste.

## Gerar builds

```sh
# Android, para instalação de teste
flutter build apk --debug --dart-define-from-file=config/supabase.json

# Android, distribuição (configure a assinatura antes)
flutter build appbundle --release --dart-define-from-file=config/supabase.json

# iOS, somente no macOS (selecione equipe/assinatura no Xcode)
flutter build ios --release --no-codesign --dart-define-from-file=config/supabase.json
flutter build ipa --release --dart-define-from-file=config/supabase.json

# Web
flutter build web --release --dart-define-from-file=config/supabase.web.json
```

O Android mantém a assinatura de debug do template para execução local.
Antes de distribuir, configure um keystore próprio conforme o
[guia oficial Android](https://docs.flutter.dev/deployment/android#sign-the-app).
O identificador inicial é `br.com.mocochovisk.mocochovisk`; altere os identificadores
e o callback de forma coordenada se usar outro domínio. O build sem variáveis
valida a compilação, mas abre a orientação de configuração.

## Organização

```text
lib/
  app.dart
  main.dart
  core/
    router/       # GoRouter, proteção de sessão, pilhas por aba
    supabase/     # bootstrap, configuração e providers
    theme/        # tema Cupertino adaptativo
    utils/        # apresentação BRL e dd/MM/yyyy
    widgets/      # listas/páginas com títulos grandes
  features/
    auth/         # domain, data e presentation implementados
    dashboard/
    ingredients/
    products/
    settings/
    statement/
    suppliers/
    transactions/
config/           # exemplos de dart-define
supabase/         # migration inicial, RLS, views e instruções
test/             # testes e fakes isolados
assets/fonts/     # Inter + licença SIL OFL
```

Cada feature possui pastas `data`, `domain` e `presentation`; as camadas ainda
sem implementação ficam vazias até a etapa correspondente. A autenticação usa
uma interface de repositório, implementação Supabase e controller observável
injetado por Riverpod. GoRouter reage ao controller sem reconstruir a pilha
em cada evento. `CupertinoTabBar` fica no shell com os Navigators do GoRouter
para preservar as pilhas sem criar uma segunda árvore de navegação concorrente.

Dependências nesta etapa: `supabase_flutter`, `flutter_riverpod`, `go_router`,
`intl`, `cupertino_icons`, `shared_preferences` e localizações oficiais Flutter.
DTOs pequenos e imutáveis são escritos manualmente; Freezed/json_serializable
serão avaliados com as entidades financeiras, evitando geração sem necessidade
nesta etapa. Gráficos, CSV, PDF e compartilhamento entram nas etapas específicas.
Valores financeiros serão calculados fora da UI; o formatador atual recebe
centavos inteiros e usa vírgula decimal em pt-BR.

## Próximas entregas e melhorias

Etapa 2 concluída: migration idempotente, RLS explícita, funções/views e
categorias padrão. Veja [supabase/README.md](supabase/README.md) para aplicá-la.

3. Fornecedores, ingredientes, histórico e comparação de preços.
4. Entradas/saídas, categorias, recorrência e extrato filtrado.
5. Produtos, receitas, custos, margem e sugestão de preço.
6. Dashboard, rankings, gráficos e alertas.
7. Exportação PDF/CSV, testes financeiros, polimento e documentação final.

Melhorias posteriores: cache de leitura e fila offline com reconciliação,
armazenamento de sessão com proteção adicional do sistema e links universais
verificados. Nesta etapa só a sessão e a intenção de recuperação persistem
localmente; o app não oferece lançamentos offline.
