# Bar do Mocochovisk

Aplicativo Flutter com interface Cupertino em português do Brasil e Supabase.
**Escopo atual: etapas 1 a 4.** Produtos/fichas técnicas (5), dashboard (6) e
exportação PDF/CSV (7) ficam para a próxima entrega.

## Recursos disponíveis

- Cadastro, confirmação por e-mail, login, recuperação de senha, sessão persistente
  e logout; cinco abas protegidas, tema claro/escuro e fonte adaptativa.
- Fornecedores: cadastro completo, edição/exclusão, busca, ativo/inativo, contatos,
  ligação/WhatsApp, preços atuais e gastos pagos no período.
- Ingredientes: cadastro, categorias, unidades base, histórico imutável de
  cotações/compras, conversão kg/g e L/ml, comparação de fornecedores ativos,
  menor preço, variação percentual e gráfico de evolução.
- Entradas/saídas: valor, categoria, pagamento, data, descrição, fornecedor,
  pago/pendente e comprovante privado JPG/PNG/PDF de até 10 MB.
- Compra de ingrediente e lançamento financeiro no mesmo fluxo, gravados em uma
  única transação SQL. Reenvios do mesmo lançamento mantêm o identificador.
- Categorias editáveis e recorrências mensais com intervalos configuráveis.
- Extrato cronológico agrupado por dia, todos os filtros solicitados, detalhes,
  edição/exclusão confirmada, totais e saldo acumulado do filtro.
- Migration idempotente com nove tabelas, RLS, chaves compostas entre usuários,
  índices, triggers, views de preços/custos e RPCs de compras/recorrências/resumos.

Os dados do aplicativo vêm do Supabase. Os registros fictícios existem somente
nos testes. A aba Início mantém atalhos; Produtos permanece sinalizado como
recurso de uma etapa futura.

## Pré-requisitos

- Flutter 3.47.5 e Dart 3.13.4, conforme `.fvmrc`.
- Projeto Supabase com autenticação por e-mail e Postgres 15 ou posterior.
- Android SDK/JDK para Android; macOS/Xcode para iOS; Chrome para web.

O SDK local em `.tooling/flutter` não é versionado. O script
`scripts/flutter.ps1` prefere esse SDK e usa o Flutter do PATH como alternativa.
No Windows, ele prepara um caminho temporário sem espaços para evitar falhas
dos hooks de dependências nativas. Não altere a política de execução do sistema:
se scripts estiverem bloqueados, execute os exemplos desta forma:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter.ps1 --version
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter.ps1 pub get
```

Em um terminal com execução de scripts habilitada, use `.\scripts\flutter.ps1`.
Nas demais plataformas, use `flutter` diretamente.

## Configurar Supabase e banco

1. Crie um projeto Supabase; copie a URL e a chave pública publishable ou anon.
2. Ative Email em Authentication; mantenha a confirmação e configure SMTP real.
   O app exige pelo menos oito caracteres para novas senhas.
3. Cadastre as Redirect URLs:
   - `br.com.mocochovisk.app://login-callback` para Android/iOS;
   - `http://localhost:3000/` para desenvolvimento web;
   - a URL HTTPS exata de sua publicação web.
4. Preserve `{{ .ConfirmationURL }}` nos templates de confirmação/recuperação.
5. Execute **todo** o arquivo `supabase/migrations/001_init.sql` no SQL Editor.
   Ele cria também o bucket privado `receipts` e suas policies.
6. Copie um dos arquivos de configuração de exemplo e preencha os dados reais.

```powershell
Copy-Item config/supabase.example.json config/supabase.json
Copy-Item config/supabase.web.example.json config/supabase.web.json
```

Não use secret/service_role no cliente. Os arquivos reais de configuração são
ignorados pelo Git. Somente URL, chave pública e endereço de retorno entram nos
`dart-define`; a autorização é aplicada no banco por RLS.

Detalhes do banco e das decisões de negócio em [supabase/README.md](supabase/README.md).

