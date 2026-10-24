import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/br_formatters.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../../core/widgets/financial_charts.dart';
import '../../../../core/widgets/premium_finance.dart';
import '../../../ingredients/presentation/pages/ingredients_page.dart';
import '../../../products/domain/product_financials.dart';
import '../../../products/presentation/pages/product_detail_page.dart';
import '../../../settings/presentation/pages/cost_settings_page.dart';
import '../../../suppliers/presentation/pages/suppliers_page.dart';
import '../../../transactions/data/finance_repository.dart';
import '../../../transactions/presentation/pages/transaction_editor.dart';
import '../../domain/dashboard_report.dart';

const _periodLabels = {
  DashboardPeriod.today: 'Hoje',
  DashboardPeriod.week: 'Últimos 7 dias',
  DashboardPeriod.month: 'Este mês',
  DashboardPeriod.previousMonth: 'Mês anterior',
  DashboardPeriod.custom: 'Personalizado',
};

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({this.currentDate, super.key});
  final DateTime? currentDate;
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  DashboardPeriod _period = DashboardPeriod.month;
  DateRange? _custom;
  String? _ingredientId, _productId;
  DateTime get _now => widget.currentDate ?? DateTime.now();
  DateRange get _range => _period == DashboardPeriod.custom && _custom != null
      ? _custom!
      : DateRange.period(_period, _now);

  Future<void> _selectPeriod() async {
    final selected = await showCupertinoModalPopup<DashboardPeriod>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('Período do dashboard'),
        actions: [
          for (final entry in _periodLabels.entries)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(sheetContext, entry.key),
              child: Text(entry.value),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('Cancelar'),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    if (selected == DashboardPeriod.custom) {
      final start = await chooseDate(context, _range.start);
      if (start == null || !mounted) return;
      final end = await chooseDate(
        context,
        _range.end.isBefore(start) ? start : _range.end,
      );
      if (end == null || !mounted) return;
      if (end.isBefore(start)) {
        await showFinanceError(
          context,
          const FormatException(
            'A data final deve ser igual ou posterior à inicial.',
          ),
        );
        return;
      }
      setState(() {
        _custom = DateRange(start, end);
        _period = selected;
      });
    } else {
      setState(() => _period = selected);
    }
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) => FinanceBody(
    title: 'Início',
    trailing: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => openFinancePage<void>(context, const CostSettingsPage()),
      child: const Icon(
        CupertinoIcons.slider_horizontal_3,
        semanticLabel: 'Configurar custos e alertas',
      ),
    ),
    builder: (snapshot) {
      final range = _range;
      final report = DashboardReport(snapshot, range);
      final preferences = CostPreferences.fromSnapshot(snapshot);
      final ingredients = snapshot.rows('ingredients').toList()
        ..sort((first, second) {
          final firstCount = snapshot
              .rows('product_recipe_items')
              .where((row) => row['ingredient_id'] == first['id'])
              .length;
          final secondCount = snapshot
              .rows('product_recipe_items')
              .where((row) => row['ingredient_id'] == second['id'])
              .length;
          return firstCount != secondCount
              ? secondCount.compareTo(firstCount)
              : first['name'].toString().compareTo(second['name'].toString());
        });
      final products = snapshot.rows('products');
      final ingredientId = ingredients.any((row) => row['id'] == _ingredientId)
          ? _ingredientId
          : ingredients.firstOrNull?['id'] as String?;
      final productId = products.any((row) => row['id'] == _productId)
          ? _productId
          : products.firstOrNull?['id'] as String?;
      final ingredient = ingredients
          .where((row) => row['id'] == ingredientId)
          .firstOrNull;
      final lowCount = report.lowMarginProducts.length;
      return [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BAR DO MOCOCHOVISK',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                            color: AppTheme.secondaryTextColor.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Seu bar, em números.',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  color: CupertinoColors.secondarySystemGroupedBackground
                      .resolveFrom(context),
                  borderRadius: BorderRadius.circular(20),
                  onPressed: _selectPeriod,
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.calendar, size: 18),
                      Text(
                        _periodLabels[_period]!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_down, size: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${BrFormatters.date(range.start)} — ${BrFormatters.date(range.end)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 20),
              _BalanceHero(report: report),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                  final columns = scale > 1.3
                      ? 1
                      : constraints.maxWidth >= 720
                      ? 4
                      : constraints.maxWidth >= 340
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - 12 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: width,
                        child: FinanceMetricCard(
                          label: 'Entradas pagas',
                          value: BrFormatters.currencyFromCents(
                            report.totals.income,
                          ),
                          icon: CupertinoIcons.arrow_down_left,
                          accent: FinancePalette.income,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: FinanceMetricCard(
                          label: 'Saídas pagas',
                          value: BrFormatters.currencyFromCents(
                            report.totals.expenses,
                          ),
                          icon: CupertinoIcons.arrow_up_right,
                          accent: FinancePalette.expense,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: FinanceMetricCard(
                          label: 'Pendente a pagar',
                          value: BrFormatters.currencyFromCents(
                            report.pendingPayables,
                          ),
                          icon: CupertinoIcons.clock,
                          accent: FinancePalette.warning,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: FinanceMetricCard(
                          label: 'Gasto com fornecedores',
                          value: BrFormatters.currencyFromCents(
                            report.supplierSpend,
                          ),
                          icon: CupertinoIcons.shippingbox,
                          accent: AppTheme.actionColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CupertinoButton.filled(
                    onPressed: () => editTransaction(context, ref, snapshot),
                    child: const Text('Novo lançamento'),
                  ),
                  CupertinoButton(
                    onPressed: () => context.go('/extrato'),
                    child: const Text('Ver extrato'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PremiumSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeading(
                      'Atenção às margens',
                      subtitle:
                          'Situação atual dos produtos · meta ${localizedDecimal(preferences.targetMargin * Decimal.fromInt(100))}%',
                    ),
                    LabeledAmount(
                      label: 'Produtos abaixo da meta',
                      amount:
                          '$lowCount ${lowCount == 1 ? 'produto' : 'produtos'}',
                      color: lowCount > 0
                          ? FinancePalette.warning.resolveFrom(context)
                          : FinancePalette.income.resolveFrom(context),
                    ),
                    if (report.missingCosts > 0)
                      MarginNotice(
                        message:
                            '${report.missingCosts} produto(s) ainda sem custo completo. Complete as fichas e os preços.',
                        warning: false,
                      ),
                    if (lowCount == 0 && report.missingCosts == 0)
                      Text(
                        products.isEmpty
                            ? 'Cadastre produtos e fichas técnicas para acompanhar as margens.'
                            : 'Nenhum produto abaixo da meta.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondaryTextColor.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    for (final product in report.lowMarginProducts.take(3))
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        onPressed: () => openFinancePage<void>(
                          context,
                          ProductDetailPage(id: product['id']),
                        ),
                        child: LabeledAmount(
                          label: product['name'],
                          amount:
                              '${localizedDecimal(ProductFinancials.fromDatabase(product).marginPercent!)}%',
                          color: FinancePalette.warning.resolveFrom(context),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _panel(
                'Entradas × saídas',
                'Movimentações pagas no período',
                CashFlowChart(report: report),
              ),
              _panel(
                'Evolução do saldo',
                'Saldo acumulado do período; inicia em zero.',
                FinancialLineChart(
                  series: report.hasPayments
                      ? [ValueSeries('Saldo', report.balancePoints)]
                      : [],
                  emptyMessage: 'Sem movimentações pagas neste período.',
                ),
              ),
              _panel(
                'Para onde foi o dinheiro',
                'Despesas pagas por categoria',
                ExpensesDonut(categories: report.categories),
              ),
              _panel(
                'Fornecedores por gasto',
                'Saídas pagas vinculadas a fornecedores',
                Column(
                  children: [
                    if (report.suppliers.isEmpty)
                      const FinanceEmptyState(
                        message: 'Nenhum gasto com fornecedor no período.',
                        icon: CupertinoIcons.person_2,
                      ),
                    for (final supplier in report.suppliers.take(5))
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        onPressed: () => openFinancePage<void>(
                          context,
                          SupplierDetailPage(id: supplier.id),
                        ),
                        child: LabeledAmount(
                          label: supplier.label,
                          amount: BrFormatters.currencyFromCents(
                            supplier.cents,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _panel(
                'Margens dos produtos',
                'Margem bruta dos ingredientes, calculada agora.',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (report.currentProducts.isEmpty)
                      const FinanceEmptyState(
                        message:
                            'Complete as fichas técnicas para ver o ranking.',
                        icon: CupertinoIcons.cube_box,
                      ),
                    if (report.currentProducts.isNotEmpty) ...[
                      const Text(
                        'MAIORES MARGENS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      for (final product
                          in report.currentProducts.reversed.take(3))
                        _productRank(product),
                      const SizedBox(height: 16),
                      const Text(
                        'MENORES MARGENS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      for (final product in report.currentProducts.take(3))
                        _productRank(product),
                    ],
                  ],
                ),
              ),
              _panel(
                'Preços dos ingredientes',
                'Compare o histórico por fornecedor. O primeiro ponto pode trazer o preço conhecido antes do período.',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (ingredients.isNotEmpty)
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        onPressed: () async {
                          final selected = await chooseOption(
                            context,
                            'Ingrediente',
                            {
                              for (final row in ingredients)
                                row['id'] as String: row['name'].toString(),
                            },
                          );
                          if (selected != null && mounted)
                            setState(() => _ingredientId = selected);
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ingredient?['name'] ?? 'Selecionar ingrediente',
                              ),
                            ),
                            const Icon(CupertinoIcons.chevron_down, size: 14),
                          ],
                        ),
                      ),
                    FinancialLineChart(
                      series: ingredientId == null
                          ? []
                          : DashboardHistory.ingredient(
                              snapshot,
                              ingredientId,
                              range,
                            ),
                      unit: ingredient?['base_unit'],
                      emptyMessage:
                          'Registre cotações para comparar os preços.',
                    ),
                  ],
                ),
              ),
              _panel(
                'Custos dos produtos',
                'Custos observados desde a ativação do histórico. Mudanças anteriores não são reconstruídas.',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (products.isNotEmpty)
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        onPressed: () async {
                          final selected = await chooseOption(
                            context,
                            'Produto',
                            rowOptions(snapshot, 'products'),
                          );
                          if (selected != null && mounted)
                            setState(() => _productId = selected);
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(snapshot.name('products', productId)),
                            ),
                            const Icon(CupertinoIcons.chevron_down, size: 14),
                          ],
                        ),
                      ),
                    FinancialLineChart(
                      series: productId == null
                          ? []
                          : [
                              ValueSeries(
                                snapshot.name('products', productId),
                                DashboardHistory.product(
                                  snapshot,
                                  productId,
                                  range,
                                ),
                              ),
                            ],
                    ),
                  ],
                ),
              ),
              _panel(
                'Alertas de preços',
                'Aumento acima de ${localizedDecimal(preferences.priceAlertThreshold * Decimal.fromInt(100))}% na última cotação de fornecedores ativos, dentro do período.',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (report.alerts.isEmpty)
                      const FinanceEmptyState(
                        message: 'Nenhum aumento acima do limite configurado.',
                        icon: CupertinoIcons.checkmark_shield,
                      ),
                    for (final alert in report.alerts)
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        onPressed: () => openFinancePage<void>(
                          context,
                          IngredientDetailPage(id: alert.ingredientId),
                        ),
                        child: MarginNotice(
                          message:
                              '${snapshot.name('ingredients', alert.ingredientId)} · +${localizedDecimal(alert.variation)}%\n${snapshot.name('suppliers', alert.supplierId)}',
                        ),
                      ),
                  ],
                ),
              ),
              const Text(
                'Valores pagos compõem o caixa. Margens usam custos diretos dos ingredientes e não representam lucro líquido.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ];
    },
  );

  Widget _panel(String title, String subtitle, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: PremiumSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeading(title, subtitle: subtitle),
          child,
        ],
      ),
    ),
  );
  Widget _productRank(Map<String, dynamic> product) => CupertinoButton(
    padding: const EdgeInsets.symmetric(vertical: 4),
    onPressed: () =>
        openFinancePage<void>(context, ProductDetailPage(id: product['id'])),
    child: LabeledAmount(
      label: product['name'],
      amount:
          '${localizedDecimal(ProductFinancials.fromDatabase(product).marginPercent!)}%',
      color: ProductFinancials.fromDatabase(product).lowMargin
          ? FinancePalette.warning.resolveFrom(context)
          : null,
    ),
  );
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.report});
  final DashboardReport report;
  @override
  Widget build(BuildContext context) {
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final reduced = MediaQuery.of(context).accessibleNavigation;
    final background = dark ? const Color(0xFF0C251C) : const Color(0xFFE4F3EC);
    final foreground = dark ? const Color(0xFF8BF0BD) : const Color(0xFF125435);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        gradient: reduced
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  background,
                  dark ? const Color(0xFF112C22) : const Color(0xFFF0F8F3),
                ],
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.chart_bar_alt_fill,
                size: 20,
                color: foreground,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Saldo do período',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            child: Text(
              BrFormatters.currencyFromCents(report.totals.balance),
              key: ValueKey(report.totals.balance),
              style: AppTheme.tabularFigures(
                TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.3,
                  color: foreground,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Entradas pagas − saídas pagas',
            style: TextStyle(fontSize: 12, color: foreground),
          ),
          const SizedBox(height: 6),
          Text(
            'O movimento do seu caixa, com clareza.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: foreground.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
