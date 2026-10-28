import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/core/widgets/app_interaction.dart';
import 'package:mocochovisk/core/widgets/finance_sheet.dart';
import 'package:mocochovisk/core/widgets/finance_widgets.dart';

Future<void> openEditor(
  WidgetTester tester, {
  Future<void> Function(Map<String, dynamic>)? save,
  bool externalChanges = false,
}) async {
  await tester.pumpWidget(
    CupertinoApp(
      home: Builder(
        builder: (context) => Center(
          child: AppButton(
            onPressed: () => openFinanceSheet<bool>(
              context,
              RecordEditor(
                title: 'Cadastro',
                hasExternalChanges: externalChanges,
                fields: const [EditField('name', 'Nome', required: true)],
                onSave: save ?? (_) async {},
              ),
            ),
            child: const Text('Abrir cadastro'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir cadastro'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'dirty forms disable gesture dismissal and confirm explicit close',
    (tester) async {
      await openEditor(tester);
      final route = ModalRoute.of(
        tester.element(find.byType(RecordEditor)),
      ) as FinanceSheetRoute<bool>;
      expect(route.enableDrag, isTrue);
      await tester.enterText(
        find.byType(CupertinoTextFormFieldRow),
        'Distribuidora',
      );
      await tester.pump();
      expect(route.enableDrag, isFalse);
      await tester.tap(find.bySemanticsLabel('Fechar formulário'));
      await tester.pumpAndSettle();
      expect(find.text('Descartar alterações?'), findsOneWidget);
      await tester.tap(find.text('Continuar editando'));
      await tester.pumpAndSettle();
      expect(find.text('Distribuidora'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      expect(find.byType(RecordEditor), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a changed attachment is protected even with untouched fields', (
    tester,
  ) async {
    await openEditor(tester, externalChanges: true);
    await tester.tap(find.bySemanticsLabel('Fechar formulário'));
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);
  });

  testWidgets(
    'saving cannot be dismissed and successful save closes without discard',
    (tester) async {
      final saved = Completer<void>();
      Map<String, dynamic>? payload;
      await openEditor(
        tester,
        save: (value) {
          payload = value;
          return saved.future;
        },
      );
      await tester.enterText(
        find.byType(CupertinoTextFormFieldRow),
        'Fornecedor',
      );
      await tester.tap(find.text('Salvar').first);
      await tester.pump();
      final route = ModalRoute.of(
        tester.element(find.byType(RecordEditor)),
      ) as FinanceSheetRoute<bool>;
      expect(route.enableDrag, isFalse);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      saved.complete();
      await tester.pumpAndSettle();
      expect(payload?['name'], 'Fornecedor');
      expect(find.byType(RecordEditor), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
