import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/core/services/ai_analysis_service.dart';
import 'package:ai_expense_tracker/data/models/expense_model.dart';
import 'package:ai_expense_tracker/data/models/budget_model.dart';
import 'package:ai_expense_tracker/data/models/user_settings.dart';

void main() {
  group('AIAnalysisService Tests', () {
    late AIAnalysisService service;

    setUp(() {
      service = AIAnalysisService();
    });

    tearDown(() {
      service.dispose();
    });

    test('AIAnalysisService can be instantiated', () {
      expect(service, isNotNull);
    });

    test('AIAnalysisService analyzeSpendingHabits works with data', () async {
      const settings = UserSettings();

      // Create sample expenses
      final expenses = [
        Expense(
          id: '1',
          amount: 50.0,
          description: '午餐',
          category: '餐饮',
          date: DateTime.now(),
        ),
        Expense(
          id: '2',
          amount: 30.0,
          description: '打车',
          category: '交通',
          date: DateTime.now(),
        ),
        Expense(
          id: '3',
          amount: 100.0,
          description: '购物',
          category: '购物',
          date: DateTime.now(),
        ),
      ];

      final result = await service.analyzeSpendingHabits(expenses, settings);

      expect(result, isNotNull);
      expect(result['hasData'], isTrue);
      expect(result['thisMonthTotal'], isNotNull);
      expect(result['expenseCount'], equals(3));
      expect(result['categoryBreakdown'], isNotNull);
    });

    test('AIAnalysisService analyzeSpendingHabits handles empty data', () async {
      const settings = UserSettings();

      final result = await service.analyzeSpendingHabits([], settings);

      expect(result, isNotNull);
      expect(result['hasData'], isFalse);
      expect(result['message'], equals('暂无消费数据'));
    });

    test('AIAnalysisService suggestBudget returns default for empty data', () async {
      const settings = UserSettings();

      final budget = await service.suggestBudget([], settings);

      // Default suggested budget is 3000.0
      expect(budget, equals(3000.0));
    });

    test('AIAnalysisService suggestBudget calculates based on recent expenses', () async {
      const settings = UserSettings();

      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          amount: 2000.0,
          description: ' expense 1',
          category: '餐饮',
          date: DateTime(now.year, now.month - 1, 15),
        ),
        Expense(
          id: '2',
          amount: 2500.0,
          description: ' expense 2',
          category: '购物',
          date: DateTime(now.year, now.month - 2, 10),
        ),
      ];

      final budget = await service.suggestBudget(expenses, settings);

      // Should be around the average * 1.1 = 2250 * 1.1 = 2475
      expect(budget, greaterThan(2000));
      expect(budget, lessThan(3000));
    });

    test('AIAnalysisService generateMonthlyReport works with data', () async {
      const settings = UserSettings();

      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          amount: 100.0,
          description: '午餐',
          category: '餐饮',
          date: DateTime(now.year, now.month, 5),
        ),
        Expense(
          id: '2',
          amount: 50.0,
          description: '打车',
          category: '交通',
          date: DateTime(now.year, now.month, 10),
        ),
      ];

      final report = await service.generateMonthlyReport(expenses, null, settings);

      expect(report, isNotEmpty);
      expect(report, contains('消费'));
    });

    test('AIAnalysisService generateMonthlyReport works with empty data', () async {
      const settings = UserSettings();

      final report = await service.generateMonthlyReport([], null, settings);

      expect(report, isNotEmpty);
      expect(report, contains('还没有消费记录'));
    });

    test('AIAnalysisService generateMonthlyReport works with budget', () async {
      const settings = UserSettings();

      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          amount: 500.0,
          description: '购物',
          category: '购物',
          date: DateTime(now.year, now.month, 5),
        ),
      ];

      final budget = Budget(
        amount: 1000.0,
        month: now.month,
        year: now.year,
      );

      final report = await service.generateMonthlyReport(expenses, budget, settings);

      expect(report, isNotEmpty);
      expect(report, contains('预算'));
      expect(report, contains('剩余'));
    });

    test('AIAnalysisService generateMonthlyReport shows over budget', () async {
      const settings = UserSettings();

      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          amount: 1500.0,
          description: '大额消费',
          category: '购物',
          date: DateTime(now.year, now.month, 5),
        ),
      ];

      final budget = Budget(
        amount: 1000.0,
        month: now.month,
        year: now.year,
      );

      final report = await service.generateMonthlyReport(expenses, budget, settings);

      expect(report, isNotEmpty);
      expect(report, contains('超出'));
    });
  });

  group('AIAnalysisService Calculation Tests', () {
    late AIAnalysisService service;

    setUp(() {
      service = AIAnalysisService();
    });

    tearDown(() {
      service.dispose();
    });

    test('analyzeSpendingHabits calculates month over month change', () async {
      const settings = UserSettings();

      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);
      final lastMonth = DateTime(now.year, now.month - 1);

      final expenses = [
        // This month expenses
        Expense(
          id: '1',
          amount: 100.0,
          description: 'this month',
          category: '餐饮',
          date: thisMonth,
        ),
        // Last month expenses
        Expense(
          id: '2',
          amount: 200.0,
          description: 'last month',
          category: '购物',
          date: lastMonth,
        ),
      ];

      final result = await service.analyzeSpendingHabits(expenses, settings);

      // This month total: 100, Last month total: 200
      // Change: (100 - 200) / 200 * 100 = -50%
      expect(result['monthOverMonthChange'], equals(-50.0));
    });

    test('analyzeSpendingHabits calculates average expense', () async {
      const settings = UserSettings();

      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          amount: 100.0,
          description: 'expense 1',
          category: '餐饮',
          date: DateTime(now.year, now.month, 1),
        ),
        Expense(
          id: '2',
          amount: 200.0,
          description: 'expense 2',
          category: '交通',
          date: DateTime(now.year, now.month, 5),
        ),
        Expense(
          id: '3',
          amount: 300.0,
          description: 'expense 3',
          category: '购物',
          date: DateTime(now.year, now.month, 10),
        ),
      ];

      final result = await service.analyzeSpendingHabits(expenses, settings);

      // Average = (100 + 200 + 300) / 3 = 200
      expect(result['averageExpense'], equals(200.0));
    });

    test('analyzeSpendingHabits calculates category breakdown', () async {
      const settings = UserSettings();

      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          amount: 50.0,
          description: 'food 1',
          category: '餐饮',
          date: DateTime(now.year, now.month, 1),
        ),
        Expense(
          id: '2',
          amount: 50.0,
          description: 'food 2',
          category: '餐饮',
          date: DateTime(now.year, now.month, 2),
        ),
        Expense(
          id: '3',
          amount: 100.0,
          description: 'shopping',
          category: '购物',
          date: DateTime(now.year, now.month, 3),
        ),
      ];

      final result = await service.analyzeSpendingHabits(expenses, settings);

      final breakdown = result['categoryBreakdown'] as Map<String, double>;
      expect(breakdown['餐饮'], equals(50.0)); // 100/200 = 50%
      expect(breakdown['购物'], equals(50.0)); // 100/200 = 50%
    });

    test('analyzeSpendingHabits calculates amount ranges', () async {
      const settings = UserSettings();

      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          amount: 25.0, // 0-50 range
          description: 'small',
          category: '餐饮',
          date: DateTime(now.year, now.month, 1),
        ),
        Expense(
          id: '2',
          amount: 75.0, // 50-100 range
          description: 'medium',
          category: '餐饮',
          date: DateTime(now.year, now.month, 2),
        ),
        Expense(
          id: '3',
          amount: 150.0, // 100-200 range
          description: 'large',
          category: '购物',
          date: DateTime(now.year, now.month, 3),
        ),
      ];

      final result = await service.analyzeSpendingHabits(expenses, settings);

      final ranges = result['amountRanges'] as Map<String, int>;
      expect(ranges['0-50'], equals(1));
      expect(ranges['50-100'], equals(1));
      expect(ranges['100-200'], equals(1));
    });
  });
}
