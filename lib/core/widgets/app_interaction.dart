import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';

/// Adds pointer/focus feedback without intercepting a child's gestures or focus.
class AppHover extends StatefulWidget {
  const AppHover({
    required this.child,
    this.enabled = true,
    this.lift = false,
    this.radius = AppRadii.control,
    this.filled = false,
    super.key,
  });
  final Widget child;
  final bool enabled, lift, filled;
  final double radius;

  @override
  State<AppHover> createState() => _AppHoverState();
}

class _AppHoverState extends State<AppHover> {
  bool _hovered = false, _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && (_hovered || _focused);
    final primary = CupertinoTheme.of(context).primaryColor;
    final tint = widget.filled ? CupertinoColors.white : primary;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        canRequestFocus: false,
        onFocusChange: (value) => setState(() => _focused = value),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: active && widget.lift && !reduceMotion ? 1 : 0),
          duration: AppMotion.duration(context, AppMotion.short),
          curve: AppMotion.curve,
          builder: (context, progress, child) => Transform.translate(
            offset: Offset(0, -2 * progress),
            child: child,
          ),
          child: AnimatedContainer(
            duration: AppMotion.duration(context, AppMotion.short),
            curve: AppMotion.curve,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(
                    alpha: active && widget.lift ? .09 : 0,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              color: tint.withValues(
                alpha: active ? (widget.lift ? .025 : .08) : 0,
              ),
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(
                color: tint.withValues(
                  alpha: active ? (_focused ? .5 : .18) : 0,
                ),
                width: 1,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Keeps Cupertino touch, keyboard, disabled and accessibility behavior.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.child,
    required this.onPressed,
    this.padding,
    this.color,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.hoverFeedback = true,
    super.key,
  }) : _filled = false;
  const AppButton.filled({
    required this.child,
    required this.onPressed,
    this.padding,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.hoverFeedback = true,
    super.key,
  }) : _filled = true,
       color = null;

  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final AlignmentGeometry alignment;
  final bool _filled;
  final bool hoverFeedback;

  @override
  Widget build(BuildContext context) {
    final button = _filled
        ? CupertinoButton.filled(
            padding: padding,
            borderRadius: borderRadius,
            alignment: alignment,
            onPressed: onPressed,
            child: child,
          )
        : CupertinoButton(
            padding: padding,
            color: color,
            borderRadius: borderRadius,
            alignment: alignment,
            onPressed: onPressed,
            child: child,
          );
    final responsive = _PressResponse(
      enabled: onPressed != null,
      child: button,
    );
    return hoverFeedback
        ? AppHover(
            enabled: onPressed != null,
            filled: _filled || color != null,
            radius: borderRadius?.topLeft.x ?? AppRadii.control,
            child: responsive,
          )
        : responsive;
  }
}

class _PressResponse extends StatefulWidget {
  const _PressResponse({required this.enabled, required this.child});
  final bool enabled;
  final Widget child;
  @override
  State<_PressResponse> createState() => _PressResponseState();
}

class _PressResponseState extends State<_PressResponse> {
  bool _pressed = false;
  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.enabled ? (_) => _set(true) : null,
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: TweenAnimationBuilder<double>(
      tween: Tween(
        end:
            _pressed &&
                widget.enabled &&
                !MediaQuery.disableAnimationsOf(context)
            ? .97
            : 1,
      ),
      duration: AppMotion.duration(
        context,
        _pressed ? AppMotion.press : AppMotion.navigation,
      ),
      curve: AppMotion.spring,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: widget.child,
    ),
  );
}

class AppListTile extends StatelessWidget {
  const AppListTile({
    required this.title,
    this.subtitle,
    this.additionalInfo,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
    super.key,
  }) : _notched = false;
  const AppListTile.notched({
    required this.title,
    this.subtitle,
    this.additionalInfo,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
    super.key,
  }) : _notched = true;
  final Widget title;
  final Widget? subtitle, additionalInfo, leading, trailing;
  final FutureOr<void> Function()? onTap;
  final EdgeInsetsGeometry? padding;
  final bool _notched;

  @override
  Widget build(BuildContext context) => AppHover(
    enabled: onTap != null,
    radius: 0,
    child: FocusableActionDetector(
      enabled: onTap != null,
      mouseCursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onTap?.call();
            return null;
          },
        ),
      },
      child: _notched
          ? CupertinoListTile.notched(
              title: title,
              subtitle: subtitle,
              additionalInfo: additionalInfo,
              leading: leading,
              trailing: trailing,
              onTap: onTap,
              padding: padding,
            )
          : CupertinoListTile(
              title: title,
              subtitle: subtitle,
              additionalInfo: additionalInfo,
              leading: leading,
              trailing: trailing,
              onTap: onTap,
              padding: padding,
            ),
    ),
  );
}
