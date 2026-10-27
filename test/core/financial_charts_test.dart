import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/app.dart';
import 'package:mocochovisk/core/utils/br_formatters.dart';
import 'package:mocochovisk/core/widgets/financial_charts.dart';
import 'package:mocochovisk/features/dashboard/domain/dashboard_report.dart';

void main() {
  testWidgets(
    'chart values preserve six decimals and unknown observations in the accessible list',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: appLocalizationsDelegates,
          home: CupertinoPageScaffold(
            child: SafeArea(
              child: ListView(
                children: [
                  FinancialLineChart(
                    unit: 'g',
                    series: [
                      ValueSeries('Limão', [
                        ChartPoint(
                          DateTime(2026, 10, 20),
                          Decimal.parse('0.000001'),
                        ),
                        ChartPoint(DateTime(2026, 10, 21), null),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver valores'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver valores'));
      await tester.pumpAndSettle();
      expect(find.text('Valores do gráfico'), findsOneWidget);
      expect(find.text('Limão · 20/10/2026'), findsOneWidget);
      expect(find.text('R\$ 0,000001/g'), findsOneWidget);
      expect(find.text('Indisponível'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selected expense category survives reordering and clears when removed',
    (tester) async {
      final categories = ValueNotifier(const [
        RankedAmount('supplies', 'Ingredientes', 8000),
        RankedAmount('rent', 'Aluguel', 2000),
      ]);
      addTearDown(categories.dispose);
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SafeArea(
              child: ValueListenableBuilder(
                valueListenable: categories,
                builder: (context, value, child) =>
                    ListView(children: [ExpensesDonut(categories: value)]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Aluguel ·'));
      await tester.pumpAndSettle();
      final selectedLabel =
          'Selecionado: Aluguel · ${BrFormatters.currencyFromCents(2000)}';
      expect(find.text(selectedLabel), findsOneWidget);
      categories.value = categories.value.reversed.toList();
      await tester.pumpAndSettle();
      expect(find.text(selectedLabel), findsOneWidget);
      categories.value = [categories.value.last];
      await tester.pumpAndSettle();
      expect(find.textContaining('Selecionado:'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
