import 'package:decimal/decimal.dart';

import '../../transactions/domain/statement_filter.dart';

abstract final class PriceHistory {
  static List<DataRow> chronological(Iterable<DataRow> prices) =>
      prices.toList()..sort((first, second) {
        final date = first['date'].toString().compareTo(
          second['date'].toString(),
        );
        if (date != 0) return date;
        final created = first['created_at'].toString().compareTo(
          second['created_at'].toString(),
        );
        return created != 0
            ? created
            : first['id'].toString().compareTo(second['id'].toString());
      });

  static List<DataRow> current(Iterable<DataRow> prices) {
    final result = <String, DataRow>{};
    for (final price in chronological(prices)) {
      result['${price['ingredient_id']}/${price['supplier_id']}'] = price;
    }
    return result.values.toList()..sort(
      (first, second) =>
          Decimal.parse(first['unit_price'].toString())
              .compareTo(Decimal.parse(second['unit_price'].toString())),
    );
  }

  static String? variation(Iterable<DataRow> prices) {
    final sorted = chronological(prices);
    if (sorted.length < 2) return null;
    final current = Decimal.parse(sorted.last['unit_price'].toString());
    final previous = Decimal.parse(
      sorted[sorted.length - 2]['unit_price'].toString(),
    );
    if (previous == Decimal.zero) return null;
    return (((current - previous) * Decimal.fromInt(100)) / previous)
        .toDecimal(
          scaleOnInfinitePrecision: 2,
          toBigInt: (value) => value.round(),
        )
        .toStringAsFixed(2);
  }
}
