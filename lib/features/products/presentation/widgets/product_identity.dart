import 'package:flutter/cupertino.dart';

class ProductIdentity extends StatelessWidget {
  const ProductIdentity({
    required this.id,
    required this.name,
    this.detail = false,
    super.key,
  });
  final String id, name;
  final bool detail;
  @override
  Widget build(BuildContext context) => HeroMode(
    enabled: !MediaQuery.disableAnimationsOf(context),
    child: Hero(
      tag: 'product-name-$id',
      transitionOnUserGestures: true,
      child: Text(
        name,
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          fontSize: detail ? 28 : 17,
          fontWeight: FontWeight.w600,
          letterSpacing: detail ? -.6 : -.2,
        ),
      ),
    ),
  );
}
