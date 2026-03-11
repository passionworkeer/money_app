/// 同步提供商类型枚举
enum SyncProvider {
  none('none', '无'),
  supabase('supabase', 'Supabase'),
  webdav('webdav', 'WebDAV'),
  s3('s3', 'S3/MinIO'),
  icloud('icloud', 'iCloud');

  final String id;
  final String displayName;

  const SyncProvider(this.id, this.displayName);

  static SyncProvider fromId(String id) {
    return SyncProvider.values.firstWhere(
      (p) => p.id == id,
      orElse: () => SyncProvider.none,
    );
  }
}

/// 同步状态
enum SyncStatus {
  idle('idle', '空闲'),
  syncing('syncing', '同步中'),
  success('success', '同步成功'),
  error('error', '同步失败');

  final String id;
  final String displayName;

  const SyncStatus(this.id, this.displayName);

  static SyncStatus fromId(String id) {
    return SyncStatus.values.firstWhere(
      (s) => s.id == id,
      orElse: () => SyncStatus.idle,
    );
  }
}

/// 同步配置模型
class SyncConfig {
  final SyncProvider provider;
  final DateTime? lastSyncTime;
  final SyncStatus status;
  final String? errorMessage;

  // Supabase 配置
  final String? supabaseUrl;
  final String? supabaseAnonKey;

  // WebDAV 配置
  final String? webdavUrl;
  final String? webdavUsername;
  final String? webdavPassword;

  // S3 配置
  final String? s3AccessKey;
  final String? s3SecretKey;
  final String? s3Bucket;
  final String? s3Endpoint;
  final bool? s3UseSsl;
  final String? s3Region; // 新增：S3 Region 配置

  const SyncConfig({
    this.provider = SyncProvider.none,
    this.lastSyncTime,
    this.status = SyncStatus.idle,
    this.errorMessage,
    this.supabaseUrl,
    this.supabaseAnonKey,
    this.webdavUrl,
    this.webdavUsername,
    this.webdavPassword,
    this.s3AccessKey,
    this.s3SecretKey,
    this.s3Bucket,
    this.s3Endpoint,
    this.s3UseSsl,
    this.s3Region,
  });

  SyncConfig copyWith({
    SyncProvider? provider,
    DateTime? lastSyncTime,
    SyncStatus? status,
    String? errorMessage,
    String? supabaseUrl,
    String? supabaseAnonKey,
    String? webdavUrl,
    String? webdavUsername,
    String? webdavPassword,
    String? s3AccessKey,
    String? s3SecretKey,
    String? s3Bucket,
    String? s3Endpoint,
    bool? s3UseSsl,
    String? s3Region,
  }) {
    return SyncConfig(
      provider: provider ?? this.provider,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      status: status ?? this.status,
      errorMessage: errorMessage,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      supabaseAnonKey: supabaseAnonKey ?? this.supabaseAnonKey,
      webdavUrl: webdavUrl ?? this.webdavUrl,
      webdavUsername: webdavUsername ?? this.webdavUsername,
      webdavPassword: webdavPassword ?? this.webdavPassword,
      s3AccessKey: s3AccessKey ?? this.s3AccessKey,
      s3SecretKey: s3SecretKey ?? this.s3SecretKey,
      s3Bucket: s3Bucket ?? this.s3Bucket,
      s3Endpoint: s3Endpoint ?? this.s3Endpoint,
      s3UseSsl: s3UseSsl ?? this.s3UseSsl,
      s3Region: s3Region ?? this.s3Region,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider.id,
      'lastSyncTime': lastSyncTime?.millisecondsSinceEpoch,
      'status': status.id,
      'supabaseUrl': supabaseUrl,
      'supabaseAnonKey': supabaseAnonKey,
      'webdavUrl': webdavUrl,
      'webdavUsername': webdavUsername,
      'webdavPassword': webdavPassword,
      's3AccessKey': s3AccessKey,
      's3SecretKey': s3SecretKey,
      's3Bucket': s3Bucket,
      's3Endpoint': s3Endpoint,
      's3UseSsl': s3UseSsl ?? true,
      's3Region': s3Region,
    };
  }

  factory SyncConfig.fromMap(Map<String, dynamic> map) {
    return SyncConfig(
      provider: SyncProvider.fromId(map['provider'] as String? ?? 'none'),
      lastSyncTime: map['lastSyncTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSyncTime'] as int)
          : null,
      status: SyncStatus.fromId(map['status'] as String? ?? 'idle'),
      supabaseUrl: map['supabaseUrl'] as String?,
      supabaseAnonKey: map['supabaseAnonKey'] as String?,
      webdavUrl: map['webdavUrl'] as String?,
      webdavUsername: map['webdavUsername'] as String?,
      webdavPassword: map['webdavPassword'] as String?,
      s3AccessKey: map['s3AccessKey'] as String?,
      s3SecretKey: map['s3SecretKey'] as String?,
      s3Bucket: map['s3Bucket'] as String?,
      s3Endpoint: map['s3Endpoint'] as String?,
      s3UseSsl: map['s3UseSsl'] as bool? ?? true,
      s3Region: map['s3Region'] as String?,
    );
  }

  /// 验证配置是否有效
  bool get isConfigured {
    switch (provider) {
      case SyncProvider.none:
        return false;
      case SyncProvider.supabase:
        return supabaseUrl != null &&
            supabaseUrl!.isNotEmpty &&
            supabaseAnonKey != null &&
            supabaseAnonKey!.isNotEmpty;
      case SyncProvider.webdav:
        return webdavUrl != null &&
            webdavUrl!.isNotEmpty &&
            webdavUsername != null &&
            webdavUsername!.isNotEmpty;
      case SyncProvider.s3:
        return s3AccessKey != null &&
            s3AccessKey!.isNotEmpty &&
            s3SecretKey != null &&
            s3SecretKey!.isNotEmpty &&
            s3Bucket != null &&
            s3Bucket!.isNotEmpty;
      case SyncProvider.icloud:
        return true; // iCloud 不需要额外配置
    }
  }

  /// 验证 URL 格式
  ///
  /// SECURITY: 验证 URL 格式以防止注入攻击和配置错误
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      // 必须有 scheme 和 host
      if (!uri.hasScheme || !uri.hasAuthority) return false;
      // scheme 必须是 http 或 https
      if (uri.scheme != 'http' && uri.scheme != 'https') return false;
      // host 不能是空字符串
      if (uri.host.isEmpty) return false;
      // 防止 CRLF 注入
      if (url.contains('\r') || url.contains('\n')) return false;
      return true;
    } catch (e) {
      return false;
    }
  }
}
