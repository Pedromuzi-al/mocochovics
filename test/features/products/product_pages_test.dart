import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/app.dart';
import 'package:mocochovisk/core/theme/app_theme.dart';
import 'package:mocochovisk/features/products/presentation/pages/products_page.dart';
import 'package:mocochovisk/features/products/presentation/pages/product_detail_page.dart';
import 'package:mocochovisk/features/settings/presentation/pages/cost_settings_page.dart';
import 'package:mocochovisk/features/transactions/data/finance_repository.dart';

import '../transactions/fake_finance_repository.dart';
import 'finance_fixture.dart';

Future<void> pumpFinancePage(
  WidgetTester tester,
  Widget page,
  FakeFinanceRepository repository, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [financeRepositoryProvider.overrideWithValue(repository)],
      child: CupertinoApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: appLocalizationsDelegates,
        theme: AppTheme.build(brightness),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'products show costs and estimated margins, then filter low margins',
    (tester) async {
      await pumpFinancePage(tester, const ProductsPage(), financeFixture());
      expect(find.text('Caipirinha'), findsOneWidget);
      expect(find.textContaining('87,50%'), findsOneWidget);
      await tester.tap(find.text('Margem baixa'));
      await tester.pumpAndSettle();
      expect(find.text('Caipirinha'), findsNothing);
      expect(find.text('Porção de carne'), findsOneWidget);
      expect(find.text('Novo lanche'), findsNothing);
    },
  );
  testWidgets('creating a product persists its Brazilian currency value', (
    tester,
  ) async {
    final repository = financeFixture();
    await pumpFinancePage(tester, const ProductsPage(), repository);
    await tester.tap(find.byIcon(CupertinoIcons.add));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(CupertinoTextFormFieldRow).at(0),
      'Porção de fritas',
    );
    await tester.enterText(
      find.byType(CupertinoTextFormFieldRow).at(1),
      'Porções',
    );
    await tester.enterText(
      find.byType(CupertinoTextFormFieldRow).at(2),
      '2590',
    );
    await tester.tap(find.text('Salvar').first);
    await tester.pumpAndSettle();
    expect(repository.data['products']!.last['sale_price'], '25.90');
    expect(find.text('Porção de fritas'), findsOneWidget);
  });
  testWidgets(
    'recipe ingredient quantities and percentages are stored in base units and fractions',
    (tester) async {
      final repository = financeFixture();
      await pumpFinancePage(
        tester,
        const ProductDetailPage(id: 'empty'),
        repository,
      );
      final add = find.bySemanticsLabel('Adicionar ingrediente à receita');
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ingrediente e unidade base'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limão (g)'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(CupertinoTextFormFieldRow).at(0),
        '100',
      );
      await tester.enterText(
        find.byType(CupertinoTextFormFieldRow).at(1),
        '10',
      );
      await tester.tap(find.text('Salvar').first);
      await tester.pumpAndSettle();
      final item = repository.data['product_recipe_items']!.last;
      expect(item['product_id'], 'empty');
      expect(item['ingredient_id'], 'lime');
      expect(item['quantity'], '100.000000');
      expect(item['loss'], '0.1');
    },
  );
  testWidgets(
    'settings convert percentage input and preserve zero alert thresholds',
    (tester) async {
      final repository = financeFixture();
      await pumpFinancePage(tester, const CostSettingsPage(), repository);
      await tester.ensureVisible(find.text('Editar configurações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar configurações'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(CupertinoTextFormFieldRow).at(1),
        '30,5',
      );
      await tester.enterText(find.byType(CupertinoTextFormFieldRow).at(2), '0');
      await tester.tap(find.text('Salvar').first);
      await tester.pumpAndSettle();
      final settings = repository.data['app_settings']!.single;
      expect(settings['target_margin'], '0.305');
      expect(settings['price_alert_threshold'], '0');
      expect(settings.containsKey('margin_percent'), isFalse);
    },
  );
  testWidgets('settings reject margins of 100 percent without persisting', (
    tester,
  ) async {
    final repository = financeFixture();
    await pumpFinancePage(tester, const CostSettingsPage(), repository);
    await tester.ensureVisible(find.text('Editar configurações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar configurações'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoTextFormFieldRow).at(1), '100');
    await tester.tap(find.text('Salvar').first);
    await tester.pumpAndSettle();
    expect(find.text('A margem deve ser menor que 100%.'), findsOneWidget);
    expect(repository.data['app_settings']!.single['target_margin'], '0.30');
  });
  testWidgets('product detail distinguishes unknown cost from a free recipe', (
    tester,
  ) async {
    await pumpFinancePage(
      tester,
      const ProductDetailPage(id: 'empty'),
      financeFixture(),
    );
    expect(find.text('Indisponível'), findsOneWidget);
    expect(
      find.textContaining(
        'Ingredientes sem custo não são tratados como gratuitos.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('product detail fits narrow screens with enlarged fonts', (
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
      const ProductDetailPage(id: 'drink'),
      financeFixture(),
      brightness: Brightness.dark,
    );
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1100));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
