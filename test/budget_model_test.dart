import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/data/models/budget_model.dart';

void main() {
  group('Budget Model Tests', () {
    test('Budget can be created with required fields', () {
      final budget = Budget(
        amount: 5000.0,
        month: 1,
        year: 2024,
      );

      expect(budget.amount, 5000.0);
      expect(budget.month, 1);
      expect(budget.year, 2024);
      expect(budget.id, isNotEmpty);
      expect(budget.createdAt, isNotNull);
      expect(budget.updatedAt, isNotNull);
    });

    test('Budget can be created with all fields', () {
      final now = DateTime.now();
      final budget = Budget(
        id: 'test-id',
        amount: 3000.0,
        month: 6,
        year: 2024,
        createdAt: now,
        updatedAt: now,
      );

      expect(budget.id, 'test-id');
      expect(budget.amount, 3000.0);
      expect(budget.month, 6);
      expect(budget.year, 2024);
      expect(budget.createdAt, now);
      expect(budget.updatedAt, now);
    });

    test('Budget copyWith creates new instance with updated fields', () {
      final budget = Budget(
        id: 'original-id',
        amount: 1000.0,
        month: 1,
        year: 2024,
      );

      final updated = budget.copyWith(amount: 2000.0, month: 2);

      expect(updated.id, 'original-id');
      expect(updated.amount, 2000.0);
      expect(updated.month, 2);
      expect(updated.year, 2024);
      // Original unchanged
      expect(budget.amount, 1000.0);
      expect(budget.month, 1);
    });

    test('Budget copyWith preserves original when no params provided', () {
      final now = DateTime.now();
      final budget = Budget(
        id: 'test-id',
        amount: 1500.0,
        month: 3,
        year: 2024,
        createdAt: now,
        updatedAt: now,
      );

      final copy = budget.copyWith();

      expect(copy.id, budget.id);
      expect(copy.amount, budget.amount);
      expect(copy.month, budget.month);
      expect(copy.year, budget.year);
      expect(copy.createdAt, budget.createdAt);
      expect(copy.updatedAt, budget.updatedAt);
    });

    test('Budget toMap and fromMap works correctly', () {
      final now = DateTime.now();
      final budget = Budget(
        id: 'test-id',
        amount: 2500.0,
        month: 5,
        year: 2024,
        createdAt: now,
        updatedAt: now,
      );

      final map = budget.toMap();
      final restored = Budget.fromMap(map);

      expect(restored.id, budget.id);
      expect(restored.amount, budget.amount);
      expect(restored.month, budget.month);
      expect(restored.year, budget.year);
    });

    test('Budget fromMap handles num amount conversion', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final map = {
        'id': 'test-id',
        'amount': 1000, // int instead of double
        'month': 6,
        'year': 2024,
        'createdAt': now,
        'updatedAt': now,
      };

      final budget = Budget.fromMap(map);

      expect(budget.amount, 1000.0);
      expect(budget.amount, isA<double>());
    });

    test('Budget fromMap handles num amount with decimal', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final map = {
        'id': 'test-id',
        'amount': 1234.56, // double as num
        'month': 7,
        'year': 2024,
        'createdAt': now,
        'updatedAt': now,
      };

      final budget = Budget.fromMap(map);

      expect(budget.amount, 1234.56);
    });

    test('Budget equality based on id', () {
      final budget1 = Budget(
        id: 'same-id',
        amount: 1000.0,
        month: 1,
        year: 2024,
      );

      final budget2 = Budget(
        id: 'same-id',
        amount: 2000.0, // Different amount
        month: 2,       // Different month
        year: 2025,     // Different year
      );

      expect(budget1, equals(budget2)); // Same ID
    });

    test('Budget inequality with different ids', () {
      final budget1 = Budget(
        id: 'id-1',
        amount: 1000.0,
        month: 1,
        year: 2024,
      );

      final budget2 = Budget(
        id: 'id-2',
        amount: 1000.0,
        month: 1,
        year: 2024,
      );

      expect(budget1, isNot(equals(budget2)));
    });

    test('Budget hashCode based on id', () {
      final budget1 = Budget(
        id: 'test-id',
        amount: 1000.0,
        month: 1,
        year: 2024,
      );

      final budget2 = Budget(
        id: 'test-id',
        amount: 2000.0,
        month: 2,
        year: 2025,
      );

      expect(budget1.hashCode, equals(budget2.hashCode));
    });

    test('Budget edge cases - month boundaries', () {
      final budgetJan = Budget(amount: 1000.0, month: 1, year: 2024);
      final budgetDec = Budget(amount: 1000.0, month: 12, year: 2024);

      expect(budgetJan.month, 1);
      expect(budgetDec.month, 12);
    });

    test('Budget edge cases - zero amount', () {
      final budget = Budget(amount: 0.0, month: 1, year: 2024);

      expect(budget.amount, 0.0);
    });

    test('Budget edge cases - large amount', () {
      final budget = Budget(amount: 999999999.0, month: 1, year: 2024);

      expect(budget.amount, 999999999.0);
    });

    test('Budget edge cases - negative amount', () {
      final budget = Budget(amount: -100.0, month: 1, year: 2024);

      expect(budget.amount, -100.0);
    });

    test('Budget edge cases - year boundaries', () {
      final budget2020 = Budget(amount: 1000.0, month: 1, year: 2020);
      final budget2100 = Budget(amount: 1000.0, month: 1, year: 2100);

      expect(budget2020.year, 2020);
      expect(budget2100.year, 2100);
    });
  });
}
