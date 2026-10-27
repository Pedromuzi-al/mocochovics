# Refinamento visual — entrega das etapas 1 a 8

Data: 27/10/2026. Implementação sobre a base `90172fb`, no projeto Flutter
existente. O usuário autorizou a execução de todas as etapas com validação
conjunta ao final. Nenhuma biblioteca de animação foi adicionada.

Atualização posterior: a navegação móvel passou para um menu retrátil e a
barra desktop passou a recolher para ícones. Foram acrescentados hovers e
animações de cards. Consulte [Hover, cards e menu retrátil](interacoes-menu-retratil.md).
Os resultados abaixo registram a entrega anterior a essa atualização.

## Etapas e arquivos

| Etapa | Resultado | Arquivos principais | Verificação |
| --- | --- | --- | --- |
| 1 — Auditoria | Estrutura, navegação, temas, estados e problemas A01–A16 registrados antes da implementação. | `docs/auditoria-visual-etapa-1.md`, `test/visual_audit_test.dart` | Cinco abas, páginas secundárias, fixtures e abertura real do login. |
| 2 — Design system | Tokens de tipografia, espaçamento, raios, larguras e movimento; cores semânticas existentes reaproveitadas. Componentes de loading, erro e vazio. | `design_tokens.dart`, `app_theme.dart`, `app_states.dart`, `premium_finance.dart`, `finance_widgets.dart` | Análise estática, capturas claro/escuro, números tabulares e redução de movimento. |
| 3 — Dashboard | Saudação contextual, saldo verde refinado, indicadores com largura uniforme em até quatro colunas, painéis em grid, ações de detalhamento e primeiro acesso dos produtos. Gráfico de margens e históricos com consulta textual. | `dashboard_page.dart`, `financial_charts.dart`, `premium_finance.dart` | Testes de períodos, alertas, gráficos e navegação dos indicadores; capturas após rolagem. |
| 4 — Extrato | Descrição principal, valor à direita quando há espaço, ícone de categoria, pagamento/status discretos e agrupamento por dia. Filtros em sheet com botão fixo de aplicação e chips removíveis. | `statement_page.dart`, `transaction_record_tile.dart` | Totais, acumulado, filtros combinados, aplicação/remoção de chip, detalhe e edição/exclusão. |
| 5 — Produtos e fornecedores | Listas sob demanda, ações em menu, estados de primeiro acesso/busca, seção de margem no produto, contatos e preços em formato brasileiro. Histórico completo do fornecedor e acesso ao extrato do período. | `products_page.dart`, `product_detail_page.dart`, `suppliers_page.dart` | Ficha, custos, margem indisponível, filtros, exclusão confirmada, histórico e catálogo de mil produtos. |
| 6 — Mais e secundárias | Listas agrupadas preservadas, cabeçalhos discretos, conta/logout refinados, formulários centrados e limitados a 640 px. Ingredientes reutilizam o gráfico compartilhado. | `settings_page.dart`, `ingredients_page.dart`, `categories_page.dart`, `recurring_page.dart`, `finance_widgets.dart` | Navegação, retorno, formulários, erros ao salvar e capturas secundárias. |
| 7 — Responsividade e animações | Sidebar a partir de 1000 px, conteúdo de gestão até 1040 px/dashboard até 1240 px. Navegação inferior adaptada à fonte ampliada. Seleção animada, feedback Cupertino/tátil, revelação inicial, contagem em mudanças e saída discreta após exclusão confirmada. | `app_shell.dart`, `feature_scaffold.dart`, `app_motion.dart`, `finance_record_tile.dart` | Redimensionamento preservando aba, telas estreitas com fonte de 200%, desktop com fonte ampliada, controllers descartados. |
| 8 — Validação | Testes, análise, formatação, SQL local, build web e revisão visual. Carregamento HTML antes do primeiro frame com recuperação em falhas e demora. | `web/index.html`, `web/flutter_bootstrap.js`, `scripts/validate_web_bootstrap.mjs`, testes | Resultados e limites abaixo. |

Os arquivos Dart de componentes ficam em `lib/core/theme` e `lib/core/widgets`;
as páginas ficam em `lib/features/<área>/presentation/pages`.

## Comportamento preservado

Auth, repositórios, regras de domínio, migrations, RLS, RPCs e views não foram
alterados. Os valores continuam vindo do Supabase; fixtures permanecem restritas
aos testes. Custos indisponíveis continuam distintos de zero. O histórico é
consultado, não reescrito. A exclusão continua exigindo confirmação; o fade só
começa após a exclusão ser aceita pelo repositório.

