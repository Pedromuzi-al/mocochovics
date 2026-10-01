import 'package:flutter/cupertino.dart';

import '../../../../core/widgets/feature_pending_page.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePendingPage(
      title: 'Produtos',
      icon: CupertinoIcons.cube_box,
      message:
          'Aqui você vai cadastrar os produtos do bar, montar as fichas '
          'técnicas e acompanhar custos, preços de venda e margens.',
    );
  }
}
