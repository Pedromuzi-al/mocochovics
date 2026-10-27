import '../../../../core/widgets/app_interaction.dart';

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/finance_record_tile.dart';
import '../../../../core/widgets/premium_finance.dart';
import '../../../transactions/domain/statement_filter.dart';
import '../../domain/product_financials.dart';

/// A grouped list row with a readable financial summary and secondary actions.
class ProductRecordTile extends StatelessWidget {
  const ProductRecordTile({
    required this.product,
    required this.financials,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final DataRow product;
  final ProductFinancials? financials;
  final VoidCallback onTap, onEdit, onDelete;

  Future<void> _showActions(BuildContext context) async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(product['name']),
        actions: [
          AppHover(
            child: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, 'edit'),
              child: const Text('Editar produto'),
            ),
          ),
          AppHover(
            child: CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, 'delete'),
              child: const Text('Excluir produto'),
            ),
          ),
        ],
        cancelButton: AppHover(
          child: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') onEdit();
    if (action == 'delete') onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final secondary = AppTheme.secondaryTextColor.resolveFrom(context);
    final warning = FinancePalette.warning.resolveFrom(context);
    final missingCost = financials?.cost == null;
    final lowMargin = financials?.lowMargin == true;
    return FinanceRecordTile(
      id: product['id'],
      title: product['name'],
      onEdit: onEdit,
      onDelete: onDelete,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppButton(
              padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
              alignment: Alignment.centerLeft,
              onPressed: onTap,
              child: DefaultTextStyle(
                style: CupertinoTheme.of(context).textTheme.textStyle,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked =
                        constraints.maxWidth < 260 ||
                        MediaQuery.textScalerOf(context).scale(14) > 20;
                    final name = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product['category'],
                          style: TextStyle(fontSize: 13, color: secondary),
                        ),
                      ],
                    );
                    final salePrice = Text(
                      money(decimalOrNull(product['sale_price'])),
                      style: AppTheme.tabularFigures(
                        const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (stacked) ...[
                          name,
                          const SizedBox(height: 8),
                          Text(
                            'Preço de venda',
                            style: TextStyle(fontSize: 12, color: secondary),
                          ),
                          salePrice,
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: name),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Venda',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: secondary,
                                      ),
                                    ),
                                    salePrice,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 6,
                          children: [
                            Text(
                              'Custo ${missingCost ? 'indisponível' : money(financials!.cost)}',
                              style: AppTheme.tabularFigures(
                                TextStyle(fontSize: 13, color: secondary),
                              ),
                            ),
                            Text(
                              'Margem ${financials?.marginPercent == null ? '—' : '${localizedDecimal(financials!.marginPercent!)}%'}',
                              style: AppTheme.tabularFigures(
                                TextStyle(
                                  fontSize: 13,
                                  color: lowMargin ? warning : secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (lowMargin || missingCost) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                lowMargin
                                    ? CupertinoIcons.exclamationmark_triangle
                                    : CupertinoIcons.info_circle,
                                size: 16,
                                color: lowMargin ? warning : secondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  lowMargin
                                      ? 'Margem abaixo da meta'
                                      : 'Complete a ficha e os preços',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: lowMargin ? warning : secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: AppButton(
              padding: const EdgeInsets.all(10),
              onPressed: () => _showActions(context),
              child: Icon(
                CupertinoIcons.ellipsis,
                size: 20,
                semanticLabel: 'Ações de ${product['name']}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
