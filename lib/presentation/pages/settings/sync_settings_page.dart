import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/sync/sync.dart';
import '../../providers/sync_providers.dart';

/// 同步设置页面
class SyncSettingsPage extends ConsumerStatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  ConsumerState<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends ConsumerState<SyncSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final syncConfig = ref.watch(syncConfigProvider);
    final syncState = ref.watch(syncStatusProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildSyncStatusCard(syncState),
                      const SizedBox(height: 20),
                      _buildProviderSelector(syncConfig),
                      const SizedBox(height: 20),
                      if (syncConfig.provider != SyncProvider.none) ...[
                        _buildProviderConfig(syncConfig),
                        const SizedBox(height: 20),
                        _buildSyncActions(syncState, syncConfig),
                      ],
                      const SizedBox(height: 20),
                      _buildInfoCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const Expanded(
            child: Text(
              '同步设置',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSyncStatusCard(SyncState syncState) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (syncState.status) {
      case SyncStatus.idle:
        statusColor = Colors.grey;
        statusIcon = Icons.cloud_off_rounded;
        statusText = '未同步';
        break;
      case SyncStatus.syncing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync_rounded;
        statusText = '同步中...';
        break;
      case SyncStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.cloud_done_rounded;
        statusText = '同步成功';
        break;
      case SyncStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.cloud_off_rounded;
        statusText = syncState.errorMessage ?? '同步失败';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: syncState.isSyncing
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: statusColor,
                        ),
                      )
                    : Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    if (syncState.lastSyncTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '上次同步: ${DateFormat('yyyy-MM-dd HH:mm').format(syncState.lastSyncTime!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelector(SyncConfig syncConfig) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cloud_rounded, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '选择同步方式',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...SyncProvider.values.map((provider) => _buildProviderOption(
                provider: provider,
                isSelected: syncConfig.provider == provider,
              )),
        ],
      ),
    );
  }

  Widget _buildProviderOption({
    required SyncProvider provider,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _selectProvider(provider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getProviderIcon(provider),
              color: isSelected ? Colors.green : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                provider.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.green : Colors.grey.shade700,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _getProviderIcon(SyncProvider provider) {
    switch (provider) {
      case SyncProvider.none:
        return Icons.block_rounded;
      case SyncProvider.supabase:
        return Icons.storage_rounded;
      case SyncProvider.webdav:
        return Icons.folder_rounded;
      case SyncProvider.s3:
        return Icons.cloud_rounded;
      case SyncProvider.icloud:
        return Icons.apple_rounded;
    }
  }

  void _selectProvider(SyncProvider provider) {
    ref.read(syncConfigProvider.notifier).updateProvider(provider);
  }

  Widget _buildProviderConfig(SyncConfig syncConfig) {
    switch (syncConfig.provider) {
      case SyncProvider.supabase:
        return _buildSupabaseConfig(syncConfig);
      case SyncProvider.webdav:
        return _buildWebDAVConfig(syncConfig);
      case SyncProvider.s3:
        return _buildS3Config(syncConfig);
      case SyncProvider.icloud:
        return _buildiCloudConfig();
      case SyncProvider.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSupabaseConfig(SyncConfig config) {
    return _ConfigForm(
      title: 'Supabase 配置',
      fields: [
        _ConfigField(
          label: 'Supabase URL',
          hint: 'https://xxx.supabase.co',
          value: config.supabaseUrl,
          onSave: (value) => ref.read(syncConfigProvider.notifier).updateSupabaseConfig(
                url: value,
                anonKey: config.supabaseAnonKey ?? '',
              ),
        ),
        _ConfigField(
          label: 'Anon Key',
          hint: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
          value: config.supabaseAnonKey,
          isSecret: true,
          onSave: (value) => ref.read(syncConfigProvider.notifier).updateSupabaseConfig(
                url: config.supabaseUrl ?? '',
                anonKey: value,
              ),
        ),
      ],
    );
  }

  Widget _buildWebDAVConfig(SyncConfig config) {
    return _ConfigForm(
      title: 'WebDAV 配置',
      fields: [
        _ConfigField(
          label: '服务器地址',
          hint: 'https://nextcloud.example.com/remote.php/dav/files/user/',
          value: config.webdavUrl,
          onSave: (value) => ref.read(syncConfigProvider.notifier).updateWebDAVConfig(
                url: value,
                username: config.webdavUsername ?? '',
                password: config.webdavPassword ?? '',
              ),
        ),
        _ConfigField(
          label: '用户名',
          hint: 'username',
          value: config.webdavUsername,
          onSave: (value) => ref.read(syncConfigProvider.notifier).updateWebDAVConfig(
                url: config.webdavUrl ?? '',
                username: value,
                password: config.webdavPassword ?? '',
              ),
        ),
        _ConfigField(
          label: '密码',
          hint: 'password',
          value: config.webdavPassword,
          isSecret: true,
          onSave: (value) => ref.read(syncConfigProvider.notifier).updateWebDAVConfig(
                url: config.webdavUrl ?? '',
                username: config.webdavUsername ?? '',
                password: value,
              ),
        ),
      ],
    );
  }

  Widget _buildS3Config(SyncConfig config) {
    return _ConfigForm(
      title: 'S3/MinIO 配置',
      fields: [
        _ConfigField(
          label: 'Endpoint',
          hint: 's3.amazonaws.com 或 http://localhost:9000',
          value: config.s3Endpoint,
          onSave: (value) => ref.read(syncConfigProvider.notifier).updateS3Config(
                accessKey: config.s3AccessKey ?? '',
                secretKey: config.s3SecretKey ?? '',
                bucket: config.s3Bucket ?? '',
                endpoint: value,
              ),
        ),
        _ConfigField(
          label: 'Access Key',
          hint: 'access_key',
          value: config.s3AccessKey,
          onSave: (value) => ref.read(syncConfigProvider.notifier).updateS3Config(
                accessKey: value,
                secretKey: config.s3SecretKey ?? '',
                bucket: config.s3Bucket ?? '',
                endpoint: config.s3Endpoint,
              ),
        ),
        _ConfigField(
          label: 'Secret Key',
          hint: 'secret_key',
          value: config.s3SecretKey,
          isSecret: true,
          onSave: (value) => ref.read(syncConfigProvider.notifier).updateS3Config(
                accessKey: config.s3AccessKey ?? '',
                secretKey: value,
                bucket: config.s3Bucket ?? '',
                endpoint: config.s3Endpoint,
              ),
        ),
        _ConfigField(
          label: 'Bucket',
          hint: 'expense-tracker',
          value: config.s3Bucket,
          onSave: (value) => ref.read(syncConfigProvider.notifier).updateS3Config(
                accessKey: config.s3AccessKey ?? '',
                secretKey: config.s3SecretKey ?? '',
                bucket: value,
                endpoint: config.s3Endpoint,
              ),
        ),
      ],
    );
  }

  Widget _buildiCloudConfig() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.apple_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'iCloud 配置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'iCloud 同步使用 iCloud Key-Value 存储，无需额外配置。确保在 iOS 设备上登录了 iCloud 账户。',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncActions(SyncState syncState, SyncConfig config) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sync_rounded, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '同步操作',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.sync_rounded,
                  label: '立即同步',
                  color: Colors.blue,
                  isLoading: syncState.isSyncing,
                  onTap: config.isConfigured ? () => _doSync() : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.wifi_tethering_rounded,
                  label: '测试连接',
                  color: Colors.green,
                  onTap: config.isConfigured ? () => _testConnection() : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _ActionButton(
              icon: Icons.delete_outline_rounded,
              label: '清除同步配置',
              color: Colors.red,
              isOutlined: true,
              onTap: () => _clearConfig(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doSync() async {
    final success = await ref.read(syncStatusProvider.notifier).sync();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '同步成功' : '同步失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    final success = await ref.read(syncStatusProvider.notifier).testConnection();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '连接成功' : '连接失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _clearConfig() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除同步配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(syncConfigProvider.notifier).clearConfig();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配置已清除')),
        );
      }
    }
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '同步说明',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoItem(
            icon: Icons.sync_problem_rounded,
            title: '冲突解决',
            description: '采用最后写入优先策略（last-write-wins）',
          ),
          const SizedBox(height: 12),
          _InfoItem(
            icon: Icons.offline_bolt_rounded,
            title: '离线支持',
            description: '本地数据将保存在设备上，联网后自动同步',
          ),
          const SizedBox(height: 12),
          _InfoItem(
            icon: Icons.security_rounded,
            title: '数据安全',
            description: '敏感数据使用加密传输和存储',
          ),
        ],
      ),
    );
  }
}

class _ConfigForm extends StatelessWidget {
  final String title;
  final List<_ConfigField> fields;

  const _ConfigForm({
    required this.title,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.settings_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...fields.map((field) => _buildField(context, field)),
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, _ConfigField field) {
    final controller = TextEditingController(text: field.value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: field.isSecret,
                  decoration: InputDecoration(
                    hintText: field.hint,
                    hintStyle: TextStyle(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.save_rounded, color: Colors.green),
                onPressed: () {
                  field.onSave(controller.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('保存成功')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfigField {
  final String label;
  final String hint;
  final String? value;
  final bool isSecret;
  final Function(String) onSave;

  const _ConfigField({
    required this.label,
    required this.hint,
    this.value,
    this.isSecret = false,
    required this.onSave,
  });
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isOutlined;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: isOutlined ? Border.all(color: color) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
