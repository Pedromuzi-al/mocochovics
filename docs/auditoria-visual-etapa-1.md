# Auditoria visual — Etapa 1

Data: 27/10/2026. Código de referência: `90172fb` (`visual novo`).

Registro histórico do diagnóstico anterior às alterações. Depois desta auditoria,
o usuário autorizou a execução de todas as etapas e a validação conjunta ao final.
A implementação e as verificações finais estão em
[Refinamento visual — entrega](refinamento-visual-entrega.md). As observações
abaixo descrevem a base `90172fb`; as imagens em `build/visual-audit` são
regeneráveis e agora mostram a versão refinada, não a base anterior.

## Estrutura confirmada

| Área | Implementação atual |
| --- | --- |
| SDK | Flutter 3.47.5, Dart 3.13.4; versão fixada em `.fvmrc` |
| Interface | Cupertino, localização pt-BR, Inter na web/Android e fonte do sistema nas plataformas Apple nativas |
| Estado | Riverpod 3.4.3; autenticação por controller; dados financeiros por `financeSnapshotProvider` |
| Rotas | GoRouter 18.0.2, `StatefulShellRoute.indexedStack`, cinco abas com pilhas preservadas |
| Backend | Supabase Flutter 2.18.0; Auth, Postgres, Storage; migrations 001 e 002 presentes |
| Financeiro | Regras de domínio com Decimal/centavos; views e RPCs no banco; cálculos separados dos widgets |
| Gráficos | fl_chart 1.2.0; componentes compartilhados e um gráfico específico de ingredientes |
| Componentes | `FeatureScaffold`, `FinanceBody`, `FinanceSection`, `RecordEditor`, `FinanceRecordTile`, `PremiumSurface`, `FinanceMetricCard`, `LabeledAmount` |
| Tema | `AppTheme` e `FinancePalette`; claro/escuro automáticos; números tabulares em parte dos componentes |
| Movimento | Transições Cupertino, feedback tátil, `AnimatedSwitcher` de 180 ms e gráficos compartilhados de 220 ms |

O sistema de cores está parcialmente centralizado. Tipografia, espaçamentos,
raios, durações e limites de largura ainda aparecem como valores locais.
Não há um sistema compartilhado de entrada de cards, contagem financeira ou
animação de inserção/remoção de listas.

## Como foi verificado

A aplicação existente foi executada em `http://localhost:3000`. O login foi
aberto no Chrome headless em 390 × 844, 834 × 1112 e 1440 × 1000, nos dois temas:
seis capturas, uma view Flutter renderizada em cada caso e nenhuma exceção
JavaScript capturada. Nenhum login, cadastro ou alteração no banco foi feito.

As áreas autenticadas foram renderizadas com os widgets e o roteador reais,
usando exclusivamente os repositórios de teste já existentes. Isso permite
inspecionar dados, vazios, erros e carregamento sem preencher o banco do bar.
Essas capturas não comprovam autenticação ou persistência remota.

| Perfil | Dimensões lógicas | Fonte | Temas | Capturas por tema |
| --- | --- | --- | --- | --- |
| Celular | 390 × 844 | 100% | Claro e escuro | 30 |
| Tablet | 834 × 1112 | 100% | Claro e escuro | 5 |
| Desktop | 1440 × 1000 | 100% | Claro e escuro | 30 |
| Acessibilidade | 320 × 740 | 200% | Claro e escuro | 5 |

Total: **140 capturas de widgets**, além das seis capturas do navegador.
Os oito cenários passaram sem exceções de layout reportadas pelo Flutter.
Isso não equivale a aprovação visual: há quebras de texto e hierarquia
insatisfatória mesmo sem `RenderFlex overflow`.

