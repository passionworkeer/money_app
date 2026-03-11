import 'package:supabase_flutter/supabase_flutter.dart';
import 'sync_config.dart';
import 'sync_service.dart';

/// Supabase 同步服务实现
class SupabaseSyncService implements SyncService {
  SupabaseClient? _client;
  SyncConfig _config = const SyncConfig();

  @override
  String get providerName => 'Supabase';

  @override
  bool get isConfigured => _config.isConfigured;

  @override
  Future<void> initialize(SyncConfig config) async {
    _config = config;
    if (!config.isConfigured) {
      throw Exception('Supabase 配置不完整');
    }

    await Supabase.initialize(
      url: config.supabaseUrl!,
      anonKey: config.supabaseAnonKey!,
    );
    _client = Supabase.instance.client;
  }

  @override
  Future<bool> testConnection() async {
    if (_client == null) return false;

    try {
      final response = await _client!.from('expenses').select('id').limit(1);
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<SyncData?> pull() async {
    if (_client == null) {
      throw Exception('Supabase 未初始化');
    }

    try {
      // 拉取支出数据
      final expensesResponse = await _client!.from('expenses').select('*');
      final expenses = (expensesResponse as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // 拉取预算数据
      final budgetsResponse = await _client!.from('budgets').select('*');
      final budgets = (budgetsResponse as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // 拉取设置数据
      final settingsResponse = await _client!.from('settings').select('*').limit(1);
      final settings = settingsResponse.isNotEmpty
          ? Map<String, dynamic>.from(settingsResponse.first)
          : null;

      return SyncData(
        expenses: expenses,
        budgets: budgets,
        settings: settings,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> push(SyncData data) async {
    if (_client == null) {
      throw Exception('Supabase 未初始化');
    }

    try {
      // 同步支出数据
      if (data.expenses.isNotEmpty) {
        // 使用 upsert 来处理增量同步
        await _client!.from('expenses').upsert(
          data.expenses.map((e) => {
            'id': e['id'],
            'amount': e['amount'],
            'description': e['description'],
            'category': e['category'],
            'date': e['date'],
            'createdAt': e['createdAt'],
            'isSynced': true,
          }).toList(),
          onConflict: 'id',
        );
      }

      // 同步预算数据
      if (data.budgets.isNotEmpty) {
        await _client!.from('budgets').upsert(
          data.budgets,
          onConflict: 'id',
        );
      }

      // 同步设置数据（如果有）
      if (data.settings != null) {
        await _client!.from('settings').upsert(
          data.settings!,
          onConflict: 'id',
        );
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> sync() async {
    try {
      // TODO: 拉取远程数据并实现冲突解决策略（last-write-wins）
      // final remoteData = await pull();

      // 推送本地数据
      // 这里需要从数据库获取最新数据
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    _client = null;
  }
}
