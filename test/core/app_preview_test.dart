import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/app.dart';
import 'package:mocochovisk/features/auth/domain/auth_repository.dart';
import 'package:mocochovisk/features/auth/presentation/controllers/auth_controller.dart';

import '../features/auth/fake_auth_repository.dart';

void main() {
  testWidgets('capture app previews for visual review', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    final icons = FontLoader('packages/cupertino_icons/CupertinoIcons')
      ..addFont(
        rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
      );
    await font.load();
    await icons.load();

    final repository = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await repository.dispose();
    });

    final previewKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: previewKey,
        child: UncontrolledProviderScope(
          container: container,
          child: const MocochoviskApp(),
        ),
      ),
    );

    Future<void> capture(String fileName) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          previewKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/previews').create(recursive: true);
        await File('build/previews/$fileName.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await capture('login-light');
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await capture('login-dark');
    repository.emit(
      const AuthSession(email: 'dono@bar.example', isAuthenticated: true),
    );
    await capture('home-dark');
  }, skip: !const bool.fromEnvironment('CAPTURE_PREVIEWS'));
}
