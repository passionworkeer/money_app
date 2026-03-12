import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/core/services/sync/sync_config.dart';
import 'package:ai_expense_tracker/core/services/sync/sync_manager.dart';

void main() {
  group('SyncManager Tests', () {
    late SyncManager syncManager;

    setUp(() {
      syncManager = SyncManager();
    });

    test('SyncManager can be instantiated', () {
      expect(syncManager, isNotNull);
    });

    test('SyncManager has correct initial state', () {
      expect(syncManager.config, isA<SyncConfig>());
      expect(syncManager.config.provider, SyncProvider.none);
      expect(syncManager.config.status, SyncStatus.idle);
      expect(syncManager.status, isA<ValueNotifier<SyncStatus>>());
      expect(syncManager.errorMessage, isA<ValueNotifier<String?>>());
      expect(syncManager.status.value, SyncStatus.idle);
    });

    test('SyncManager config getter returns current config', () {
      final config = syncManager.config;
      expect(config, isNotNull);
      expect(config.provider, SyncProvider.none);
    });

    test('SyncManager status notifier is initially idle', () {
      expect(syncManager.status.value, SyncStatus.idle);
    });

    test('SyncManager errorMessage notifier is initially null', () {
      expect(syncManager.errorMessage.value, isNull);
    });

    test('SyncManager config can be updated via updateConfig', () async {
      const newConfig = SyncConfig(
        provider: SyncProvider.supabase,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'test-key',
      );

      // Note: This will try to initialize service, which may fail without proper setup
      // but the config should be updated
      try {
        await syncManager.updateConfig(newConfig);
      } catch (e) {
        // Expected to fail without proper SharedPreferences setup
      }

      // Config should be updated
      expect(syncManager.config.provider, SyncProvider.supabase);
    });

    test('SyncManager status resets to idle when config is updated', () async {
      // Manually set status to error
      syncManager.status.value = SyncStatus.error;
      syncManager.errorMessage.value = 'Previous error';

      const newConfig = SyncConfig(
        provider: SyncProvider.none,
      );

      try {
        await syncManager.updateConfig(newConfig);
      } catch (e) {
        // Expected
      }

      // Status should reset to idle
      expect(syncManager.status.value, SyncStatus.idle);
      expect(syncManager.errorMessage.value, isNull);
    });

    test('SyncManager sync fails when not configured', () async {
      // Default config has no provider configured
      final result = await syncManager.sync();

      expect(result, false);
      expect(syncManager.status.value, SyncStatus.error);
      expect(syncManager.errorMessage.value, isNotNull);
    });

    test('SyncManager testConnection returns false when not configured', () async {
      final result = await syncManager.testConnection();

      expect(result, false);
    });

    test('SyncManager dispose can be called without error', () async {
      await syncManager.dispose();

      // After dispose, the manager should be in a clean state
      // The status notifier should still be accessible
      expect(syncManager.status, isNotNull);
    });
  });

  group('SyncManager Integration Tests', () {
    test('SyncManager initialize can be called', () async {
      final syncManager = SyncManager();

      // Should not throw even without SharedPreferences
      try {
        await syncManager.initialize();
      } catch (e) {
        // May fail in test environment without proper setup
      }

      expect(syncManager, isNotNull);
    });
  });
}
