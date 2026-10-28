import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../features/statement/presentation/pages/statement_page.dart';
import '../../features/transactions/domain/statement_filter.dart';

int _statementRequest = 0;

void openStatement(BuildContext context, StatementFilter filter) {
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    // Also support presenting this feature outside the application's tab shell.
    Navigator.of(context).push<void>(
      CupertinoPageRoute(builder: (_) => StatementPage(initialFilter: filter)),
    );
    return;
  }
  final uri = Uri(
    path: '/extrato',
    queryParameters: filter.toQueryParameters(),
  );
  // An explicit shortcut reapplies its filter, even when that URL was visited
  // before. Restoring a tab keeps the same request and preserves local edits.
  router.go(uri.toString(), extra: ++_statementRequest);
}
