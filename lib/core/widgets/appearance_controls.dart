import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/appearance_controller.dart';
import '../theme/app_theme.dart';
import 'app_interaction.dart';

const _appearanceIcons = {
  AppAppearance.system: CupertinoIcons.circle_lefthalf_fill,
  AppAppearance.light: CupertinoIcons.sun_max_fill,
  AppAppearance.dark: CupertinoIcons.moon_fill,
};

class AppearanceButton extends ConsumerWidget {
  const AppearanceButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppButton(
    padding: const EdgeInsets.all(12),
    onPressed: () async {
      final choice = await showCupertinoModalPopup<AppAppearance>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Aparência'),
          actions: [
            for (final appearance in AppAppearance.values)
              CupertinoActionSheetAction(
                isDefaultAction:
                    ref.read(appearanceProvider).appearance == appearance,
                onPressed: () => Navigator.pop(context, appearance),
                child: Text(appearance.label),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ),
      );
      if (choice != null) {
        await ref.read(appearanceProvider.notifier).update(appearance: choice);
      }
    },
    child: Icon(
      _appearanceIcons[ref.watch(appearanceProvider).appearance],
      size: 22,
      semanticLabel: 'Alterar aparência',
    ),
  );
}

class AppearanceControls extends ConsumerWidget {
  const AppearanceControls({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appearanceProvider);
    final controller = ref.read(appearanceProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Aparência',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Escolha como você quer ver seu bar.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.secondaryTextColor.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mode in AppAppearance.values)
                  SizedBox(
                    width: MediaQuery.textScalerOf(context).scale(14) > 22
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 16) / 3,
                    child: Semantics(
                      selected: mode == settings.appearance,
                      child: AppButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        color: mode == settings.appearance
                            ? CupertinoTheme.of(context).primaryColor
                                  .withValues(alpha: .12)
                            : CupertinoColors.tertiarySystemFill.resolveFrom(
                                context,
                              ),
                        onPressed: () => controller.update(appearance: mode),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_appearanceIcons[mode], size: 24),
                            const SizedBox(height: 10),
                            Text(
                              mode.label,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              mode == settings.appearance
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.circle,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppListTile(
            padding: EdgeInsets.zero,
            title: const Text('Reduzir transparência', maxLines: 3),
            subtitle: const Text('Usar controles opacos', maxLines: 2),
            trailing: CupertinoSwitch(
              value: settings.reduceTransparency,
              onChanged: (value) =>
                  controller.update(reduceTransparency: value),
            ),
          ),
          AppListTile(
            padding: EdgeInsets.zero,
            title: const Text('Reduzir movimento', maxLines: 3),
            subtitle: const Text('Somar à preferência do sistema', maxLines: 3),
            trailing: CupertinoSwitch(
              value: settings.reduceMotion,
              onChanged: (value) => controller.update(reduceMotion: value),
            ),
          ),
          if (settings.saveFailed)
            Text(
              'A aparência foi aplicada, mas não foi possível salvar a preferência neste dispositivo.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.destructiveColor.resolveFrom(context),
              ),
            ),
        ],
      ),
    );
  }
}
