import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/br_formatters.dart';
import '../../../../core/utils/financial_math.dart';
import '../../../../core/widgets/finance_record_tile.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../transactions/domain/statement_filter.dart';
import '../../../ingredients/domain/price_history.dart';

class SuppliersPage extends ConsumerStatefulWidget {
  const SuppliersPage({super.key});
  @override
  ConsumerState<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends ConsumerState<SuppliersPage> {
  String _search = '';
  String _status = 'todos';
  @override
  Widget build(BuildContext context) => FinanceBody(
    title: 'Fornecedores',
    trailing: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => editSupplier(context, ref),
      child: const Icon(CupertinoIcons.add, semanticLabel: 'Novo fornecedor'),
    ),
    builder: (snapshot) {
      final suppliers =
          snapshot
              .rows('suppliers')
              .where(
                (row) =>
                    row['name'].toString().toLowerCase().contains(
                      _search.toLowerCase(),
                    ) &&
                    (_status == 'todos' ||
                        row['active'] == (_status == 'ativos')),
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
                placeholder: 'Buscar fornecedor',
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: 16),
              CupertinoSlidingSegmentedControl<String>(
                groupValue: _status,
                children: const {
                  'todos': Text('Todos'),
                  'ativos': Text('Ativos'),
                  'inativos': Text('Inativos'),
                },
                onValueChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 16),
              FinanceSection(
                children: [
                  for (final supplier in suppliers)
                    FinanceRecordTile(
                      id: supplier['id'],
                      title: supplier['name'],
                      subtitle: supplier['active'] == true
                          ? 'Ativo'
                          : 'Inativo',
                      onEdit: () => editSupplier(context, ref, supplier),
                      onDelete: () => deleteRecord(
                        context,
                        ref,
                        'suppliers',
                        supplier['id'],
                      ),
                      onTap: () => openFinancePage<void>(
                        context,
                        SupplierDetailPage(id: supplier['id']),
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

Future<void> editSupplier(
  BuildContext context,
  WidgetRef ref, [
  DataRow? initial,
]) => editRecord(
  context,
  ref,
  title: initial == null ? 'Novo fornecedor' : 'Editar fornecedor',
  table: 'suppliers',
  initial: initial,
  fields: [
    const EditField('name', 'Nome', required: true),
    const EditField('document', 'CNPJ/CPF (opcional)', maxLength: 18),
    const EditField('phone', 'Telefone/WhatsApp', maxLength: 25),
    EditField(
      'email',
      'E-mail',
      validate: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)
          ? null
          : 'Informe um e-mail válido.',
    ),
    const EditField('address', 'Endereço', maxLength: 500),
    const EditField(
      'payment_term_days',
      'Prazo de pagamento (dias)',
      integer: true,
      defaultValue: 0,
    ),
    const EditField('notes', 'Observações', maxLength: 2000),
    const EditField('active', 'Ativo', toggle: true, defaultValue: true),
  ],
);

class SupplierDetailPage extends ConsumerStatefulWidget {
  const SupplierDetailPage({required this.id, super.key});
  final String id;
  @override
  ConsumerState<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends ConsumerState<SupplierDetailPage> {
  DateTime _start = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _end = DateTime.now();
  Future<void> _launch(Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('link');
      }
    } catch (error) {
      if (mounted) {
        await showFinanceError(
          context,
          const FormatException(
            'Não foi possível abrir o contato neste dispositivo.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => FinanceBody(
    title: 'Fornecedor',
    builder: (snapshot) {
      final suppliers = snapshot
          .rows('suppliers')
          .where((row) => row['id'] == widget.id);
      if (suppliers.isEmpty) {
        return [
          const SliverToBoxAdapter(child: Text('Fornecedor não encontrado.')),
        ];
      }
      final supplier = suppliers.first;
      final phone = (supplier['phone'] ?? '').toString().replaceAll(
        RegExp(r'\D'),
        '',
      );
      final prices = PriceHistory.current(
        snapshot
            .rows('ingredient_prices')
            .where((row) => row['supplier_id'] == widget.id),
      );
      final spent = StatementTotals(
        StatementFilter(
          start: _start,
          end: DateTime(_end.year, _end.month, _end.day),
          supplierId: widget.id,
          type: 'saida',
          status: 'pago',
        ).apply(snapshot.rows('transactions')),
      ).expenses;
      return [
        SliverToBoxAdapter(
          child: Column(
            children: [
              FinanceSection(
                title: supplier['name'],
                children: [
                  for (final field in {
                    'document': 'Documento',
                    'phone': 'Telefone',
                    'email': 'E-mail',
                    'address': 'Endereço',
                    'payment_term_days': 'Prazo (dias)',
                    'notes': 'Observações',
                  }.entries)
                    CupertinoListTile(
                      title: Text(field.value),
                      subtitle: Text(
                        (supplier[field.key] ?? 'Não informado').toString(),
                        maxLines: 6,
                      ),
                    ),
                  if (phone.isNotEmpty)
                    Wrap(
                      children: [
                        CupertinoButton(
                          onPressed: () =>
                              _launch(Uri(scheme: 'tel', path: phone)),
                          child: const Text('Ligar'),
                        ),
                        CupertinoButton(
                          onPressed: () => _launch(
                            Uri.https(
                              'wa.me',
                              '/${phone.length <= 11 ? '55$phone' : phone}',
                            ),
                          ),
                          child: const Text('WhatsApp'),
                        ),
                      ],
                    ),
                  CupertinoButton(
                    onPressed: () => editSupplier(context, ref, supplier),
                    child: const Text('Editar fornecedor'),
                  ),
                ],
              ),
              FinanceSection(
                title: 'Gastos pagos no período',
                children: [
                  CupertinoListTile(
                    title: const Text('De'),
                    additionalInfo: Text(BrFormatters.date(_start)),
                    onTap: () async {
                      final date = await chooseDate(context, _start);
                      if (date != null && mounted) {
                        setState(() {
                          _start = date;
                          if (_end.isBefore(date)) _end = date;
                        });
                      }
                    },
                  ),
                  CupertinoListTile(
                    title: const Text('Até'),
                    additionalInfo: Text(BrFormatters.date(_end)),
                    onTap: () async {
                      final date = await chooseDate(context, _end);
                      if (date != null && mounted) {
                        setState(() {
                          _end = date;
                          if (_start.isAfter(date)) _start = date;
                        });
                      }
                    },
                  ),
                  CupertinoListTile(
                    title: Text(BrFormatters.currencyFromCents(spent)),
                  ),
                ],
              ),
              FinanceSection(
                title: 'Preços atuais por ingrediente',
                children: [
                  for (final price in prices)
                    CupertinoListTile(
                      title: Text(
                        snapshot.name('ingredients', price['ingredient_id']),
                      ),
                      subtitle: Text(
                        'R\$ ${price['unit_price']} por unidade base · ${BrFormatters.date(DateTime.parse(price['date']))}',
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
}
