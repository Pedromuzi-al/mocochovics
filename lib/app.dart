import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

const appLocalizationsDelegates = [
  GlobalCupertinoLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

class MocochoviskApp extends ConsumerWidget {
  const MocochoviskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MediaQuery.fromView(
    view: View.of(context),
    child: Builder(
      builder: (context) => CupertinoApp.router(
        title: 'Bar do Mocochovisk',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: appLocalizationsDelegates,
        theme: AppTheme.build(MediaQuery.platformBrightnessOf(context)),
        routerConfig: ref.watch(appRouterProvider),
      ),
    ),
  );
}
