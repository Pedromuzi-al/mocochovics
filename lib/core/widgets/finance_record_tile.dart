import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

class FinanceRecordTile extends StatelessWidget {
  const FinanceRecordTile({
    required this.id,
    required this.title,
    required this.onEdit,
    required this.onDelete,
    this.subtitle,
    this.onTap,
    this.titleColor,
    this.child,
    super.key,
  });
  final String id, title;
  final String? subtitle;
  final VoidCallback onEdit, onDelete;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Widget? child;
  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey(id),
    background: Container(
      color: CupertinoColors.systemBlue,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(16),
      child: const Icon(CupertinoIcons.pencil, color: CupertinoColors.white),
    ),
    secondaryBackground: Container(
      color: CupertinoColors.systemRed,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.all(16),
      child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
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
        CupertinoListTile(
          title: Text(
            title,
            maxLines: 3,
            style: AppTheme.tabularFigures(
              CupertinoTheme.of(context).textTheme.textStyle,
            ).copyWith(color: titleColor),
          ),
          subtitle: subtitle == null ? null : Text(subtitle!, maxLines: 4),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.all(10),
                onPressed: onEdit,
                child: const Icon(
                  CupertinoIcons.pencil,
                  semanticLabel: 'Editar',
                ),
              ),
              CupertinoButton(
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
  );
}
