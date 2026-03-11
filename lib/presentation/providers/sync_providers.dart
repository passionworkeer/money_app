import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/sync/sync.dart';

/// 全局 SyncManager 实例
final _syncManager = SyncManager();

/// 同步管理器 Provider
final syncManagerProvider = Provider<SyncManager>((ref) {
  // 初始化
  _syncManager.initialize();
  ref.onDispose(() => _syncManager.dispose());
  return _syncManager;
});

/// 同步配置 Provider
final syncConfigProvider = StateNotifierProvider<SyncConfigNotifier, SyncConfig>((ref) {
  final manager = ref.watch(syncManagerProvider);
  return SyncConfigNotifier(manager);
});

class SyncConfigNotifier extends StateNotifier<SyncConfig> {
  final SyncManager _manager;

  SyncConfigNotifier(this._manager) : super(const SyncConfig()) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    state = _manager.config;
  }

  Future<void> updateProvider(SyncProvider provider) async {
    state = state.copyWith(provider: provider);
    await _manager.updateConfig(state);
  }

  Future<void> updateSupabaseConfig({
    required String url,
    required String anonKey,
  }) async {
    state = state.copyWith(
      provider: SyncProvider.supabase,
      supabaseUrl: url,
      supabaseAnonKey: anonKey,
    );
    await _manager.updateConfig(state);
  }

  Future<void> updateWebDAVConfig({
    required String url,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(
      provider: SyncProvider.webdav,
      webdavUrl: url,
      webdavUsername: username,
      webdavPassword: password,
    );
    await _manager.updateConfig(state);
  }

  Future<void> updateS3Config({
    required String accessKey,
    required String secretKey,
    required String bucket,
    String? endpoint,
    bool? useSsl,
  }) async {
    state = state.copyWith(
      provider: SyncProvider.s3,
      s3AccessKey: accessKey,
      s3SecretKey: secretKey,
      s3Bucket: bucket,
      s3Endpoint: endpoint,
      s3UseSsl: useSsl,
    );
    await _manager.updateConfig(state);
  }

  Future<void> clearConfig() async {
    state = const SyncConfig();
    await _manager.updateConfig(state);
  }
}

/// 同步状态 Provider
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncState>((ref) {
  final manager = ref.watch(syncManagerProvider);
  return SyncStatusNotifier(manager);
});

class SyncState {
  final SyncStatus status;
  final String? errorMessage;
  final DateTime? lastSyncTime;
  final bool isSyncing;

  const SyncState({
    this.status = SyncStatus.idle,
    this.errorMessage,
    this.lastSyncTime,
    this.isSyncing = false,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? errorMessage,
    DateTime? lastSyncTime,
    bool? isSyncing,
  }) {
    return SyncState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class SyncStatusNotifier extends StateNotifier<SyncState> {
  final SyncManager _manager;

  SyncStatusNotifier(this._manager) : super(const SyncState()) {
    _init();
  }

  void _init() {
    _manager.status.addListener(_onStatusChanged);
    _manager.errorMessage.addListener(_onErrorChanged);
  }

  void _onStatusChanged() {
    state = state.copyWith(
      status: _manager.status.value,
      isSyncing: _manager.status.value == SyncStatus.syncing,
    );
  }

  void _onErrorChanged() {
    state = state.copyWith(
      errorMessage: _manager.errorMessage.value,
    );
  }

  Future<bool> sync() async {
    state = state.copyWith(isSyncing: true, errorMessage: null);
    final result = await _manager.sync();
    state = state.copyWith(
      isSyncing: false,
      lastSyncTime: _manager.config.lastSyncTime,
    );
    return result;
  }

  Future<bool> testConnection() async {
    return await _manager.testConnection();
  }

  @override
  void dispose() {
    _manager.status.removeListener(_onStatusChanged);
    _manager.errorMessage.removeListener(_onErrorChanged);
    super.dispose();
  }
}
