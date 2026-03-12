import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_expense_tracker/presentation/pages/statistics/statistics_page.dart';
import 'package:ai_expense_tracker/presentation/providers/expense_providers.dart';
import 'package:ai_expense_tracker/presentation/providers/budget_providers.dart';
import 'package:ai_expense_tracker/domain/repositories/expense_repository.dart';
import 'package:ai_expense_tracker/domain/repositories/budget_repository.dart';
import 'package:ai_expense_tracker/data/models/expense_model.dart';
import 'package:ai_expense_tracker/data/models/budget_model.dart';

// Mock ExpenseRepository for testing
class MockExpenseRepository implements ExpenseRepository {
  final List<Expense> mockExpenses;
  final Map<String, double> mockCategoryTotals;
  final double mockMonthTotal;

  MockExpenseRepository({
    this.mockExpenses = const [],
    this.mockCategoryTotals = const {},
    this.mockMonthTotal = 0.0,
  });

  @override
  Future<List<Expense>> getAllExpenses() async => mockExpenses;

  @override
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    return mockExpenses.where((e) {
      return e.date.isAfter(start.subtract(const Duration(days: 1))) &&
          e.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Future<List<Expense>> getExpensesByCategory(String category) async {
    return mockExpenses.where((e) => e.category == category).toList();
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    return mockExpenses.where((e) => e.id == id).firstOrNull;
  }

  @override
  Future<void> addExpense(Expense expense) async {}

  @override
  Future<void> updateExpense(Expense expense) async {}

  @override
  Future<void> deleteExpense(String id) async {}

  @override
  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    return mockMonthTotal;
  }

  @override
  Future<Map<String, double>> getCategoryTotals(DateTime start, DateTime end) async {
    return mockCategoryTotals;
  }
}

// Mock BudgetRepository for testing
class MockBudgetRepository implements BudgetRepository {
  final Budget? mockBudget;

  MockBudgetRepository({this.mockBudget});

  @override
  Future<Budget?> getBudgetByMonth(int year, int month) async => mockBudget;

  @override
  Future<List<Budget>> getAllBudgets() async => mockBudget != null ? [mockBudget!] : [];

  @override
  Future<void> addBudget(Budget budget) async {}

  @override
  Future<void> updateBudget(Budget budget) async {}

