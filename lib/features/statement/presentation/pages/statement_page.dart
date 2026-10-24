import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/br_formatters.dart';
import '../../../../core/utils/financial_math.dart';
import '../../../../core/widgets/finance_record_tile.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../transactions/data/finance_repository.dart';
import '../../../transactions/domain/statement_filter.dart';
import '../../../transactions/presentation/pages/transaction_editor.dart';

class StatementPage extends ConsumerStatefulWidget {
  const StatementPage({super.key});
  @override
  ConsumerState<StatementPage> createState() => _StatementPageState();
}

class _StatementPageState extends ConsumerState<StatementPage> {
  DataRow _filters = {};
  String _search = '';
  final _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  StatementFilter get _filter => StatementFilter(
    start: _filters['use_period'] == true
        ? DateTime.parse(_filters['start'])
        : null,
    end: _filters['use_period'] == true
        ? DateTime.parse(_filters['end'])
        : null,
    type: _filters['type'],
    categoryId: _filters['category_id'],
    supplierId: _filters['supplier_id'],
    paymentMethod: _filters['payment_method'],
    status: _filters['status'],
    search: _search,
  );
  Future<void> _configure(FinanceSnapshot snapshot) async {
    DataRow? selected;
    final saved = await openFinancePage<bool>(
      context,
      RecordEditor(
        title: 'Filtros do extrato',
        initial: _filters,
        fields: [
          const EditField(
            'use_period',
            'Filtrar período',
            toggle: true,
            defaultValue: true,
          ),
          EditField(
            'start',
            'De',
            date: true,
            defaultValue: FinancialMath.date(
              DateTime(DateTime.now().year, DateTime.now().month),
            ),
          ),
          EditField(
            'end',
            'Até',
            date: true,
            defaultValue: FinancialMath.date(DateTime.now()),
          ),
          const EditField('type', 'Tipo', options: transactionTypes),
          EditField(
            'category_id',
            'Categoria',
            options: rowOptions(snapshot, 'transaction_categories'),
          ),
          EditField(
            'supplier_id',
            'Fornecedor',
            options: rowOptions(snapshot, 'suppliers'),
          ),
          const EditField(
            'payment_method',
            'Pagamento',
            options: paymentMethods,
          ),
          const EditField('status', 'Status', options: paymentStatuses),
        ],
        onSave: (values) async {
          if (values['use_period'] == true &&
              values['start'].toString().compareTo(values['end'].toString()) >
                  0) {
            throw const FormatException(
              'A data inicial deve ser anterior à final.',
            );
          }
          selected = values;
        },
      ),
    );
    if (saved == true && mounted) setState(() => _filters = selected!);
  }

  @override
  Widget build(BuildContext context) => FinanceBody(
    title: 'Extrato',
    builder: (snapshot) {
      final rows = _filter.apply(snapshot.rows('transactions'));
      final totals = StatementTotals(rows);
      var accumulated = 0;
      final balances = <String, int>{};
      for (final row in rows) {
        if (row['status'] == 'pago') {
          accumulated +=
              FinancialMath.cents(row['amount']) *
              (row['type'] == 'entrada' ? 1 : -1);
        }
        balances[row['id']] = accumulated;
      }
      return [
        SliverToBoxAdapter(
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  CupertinoButton.filled(
                    onPressed: () => editTransaction(context, ref, snapshot),
                    child: const Text('Novo lançamento'),
                  ),
                  CupertinoButton(
                    onPressed: () => _configure(snapshot),
                    child: const Text('Filtros'),
                  ),
                  CupertinoButton(
                    onPressed: () => setState(() {
                      _filters = {};
                      _search = '';
                      _searchController.clear();
                    }),
                    child: const Text('Limpar filtros'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Buscar descrição',
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: 16),
              FinanceSection(
                title: '${rows.length} lançamento(s) · totais do filtro',
                children: [
                  CupertinoListTile(
                    title: const Text('Entradas pagas'),
                    subtitle: Text(
                      BrFormatters.currencyFromCents(totals.income),
                    ),
                  ),
                  CupertinoListTile(
                    title: const Text('Saídas pagas'),
                    subtitle: Text(
                      BrFormatters.currencyFromCents(totals.expenses),
                    ),
                  ),
                  CupertinoListTile(
                    title: const Text('Saldo do filtro'),
                    subtitle: Text(
                      BrFormatters.currencyFromCents(totals.balance),
                    ),
                  ),
                  CupertinoListTile(
                    title: const Text('Total pendente (entradas e saídas)'),
                    subtitle: Text(
                      BrFormatters.currencyFromCents(totals.pending),
                    ),
                  ),
                ],
              ),
              const Text(
                'Ordem cronológica. O saldo acumulado começa em zero para o filtro aplicado e considera somente pagamentos.',
              ),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nenhum lançamento encontrado.'),
                ),
            ],
          ),
        ),
        SliverList.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            final newDay = index == 0 || rows[index - 1]['date'] != row['date'];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (newDay)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      BrFormatters.date(DateTime.parse(row['date'])),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                FinanceRecordTile(
                  id: row['id'],
                  titleColor:
                      (row['type'] == 'entrada'
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemRed)
                          .resolveFrom(context),
                  title:
                      '${row['type'] == 'entrada' ? '+' : '−'} ${BrFormatters.currencyFromCents(FinancialMath.cents(row['amount']))}',
                  subtitle:
                      '${row['description']}\n${snapshot.name('transaction_categories', row['category_id'])} · ${paymentStatuses[row['status']]}\nAcumulado: ${BrFormatters.currencyFromCents(balances[row['id']]!)}',
                  onEdit: () => editTransaction(context, ref, snapshot, row),
                  onDelete: () =>
                      deleteRecord(context, ref, 'transactions', row['id']),
                  onTap: () => openFinancePage<void>(
                    context,
                    TransactionDetailPage(id: row['id']),
                  ),
                ),
              ],
            );
          },
        ),
      ];
    },
  );
}
