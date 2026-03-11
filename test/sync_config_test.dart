import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/core/services/sync/sync_config.dart';

void main() {
  group('SyncProvider Tests', () {
    test('SyncProvider values are correct', () {
      expect(SyncProvider.none.id, 'none');
      expect(SyncProvider.none.displayName, '无');

      expect(SyncProvider.supabase.id, 'supabase');
      expect(SyncProvider.supabase.displayName, 'Supabase');

      expect(SyncProvider.webdav.id, 'webdav');
      expect(SyncProvider.webdav.displayName, 'WebDAV');

      expect(SyncProvider.s3.id, 's3');
      expect(SyncProvider.s3.displayName, 'S3/MinIO');

      expect(SyncProvider.icloud.id, 'icloud');
      expect(SyncProvider.icloud.displayName, 'iCloud');
    });

    test('SyncProvider fromId returns correct type', () {
      expect(SyncProvider.fromId('none'), SyncProvider.none);
      expect(SyncProvider.fromId('supabase'), SyncProvider.supabase);
      expect(SyncProvider.fromId('webdav'), SyncProvider.webdav);
      expect(SyncProvider.fromId('s3'), SyncProvider.s3);
      expect(SyncProvider.fromId('icloud'), SyncProvider.icloud);
    });

    test('SyncProvider fromId returns none for unknown id', () {
      expect(SyncProvider.fromId('unknown'), SyncProvider.none);
      expect(SyncProvider.fromId(''), SyncProvider.none);
      expect(SyncProvider.fromId('invalid_provider'), SyncProvider.none);
    });

    test('SyncProvider values length is correct', () {
      expect(SyncProvider.values.length, 5);
    });
  });

  group('SyncStatus Tests', () {
    test('SyncStatus values are correct', () {
      expect(SyncStatus.idle.id, 'idle');
      expect(SyncStatus.idle.displayName, '空闲');

      expect(SyncStatus.syncing.id, 'syncing');
      expect(SyncStatus.syncing.displayName, '同步中');

      expect(SyncStatus.success.id, 'success');
      expect(SyncStatus.success.displayName, '同步成功');

      expect(SyncStatus.error.id, 'error');
      expect(SyncStatus.error.displayName, '同步失败');
    });

    test('SyncStatus fromId returns correct type', () {
      expect(SyncStatus.fromId('idle'), SyncStatus.idle);
      expect(SyncStatus.fromId('syncing'), SyncStatus.syncing);
      expect(SyncStatus.fromId('success'), SyncStatus.success);
      expect(SyncStatus.fromId('error'), SyncStatus.error);
    });

    test('SyncStatus fromId returns idle for unknown id', () {
      expect(SyncStatus.fromId('unknown'), SyncStatus.idle);
      expect(SyncStatus.fromId(''), SyncStatus.idle);
    });
  });

  group('SyncConfig Tests', () {
    test('SyncConfig can be created with required fields', () {
      final config = SyncConfig(
        provider: SyncProvider.supabase,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'test-key',
      );

      expect(config.provider, SyncProvider.supabase);
      expect(config.supabaseUrl, 'https://example.supabase.co');
      expect(config.supabaseAnonKey, 'test-key');
      expect(config.status, SyncStatus.idle);
      expect(config.lastSyncTime, isNull);
      expect(config.errorMessage, isNull);
    });

    test('SyncConfig can be created with default values', () {
      const config = SyncConfig();

      expect(config.provider, SyncProvider.none);
      expect(config.status, SyncStatus.idle);
      expect(config.lastSyncTime, isNull);
      expect(config.errorMessage, isNull);
      expect(config.supabaseUrl, isNull);
      expect(config.supabaseAnonKey, isNull);
    });

    test('SyncConfig copyWith works correctly', () {
      final original = SyncConfig(
        provider: SyncProvider.supabase,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'test-key',
      );

      final updated = original.copyWith(
        status: SyncStatus.success,
        lastSyncTime: DateTime(2024, 1, 1),
      );

      // Original unchanged
      expect(original.status, SyncStatus.idle);
      expect(original.lastSyncTime, isNull);

      // Updated has new values
      expect(updated.provider, SyncProvider.supabase);
      expect(updated.supabaseUrl, 'https://example.supabase.co');
      expect(updated.status, SyncStatus.success);
      expect(updated.lastSyncTime, DateTime(2024, 1, 1));
    });

    test('SyncConfig copyWith preserves original values when not specified', () {
      final original = SyncConfig(
        provider: SyncProvider.webdav,
        webdavUrl: 'https://webdav.example.com',
        webdavUsername: 'user',
        webdavPassword: 'password',
      );

      final updated = original.copyWith(errorMessage: 'Error occurred');

      expect(updated.provider, SyncProvider.webdav);
      expect(updated.webdavUrl, 'https://webdav.example.com');
      expect(updated.webdavUsername, 'user');
      expect(updated.webdavPassword, 'password');
      expect(updated.errorMessage, 'Error occurred');
    });

    test('SyncConfig copyWith with null errorMessage clears error', () {
      final original = SyncConfig(
        errorMessage: 'Previous error',
      );

      final updated = original.copyWith(errorMessage: null);

      expect(original.errorMessage, 'Previous error');
      expect(updated.errorMessage, isNull);
    });

    test('SyncConfig toMap and fromMap works correctly', () {
      final original = SyncConfig(
        provider: SyncProvider.s3,
        status: SyncStatus.success,
        s3AccessKey: 'access-key',
        s3SecretKey: 'secret-key',
        s3Bucket: 'test-bucket',
        s3Endpoint: 'https://s3.example.com',
        s3UseSsl: true,
        s3Region: 'us-east-1',
      );

      final map = original.toMap();
      final restored = SyncConfig.fromMap(map);

      expect(restored.provider, original.provider);
      expect(restored.status, original.status);
      expect(restored.s3AccessKey, original.s3AccessKey);
      expect(restored.s3SecretKey, original.s3SecretKey);
      expect(restored.s3Bucket, original.s3Bucket);
      expect(restored.s3Endpoint, original.s3Endpoint);
      expect(restored.s3UseSsl, original.s3UseSsl);
      expect(restored.s3Region, original.s3Region);
    });

    test('SyncConfig isConfigured returns correct value for none provider', () {
      const config = SyncConfig(provider: SyncProvider.none);
      expect(config.isConfigured, false);
    });

    test('SyncConfig isConfigured returns correct value for supabase', () {
      const configNotConfigured = SyncConfig(
        provider: SyncProvider.supabase,
        supabaseUrl: null,
        supabaseAnonKey: null,
      );
      expect(configNotConfigured.isConfigured, false);

      const configPartial = SyncConfig(
        provider: SyncProvider.supabase,
        supabaseUrl: 'https://example.supabase.co',
      );
      expect(configPartial.isConfigured, false);

      const configFull = SyncConfig(
        provider: SyncProvider.supabase,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'test-key',
      );
      expect(configFull.isConfigured, true);
    });

    test('SyncConfig isConfigured returns correct value for webdav', () {
      const configNotConfigured = SyncConfig(
        provider: SyncProvider.webdav,
        webdavUrl: null,
      );
      expect(configNotConfigured.isConfigured, false);

      const configPartial = SyncConfig(
        provider: SyncProvider.webdav,
        webdavUrl: 'https://webdav.example.com',
      );
      expect(configPartial.isConfigured, false);

      const configFull = SyncConfig(
        provider: SyncProvider.webdav,
        webdavUrl: 'https://webdav.example.com',
        webdavUsername: 'user',
        webdavPassword: 'password',
      );
      expect(configFull.isConfigured, true);
    });

    test('SyncConfig isConfigured returns correct value for s3', () {
      const configNotConfigured = SyncConfig(
        provider: SyncProvider.s3,
      );
      expect(configNotConfigured.isConfigured, false);

      const configPartial = SyncConfig(
        provider: SyncProvider.s3,
        s3AccessKey: 'access-key',
      );
      expect(configPartial.isConfigured, false);

      const configFull = SyncConfig(
        provider: SyncProvider.s3,
        s3AccessKey: 'access-key',
        s3SecretKey: 'secret-key',
        s3Bucket: 'test-bucket',
      );
      expect(configFull.isConfigured, true);
    });

    test('SyncConfig isConfigured returns true for icloud', () {
      const config = SyncConfig(provider: SyncProvider.icloud);
      expect(config.isConfigured, true);
    });

    test('SyncConfig isValidUrl validates URLs correctly', () {
      // Valid URLs
      expect(SyncConfig.isValidUrl('https://example.com'), true);
      expect(SyncConfig.isValidUrl('http://example.com'), true);
      expect(SyncConfig.isValidUrl('https://example.com/path'), true);
      expect(SyncConfig.isValidUrl('https://example.com:8080'), true);

      // Invalid URLs
      expect(SyncConfig.isValidUrl(null), false);
      expect(SyncConfig.isValidUrl(''), false);
      expect(SyncConfig.isValidUrl('ftp://example.com'), false); // Not http/https
      expect(SyncConfig.isValidUrl('example.com'), false); // No scheme
      expect(SyncConfig.isValidUrl('https://'), false); // No host
      expect(SyncConfig.isValidUrl('https://exam\r\nple.com'), false); // CRLF injection
    });
  });

  group('SyncData Tests', () {
    test('SyncData can be created with required fields', () {
      final timestamp = DateTime.now();
      final syncData = SyncData(
        expenses: [],
        budgets: [],
        timestamp: timestamp,
      );

      expect(syncData.expenses, isEmpty);
      expect(syncData.budgets, isEmpty);
      expect(syncData.settings, isNull);
      expect(syncData.timestamp, timestamp);
    });

    test('SyncData toJson and fromJson works correctly', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final original = SyncData(
        expenses: [
          {'id': 'exp1', 'amount': 100.0},
        ],
        budgets: [
          {'id': 'budget1', 'amount': 500.0},
        ],
        settings: {'theme': 'dark'},
        timestamp: timestamp,
      );

      final json = original.toJson();
      final restored = SyncData.fromJson(json);

      expect(restored.expenses.length, 1);
      expect(restored.expenses[0]['id'], 'exp1');
      expect(restored.budgets.length, 1);
      expect(restored.budgets[0]['id'], 'budget1');
      expect(restored.settings?['theme'], 'dark');
    });

    test('SyncData fromJson handles null values', () {
      final json = <String, dynamic>{
        'expenses': null,
        'budgets': null,
        'settings': null,
        'timestamp': null,
      };

      final syncData = SyncData.fromJson(json);

      expect(syncData.expenses, isEmpty);
      expect(syncData.budgets, isEmpty);
      expect(syncData.settings, isNull);
      expect(syncData.timestamp, isNotNull); // Defaults to now
    });
  });
}
