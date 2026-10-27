import 'package:decimal/decimal.dart';

import '../../../core/utils/financial_math.dart';
import '../../../core/utils/br_formatters.dart';
import '../../ingredients/domain/price_history.dart';
import '../../transactions/domain/finance_snapshot.dart';
import '../../transactions/domain/statement_filter.dart';

Decimal? decimalOrNull(Object? value) =>
    value == null ? null : Decimal.parse(value.toString());
Decimal roundedDivision(Decimal numerator, Decimal denominator, int scale) =>
    (numerator / denominator)
        .toDecimal(
          scaleOnInfinitePrecision: scale,
          toBigInt: (value) => value.round(),
        )
        .round(scale: scale);
String localizedDecimal(Decimal value, [int digits = 2]) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');
String localizedMeasurement(Decimal value, {int digits = 6}) =>
    value.round(scale: digits).toString().replaceAll('.', ',');
String money(Decimal? value) => value == null
    ? 'Sem custo disponível'
    : BrFormatters.currencyFromCents(FinancialMath.cents(value));

class CostPreferences {
  const CostPreferences({
    required this.targetMargin,
    required this.method,
    required this.purchaseCount,
    required this.priceAlertThreshold,
    this.id,
  });
  factory CostPreferences.fromSnapshot(FinanceSnapshot snapshot) {
    final row = snapshot.rows('app_settings').firstOrNull;
    return CostPreferences(
      id: row?['id'],
      targetMargin:
          decimalOrNull(row?['target_margin']) ?? Decimal.parse('0.30'),
      method: row?['cost_method'] ?? 'weighted_average',
      purchaseCount: row?['purchase_count'] ?? 5,
      priceAlertThreshold:
          decimalOrNull(row?['price_alert_threshold']) ?? Decimal.parse('0.10'),
    );
  }
  final String? id;
  final Decimal targetMargin, priceAlertThreshold;
  final String method;
  final int purchaseCount;
  String get methodLabel => switch (method) {
    'last_paid' => 'Último preço pago',
    'lowest_active' => 'Menor preço ativo',
    _ => 'Média ponderada ($purchaseCount compras)',
  };
  static Decimal percentToFraction(String input, {bool margin = false}) {
    final percentage = Decimal.parse(
      FinancialMath.number(input, scale: 4, positive: false),
    );
    if (margin && percentage >= Decimal.fromInt(100)) {
      throw const FormatException('A margem deve ser menor que 100%.');
    }
    return (percentage / Decimal.fromInt(100)).toDecimal();
  }

  static String? percentageError(String input, {bool margin = false}) {
    try {
      percentToFraction(input, margin: margin);
      return null;
    } on FormatException catch (error) {
      return error.message;
    }
  }
}

class RecipeComponent {
  RecipeComponent({
    required this.quantity,
    required this.loss,
    required this.unitCost,
  }) {
    if (quantity <= Decimal.zero ||
        loss < Decimal.zero ||
        (unitCost != null && unitCost! < Decimal.zero)) {
      throw ArgumentError('Quantidade, perda ou custo inválido.');
    }
  }
  final Decimal quantity, loss;
  final Decimal? unitCost;
  Decimal? get cost =>
      unitCost == null ? null : quantity * (Decimal.one + loss) * unitCost!;
}

class ProductFinancials {
  const ProductFinancials({
    required this.salePrice,
    required this.cost,
    required this.targetMargin,
  });
  factory ProductFinancials.fromDatabase(DataRow row) => ProductFinancials(
    salePrice: Decimal.parse(row['sale_price'].toString()),
    cost: decimalOrNull(row['cost']),
    targetMargin: Decimal.parse(row['target_margin'].toString()),
  );
  factory ProductFinancials.calculate({
    required Decimal salePrice,
    required List<RecipeComponent> recipe,
    required Decimal targetMargin,
  }) {
    if (salePrice <= Decimal.zero ||
        targetMargin < Decimal.zero ||
        targetMargin >= Decimal.one) {
      throw ArgumentError('Preço e margem-alvo inválidos.');
    }
    final complete =
        recipe.isNotEmpty && recipe.every((item) => item.unitCost != null);
    return ProductFinancials(
      salePrice: salePrice,
      targetMargin: targetMargin,
      cost: complete
          ? recipe
                .fold(Decimal.zero, (total, item) => total + item.cost!)
                .round(scale: 2)
          : null,
    );
  }
  final Decimal salePrice, targetMargin;
  final Decimal? cost;
  Decimal? get profit => cost == null ? null : salePrice - cost!;
  Decimal? get marginPercent => profit == null
      ? null
      : roundedDivision(profit! * Decimal.fromInt(100), salePrice, 2);
  Decimal? get markup => cost == null || cost == Decimal.zero
      ? null
      : roundedDivision(salePrice, cost!, 6);
  Decimal? get suggestedPrice => cost == null
      ? null
      : roundedDivision(cost!, Decimal.one - targetMargin, 2);
  bool get lowMargin => profit != null && profit! < salePrice * targetMargin;
}

abstract final class IngredientCostPolicy {
  static Decimal? calculate(
    List<DataRow> history,
    Set<String> activeSuppliers, {
    String method = 'weighted_average',
    int purchaseCount = 5,
  }) {
    if (purchaseCount < 1 || purchaseCount > 1000) {
      throw ArgumentError.value(purchaseCount);
    }
    if (!const [
      'last_paid',
      'weighted_average',
      'lowest_active',
    ].contains(method)) {
      throw ArgumentError.value(method);
    }
    if (method == 'lowest_active') {
      return PriceHistory.current(history)
          .where((row) => activeSuppliers.contains(row['supplier_id']))
          .map((row) => Decimal.parse(row['unit_price'].toString()))
          .firstOrNull;
    }
    final purchases = PriceHistory.chronological(
      history.where((row) => row['kind'] == 'purchase'),
    ).reversed.toList();
    if (purchases.isEmpty) return null;
    if (method == 'last_paid') {
      return Decimal.parse(purchases.first['unit_price'].toString());
    }
    final recent = purchases.take(purchaseCount);
    final total = recent.fold(
      Decimal.zero,
      (sum, row) => sum + Decimal.parse(row['price'].toString()),
    );
    final quantity = recent.fold(
      Decimal.zero,
      (sum, row) => sum + Decimal.parse(row['base_quantity'].toString()),
    );
    return roundedDivision(total, quantity, 6);
  }
}
