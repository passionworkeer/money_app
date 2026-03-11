import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/user_settings.dart';
import '../../data/datasources/local/database_helper.dart';

/// Backup and restore service for the expense tracker app.
/// Provides export to JSON, share functionality, and data restoration.
class BackupService {
  static const String _backupVersion = '1.0.0';

  final DatabaseHelper _databaseHelper;

  BackupService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Exports all data to a JSON string.
  /// [expenses] - List of expenses to export
  /// [budgets] - List of budgets to export
  /// [settings] - User settings to export
  Future<String> exportData({
    required List<Expense> expenses,
    required List<Budget> budgets,
    required UserSettings settings,
  }) async {
    final data = <String, dynamic>{
      'version': _backupVersion,
      'exportDate': DateTime.now().toIso8601String(),
      'expenses': expenses.map((e) => _expenseToMap(e)).toList(),
      'budgets': budgets.map((b) => _budgetToMap(b)).toList(),
      'settings': _settingsToMap(settings),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Exports data directly from the database.
  Future<String> exportDataFromDatabase() async {
    final expenses = await _databaseHelper.getAllExpenses();
    final budgets = await _databaseHelper.getAllBudgets();
    final settings = await _databaseHelper.getSettings();

    return exportData(
      expenses: expenses,
      budgets: budgets,
      settings: settings,
    );
  }

  /// Creates a temporary file and shares it.
  /// [jsonContent] - The JSON content to share
  /// Returns the file path of the shared file
  Future<String> shareFile(String jsonContent) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'ai_expense_backup_$timestamp.json';
    final file = File('${directory.path}/$fileName');

    try {
      await file.writeAsString(jsonContent);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'AI Expense Tracker Backup',
        text: 'Backup from AI Expense Tracker app',
      );

      return file.path;
    } finally {
      // 清理临时文件
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // 忽略删除失败，避免影响主流程
      }
    }
  }

  /// Exports and shares the data in one operation.
  Future<String> exportAndShare() async {
    final jsonContent = await exportDataFromDatabase();
    return shareFile(jsonContent);
  }

  /// Validates and imports data from JSON string.
  /// Returns the parsed data map
  Future<BackupData> importData(String jsonContent) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;

      // Validate version compatibility
      final version = data['version'] as String? ?? '0.0.0';
      if (!_isVersionCompatible(version)) {
        throw BackupException(
          'Incompatible backup version: $version. Supported version: $_backupVersion',
        );
      }

      // Validate required fields
      if (!data.containsKey('expenses') ||
          !data.containsKey('budgets') ||
          !data.containsKey('settings')) {
        throw BackupException('Invalid backup format: missing required fields');
      }

      // Parse expenses
      final expensesList = (data['expenses'] as List<dynamic>)
          .map((e) => _expenseFromMap(e as Map<String, dynamic>))
          .toList();

      // Validate data size limits
      if (expensesList.length > 10000) {
        throw BackupException('数据量过大，最多支持10000条记录');
      }

      // Validate description length
      for (final expense in expensesList) {
        if (expense.description.length > 500) {
          throw BackupException('备注内容过长，不能超过500字符');
        }
      }

      // Parse budgets
      final budgetsList = (data['budgets'] as List<dynamic>)
          .map((b) => _budgetFromMap(b as Map<String, dynamic>))
          .toList();

      // Parse settings
      final settings = _settingsFromMap(
        data['settings'] as Map<String, dynamic>,
      );

      return BackupData(
        expenses: expensesList,
        budgets: budgetsList,
        settings: settings,
        exportDate: data['exportDate'] as String?,
        version: version,
      );
    } on FormatException {
      throw BackupException('Invalid JSON format');
    }
  }

  /// Restores data from a BackupData object.
  /// This will replace all existing data in the database.
  Future<void> restoreData(BackupData backupData) async {
    await _databaseHelper.database; // Ensure database is initialized

    // Use a batch operation for better performance
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('expenses');
      await txn.delete('budgets');

      // Insert expenses
      for (final expense in backupData.expenses) {
        await txn.insert('expenses', _expenseToMap(expense));
      }

      // Insert budgets
      for (final budget in backupData.budgets) {
        await txn.insert('budgets', _budgetToMap(budget));
      }

      // Update settings
      await txn.update(
        'settings',
        _settingsToMap(backupData.settings),
        where: 'id = ?',
        whereArgs: [1],
      );
    });
  }

  /// Restores data directly from JSON string.
  Future<void> restoreFromJson(String jsonContent) async {
    final backupData = await importData(jsonContent);
    await restoreData(backupData);
  }

  /// Gets all expenses from database
  Future<List<Expense>> getAllExpenses() async {
    return await _databaseHelper.getAllExpenses();
  }

  /// Gets all budgets from database
  Future<List<Budget>> getAllBudgets() async {
    return await _databaseHelper.getAllBudgets();
  }

  // Private helper methods

  bool _isVersionCompatible(String version) {
    final parts = version.split('.');
    if (parts.isEmpty) return false;

    final major = int.tryParse(parts[0]) ?? 0;
    // Support major version 1.x.x
    return major == 1;
  }

  Map<String, dynamic> _expenseToMap(Expense expense) {
    return {
      'id': expense.id,
      'amount': expense.amount,
      'description': expense.description,
      'category': expense.category,
      'date': expense.date.millisecondsSinceEpoch,
      'createdAt': expense.createdAt.millisecondsSinceEpoch,
      'isSynced': expense.isSynced ? 1 : 0,
    };
  }

  Expense _expenseFromMap(Map<String, dynamic> map) {
    // 验证必填字段
    if (map['id'] == null || map['amount'] == null ||
        map['description'] == null || map['category'] == null) {
      throw BackupException('Invalid expense data: missing required fields');
    }

    // 类型验证 - amount
    final amount = map['amount'];
    if (amount is! num) {
      throw BackupException('Invalid expense data: amount must be a number');
    }

    // 金额范围验证
    final amountValue = amount.toDouble();
    if (amountValue < 0 || amountValue > 999999999) {
      throw BackupException('Invalid expense data: amount out of valid range');
    }

    // 类型验证 - date
    if (map['date'] is! int) {
      throw BackupException('Invalid expense data: date must be a timestamp');
    }

    // 类型验证 - createdAt
    if (map['createdAt'] is! int) {
      throw BackupException('Invalid expense data: createdAt must be a timestamp');
    }

    return Expense(
      id: map['id'] as String,
      amount: amountValue,
      description: map['description'] as String,
      category: map['category'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      isSynced: (map['isSynced'] as int?) == 1,
    );
  }

  Map<String, dynamic> _budgetToMap(Budget budget) {
    return {
      'id': budget.id,
      'amount': budget.amount,
      'month': budget.month,
      'year': budget.year,
      'createdAt': budget.createdAt.millisecondsSinceEpoch,
      'updatedAt': budget.updatedAt.millisecondsSinceEpoch,
    };
  }

  Budget _budgetFromMap(Map<String, dynamic> map) {
    // 验证必填字段
    if (map['id'] == null || map['amount'] == null ||
        map['month'] == null || map['year'] == null) {
      throw BackupException('Invalid budget data: missing required fields');
    }

    // 类型验证 - amount
    final amount = map['amount'];
    if (amount is! num) {
      throw BackupException('Invalid budget data: amount must be a number');
    }

    // 金额范围验证
    final amountValue = amount.toDouble();
    if (amountValue < 0 || amountValue > 999999999) {
      throw BackupException('Invalid budget data: amount out of valid range');
    }

    // 类型验证 - month/year
    if (map['month'] is! int || map['year'] is! int) {
      throw BackupException('Invalid budget data: month and year must be integers');
    }

    // 月份范围验证
    final month = map['month'] as int;
    final year = map['year'] as int;
    if (month < 1 || month > 12) {
      throw BackupException('Invalid budget data: month must be between 1 and 12');
    }
    if (year < 2000 || year > 2100) {
      throw BackupException('Invalid budget data: year out of valid range');
    }

    return Budget(
      id: map['id'] as String,
      amount: amountValue,
      month: month,
      year: year,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  Map<String, dynamic> _settingsToMap(UserSettings settings) {
    return {
      'openaiApiKey': settings.openaiApiKey,
      'claudeApiKey': settings.claudeApiKey,
      'useCloudSync': settings.useCloudSync ? 1 : 0,
      'defaultCurrency': settings.defaultCurrency,
      'themeMode': settings.themeMode.index,
    };
  }

  UserSettings _settingsFromMap(Map<String, dynamic> map) {
    return UserSettings(
      openaiApiKey: map['openaiApiKey'] as String?,
      claudeApiKey: map['claudeApiKey'] as String?,
      useCloudSync: (map['useCloudSync'] as int?) == 1,
      defaultCurrency: map['defaultCurrency'] as String? ?? 'CNY',
      themeMode: ThemeMode.values[map['themeMode'] as int? ?? 0],
    );
  }
}

/// Data class holding parsed backup data
class BackupData {
  final List<Expense> expenses;
  final List<Budget> budgets;
  final UserSettings settings;
  final String? exportDate;
  final String version;

  const BackupData({
    required this.expenses,
    required this.budgets,
    required this.settings,
    this.exportDate,
    required this.version,
  });

  int get totalExpenses => expenses.length;
  int get totalBudgets => budgets.length;
}

/// Exception thrown during backup/restore operations
class BackupException implements Exception {
  final String message;

  const BackupException(this.message);

  @override
  String toString() => 'BackupException: $message';
}
