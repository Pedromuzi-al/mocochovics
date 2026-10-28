import 'package:flutter/cupertino.dart';

import 'app_interaction.dart';
import 'liquid_glass.dart';

class FinanceSearchField extends StatelessWidget {
  const FinanceSearchField({
    required this.controller,
    required this.placeholder,
    required this.onChanged,
    super.key,
  });
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => LiquidGlass(
    radius: 18,
    child: AppHover(
      child: CupertinoSearchTextField(
        controller: controller,
        placeholder: placeholder,
        backgroundColor: CupertinoColors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        onChanged: onChanged,
      ),
    ),
  );
}
