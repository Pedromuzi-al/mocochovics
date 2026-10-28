import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../theme/design_tokens.dart';
import 'liquid_glass.dart';

class OperationFeedback extends StatefulWidget {
  const OperationFeedback({required this.child, super.key});
  final Widget child;
  static void show(BuildContext context, String message) => context
      .findAncestorStateOfType<_OperationFeedbackState>()
      ?._show(message);
  @override
  State<OperationFeedback> createState() => _OperationFeedbackState();
}

class _OperationFeedbackState extends State<OperationFeedback> {
  Timer? _timer;
  String? _message;
  void _show(String message) {
    _timer?.cancel();
    setState(() => _message = message);
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _message = null);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: widget.child),
      Positioned(
        left: 24,
        right: 24,
        top: MediaQuery.paddingOf(context).top + 16,
        child: IgnorePointer(
          child: AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.short),
            child: _message == null
                ? const SizedBox.shrink()
                : Center(
                    child: Semantics(
                      liveRegion: true,
                      child: LiquidGlass(
                        key: ValueKey(_message),
                        radius: 22,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              color: CupertinoColors.activeGreen,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                _message!,
                                style: CupertinoTheme.of(context)
                                    .textTheme
                                    .textStyle
                                    .copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    ],
  );
}
