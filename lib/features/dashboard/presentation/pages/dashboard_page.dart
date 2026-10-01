import '../../../../core/theme/app_theme.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/feature_scaffold.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;
    final secondaryLabel = AppTheme.secondaryTextColor.resolveFrom(context);

    return FeatureScaffold(
      title: 'Início',
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
                ExcludeSemantics(
                  child: Icon(
                    CupertinoIcons.house_fill,
                    size: 36,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    'Bem-vindo ao\nBar do Mocochovisk',
                    style: textTheme.textStyle.copyWith(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'O controle do bar começa aqui.',
                  style: textTheme.textStyle.copyWith(
                    color: secondaryLabel,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'A navegação e o acesso à sua conta estão prontos. '
                  'Os cadastros e as informações financeiras serão '
                  'adicionados nas próximas etapas.',
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
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: CupertinoListSection.insetGrouped(
            margin: EdgeInsets.zero,
            header: Semantics(header: true, child: const Text('EXPLORE O APP')),
            footer: const Text(
              'Cada espaço apresenta os recursos previstos para o bar.',
            ),
            children: const [
              _Shortcut(
                title: 'Extrato',
                icon: CupertinoIcons.doc_text,
                route: '/extrato',
              ),
              _Shortcut(
                title: 'Produtos',
                icon: CupertinoIcons.cube_box,
                route: '/produtos',
              ),
              _Shortcut(
                title: 'Fornecedores',
                icon: CupertinoIcons.person_2,
                route: '/fornecedores',
              ),
              _Shortcut(
                title: 'Ingredientes',
                icon: CupertinoIcons.leaf_arrow_circlepath,
                route: '/mais/ingredientes',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.title,
    required this.icon,
    required this.route,
  });

  final String title;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile.notched(
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(title, maxLines: 3),
      ),
      leading: Icon(icon, color: CupertinoTheme.of(context).primaryColor),
      trailing: const CupertinoListTileChevron(),
      onTap: () {
        HapticFeedback.selectionClick();
        context.go(route);
      },
    );
  }
}
