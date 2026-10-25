import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/features/dashboard/domain/dashboard_report.dart';
import 'package:mocochovisk/features/transactions/domain/statement_filter.dart';

import '../products/finance_fixture.dart';

void main() {
  test('periods include today and handle previous-month year boundaries', () {
    final now = DateTime(2026, 1, 3, 18);
    expect(
      DateRange.period(DashboardPeriod.week, now).start,
      DateTime(2025, 12, 28),
    );
    expect(
      DateRange.period(DashboardPeriod.previousMonth, now).end,
      DateTime(2025, 12, 31),
    );
    expect(
      () => DateRange(DateTime(2026, 2), DateTime(2026, 1)),
      throwsArgumentError,
    );
  });
  test(
    'dashboard separates paid cash, pending payables and supplier spending',
    () {
      final report = DashboardReport(
        fixtureSnapshot(),
        DateRange(DateTime(2026, 10, 1), DateTime(2026, 10, 25)),
      );
      expect(report.totals.income, 84050);
      expect(report.totals.expenses, 17540);
      expect(report.totals.balance, 66510);
      expect(report.pendingPayables, 95000);
      expect(report.supplierSpend, 12040);
      expect(report.categories.map((row) => row.id), ['supplies', 'energy']);
      expect(report.balancePoints.last.value, Decimal.parse('665.10'));
      expect(report.lowMarginProducts.single['id'], 'portion');
      expect(report.missingCosts, 1);
    },
  );
  test(
    'period filters apply to cash and price alerts, margins are current',
    () {
      final report = DashboardReport(
        fixtureSnapshot(),
        DateRange(DateTime(2026, 10, 24), DateTime(2026, 10, 24)),
      );
      expect(report.totals.balance, 84050);
      expect(report.pendingPayables, 0);
      expect(report.alerts, isEmpty);
      expect(report.lowMarginProducts, hasLength(1));
      final latest = DashboardReport(
        fixtureSnapshot(),
        DateRange(DateTime(2026, 10, 25), DateTime(2026, 10, 25)),
      );
      expect(latest.alerts, hasLength(2));
      expect(latest.alerts.first.variation, Decimal.fromInt(40));
    },
  );
  test('inactive suppliers do not generate actionable price alerts', () {
    final snapshot = fixtureSnapshot();
    snapshot.rows('suppliers').first['active'] = false;
    final report = DashboardReport(
      snapshot,
      DateRange(DateTime(2026, 10, 1), DateTime(2026, 10, 25)),
    );
    expect(report.alerts.single.ingredientId, 'lime');
  });
  test('long periods group by week or month without losing payments', () {
    final weekly = DashboardReport(
      fixtureSnapshot(),
      DateRange(DateTime(2026, 9, 1), DateTime(2026, 10, 25)),
    );
    final monthly = DashboardReport(
      fixtureSnapshot(),
      DateRange(DateTime(2026, 1, 1), DateTime(2026, 10, 25)),
    );
    expect(weekly.grouping, 'semana');
    expect(monthly.grouping, 'mês');
    expect(monthly.balancePoints.last.value, weekly.balancePoints.last.value);
  });
  test('history uses a real baseline and preserves gaps for unknown costs', () {
    final history = <DataRow>[
      {'id': '1', 'observed_on': '2026-10-01', 'revision': 1, 'cost': '4'},
      {'id': '2', 'observed_on': '2026-10-20', 'revision': 2, 'cost': '5'},
      {'id': '3', 'observed_on': '2026-10-20', 'revision': 3, 'cost': null},
      {'id': '4', 'observed_on': '2026-10-25', 'revision': 4, 'cost': '6'},
    ];
    final points = DashboardHistory.observations(
      history,
      DateRange(DateTime(2026, 10, 10), DateTime(2026, 10, 24)),
      dateKey: 'observed_on',
      valueKey: 'cost',
    );
    expect(points.map((point) => point.date), [
      DateTime(2026, 10, 10),
      DateTime(2026, 10, 20),
    ]);
    expect(points.first.value, Decimal.fromInt(4));
    expect(points.last.value, isNull);
    expect(
      DashboardHistory.observations(
        history,
        DateRange(DateTime(2026, 9, 1), DateTime(2026, 9, 30)),
        dateKey: 'observed_on',
        valueKey: 'cost',
      ),
      isEmpty,
    );
  });
}
