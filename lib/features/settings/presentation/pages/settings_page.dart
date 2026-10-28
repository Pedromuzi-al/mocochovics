import '../../../../core/widgets/app_interaction.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../../../../core/widgets/appearance_controls.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você precisará entrar novamente para acessar o aplicativo.',
        ),
        actions: [
          AppHover(
            child: CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
          ),
          AppHover(
            child: CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Sair',
                style: TextStyle(
                  color: AppTheme.destructiveColor.resolveFrom(dialogContext),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final controller = ref.read(authControllerProvider);
    final succeeded = await controller.signOut();
    if (!context.mounted || succeeded) return;

    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Não foi possível sair'),
        content: Text(
          controller.errorMessage ?? 'Verifique sua conexão e tente novamente.',
        ),
        actions: [
          AppHover(
            child: CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(authControllerProvider);
    final textTheme = CupertinoTheme.of(context).textTheme;
    final secondaryLabel = AppTheme.secondaryTextColor.resolveFrom(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) => FeatureScaffold(
        title: 'Mais',
        slivers: [
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              margin: EdgeInsets.zero,
              header: Text(
                'SUA CONTA',
                style: AppType.group.copyWith(color: secondaryLabel),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'E-mail',
                          style: textTheme.textStyle.copyWith(
                            fontSize: 15,
                            color: secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              CupertinoIcons.person_crop_circle,
                              color: CupertinoTheme.of(context).primaryColor,
                              size: 30,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                controller.email ?? 'E-mail indisponível',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              margin: EdgeInsets.zero,
              header: Text(
                'ORGANIZAÇÃO DO BAR',
                style: AppType.group.copyWith(color: secondaryLabel),
              ),
              children: [
                AppListTile.notched(
                  title: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Ingredientes', maxLines: 3),
                  ),
                  leading: Icon(
                    CupertinoIcons.leaf_arrow_circlepath,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => context.go('/mais/ingredientes'),
                ),
                AppListTile.notched(
                  title: const Text('Categorias'),
                  leading: const Icon(CupertinoIcons.tag),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => context.go('/mais/categorias'),
                ),
                AppListTile.notched(
                  title: const Text('Recorrências'),
                  leading: const Icon(CupertinoIcons.repeat),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => context.go('/mais/recorrencias'),
                ),
                AppListTile.notched(
                  title: const Text('Custos e alertas'),
                  leading: const Icon(CupertinoIcons.slider_horizontal_3),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => context.go('/mais/configuracoes'),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              margin: EdgeInsets.zero,
              header: Text(
                'APLICATIVO',
                style: AppType.group.copyWith(color: secondaryLabel),
              ),
              children: [
                const AppearanceControls(),
                AppListTile.notched(
                  title: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Sobre', maxLines: 3),
                  ),
                  leading: Icon(
                    CupertinoIcons.info_circle,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => context.go('/mais/sobre'),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemGroupedBackground
                    .resolveFrom(context),
                borderRadius: BorderRadius.circular(AppRadii.section),
              ),
              child: AppButton(
                onPressed: controller.isBusy
                    ? null
                    : () => _signOut(context, ref),
                child: controller.isBusy
                    ? Semantics(
                        label: 'Saindo da conta',
                        child: const CupertinoActivityIndicator(),
                      )
                    : Text(
                        'Sair da conta',
                        style: textTheme.textStyle.copyWith(
                          color: AppTheme.destructiveColor.resolveFrom(context),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
