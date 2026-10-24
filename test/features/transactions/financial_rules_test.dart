import 'package:decimal/decimal.dart';
import 'package:mocochovisk/core/utils/br_currency_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocochovisk/core/utils/financial_math.dart';
import 'package:mocochovisk/features/ingredients/domain/price_history.dart';
import 'package:mocochovisk/features/transactions/domain/statement_filter.dart';

void main() {
  test('currency input formats cents in pt-BR without binary rounding', () {
    final formatter = BrCurrencyInputFormatter();
    final result = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(text: '123456'),
    );
    expect(result.text, 'R\$\u00a01.234,56');
    expect(FinancialMath.number(result.text, scale: 2), '1234.56');
    expect(
      formatter.formatEditUpdate(result, const TextEditingValue()).text,
      isEmpty,
    );
  });
  test('parses Brazilian money without binary rounding and rejects excess decimals', () {
    expect(FinancialMath.number('R\$ 1.234,56', scale: 2), '1234.56');
    expect(FinancialMath.cents('0.29'), 29);
    expect(
      () => FinancialMath.number('1,234', scale: 2),
      throwsFormatException,
    );
    expect(() => FinancialMath.number('-10'), throwsFormatException);
    expect(() => FinancialMath.number('0'), throwsFormatException);
  });
  test('converts only compatible units and computes unit price', () {
    expect(FinancialMath.baseQuantity('1,5', 'kg', 'g'), Decimal.fromInt(1500));
    expect(FinancialMath.baseQuantity('0,9', 'l', 'ml'), Decimal.fromInt(900));
    expect(
      FinancialMath.unitPrice('2,00', '3', 'un', 'un'),
      Decimal.parse('0.666667'),
    );
    expect(
      FinancialMath.unitPrice('15,00', '1,5', 'kg', 'g'),
      Decimal.parse('0.01'),
    );
    expect(
      () => FinancialMath.baseQuantity('1', 'kg', 'ml'),
      throwsFormatException,
    );
  });
  test(
    'filters all dimensions inclusively and excludes pending from balances',
    () {
      final rows = <DataRow>[
        {
          'id': '1',
          'date': '2026-10-01',
          'created_at': '1',
          'type': 'entrada',
          'amount': '100.10',
          'status': 'pago',
          'description': 'Vendas',
          'category_id': 'sales',
          'supplier_id': null,
          'payment_method': 'pix',
        },
        {
          'id': '2',
          'date': '2026-10-02',
          'created_at': '2',
          'type': 'saida',
          'amount': '20.05',
          'status': 'pago',
          'description': 'Compra gelo',
          'category_id': 'supplies',
          'supplier_id': 'supplier',
          'payment_method': 'pix',
        },
        {
          'id': '3',
          'date': '2026-10-03',
          'created_at': '3',
          'type': 'saida',
          'amount': '30.00',
          'status': 'pendente',
          'description': 'Compra carne',
          'category_id': 'supplies',
          'supplier_id': 'supplier',
          'payment_method': 'credito',
        },
      ];
      final totals = StatementTotals(rows);
      expect(totals.balance, 8005);
      expect(totals.pending, 3000);
      final filtered = StatementFilter(
        start: DateTime(2026, 10, 2),
        end: DateTime(2026, 10, 2),
        type: 'saida',
        categoryId: 'supplies',
        supplierId: 'supplier',
        paymentMethod: 'pix',
        status: 'pago',
        search: 'GELO',
      ).apply(rows.reversed.toList());
      expect(filtered.map((row) => row['id']), ['2']);
    },
  );
  test('latest prices use quote dates and compare exact decimals', () {
    final prices = <DataRow>[
      {
        'id': '1',
        'ingredient_id': 'ice',
        'supplier_id': 'a',
        'date': '2026-10-01',
        'created_at': '1',
        'unit_price': '0.020000',
      },
      {
        'id': '2',
        'ingredient_id': 'ice',
        'supplier_id': 'a',
        'date': '2026-10-03',
        'created_at': '2',
        'unit_price': '0.030000',
      },
      {
        'id': '3',
        'ingredient_id': 'ice',
        'supplier_id': 'b',
        'date': '2026-10-02',
        'created_at': '3',
        'unit_price': '0.025000',
      },
    ];
    expect(PriceHistory.current(prices).map((row) => row['id']), ['3', '2']);
    expect(
      PriceHistory.variation(prices.where((row) => row['supplier_id'] == 'a')),
      '50.00',
    );
    expect(PriceHistory.variation(prices.take(1)), isNull);
  });
}
