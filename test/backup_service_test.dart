import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/core/services/backup_service.dart';
import 'package:ai_expense_tracker/data/models/expense_model.dart';
import 'package:ai_expense_tracker/data/models/budget_model.dart';
import 'package:ai_expense_tracker/data/models/user_settings.dart';

void main() {
  group('BackupService Tests', () {
    late BackupService backupService;

    setUp(() {
      backupService = BackupService();
    });

    group('exportData', () {
      test('should export valid JSON', () async {
        final expenses = [
          Expense(
            id: 'expense-1',
            amount: 100.0,
            description: '午餐',
            category: 'food',
            date: DateTime(2024, 1, 1),
            createdAt: DateTime(2024, 1, 1),
          ),
        ];

        final budgets = [
          Budget(
            id: 'budget-1',
            amount: 5000.0,
            month: 1,
            year: 2024,
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];

        const settings = UserSettings(
          openaiApiKey: 'sk-test',
          useCloudSync: false,
          defaultCurrency: 'CNY',
        );

        final json = await backupService.exportData(
          expenses: expenses,
          budgets: budgets,
          settings: settings,
        );

        // Should be valid JSON
        final data = jsonDecode(json) as Map<String, dynamic>;
        expect(data['version'], isNotNull);
        expect(data['exportDate'], isNotNull);
        expect(data['expenses'], isA<List>());
        expect(data['budgets'], isA<List>());
        expect(data['settings'], isA<Map>());
      });

      test('should export expenses correctly', () async {
        final expenses = [
          Expense(
            id: 'expense-1',
            amount: 50.0,
            description: '测试消费',
            category: 'food',
            date: DateTime(2024, 1, 15),
            createdAt: DateTime(2024, 1, 15),
            isSynced: false,
          ),
        ];

        final json = await backupService.exportData(
          expenses: expenses,
          budgets: [],
          settings: const UserSettings(),
        );

        final data = jsonDecode(json) as Map<String, dynamic>;
        final expensesList = data['expenses'] as List;

        expect(expensesList.length, 1);
        expect(expensesList[0]['id'], 'expense-1');
        expect(expensesList[0]['amount'], 50.0);
        expect(expensesList[0]['description'], '测试消费');
        expect(expensesList[0]['category'], 'food');
      });

      test('should export budgets correctly', () async {
        final budgets = [
          Budget(
            id: 'budget-1',
            amount: 3000.0,
            month: 6,
            year: 2024,
            createdAt: DateTime(2024, 6, 1),
            updatedAt: DateTime(2024, 6, 1),
          ),
        ];

        final json = await backupService.exportData(
          expenses: [],
          budgets: budgets,
          settings: const UserSettings(),
        );

        final data = jsonDecode(json) as Map<String, dynamic>;
        final budgetsList = data['budgets'] as List;

        expect(budgetsList.length, 1);
        expect(budgetsList[0]['id'], 'budget-1');
        expect(budgetsList[0]['amount'], 3000.0);
        expect(budgetsList[0]['month'], 6);
        expect(budgetsList[0]['year'], 2024);
      });

      test('should export settings correctly', () async {
        const settings = UserSettings(
          openaiApiKey: 'sk-openai',
          claudeApiKey: 'sk-claude',
          useCloudSync: true,
          defaultCurrency: 'USD',
          themeMode: ThemeMode.dark,
          locale: 'en',
        );

        final json = await backupService.exportData(
          expenses: [],
          budgets: [],
          settings: settings,
        );

        final data = jsonDecode(json) as Map<String, dynamic>;
        final settingsMap = data['settings'] as Map<String, dynamic>;

        expect(settingsMap['openaiApiKey'], 'sk-openai');
        expect(settingsMap['claudeApiKey'], 'sk-claude');
        expect(settingsMap['useCloudSync'], 1);
        expect(settingsMap['defaultCurrency'], 'USD');
        expect(settingsMap['themeMode'], ThemeMode.dark.index);
        expect(settingsMap['locale'], 'en');
      });

      test('should export empty lists', () async {
        final json = await backupService.exportData(
          expenses: [],
          budgets: [],
          settings: const UserSettings(),
        );

        final data = jsonDecode(json) as Map<String, dynamic>;
        expect(data['expenses'], isEmpty);
        expect(data['budgets'], isEmpty);
      });
    });

    group('importData', () {
      test('should import valid data', () async {
        final exportJson = '''
        {
          "version": "1.0.0",
          "exportDate": "2024-01-01T00:00:00.000",
          "expenses": [
            {
              "id": "expense-1",
              "amount": 100.0,
              "description": "测试",
              "category": "food",
              "date": 1704067200000,
              "createdAt": 1704067200000,
              "isSynced": 0
            }
          ],
          "budgets": [
            {
              "id": "budget-1",
              "amount": 5000.0,
              "month": 1,
              "year": 2024,
              "createdAt": 1704067200000,
              "updatedAt": 1704067200000
            }
          ],
          "settings": {
            "openaiApiKey": "sk-test",
            "useCloudSync": 0,
            "defaultCurrency": "CNY",
            "themeMode": 0,
            "locale": "zh"
          }
        }
        ''';

        final backupData = await backupService.importData(exportJson);

        expect(backupData.expenses.length, 1);
        expect(backupData.budgets.length, 1);
        expect(backupData.settings.openaiApiKey, 'sk-test');
        expect(backupData.version, '1.0.0');
      });

      test('should throw on invalid JSON format', () async {
        expect(
          () => backupService.importData('not valid json'),
          throwsA(isA<BackupException>()),
        );
      });

      test('should throw on missing required fields', () async {
        final invalidJson = '{"version": "1.0.0", "expenses": []}';

        expect(
          () => backupService.importData(invalidJson),
          throwsA(isA<BackupException>()),
        );
      });

      test('should throw on incompatible version', () async {
        final incompatibleJson = '''
        {
          "version": "2.0.0",
          "expenses": [],
          "budgets": [],
          "settings": {}
        }
        ''';

        expect(
          () => backupService.importData(incompatibleJson),
          throwsA(isA<BackupException>()),
        );
      });

      test('should handle compatible minor version', () async {
        final json = '''
        {
          "version": "1.5.0",
          "expenses": [],
          "budgets": [],
          "settings": {}
        }
        ''';

        final backupData = await backupService.importData(json);
        expect(backupData.version, '1.5.0');
      });

      test('should validate expense data - missing required fields', () async {
        final invalidJson = '''
        {
          "version": "1.0.0",
          "expenses": [{"id": "exp1"}],
          "budgets": [],
          "settings": {}
        }
        ''';

        expect(
          () => backupService.importData(invalidJson),
          throwsA(isA<BackupException>()),
        );
      });

      test('should validate expense data - invalid amount type', () async {
        final invalidJson = '''
        {
          "version": "1.0.0",
          "expenses": [{"id": "exp1", "amount": "not a number", "description": "test", "category": "food", "date": 1704067200000, "createdAt": 1704067200000}],
          "budgets": [],
          "settings": {}
        }
        ''';

        expect(
          () => backupService.importData(invalidJson),
          throwsA(isA<BackupException>()),
        );
      });

      test('should validate expense data - invalid amount range', () async {
        final invalidJson = '''
        {
          "version": "1.0.0",
          "expenses": [{"id": "exp1", "amount": -100, "description": "test", "category": "food", "date": 1704067200000, "createdAt": 1704067200000}],
          "budgets": [],
          "settings": {}
        }
        ''';

        expect(
          () => backupService.importData(invalidJson),
          throwsA(isA<BackupException>()),
        );
      });

      test('should validate budget data - missing required fields', () async {
        final invalidJson = '''
        {
          "version": "1.0.0",
          "expenses": [],
          "budgets": [{"id": "budget1"}],
          "settings": {}
        }
        ''';

        expect(
          () => backupService.importData(invalidJson),
          throwsA(isA<BackupException>()),
        );
      });

      test('should validate budget data - invalid month range', () async {
        final invalidJson = '''
        {
          "version": "1.0.0",
          "expenses": [],
          "budgets": [{"id": "budget1", "amount": 1000, "month": 13, "year": 2024, "createdAt": 1704067200000, "updatedAt": 1704067200000}],
          "settings": {}
        }
        ''';

        expect(
          () => backupService.importData(invalidJson),
          throwsA(isA<BackupException>()),
        );
      });

      test('should validate budget data - invalid year range', () async {
        final invalidJson = '''
        {
          "version": "1.0.0",
          "expenses": [],
          "budgets": [{"id": "budget1", "amount": 1000, "month": 6, "year": 1999, "createdAt": 1704067200000, "updatedAt": 1704067200000}],
          "settings": {}
        }
        ''';

        expect(
          () => backupService.importData(invalidJson),
          throwsA(isA<BackupException>()),
        );
      });

      test('should throw on invalid date timestamp', () async {
        final invalidJson = '''
        {
          "version": "1.0.0",
          "expenses": [{"id": "exp1", "amount": 100, "description": "test", "category": "food", "date": "not a timestamp", "createdAt": 1704067200000}],
          "budgets": [],
          "settings": {}
        }
        ''';

        expect(
          () => backupService.importData(invalidJson),
          throwsA(isA<BackupException>()),
        );
      });
    });

    group('BackupData', () {
      test('BackupData totalExpenses returns correct count', () {
        final backupData = BackupData(
          expenses: [
            Expense(
              id: '1',
              amount: 100,
              description: 'test',
              category: 'food',
              date: DateTime.now(),
            ),
            Expense(
              id: '2',
              amount: 200,
              description: 'test2',
              category: 'transport',
              date: DateTime.now(),
            ),
          ],
          budgets: [],
          settings: const UserSettings(),
          version: '1.0.0',
        );

        expect(backupData.totalExpenses, 2);
      });

      test('BackupData totalBudgets returns correct count', () {
        final backupData = BackupData(
          expenses: [],
          budgets: [
            Budget(amount: 1000, month: 1, year: 2024),
            Budget(amount: 2000, month: 2, year: 2024),
            Budget(amount: 3000, month: 3, year: 2024),
          ],
          settings: const UserSettings(),
          version: '1.0.0',
        );

        expect(backupData.totalBudgets, 3);
      });

      test('BackupData handles empty lists', () {
        final backupData = BackupData(
          expenses: [],
          budgets: [],
          settings: const UserSettings(),
          version: '1.0.0',
        );

        expect(backupData.totalExpenses, 0);
        expect(backupData.totalBudgets, 0);
      });
    });

    group('BackupException', () {
      test('BackupException toString returns formatted message', () {
        const exception = BackupException('Test error message');
        expect(exception.toString(), 'BackupException: Test error message');
      });

      test('BackupException can be thrown and caught', () {
        try {
          throw const BackupException('Test exception');
        } on BackupException catch (e) {
          expect(e.message, 'Test exception');
        }
      });
    });

    group('Version Compatibility', () {
      test('should accept version 1.0.0', () async {
        final json = '''
        {
          "version": "1.0.0",
          "expenses": [],
          "budgets": [],
          "settings": {}
        }
        ''';

        final backupData = await backupService.importData(json);
        expect(backupData.version, '1.0.0');
      });

      test('should accept version 1.1.0', () async {
        final json = '''
        {
          "version": "1.1.0",
          "expenses": [],
          "budgets": [],
          "settings": {}
        }
        ''';

        final backupData = await backupService.importData(json);
        expect(backupData.version, '1.1.0');
      });

      test('should reject version 0.9.0', () async {
        final json = '''
        {
          "version": "0.9.0",
          "expenses": [],
          "budgets": [],
          "settings": {}
        }
        ''';

        expect(
          () => backupService.importData(json),
          throwsA(isA<BackupException>()),
        );
      });

      test('should reject empty version', () async {
        final json = '''
        {
          "version": "",
          "expenses": [],
          "budgets": [],
          "settings": {}
        }
        ''';

        expect(
          () => backupService.importData(json),
          throwsA(isA<BackupException>()),
        );
      });
    });

    group('Round-trip', () {
      test('should export and import data correctly', () async {
        final originalExpenses = [
          Expense(
            id: 'exp-1',
            amount: 100.0,
            description: '午餐',
            category: 'food',
            date: DateTime(2024, 1, 1),
            createdAt: DateTime(2024, 1, 1),
            isSynced: false,
          ),
          Expense(
            id: 'exp-2',
            amount: 50.0,
            description: '打车',
            category: 'transport',
            date: DateTime(2024, 1, 2),
            createdAt: DateTime(2024, 1, 2),
            isSynced: true,
          ),
        ];

        final originalBudgets = [
          Budget(
            id: 'budget-1',
            amount: 5000.0,
            month: 1,
            year: 2024,
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];

        const originalSettings = UserSettings(
          openaiApiKey: 'sk-test-key',
          useCloudSync: true,
          defaultCurrency: 'USD',
          themeMode: ThemeMode.dark,
        );

        // Export
        final json = await backupService.exportData(
          expenses: originalExpenses,
          budgets: originalBudgets,
          settings: originalSettings,
        );

        // Import
        final importedData = await backupService.importData(json);

        // Verify
        expect(importedData.expenses.length, 2);
        expect(importedData.budgets.length, 1);
        expect(importedData.settings.openaiApiKey, originalSettings.openaiApiKey);
        expect(importedData.settings.useCloudSync, originalSettings.useCloudSync);
        expect(importedData.settings.defaultCurrency, originalSettings.defaultCurrency);
        expect(importedData.settings.themeMode, originalSettings.themeMode);
      });
    });
  });
}
