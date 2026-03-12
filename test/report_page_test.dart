import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_expense_tracker/presentation/pages/report/report_page.dart';
import 'package:ai_expense_tracker/presentation/providers/report_providers.dart';
import 'package:ai_expense_tracker/presentation/widgets/report/monthly_report_card.dart';
import 'package:ai_expense_tracker/presentation/widgets/report/category_pie_chart.dart';
import 'package:ai_expense_tracker/presentation/widgets/report/trend_line_chart.dart';
import 'package:ai_expense_tracker/presentation/widgets/report/spending_insight_card.dart';
import 'package:ai_expense_tracker/presentation/widgets/report/top_category_list.dart';
import 'package:ai_expense_tracker/domain/repositories/expense_repository.dart';
import 'package:ai_expense_tracker/data/models/expense_model.dart';

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

void main() {
  group('ReportPage Tests', () {
    late GoRouter router;

    Widget createTestWidget({
      List<Expense> mockExpenses = const [],
      Map<String, double> mockCategoryTotals = const {},
      double mockMonthTotal = 0.0,
    }) {
      return ProviderScope(
        overrides: [
          reportExpenseRepositoryProvider.overrideWithValue(MockExpenseRepository(
            mockExpenses: mockExpenses,
            mockCategoryTotals: mockCategoryTotals,
            mockMonthTotal: mockMonthTotal,
          )),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    setUp(() {
      router = GoRouter(
        initialLocation: '/report',
        routes: [
          GoRoute(
            path: '/report',
            builder: (context, state) => const ReportPage(),
          ),
        ],
      );
    });

    testWidgets('ReportPage loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Verify ReportPage is displayed
      expect(find.byType(ReportPage), findsOneWidget);
    });

    testWidgets('ReportPage displays monthly report tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify monthly tab is displayed
      expect(find.text('月度'), findsOneWidget);
    });

    testWidgets('ReportPage displays yearly report tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify yearly tab is displayed
      expect(find.text('年度'), findsOneWidget);
    });

    testWidgets('ReportPage switches between tabs correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially on monthly tab
      expect(find.text('月度'), findsOneWidget);
      expect(find.text('年度'), findsOneWidget);

      // Tap on yearly tab
      await tester.tap(find.text('年度'));
      await tester.pumpAndSettle();

      // Verify yearly tab content is shown
      expect(find.textContaining('年度支出'), findsOneWidget);
    });

    testWidgets('ReportPage shows MonthlyReportCard widget', (WidgetTester tester) async {
      const mockCategoryTotals = {
        'food': 500.0,
        'transport': 200.0,
      };

      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: mockCategoryTotals,
        mockMonthTotal: 700.0,
      ));
      await tester.pumpAndSettle();

      // Verify MonthlyReportCard is displayed
      expect(find.byType(MonthlyReportCard), findsOneWidget);
    });

    testWidgets('ReportPage shows CategoryPieChart widget', (WidgetTester tester) async {
      const mockCategoryTotals = {
        'food': 500.0,
        'transport': 200.0,
      };

      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: mockCategoryTotals,
        mockMonthTotal: 700.0,
      ));
      await tester.pumpAndSettle();

      // Verify CategoryPieChart is displayed
      expect(find.byType(CategoryPieChart), findsOneWidget);
    });

    testWidgets('ReportPage shows TrendLineChart widget', (WidgetTester tester) async {
      const mockCategoryTotals = {
        'food': 500.0,
      };

      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: mockCategoryTotals,
        mockMonthTotal: 500.0,
      ));
      await tester.pumpAndSettle();

      // Verify TrendLineChart is displayed
      expect(find.byType(TrendLineChart), findsOneWidget);
    });

    testWidgets('ReportPage shows header title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify header title is displayed
      expect(find.text('消费报表'), findsOneWidget);
    });

    testWidgets('ReportPage shows back button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify back button is displayed
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('ReportPage displays month selector', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify year selector is displayed
      final now = DateTime.now();
      expect(find.text('${now.year}年'), findsOneWidget);
    });

    testWidgets('ReportPage can navigate to previous year', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: {'food': 500.0},
        mockMonthTotal: 500.0,
      ));
      await tester.pumpAndSettle();

      // Tap on left arrow to go to previous year
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // Verify year changed to previous year
      final now = DateTime.now();
      expect(find.text('${now.year - 1}年'), findsOneWidget);
    });

    testWidgets('ReportPage shows trend period selector', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: {'food': 500.0},
        mockMonthTotal: 500.0,
      ));
      await tester.pumpAndSettle();

      // Verify trend period chips are displayed
      expect(find.text('周'), findsOneWidget);
      expect(find.text('月'), findsOneWidget);
      expect(find.text('年'), findsOneWidget);
    });

    testWidgets('ReportPage shows spending insight card', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: {'food': 500.0},
        mockMonthTotal: 500.0,
      ));
      await tester.pumpAndSettle();

      // Verify SpendingInsightCard is displayed
      expect(find.byType(SpendingInsightCard), findsOneWidget);
    });

    testWidgets('ReportPage shows top category list', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        mockCategoryTotals: {'food': 500.0},
        mockMonthTotal: 500.0,
      ));
      await tester.pumpAndSettle();

      // Verify TopCategoryList is displayed
      expect(find.byType(TopCategoryList), findsOneWidget);
    });
  });
}
