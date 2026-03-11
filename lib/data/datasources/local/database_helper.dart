import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/expense_model.dart';
import '../../models/budget_model.dart';
import '../../models/user_settings.dart';
import '../../models/automation_rule.dart';

/// API Key helper for simple obfuscation (NOT secure encryption)
///
/// WARNING: This is basic obfuscation only, NOT real encryption.
/// The reverse+base64 approach can be easily reversed by attackers.
/// This provides minimal protection against casual inspection only.
///
/// LIMITATIONS:
/// - String reversal is trivially reversible
/// - Base64 encoding provides no security (just encoding)
/// - Keys are stored in SQLite database which may be accessible
///   with device root access
///
/// RECOMMENDED FOR PRODUCTION:
/// Use flutter_secure_storage package for encrypted storage:
/// - flutter_secure_storage uses Keychain (iOS) / Keystore (Android)
/// - Provides hardware-backed encryption when available
/// - Keys are encrypted with AES-256
///
/// Example migration:
/// ```dart
/// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
///
/// final storage = FlutterSecureStorage(
///   aOptions: AndroidOptions(encryptedSharedPreferences: true),
///   iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
/// );
///
/// // Store
/// await storage.write(key: 'openai_api_key', value: apiKey);
///
/// // Retrieve
/// final apiKey = await storage.read(key: 'openai_api_key');
/// ```
class ApiKeyHelper {
  /// Encodes an API key using simple reversal + base64 encoding
  static String encode(String? key) {
    if (key == null || key.isEmpty) return '';
    final reversed = key.split('').reversed.join();
    return base64Encode(utf8.encode(reversed));
  }

  /// Decodes an API key that was encoded with [encode]
  static String? decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final decoded = utf8.decode(base64Decode(encoded));
      return decoded.split('').reversed.join();
    } catch (e) {
      return null;
    }
  }
}

class DatabaseHelper {
  static const String _databaseName = 'ai_expense_tracker.db';
  static const int _databaseVersion = 4;
  static const int defaultSettingsId = 1;

