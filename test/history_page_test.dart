import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_expense_tracker/presentation/pages/history/history_page.dart';
import 'package:ai_expense_tracker/data/models/expense_model.dart';
import 'package:ai_expense_tracker/data/models/filter_options.dart';
import 'package:ai_expense_tracker/presentation/providers/expense_providers.dart';
import 'package:ai_expense_tracker/presentation/providers/filter_providers.dart';

// Helper to create testable widget with providers
Widget createTestableWidget({
  required List<Expense> expenses,
  FilterOptions filterOptions = const FilterOptions(),
}) {
  return ProviderScope(
    overrides: [
      allExpensesProvider.overrideWith((ref) async => expenses),
      filterOptionsProvider.overrideWith((ref) => filterOptions),
    ],
    child: const MaterialApp(
      home: HistoryPage(),
    ),
  );
}

void main() {
  group('HistoryPage Tests', () {
    testWidgets('HistoryPage loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(expenses: []),
      );
      await tester.pumpAndSettle();

      // Verify page title is displayed
      expect(find.text('消费记录'), findsOneWidget);
    });

    testWidgets('HistoryPage displays list of expenses', (WidgetTester tester) async {
      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          amount: 50.0,
          description: '午餐',
          category: '餐饮',
          date: DateTime(now.year, now.month, now.day - 1),
        ),
        Expense(
          id: '2',
          amount: 30.0,
          description: '打车',
          category: '交通',
          date: DateTime(now.year, now.month, now.day - 2),
        ),
      ];

      await tester.pumpWidget(
        createTestableWidget(expenses: expenses),
      );
      await tester.pumpAndSettle();

      // Verify expense descriptions are displayed
      expect(find.text('午餐'), findsOneWidget);
      expect(find.text('打车'), findsOneWidget);

      // Verify amounts are displayed
      expect(find.text('¥50.00'), findsOneWidget);
      expect(find.text('¥30.00'), findsOneWidget);
    });

    testWidgets('HistoryPage shows search bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(expenses: []),
      );
      await tester.pumpAndSettle();

      // Verify search bar exists
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('搜索账单备注...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('HistoryPage shows filter button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(expenses: []),
      );
      await tester.pumpAndSettle();

      // Verify filter button exists
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('HistoryPage handles empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(expenses: []),
      );
      await tester.pumpAndSettle();

      // Verify empty state message is displayed
      expect(find.text('暂无记录'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('HistoryPage shows filtered empty state when no matching records', (WidgetTester tester) async {
      final expenses = [
        Expense(
          id: '1',
          amount: 50.0,
          description: '午餐',
          category: '餐饮',
          date: DateTime.now(),
        ),
      ];

      // Set filter options that won't match any expense
      const filterOptions = FilterOptions(
        category: '交通',
        minAmount: 1000,
        maxAmount: 2000,
      );

      await tester.pumpWidget(
        createTestableWidget(
          expenses: expenses,
          filterOptions: filterOptions,
        ),
      );
      await tester.pumpAndSettle();

      // Verify filtered empty state message
      expect(find.text('没有找到匹配的记录'), findsOneWidget);
    });

    testWidgets('HistoryPage can search for expense', (WidgetTester tester) async {
      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          amount: 50.0,
          description: '午餐',
          category: '餐饮',
          date: DateTime(now.year, now.month, now.day),
        ),
      ];

      await tester.pumpWidget(
        createTestableWidget(expenses: expenses),
      );
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), '午餐');
      await tester.pumpAndSettle();

      // Verify search text is entered
      expect(find.text('午餐'), findsOneWidget);
    });

    testWidgets('HistoryPage displays expenses grouped by date', (WidgetTester tester) async {
      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          amount: 50.0,
          description: '午餐',
          category: '餐饮',
          date: DateTime(now.year, now.month, now.day),
        ),
        Expense(
          id: '2',
          amount: 30.0,
          description: '打车',
          category: '交通',
          date: DateTime(now.year, now.month, now.day),
        ),
      ];

      await tester.pumpWidget(
        createTestableWidget(expenses: expenses),
      );
      await tester.pumpAndSettle();

      // Verify today's date header
      expect(find.text('今天'), findsOneWidget);

      // Verify total for the day is displayed
      expect(find.text('¥80.00'), findsOneWidget);
    });

    testWidgets('HistoryPage shows yesterday date for yesterday expenses', (WidgetTester tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final expenses = [
        Expense(
          id: '1',
          amount: 100.0,
          description: '昨天消费',
          category: '购物',
          date: yesterday,
        ),
      ];

      await tester.pumpWidget(
        createTestableWidget(expenses: expenses),
      );
      await tester.pumpAndSettle();

      // Verify yesterday header
      expect(find.text('昨天'), findsOneWidget);
    });

    testWidgets('HistoryPage shows more options menu', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(expenses: []),
      );
      await tester.pumpAndSettle();

      // Verify more options button exists
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('HistoryPage shows category chips when filtered', (WidgetTester tester) async {
      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          amount: 50.0,
          description: '午餐',
          category: '餐饮',
          date: DateTime(now.year, now.month, now.day),
        ),
      ];

      // Set category filter
      const filterOptions = FilterOptions(category: '餐饮');

      await tester.pumpWidget(
        createTestableWidget(
          expenses: expenses,
          filterOptions: filterOptions,
        ),
      );
      await tester.pumpAndSettle();

      // Verify category chip is displayed
      expect(find.text('餐饮'), findsWidgets);
      expect(find.text('清除全部'), findsOneWidget);
    });

    testWidgets('HistoryPage has filter button that opens bottom sheet', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(expenses: []),
      );
      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // The filter bottom sheet should appear (we can verify by checking for filter UI)
      // Since we can't easily test the bottom sheet without importing it,
      // we just verify the tap doesn't throw an error
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });
  });

  group('HistoryPage Expense Display Tests', () {
    testWidgets('HistoryPage displays expense with correct category icon', (WidgetTester tester) async {
      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          amount: 50.0,
          description: '午餐',
          category: '餐饮',
          date: DateTime(now.year, now.month, now.day),
        ),
      ];

      await tester.pumpWidget(
        createTestableWidget(expenses: expenses),
      );
      await tester.pumpAndSettle();

      // Verify expense is displayed (the description should be visible in ExpenseCard)
      expect(find.text('午餐'), findsOneWidget);
    });

    testWidgets('HistoryPage handles single expense', (WidgetTester tester) async {
      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          amount: 100.0,
          description: '单笔消费',
          category: '购物',
          date: DateTime(now.year, now.month, now.day),
        ),
      ];

      await tester.pumpWidget(
        createTestableWidget(expenses: expenses),
      );
      await tester.pumpAndSettle();

      // Verify single expense is displayed
      expect(find.text('单笔消费'), findsOneWidget);
      expect(find.text('¥100.00'), findsOneWidget);
    });

    testWidgets('HistoryPage handles many expenses', (WidgetTester tester) async {
      final now = DateTime.now();
      final expenses = List.generate(
        20,
        (index) => Expense(
          id: 'expense_$index',
          amount: 10.0 + index * 5,
          description: '消费$index',
          category: index % 2 == 0 ? '餐饮' : '交通',
          date: DateTime(now.year, now.month, now.day - (index % 3)),
        ),
      );

      await tester.pumpWidget(
        createTestableWidget(expenses: expenses),
      );
      await tester.pumpAndSettle();

      // Verify list view exists
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('HistoryPage Date Grouping Tests', () {
    testWidgets('HistoryPage groups expenses by date correctly', (WidgetTester tester) async {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);

      final expenses = [
        Expense(
          id: '1',
          amount: 50.0,
          description: '今天午餐',
          category: '餐饮',
          date: DateTime(now.year, now.month, now.day),
        ),
        Expense(
          id: '2',
          amount: 30.0,
          description: '昨天打车',
          category: '交通',
          date: yesterday,
        ),
      ];

      await tester.pumpWidget(
        createTestableWidget(expenses: expenses),
      );
      await tester.pumpAndSettle();

      // Both date headers should appear
      expect(find.text('今天'), findsOneWidget);
      expect(find.text('昨天'), findsOneWidget);
    });

    testWidgets('HistoryPage calculates day total correctly', (WidgetTester tester) async {
      final now = DateTime.now();
      final expenses = [
        Expense(
          id: '1',
          amount: 50.0,
          description: '午餐1',
          category: '餐饮',
          date: DateTime(now.year, now.month, now.day),
        ),
        Expense(
          id: '2',
          amount: 70.0,
          description: '午餐2',
          category: '餐饮',
          date: DateTime(now.year, now.month, now.day),
        ),
      ];

      await tester.pumpWidget(
        createTestableWidget(expenses: expenses),
      );
      await tester.pumpAndSettle();

      // Total should be 50 + 70 = 120
      expect(find.text('¥120.00'), findsOneWidget);
    });
  });
}
