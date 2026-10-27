import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/core/utils/br_formatters.dart';
import 'package:mocochovisk/core/widgets/app_motion.dart';
import 'package:mocochovisk/core/widgets/finance_widgets.dart';
import 'package:mocochovisk/features/products/presentation/pages/products_page.dart';
import 'package:mocochovisk/features/products/presentation/widgets/product_record_tile.dart';
import 'package:mocochovisk/features/statement/presentation/pages/statement_page.dart';
import 'package:mocochovisk/features/suppliers/presentation/pages/suppliers_page.dart';

import '../features/products/finance_fixture.dart';
import '../features/products/product_pages_test.dart' show pumpFinancePage;

void main() {
  testWidgets('financial editor stays readable on a wide viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpFinancePage(
      tester,
      RecordEditor(
        title: 'Cadastro',
        fields: const [EditField('name', 'Nome', required: true)],
        onSave: (_) async {},
      ),
      financeFixture(),
    );
    expect(tester.getSize(find.byType(Form)).width, lessThanOrEqualTo(640));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'money honors reduced motion and exposes the exact current amount',
    (tester) async {
      final amount = ValueNotifier(10000);
      addTearDown(amount.dispose);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        CupertinoApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: ValueListenableBuilder(
              valueListenable: amount,
              builder: (context, value, child) => AnimatedMoney(cents: value),
            ),
          ),
        ),
      );
      amount.value = 987654321;
      await tester.pump();
      expect(
        find.text(BrFormatters.currencyFromCents(amount.value)),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(BrFormatters.currencyFromCents(amount.value)),
        findsOneWidget,
      );
      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('native filter sheet applies and removes a transaction filter', (
    tester,
  ) async {
    await pumpFinancePage(tester, const StatementPage(), financeFixture());
    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPopupSurface), findsWidgets);
    await tester.tap(find.text('Tipo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrada'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Tipo: Entrada'), findsOneWidget);
    expect(find.text('2 lançamentos · ordem cronológica'), findsOneWidget);
    await tester.tap(find.text('Tipo: Entrada'));
    await tester.pumpAndSettle();
    expect(find.text('5 lançamentos · ordem cronológica'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large product catalogs build only nearby rows', (tester) async {
    final repository = financeFixture();
    repository.data['products'] = List.generate(
      1000,
      (index) => {
        'id': 'product-$index',
        'name': 'Produto $index',
        'category': 'Outros',
        'sale_price': '10.00',
      },
    );
    repository.data['product_costs'] = [];
    await pumpFinancePage(tester, const ProductsPage(), repository);
    expect(find.byType(ProductRecordTile).evaluate().length, lessThan(30));
    expect(find.byType(ProductRecordTile), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supplier history shows all recorded quotes and purchases', (
    tester,
  ) async {
    await pumpFinancePage(
      tester,
      const SupplierPriceHistoryPage(id: 'central'),
      financeFixture(),
    );
    expect(find.text('Histórico do fornecedor'), findsWidgets);
    expect(find.text(BrFormatters.currencyFromCents(5000)), findsOneWidget);
    expect(find.text(BrFormatters.currencyFromCents(7000)), findsOneWidget);
    expect(find.textContaining('Compra'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
