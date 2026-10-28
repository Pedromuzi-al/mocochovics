# Bar do Mocochovisk

Aplicativo Flutter com interface Cupertino em português do Brasil e Supabase.
**Escopo atual: etapas 1 a 6.** Exportação PDF/CSV e os acabamentos finais da
etapa 7 ficam para a próxima entrega.

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
- Produtos com cadastro, ficha técnica, perdas, custo, lucro bruto estimado,
  margem, markup e preço sugerido a partir da margem-alvo.
- Configurações de método de custo, quantidade de compras para a média,
  margem-alvo e limite de aumento de preço em Mais → Custos e alertas.
- Dashboard com períodos, cards, gráficos interativos, rankings e alertas de
  preço/margem. Base Apple com destaque financeiro no painel e listas discretas
  nas demais áreas, conforme o prompt visual.
- Histórico de custos por produto, gerado automaticamente no banco pela
  migration 002 e protegido contra escrita direta pelo cliente.
- Produtos com filtros de margem baixa e custo indisponível, resumo legível de
  venda/custo/margem e ações de edição/exclusão em sheet, preservando os gestos.
- Indicadores do dashboard abrem os lançamentos do período com os filtros de
  entrada, saída paga, contas pendentes ou gastos com fornecedores. Os alertas
  permitem abrir diretamente as listas de produtos que precisam de atenção.
- Gráficos com consulta dos valores em uma lista acessível, sem depender do
  toque nos pontos. A seleção de categoria acompanha seu identificador mesmo
  quando a ordem das despesas muda ao atualizar o período.
- Fichas exibem quantidades com até seis casas e perdas com até quatro casas
  percentuais; metas e limites também preservam as casas aceitas no cadastro.

Os dados do aplicativo vêm do Supabase. Os registros fictícios existem somente
nos testes, inclusive nas capturas de tela. O saldo considera movimentos pagos;
as margens usam apenas os ingredientes e não representam lucro líquido.

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
5. Execute `supabase/migrations/001_init.sql` e depois
   `supabase/migrations/002_product_history.sql` no SQL Editor. O primeiro cria
   também o bucket privado `receipts`. Se a etapa 4 já está instalada, basta
   aplicar a migration 002. Ela preserva os cadastros existentes e registra uma
   observação inicial dos custos atuais, sem inventar valores de datas anteriores.
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
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter.ps1 run --device-id=web-server --web-hostname=localhost --web-port=3000 --dart-define-from-file=config/supabase.web.json
```

No Linux, com o SDK local deste workspace e a configuração já preenchida:

```bash
.tooling/flutter/bin/flutter pub get
.tooling/flutter/bin/flutter run -d web-server --web-hostname=127.0.0.1 --web-port=3000 --dart-define-from-file=config/supabase.web.json
```

Abra `http://localhost:3000` quando o terminal indicar que o servidor está pronto.
Para executar uma compilação pronta, use:

```bash
.tooling/flutter/bin/flutter build web --release --dart-define-from-file=config/supabase.web.json
python3 -m http.server 3000 --bind 127.0.0.1 --directory build/web
```

Sem configuração válida, o app apresenta orientação para conectar ao Supabase.
Sem a migration, as telas de dados apresentam erro com opção de tentar novamente.

## Roteiro de validação das etapas 1 a 6

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
11. Cadastre um produto vendido a R$ 10. Na ficha, adicione 100 g de ingrediente
    a R$ 0,02/g com perda de 10% e 50 ml de outro a R$ 0,03/ml. Confira custo
    R$ 3,70, lucro bruto R$ 6,30, margem 63%, markup 2,703× e sugestão R$ 5,29
    para a meta de 30%. Registre compras, não apenas cotações, para o método padrão.
12. Altere os preços e confira a atualização do produto e do histórico. Troque
    o método em Custos e alertas; sem compras/preços suficientes, o custo deve
    aparecer indisponível. Não deve virar zero por falta de informação.
13. No Início, troque entre hoje, sete dias, mês, mês anterior e personalizado.
    Compare os cards com os mesmos períodos do extrato. Pendências a receber
    não compõem as contas a pagar nem o saldo pago.
14. Toque em barras, linhas e categorias; selecione ingredientes/produtos nos
    gráficos. Confira rankings de fornecedores e margens. Alertas de preço
    respeitam o período; margens são a situação atual dos produtos.
15. Toque nos indicadores de entradas, saídas, pendências e fornecedores.
    Confira no extrato o mesmo período, os filtros ativos e os totais do card.
    O indicador de fornecedores não deve incluir saídas sem fornecedor.
16. Nos produtos, combine busca com os filtros de margem baixa e sem custo.
    Abra o menu de ações e confirme a exclusão; confira também os gestos.
    Com fonte ampliada, o filtro abre uma sheet para manter a legibilidade.
