import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/core/widgets/finance_widgets.dart';
import 'package:mocochovisk/app.dart';
import 'package:mocochovisk/features/suppliers/presentation/pages/suppliers_page.dart';
import 'package:mocochovisk/features/statement/presentation/pages/statement_page.dart';
import 'package:mocochovisk/features/transactions/data/finance_repository.dart';
import 'package:mocochovisk/features/transactions/presentation/pages/transaction_editor.dart';

import 'fake_finance_repository.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    FakeFinanceRepository repository,
    Widget page,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [financeRepositoryProvider.overrideWithValue(repository)],
        child: CupertinoApp(
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: appLocalizationsDelegates,
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('suppliers load real repository data, search and retry errors', (
    tester,
  ) async {
    final repository = FakeFinanceRepository();
    repository.data['suppliers'] = [
      {'id': 'one', 'name': 'Distribuidora Central', 'active': true},
      {'id': 'two', 'name': 'Horta', 'active': false},
    ];
    await pump(tester, repository, const SuppliersPage());
    expect(find.text('Distribuidora Central'), findsOneWidget);
    await tester.enterText(find.byType(CupertinoSearchTextField), 'horta');
    await tester.pumpAndSettle();
    expect(find.text('Distribuidora Central'), findsNothing);
    expect(find.text('Horta'), findsOneWidget);
  });
  testWidgets(
    'editor keeps entered data after failed save and supports retry',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        CupertinoApp(
          home: RecordEditor(
            title: 'Fornecedor',
            fields: const [EditField('name', 'Nome', required: true)],
            onSave: (values) async {
              calls++;
              if (calls == 1) throw const FormatException('Falha temporária.');
            },
          ),
        ),
      );
      await tester.enterText(
        find.byType(CupertinoTextFormFieldRow),
        'Distribuidora',
      );
      await tester.tap(find.text('Salvar').first);
      await tester.pumpAndSettle();
      expect(find.text('Falha temporária.'), findsOneWidget);
      expect(find.text('Distribuidora'), findsOneWidget);
      expect(calls, 1);
    },
  );
  testWidgets('statement distinguishes paid balance from pending totals', (
    tester,
  ) async {
    final repository = FakeFinanceRepository();
    repository.data['transactions'] = [
      {
        'id': 'one',
        'date': '2026-10-01',
        'created_at': '1',
        'type': 'entrada',
        'amount': '100.00',
        'status': 'pago',
        'description': 'Venda',
        'category_id': 'sales',
      },
      {
        'id': 'two',
        'date': '2026-10-01',
        'created_at': '2',
        'type': 'saida',
        'amount': '30.00',
        'status': 'pendente',
        'description': 'Aluguel',
        'category_id': 'rent',
      },
    ];
    await pump(tester, repository, const StatementPage());
    expect(find.text('Saldo do filtro'), findsOneWidget);
    expect(find.text('R\$\u00a0100,00'), findsNWidgets(2));
    expect(find.text('R\$\u00a030,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('existing unlinked quotes do not hide the purchase shortcut', (
    tester,
  ) async {
    final repository = FakeFinanceRepository();
    final snapshot = FinanceSnapshot({
      'ingredient_prices': [
        {'id': 'quote', 'transaction_id': null},
      ],
    });
    await pump(tester, repository, TransactionEditor(snapshot: snapshot));
    await tester.scrollUntilVisible(
      find.text('Registrar compra de ingrediente'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Registrar compra de ingrediente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('populated suppliers fit narrow screens with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = FakeFinanceRepository();
    repository.data['suppliers'] = [
      {
        'id': 'supplier',
        'name': 'Distribuidora de bebidas Central',
        'active': true,
      },
    ];
    await pump(tester, repository, const SuppliersPage());
    expect(tester.takeException(), isNull);
  });
  testWidgets('repository failures have a working retry action', (
    tester,
  ) async {
    final repository = FakeFinanceRepository()
      ..failure = const FormatException('Sem conexão.');
    await pump(tester, repository, const SuppliersPage());
    expect(find.text('Sem conexão.'), findsOneWidget);
    repository.failure = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum registro encontrado.'), findsOneWidget);
  });
}
