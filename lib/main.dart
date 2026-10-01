import 'package:flutter/cupertino.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/supabase/app_bootstrap.dart';
import 'core/supabase/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');
  runApp(AppBootstrap(config: AppConfig.fromEnvironment()));
}
