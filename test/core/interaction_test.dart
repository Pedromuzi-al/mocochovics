import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/core/widgets/app_interaction.dart';
import 'package:mocochovisk/core/widgets/premium_finance.dart';

void main() {
  testWidgets('list actions accept keyboard activation once', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: AppListTile(
            title: const Text('Abrir detalhe'),
            onTap: () async => calls++,
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.tap(find.text('Abrir detalhe'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets(
    'hover feedback preserves a single touch and keyboard activation',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: AppButton(
              onPressed: () => calls++,
              child: const Text('Ação'),
            ),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('Ação')));
      await tester.pumpAndSettle();
      final decoration =
          tester
                  .widget<AnimatedContainer>(
                    find
                        .descendant(
                          of: find.byType(AppHover),
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .foregroundDecoration
              as BoxDecoration;
      expect(decoration.color!.a, greaterThan(0));
      expect(calls, 0);
      await tester.tap(find.text('Ação'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(calls, 2);
      await mouse.removePointer();
    },
  );

  testWidgets('disabled buttons remain disabled with the pointer over them', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: AppButton(onPressed: null, child: Text('Indisponível')),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Indisponível')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CupertinoButton>(find.byType(CupertinoButton)).enabled,
      isFalse,
    );
    final decoration =
        tester
                .widget<AnimatedContainer>(
                  find
                      .descendant(
                        of: find.byType(AppHover),
                        matching: find.byType(AnimatedContainer),
                      )
                      .first,
                )
                .foregroundDecoration
            as BoxDecoration;
    expect(decoration.color!.a, 0);
    await mouse.removePointer();
  });

  testWidgets(
    'card hover lifts without moving layout and respects reduced motion',
    (tester) async {
      final reduced = ValueNotifier(false);
      addTearDown(reduced.dispose);
      await tester.pumpWidget(
        CupertinoApp(
          home: ValueListenableBuilder(
            valueListenable: reduced,
            builder: (context, value, child) => MediaQuery(
              data: MediaQueryData(disableAnimations: value),
              child: const Center(
                child: SizedBox(
                  width: 250,
                  child: PremiumSurface(child: Text('Resumo')),
                ),
              ),
            ),
          ),
        ),
      );
      final original = tester.getSize(find.byType(PremiumSurface));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('Resumo')));
      await tester.pumpAndSettle();
      Finder transform() => find
          .descendant(
            of: find.byType(AppHover),
            matching: find.byType(Transform),
          )
          .first;
      expect(tester.widget<Transform>(transform()).transform.storage[13], -2);
      expect(tester.getSize(find.byType(PremiumSurface)), original);
      reduced.value = true;
      await tester.pumpAndSettle();
      expect(tester.widget<Transform>(transform()).transform.storage[13], 0);
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
    },
  );
}
