import 'app_interaction.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/transactions/data/finance_repository.dart';
import '../../features/transactions/domain/statement_filter.dart';
import '../utils/financial_math.dart';
import '../utils/br_currency_input_formatter.dart';
import '../utils/br_formatters.dart';
import 'feature_scaffold.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'app_states.dart';
import 'app_motion.dart';
export 'app_states.dart';

String financeError(Object error) {
  if (error is FormatException) return error.message;
  if (error is PostgrestException) {
    if (error.code == '42P01' || error.code == 'PGRST205') {
      return 'Atualize o banco aplicando as migrations 001 e 002 do projeto no Supabase e tente novamente.';
    }
    if (error.code == '23503') {
      return 'Este cadastro está em uso. Desative-o ou remova os vínculos antes de excluir.';
    }
    if (error.code == '23505') return 'Já existe um registro com esses dados.';
    if (error.code == '42501') {
      return 'Sua sessão não permite esta operação. Entre novamente.';
    }
    if (error.code == 'P0001') return error.message;
    if (error.code == '23514' || error.code == '22003') {
      return 'Confira os valores e os limites dos campos.';
    }
  }
  return 'Não foi possível concluir. Confira sua conexão e a migration do Supabase e tente novamente.';
}

Future<void> showFinanceError(BuildContext context, Object error) =>
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Não foi possível concluir'),
        content: Text(financeError(error)),
        actions: [
          AppHover(
            child: CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );

Future<bool> confirmDelete(BuildContext context) async =>
    await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Excluir registro?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          AppHover(
            child: CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
          ),
          AppHover(
            child: CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Excluir'),
            ),
          ),
        ],
      ),
    ) ??
    false;

Future<void> deleteRecord(
  BuildContext context,
  WidgetRef ref,
  String table,
  String id,
) async {
  if (!await confirmDelete(context) || !context.mounted) return;
  try {
    await ref.read(financeRepositoryProvider).delete(table, id);
    if (!context.mounted) return;
    final motion = ref.read(recordRemovalProvider.notifier);
    motion.begin(id);
    try {
      await Future<void>.delayed(AppMotion.duration(context, AppMotion.short));
      if (!context.mounted) return;
      ref.invalidate(financeSnapshotProvider);
      try {
        await ref.read(financeSnapshotProvider.future);
      } catch (_) {
        /* The shared body displays refresh failures. */
      }
      HapticFeedback.mediumImpact();
    } finally {
      motion.finish(id);
    }
  } catch (error) {
    if (context.mounted) await showFinanceError(context, error);
  }
}

class FinanceBody extends ConsumerWidget {
  const FinanceBody({
    required this.title,
    required this.builder,
    this.trailing,
    this.maxContentWidth = AppLayout.contentWidth,
    super.key,
  });
  final double maxContentWidth;
  final String title;
  final Widget? trailing;
  final List<Widget> Function(FinanceSnapshot snapshot) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(financeSnapshotProvider);
    return FeatureScaffold(
      title: title,
      trailing: trailing,
      maxContentWidth: maxContentWidth,
      slivers: data.when(
        loading: () => [const SliverToBoxAdapter(child: FinanceLoadingState())],
        error: (error, stack) => [
          SliverToBoxAdapter(
            child: AppStateView(
              title: error is PostgrestException && error.code == '42501'
                  ? 'Acesso indisponível'
                  : 'Não foi possível carregar',
              message: financeError(error),
              icon: CupertinoIcons.wifi_exclamationmark,
              actionLabel: 'Tentar novamente',
              onAction: () => ref.invalidate(financeSnapshotProvider),
            ),
          ),
        ],
        data: (snapshot) => [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(financeSnapshotProvider);
              await ref.read(financeSnapshotProvider.future);
            },
          ),
          ...builder(snapshot),
        ],
      ),
    );
  }
}

class FinanceSection extends StatelessWidget {
  const FinanceSection({required this.children, this.title, super.key});
  final String? title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: CupertinoListSection.insetGrouped(
      margin: EdgeInsets.zero,
      header: title == null
          ? null
          : Text(
              title!,
              style: AppType.group.copyWith(
                color: AppTheme.secondaryTextColor.resolveFrom(context),
              ),
            ),
      children: children.isEmpty
          ? [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Nenhum registro encontrado.'),
              ),
            ]
          : children,
    ),
  );
}

