import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/br_formatters.dart';
import '../../../../core/utils/financial_math.dart';
import '../../../../core/widgets/finance_record_tile.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../data/finance_repository.dart';
import '../../domain/statement_filter.dart';
import 'transaction_editor.dart';

class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});
  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    FinanceSnapshot snapshot, [
    DataRow? initial,
  ]) => editRecord(
    context,
    ref,
    title: 'Recorrência',
    table: 'recurring_transactions',
    initial: initial,
    fields: transactionFields(snapshot, recurring: true),
    transform: (values) => {
      ...values,
      'description': values['description'] ?? '',
      'supplier_id': values['type'] == 'saida' ? values['supplier_id'] : null,
      'anchor_day':
          initial != null && values['next_date'] == initial['next_date']
          ? initial['anchor_day']
          : DateTime.parse(values['next_date']).day,
    },
  );
  @override
  Widget build(BuildContext context, WidgetRef ref) => FinanceBody(
    title: 'Recorrências',
    builder: (snapshot) => [
      SliverToBoxAdapter(
        child: Column(
          children: [
            const Text(
              'Ao abrir ou atualizar os dados, os vencimentos até hoje geram lançamentos pendentes. No dia 31, meses menores usam o último dia. A pausa preserva lançamentos existentes.',
            ),
            CupertinoButton.filled(
              onPressed: () => _edit(context, ref, snapshot),
              child: const Text('Nova recorrência'),
            ),
            const SizedBox(height: 16),
            FinanceSection(
              children: [
                for (final rule in snapshot.rows('recurring_transactions'))
                  FinanceRecordTile(
                    id: rule['id'],
                    title: (rule['description'] as String).isEmpty
                        ? snapshot.name(
                            'transaction_categories',
                            rule['category_id'],
                          )
                        : rule['description'],
                    subtitle:
                        '${BrFormatters.currencyFromCents(FinancialMath.cents(rule['amount']))} · a cada ${rule['interval_months']} mês(es)\nPróxima: ${BrFormatters.date(DateTime.parse(rule['next_date']))} · ${rule['active'] == true ? 'Ativa' : 'Pausada'}',
                    onEdit: () => _edit(context, ref, snapshot, rule),
                    onDelete: () => deleteRecord(
                      context,
                      ref,
                      'recurring_transactions',
                      rule['id'],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
