import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'sync_config.dart';
import 'sync_service.dart';

/// iCloud 同步服务实现
/// 使用 SharedPreferences 模拟 iCloud Key-Value 存储
/// 在真实 iOS 环境中，应使用 flutter_icloud_container
class iCloudSyncService implements SyncService {
  static const String _expensesKey = 'icloud_expenses';
  static const String _budgetsKey = 'icloud_budgets';
  static const String _settingsKey = 'icloud_settings';
  static const String _timestampKey = 'icloud_timestamp';

  SharedPreferences? _prefs;
  SyncConfig _config = const SyncConfig();

  @override
  String get providerName => 'iCloud';

  @override
  bool get isConfigured => true; // iCloud 不需要额外配置

  @override
  Future<void> initialize(SyncConfig config) async {
    _config = config;
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<bool> testConnection() async {
    // 测试 SharedPreferences 是否可用
    try {
      await _prefs!.setString('test', 'test');
      await _prefs!.remove('test');
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<SyncData?> pull() async {
    if (_prefs == null) {
      throw Exception('iCloud 未初始化');
    }

    try {
      final expensesJson = _prefs!.getString(_expensesKey);
      final budgetsJson = _prefs!.getString(_budgetsKey);
      final settingsJson = _prefs!.getString(_settingsKey);
      final timestampStr = _prefs!.getString(_timestampKey);

      final expenses = expensesJson != null
          ? (jsonDecode(expensesJson) as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      final budgets = budgetsJson != null
          ? (jsonDecode(budgetsJson) as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      final settings = settingsJson != null
          ? Map<String, dynamic>.from(jsonDecode(settingsJson))
          : null;

      return SyncData(
        expenses: expenses,
        budgets: budgets,
        settings: settings,
        timestamp: timestampStr != null
            ? DateTime.parse(timestampStr)
            : DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> push(SyncData data) async {
    if (_prefs == null) {
      throw Exception('iCloud 未初始化');
    }

    try {
      await Future.wait([
        _prefs!.setString(
          _expensesKey,
          jsonEncode(data.expenses),
        ),
        _prefs!.setString(
          _budgetsKey,
          jsonEncode(data.budgets),
        ),
        if (data.settings != null)
          _prefs!.setString(
            _settingsKey,
            jsonEncode(data.settings),
          ),
        _prefs!.setString(
          _timestampKey,
          data.timestamp.toIso8601String(),
        ),
      ]);

      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> sync() async {
    try {
      // 拉取远程数据
      final remoteData = await pull();

      // TODO: 实现冲突解决策略（last-write-wins）

      // 推送本地数据
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    _prefs = null;
  }
}
