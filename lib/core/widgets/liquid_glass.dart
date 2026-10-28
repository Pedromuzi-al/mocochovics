import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/appearance_controller.dart';
import '../theme/design_tokens.dart';

/// Glass is reserved for navigation and controls; financial content stays solid.
class LiquidGlass extends ConsumerWidget {
  const LiquidGlass({
    required this.child,
    this.radius = AppRadii.glass,
    this.padding = EdgeInsets.zero,
    super.key,
  });
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final opaque =
        ref.watch(
          appearanceProvider.select((value) => value.reduceTransparency),
        ) ||
        MediaQuery.highContrastOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final surface = dark ? const Color(0xFF20232B) : const Color(0xFFF8FAFF);
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: surface.withValues(
          alpha: opaque
              ? 1
              : dark
              ? .88
              : .84,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: dark ? .18 : .9),
        ),
        gradient: opaque
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  surface.withValues(alpha: dark ? .92 : .95),
                  surface.withValues(alpha: dark ? .75 : .78),
                ],
              ),
      ),
      child: Padding(padding: padding, child: child),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: dark ? .28 : .09),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: opaque
            ? content
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: content,
              ),
      ),
    );
  }
}
