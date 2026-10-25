import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/finance_widgets.dart';
import '../../../../core/widgets/premium_finance.dart';
import '../../../products/domain/product_financials.dart';

class CostSettingsPage extends ConsumerWidget {
  const CostSettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => FinanceBody(
    title: 'Custos e alertas',
    builder: (snapshot) {
      final preferences = CostPreferences.fromSnapshot(snapshot);
      return [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MarginNotice(
                message: 'As configurações se aplicam a todos os produtos. A margem usa apenas o custo dos ingredientes.',
                warning: false,
              ),
              const SizedBox(height: 20),
              FinanceSection(
                children: [
                  CupertinoListTile(
                    title: const Text('Método de custo'),
                    subtitle: Text(preferences.methodLabel, maxLines: 3),
                  ),
                  CupertinoListTile(
                    title: const Text('Margem-alvo'),
                    subtitle: Text(
                      '${localizedDecimal(preferences.targetMargin * Decimal.fromInt(100))}%',
                    ),
                  ),
                  CupertinoListTile(
                    title: const Text('Alerta de aumento de preço'),
                    subtitle: Text(
                      'Acima de ${localizedDecimal(preferences.priceAlertThreshold * Decimal.fromInt(100))}%',
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
              const Text(
                'Último preço e média usam compras realizadas. Menor preço usa a cotação atual de fornecedores ativos. Sem compras, esses métodos deixam o custo indisponível.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: () => editRecord(
                  context,
                  ref,
                  title: 'Configurar cálculo',
                  table: 'app_settings',
                  initial: {
                    if (preferences.id != null) 'id': preferences.id,
                    'cost_method': preferences.method,
                    'purchase_count': preferences.purchaseCount,
                    'margin_percent':
                        (preferences.targetMargin * Decimal.fromInt(100))
                            .toString(),
                    'alert_percent':
                        (preferences.priceAlertThreshold * Decimal.fromInt(100))
                            .toString(),
                  },
                  fields: [
                    const EditField(
                      'cost_method',
                      'Custo do ingrediente',
                      required: true,
                      options: {
                        'last_paid': 'Último preço pago',
                        'weighted_average':
                            'Média ponderada das últimas compras',
                        'lowest_active': 'Menor preço de fornecedor ativo',
                      },
                    ),
                    EditField(
                      'purchase_count',
                      'Quantidade de compras para a média',
                      required: true,
                      integer: true,
                      validate: (value) =>
                          int.parse(value) < 1 || int.parse(value) > 1000
                          ? 'Use de 1 a 1000 compras.'
                          : null,
                    ),
                    EditField(
                      'margin_percent',
                      'Margem-alvo (%)',
                      required: true,
                      number: true,
                      allowZero: true,
                      validate: (value) =>
                          CostPreferences.percentageError(value, margin: true),
                    ),
                    EditField(
                      'alert_percent',
                      'Alertar aumentos acima de (%)',
                      required: true,
                      number: true,
                      allowZero: true,
                      validate: CostPreferences.percentageError,
                    ),
                  ],
                  transform: (values) {
                    final margin = CostPreferences.percentToFraction(
                      values.remove('margin_percent'),
                      margin: true,
                    );
                    final alert = CostPreferences.percentToFraction(
                      values.remove('alert_percent'),
                    );
                    return {
                      ...values,
                      'target_margin': margin.toString(),
                      'price_alert_threshold': alert.toString(),
                    };
                  },
                ),
                child: const Text('Editar configurações'),
              ),
            ],
          ),
        ),
      ];
    },
  );
}
