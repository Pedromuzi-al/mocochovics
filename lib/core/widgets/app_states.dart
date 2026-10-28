import 'app_interaction.dart';

import 'dart:async';

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

class FinanceLoadingState extends StatefulWidget {
  const FinanceLoadingState({this.onRetry, super.key});
  final VoidCallback? onRetry;
  @override
  State<FinanceLoadingState> createState() => _FinanceLoadingStateState();
}

class _FinanceLoadingStateState extends State<FinanceLoadingState> {
  Timer? _timer;
  bool _delayed = false;
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 20), () {
      if (mounted) setState(() => _delayed = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _delayed
      ? AppStateView(
          icon: CupertinoIcons.wifi_exclamationmark,
          title: 'A conexão está demorando',
          message: 'Confira sua conexão e tente carregar seus dados novamente.',
          actionLabel: widget.onRetry == null ? null : 'Tentar novamente',
          onAction: widget.onRetry == null
              ? null
              : () {
                  setState(() => _delayed = false);
                  _startTimer();
                  widget.onRetry!();
                },
        )
      : Semantics(
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