## Executar

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter.ps1 run --dart-define-from-file=config/supabase.json
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter.ps1 run -d chrome --web-port=3000 --dart-define-from-file=config/supabase.web.json
```

Sem configuração válida, o app apresenta orientação para conectar ao Supabase.
Sem a migration, as telas de dados apresentam erro com opção de tentar novamente.

## Roteiro de validação das etapas 1 a 4

1. Cadastre uma conta, confirme o e-mail, entre, feche/reabra e confira a sessão.
   Solicite recuperação e defina uma nova senha no mesmo dispositivo/perfil.
2. Cadastre dois fornecedores; altere contatos, filtre ativos e abra os detalhes.
3. Em Mais → Ingredientes, cadastre um ingrediente em g. Registre 1 kg a R$ 20
   e 2 kg a R$ 50 em fornecedores diferentes. Compare R$ 0,020000/g com
   R$ 0,025000/g; confira histórico, variação e gráfico após nova cotação.
4. No Extrato, registre entrada e saída paga. Na saída, selecione fornecedor e
   ative o registro da compra de ingrediente; confira a cotação gerada.
5. Anexe um PDF ou imagem, abra o detalhe e confira o comprovante.
6. Crie e edite categorias em Mais → Categorias. Registros em uso não podem ser
   excluídos sem resolver seus vínculos.
7. Crie uma recorrência vencida em Mais → Recorrências e atualize os dados.
   Confira os lançamentos pendentes, atualize novamente e verifique que não
   duplicam. Marque um lançamento como pago.
8. Combine filtros do extrato e confira totais, agrupamento diário e acumulado.
9. Entre com outra conta: fornecedores, ingredientes, lançamentos, views e
   comprovantes da primeira conta devem permanecer inacessíveis.
10. Confira modo escuro, fonte ampliada, telas estreitas e falhas de rede.

## Verificações automatizadas

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter.ps1 analyze --no-pub
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter.ps1 test --no-pub
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter.ps1 build web --no-pub
```

A suíte cobre autenticação, navegação, configuração, formulários, falhas de
persistência, filtros, saldos, conversão de unidades, decimais e histórico.

Verificado nesta entrega: 57 testes aprovados, uma captura visual opcional
ignorada, análise sem issues e build web compilado. O teste SQL local também
passou. Os serviços de e-mail e comprovantes ainda precisam da validação em
um projeto Supabase real; builds Android/iOS não foram executados nesta entrega.

`scripts/validate_sql.mjs` executa a migration duas vezes e testa RLS, integridade
entre donos, compra atômica, histórico imutável, recorrências e custos. Para
executá-lo com Node e npm instalados:

```powershell
npm install --prefix .tooling/sql-validation --no-save @electric-sql/pglite
node scripts/validate_sql.mjs
```

Esse teste usa Postgres em WASM: Auth e Storage são representados por schemas
mínimos; somente a criação da extensão pgcrypto é omitida (gen_random_uuid já
existe no Postgres). Ele não substitui o teste em um Supabase real.

## Gerar builds

```sh
flutter build apk --debug --dart-define-from-file=config/supabase.json
flutter build appbundle --release --dart-define-from-file=config/supabase.json
flutter build ios --release --no-codesign --dart-define-from-file=config/supabase.json
flutter build ipa --release --dart-define-from-file=config/supabase.json
flutter build web --release --dart-define-from-file=config/supabase.web.json
```

No Windows, os comandos podem ser passados ao script acima. Android release
ainda exige configurar um keystore próprio; o template utiliza assinatura debug.
iOS exige macOS e assinatura configurada no Xcode.

## Organização e decisões

`lib/core` reúne configuração, navegação, tema, formatação e componentes.
`lib/features/auth` mantém domínio/repositório/controller de autenticação.
As features de fornecedores, ingredientes, transações e extrato reutilizam o
repositório financeiro injetável e o editor de formulários; regras de preços e
filtros ficam em módulos de domínio separados da apresentação. O banco aplica
cálculos e operações que precisam de atomicidade. Modelos pequenos usam mapas
tipados como `DataRow`; DTOs próprios podem ser introduzidos com a etapa 5.

Assumimos um dono por conta, sem equipe compartilhada e sem controle de estoque.
Valores financeiros usam Decimal/centavos no Dart e numeric no Postgres;
double é usado somente para desenhar o gráfico.

Cache offline, fila de sincronização e execução de recorrências com o app
fechado ficam fora desta entrega. As recorrências vencidas são geradas ao abrir
uma tela de dados ou atualizar a lista. Exportações pertencem à etapa 7.
