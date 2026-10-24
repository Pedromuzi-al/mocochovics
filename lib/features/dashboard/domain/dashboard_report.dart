import 'package:decimal/decimal.dart';

import '../../../core/utils/financial_math.dart';
import '../../ingredients/domain/price_history.dart';
import '../../products/domain/product_financials.dart';
import '../../transactions/data/finance_repository.dart';
import '../../transactions/domain/statement_filter.dart';

enum DashboardPeriod { today, week, month, previousMonth, custom }

class DateRange {
  DateRange(DateTime start, DateTime end)
    : start = DateTime(start.year, start.month, start.day),
      end = DateTime(end.year, end.month, end.day) {
    if (this.end.isBefore(this.start)) throw ArgumentError('Período inválido.');
  }
  factory DateRange.period(DashboardPeriod period, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (period) {
      DashboardPeriod.today => DateRange(today, today),
      DashboardPeriod.week => DateRange(
        today.subtract(const Duration(days: 6)),
        today,
      ),
      DashboardPeriod.previousMonth => DateRange(
        DateTime(now.year, now.month - 1),
        DateTime(now.year, now.month, 0),
      ),
      _ => DateRange(DateTime(now.year, now.month), today),
    };
  }
  final DateTime start, end;
  bool contains(DateTime date) => !date.isBefore(start) && !date.isAfter(end);
}

class ChartPoint {
  const ChartPoint(this.date, this.value);
  final DateTime date;
  final Decimal? value;
}

class ValueSeries {
  const ValueSeries(this.label, this.points);
  final String label;
  final List<ChartPoint> points;
}

class CashBucket {
  CashBucket(this.date);
  final DateTime date;
  int income = 0, expenses = 0;
}

class RankedAmount {
  const RankedAmount(this.id, this.label, this.cents);
  final String id, label;
  final int cents;
}

class PriceAlert {
  const PriceAlert({
    required this.ingredientId,
    required this.supplierId,
    required this.variation,
  });
  final String ingredientId, supplierId;
  final Decimal variation;
}

class DashboardReport {
  DashboardReport(FinanceSnapshot snapshot, this.range) {
    final filtered = StatementFilter(
      start: range.start,
      end: range.end,
    ).apply(snapshot.rows('transactions'));
    totals = StatementTotals(filtered);
    final categoryAmounts = <String, int>{};
    final supplierAmounts = <String, int>{};
    final days = range.end.difference(range.start).inDays + 1;
    grouping = days > 90
        ? 'mês'
        : days > 31
        ? 'semana'
        : 'dia';
    DateTime bucketDate(DateTime date) => grouping == 'mês'
        ? DateTime(date.year, date.month)
        : grouping == 'semana'
        ? range.start.add(
            Duration(days: (date.difference(range.start).inDays ~/ 7) * 7),
          )
        : date;
    final grouped = <DateTime, CashBucket>{};
    for (
      var date = range.start;
      !date.isAfter(range.end);
      date = date.add(const Duration(days: 1))
    ) {
      final key = bucketDate(date);
      grouped.putIfAbsent(key, () => CashBucket(key));
    }
    for (final entry in filtered) {
      final amount = FinancialMath.cents(entry['amount']);
      if (entry['status'] == 'pendente') {
        if (entry['type'] == 'saida') pendingPayables += amount;
        continue;
      }
      hasPayments = true;
      final bucket = grouped[bucketDate(DateTime.parse(entry['date']))]!;
      if (entry['type'] == 'entrada') {
        bucket.income += amount;
      } else {
        bucket.expenses += amount;
        final category = entry['category_id'] as String;
        categoryAmounts[category] = (categoryAmounts[category] ?? 0) + amount;
        final supplier = entry['supplier_id'] as String?;
        if (supplier != null)
          supplierAmounts[supplier] = (supplierAmounts[supplier] ?? 0) + amount;
      }
    }
    buckets = grouped.values.toList();
    categories = _ranking(categoryAmounts, snapshot, 'transaction_categories');
    suppliers = _ranking(supplierAmounts, snapshot, 'suppliers');
    supplierSpend = suppliers.fold(0, (sum, supplier) => sum + supplier.cents);
    currentProducts =
        snapshot
            .rows('product_costs')
            .where((row) => row['cost'] != null)
            .toList()
          ..sort(
            (first, second) => ProductFinancials.fromDatabase(first)
                .marginPercent!
                .compareTo(
                  ProductFinancials.fromDatabase(second).marginPercent!,
                ),
          );
    lowMarginProducts = currentProducts
        .where((row) => ProductFinancials.fromDatabase(row).lowMargin)
        .toList();
    missingCosts = snapshot.rows('products').length - currentProducts.length;
    final preferences = CostPreferences.fromSnapshot(snapshot);
    final activeIds = snapshot
        .rows('suppliers')
        .where((row) => row['active'] == true)
        .map((row) => row['id'])
        .toSet();
    final historyGroups = <String, List<DataRow>>{};
    for (final price in snapshot.rows('ingredient_prices')) {
      if (!activeIds.contains(price['supplier_id'])) continue;
      historyGroups
          .putIfAbsent(
            '${price['ingredient_id']}/${price['supplier_id']}',
            () => [],
          )
          .add(price);
    }
    for (final history in historyGroups.values) {
      final ordered = PriceHistory.chronological(
        history.where((row) => !DateTime.parse(row['date']).isAfter(range.end)),
      );
      if (ordered.length < 2 ||
          !range.contains(DateTime.parse(ordered.last['date'])))
        continue;
      final previous = Decimal.parse(
        ordered[ordered.length - 2]['unit_price'].toString(),
      );
      final latest = Decimal.parse(ordered.last['unit_price'].toString());
      if (latest - previous > previous * preferences.priceAlertThreshold) {
        alerts.add(
          PriceAlert(
            ingredientId: ordered.last['ingredient_id'],
            supplierId: ordered.last['supplier_id'],
            variation: roundedDivision(
              (latest - previous) * Decimal.fromInt(100),
              previous,
              2,
            ),
          ),
        );
      }
    }
    alerts.sort((first, second) => second.variation.compareTo(first.variation));
  }
  final DateRange range;
  late StatementTotals totals;
  late List<CashBucket> buckets;
  late List<RankedAmount> categories, suppliers;
  late List<DataRow> currentProducts, lowMarginProducts;
  late String grouping;
  int pendingPayables = 0, supplierSpend = 0, missingCosts = 0;
  bool hasPayments = false;
  final alerts = <PriceAlert>[];
  List<ChartPoint> get balancePoints {
    var accumulated = 0;
    return [
      for (final bucket in buckets)
        ChartPoint(
          bucket.date,
          Decimal.fromInt(accumulated += bucket.income - bucket.expenses) *
              Decimal.parse('0.01'),
        ),
    ];
  }

