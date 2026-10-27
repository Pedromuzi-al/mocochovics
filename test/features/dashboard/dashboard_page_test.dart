import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/core/utils/br_formatters.dart';
import 'package:mocochovisk/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:mocochovisk/features/statement/presentation/pages/statement_page.dart';
import 'package:mocochovisk/features/products/presentation/pages/products_page.dart';

import '../products/finance_fixture.dart';
import '../products/product_pages_test.dart' show pumpFinancePage;
import '../transactions/fake_finance_repository.dart';

void main() {
  for (final scenario in [
    (
      label: 'Ver entradas ›',
      included: 'Vendas do dia',
      excluded: ['Aluguel', 'Compra', 'Venda a receber'],
      amount: 84050,
    ),
    (
      label: 'Ver saídas ›',
      included: 'Energia',
      excluded: ['Aluguel', 'Vendas do dia', 'Venda a receber'],
      amount: 17540,
    ),
    (
      label: 'Ver contas ›',
      included: 'Aluguel',
      excluded: ['Compra', 'Vendas do dia', 'Venda a receber'],
      amount: 95000,
    ),
    (
      label: 'Ver gastos ›',
      included: 'Compra',
      excluded: ['Energia', 'Aluguel', 'Vendas do dia'],
      amount: 12040,
    ),
  ]) {
    testWidgets(
      'dashboard ${scenario.label} opens only matching transactions in the selected period',
      (tester) async {
        final repository = financeFixture();
        repository.data['transactions']!.add({
          ...repository.data['transactions']!.first,
          'id': 'old',
          'date': '2026-09-01',
          'description': 'Venda antiga',
        });
        await pumpFinancePage(
          tester,
          DashboardPage(currentDate: DateTime(2026, 10, 25)),
          repository,
        );
        await tester.ensureVisible(find.text(scenario.label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(scenario.label));
        await tester.pumpAndSettle();
        expect(find.byType(StatementPage), findsOneWidget);
        expect(find.text('01/10/2026 — 25/10/2026'), findsOneWidget);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(find.textContaining(scenario.included), findsWidgets);
        for (final description in [...scenario.excluded, 'Venda antiga']) {
          expect(find.textContaining(description), findsNothing);
        }
        expect(
          find.text(BrFormatters.currencyFromCents(scenario.amount)),
          findsWidgets,
        );
      },
    );
  }

  testWidgets('dashboard opens the missing-cost product list directly', (
    tester,
  ) async {
    await pumpFinancePage(
      tester,
      DashboardPage(currentDate: DateTime(2026, 10, 25)),
      financeFixture(),
    );
    await tester.ensureVisible(find.text('Completar fichas sem custo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completar fichas sem custo'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductsPage), findsOneWidget);
    expect(find.text('Novo lanche'), findsOneWidget);
    expect(find.text('Caipirinha'), findsNothing);
  });

  testWidgets('full statement keeps pending entries and the dashboard period', (
    tester,
  ) async {
    final repository = financeFixture();
    repository.data['transactions']!.add({
      ...repository.data['transactions']!.first,
      'id': 'old',
      'date': '2026-09-01',
      'description': 'Venda antiga',
    });
    await pumpFinancePage(
      tester,
      DashboardPage(currentDate: DateTime(2026, 10, 25)),
      repository,
    );
    await tester.ensureVisible(find.text('Ver extrato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver extrato'));
    await tester.pumpAndSettle();
    expect(find.text('01/10/2026 — 25/10/2026'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.textContaining('Venda a receber'), findsOneWidget);
    expect(find.text('Aluguel'), findsOneWidget);
    expect(find.textContaining('Venda antiga'), findsNothing);
  });

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
      expect(find.byType(BarChart), findsNWidgets(2));
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
