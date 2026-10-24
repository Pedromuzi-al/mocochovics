import 'dart:typed_data';

import 'package:mocochovisk/features/transactions/data/finance_repository.dart';
import 'package:mocochovisk/features/transactions/domain/statement_filter.dart';

class FakeFinanceRepository implements FinanceRepository {
  final data = <String, List<DataRow>>{};
  Object? failure;
  int _sequence = 0;
  @override
  Future<void> prepare() async {
    if (failure != null) throw failure!;
  }

  @override
  Future<List<DataRow>> read(String table) async => List.of(data[table] ?? []);
  @override
  Future<void> save(String table, DataRow values) async {
    if (failure != null) throw failure!;
    final rows = data.putIfAbsent(table, () => []);
    final id = values['id'] ?? 'test-${++_sequence}';
    rows.removeWhere((row) => row['id'] == id);
    rows.add({...values, 'id': id});
  }

  @override
  Future<void> delete(String table, String id) async {
    if (failure != null) throw failure!;
    data[table]?.removeWhere((row) => row['id'] == id);
  }

  @override
  Future<void> saveTransaction(DataRow entry, DataRow? quote) =>
      save('transactions', entry);
  @override
  Future<String> uploadReceipt(Uint8List bytes, String extension) async =>
      'test/receipt.$extension';
  @override
  Future<void> removeReceipt(String path) async {}
  @override
  Future<String> receiptUrl(String path) async => 'https://example.com/receipt';
}
