import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/core/services/sync/sync_config.dart';
import 'package:ai_expense_tracker/core/services/sync/sync_service.dart';

void main() {
  group('SyncService Interface Tests', () {
    test('SyncService interface can be implemented', () {
      // Create a mock implementation of SyncService
      final mockService = MockSyncService();

      expect(mockService, isA<SyncService>());
      expect(mockService.providerName, 'MockService');
    });

    test('SyncService sync method signature is correct', () async {
      final mockService = MockSyncService();

      // Mock service should implement sync() -> Future<bool>
      final result = mockService.sync();

      expect(result, isA<Future<bool>>());
    });

    test('SyncService pull method signature is correct', () async {
      final mockService = MockSyncService();

      // Mock service should implement pull() -> Future<SyncData?>
      final result = mockService.pull();

      expect(result, isA<Future<SyncData?>>());
    });

    test('SyncService push method signature is correct', () async {
      final mockService = MockSyncService();

      final testData = SyncData(
        expenses: [],
        budgets: [],
        timestamp: DateTime.now(),
      );

      // Mock service should implement push(SyncData) -> Future<bool>
      final result = mockService.push(testData);

      expect(result, isA<Future<bool>>());
    });

    test('SyncService initialize method signature is correct', () async {
      final mockService = MockSyncService();

      const testConfig = SyncConfig(
        provider: SyncProvider.supabase,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'test-key',
      );

      // Mock service should implement initialize(SyncConfig) -> Future<void>
      final result = mockService.initialize(testConfig);

      expect(result, isA<Future<void>>());
    });

    test('SyncService isConfigured getter exists', () {
      final mockService = MockSyncService();

      expect(mockService.isConfigured, isA<bool>());
    });

    test('SyncService testConnection method signature is correct', () async {
      final mockService = MockSyncService();

      // Mock service should implement testConnection() -> Future<bool>
      final result = mockService.testConnection();

      expect(result, isA<Future<bool>>());
    });

    test('SyncService dispose method signature is correct', () async {
      final mockService = MockSyncService();

      // Mock service should implement dispose() -> Future<void>
      final result = mockService.dispose();

      expect(result, isA<Future<void>>());
    });
  });

  group('SyncService Contract Tests', () {
    test('SyncService contract - initialize before sync', () async {
      final mockService = MockSyncService();

      // Should be able to initialize
      await mockService.initialize(const SyncConfig(
        provider: SyncProvider.none,
      ));

      // After initialize, service should be ready
      expect(mockService.isConfigured, false); // none provider is not configured
    });

    test('SyncService contract - pull returns null when no data', () async {
      final mockService = MockSyncService();

      await mockService.initialize(const SyncConfig(
        provider: SyncProvider.none,
      ));

      final data = await mockService.pull();

      // Mock returns null for no data
      expect(data, isNull);
    });

    test('SyncService contract - push with empty data', () async {
      final mockService = MockSyncService();

      await mockService.initialize(const SyncConfig(
        provider: SyncProvider.none,
      ));

      final emptyData = SyncData(
        expenses: [],
        budgets: [],
        timestamp: DateTime.now(),
      );

      final result = await mockService.push(emptyData);

      // Mock always returns true
      expect(result, true);
    });

    test('SyncService contract - testConnection returns false for none', () async {
      final mockService = MockSyncService();

      await mockService.initialize(const SyncConfig(
        provider: SyncProvider.none,
      ));

      final result = await mockService.testConnection();

      // Mock returns false for none provider
      expect(result, false);
    });

    test('SyncService contract - dispose cleans up resources', () async {
      final mockService = MockSyncService();

      await mockService.initialize(const SyncConfig(
        provider: SyncProvider.none,
      ));

      // Should not throw
      await mockService.dispose();

      // After dispose, service is no longer "configured" in mock
      expect(mockService.isDisposed, true);
    });
  });
}

/// Mock implementation of SyncService for testing
class MockSyncService implements SyncService {
  @override
  String get providerName => 'MockService';

  bool _isConfigured = false;
  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  @override
  bool get isConfigured => _isConfigured;

  @override
  Future<void> initialize(SyncConfig config) async {
    _isConfigured = config.isConfigured;
  }

  @override
  Future<bool> sync() async {
    return true;
  }

  @override
  Future<SyncData?> pull() async {
    return null;
  }

  @override
  Future<bool> push(SyncData data) async {
    return true;
  }

  @override
  Future<bool> testConnection() async {
    return false;
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    _isConfigured = false;
  }
}
