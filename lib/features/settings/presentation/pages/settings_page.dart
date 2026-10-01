import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/feature_scaffold.dart';
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
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Sair',
              style: TextStyle(
                color: AppTheme.destructiveColor.resolveFrom(dialogContext),
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
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
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
              header: const Text('SUA CONTA'),
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
                        Text(controller.email ?? 'E-mail indisponível'),
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
              header: const Text('ORGANIZAÇÃO DO BAR'),
              children: [
                CupertinoListTile.notched(
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
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              margin: EdgeInsets.zero,
              header: const Text('APLICATIVO'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aparência'),
                        const SizedBox(height: 6),
                        Text(
                          'Automática · acompanha o sistema',
                          style: textTheme.textStyle.copyWith(
                            fontSize: 15,
                            color: secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                CupertinoListTile.notched(
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: CupertinoButton(
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
