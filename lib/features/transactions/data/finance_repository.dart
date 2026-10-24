import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../domain/statement_filter.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final auth = ref.watch(authControllerProvider);
  final ownerId = client.auth.currentUser?.id;
  void onAuthChanged() {
    if (client.auth.currentUser?.id != ownerId) ref.invalidateSelf();
  }

  auth.addListener(onAuthChanged);
  ref.onDispose(() => auth.removeListener(onAuthChanged));
  return SupabaseFinanceRepository(client);
});

final financeSnapshotProvider = FutureProvider.autoDispose<FinanceSnapshot>((
  ref,
) async {
  final repository = ref.watch(financeRepositoryProvider);
  await repository.prepare();
  final rows = await Future.wait(FinanceSnapshot.tables.map(repository.read));
  return FinanceSnapshot(Map.fromIterables(FinanceSnapshot.tables, rows));
});

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

abstract interface class FinanceRepository {
  Future<void> prepare();
  Future<List<DataRow>> read(String table);
  Future<void> save(String table, DataRow values);
  Future<void> delete(String table, String id);
  Future<void> saveTransaction(DataRow entry, DataRow? quote);
  Future<String> uploadReceipt(Uint8List bytes, String extension);
  Future<void> removeReceipt(String path);
  Future<String> receiptUrl(String path);
}

class SupabaseFinanceRepository implements FinanceRepository {
  SupabaseFinanceRepository(this.client);
  final SupabaseClient client;
  String get ownerId =>
      client.auth.currentUser?.id ??
      (throw StateError('Entre novamente para continuar.'));

  @override
  Future<void> prepare() async {
    await client.rpc('ensure_defaults');
    await client.rpc('generate_recurring');
  }

  @override
  Future<List<DataRow>> read(String table) async {
    final result = <DataRow>[];
    for (var offset = 0; ; offset += 500) {
      final page = await client
          .from(table)
          .select()
          .eq('owner_id', ownerId)
          .order('id')
          .range(offset, offset + 499);
      result.addAll(page);
      if (page.length < 500) return result;
    }
  }

  @override
  Future<void> save(String table, DataRow values) async {
    final payload = {...values, 'owner_id': ownerId};
    if (values['id'] == null) {
      await client.from(table).insert(payload);
    } else {
      await client
          .from(table)
          .update(payload)
          .eq('id', values['id'] as String)
          .eq('owner_id', ownerId);
    }
  }

  @override
  Future<void> delete(String table, String id) async {
    final receipt = table == 'transactions'
        ? await client
              .from(table)
              .select('receipt_path')
              .eq('id', id)
              .eq('owner_id', ownerId)
              .maybeSingle()
        : null;
    await client.from(table).delete().eq('id', id).eq('owner_id', ownerId);
    if (receipt?['receipt_path'] != null) {
      try {
        await removeReceipt(receipt!['receipt_path'] as String);
      } catch (_) {}
    }
  }

  @override
  Future<void> saveTransaction(DataRow entry, DataRow? quote) async {
    await client.rpc(
      'save_transaction',
      params: {'entry': entry, 'quote': quote},
    );
  }

  @override
  Future<String> uploadReceipt(Uint8List bytes, String extension) async {
    final path = '$ownerId/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await client.storage
        .from('receipts')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: switch (extension) {
              'pdf' => 'application/pdf',
              'png' => 'image/png',
              _ => 'image/jpeg',
            },
          ),
        );
    return path;
  }

  @override
  Future<void> removeReceipt(String path) async =>
      client.storage.from('receipts').remove([path]);

  @override
  Future<String> receiptUrl(String path) =>
      client.storage.from('receipts').createSignedUrl(path, 60);
}
