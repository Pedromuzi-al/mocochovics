import 'package:flutter/cupertino.dart';

import '../../../../core/widgets/feature_pending_page.dart';

class IngredientsPage extends StatelessWidget {
  const IngredientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePendingPage(
      title: 'Ingredientes',
      icon: CupertinoIcons.leaf_arrow_circlepath,
      message:
          'Aqui você vai cadastrar os ingredientes, registrar o '
          'histórico de compras e comparar os preços por fornecedor.',
    );
  }
}
