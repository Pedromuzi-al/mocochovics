import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:mocochovisk/core/widgets/premium_finance.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/app.dart';
import 'package:mocochovisk/core/router/app_router.dart';
import 'package:mocochovisk/features/auth/domain/auth_repository.dart';
import 'package:mocochovisk/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mocochovisk/features/transactions/data/finance_repository.dart';

import 'features/auth/fake_auth_repository.dart';
import 'features/products/finance_fixture.dart';
import 'features/transactions/fake_finance_repository.dart';

/// Diagnostic captures of the real app widgets; no production data or writes.
/// Run explicitly with --dart-define=VISUAL_AUDIT=true.
class _LoadingRepository extends FakeFinanceRepository {
  final _ready = Completer<void>();
  @override
  Future<void> prepare() => _ready.future;
}

void main() {
  const enabled = bool.fromEnvironment('VISUAL_AUDIT');
  final sizes = {
    'mobile': (size: const Size(390, 844), scale: 1.0),
    'tablet': (size: const Size(834, 1112), scale: 1.0),
    'desktop': (size: const Size(1440, 1000), scale: 1.0),
    'large-text': (size: const Size(320, 740), scale: 2.0),
    'desktop-large-text': (size: const Size(1440, 1000), scale: 2.0),
  };
  const tabs = {
    'dashboard': '/inicio',
    'statement': '/extrato',
    'products': '/produtos',
    'suppliers': '/fornecedores',
    'settings': '/mais',
  };

  for (final viewport in sizes.entries) {
    for (final brightness in Brightness.values) {
      final name = '${viewport.key}-${brightness.name}';
      testWidgets('visual audit $name', (tester) async {
        tester.view.physicalSize = viewport.value.size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue =
            viewport.value.scale;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        await (FontLoader(
          'Inter',
        )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
        await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
              rootBundle.load(
                'packages/cupertino_icons/assets/CupertinoIcons.ttf',
              ),
            ))
            .load();

        ProviderContainer? container;
        FakeAuthRepository? auth;
        final boundaryKey = GlobalKey();
        final issues = <String>[];
        final captures = <String>[];
        final folder = Directory('build/visual-audit/$name');
        await tester.runAsync(() => folder.create(recursive: true));

        Future<void> unmount() async {
          await tester.pumpWidget(const SizedBox.shrink());
          container?.dispose();
          await auth?.dispose();
        }

        addTearDown(unmount);

        void collectIssues(String screen) {
          final error = tester.takeException();
          if (error != null) issues.add('$screen: $error');
        }

        Future<void> mount(
          FakeFinanceRepository repository, {
          bool loading = false,
        }) async {
          await unmount();
          auth = FakeAuthRepository(
            session: const AuthSession(
              email: 'auditoria@bar.example',
              isAuthenticated: true,
            ),
          );
          container = ProviderContainer(
            overrides: [
              authRepositoryProvider.overrideWithValue(auth!),
              financeRepositoryProvider.overrideWithValue(repository),
            ],
          );
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundaryKey,
              child: UncontrolledProviderScope(
                container: container!,
                child: const MocochoviskApp(),
              ),
            ),
          );
          if (loading) {
            await tester.pump(const Duration(milliseconds: 300));
          } else {
            await tester.pumpAndSettle();
          }
          collectIssues('mount');
        }

        Future<void> capture(String screen, {bool settle = true}) async {
          if (settle) await tester.pumpAndSettle();
          collectIssues(screen);
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File('${folder.path}/$screen.png')
                .writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
          captures.add(screen);
        }

        Future<void> route(String path) async {
          container!.read(appRouterProvider).go(path);
          await tester.pumpAndSettle();
          collectIssues(path);
        }

        Future<void> tapText(String text) async {
          await tester.ensureVisible(find.text(text).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text(text).first);
          await tester.pumpAndSettle();
          collectIssues('tap $text');
        }

        final repository = financeFixture();
        repository.data['suppliers']!.first.addAll({
          'phone': '(11) 99999-0000',
          'email': 'contato@fornecedor.example',
          'address': 'Rua do Comércio, 120',
          'payment_term_days': 30,
          'notes': 'Entregas pela manhã.',
        });
        repository.data['suppliers']!.last['active'] = false;
        await mount(repository);
        for (final tab in tabs.entries) {
          await route(tab.value);
          await capture(tab.key);
        }
        await route('/mais');
        await tester.scrollUntilVisible(
          find.text('Aparência'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await capture('settings-appearance');

        await route('/inicio');
        if (viewport.value.size.width < 1000) {
          await tester.tap(find.bySemanticsLabel('Abrir menu'));
          await capture('navigation-menu');
          await tester.tap(find.bySemanticsLabel('Fechar menu').last);
          await tester.pumpAndSettle();
        } else {
          await tester.tap(find.bySemanticsLabel('Recolher menu'));
          await capture('navigation-collapsed');
          await tester.tap(find.bySemanticsLabel('Expandir menu'));
          await tester.pumpAndSettle();
          if (viewport.key == 'desktop') {
            final mouse = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
            );
            await mouse.addPointer(location: Offset.zero);
            await mouse.moveTo(
              tester.getCenter(find.byType(FinanceMetricCard).first),
            );
            await capture('dashboard-hover');
            await mouse.removePointer();
            await tester.pumpAndSettle();
          }
        }

        if (viewport.key == 'large-text' ||
            viewport.key == 'desktop-large-text') {
          for (final tab in ['statement', 'products', 'suppliers']) {
            await route(tabs[tab]!);
            await tester.drag(
              find.byType(Scrollable).last,
              const Offset(0, -500),
            );
            await capture('$tab-lower');
          }
          await mount(_LoadingRepository(), loading: true);
          await capture('dashboard-loading', settle: false);
        }

        if (viewport.key == 'mobile' || viewport.key == 'desktop') {
          await route('/inicio');
          for (var index = 1; index <= 3; index++) {
            await tester.drag(
              find.byType(Scrollable).last,
              const Offset(0, -700),
            );
            await capture('dashboard-charts-$index');
          }
          for (final page in {
            'ingredients': '/mais/ingredientes',
            'categories': '/mais/categorias',
            'recurring': '/mais/recorrencias',
            'cost-settings': '/mais/configuracoes',
            'about': '/mais/sobre',
          }.entries) {
            await route(page.value);
            await capture(page.key);
          }
          await route('/extrato');
          await tapText('Filtros');
          await capture('statement-filters');
          container!.read(appRouterProvider).pop();
          await tester.pumpAndSettle();
          await tapText('Novo lançamento');
          await capture('transaction-form');
          await tester.drag(
            find.byType(Scrollable).last,
            const Offset(0, -800),
          );
          await capture('transaction-form-lower');
          container!.read(appRouterProvider).pop();
          await route('/produtos');
          await tapText('Caipirinha');
          await capture('product-detail');
          await tester.drag(
            find.byType(Scrollable).last,
            const Offset(0, -700),
          );
          await capture('product-detail-lower');
          container!.read(appRouterProvider).pop();
          await route('/fornecedores');
          await tapText('Distribuidora Central');
          await capture('supplier-detail');
          await tester.drag(
            find.byType(Scrollable).last,
            const Offset(0, -650),
          );
          await capture('supplier-detail-lower');
          container!.read(appRouterProvider).pop();
          await route('/mais/ingredientes');
          await tapText('Limão');
          await capture('ingredient-detail');
          container!.read(appRouterProvider).pop();
          await route('/mais/configuracoes');
          await tapText('Editar configurações');
          await capture('cost-settings-form');
          container!.read(appRouterProvider).pop();
          await route('/mais/recorrencias');
          await tapText('Nova recorrência');
          await capture('recurring-form');
          container!.read(appRouterProvider).pop();
          await route('/fornecedores');
          await tester.tap(find.bySemanticsLabel('Novo fornecedor'));
          await capture('supplier-form');
          container!.read(appRouterProvider).pop();
          await route('/produtos');
          await tester.tap(find.bySemanticsLabel('Novo produto'));
          await capture('product-form');

          await mount(FakeFinanceRepository());
          for (final tab in {
            ...tabs,
            'ingredients': '/mais/ingredientes',
          }.entries) {
            await route(tab.value);
            await capture('${tab.key}-empty');
          }
          await mount(
            FakeFinanceRepository()
              ..failure = const FormatException('Sem conexão.'),
          );
          await route('/extrato');
          await capture('statement-error');
          await mount(_LoadingRepository(), loading: true);
          await capture('dashboard-loading', settle: false);
        }
        await tester.runAsync(
          () => File('${folder.path}/report.json').writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'viewport': {
                'width': viewport.value.size.width,
                'height': viewport.value.size.height,
                'textScale': viewport.value.scale,
              },
              'brightness': brightness.name,
              'captures': captures,
              'issues': issues,
              'dataSource':
                  'Test fixtures only; no remote authentication or writes.',
            }),
          ),
        );
        expect(
          issues,
          isEmpty,
          reason:
              'See ${folder.path}/report.json for the visual audit findings.',
        );
      }, skip: !enabled);
    }
  }
}
