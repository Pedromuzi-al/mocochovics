import 'app_interaction.dart';

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'app_motion.dart';

class AppStateView extends StatelessWidget {
  const AppStateView({
    required this.title,
    required this.message,
    this.icon = CupertinoIcons.tray,
    this.actionLabel,
    this.onAction,
    super.key,
  });
  final String title, message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => AppReveal(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemFill.resolveFrom(
                    context,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: AppTheme.secondaryTextColor.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppType.section,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppTheme.secondaryTextColor.resolveFrom(context),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                AppButton.filled(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class FinanceLoadingState extends StatelessWidget {
  const FinanceLoadingState({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Carregando seus dados',
    liveRegion: true,
    child: AppReveal(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Row(
              children: [
                CupertinoActivityIndicator(),
                SizedBox(width: 12),
                Expanded(child: Text('Atualizando seu bar…')),
              ],
            ),
            const SizedBox(height: 24),
            for (final height in [112.0, 72.0, 72.0])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: height,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: CupertinoColors.tertiarySystemFill.resolveFrom(
                      context,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.section),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
