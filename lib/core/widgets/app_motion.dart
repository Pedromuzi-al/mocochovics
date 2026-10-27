import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/br_formatters.dart';

final recordRemovalProvider = NotifierProvider<RecordRemoval, Set<String>>(
  RecordRemoval.new,
);

class RecordRemoval extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  void begin(String id) {
    if (ref.mounted) state = {...state, id};
  }

  void finish(String id) {
    if (ref.mounted) state = {...state}..remove(id);
  }
}

/// Runs once for this element, without moving its layout or replaying on rebuild.
class AppReveal extends StatefulWidget {
  const AppReveal({required this.child, this.order = 0, super.key});
  final Widget child;
  final int order;
  @override
  State<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends State<AppReveal>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.reveal,
  );
  late final _animation = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.curve,
  );
  Timer? _timer;
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _timer?.cancel();
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _timer = Timer(Duration(milliseconds: widget.order.clamp(0, 4) * 35), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _animation,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.025),
        end: Offset.zero,
      ).animate(_animation),
      child: widget.child,
    ),
  );
}

class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({required this.cents, this.style, super.key});
  final int cents;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => Semantics(
    label: BrFormatters.currencyFromCents(cents),
    excludeSemantics: true,
    child: TweenAnimationBuilder<int>(
      tween: IntTween(begin: cents, end: cents),
      duration: AppMotion.duration(context, AppMotion.reveal),
      curve: AppMotion.curve,
      builder: (context, value, child) => Text(
        BrFormatters.currencyFromCents(value),
        style: AppTheme.tabularFigures(
          style ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}
