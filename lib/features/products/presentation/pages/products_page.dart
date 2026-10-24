import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/finance_record_tile.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../../core/widgets/premium_finance.dart';
import '../../../transactions/domain/statement_filter.dart';
import '../../domain/product_financials.dart';
import 'product_detail_page.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});
  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  String _search = '', _filter = 'todos';
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
                    (_filter == 'todos' ||
                        metrics[row['id']]?.lowMargin == true),
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
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: _filter,
                  children: const {
                    'todos': Text('Todos'),
                    'alertas': Text('Margem baixa'),
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
              FinanceSection(
                children: [
                  for (final product in products)
                    FinanceRecordTile(
                      id: product['id'],
                      title: product['name'],
                      subtitle:
                          '${product['category']} · Venda ${money(decimalOrNull(product['sale_price']))}\nCusto ${metrics[product['id']]?.cost == null ? 'indisponível' : money(metrics[product['id']]!.cost)} · Margem ${metrics[product['id']]?.marginPercent == null ? '—' : '${localizedDecimal(metrics[product['id']]!.marginPercent!)}%'}${metrics[product['id']]?.lowMargin == true ? '\n⚠ Margem abaixo da meta' : ''}',
                      titleColor: metrics[product['id']]?.lowMargin == true
                          ? FinancePalette.warning.resolveFrom(context)
                          : null,
                      onTap: () => openFinancePage<void>(
                        context,
                        ProductDetailPage(id: product['id']),
                      ),
                      onEdit: () => editProduct(context, ref, product),
                      onDelete: () =>
                          deleteRecord(context, ref, 'products', product['id']),
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