/// Grouped rows built only when they enter the viewport, with stable identities.
class FinanceSliverList extends StatelessWidget {
  const FinanceSliverList({
    required this.ids,
    required this.itemBuilder,
    super.key,
  });
  final List<String> ids;
  final IndexedWidgetBuilder itemBuilder;
  @override
  Widget build(BuildContext context) => SliverList.builder(
    itemCount: ids.length,
    findChildIndexCallback: (key) {
      final index = ids.indexOf((key as ValueKey<String>).value);
      return index < 0 ? null : index;
    },
    itemBuilder: (context, index) => ClipRRect(
      key: ValueKey(ids[index]),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(index == 0 ? AppRadii.section : 0),
        bottom: Radius.circular(index == ids.length - 1 ? AppRadii.section : 0),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          border: index < ids.length - 1
              ? Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator
                        .resolveFrom(context)
                        .withValues(alpha: .25),
                  ),
                )
              : null,
        ),
        child: itemBuilder(context, index),
      ),
    ),
  );
}

class EditField {
  const EditField(
    this.key,
    this.label, {
    this.required = false,
    this.number = false,
    this.money = false,
    this.integer = false,
    this.date = false,
    this.toggle = false,
    this.options,
    this.optionsBuilder,
    this.defaultValue,
    this.maxLength = 200,
    this.visible,
    this.validate,
    this.allowZero = false,
  });
  final String key;
  final String label;
  final bool required, number, money, integer, date, toggle;
  final bool allowZero;
  final Map<String, String>? options;
  final Map<String, String> Function(DataRow values)? optionsBuilder;
  final Object? defaultValue;
  final int maxLength;
  final bool Function(DataRow values)? visible;
  final String? Function(String value)? validate;
}

Future<T?> openFinanceSheet<T>(BuildContext context, Widget page) =>
    showCupertinoModalPopup<T>(
      context: context,
      useRootNavigator: false,
      builder: (context) => SafeArea(
        top: true,
        bottom: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 760,
              maxHeight: MediaQuery.sizeOf(context).height * .92,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.card),
              ),
              child: CupertinoPopupSurface(child: page),
            ),
          ),
        ),
      ),
    );

Future<T?> openFinancePage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(CupertinoPageRoute(builder: (_) => page));

Future<void> editRecord(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String table,
  required List<EditField> fields,
  DataRow? initial,
  Future<void> Function(DataRow)? save,
  DataRow Function(DataRow)? transform,
}) async {
  final repository = ref.read(financeRepositoryProvider);
  final saved = await openFinancePage<bool>(
    context,
    RecordEditor(
      title: title,
      fields: fields,
      initial: initial,
      onSave: (values) async {
        final payload = transform == null ? values : transform(values);
        if (save != null) {
          await save(payload);
        } else {
          await repository.save(table, payload);
        }
      },
    ),
  );
  if (saved == true) ref.invalidate(financeSnapshotProvider);
}

