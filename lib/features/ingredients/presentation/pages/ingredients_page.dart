import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/br_formatters.dart';
import '../../../../core/utils/financial_math.dart';
import '../../../../core/widgets/finance_record_tile.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../transactions/data/finance_repository.dart';
import '../../../transactions/domain/statement_filter.dart';
import '../../domain/price_history.dart';

const ingredientCategories = {
  'bebida': 'Bebida',
  'carne': 'Carne',
  'hortifruti': 'Hortifruti',
  'laticinio': 'Laticínio',
  'descartavel': 'Descartável',
  'outros': 'Outros',
};

class IngredientsPage extends ConsumerStatefulWidget {
  const IngredientsPage({super.key});
  @override
  ConsumerState<IngredientsPage> createState() => _IngredientsPageState();
}

class _IngredientsPageState extends ConsumerState<IngredientsPage> {
  String _search = '';
  @override
  Widget build(BuildContext context) => FinanceBody(
    title: 'Ingredientes',
    trailing: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => editIngredient(context, ref),
      child: const Icon(CupertinoIcons.add, semanticLabel: 'Novo ingrediente'),
    ),
    builder: (snapshot) {
      final ingredients =
          snapshot
              .rows('ingredients')
              .where(
                (row) => row['name'].toString().toLowerCase().contains(
                  _search.toLowerCase(),
                ),
              )
              .toList()
            ..sort(
              (first, second) =>
                  first['name'].toString().compareTo(second['name'].toString()),
            );
      return [
        SliverToBoxAdapter(
          child: Column(
            children: [
              CupertinoSearchTextField(
                placeholder: 'Buscar ingrediente',
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: 16),
              FinanceSection(
                children: [
                  for (final ingredient in ingredients)
                    FinanceRecordTile(
                      id: ingredient['id'],
                      title: ingredient['name'],
                      subtitle:
                          '${ingredientCategories[ingredient['category']]} · ${ingredient['base_unit']}',
                      onEdit: () => editIngredient(context, ref, ingredient),
                      onDelete: () => deleteRecord(
                        context,
                        ref,
                        'ingredients',
                        ingredient['id'],
                      ),
                      onTap: () => openFinancePage<void>(
                        context,
                        IngredientDetailPage(id: ingredient['id']),
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
}

Future<void> editIngredient(
  BuildContext context,
  WidgetRef ref, [
  DataRow? initial,
]) => editRecord(
  context,
  ref,
  title: initial == null ? 'Novo ingrediente' : 'Editar ingrediente',
  table: 'ingredients',
  initial: initial,
  fields: const [
    EditField('name', 'Nome', required: true),
    EditField(
      'category',
      'Categoria',
      required: true,
      options: ingredientCategories,
      defaultValue: 'outros',
    ),
    EditField(
      'base_unit',
      'Unidade base',
      required: true,
      options: {'g': 'Grama (g)', 'ml': 'Mililitro (ml)', 'un': 'Unidade (un)'},
      defaultValue: 'g',
    ),
  ],
);

class IngredientDetailPage extends ConsumerWidget {
  const IngredientDetailPage({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FinanceBody(
    title: 'Preços do ingrediente',
    builder: (snapshot) {
      final matching = snapshot
          .rows('ingredients')
          .where((row) => row['id'] == id);
      if (matching.isEmpty) {
        return [
          const SliverToBoxAdapter(child: Text('Ingrediente não encontrado.')),
        ];
      }
      final ingredient = matching.first;
      final prices = PriceHistory.chronological(
        snapshot
            .rows('ingredient_prices')
            .where((row) => row['ingredient_id'] == id),
      );
      final current = PriceHistory.current(prices);
      final activeIds = snapshot
          .rows('suppliers')
          .where((row) => row['active'] == true)
          .map((row) => row['id'])
          .toSet();
      final active = current
          .where((row) => activeIds.contains(row['supplier_id']))
          .toList();
      final lowest = active.isEmpty
          ? null
          : Decimal.parse(active.first['unit_price'].toString());
      return [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ingredient['name'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CupertinoButton.filled(
                onPressed: () => _quote(context, ref, snapshot, ingredient),
                child: const Text('Nova cotação / compra'),
              ),
              const SizedBox(height: 16),
              FinanceSection(
                title:
                    'Comparação por fornecedor · R\$/${ingredient['base_unit']}',
                children: [
                  if (current.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final price in current)
                            SizedBox(
                              width: 210,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      snapshot.name(
                                        'suppliers',
                                        price['supplier_id'],
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'R\$ ${price['unit_price'].toString().replaceAll('.', ',')}/${ingredient['base_unit']}',
                                    ),
                                    Text(
                                      BrFormatters.date(
                                        DateTime.parse(price['date']),
                                      ),
                                    ),
                                    Text(
                                      'Variação: ${PriceHistory.variation(prices.where((row) => row['supplier_id'] == price['supplier_id']))?.replaceAll('.', ',') ?? '—'}%',
                                    ),
                                    if (!activeIds.contains(
                                      price['supplier_id'],
                                    ))
                                      const Text('Fornecedor inativo'),
                                    if (activeIds.contains(
                                          price['supplier_id'],
                                        ) &&
                                        Decimal.parse(
                                              price['unit_price'].toString(),
                                            ) ==
                                            lowest)
                                      const Text('★ Menor preço ativo'),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              if (prices.isNotEmpty)
                PriceEvolution(
                  prices: prices,
                  snapshot: snapshot,
                  baseUnit: ingredient['base_unit'],
                ),
              FinanceSection(
                title: 'Histórico (mais recente primeiro)',
                children: [
                  for (final price in prices.reversed)
                    CupertinoListTile(
                      title: Text(
                        snapshot.name('suppliers', price['supplier_id']),
                      ),
                      subtitle: Text(
                        '${BrFormatters.date(DateTime.parse(price['date']))} · ${price['package_size']} ${price['package_unit']} · ${price['kind'] == 'purchase' ? 'Compra' : 'Cotação'}',
                      ),
                      additionalInfo: Text(
                        BrFormatters.currencyFromCents(
                          FinancialMath.cents(price['price']),
                        ),
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
  Future<void> _quote(
    BuildContext context,
    WidgetRef ref,
    FinanceSnapshot snapshot,
    DataRow ingredient,
  ) async {
    final suppliers = {
      for (final row
          in snapshot.rows('suppliers').where((row) => row['active'] == true))
        row['id'] as String: row['name'].toString(),
    };
    if (suppliers.isEmpty) {
      await showFinanceError(
        context,
        const FormatException(
          'Cadastre um fornecedor ativo antes de registrar preços.',
        ),
      );
      return;
    }
    final units = switch (ingredient['base_unit']) {
      'g' => {'g': 'g', 'kg': 'kg'},
      'ml' => {'ml': 'ml', 'l': 'L'},
      _ => {'un': 'un'},
    };
    await editRecord(
      context,
      ref,
      title: 'Registrar preço',
      table: 'ingredient_prices',
      fields: [
        EditField(
          'supplier_id',
          'Fornecedor',
          required: true,
          options: suppliers,
        ),
        const EditField(
          'package_size',
          'Quantidade total da embalagem',
          required: true,
          number: true,
        ),
        EditField(
          'package_unit',
          'Unidade da embalagem',
          required: true,
          options: units,
          defaultValue: units.keys.first,
        ),
        const EditField(
          'price',
          'Preço total (R\$)',
          required: true,
          money: true,
        ),
        EditField(
          'date',
          'Data',
          date: true,
          defaultValue: FinancialMath.date(DateTime.now()),
        ),
        const EditField(
          'kind',
          'Tipo do registro',
          required: true,
          options: {
            'quote': 'Somente cotação',
            'purchase': 'Compra realizada (não gera saída)',
          },
          defaultValue: 'quote',
        ),
      ],
      transform: (values) {
        FinancialMath.baseQuantity(
          values['package_size'],
          values['package_unit'],
          ingredient['base_unit'],
        );
        return {...values, 'ingredient_id': id};
      },
    );
  }
}

class PriceEvolution extends StatelessWidget {
  const PriceEvolution({
    required this.prices,
    required this.snapshot,
    required this.baseUnit,
    super.key,
  });
  final List<DataRow> prices;
  final FinanceSnapshot snapshot;
  final String baseUnit;
  static const _colors = [
    CupertinoColors.systemBlue,
    CupertinoColors.systemOrange,
    CupertinoColors.systemGreen,
    CupertinoColors.systemPurple,
    CupertinoColors.systemRed,
  ];
  @override
  Widget build(BuildContext context) {
    final suppliers = prices
        .map((row) => row['supplier_id'] as String)
        .toSet()
        .toList();
    final dates = prices.map((row) => row['date'].toString()).toSet().toList()
      ..sort();
    return Semantics(
      label:
          'Evolução do preço em reais por $baseUnit. Valores detalhados no histórico abaixo.',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolução de ${BrFormatters.date(DateTime.parse(dates.first))} a ${BrFormatters.date(DateTime.parse(dates.last))}',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: dates.length > 1 ? (dates.length - 1).toDouble() : 1,
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [
                    for (var index = 0; index < suppliers.length; index++)
                      LineChartBarData(
                        color: _colors[index % _colors.length].resolveFrom(
                          context,
                        ),
                        spots: [
                          for (final price in prices.where(
                            (row) => row['supplier_id'] == suppliers[index],
                          ))
                            FlSpot(
                              dates.indexOf(price['date']).toDouble(),
                              double.parse(price['unit_price'].toString()),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            Wrap(
              spacing: 14,
              children: [
                for (var index = 0; index < suppliers.length; index++)
                  Text(
                    snapshot.name('suppliers', suppliers[index]),
                    style: TextStyle(
                      color: _colors[index % _colors.length].resolveFrom(
                        context,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
