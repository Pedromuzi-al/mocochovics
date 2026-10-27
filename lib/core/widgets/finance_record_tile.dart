import 'app_interaction.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/design_tokens.dart';

import '../theme/app_theme.dart';
import 'app_motion.dart';

class FinanceRecordTile extends ConsumerWidget {
  const FinanceRecordTile({
    required this.id,
    required this.title,
    required this.onEdit,
    required this.onDelete,
    this.subtitle,
    this.onTap,
    this.titleColor,
    this.child,
    this.actionsInMenu = false,
    this.leading,
    super.key,
  });
  final String id, title;
  final String? subtitle;
  final VoidCallback onEdit, onDelete;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Widget? child;
  final bool actionsInMenu;
  final Widget? leading;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AnimatedOpacity(
    opacity: ref.watch(recordRemovalProvider.select((ids) => ids.contains(id)))
        ? 0
        : 1,
    duration: AppMotion.duration(context, AppMotion.short),
    child: AppReveal(
      key: ValueKey('reveal-$id'),
      child: Dismissible(
        key: ValueKey(id),
        background: Container(
          color: CupertinoColors.systemBlue,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(16),
          child: const Icon(
            CupertinoIcons.pencil,
            color: CupertinoColors.white,
          ),
        ),
        secondaryBackground: Container(
          color: CupertinoColors.systemRed,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.all(16),
          child: const Icon(
            CupertinoIcons.delete,
            color: CupertinoColors.white,
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onEdit();
          } else {
            onDelete();
          }
          return false;
        },
        child:
            child ??
            AppListTile(
              leading: leading,
              title: Text(
                title,
                maxLines: 3,
                style: AppTheme.tabularFigures(
                  CupertinoTheme.of(context).textTheme.textStyle,
                ).copyWith(color: titleColor),
              ),
              subtitle: subtitle == null ? null : Text(subtitle!, maxLines: 4),
              trailing: actionsInMenu
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CupertinoListTileChevron(),
                        AppButton(
                          padding: const EdgeInsets.all(10),
                          onPressed: () => showRecordActions(
                            context,
                            title,
                            onEdit,
                            onDelete,
                          ),
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            semanticLabel: 'Ações de $title',
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppButton(
                          padding: const EdgeInsets.all(10),
                          onPressed: onEdit,
                          child: const Icon(
                            CupertinoIcons.pencil,
                            semanticLabel: 'Editar',
                          ),
                        ),
                        AppButton(
                          padding: const EdgeInsets.all(10),
                          onPressed: onDelete,
                          child: const Icon(
                            CupertinoIcons.delete,
                            semanticLabel: 'Excluir',
                          ),
                        ),
                      ],
                    ),
              onTap: onTap ?? onEdit,
            ),
      ),
    ),
  );
}

Future<void> showRecordActions(
  BuildContext context,
  String title,
  VoidCallback onEdit,
  VoidCallback onDelete,
) async {
  final action = await showCupertinoModalPopup<String>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: Text(title),
      actions: [
        AppHover(
          child: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'edit'),
            child: const Text('Editar'),
          ),
        ),
        AppHover(
          child: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Excluir'),
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
