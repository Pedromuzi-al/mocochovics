import 'package:flutter/cupertino.dart';

import '../theme/design_tokens.dart';

class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold({
    required this.title,
    required this.slivers,
    this.trailing,
    this.maxContentWidth = AppLayout.contentWidth,
    super.key,
  });

  final String title;
  final List<Widget> slivers;
  final Widget? trailing;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
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
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(title, style: AppType.page),
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
                  ),
                )
              else
                CupertinoSliverNavigationBar(
                  largeTitle: Text(title),
                  trailing: trailing,
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
