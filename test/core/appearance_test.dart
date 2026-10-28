import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/core/theme/appearance_controller.dart';
import 'package:mocochovisk/core/widgets/liquid_glass.dart';

class MemoryAppearanceStore extends AppearanceStore {
  String? value;
  final Completer<String?>? delayed;
  MemoryAppearanceStore({this.value, this.delayed});
  @override
  Future<String?> read() async => delayed == null ? value : delayed!.future;
  @override
  Future<void> write(String value) async => this.value = value;
}

void main() {
  test(
    'appearance and accessibility preferences survive a new container',
    () async {
      final store = MemoryAppearanceStore();
      final first = ProviderContainer(
        overrides: [appearanceStoreProvider.overrideWithValue(store)],
      );
      await first
          .read(appearanceProvider.notifier)
          .update(
            appearance: AppAppearance.dark,
            reduceMotion: true,
            reduceTransparency: true,
          );
      first.dispose();
      final next = ProviderContainer(
        overrides: [appearanceStoreProvider.overrideWithValue(store)],
      );
      addTearDown(next.dispose);
      next.read(appearanceProvider);
      await Future<void>.delayed(Duration.zero);
      final preferences = next.read(appearanceProvider);
      expect(preferences.appearance, AppAppearance.dark);
      expect(preferences.reduceMotion, isTrue);
      expect(preferences.reduceTransparency, isTrue);
      expect(preferences.brightness(Brightness.light), Brightness.dark);
      await next
          .read(appearanceProvider.notifier)
          .update(appearance: AppAppearance.system);
      expect(
        next.read(appearanceProvider).brightness(Brightness.light),
        Brightness.light,
      );
    },
  );

  test('a delayed restore cannot overwrite a user selection', () async {
    final ready = Completer<String?>();
    final store = MemoryAppearanceStore(delayed: ready);
    final container = ProviderContainer(
      overrides: [appearanceStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await container
        .read(appearanceProvider.notifier)
        .update(appearance: AppAppearance.light);
    ready.complete('{"appearance":"dark"}');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(appearanceProvider).appearance, AppAppearance.light);
  });

  testWidgets('reduced transparency removes blur from navigation material', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appearanceStoreProvider.overrideWithValue(MemoryAppearanceStore()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CupertinoApp(
          home: Center(child: LiquidGlass(child: Text('Navegação'))),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
    await container
        .read(appearanceProvider.notifier)
        .update(reduceTransparency: true);
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('Navegação'), findsOneWidget);
  });
}
