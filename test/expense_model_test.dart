import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/data/models/expense_model.dart';
import 'package:ai_expense_tracker/core/constants/categories.dart';

void main() {
  group('Expense Model Tests', () {
    test('Expense can be created with required fields', () {
      final expense = Expense(
        amount: 100.0,
        description: '午餐',
        category: 'food',
        date: DateTime.now(),
      );

      expect(expense.amount, 100.0);
      expect(expense.description, '午餐');
      expect(expense.category, 'food');
      expect(expense.id, isNotEmpty);
      expect(expense.createdAt, isNotNull);
      expect(expense.isSynced, false);
    });

    test('Expense copyWith creates new instance', () {
      final expense = Expense(
        amount: 100.0,
        description: '午餐',
        category: 'food',
        date: DateTime.now(),
      );

      final updated = expense.copyWith(amount: 200.0);

      expect(updated.amount, 200.0);
      expect(updated.description, '午餐');
      expect(expense.amount, 100.0); // Original unchanged
    });

    test('Expense toMap and fromMap works correctly', () {
      final expense = Expense(
        id: 'test-id',
        amount: 100.0,
        description: '午餐',
        category: 'food',
        date: DateTime(2024, 1, 1, 12, 0),
        createdAt: DateTime(2024, 1, 1, 12, 0),
        isSynced: false,
      );

      final map = expense.toMap();
      final restored = Expense.fromMap(map);

      expect(restored.id, expense.id);
      expect(restored.amount, expense.amount);
      expect(restored.description, expense.description);
      expect(restored.category, expense.category);
      expect(restored.isSynced, expense.isSynced);
    });

    test('Expense equality based on id', () {
      final expense1 = Expense(
        id: 'same-id',
        amount: 100.0,
        description: '午餐',
        category: 'food',
        date: DateTime.now(),
      );

      final expense2 = Expense(
        id: 'same-id',
        amount: 200.0, // Different amount
        description: '晚餐',
        category: 'other',
        date: DateTime.now(),
      );

      expect(expense1, equals(expense2)); // Same ID
    });
  });

  group('Category Tests', () {
    test('Category fromValue returns correct category', () {
      expect(ExpenseCategory.fromValue('food'), ExpenseCategory.food);
      expect(ExpenseCategory.fromValue('transport'), ExpenseCategory.transport);
      expect(ExpenseCategory.fromValue('shopping'), ExpenseCategory.shopping);
      expect(ExpenseCategory.fromValue('entertainment'), ExpenseCategory.entertainment);
      expect(ExpenseCategory.fromValue('medical'), ExpenseCategory.medical);
      expect(ExpenseCategory.fromValue('education'), ExpenseCategory.education);
      expect(ExpenseCategory.fromValue('other'), ExpenseCategory.other);
    });

    test('Category fromValue returns other for unknown value', () {
      expect(ExpenseCategory.fromValue('unknown'), ExpenseCategory.other);
      expect(ExpenseCategory.fromValue(''), ExpenseCategory.other);
    });

    test('Category label and value are correct', () {
      expect(ExpenseCategory.food.label, '餐饮');
      expect(ExpenseCategory.food.value, 'food');
      expect(ExpenseCategory.transport.label, '交通');
      expect(ExpenseCategory.transport.value, 'transport');
    });
  });
}