  static List<RankedAmount> _ranking(
    Map<String, int> amounts,
    FinanceSnapshot snapshot,
    String table,
  ) => [
    for (final entry in amounts.entries)
      RankedAmount(entry.key, snapshot.name(table, entry.key), entry.value),
  ]..sort((first, second) => second.cents.compareTo(first.cents));
}

abstract final class DashboardHistory {
  static List<ChartPoint> observations(
    List<DataRow> history,
    DateRange range, {
    required String dateKey,
    required String valueKey,
  }) {
    final ordered = history.toList()
      ..sort((first, second) {
        final date = first[dateKey].toString().compareTo(
          second[dateKey].toString(),
        );
        if (date != 0) return date;
        if (first['revision'] != null && second['revision'] != null)
          return (first['revision'] as num).compareTo(
            second['revision'] as num,
          );
        return first['created_at'].toString().compareTo(
          second['created_at'].toString(),
        );
      });
    DataRow? baseline;
    final points = <DateTime, Decimal?>{};
    for (final row in ordered) {
      final date = DateTime.parse(row[dateKey]);
      if (date.isBefore(range.start)) {
        baseline = row;
      } else if (!date.isAfter(range.end)) {
        points[date] = decimalOrNull(row[valueKey]);
      }
    }
    if (baseline != null && !points.containsKey(range.start))
      points[range.start] = decimalOrNull(baseline[valueKey]);
    final dates = points.keys.toList()..sort();
    return [for (final date in dates) ChartPoint(date, points[date])];
  }

  static List<ValueSeries> ingredient(
    FinanceSnapshot snapshot,
    String ingredientId,
    DateRange range,
  ) {
    final prices = snapshot
        .rows('ingredient_prices')
        .where((row) => row['ingredient_id'] == ingredientId)
        .toList();
    final ids = prices.map((row) => row['supplier_id'] as String).toSet();
    return [
      for (final id in ids)
        ValueSeries(
          snapshot.name('suppliers', id),
          observations(
            prices.where((row) => row['supplier_id'] == id).toList(),
            range,
            dateKey: 'date',
            valueKey: 'unit_price',
          ),
        ),
    ];
  }

  static List<ChartPoint> product(
    FinanceSnapshot snapshot,
    String productId,
    DateRange range,
  ) => observations(
    snapshot
        .rows('product_cost_history')
        .where((row) => row['product_id'] == productId)
        .toList(),
    range,
    dateKey: 'observed_on',
    valueKey: 'cost',
  );
}
