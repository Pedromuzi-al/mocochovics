import 'package:decimal/decimal.dart';

abstract final class FinancialMath {
  static String number(String input, {int scale = 6, bool positive = true}) {
    final normalized = input
        .trim()
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('\u00a0', '');
    final canonical = normalized.contains(',')
        ? normalized.replaceAll('.', '').replaceAll(',', '.')
        : normalized;
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(canonical)) {
      throw const FormatException('Informe um número válido.');
    }
    final value = Decimal.parse(canonical);
    if (positive && value <= Decimal.zero) {
      throw const FormatException('O valor deve ser maior que zero.');
    }
    if (value != value.round(scale: scale)) {
      throw FormatException('Use no máximo $scale casas decimais.');
    }
    return value.toStringAsFixed(scale);
  }

  static Decimal baseQuantity(String size, String unit, String baseUnit) {
    final compatible = switch (baseUnit) {
      'g' => const ['g', 'kg'],
      'ml' => const ['ml', 'l'],
      'un' => const ['un'],
      _ => const <String>[],
    };
    if (!compatible.contains(unit)) {
      throw const FormatException('Unidade incompatível com o ingrediente.');
    }
    return Decimal.parse(number(size)) *
        Decimal.fromInt(unit == 'kg' || unit == 'l' ? 1000 : 1);
  }

  static Decimal unitPrice(
    String price,
    String size,
    String unit,
    String baseUnit,
  ) =>
      (Decimal.parse(number(price, scale: 2)) /
              baseQuantity(size, unit, baseUnit))
          .toDecimal(
            scaleOnInfinitePrecision: 6,
            toBigInt: (value) => value.round(),
          )
          .round(scale: 6);

  static int cents(Object? amount) =>
      (Decimal.parse(amount.toString()) * Decimal.fromInt(100))
          .round()
          .toBigInt()
          .toInt();

  static String date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
