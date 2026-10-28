import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'app_interaction.dart';
import 'app_navigation_menu.dart';
import 'liquid_glass.dart';

class FloatingNavigation extends StatelessWidget {
  const FloatingNavigation({
    required this.currentIndex,
    required this.onSelect,
    this.compact = false,
    super.key,
  });
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final bool compact;
  static const icons = [
    CupertinoIcons.house,
    CupertinoIcons.doc_text,
    CupertinoIcons.cube_box,
    CupertinoIcons.person_2,
    CupertinoIcons.ellipsis_circle,
  ];
  static const activeIcons = [
    CupertinoIcons.house_fill,
    CupertinoIcons.doc_text_fill,
    CupertinoIcons.cube_box_fill,
    CupertinoIcons.person_2_fill,
    CupertinoIcons.ellipsis_circle_fill,
  ];
  static const shortLabels = [
    'Início',
    'Extrato',
    'Produtos',
    'Fornec.',
    'Mais',
  ];

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(11) > 16;
    final labels = !compact && !largeText;
    final color = CupertinoTheme.of(context).primaryColor;
    return LiquidGlass(
      padding: const EdgeInsets.all(6),
      child: AnimatedSize(
        duration: AppMotion.duration(context, AppMotion.navigation),
        curve: AppMotion.spring,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: labels ? 64 : 50,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth / 5;
                  return Stack(
                    children: [
                      TweenAnimationBuilder<double>(
                        key: const ValueKey('tab-indicator'),
                        tween: Tween(
                          begin: currentIndex.toDouble(),
                          end: currentIndex.toDouble(),
                        ),
                        duration: AppMotion.duration(
                          context,
                          AppMotion.navigation,
                        ),
                        curve: AppMotion.spring,
                        builder: (context, position, child) {
                          final distance = (currentIndex - position)
                              .abs()
                              .clamp(0.0, 1.0);
                          final stretch =
                              width * .14 * math.sin(math.pi * distance);
                          return Positioned(
                            left: position * width - stretch / 2,
                            top: 0,
                            bottom: 0,
                            width: width + stretch,
                            child: child!,
                          );
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(
                              labels ? 28 : 24,
                            ),
                            border: Border.all(
                              color: color.withValues(alpha: .12),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < 5; i++)
                            Expanded(
                              child: Semantics(
                                label: 'Abrir ${AppNavigationMenu.labels[i]}',
                                button: true,
                                selected: currentIndex == i,
                                excludeSemantics: true,
                                onTap: () => onSelect(i),
                                child: SizedBox(
                                  height: double.infinity,
                                  child: AppButton(
                                    padding: EdgeInsets.zero,
                                    borderRadius: BorderRadius.circular(28),
                                    onPressed: () => onSelect(i),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(
                                            end: currentIndex == i ? 1.0 : 0.0,
                                          ),
                                          duration: AppMotion.duration(
                                            context,
                                            AppMotion.navigation,
                                          ),
                                          curve: AppMotion.spring,
                                          builder: (context, progress, child) =>
                                              Transform.translate(
                                                offset: Offset(
                                                  0,
                                                  -2 * progress,
                                                ),
                                                child: Transform.scale(
                                                  scale: 1 + .06 * progress,
                                                  child: child,
                                                ),
                                              ),
                                          child: Icon(
                                            currentIndex == i
                                                ? activeIcons[i]
                                                : icons[i],
                                            size: 23,
                                            color: currentIndex == i
                                                ? color
                                                : AppTheme.secondaryTextColor
                                                      .resolveFrom(context),
                                          ),
                                        ),
                                        if (labels) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            shortLabels[i],
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: currentIndex == i
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: currentIndex == i
                                                  ? color
                                                  : AppTheme.secondaryTextColor
                                                        .resolveFrom(context),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            if (largeText)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  AppNavigationMenu.labels[currentIndex],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
