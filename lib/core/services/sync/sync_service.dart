import 'sync_config.dart';

/// 同步数据模型
class SyncData {
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> budgets;
  final Map<String, dynamic>? settings;
  final DateTime timestamp;

  const SyncData({
    required this.expenses,
    required this.budgets,
    this.settings,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'expenses': expenses,
      'budgets': budgets,
      'settings': settings,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SyncData.fromJson(Map<String, dynamic> json) {
    return SyncData(
      expenses: (json['expenses'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      budgets: (json['budgets'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'])
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

/// 抽象同步服务接口
abstract class SyncService {
  /// 获取同步提供商名称
  String get providerName;

  /// 初始化服务
  Future<void> initialize(SyncConfig config);

  /// 检查服务是否已配置
  bool get isConfigured;

  /// 执行完整同步（拉取 + 推送）
  Future<bool> sync();

  /// 拉取远程数据
  Future<SyncData?> pull();

  /// 推送本地数据
  Future<bool> push(SyncData data);

  /// 测试连接
  Future<bool> testConnection();

  /// 断开连接/清理资源
  Future<void> dispose();
}