  @override
  Future<void> deleteBudget(String id) async {}
}

void main() {
  group('StatisticsPage Tests', () {
    late GoRouter router;

    Widget createTestWidget({
      List<Expense> mockExpenses = const [],
      Map<String, double> mockCategoryTotals = const {},
      double mockMonthTotal = 0.0,
      Budget? mockBudget,
    }) {
      return ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(MockExpenseRepository(
            mockExpenses: mockExpenses,
            mockCategoryTotals: mockCategoryTotals,
            mockMonthTotal: mockMonthTotal,
          )),
          budgetRepositoryProvider.overrideWithValue(MockBudgetRepository(mockBudget: mockBudget)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    setUp(() {
      // Setup router for navigation
      router = GoRouter(
        initialLocation: '/statistics',
        routes: [
          GoRoute(
            path: '/statistics',
            builder: (context, state) => const StatisticsPage(),
          ),
          GoRoute(
            path: '/report',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Report Page')),
            ),
          ),
        ],
      );
    });

    testWidgets('StatisticsPage loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify StatisticsPage is displayed
      expect(find.byType(StatisticsPage), findsOneWidget);
    });

    testWidgets('StatisticsPage displays "消费统计" title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify header title is displayed
      expect(find.text('消费统计'), findsOneWidget);
    });

    testWidgets('StatisticsPage shows month selector', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify month selector is present (shows current year and month)
      final now = DateTime.now();
      expect(find.text('${now.year}年${now.month}月'), findsOneWidget);
    });

    testWidgets('StatisticsPage shows monthly total when data exists', (WidgetTester tester) async {
      const mockCategoryTotals = {
        'food': 500.0,
        'transport': 200.0,
        'shopping': 300.0,
      };

      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: mockCategoryTotals,
        mockMonthTotal: 1000.0,
      ));
      await tester.pumpAndSettle();

      // Verify monthly total is displayed
      expect(find.text('本月支出'), findsOneWidget);
      expect(find.text('¥1000.00'), findsOneWidget);
    });

    testWidgets('StatisticsPage shows category breakdown when data exists', (WidgetTester tester) async {
      const mockCategoryTotals = {
        'food': 500.0,
        'transport': 200.0,
      };

      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: mockCategoryTotals,
        mockMonthTotal: 700.0,
      ));
      await tester.pumpAndSettle();

      // Verify category section titles are displayed
      expect(find.text('分类占比'), findsOneWidget);
      expect(find.text('分类详情'), findsOneWidget);
    });

    testWidgets('StatisticsPage handles empty state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: {},
        mockMonthTotal: 0.0,
      ));
      await tester.pumpAndSettle();

      // Verify empty state message is displayed
      expect(find.text('本月暂无消费记录\n开始记账吧！'), findsOneWidget);
      expect(find.byIcon(Icons.pie_chart_outline), findsOneWidget);
    });

    testWidgets('StatisticsPage shows loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      // Pump once without settling to show loading state
      await tester.pump();

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('StatisticsPage has report button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify report button is displayed
      expect(find.text('报表'), findsOneWidget);
      expect(find.byIcon(Icons.analytics_rounded), findsOneWidget);
    });

    testWidgets('StatisticsPage can navigate to previous month', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: {'food': 500.0},
        mockMonthTotal: 500.0,
      ));
      await tester.pumpAndSettle();

      // Tap on left arrow to go to previous month
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // Verify month changed to previous month
      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      expect(find.text('${prevMonth.year}年${prevMonth.month}月'), findsOneWidget);
    });

    testWidgets('StatisticsPage shows category with correct percentage', (WidgetTester tester) async {
      const mockCategoryTotals = {
        'food': 750.0,
        'transport': 250.0,
      };

      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: mockCategoryTotals,
        mockMonthTotal: 1000.0,
      ));
      await tester.pumpAndSettle();

      // Verify food category shows 75.0%
      expect(find.text('75.0%'), findsOneWidget);
      // Verify transport category shows 25.0%
      expect(find.text('25.0%'), findsOneWidget);
    });

    testWidgets('StatisticsPage shows daily average', (WidgetTester tester) async {
      const mockCategoryTotals = {
        'food': 500.0,
      };

      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: mockCategoryTotals,
        mockMonthTotal: 500.0,
      ));
      await tester.pumpAndSettle();

      // Verify daily average is displayed
      expect(find.textContaining('日均'), findsOneWidget);
    });

    testWidgets('StatisticsPage shows budget execution rate when budget exists', (WidgetTester tester) async {
      final now = DateTime.now();
      final mockBudget = Budget(
        id: '1',
        amount: 5000.0,
        month: now.month,
        year: now.year,
      );

      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: {'food': 2500.0},
        mockMonthTotal: 2500.0,
        mockBudget: mockBudget,
      ));
      await tester.pumpAndSettle();

      // Verify budget execution rate is displayed (50%)
      expect(find.textContaining('预算执行率'), findsOneWidget);
      expect(find.textContaining('50.0%'), findsOneWidget);
    });

    testWidgets('StatisticsPage shows exceeded budget warning', (WidgetTester tester) async {
      final now = DateTime.now();
      final mockBudget = Budget(
        id: '1',
        amount: 1000.0,
        month: now.month,
        year: now.year,
      );

      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: {'food': 1500.0},
        mockMonthTotal: 1500.0,
        mockBudget: mockBudget,
      ));
      await tester.pumpAndSettle();

      // Verify exceeded warning is displayed
      expect(find.textContaining('已超支'), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets('StatisticsPage displays category icons', (WidgetTester tester) async {
      const mockCategoryTotals = {
        'food': 500.0,
        'transport': 300.0,
      };

      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: mockCategoryTotals,
        mockMonthTotal: 800.0,
      ));
      await tester.pumpAndSettle();

      // Verify category icons are displayed
      // Food category icon
      expect(find.byIcon(Icons.restaurant), findsWidgets);
      // Transport category icon
      expect(find.byIcon(Icons.directions_car), findsWidgets);
    });
  });
}