Os gráficos mantêm tooltips e consulta dos dados em lista, incluindo lacunas de
custo. As animações usam durações curtas e respeitam `disableAnimations`.
A semântica dos valores animados expõe imediatamente o valor atual exato.
Os estados de erro não exibem saldo zero como substituto dos dados.

As listagens principais de produtos, fornecedores e ingredientes agora usam
`SliverList.builder`, com chaves estáveis. No teste de mil produtos, apenas as
linhas próximas à área visível são montadas. O snapshot de dados continua sendo
carregado pelo repositório existente; esta entrega não implementa paginação
remota nem constitui uma medição de FPS com um banco grande.

## Validação automatizada

- Suíte completa com previews e auditoria habilitados: **107 testes aprovados**.
- Revisão ampliada posterior de navegação e layouts: **21 testes aprovados**, incluindo desktop com fonte de 200%.
- Auditoria visual final: dez perfis/cenários, com **178 capturas** e nenhuma exceção de layout coletada; cinco abas nos dois temas, celular/tablet/desktop, fonte ampliada, estados e páginas secundárias.
- `dart analyze lib test`: sem issues.
- Formatação Dart e `git diff --check`: verificados.
- Bootstrap web: sucesso, espera pelo primeiro frame, falhas do loader/engine e recuperação após demora aprovados pelo script Node.
- SQL local: migrations reaplicáveis, métodos de custo, margens, histórico imutável, compra atômica, recorrências idempotentes e isolamento aprovados em PGlite, com Auth/Storage simulados. Não aplica migrations no projeto remoto.

- Build web release: compilado com a configuração pública local do Supabase.
- Chrome real: seis aberturas do login (celular, tablet e desktop, claro/escuro),
  primeiro frame renderizado em todas e nenhuma exceção JavaScript capturada.
  A indisponibilidade do próprio `flutter_bootstrap.js` também foi simulada;
  a mensagem de recuperação e o botão Atualizar página apareceram.

O relatório do navegador fica em `build/visual-audit/browser/report.json`;
os logs das verificações ficam em `build/validation/`. O build está servido em
`http://localhost:3000` para a revisão local.

## Capturas para revisar

As imagens usam dados exclusivamente de teste, identificados por e-mails `.example`.
São geradas em `build/`, ignorado pelo Git, pelos comandos abaixo.

- [Dashboard desktop](../build/visual-audit/desktop-light/dashboard.png).
- [Gráficos desktop](../build/visual-audit/desktop-light/dashboard-charts-2.png).
- [Extrato mobile](../build/visual-audit/mobile-light/statement.png).
- [Filtros mobile](../build/visual-audit/mobile-light/statement-filters.png).
- [Produtos mobile](../build/visual-audit/mobile-light/products.png).
- [Fornecedor e preços](../build/visual-audit/desktop-light/supplier-detail-lower.png).
- [Primeiro acesso de fornecedores](../build/visual-audit/mobile-light/suppliers-empty.png).
- [Mais escuro](../build/visual-audit/desktop-dark/settings.png).
- [Desktop com fonte de 200%](../build/visual-audit/desktop-large-text-light/statement-lower.png).
- [Celular com fonte de 200%](../build/visual-audit/large-text-light/products-lower.png).

## Reproduzir

```bash
.tooling/flutter/bin/dart format --output=none --set-exit-if-changed lib test
.tooling/flutter/bin/dart analyze lib test
.tooling/flutter/bin/flutter test --no-pub --dart-define=CAPTURE_PREVIEWS=true --dart-define=VISUAL_AUDIT=true
node scripts/validate_web_bootstrap.mjs
.tooling/flutter/bin/flutter build web --release --dart-define-from-file=config/supabase.web.json
python3 -m http.server 3000 --bind 127.0.0.1 --directory build/web
```

Para desenvolvimento com hot reload, use o comando `flutter run -d web-server`
do README. Use apenas um servidor por vez na porta 3000.

## Validação que depende do ambiente real

As telas autenticadas foram testadas com o roteador e widgets reais, usando
repositórios isolados. Cadastro/login real, e-mail, upload de comprovantes e
persistência de CRUD no Supabase precisam da validação com sua conta. Não foram
criadas contas nem feitas alterações em dados de produção nesta entrega.

Não foram executados builds Android/iOS nem testes em aparelhos físicos,
VoiceOver/TalkBack, teclado virtual real ou medições de fluidez. Redução de
movimento e fonte ampliada foram verificadas por testes Flutter; o fundo opaco
reduz o uso de transparência sem depender de uma configuração específica do SO.
A aprovação estética final permanece com você, conforme solicitado.
