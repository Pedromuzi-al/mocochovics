import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/features/products/domain/product_financials.dart';

import 'finance_fixture.dart';

void main() {
  test('recipe loss, direct cost, margin, markup and suggested price use exact decimals', () {
    final result = ProductFinancials.calculate(
      salePrice: Decimal.fromInt(10),
      targetMargin: Decimal.parse('0.30'),
      recipe: [
        RecipeComponent(
          quantity: Decimal.fromInt(100),
          loss: Decimal.parse('0.10'),
          unitCost: Decimal.parse('0.02'),
        ),
        RecipeComponent(
          quantity: Decimal.fromInt(50),
          loss: Decimal.zero,
          unitCost: Decimal.parse('0.03'),
        ),
      ],
    );
    expect(result.cost, Decimal.parse('3.70'));
    expect(result.profit, Decimal.parse('6.30'));
    expect(result.marginPercent, Decimal.fromInt(63));
    expect(result.markup, Decimal.parse('2.702703'));
    expect(result.suggestedPrice, Decimal.parse('5.29'));
    expect(result.lowMargin, isFalse);
  });
  test('rounds the complete recipe once and preserves unknown costs', () {
    final recipe = List.generate(
      3,
      (_) => RecipeComponent(
        quantity: Decimal.one,
        loss: Decimal.zero,
        unitCost: Decimal.parse('0.004'),
      ),
    );
    expect(
      ProductFinancials.calculate(
        salePrice: Decimal.one,
        targetMargin: Decimal.zero,
        recipe: recipe,
      ).cost,
      Decimal.parse('0.01'),
    );
    final missing = ProductFinancials.calculate(
      salePrice: Decimal.one,
      targetMargin: Decimal.parse('0.3'),
      recipe: [
        RecipeComponent(
          quantity: Decimal.one,
          loss: Decimal.zero,
          unitCost: null,
        ),
      ],
    );
    expect(missing.cost, isNull);
    expect(missing.markup, isNull);
    expect(missing.marginPercent, isNull);
    expect(missing.lowMargin, isFalse);
    expect(
      ProductFinancials.calculate(
        salePrice: Decimal.one,
        targetMargin: Decimal.zero,
        recipe: [],
      ).cost,
      isNull,
    );
  });
  test('low-margin alert compares unrounded margin and allows a loss', () {
    final result = ProductFinancials(
      salePrice: Decimal.fromInt(10),
      cost: Decimal.fromInt(12),
      targetMargin: Decimal.parse('0.30'),
    );
    expect(result.marginPercent, Decimal.fromInt(-20));
    expect(result.profit, Decimal.fromInt(-2));
    expect(result.lowMargin, isTrue);
    final near = ProductFinancials(
      salePrice: Decimal.fromInt(10000),
      cost: Decimal.parse('7000.01'),
      targetMargin: Decimal.parse('0.30'),
    );
    expect(near.marginPercent, Decimal.fromInt(30));
    expect(near.lowMargin, isTrue);
  });
  test(
    'rejects invalid financial inputs and validates percentage precision',
    () {
      expect(
        () => RecipeComponent(
          quantity: Decimal.zero,
          loss: Decimal.zero,
          unitCost: Decimal.one,
        ),
        throwsArgumentError,
      );
      expect(
        () => ProductFinancials.calculate(
          salePrice: Decimal.zero,
          targetMargin: Decimal.zero,
          recipe: [],
        ),
        throwsArgumentError,
      );
      expect(
        CostPreferences.percentToFraction('30,1250', margin: true),
        Decimal.parse('0.30125'),
      );
      expect(CostPreferences.percentToFraction('0'), Decimal.zero);
      expect(
        () => CostPreferences.percentToFraction('100', margin: true),
        throwsFormatException,
      );
      expect(
        () => CostPreferences.percentToFraction('0,00001'),
        throwsFormatException,
      );
      expect(
        () => CostPreferences.percentToFraction('-1'),
        throwsFormatException,
      );
    },
  );
  test('cost policies distinguish purchases from quotes and exclude inactive suppliers only for minimum', () {
    final history = fixtureSnapshot()
        .rows('ingredient_prices')
        .where((row) => row['ingredient_id'] == 'meat')
        .toList();
    expect(
      IngredientCostPolicy.calculate(history, {'central'}),
      Decimal.parse('0.06'),
    );
    expect(
      IngredientCostPolicy.calculate(history, {}, method: 'last_paid'),
      Decimal.parse('0.07'),
    );
    expect(
      IngredientCostPolicy.calculate(history, {}, purchaseCount: 1),
      Decimal.parse('0.07'),
    );
    expect(
      IngredientCostPolicy.calculate(history, {
        'central',
      }, method: 'lowest_active'),
      Decimal.parse('0.07'),
    );
    expect(
      IngredientCostPolicy.calculate(history, {}, method: 'lowest_active'),
      isNull,
    );
    final quotes = [
      {...history.last, 'kind': 'quote'},
    ];
    expect(IngredientCostPolicy.calculate(quotes, {'central'}), isNull);
    expect(
      IngredientCostPolicy.calculate(quotes, {
        'central',
      }, method: 'lowest_active'),
      Decimal.parse('0.07'),
    );
  });
  test(
    'weighted average weights quantities instead of averaging unit prices',
    () {
      final original = fixtureSnapshot()
          .rows('ingredient_prices')
          .where((row) => row['ingredient_id'] == 'meat')
          .toList();
      final history = [
        original.first,
        {...original.last, 'price': '140', 'base_quantity': '2000'},
      ];
      expect(
        IngredientCostPolicy.calculate(history, {'central'}),
        Decimal.parse('0.063333'),
      );
    },
  );
}
