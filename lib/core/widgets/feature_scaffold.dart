import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../theme/design_tokens.dart';
import 'app_interaction.dart';

class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold({
    required this.title,
    required this.slivers,
    this.trailing,
    this.maxContentWidth = AppLayout.contentWidth,
    this.isDashboard = false,
    super.key,
  });

  final String title;
  final List<Widget> slivers;
  final Widget? trailing;
  final double maxContentWidth;
  final bool isDashboard;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final router = GoRouter.maybeOf(context);
    final canGoBack = navigator.canPop();
    final showDashboard = !isDashboard && router != null;

    void openDashboard() {
      // A detail pushed with Navigator may share the dashboard's URL. Clear
      // that stack too, so returning to /inicio always reveals the panel.
      navigator.popUntil((route) => route.isFirst);
      router?.go('/inicio');
    }

    Widget dashboardButton({bool label = false}) => AppButton(
      padding: const EdgeInsets.all(10),
      onPressed: openDashboard,
      child: Semantics(
        label: 'Voltar ao painel',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.house, size: 21),
            if (label) ...[
              const SizedBox(width: 8),
              const Text('Painel', style: TextStyle(fontSize: 15)),
            ],
          ],
        ),
      ),
    );

    return CupertinoPageScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = AppLayout.inset(
            constraints.maxWidth,
            maxContentWidth,
          );
          final wide =
              MediaQuery.sizeOf(context).width >= AppLayout.sidebarBreakpoint;

          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              if (wide)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      32,
                      horizontalPadding,
                      8,
                    ),
                    child: Row(
                      children: [
                        if (canGoBack) ...[
                          CupertinoNavigationBarBackButton(
                            previousPageTitle: 'Voltar',
                            onPressed: () => navigator.maybePop(),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(title, style: AppType.page),
                          ),
                        ),
                        if (showDashboard) dashboardButton(label: true),
                        ?trailing,
                      ],
                    ),
                  ),
                )
              else
                CupertinoSliverNavigationBar(
                  largeTitle: Text(title),
                  trailing: showDashboard
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [dashboardButton(), ?trailing],
                        )
                      : trailing,
                  border: null,
                ),
              SliverSafeArea(
                top: false,
                sliver: SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    32,
                  ),
                  sliver: SliverMainAxisGroup(slivers: slivers),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
