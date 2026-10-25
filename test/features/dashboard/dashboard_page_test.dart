import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/core/utils/br_formatters.dart';
import 'package:mocochovisk/features/dashboard/presentation/pages/dashboard_page.dart';

import '../products/finance_fixture.dart';
import '../products/product_pages_test.dart' show pumpFinancePage;
import '../transactions/fake_finance_repository.dart';

void main() {
  testWidgets(
    'dashboard shows paid cash and changes period through a native action sheet',
    (tester) async {
      await pumpFinancePage(
        tester,
        DashboardPage(currentDate: DateTime(2026, 10, 25)),
        financeFixture(),
      );
      expect(find.text(BrFormatters.currencyFromCents(66510)), findsOneWidget);
      expect(find.text(BrFormatters.currencyFromCents(95000)), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(PieChart), findsOneWidget);
      await tester.tap(find.text('Este mês'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      await tester.tap(find.text('Hoje'));
      await tester.pumpAndSettle();
      expect(find.text(BrFormatters.currencyFromCents(-17540)), findsOneWidget);
      expect(find.text('Hoje'), findsOneWidget);
    },
  );
  testWidgets(
    'dashboard has clear empty chart states and no invented financial data',
    (tester) async {
      await pumpFinancePage(
        tester,
        DashboardPage(currentDate: DateTime(2026, 10, 25)),
        FakeFinanceRepository(),
      );
      expect(find.byType(BarChart), findsNothing);
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(PieChart), findsNothing);
      expect(find.text('Nenhuma despesa paga no período.'), findsOneWidget);
      expect(
        find.text(
          'Cadastre produtos e fichas técnicas para acompanhar as margens.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets('dashboard fits a narrow dark screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpFinancePage(
      tester,
      DashboardPage(currentDate: DateTime(2026, 10, 25)),
      financeFixture(),
      brightness: Brightness.dark,
    );
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
