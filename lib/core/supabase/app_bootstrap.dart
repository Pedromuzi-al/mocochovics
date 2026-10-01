import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app.dart';
import '../theme/app_theme.dart';
import 'app_config.dart';
import 'supabase_providers.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({required this.config, super.key});
  final AppConfig config;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    if (widget.config.validationErrors.isNotEmpty) return;
    try {
      await Supabase.initialize(
        url: widget.config.supabaseUrl,
        publishableKey: widget.config.supabaseKey,
        debug: false,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
    } catch (_) {
      // A inicialização pode falhar depois de criar o singleton (ex.: storage).
      // Liberá-lo permite uma nova tentativa completa.
      try {
        await Supabase.instance.dispose();
      } catch (_) {
        /* Ainda não inicializado. */
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final errors = widget.config.validationErrors;
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (errors.isEmpty &&
            snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return ProviderScope(
            overrides: [appConfigProvider.overrideWithValue(widget.config)],
            child: const MocochoviskApp(),
          );
        }
        return MediaQuery.fromView(
          view: View.of(context),
          child: Builder(
            builder: (context) => CupertinoApp(
              title: 'Bar do Mocochovisk',
              debugShowCheckedModeBanner: false,
              locale: const Locale('pt', 'BR'),
              supportedLocales: const [Locale('pt', 'BR')],
              localizationsDelegates: appLocalizationsDelegates,
              theme: AppTheme.build(MediaQuery.platformBrightnessOf(context)),
              home: CupertinoPageScaffold(
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              CupertinoIcons.building_2_fill,
                              size: 52,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Bar do Mocochovisk',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (errors.isNotEmpty) ...[
                              const Text(
                                'Configure sua conexão',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Copie config/supabase.example.json para config/supabase.json '
                                'e preencha os dados do seu projeto.',
                              ),
                              const SizedBox(height: 16),
                              ...errors.map(
                                (error) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(error),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'flutter run --dart-define-from-file=config/supabase.json',
                              ),
                            ] else if (snapshot.hasError) ...[
                              const Text(
                                'Não foi possível iniciar o aplicativo. Verifique sua conexão e tente novamente.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              CupertinoButton.filled(
                                onPressed: () => setState(
                                  () => _initialization = _initialize(),
                                ),
                                child: const Text('Tentar novamente'),
                              ),
                            ] else ...[
                              const CupertinoActivityIndicator(),
                              const SizedBox(height: 16),
                              const Text(
                                'Preparando seu bar…',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
