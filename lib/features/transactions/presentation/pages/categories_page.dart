import '../../../../core/widgets/app_interaction.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/finance_record_tile.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../domain/statement_filter.dart';
import 'transaction_editor.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});
  Future<void> _edit(BuildContext context, WidgetRef ref, [DataRow? initial]) =>
      editRecord(
        context,
        ref,
        title: 'Categoria',
        table: 'transaction_categories',
        initial: initial,
        fields: const [
          EditField('name', 'Nome', required: true),
          EditField(
            'type',
            'Tipo',
            required: true,
            options: transactionTypes,
            defaultValue: 'saida',
          ),
        ],
      );
  @override
  Widget build(BuildContext context, WidgetRef ref) => FinanceBody(
    title: 'Categorias',
    trailing: AppButton(
      padding: EdgeInsets.zero,
      onPressed: () => _edit(context, ref),
      child: const Icon(CupertinoIcons.add, semanticLabel: 'Nova categoria'),
    ),
    builder: (snapshot) => snapshot.rows('transaction_categories').isEmpty
        ? [
            SliverToBoxAdapter(
              child: AppStateView(
                title: 'Organize suas categorias',
                message: 'Separe receitas e despesas para entender os resultados do bar.',
                icon: CupertinoIcons.tag,
                actionLabel: 'Cadastrar categoria',
                onAction: () => _edit(context, ref),
              ),
            ),
          ]
        : [
            SliverToBoxAdapter(
              child: FinanceSection(
                children: [
                  for (final category in snapshot.rows(
                    'transaction_categories',
                  ))
                    FinanceRecordTile(
                      id: category['id'],
                      title: category['name'],
                      subtitle: transactionTypes[category['type']],
                      onEdit: () => _edit(context, ref, category),
                      onDelete: () => deleteRecord(
                        context,
                        ref,
                        'transaction_categories',
                        category['id'],
                      ),
                    ),
                ],
              ),
            ),
          ],
  );
}
