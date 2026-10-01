import 'package:flutter/cupertino.dart';

import '../../../../core/widgets/feature_pending_page.dart';

class StatementPage extends StatelessWidget {
  const StatementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePendingPage(
      title: 'Extrato',
      icon: CupertinoIcons.doc_text,
      message:
          'Aqui você vai acompanhar as entradas e saídas do bar, '
          'filtrar lançamentos e consultar o saldo de cada período.',
    );
  }
}