class RecordEditor extends StatefulWidget {
  const RecordEditor({
    required this.title,
    required this.fields,
    required this.onSave,
    this.initial,
    this.footer,
    this.saveLabel = 'Salvar',
    this.showNavigationSave = true,
    super.key,
  });
  final String title;
  final List<EditField> fields;
  final DataRow? initial;
  final Future<void> Function(DataRow) onSave;
  final Widget? footer;
  final String saveLabel;
  final bool showNavigationSave;
  @override
  State<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<RecordEditor> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  late DataRow _values;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _values = {if (widget.initial?['id'] != null) 'id': widget.initial!['id']};
    for (final field in widget.fields) {
      final value =
          widget.initial?[field.key] ??
          field.defaultValue ??
          (field.toggle ? false : '');
      _values[field.key] = value;
      final text = field.money && value.toString().isNotEmpty
          ? BrFormatters.currencyFromCents(FinancialMath.cents(value))
          : value.toString();
      _controllers[field.key] = TextEditingController(text: text);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final payload = <String, dynamic>{
        if (_values['id'] != null) 'id': _values['id'],
      };
      for (final field in widget.fields) {
        if (field.visible != null && !field.visible!(_values)) continue;
        final value = _values[field.key];
        if (field.toggle) {
          payload[field.key] = value;
        } else if (value.toString().trim().isEmpty) {
          payload[field.key] = null;
        } else if (field.integer) {
          payload[field.key] = int.parse(value.toString());
        } else if (field.money || field.number) {
          payload[field.key] = FinancialMath.number(
            value.toString(),
            scale: field.money ? 2 : 6,
            positive: !field.allowZero,
          );
        } else {
          payload[field.key] = value.toString().trim();
        }
      }
      await widget.onSave(payload);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = financeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      middle: Text(widget.title),
      trailing: !widget.showNavigationSave
          ? null
          : _busy
          ? const CupertinoActivityIndicator()
          : AppButton(
              padding: EdgeInsets.zero,
              onPressed: _save,
              child: Text(widget.saveLabel),
            ),
    ),
    child: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.formWidth),
          child: Form(
            key: _form,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final field in widget.fields)
                        if (field.visible == null || field.visible!(_values))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: CupertinoColors
                                    .secondarySystemGroupedBackground
                                    .resolveFrom(context),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.section,
                                ),
                              ),
                              child: _field(field),
                            ),
                          ),
                      if (widget.footer != null)
                        IgnorePointer(ignoring: _busy, child: widget.footer!),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: CupertinoColors.systemRed.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppButton.filled(
                      onPressed: _busy ? null : _save,
                      child: Text(_busy ? 'Salvando…' : widget.saveLabel),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _field(EditField field) {
    final value = _values[field.key];
    if (field.toggle) {
      return AppListTile(
        title: Text(field.label),
        trailing: AppHover(
          child: CupertinoSwitch(
            value: value == true,
            onChanged: _busy
                ? null
                : (value) => setState(() => _values[field.key] = value),
          ),
        ),
      );
    }
    if (field.date) {
      return AppListTile(
        title: Text(field.label),
        subtitle: Text(value.toString().split('-').reversed.join('/')),
        onTap: _busy
            ? null
            : () async {
                final selected = await chooseDate(
                  context,
                  DateTime.tryParse(value.toString()) ?? DateTime.now(),
                );
                if (selected != null && mounted) {
                  setState(
                    () => _values[field.key] = FinancialMath.date(selected),
                  );
                }
              },
      );
    }
    final options = field.optionsBuilder?.call(_values) ?? field.options;
    if (options != null) {
      return FormField<String>(
        validator: (_) =>
            field.required && !options.containsKey(_values[field.key])
            ? 'Selecione ${field.label.toLowerCase()}.'
            : null,
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppListTile(
              title: Text(field.label),
              subtitle: Text(options[value] ?? 'Selecionar'),
              trailing: const CupertinoListTileChevron(),
              onTap: _busy
                  ? null
                  : () async {
                      final selected = await chooseOption(
                        context,
                        field.label,
                        {if (!field.required) '': 'Não informado', ...options},
                      );
                      if (selected != null && mounted) {
                        setState(() => _values[field.key] = selected);
                        state.didChange(selected);
                      }
                    },
            ),
            if (state.hasError)
              Text(
                state.errorText!,
                style: TextStyle(
                  color: CupertinoColors.systemRed.resolveFrom(context),
                ),
              ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: AppType.caption.copyWith(
              color: AppTheme.secondaryTextColor.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 6),
          AppHover(
            child: CupertinoTextFormFieldRow(
              controller: _controllers[field.key],
              enabled: !_busy,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemGroupedBackground
                    .resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
              ),
              maxLength: field.maxLength,
              inputFormatters: field.money
                  ? [BrCurrencyInputFormatter()]
                  : null,
              keyboardType: field.money || field.number
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : field.integer
                  ? TextInputType.number
                  : TextInputType.text,
              onChanged: (text) => setState(() => _values[field.key] = text),
              validator: (text) {
                if (field.required && (text == null || text.trim().isEmpty)) {
                  return 'Preencha ${field.label.toLowerCase()}.';
                }
                if (text == null || text.trim().isEmpty) return null;
                if (field.integer &&
                    (int.tryParse(text) == null || int.parse(text) < 0)) {
                  return 'Informe um inteiro maior ou igual a zero.';
                }
                if (field.money || field.number) {
                  try {
                    FinancialMath.number(
                      text,
                      scale: field.money ? 2 : 6,
                      positive: !field.allowZero,
                    );
                  } on FormatException catch (error) {
                    return error.message;
                  }
                }
                return field.validate?.call(text);
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> chooseOption(
  BuildContext context,
  String title,
  Map<String, String> options,
) => openFinanceSheet<String>(
  context,
  CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      middle: Text(title),
      trailing: AppButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.pop(context),
        child: const Icon(
          CupertinoIcons.xmark,
          semanticLabel: 'Fechar seleção',
        ),
      ),
    ),
    child: SafeArea(
      child: ListView(
        children: [
          for (final option in options.entries)
            AppListTile(
              title: Text(option.value, maxLines: 3),
              onTap: () => Navigator.pop(context, option.key),
            ),
        ],
      ),
    ),
  ),
);

Future<DateTime?> chooseDate(BuildContext context, DateTime initial) async {
  var selected = initial;
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (sheetContext) => Container(
      height: 350,
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            AppButton(
              onPressed: () => Navigator.pop(sheetContext, selected),
              child: const Text('Confirmar data'),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                onDateTimeChanged: (value) => selected = value,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Map<String, String> rowOptions(FinanceSnapshot snapshot, String table) => {
  for (final row in snapshot.rows(table))
    row['id'] as String: row['name'].toString(),
};
