import 'package:flutter/cupertino.dart';

class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold({
    required this.title,
    required this.slivers,
    this.trailing,
    super.key,
  });

  final String title;
  final List<Widget> slivers;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > 832
              ? (constraints.maxWidth - 800) / 2
              : 16.0;

          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
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
