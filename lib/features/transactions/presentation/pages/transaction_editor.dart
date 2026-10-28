import '../../../../core/widgets/app_interaction.dart';

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/br_formatters.dart';
import '../../../../core/utils/financial_math.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../../core/widgets/operation_feedback.dart';
import '../../data/finance_repository.dart';
import '../../domain/statement_filter.dart';

const transactionTypes = {'entrada': 'Entrada', 'saida': 'Saída'};
const paymentMethods = {
  'dinheiro': 'Dinheiro',
  'pix': 'Pix',
  'debito': 'Débito',
  'credito': 'Crédito',
  'outro': 'Outro',
};
const paymentStatuses = {'pago': 'Pago', 'pendente': 'Pendente'};

List<EditField> transactionFields(
  FinanceSnapshot snapshot, {
  bool recurring = false,
}) => [
  const EditField(
    'type',
    'Tipo',
    required: true,
    options: transactionTypes,
    defaultValue: 'saida',
  ),
  const EditField('amount', 'Valor (R\$)', required: true, money: true),
  EditField(
    recurring ? 'next_date' : 'date',
    recurring ? 'Primeiro / próximo vencimento' : 'Data',
    date: true,
    defaultValue: FinancialMath.date(DateTime.now()),
  ),
  EditField(
    'category_id',
    'Categoria',
    required: true,
    optionsBuilder: (values) => {
      for (final row
          in snapshot
              .rows('transaction_categories')
              .where((row) => row['type'] == values['type']))
        row['id'] as String: row['name'].toString(),
    },
  ),
  const EditField(
    'payment_method',
    'Forma de pagamento',
    required: true,
    options: paymentMethods,
    defaultValue: 'pix',
  ),
  EditField(
    'supplier_id',
    'Fornecedor (opcional)',
    options: rowOptions(snapshot, 'suppliers'),
    visible: (values) => values['type'] == 'saida',
  ),
  const EditField(
    'description',
    'Descrição',
    maxLength: 2000,
    defaultValue: '',
  ),
  if (!recurring)
    const EditField(
      'status',
      'Status',
      required: true,
      options: paymentStatuses,
      defaultValue: 'pago',
    ),
  if (recurring) ...[
    EditField(
      'interval_months',
      'Repetir a cada quantos meses?',
      integer: true,
      required: true,
      defaultValue: 1,
      validate: (value) =>
          (int.tryParse(value) ?? 0) < 1 || (int.tryParse(value) ?? 121) > 120
          ? 'Informe de 1 a 120 meses.'
          : null,
    ),
    const EditField('active', 'Ativa', toggle: true, defaultValue: true),
  ],
];

Future<void> editTransaction(
  BuildContext context,
  WidgetRef ref,
  FinanceSnapshot snapshot, [
  DataRow? entry,
]) async {
  final saved = await openFinanceSheet<bool>(
    context,
    TransactionEditor(snapshot: snapshot, initial: entry),
  );
  if (saved == true) {
    ref.invalidate(financeSnapshotProvider);
    if (context.mounted) OperationFeedback.show(context, 'Lançamento salvo');
  }
}

class TransactionEditor extends ConsumerStatefulWidget {
  const TransactionEditor({required this.snapshot, this.initial, super.key});
  final FinanceSnapshot snapshot;
  final DataRow? initial;
  @override
  ConsumerState<TransactionEditor> createState() => _TransactionEditorState();
}

