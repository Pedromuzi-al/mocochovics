import '../../../../core/widgets/app_interaction.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/br_formatters.dart';
import '../../../../core/utils/financial_math.dart';
import '../../../../core/widgets/transaction_record_tile.dart';
import '../../../../core/widgets/premium_finance.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../transactions/data/finance_repository.dart';
import '../../../transactions/domain/statement_filter.dart';
import '../../../transactions/presentation/pages/transaction_editor.dart';

class StatementPage extends ConsumerStatefulWidget {
  const StatementPage({
    this.initialFilter = const StatementFilter(),
    super.key,
  });
  final StatementFilter initialFilter;
  @override
  ConsumerState<StatementPage> createState() => _StatementPageState();
}

class _StatementPageState extends ConsumerState<StatementPage> {
  DataRow _filters = {};
  String _search = '';
  final _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    final filter = widget.initialFilter;
    _filters = {
      if (filter.start != null || filter.end != null) 'use_period': true,
      if (filter.start != null) 'start': FinancialMath.date(filter.start!),
      if (filter.end != null) 'end': FinancialMath.date(filter.end!),
      'type': filter.type,
      'category_id': filter.categoryId,
      'supplier_id': filter.supplierId,
      'suppliers_only': filter.suppliersOnly,
      'payment_method': filter.paymentMethod,
      'status': filter.status,
    };
    _search = filter.search;
    _searchController.text = _search;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  StatementFilter get _filter => StatementFilter(
    start: _filters['use_period'] == true && _filters['start'] != null
        ? DateTime.parse(_filters['start'])
        : null,
    end: _filters['use_period'] == true && _filters['end'] != null
        ? DateTime.parse(_filters['end'])
        : null,
    type: _filters['type'],
    categoryId: _filters['category_id'],
    supplierId: _filters['supplier_id'],
    suppliersOnly: _filters['suppliers_only'] == true,
    paymentMethod: _filters['payment_method'],
    status: _filters['status'],
    search: _search,
  );
  Future<void> _configure(FinanceSnapshot snapshot) async {
    DataRow? selected;
    final saved = await openFinanceSheet<bool>(
      context,
      RecordEditor(
        title: 'Filtros do extrato',
        saveLabel: 'Aplicar filtros',
        showNavigationSave: false,
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
            'suppliers_only',
            'Somente com fornecedor',
            toggle: true,
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

  bool get _hasFilters =>
      _search.isNotEmpty ||
      _filters['use_period'] == true ||
      _filters['suppliers_only'] == true ||
      [
        'type',
        'status',
        'payment_method',
        'category_id',
        'supplier_id',
      ].any((key) => _filters[key] != null && _filters[key] != '');
  void _clearFilters() => setState(() {
    _filters = {};
    _search = '';
    _searchController.clear();
  });
  Widget _chip(String label, VoidCallback clear) => AppButton(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
    onPressed: clear,
    child: Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const Icon(CupertinoIcons.xmark, size: 12),
      ],
    ),
  );

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
                  AppButton.filled(
                    onPressed: () => editTransaction(context, ref, snapshot),
                    child: const Text('Novo lançamento'),
                  ),
                  AppButton(
                    onPressed: () => _configure(snapshot),
                    child: const Text('Filtros'),
                  ),
                  if (_hasFilters)
                    AppButton(
                      onPressed: _clearFilters,
                      child: const Text('Limpar filtros'),
                    ),
                ],
              ),
              if (_hasFilters)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_filters['use_period'] == true &&
                          _filters['start'] != null &&
                          _filters['end'] != null)
                        _chip(
                          '${BrFormatters.date(DateTime.parse(_filters['start']))} — ${BrFormatters.date(DateTime.parse(_filters['end']))}',
                          () => setState(() => _filters['use_period'] = false),
                        ),
                      for (final field in {
                        'type': 'Tipo',
                        'status': 'Status',
                        'payment_method': 'Pagamento',
                        'category_id': 'Categoria',
                        'supplier_id': 'Fornecedor',
                      }.entries)
                        if (_filters[field.key] != null &&
                            _filters[field.key] != '')
                          _chip(
                            '${field.value}: ${switch (field.key) {
                              'type' => transactionTypes[_filters[field.key]],
                              'status' => paymentStatuses[_filters[field.key]],
                              'payment_method' => paymentMethods[_filters[field.key]],
                              'category_id' => snapshot.name('transaction_categories', _filters[field.key]),
                              _ => snapshot.name('suppliers', _filters[field.key]),
                            }}',
                            () => setState(() => _filters.remove(field.key)),
                          ),
                      if (_filters['suppliers_only'] == true)
                        _chip(
                          'Com fornecedor',
                          () =>
                              setState(() => _filters.remove('suppliers_only')),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              AppHover(
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'Buscar descrição',
                  onChanged: (value) => setState(() => _search = value),
                ),
              ),
              const SizedBox(height: 16),
              _StatementSummary(totals: totals),
              const SizedBox(height: 20),
              Text(
                '${rows.length} ${rows.length == 1 ? 'lançamento' : 'lançamentos'} · ordem cronológica',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.secondaryTextColor.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'O saldo acumulado começa em zero para o filtro e considera somente pagamentos.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor.resolveFrom(context),
                ),
              ),
              if (rows.isEmpty)
                AppStateView(
                  icon: _hasFilters
                      ? CupertinoIcons.search
                      : CupertinoIcons.doc_text,
                  title: _hasFilters
                      ? 'Nenhum lançamento encontrado'
                      : 'Seu extrato começa aqui',
                  message: _hasFilters
                      ? 'Tente outra busca ou remova os filtros para ver suas movimentações.'
                      : 'Registre entradas e saídas para acompanhar o movimento do seu caixa.',
                  actionLabel: _hasFilters
                      ? 'Limpar filtros'
                      : 'Novo lançamento',
                  onAction: _hasFilters
                      ? _clearFilters
                      : () => editTransaction(context, ref, snapshot),
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
              key: ValueKey(row['id']),
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
                TransactionRecordTile(
                  key: ValueKey(row['id']),
                  entry: row,
                  category: snapshot.name(
                    'transaction_categories',
                    row['category_id'],
                  ),
                  accumulated: balances[row['id']]!,
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

class _StatementSummary extends StatelessWidget {
  const _StatementSummary({required this.totals});
  final StatementTotals totals;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = MediaQuery.textScalerOf(context).scale(14) > 20
          ? 1
          : constraints.maxWidth >= 900
          ? 4
          : 2;
      final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
      final metrics = [
        (
          label: 'Entradas pagas',
          amount: totals.income,
          color: FinancePalette.income,
        ),
        (
          label: 'Saídas pagas',
          amount: totals.expenses,
          color: FinancePalette.expense,
        ),
        (
          label: 'Saldo do filtro',
          amount: totals.balance,
          color: totals.balance < 0
              ? FinancePalette.expense
              : FinancePalette.income,
        ),
        (
          label: 'Total pendente (entradas e saídas)',
          amount: totals.pending,
          color: FinancePalette.warning,
        ),
      ];
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final metric in metrics)
            SizedBox(
              width: width,
              child: AppHover(
                lift: true,
                radius: 24,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemGroupedBackground
                        .resolveFrom(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondaryTextColor.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedMoney(
                        cents: metric.amount,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: metric.color.resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
