import 'package:flutter/cupertino.dart';

import '../../../../core/widgets/feature_pending_page.dart';

class SuppliersPage extends StatelessWidget {
  const SuppliersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePendingPage(
      title: 'Fornecedores',
      icon: CupertinoIcons.person_2,
      message:
          'Aqui você vai organizar os contatos dos fornecedores, '
          'consultar o que cada um fornece e acompanhar seus preços.',
    );
  }
}