17. Use Ver valores nos gráficos para consultar números sem selecionar pontos,
    incluindo observações com custo indisponível nos históricos com lacunas.

## Verificações automatizadas

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter.ps1 analyze --no-pub
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter.ps1 test --no-pub
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter.ps1 build web --no-pub
```

A suíte cobre autenticação, navegação, configuração, formulários, falhas de
persistência, filtros, saldos, conversão de unidades, decimais, receitas, perdas,
margem, markup, configurações, períodos, agrupamentos, alertas e histórico.

Verificado nesta continuação das etapas 5 e 6: 93 testes aprovados com as capturas
visuais habilitadas (92 testes de comportamento e uma captura opcional), análise sem issues,
formatação verificada, build web compilado e testes SQL locais aprovados.
Os serviços de e-mail e comprovantes ainda precisam da validação em um projeto
Supabase real; builds Android/iOS não foram executados nesta entrega.

No Linux desta validação, `flutter analyze` encontrou uma falha de protocolo do
analisador quando executado no caminho com acento. A análise foi concluída em
uma cópia temporária das mesmas fontes em caminho ASCII, com o SDK fixado pelo
projeto. O SDK não foi alterado. Testes, capturas e build web usam a pasta original.

Para gerar as capturas, execute os testes com
`--dart-define=CAPTURE_PREVIEWS=true`. As imagens ficam em `build/previews/`:
login claro/escuro, dashboard claro/escuro, gráficos, lista de produtos e detalhe do produto.
Elas renderizam os widgets reais com registros exclusivamente de teste.

`scripts/validate_sql.mjs` executa as migrations duas vezes e testa RLS, integridade
entre donos, compra atômica, histórico imutável, recorrências, custos e as
permissões e atualizações do histórico dos produtos. Para
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

O build local mais recente em `build/web/` usa `config/supabase.web.json`.
Ao gerar um build em outro ambiente, informe a configuração pública do Supabase
com `--dart-define-from-file`; sem ela, o aplicativo abre a orientação de configuração.

## Organização e decisões

`lib/core` reúne configuração, navegação, tema, formatação e componentes.
`lib/features/auth` mantém domínio/repositório/controller de autenticação.
As features de fornecedores, ingredientes, transações e extrato reutilizam o
repositório financeiro injetável e o editor de formulários; regras de preços,
fichas técnicas, indicadores e filtros ficam em módulos de domínio independentes
dos widgets e do cliente Supabase. O banco aplica
cálculos e operações que precisam de atomicidade. Modelos pequenos usam mapas
tipados como `DataRow`; `ProductFinancials`, `RecipeComponent`, `CostPreferences`
e os modelos do dashboard representam cálculos e indicadores.

Assumimos um dono por conta, sem equipe compartilhada e sem controle de estoque.
Valores financeiros usam Decimal/centavos no Dart e numeric no Postgres;
double é usado somente para desenhar o gráfico.

Cache offline, fila de sincronização e execução de recorrências com o app
fechado ficam fora desta entrega. As recorrências vencidas são geradas ao abrir
uma tela de dados ou atualizar a lista. Exportações permanecem no roadmap funcional, separado das etapas de refinamento visual.

## Refinamento visual e animações

As oito etapas de refinamento foram aplicadas ao aplicativo existente: tokens
compartilhados, dashboard responsivo, extrato com filtros em sheet e chips,
listagens de produtos/fornecedores, telas secundárias, navegação lateral no
desktop e motion com redução de movimento. A inicialização web apresenta
carregamento e recuperação antes do primeiro frame Flutter.

Veja o [relatório de entrega e validação](docs/refinamento-visual-entrega.md)
e a [auditoria inicial](docs/auditoria-visual-etapa-1.md).

```bash
.tooling/flutter/bin/dart analyze lib test
.tooling/flutter/bin/flutter test --no-pub --dart-define=CAPTURE_PREVIEWS=true --dart-define=VISUAL_AUDIT=true
node scripts/validate_web_bootstrap.mjs
```

As capturas em `build/visual-audit/` usam fixtures de teste nas áreas autenticadas;
o login é verificado separadamente no navegador. Elas não comprovam operações
autenticadas em um Supabase real.

A navegação móvel usa uma barra flutuante com cinco destinos e mantém o menu
retrátil como atalho adicional. No desktop, a barra lateral pode ser recolhida
para ícones. O visual 2.0 aplica materiais adaptativos aos controles, animações
amortecidas, dashboard em verde profundo e formulários em sheets com proteção
contra descarte de alterações. Em **Mais → Aplicativo → Aparência**, escolha
**Sistema**, **Claro** ou **Escuro**; a preferência é salva no dispositivo.
Veja a [entrega Liquid Glass 2.0](docs/liquid-glass-2.0.md).