  static Database? _database;

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        date INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        openaiApiKey TEXT,
        claudeApiKey TEXT,
        ernieApiKey TEXT,
        qwenApiKey TEXT,
        sparkApiKey TEXT,
        hunyuanApiKey TEXT,
        zhipuApiKey TEXT,
        preferredModel TEXT,
        useCloudSync INTEGER NOT NULL DEFAULT 0,
        defaultCurrency TEXT NOT NULL DEFAULT 'CNY',
        themeMode INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insert default settings
    await db.insert('settings', {
      'id': defaultSettingsId,
      'useCloudSync': 0,
      'defaultCurrency': 'CNY',
      'themeMode': 0,
    });

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE automation_rules (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        triggerType TEXT NOT NULL,
        actionType TEXT NOT NULL,
        config TEXT NOT NULL,
        isEnabled INTEGER NOT NULL DEFAULT 1,
        lastTriggered INTEGER,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new API key columns for version 2
      await db.execute('ALTER TABLE settings ADD COLUMN ernieApiKey TEXT');
      await db.execute('ALTER TABLE settings ADD COLUMN qwenApiKey TEXT');
      await db.execute('ALTER TABLE settings ADD COLUMN sparkApiKey TEXT');
      await db.execute('ALTER TABLE settings ADD COLUMN hunyuanApiKey TEXT');
      await db.execute('ALTER TABLE settings ADD COLUMN zhipuApiKey TEXT');
      await db.execute('ALTER TABLE settings ADD COLUMN preferredModel TEXT');
    }
    if (oldVersion < 3) {
      // Add updatedAt column for version 3 (sync support)
      await db.execute('ALTER TABLE expenses ADD COLUMN updatedAt INTEGER');
    }
    if (oldVersion < 4) {
      // Add automation_rules table for version 4
      await db.execute('''
        CREATE TABLE automation_rules (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          triggerType TEXT NOT NULL,
          actionType TEXT NOT NULL,
          config TEXT NOT NULL,
          isEnabled INTEGER NOT NULL DEFAULT 1,
          lastTriggered INTEGER,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER
        )
      ''');
    }
  }

  // Expense CRUD Operations
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      orderBy: 'date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> getExpensesByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  /// Get filtered expenses with multiple filter options
  Future<List<Expense>> getFilteredExpenses({
    String? category,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    String? sortBy, // 'dateDesc', 'dateAsc', 'amountDesc', 'amountAsc'
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (category != null) {
      whereConditions.add('category = ?');
      whereArgs.add(category);
    }
    if (minAmount != null) {
      whereConditions.add('amount >= ?');
      whereArgs.add(minAmount);
    }
    if (maxAmount != null) {
      whereConditions.add('amount <= ?');
      whereArgs.add(maxAmount);
    }
    if (startDate != null) {
      whereConditions.add('date >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      whereConditions.add('date <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereConditions.add('description LIKE ?');
      whereArgs.add('%$searchQuery%');
    }

    String? where;
    if (whereConditions.isNotEmpty) {
      where = whereConditions.join(' AND ');
    }

    String orderBy = 'date DESC';
    if (sortBy != null) {
      switch (sortBy) {
        case 'dateAsc':
          orderBy = 'date ASC';
          break;
        case 'amountDesc':
          orderBy = 'amount DESC';
          break;
        case 'amountAsc':
          orderBy = 'amount ASC';
          break;
        default:
          orderBy = 'date DESC';
      }
    }

    final result = await db.query(
      'expenses',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return result.map((row) => Expense.fromMap(row)).toList();
  }

  Future<Expense?> getExpenseById(String id) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Expense.fromMap(maps.first);
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(String id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE date >= ? AND date <= ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM expenses WHERE date >= ? AND date <= ? GROUP BY category',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return {
      for (final row in result)
        row['category'] as String: (row['total'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // Settings Operations
  Future<UserSettings> getSettings() async {
    final db = await database;
    final maps = await db.query('settings', where: 'id = ?', whereArgs: [defaultSettingsId]);
    if (maps.isEmpty) {
      return const UserSettings();
    }
    return UserSettings.fromMap(maps.first);
  }

  Future<int> updateSettings(UserSettings settings) async {
    final db = await database;
    return await db.update(
      'settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [defaultSettingsId],
    );
  }

  // Budget CRUD Operations
  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<Budget?> getBudgetByMonth(int year, int month) async {
    final db = await database;
    final maps = await db.query(
      'budgets',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  Future<List<Budget>> getAllBudgets() async {
    final db = await database;
    final maps = await db.query(
      'budgets',
      orderBy: 'year DESC, month DESC',
    );
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> deleteBudget(String id) async {
    final db = await database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Automation Rules CRUD Operations
  Future<int> insertAutomationRule(AutomationRule rule) async {
    final db = await database;
    final map = rule.toMap();
    map['config'] = jsonEncode(map['config']);
    return await db.insert('automation_rules', map);
  }

  Future<List<AutomationRule>> getAllAutomationRules() async {
    final db = await database;
    final maps = await db.query(
      'automation_rules',
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) {
      final mutableMap = Map<String, dynamic>.from(map);
      // Parse config as JSON
      final configStr = map['config'] as String?;
      if (configStr != null) {
        try {
          mutableMap['config'] = jsonDecode(configStr);
        } catch (_) {
          mutableMap['config'] = <String, dynamic>{};
        }
      }
      return AutomationRule.fromMap(mutableMap);
    }).toList();
  }

  Future<List<AutomationRule>> getEnabledAutomationRules() async {
    final db = await database;
    final maps = await db.query(
      'automation_rules',
      where: 'isEnabled = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) {
      final mutableMap = Map<String, dynamic>.from(map);
      // Parse config as JSON
      final configStr = map['config'] as String?;
      if (configStr != null) {
        try {
          mutableMap['config'] = jsonDecode(configStr);
        } catch (_) {
          mutableMap['config'] = <String, dynamic>{};
        }
      }
      return AutomationRule.fromMap(mutableMap);
    }).toList();
  }

  Future<AutomationRule?> getAutomationRuleById(String id) async {
    final db = await database;
    final maps = await db.query(
      'automation_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    final mutableMap = Map<String, dynamic>.from(maps.first);
    // Parse config as JSON
    final configStr = maps.first['config'] as String?;
    if (configStr != null) {
      try {
        mutableMap['config'] = jsonDecode(configStr);
      } catch (_) {
        mutableMap['config'] = <String, dynamic>{};
      }
    }
    return AutomationRule.fromMap(mutableMap);
  }

  Future<int> updateAutomationRule(AutomationRule rule) async {
    final db = await database;
    final map = rule.toMap();
    map['config'] = jsonEncode(map['config']);
    map['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    return await db.update(
      'automation_rules',
      map,
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<int> deleteAutomationRule(String id) async {
    final db = await database;
    return await db.delete(
      'automation_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleAutomationRule(String id, bool isEnabled) async {
    final db = await database;
    return await db.update(
      'automation_rules',
      {
        'isEnabled': isEnabled ? 1 : 0,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('budgets');
  }

  // Export data to JSON
  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    final expenses = await db.query('expenses', orderBy: 'date DESC');
    final budgets = await db.query('budgets', orderBy: 'year DESC, month DESC');
    final settings = await db.query('settings', where: 'id = ?', whereArgs: [defaultSettingsId]);

    return {
      'expenses': expenses,
      'budgets': budgets,
      'settings': settings.isNotEmpty ? settings.first : null,
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // Import data from JSON
  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;

    // Clear existing data
    await clearAllData();

    // Import expenses
    if (data['expenses'] != null) {
      for (final expense in data['expenses'] as List) {
        await db.insert('expenses', Map<String, dynamic>.from(expense));
      }
    }

    // Import budgets
    if (data['budgets'] != null) {
      for (final budget in data['budgets'] as List) {
        await db.insert('budgets', Map<String, dynamic>.from(budget));
      }
    }

    // Import settings
    if (data['settings'] != null) {
      await db.update(
        'settings',
        Map<String, dynamic>.from(data['settings']),
        where: 'id = ?',
        whereArgs: [defaultSettingsId],
      );
    }
  }
}