Foram inspecionadas as cinco abas. Em celular e desktop, também foram abertos:
ingredientes, categorias, recorrências, custos e alertas, Sobre, filtros do
extrato, lançamento financeiro, detalhe de produto, detalhe de fornecedor,
detalhe de ingrediente e formulários de fornecedor, produto, recorrência e
configurações. Algumas páginas longas têm capturas após rolagem.

## Problemas registrados antes da implementação

P1 indica prioridade de legibilidade ou responsividade. P2 indica refinamento
de apresentação, consistência ou interação. As prioridades são uma avaliação
da auditoria, não erros de cálculo financeiro.

| ID | Prioridade | Evidência e impacto | Arquivos principais | Etapa prevista |
| --- | --- | --- | --- | --- |
| A01 | P1 | A tab bar ocupa os 1440 px no desktop enquanto o conteúdo fica limitado a 800 px. Grandes margens e navegação distante do conteúdo confirmam a experiência de celular ampliado. | `app_shell.dart`, `feature_scaffold.dart` | 2 e 7 |
| A02 | P1 | Com fonte de 200% em 320 px, rótulos como “Extrato”, “Produtos” e “Fornecedores” quebram em várias linhas. Não há overflow reportado, mas a navegação perde legibilidade. | `app_shell.dart` | 2 e 7 |
| A03 | P1 | Formulários financeiros ocupam quase toda a largura do desktop, com campos e botão Salvar muito extensos. A largura não segue o limite das páginas de gestão nem um limite próprio de formulário. | `finance_widgets.dart`, `transaction_editor.dart` | 2 e 6 |
| A04 | P1 | No extrato claro, valores usam `systemGreen` e `systemRed` sobre `#F2F2F7`. O contraste calculado é aproximadamente 1,99:1 e 3,18:1; fica abaixo de 4,5:1 para texto normal. As cores financeiras já existentes em `FinancePalette` têm aproximadamente 5,13:1 e 5,16:1 sobre esse fundo. | `statement_page.dart:264`, `premium_finance.dart` | 2 e 4 |
| A05 | P1 | O extrato destaca o valor à esquerda e coloca descrição/status em texto secundário pequeno. Falta uma linha financeira com descrição principal, valor à direita, forma de pagamento, ícone e status discreto. O resumo usa valores em subtítulos pequenos. | `statement_page.dart`, `finance_record_tile.dart` | 4 |
| A06 | P2 | Os cards do dashboard não preenchem uniformemente suas células. A superfície cresce conforme o conteúdo do botão: cards com rótulos curtos ficam mais estreitos. É visível no desktop, tablet e no dashboard vazio. | `premium_finance.dart:178`, `dashboard_page.dart:251` | 2 e 3 |
| A07 | P2 | O dashboard já orienta a cadastrar produtos quando não há nenhum, mas mantém “0 produtos” em verde na seção de margem. Falta apresentar essa condição como configuração inicial com ação direta de cadastro. | `dashboard_page.dart:350` | 3 |
| A08 | P2 | Fornecedores e ingredientes vazios recebem somente “Nenhum registro encontrado.”; buscas sem resultado reutilizam a mesma apresentação. Produtos têm ícone, explicação e CTA, mas falta o título de primeiro acesso pedido. O extrato vazio não oferece uma ação contextual. | `finance_widgets.dart:138`, `suppliers_page.dart`, `ingredients_page.dart`, `products_page.dart`, `statement_page.dart` | 2, 4 e 5 |
| A09 | P2 | Loading apresenta um spinner próximo ao topo; erro apresenta texto e Tentar novamente. Há distinção funcional entre dados e erro, mas faltam título, ícone, contexto e composição visual reutilizável. | `finance_widgets.dart:103` | 2 e 6 |
| A10 | P2 | Filtros do extrato abrem uma página inteira, com dois botões Salvar, em vez de uma sheet. Alguns filtros ativos aparecem em texto, mas categoria, fornecedor específico e pagamento não aparecem nessa indicação; não existem chips removíveis. | `statement_page.dart:65`, `finance_widgets.dart:190` | 4 |
| A11 | P2 | A lista de fornecedores mostra nome e ativo/inativo, mesmo havendo telefone preenchido no teste. Editar/excluir ficam expostos em todas as linhas; falta o contato secundário e o chevron pedido. | `suppliers_page.dart:70`, `finance_record_tile.dart` | 5 |
| A12 | P2 | No detalhe do fornecedor, o preço unitário aparece como `R$ 0.070 por unidade base`: separador decimal não brasileiro e unidade pouco explícita. A tela tem preços atuais e total gasto, mas não apresenta uma seção própria de histórico de compras/preços. | `suppliers_page.dart` | 5 |
| A13 | P2 | “Mais” mantém boa base de listas agrupadas e deve ser preservada. Os cabeçalhos de seção estão muito destacados em relação às linhas e podem usar uma hierarquia mais discreta. O bloco de conta e o logout podem melhorar sem novos cards coloridos. | `settings_page.dart` | 6 |
| A14 | P2 | Números fazem crossfade, não contagem; não existe revelação inicial controlada dos cards ou transição própria de listas/ícones de abas. Durações e curvas não são tokens compartilhados. | `premium_finance.dart`, `dashboard_page.dart`, `app_shell.dart` | 2, 3 e 7 |
| A15 | P2 | Os gráficos compartilhados já respeitam `disableAnimations` e oferecem tooltips/lista de valores. O gráfico `PriceEvolution` de ingredientes usa implementação separada, sem configurar duração reduzida ou tooltip BRL/data. Margens de produtos aparecem como ranking textual, não como gráfico. | `financial_charts.dart`, `ingredients_page.dart:347`, `dashboard_page.dart` | 3, 6 e 7 |
| A16 | P2 | O cabeçalho HTML não tem estado visual de carregamento anterior ao primeiro frame Flutter. Durante a compilação inicial, uma abertura antecipada pode parecer uma tela travada, como observado no diagnóstico anterior do localhost. | `web/index.html`, `main.dart`, `app_bootstrap.dart` | 6 |

