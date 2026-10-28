import 'package:flutter/cupertino.dart';

import '../theme/design_tokens.dart';

class SheetDismissGuard {
  bool blocked = false;
}

class FinanceSheetScope extends InheritedWidget {
  const FinanceSheetScope({
    required this.guard,
    required this.controller,
    required super.child,
    super.key,
  });
  final SheetDismissGuard guard;
  final ScrollController controller;
  static FinanceSheetScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FinanceSheetScope>();
  @override
  bool updateShouldNotify(FinanceSheetScope oldWidget) =>
      guard != oldWidget.guard || controller != oldWidget.controller;
}

/// Native, gesture-following sheets with form-owned dismissal protection.
class FinanceSheetRoute<T> extends CupertinoSheetRoute<T> {
  FinanceSheetRoute({
    required Widget page,
    required this.guard,
    required this.reducedMotion,
  }) : super(
         showDragHandle: true,
         scrollableBuilder: (context, controller) => Center(
           child: ConstrainedBox(
             constraints: const BoxConstraints(maxWidth: 760),
             child: FinanceSheetScope(
               guard: guard,
               controller: controller,
               child: ClipRRect(
                 borderRadius: const BorderRadius.vertical(
                   top: Radius.circular(AppRadii.card),
                 ),
                 child: page,
               ),
             ),
           ),
         ),
       );
  final SheetDismissGuard guard;
  final bool reducedMotion;
  // Cupertino's native drag calls pop directly. Disable it while dirty or busy;
  // the explicit close button and system back show the discard confirmation.
  @override
  bool get enableDrag => !guard.blocked;
  @override
  Duration get transitionDuration =>
      reducedMotion ? Duration.zero : AppMotion.navigation;
  @override
  Duration get reverseTransitionDuration =>
      reducedMotion ? Duration.zero : AppMotion.reveal;
}
