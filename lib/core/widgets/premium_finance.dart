import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

abstract final class FinancePalette {
  static const income = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF137548),
    darkColor: Color(0xFF65E5AA),
  );
  static const expense = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFBD303A),
    darkColor: Color(0xFFFF8992),
  );
  static const warning = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF925400),
    darkColor: Color(0xFFFFC46C),
  );
  static const chartColors = [
    income,
    AppTheme.actionColor,
    warning,
    expense,
    CupertinoColors.systemPurple,
    CupertinoColors.systemTeal,
  ];
}

class PremiumSurface extends StatelessWidget {
  const PremiumSurface({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: CupertinoColors.separator
            .resolveFrom(context)
            .withValues(alpha: 0.12),
      ),
    ),
    child: child,
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {this.subtitle, this.action, super.key});
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
            ?action,
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.secondaryTextColor.resolveFrom(context),
              ),
            ),
          ),
      ],
    ),
  );
}

class FinanceMetricCard extends StatelessWidget {
  const FinanceMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.note,
    super.key,
  });
  final String label, value;
  final IconData icon;
  final CupertinoDynamicColor accent;
  final String? note;
  @override
  Widget build(BuildContext context) {
    final color = accent.resolveFrom(context);
    return PremiumSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.textScalerOf(context).scale(13) * 2.5,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                height: 1.2,
                color: AppTheme.secondaryTextColor.resolveFrom(context),
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            child: Text(
              value,
              key: ValueKey(value),
              style: AppTheme.tabularFigures(
                TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                  color: color,
                ),
              ),
            ),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                note!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor.resolveFrom(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MarginNotice extends StatelessWidget {
  const MarginNotice({required this.message, this.warning = true, super.key});
  final String message;
  final bool warning;
  @override
  Widget build(BuildContext context) {
    final color = (warning ? FinancePalette.warning : AppTheme.actionColor)
        .resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning
                ? CupertinoIcons.exclamationmark_triangle
                : CupertinoIcons.info_circle,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, height: 1.4, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class FinanceEmptyState extends StatelessWidget {
  const FinanceEmptyState({
    required this.message,
    this.icon = CupertinoIcons.chart_bar,
    super.key,
  });
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
    child: Column(
      children: [
        Icon(
          icon,
          size: 30,
          color: AppTheme.secondaryTextColor.resolveFrom(context),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppTheme.secondaryTextColor.resolveFrom(context),
          ),
        ),
      ],
    ),
  );
}

class LabeledAmount extends StatelessWidget {
  const LabeledAmount({
    required this.label,
    required this.amount,
    this.color,
    super.key,
  });
  final String label, amount;
  final Color? color;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 280 ||
          MediaQuery.textScalerOf(context).scale(14) > 20;
      final labelWidget = Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.secondaryTextColor.resolveFrom(context),
        ),
      );
      final amountWidget = Text(
        amount,
        style: AppTheme.tabularFigures(
          TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: color),
        ),
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  labelWidget,
                  const SizedBox(height: 4),
                  amountWidget,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: labelWidget),
                  const SizedBox(width: 12),
                  Flexible(child: amountWidget),
                ],
              ),
      );
    },
  );
}
