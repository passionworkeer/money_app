import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/datasources/local/database_helper.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/budget_model.dart';
import 'sync_config.dart';
import 'sync_service.dart';
import 'supabase_sync_service.dart';
import 'webdav_sync_service.dart';
import 's3_sync_service.dart';
import 'icloud_sync_service.dart';

/// 同步管理器
class SyncManager {
  static const String _configKey = 'sync_config';

  SyncService? _currentService;
  SyncConfig _config = const SyncConfig();
  final _statusController = ValueNotifier<SyncStatus>(SyncStatus.idle);
  final _errorMessageController = ValueNotifier<String?>(null);

  ValueNotifier<SyncStatus> get status => _statusController;
  ValueNotifier<String?> get errorMessage => _errorMessageController;

  SyncConfig get config => _config;

  /// 初始化同步管理器
  Future<void> initialize() async {
    await _loadConfig();
    if (_config.provider != SyncProvider.none) {
      await _initializeService();
    }
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      if (configJson != null) {
        _config = SyncConfig.fromMap(
          Map<String, dynamic>.from(
            Uri.splitQueryString(configJson).map(
              (key, value) => MapEntry(key, value),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to load sync config: $e');
    }
  }

  /// 保存配置
  ///
  /// WARNING: Current implementation stores sensitive data in plaintext!
  ///
  /// SECURITY ISSUES:
  /// - SyncConfig contains sensitive data (API keys, passwords, tokens)
  /// - SharedPreferences is NOT encrypted by default
  /// - Data is stored in plaintext in app's private storage
  /// - Anyone with root/device access can read these credentials
  ///
  /// RECOMMENDED FOR PRODUCTION:
  /// Use flutter_secure_storage package instead:
  /// - Encrypted storage using Keychain (iOS) / Keystore (Android)
  /// - Hardware-backed security when available
  /// - Example:
  ///   ```dart
  ///   import 'package:flutter_secure_storage/flutter_secure_storage.dart';
  ///
  ///   final secureStorage = FlutterSecureStorage(
  ///     aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ///   );
  ///   await secureStorage.write(key: 'sync_config', value: configJson);
  ///   ```
  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _config.toMap();
      final queryString = map.entries
          .where((e) => e.value != null)
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      await prefs.setString(_configKey, queryString);
    } catch (e) {
      debugPrint('Failed to save sync config: $e');
    }
  }

  /// 初始化同步服务
  Future<void> _initializeService() async {
    await _disposeCurrentService();

    switch (_config.provider) {
      case SyncProvider.supabase:
        _currentService = SupabaseSyncService();
        break;
      case SyncProvider.webdav:
        _currentService = WebDAVSyncService();
        break;
      case SyncProvider.s3:
        _currentService = S3SyncService();
        break;
      case SyncProvider.icloud:
        _currentService = iCloudSyncService();
        break;
      case SyncProvider.none:
        return;
    }

    if (_currentService != null) {
      await _currentService!.initialize(_config);
    }
  }

  /// 更新配置
  Future<void> updateConfig(SyncConfig newConfig) async {
    _config = newConfig;
    _statusController.value = SyncStatus.idle;
    _errorMessageController.value = null;
    await _saveConfig();
    await _initializeService();
  }

  /// 执行同步
  Future<bool> sync() async {
    if (_currentService == null || !_config.isConfigured) {
      _errorMessageController.value = '同步服务未配置';
      return false;
    }

    _statusController.value = SyncStatus.syncing;
    _errorMessageController.value = null;

    try {
      // 获取本地数据
      final localData = await _getLocalData();

      // 拉取远程数据
      final remoteData = await _currentService!.pull();

      // 冲突解决：last-write-wins
      final mergedData = _mergeData(localData, remoteData);

      // 推送合并后的数据
      final success = await _currentService!.push(mergedData);

      if (success) {
        // 更新本地数据库
        await _updateLocalData(mergedData);

        // 更新同步时间
        _config = _config.copyWith(
          lastSyncTime: DateTime.now(),
          status: SyncStatus.success,
        );
        await _saveConfig();
        _statusController.value = SyncStatus.success;
      } else {
        throw Exception('同步失败');
      }

      return true;
    } catch (e) {
      _errorMessageController.value = e.toString();
      _config = _config.copyWith(status: SyncStatus.error);
      _statusController.value = SyncStatus.error;
      return false;
    }
  }

  /// 获取本地数据
  Future<SyncData> _getLocalData() async {
    final db = DatabaseHelper.instance;
    final expenses = await db.getAllExpenses();
    final budgets = await db.getAllBudgets();

    return SyncData(
      expenses: expenses.map((e) => _expenseToMap(e)).toList(),
      budgets: budgets.map((b) => b.toMap()).toList(),
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> _expenseToMap(Expense expense) {
    return {
      'id': expense.id,
      'amount': expense.amount,
      'description': expense.description,
      'category': expense.category,
      'date': expense.date.millisecondsSinceEpoch,
      'createdAt': expense.createdAt.millisecondsSinceEpoch,
      'updatedAt': expense.updatedAt.millisecondsSinceEpoch,
      'isSynced': expense.isSynced ? 1 : 0,
    };
  }

  /// 合并数据（冲突解决：last-write-wins）
  SyncData _mergeData(SyncData localData, SyncData? remoteData) {
    if (remoteData == null) {
      return localData;
    }

    // 合并支出数据
    final mergedExpenses = _mergeExpenses(
      localData.expenses,
      remoteData.expenses,
    );

    // 合并预算数据
    final mergedBudgets = _mergeBudgets(
      localData.budgets,
      remoteData.budgets,
    );

    return SyncData(
      expenses: mergedExpenses,
      budgets: mergedBudgets,
      settings: remoteData.settings,
      timestamp: DateTime.now(),
    );
  }

  List<Map<String, dynamic>> _mergeExpenses(
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> remote,
  ) {
    final merged = <String, Map<String, dynamic>>{};

    // 添加本地数据
    for (final item in local) {
      final id = item['id'] as String;
      merged[id] = item;
    }

    // 合并远程数据（last-write-wins）
    for (final item in remote) {
      final id = item['id'] as String;
      final localItem = merged[id];

      if (localItem == null) {
        merged[id] = item;
      } else {
        final localTime = localItem['updatedAt'] ?? localItem['createdAt'] ?? 0;
        final remoteTime = item['updatedAt'] ?? item['createdAt'] ?? 0;
        if (remoteTime > localTime) {
          merged[id] = item;
        }
      }
    }

    return merged.values.toList();
  }

  List<Map<String, dynamic>> _mergeBudgets(
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> remote,
  ) {
    final merged = <String, Map<String, dynamic>>{};

    for (final item in local) {
      final id = item['id'] as String;
      merged[id] = item;
    }

    for (final item in remote) {
      final id = item['id'] as String;
      final localItem = merged[id];

      if (localItem == null) {
        merged[id] = item;
      } else {
        final localTime = localItem['updatedAt'] ?? localItem['createdAt'] ?? 0;
        final remoteTime = item['updatedAt'] ?? item['createdAt'] ?? 0;
        if (remoteTime > localTime) {
          merged[id] = item;
        }
      }
    }

    return merged.values.toList();
  }

  /// 更新本地数据
  Future<void> _updateLocalData(SyncData data) async {
    final db = DatabaseHelper.instance;

    // 清空现有数据并重新导入
    await db.clearAllData();

    for (final expense in data.expenses) {
      await db.insertExpense(Expense.fromMap(expense));
    }

    for (final budget in data.budgets) {
      await db.insertBudget(Budget.fromMap(budget));
    }
  }

  /// 测试连接
  Future<bool> testConnection() async {
    if (_currentService == null || !_config.isConfigured) {
      return false;
    }

    try {
      return await _currentService!.testConnection();
    } catch (e) {
      return false;
    }
  }

  /// 断开当前服务
  Future<void> _disposeCurrentService() async {
    if (_currentService != null) {
      await _currentService!.dispose();
      _currentService = null;
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    await _disposeCurrentService();
  }
}
