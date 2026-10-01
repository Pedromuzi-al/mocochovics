import '../theme/app_theme.dart';

import 'package:flutter/cupertino.dart';

import 'feature_scaffold.dart';

class FeaturePendingPage extends StatelessWidget {
  const FeaturePendingPage({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;
    final secondaryLabel = AppTheme.secondaryTextColor.resolveFrom(context);

    return FeatureScaffold(
      title: title,
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemGroupedBackground
                  .resolveFrom(context),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    icon,
                    size: 40,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    'Este espaço está sendo preparado',
                    style: textTheme.textStyle.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: textTheme.textStyle.copyWith(
                    color: secondaryLabel,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Você está na primeira etapa: estrutura, navegação e acesso '
                  'à conta. Os recursos desta tela ainda não estão disponíveis.',
                  style: textTheme.textStyle.copyWith(
                    fontSize: 15,
                    color: secondaryLabel,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
