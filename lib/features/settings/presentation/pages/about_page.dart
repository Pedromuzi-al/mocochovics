import '../../../../core/theme/app_theme.dart';

import 'package:flutter/cupertino.dart';

import '../../../../core/widgets/feature_scaffold.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;
    final secondaryLabel = AppTheme.secondaryTextColor.resolveFrom(context);

    return FeatureScaffold(
      title: 'Sobre',
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemGroupedBackground
                  .resolveFrom(context),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Bar do Mocochovisk',
                    style: textTheme.textStyle.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Versão 0.1.0',
                  style: textTheme.textStyle.copyWith(color: secondaryLabel),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Um lugar para cuidar das finanças, dos produtos e das '
                  'compras do bar.',
                ),
                const SizedBox(height: 24),
                Text(
                  'Finanças e custos do bar',
                  style: textTheme.textStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe entradas e saídas, organize fornecedores e '
                  'ingredientes e monte as fichas técnicas dos produtos. '
                  'O painel reúne indicadores, gráficos e alertas para '
                  'ajudar nas decisões do dia a dia. As margens estimam '
                  'o resultado dos ingredientes e não o lucro líquido do bar.',
                  style: textTheme.textStyle.copyWith(
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
