import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/br_formatters.dart';
import '../../../../core/widgets/finance_record_tile.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../../core/widgets/financial_charts.dart';
import '../../../../core/widgets/premium_finance.dart';
import '../../../dashboard/domain/dashboard_report.dart';
import '../../../ingredients/domain/price_history.dart';
import '../../../settings/presentation/pages/cost_settings_page.dart';
import '../../../transactions/data/finance_repository.dart';
import '../../../transactions/domain/statement_filter.dart';
import '../../domain/product_financials.dart';
import 'products_page.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FinanceBody(
    title: 'Produto',
    builder: (snapshot) {
      final product = snapshot
          .rows('products')
          .where((row) => row['id'] == id)
          .firstOrNull;
      if (product == null) {
        return [
          const SliverToBoxAdapter(
            child: FinanceEmptyState(
              message: 'Produto excluído ou não encontrado.',
              icon: CupertinoIcons.cube_box,
            ),
          ),
        ];
      }
      final row = snapshot
          .rows('product_costs')
          .where((row) => row['id'] == id)
          .firstOrNull;
      final financials = row == null
          ? null
          : ProductFinancials.fromDatabase(row);
      final preferences = CostPreferences.fromSnapshot(snapshot);
      final recipe = snapshot
          .rows('product_recipe_items')
          .where((item) => item['product_id'] == id)
          .toList();
      final ingredientCosts = {
        for (final cost in snapshot.rows('ingredient_costs'))
          cost['id']: decimalOrNull(cost['unit_cost']),
      };
      final ingredients = {
        for (final ingredient in snapshot.rows('ingredients'))
          ingredient['id']: ingredient,
      };
      final history =
          snapshot
              .rows('product_cost_history')
              .where((item) => item['product_id'] == id)
              .toList()
            ..sort(
              (first, second) => (first['revision'] as num).compareTo(
                second['revision'] as num,
              ),
            );
      final range = DateRange(
        history.isEmpty
            ? DateTime.now()
            : DateTime.parse(history.first['observed_on']),
        DateTime.now(),
      );
      final recipeIds = recipe.map((item) => item['ingredient_id']).toSet();
      final prices = PriceHistory.chronological(
        snapshot
            .rows('ingredient_prices')
            .where((price) => recipeIds.contains(price['ingredient_id'])),
      ).reversed.take(8);
      return [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                product['name'],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product['category'],
                style: TextStyle(
                  color: AppTheme.secondaryTextColor.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 20),
              PremiumSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeading(
                      'Resumo financeiro',
                      subtitle: 'Estimativa por unidade vendida',
                    ),
                    LabeledAmount(
                      label: 'Preço de venda',
                      amount: money(decimalOrNull(product['sale_price'])),
                    ),
                    LabeledAmount(
                      label: 'Custo de fabricação',
                      amount: financials?.cost == null
                          ? 'Indisponível'
                          : money(financials!.cost),
                    ),
                    LabeledAmount(
                      label: 'Lucro bruto estimado',
                      amount: financials?.profit == null
                          ? '—'
                          : money(financials!.profit),
                    ),
                    LabeledAmount(
                      label: 'Margem sobre a venda',
                      amount: financials?.marginPercent == null
                          ? '—'
                          : '${localizedDecimal(financials!.marginPercent!)}%',
                      color: financials?.lowMargin == true
                          ? FinancePalette.warning.resolveFrom(context)
                          : FinancePalette.income.resolveFrom(context),
                    ),
                    LabeledAmount(
                      label: 'Markup (venda ÷ custo)',
                      amount: financials?.markup == null
                          ? '—'
                          : '${localizedDecimal(financials!.markup!, 3)}×',
                    ),
                    LabeledAmount(
                      label:
                          'Preço sugerido · meta ${localizedDecimal(preferences.targetMargin * Decimal.fromInt(100))}%',
                      amount: financials?.suggestedPrice == null
                          ? '—'
                          : money(financials!.suggestedPrice),
                    ),
                    const SizedBox(height: 12),
                    if (financials?.lowMargin == true)
                      const MarginNotice(
                        message: 'A margem deste produto está abaixo da meta. Revise o preço ou os custos da ficha.',
                      ),
                    if (financials?.cost == null)
                      const MarginNotice(
                        message: 'Complete a ficha e registre preços compatíveis com o método escolhido. Ingredientes sem custo não são tratados como gratuitos.',
                        warning: false,
                      ),
                    const SizedBox(height: 12),
                    Text(
                      '${preferences.methodLabel}. A margem considera apenas os ingredientes, não o lucro líquido do bar.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppTheme.secondaryTextColor.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                children: [
                  CupertinoButton(
                    onPressed: () => editProduct(context, ref, product),
                    child: const Text('Editar produto'),
                  ),
                  CupertinoButton(
                    onPressed: () => openFinancePage<void>(
                      context,
                      const CostSettingsPage(),
                    ),
                    child: const Text('Ajustar cálculo'),
                  ),
                ],
              ),
              SectionHeading(
                'Ficha técnica',
                subtitle: 'Quantidade na unidade base. Perda aumenta a quantidade consumida.',
                action: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _editRecipe(context, ref, snapshot),
                  child: const Icon(
                    CupertinoIcons.add,
                    semanticLabel: 'Adicionar ingrediente à receita',
                  ),
                ),
              ),
              FinanceSection(
                children: [
                  for (final item in recipe)
                    FinanceRecordTile(
                      id: item['id'],
                      title: snapshot.name(
                        'ingredients',
                        item['ingredient_id'],
                      ),
                      subtitle:
                          '${localizedDecimal(Decimal.parse(item['quantity'].toString()), 3)} ${ingredients[item['ingredient_id']]?['base_unit'] ?? ''} · perda ${localizedDecimal(Decimal.parse(item['loss'].toString()) * Decimal.fromInt(100))}%\nCusto na receita: ${money(RecipeComponent(quantity: Decimal.parse(item['quantity'].toString()), loss: Decimal.parse(item['loss'].toString()), unitCost: ingredientCosts[item['ingredient_id']]).cost)}',
                      onEdit: () => _editRecipe(context, ref, snapshot, item),
                      onDelete: () => deleteRecord(
                        context,
                        ref,
                        'product_recipe_items',
                        item['id'],
                      ),
                    ),
                ],
              ),
              PremiumSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeading(
                      'Evolução do custo',
                      subtitle: 'Custos observados desde a ativação do histórico. Alterações anteriores não são reconstruídas.',
                    ),
                    FinancialLineChart(
                      series: [
                        ValueSeries(
                          product['name'],
                          DashboardHistory.product(snapshot, id, range),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FinanceSection(
                title: 'Preços recentes dos ingredientes da ficha atual',
                children: [
                  for (final price in prices)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LabeledAmount(
                            label: snapshot.name(
                              'ingredients',
                              price['ingredient_id'],
                            ),
                            amount:
                                'R\$ ${localizedDecimal(Decimal.parse(price['unit_price'].toString()), 6)}/${ingredients[price['ingredient_id']]?['base_unit'] ?? ''}',
                          ),
                          Text(
                            '${snapshot.name('suppliers', price['supplier_id'])} · ${BrFormatters.date(DateTime.parse(price['date']))}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.secondaryTextColor.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ];
    },
  );
  Future<void> _editRecipe(
    BuildContext context,
    WidgetRef ref,
    FinanceSnapshot snapshot, [
    DataRow? item,
  ]) async {
    final used = snapshot
        .rows('product_recipe_items')
        .where((row) => row['product_id'] == id && row['id'] != item?['id'])
        .map((row) => row['ingredient_id'])
        .toSet();
    final options = {
      for (final ingredient
          in snapshot
              .rows('ingredients')
              .where((row) => !used.contains(row['id'])))
        ingredient['id'] as String:
            '${ingredient['name']} (${ingredient['base_unit']})',
    };
    if (options.isEmpty) {
      await showFinanceError(
        context,
        const FormatException(
          'Cadastre um ingrediente ou edite os ingredientes já incluídos na ficha.',
        ),
      );
      return;
    }
    await editRecord(
      context,
      ref,
      title: item == null ? 'Adicionar ingrediente' : 'Editar ingrediente',
      table: 'product_recipe_items',
      initial: item == null
          ? null
          : {
              ...item,
              'loss_percent':
                  (Decimal.parse(item['loss'].toString()) *
                          Decimal.fromInt(100))
                      .toString(),
            },
      fields: [
        EditField(
          'ingredient_id',
          'Ingrediente e unidade base',
          required: true,
          options: options,
        ),
        const EditField(
          'quantity',
          'Quantidade na unidade indicada',
          required: true,
          number: true,
        ),
        EditField(
          'loss_percent',
          'Perda / quebra (%)',
          required: true,
          number: true,
          allowZero: true,
          defaultValue: '0',
          validate: CostPreferences.percentageError,
        ),
      ],
      transform: (values) {
        final loss = CostPreferences.percentToFraction(
          values.remove('loss_percent'),
        );
        return {...values, 'product_id': id, 'loss': loss.toString()};
      },
    );
  }
}