Os contrastes de A04 foram calculados a partir dos valores RGB do SDK fixado,
com a fórmula de luminância relativa e contraste WCAG. A referência de 4,5:1
para texto normal consta nas orientações de [acessibilidade da Apple](https://developer.apple.com/design/human-interface-guidelines/accessibility).

### Evidências visuais principais

- [Dashboard desktop](../build/visual-audit/desktop-light/dashboard.png): largura, alinhamento dos cards e navegação.
- [Dashboard tablet escuro](../build/visual-audit/tablet-dark/dashboard.png): quatro indicadores e distribuição do espaço.
- [Extrato mobile](../build/visual-audit/mobile-light/statement.png): hierarquia dos totais e movimentações.
- [Fonte de 200%](../build/visual-audit/large-text-light/statement.png): quebras dos rótulos inferiores.
- [Formulário desktop](../build/visual-audit/desktop-light/transaction-form.png): campos sem limite de largura apropriado.
- [Filtros mobile](../build/visual-audit/mobile-light/statement-filters.png): apresentação em página.
- [Fornecedores vazios](../build/visual-audit/mobile-light/suppliers-empty.png): mensagem genérica sem ação de primeiro acesso.
- [Produtos mobile](../build/visual-audit/mobile-light/products.png): base atual a preservar.
- [Mais escuro](../build/visual-audit/desktop-dark/settings.png): listas agrupadas e hierarquia dos títulos.
- [Detalhe do fornecedor](../build/visual-audit/desktop-light/supplier-detail-lower.png): preços e dados de contato.
- [Erro de conexão](../build/visual-audit/desktop-light/statement-error.png): tentativa novamente sem composição contextual.
- [Login real no navegador](../build/visual-audit/browser/login-desktop-light.png): aplicativo web iniciado com sua configuração local.

As imagens ficam em `build/`, ignorado pelo Git. Os dados financeiros e contatos
mostrados nas capturas autenticadas são exclusivamente de teste.

## O que preservar

- Cinco áreas, rotas protegidas, pilhas por aba e navegação de retorno.
- Valores monetários corretos, distinção entre pago/pendente, filtros e saldos.
- CRUD, validações inline, bloqueio de envio duplicado e confirmação de exclusão.
- Compra vinculada ao lançamento, comprovantes privados, históricos e métodos de custo.
- Cores semânticas, números tabulares, contraste do dashboard e tema escuro existente.
- Produtos com custo desconhecido identificados como indisponíveis.
- Listas de ficha técnica simples; card premium restrito aos resumos financeiros.
- Tooltips e consulta textual de valores dos gráficos compartilhados.
- Separação entre repositórios de teste e integração Supabase da aplicação.

## Performance e acessibilidade ainda a medir

Algumas listas são construídas integralmente dentro de `SliverToBoxAdapter` e
`FinanceSection`; o extrato já usa `SliverList.builder`. A leitura financeira
carrega todas as tabelas e históricos, em lotes de 500, em um snapshot comum.
Isso merece atenção ao introduzir animações. Não foram medidos FPS, memória
ou desempenho com um grande banco real; não há evidência para prometer 60 FPS.

Componentes Cupertino já fornecem parte do comportamento de teclado, foco e
pressão. Ainda é necessário revisar a ordem de foco em formulários completos,
leitores de tela reais, teclado virtual, redução de transparência, alto contraste
e gestos em aparelhos iOS/Android. A ausência de código próprio de hover/foco
não significa que os controles nativos não tenham esse suporte.

## Verificações executadas

- Suíte existente: **92 testes de comportamento aprovados**, uma captura opcional pulada.
- Auditoria visual: **8 testes aprovados**, **140 capturas**, nenhuma exceção de layout coletada.
- Chrome: **6 aberturas do login** nas três resoluções e nos dois temas; sem exceções JavaScript capturadas.
- `dart analyze lib test`: sem issues na base; repetido após acrescentar o teste diagnóstico.
- `dart format --output=none --set-exit-if-changed lib test`: executado sem alterações pendentes.
- `git diff --check`: executado.

Não foi necessário gerar outro build nesta etapa: nenhum arquivo da aplicação
foi alterado. A execução web usa o servidor já ativo.

Os testes de interface usam repositórios isolados. E-mail, upload/download,
persistência e operações autenticadas em um Supabase real não foram revalidados
nesta auditoria. Não houve alteração de tabelas, policies, views, RPCs ou contas.

### Reproduzir as capturas autenticadas

```bash
.tooling/flutter/bin/flutter test --no-pub test/visual_audit_test.dart \
  --dart-define=VISUAL_AUDIT=true --reporter expanded
```

O teste é pulado por padrão. Cada perfil gera um `report.json` com a lista de
capturas e as exceções coletadas; havendo exceção, o cenário falha.

## Encaminhamento original — Design system

A proposta original para a Etapa 2 era entregar:

1. Tokens de cor, contraste, tipografia, espaçamento, raios e movimento,
   preservando os estilos Apple e os destaques financeiros existentes.
2. Limites de largura por tipo de conteúdo e primitivas para o shell adaptativo.
3. Componentes de estado vazio/erro/loading com título, mensagem e ação.
4. Primitivas de linha financeira, status, filtro ativo e card com largura consistente.
5. Movimento reutilizável com redução de animações e sem repetição a cada rebuild.

O sistema foi aplicado ao dashboard, extrato e demais telas nas Etapas 3 a 7.
A instrução posterior do usuário substituiu as pausas por uma validação completa
ao final da entrega.
Referências: [Layout](https://developer.apple.com/design/human-interface-guidelines/layout),
[Motion](https://developer.apple.com/design/human-interface-guidelines/motion) e
[Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility).
