import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/core/supabase/app_bootstrap.dart';
import 'package:mocochovisk/core/supabase/app_config.dart';

void main() {
  testWidgets(
    'missing credentials show setup without starting authentication',
    (tester) async {
      await tester.pumpWidget(
        const AppBootstrap(
          config: AppConfig(supabaseUrl: '', supabaseKey: ''),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configure sua conexão'), findsOneWidget);
      expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
      expect(find.byType(CupertinoTextFormFieldRow), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('setup follows changes to system brightness', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      const AppBootstrap(
        config: AppConfig(supabaseUrl: '', supabaseKey: ''),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = find.byType(CupertinoPageScaffold);
    expect(
      CupertinoTheme.of(tester.element(scaffold)).brightness,
      Brightness.dark,
    );

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(
      CupertinoTheme.of(tester.element(scaffold)).brightness,
      Brightness.light,
    );
  });
}
