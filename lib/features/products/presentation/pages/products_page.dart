import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../../core/widgets/premium_finance.dart';
import '../../../transactions/domain/statement_filter.dart';
import '../../domain/product_financials.dart';
import '../widgets/product_record_tile.dart';
import 'product_detail_page.dart';

enum ProductFilter { all, lowMargin, missingCost }

const _filterLabels = {
  ProductFilter.all: 'Todos',
  ProductFilter.lowMargin: 'Margem baixa',
  ProductFilter.missingCost: 'Sem custo',
};

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({this.initialFilter = ProductFilter.all, super.key});
  final ProductFilter initialFilter;
  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  String _search = '';
  late ProductFilter _filter = widget.initialFilter;

  Future<void> _selectFilter() async {
    final selected = await showCupertinoModalPopup<ProductFilter>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Filtrar produtos'),
        actions: [
          for (final entry in _filterLabels.entries)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, entry.key),
              child: Text(entry.value),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _filter = selected);
  }

  @override
  Widget build(BuildContext context) => FinanceBody(
    title: 'Produtos',
    trailing: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => editProduct(context, ref),
      child: const Icon(CupertinoIcons.add, semanticLabel: 'Novo produto'),
    ),
    builder: (snapshot) {
      final metrics = {
        for (final row in snapshot.rows('product_costs'))
          row['id']: ProductFinancials.fromDatabase(row),
      };
      final products =
          snapshot
              .rows('products')
              .where(
                (row) =>
                    '${row['name']} ${row['category']}'.toLowerCase().contains(
                      _search.toLowerCase(),
                    ) &&
                    switch (_filter) {
                      ProductFilter.all => true,
                      ProductFilter.lowMargin =>
                        metrics[row['id']]?.lowMargin == true,
                      ProductFilter.missingCost =>
                        metrics[row['id']]?.cost == null,
                    },
              )
              .toList()
            ..sort(
              (first, second) =>
                  first['name'].toString().compareTo(second['name'].toString()),
            );
      return [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CupertinoSearchTextField(
                placeholder: 'Buscar produto ou categoria',
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: MediaQuery.textScalerOf(context).scale(14) > 20
                    ? CupertinoButton(
                        onPressed: _selectFilter,
                        child: Text('Filtro: ${_filterLabels[_filter]}'),
                      )
                    : CupertinoSlidingSegmentedControl<ProductFilter>(
                        groupValue: _filter,
                        children: {
                          for (final entry in _filterLabels.entries)
                            entry.key: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(entry.value),
                            ),
                        },
                        onValueChanged: (value) {
                          if (value != null) setState(() => _filter = value);
                        },
                      ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Margens estimadas sobre ingredientes. Aluguel, salários, taxas e impostos não estão incluídos.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              if (products.isEmpty)
                Column(
                  children: [
                    FinanceEmptyState(
                      icon: CupertinoIcons.cube_box,
                      message: snapshot.rows('products').isEmpty
                          ? 'Cadastre seu primeiro produto e monte a ficha técnica para conhecer seus custos.'
                          : 'Nenhum produto corresponde à busca e ao filtro.',
                    ),
                    if (snapshot.rows('products').isEmpty)
                      CupertinoButton.filled(
                        onPressed: () => editProduct(context, ref),
                        child: const Text('Cadastrar produto'),
                      ),
                  ],
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 12),
                  child: Text(
                    '${products.length} ${products.length == 1 ? 'produto' : 'produtos'} · ${CostPreferences.fromSnapshot(snapshot).methodLabel}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.secondaryTextColor.resolveFrom(context),
                    ),
                  ),
                ),
                FinanceSection(
                  children: [
                    for (final product in products)
                      ProductRecordTile(
                        product: product,
                        financials: metrics[product['id']],
                        onTap: () => openFinancePage<void>(
                          context,
                          ProductDetailPage(id: product['id']),
                        ),
                        onEdit: () => editProduct(context, ref, product),
                        onDelete: () => deleteRecord(
                          context,
                          ref,
                          'products',
                          product['id'],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ];
    },
  );
}

Future<void> editProduct(
  BuildContext context,
  WidgetRef ref, [
  DataRow? initial,
]) => editRecord(
  context,
  ref,
  title: initial == null ? 'Novo produto' : 'Editar produto',
  table: 'products',
  initial: initial,
  fields: const [
    EditField('name', 'Nome', required: true),
    EditField('category', 'Categoria', required: true, defaultValue: 'Outros'),
    EditField(
      'sale_price',
      'Preço de venda (R\$)',
      money: true,
      required: true,
    ),
  ],
);