class _TransactionEditorState extends ConsumerState<TransactionEditor> {
  late final String _entryId =
      widget.initial?['id'] as String? ?? const Uuid().v4();
  Uint8List? _receipt;
  String? _extension;
  String? _receiptName;
  bool _removeReceipt = false;
  bool _picking = false;
  Future<void> _pickReceipt() async {
    setState(() => _picking = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (file == null || !mounted) return;
      final size = await file.length();
      if (size == null || size > 10 * 1024 * 1024) {
        throw const FormatException('Escolha uma imagem ou PDF de até 10 MB.');
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _receipt = bytes;
        _extension = file.extension!.toLowerCase();
        _receiptName = file.name;
        _removeReceipt = false;
      });
    } catch (error) {
      if (mounted) await showFinanceError(context, error);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuote =
        widget.initial != null &&
        widget.snapshot
            .rows('ingredient_prices')
            .any((row) => row['transaction_id'] == widget.initial?['id']);
    bool quoteVisible(DataRow values) =>
        values['record_quote'] == true &&
        values['type'] == 'saida' &&
        values['status'] == 'pago';
    return RecordEditor(
      hasExternalChanges: _receipt != null || _removeReceipt,
      externalBusy: _picking,
      title: widget.initial == null ? 'Novo lançamento' : 'Editar lançamento',
      initial: widget.initial,
      fields: [
        ...transactionFields(widget.snapshot),
        if (!hasQuote) ...[
          EditField(
            'record_quote',
            'Registrar compra de ingrediente',
            toggle: true,
            visible: (values) =>
                values['type'] == 'saida' && values['status'] == 'pago',
          ),
          EditField(
            'ingredient_id',
            'Ingrediente comprado',
            required: true,
            options: rowOptions(widget.snapshot, 'ingredients'),
            visible: quoteVisible,
          ),
          EditField(
            'package_size',
            'Quantidade total comprada',
            required: true,
            number: true,
            visible: quoteVisible,
          ),
          EditField(
            'package_unit',
            'Unidade comprada',
            required: true,
            optionsBuilder: (values) {
              final ingredients = widget.snapshot
                  .rows('ingredients')
                  .where((row) => row['id'] == values['ingredient_id']);
              return switch (ingredients.firstOrNull?['base_unit']) {
                'g' => {'g': 'g', 'kg': 'kg'},
                'ml' => {'ml': 'ml', 'l': 'L'},
                'un' => {'un': 'un'},
                _ => <String, String>{},
              };
            },
            visible: quoteVisible,
          ),
          EditField(
            'price',
            'Valor dos ingredientes nesta compra (R\$)',
            required: true,
            money: true,
            visible: quoteVisible,
          ),
        ],
      ],
      footer: Column(
        children: [
          if (hasQuote)
            const Text(
              'A cotação desta compra está preservada no histórico. Alterações financeiras não alteram o preço registrado.',
            ),
          if (_receiptName != null) Text(_receiptName!),
          AppButton(
            onPressed: _picking ? null : _pickReceipt,
            child: Text(
              _picking ? 'Selecionando…' : 'Anexar comprovante (até 10 MB)',
            ),
          ),
          if (_receipt != null ||
              (widget.initial?['receipt_path'] != null && !_removeReceipt))
            AppButton(
              onPressed: () => setState(() {
                _receipt = null;
                _receiptName = null;
                _removeReceipt = true;
              }),
              child: const Text('Remover comprovante'),
            ),
        ],
      ),
      onSave: (values) async {
        values['id'] = _entryId;
        if (_picking) {
          throw const FormatException('Aguarde a seleção do comprovante.');
        }
        final repository = ref.read(financeRepositoryProvider);
        DataRow? quote;
        if (values.remove('record_quote') == true &&
            values['type'] == 'saida' &&
            values['status'] == 'pago') {
          if (values['supplier_id'] == null) {
            throw const FormatException(
              'Selecione o fornecedor para registrar a compra.',
            );
          }
          final ingredient = widget.snapshot
              .rows('ingredients')
              .firstWhere((row) => row['id'] == values['ingredient_id']);
          FinancialMath.baseQuantity(
            values['package_size'],
            values['package_unit'],
            ingredient['base_unit'],
          );
          if (FinancialMath.cents(values['price']) >
              FinancialMath.cents(values['amount'])) {
            throw const FormatException(
              'O valor do ingrediente não pode superar o lançamento.',
            );
          }
          quote = {
            for (final key in [
              'ingredient_id',
              'package_size',
              'package_unit',
              'price',
            ])
              key: values[key],
          };
        }
        for (final key in [
          'ingredient_id',
          'package_size',
          'package_unit',
          'price',
        ]) {
          values.remove(key);
        }
        values['description'] ??= '';
        values['supplier_id'] = values['type'] == 'saida'
            ? values['supplier_id']
            : null;
        final oldPath = widget.initial?['receipt_path'] as String?;
        String? uploaded;
        try {
          if (_receipt != null) {
            uploaded = await repository.uploadReceipt(_receipt!, _extension!);
          }
          values['receipt_path'] =
              uploaded ?? (_removeReceipt ? null : oldPath);
          await repository.saveTransaction(values, quote);
        } catch (error) {
          if (uploaded != null && error is PostgrestException) {
            try {
              await repository.removeReceipt(uploaded);
            } catch (_) {}
          }
          rethrow;
        }
        if (oldPath != null && (uploaded != null || _removeReceipt)) {
          try {
            await repository.removeReceipt(oldPath);
          } catch (_) {}
        }
      },
    );
  }
}

class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FinanceBody(
    title: 'Lançamento',
    builder: (snapshot) {
      final entry = snapshot
          .rows('transactions')
          .where((row) => row['id'] == id)
          .firstOrNull;
      if (entry == null) {
        return [
          const SliverToBoxAdapter(
            child: Text('Lançamento excluído ou não encontrado.'),
          ),
        ];
      }
      return [
        SliverToBoxAdapter(
          child: FinanceSection(
            children: [
              AppListTile(
                title: Text(
                  BrFormatters.currencyFromCents(
                    FinancialMath.cents(entry['amount']),
                  ),
                ),
              ),
              for (final field in {
                'type': 'Tipo',
                'description': 'Descrição',
                'status': 'Status',
                'payment_method': 'Pagamento',
              }.entries)
                AppListTile(
                  title: Text(field.value),
                  subtitle: Text(
                    (transactionTypes[entry[field.key]] ??
                            paymentMethods[entry[field.key]] ??
                            paymentStatuses[entry[field.key]] ??
                            entry[field.key])
                        .toString(),
                    maxLines: 8,
                  ),
                ),
              AppListTile(
                title: const Text('Data'),
                subtitle: Text(
                  BrFormatters.date(DateTime.parse(entry['date'])),
                ),
              ),
              AppListTile(
                title: const Text('Categoria'),
                subtitle: Text(
                  snapshot.name('transaction_categories', entry['category_id']),
                ),
              ),
              if (entry['supplier_id'] != null)
                AppListTile(
                  title: const Text('Fornecedor'),
                  subtitle: Text(
                    snapshot.name('suppliers', entry['supplier_id']),
                  ),
                ),
              if (entry['recurring_id'] != null)
                const AppListTile(title: Text('Gerado por recorrência')),
              if (entry['receipt_path'] != null)
                AppButton(
                  onPressed: () async {
                    try {
                      final url = await ref
                          .read(financeRepositoryProvider)
                          .receiptUrl(entry['receipt_path']);
                      if (!await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      )) {
                        throw const FormatException(
                          'Não foi possível abrir o comprovante.',
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        await showFinanceError(context, error);
                      }
                    }
                  },
                  child: const Text('Abrir comprovante'),
                ),
              AppButton(
                onPressed: () => editTransaction(context, ref, snapshot, entry),
                child: const Text('Editar lançamento'),
              ),
              AppButton(
                onPressed: () => deleteRecord(context, ref, 'transactions', id),
                child: const Text('Excluir lançamento'),
              ),
            ],
          ),
        ),
      ];
    },
  );
}
