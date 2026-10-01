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
                  'Em construção',
                  style: textTheme.textStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Esta versão entrega a estrutura do aplicativo, o tema '
                  'claro e escuro, a navegação e a autenticação. '
                  'Fornecedores, ingredientes, lançamentos, produtos, '
                  'indicadores e exportações serão implementados nas '
                  'próximas etapas.',
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
