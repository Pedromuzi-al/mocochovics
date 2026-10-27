import '../../../core/utils/financial_math.dart';

typedef DataRow = Map<String, dynamic>;

class StatementFilter {
  const StatementFilter({
    this.start,
    this.end,
    this.type,
    this.categoryId,
    this.supplierId,
    this.suppliersOnly = false,
    this.paymentMethod,
    this.status,
    this.search = '',
  });

  final DateTime? start;
  final DateTime? end;
  final String? type;
  final String? categoryId;
  final String? supplierId;
  final bool suppliersOnly;
  final String? paymentMethod;
  final String? status;
  final String search;

  List<DataRow> apply(List<DataRow> rows) {
    final result = rows.where((row) {
      final date = DateTime.parse(row['date'] as String);
      return (start == null || !date.isBefore(start!)) &&
          (end == null || !date.isAfter(end!)) &&
          (type == null || row['type'] == type) &&
          (categoryId == null || row['category_id'] == categoryId) &&
          (supplierId == null || row['supplier_id'] == supplierId) &&
          (!suppliersOnly || row['supplier_id'] != null) &&
          (paymentMethod == null || row['payment_method'] == paymentMethod) &&
          (status == null || row['status'] == status) &&
          row['description'].toString().toLowerCase().contains(
            search.trim().toLowerCase(),
          );
    }).toList();
    result.sort((first, second) {
      final date = first['date'].toString().compareTo(
        second['date'].toString(),
      );
      if (date != 0) return date;
      final created = first['created_at'].toString().compareTo(
        second['created_at'].toString(),
      );
      return created != 0
          ? created
          : first['id'].toString().compareTo(second['id'].toString());
    });
    return result;
  }
}

class StatementTotals {
  StatementTotals(Iterable<DataRow> rows) {
    for (final row in rows) {
      final amount = FinancialMath.cents(row['amount']);
      if (row['status'] == 'pendente') {
        pending += amount;
      } else if (row['type'] == 'entrada') {
        income += amount;
      } else {
        expenses += amount;
      }
    }
  }

  int income = 0;
  int expenses = 0;
  int pending = 0;
  int get balance => income - expenses;
}
