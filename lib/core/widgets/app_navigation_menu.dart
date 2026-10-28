import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'app_interaction.dart';
import 'appearance_controls.dart';
import 'liquid_glass.dart';

class AppNavigationMenu extends StatelessWidget {
  const AppNavigationMenu({
    required this.currentIndex,
    required this.onSelect,
    required this.onToggle,
    this.email,
    this.collapsed = false,
    this.drawer = false,
    super.key,
  });
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggle;
  final String? email;
  final bool collapsed, drawer;

  static const labels = [
    'Início',
    'Extrato',
    'Produtos',
    'Fornecedores',
    'Mais',
  ];
  static const _icons = [
    CupertinoIcons.house,
    CupertinoIcons.doc_text,
    CupertinoIcons.cube_box,
    CupertinoIcons.person_2,
    CupertinoIcons.ellipsis_circle,
  ];
  static const _activeIcons = [
    CupertinoIcons.house_fill,
    CupertinoIcons.doc_text_fill,
    CupertinoIcons.cube_box_fill,
    CupertinoIcons.person_2_fill,
    CupertinoIcons.ellipsis_circle_fill,
  ];

  Widget _destination(BuildContext context, int index) {
    final selected = currentIndex == index;
    final color = selected
        ? CupertinoTheme.of(context).primaryColor
        : AppTheme.secondaryTextColor.resolveFrom(context);
    return Semantics(
      label: 'Abrir ${labels[index]}',
      button: true,
      selected: selected,
      excludeSemantics: true,
      onTap: () => onSelect(index),
      child: AppButton(
        padding: EdgeInsets.zero,
        onPressed: () => onSelect(index),
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.short),
          curve: AppMotion.curve,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: .1)
                : CupertinoColors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          child: Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.short),
                child: Icon(
                  selected ? _activeIcons[index] : _icons[index],
                  key: ValueKey(selected),
                  color: color,
                  size: 24,
                ),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LiquidGlass(
    radius: drawer ? 0 : 24,
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          collapsed ? 8 : 16,
          12,
          collapsed ? 8 : 16,
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                padding: const EdgeInsets.all(12),
                onPressed: onToggle,
                child: Icon(
                  drawer
                      ? CupertinoIcons.xmark
                      : CupertinoIcons.line_horizontal_3,
                  size: 24,
                  semanticLabel: drawer
                      ? 'Fechar menu'
                      : collapsed
                      ? 'Expandir menu'
                      : 'Recolher menu',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!collapsed) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoTheme.of(context).primaryColor
                              .withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(AppRadii.section),
                        ),
                        child: Icon(
                          CupertinoIcons.chart_bar_alt_fill,
                          size: 26,
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bar do\nMocochovisk',
                        style: TextStyle(
                          fontSize:
                              drawer &&
                                  MediaQuery.textScalerOf(context).scale(22) >
                                      32
                              ? 18
                              : 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'GESTÃO DO SEU BAR',
                        style: AppType.group.copyWith(
                          color: AppTheme.secondaryTextColor.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    for (var i = 0; i < labels.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SizedBox(
                          width: double.infinity,
                          child: _destination(context, i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const AppearanceButton(),
            if (!collapsed) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CupertinoIcons.person_crop_circle,
                    color: AppTheme.secondaryTextColor.resolveFrom(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email ?? 'Sua conta',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.caption.copyWith(
                        color: AppTheme.secondaryTextColor.resolveFrom(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
