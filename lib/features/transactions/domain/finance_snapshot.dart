import 'statement_filter.dart';

class FinanceSnapshot {
  const FinanceSnapshot(this.data);
  static const tables = [
    'suppliers',
    'ingredients',
    'ingredient_prices',
    'transaction_categories',
    'transactions',
    'recurring_transactions',
    'products',
    'product_recipe_items',
    'app_settings',
    'ingredient_costs',
    'product_costs',
    'product_cost_history',
  ];
  final Map<String, List<DataRow>> data;
  List<DataRow> rows(String table) => data[table] ?? const [];
  String name(String table, Object? id) {
    for (final row in rows(table)) {
      if (row['id'] == id) return row['name'].toString();
    }
    return 'Não informado';
  }
}
