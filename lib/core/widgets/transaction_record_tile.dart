import 'app_interaction.dart';

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import '../utils/br_formatters.dart';
import '../utils/financial_math.dart';
import '../../features/transactions/domain/statement_filter.dart';
import '../../features/transactions/presentation/pages/transaction_editor.dart';
import 'finance_record_tile.dart';
import 'premium_finance.dart';

class TransactionRecordTile extends StatelessWidget {
  const TransactionRecordTile({
    required this.entry,
    required this.category,
    required this.accumulated,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });
  final DataRow entry;
  final String category;
  final int accumulated;
  final VoidCallback onTap, onEdit, onDelete;

  IconData get _icon {
    final name = category.toLowerCase();
    if (name.contains('ingred') || name.contains('insumo')) {
      return CupertinoIcons.cube_box;
    }
    if (name.contains('energia')) return CupertinoIcons.bolt;
    if (name.contains('aluguel')) return CupertinoIcons.building_2_fill;
    if (name.contains('salário')) return CupertinoIcons.person_2;
    return entry['type'] == 'entrada'
        ? CupertinoIcons.arrow_down_left
        : CupertinoIcons.arrow_up_right;
  }

  @override
  Widget build(BuildContext context) {
    final income = entry['type'] == 'entrada';
    final color = (income ? FinancePalette.income : FinancePalette.expense)
        .resolveFrom(context);
    final secondary = AppTheme.secondaryTextColor.resolveFrom(context);
    final description = (entry['description'] as String?)?.trim();
    final title = description == null || description.isEmpty
        ? category
        : description;
    return FinanceRecordTile(
      id: entry['id'],
      title: title,
      onEdit: onEdit,
      onDelete: onDelete,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator
                  .resolveFrom(context)
                  .withValues(alpha: .22),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppButton(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 12,
                ),
                alignment: Alignment.centerLeft,
                onPressed: onTap,
                child: DefaultTextStyle(
                  style: CupertinoTheme.of(context).textTheme.textStyle,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked =
                          constraints.maxWidth < 260 ||
                          MediaQuery.textScalerOf(context).scale(14) > 20;
                      final amount = Text(
                        '${income ? '+' : '−'} ${BrFormatters.currencyFromCents(FinancialMath.cents(entry['amount']))}',
                        style: AppTheme.tabularFigures(
                          TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      );
                      final details = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$category · ${paymentMethods[entry['payment_method']] ?? 'Não informado'}',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: secondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                entry['status'] == 'pago'
                                    ? CupertinoIcons.checkmark_circle
                                    : CupertinoIcons.clock,
                                size: 13,
                                color: secondary,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  paymentStatuses[entry['status']] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_icon, size: 19, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: details),
                              if (!stacked) ...[
                                const SizedBox(width: 12),
                                Flexible(child: amount),
                              ],
                            ],
                          ),
                          if (stacked)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: amount,
                            ),
                          const SizedBox(height: 10),
                          Text(
                            'Acumulado: ${BrFormatters.currencyFromCents(accumulated)}',
                            style: AppTheme.tabularFigures(
                              TextStyle(fontSize: 12, color: secondary),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            AppButton(
              padding: const EdgeInsets.fromLTRB(4, 14, 8, 8),
              onPressed: () =>
                  showRecordActions(context, title, onEdit, onDelete),
              child: Icon(
                CupertinoIcons.ellipsis,
                size: 20,
                semanticLabel: 'Ações de $title',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
