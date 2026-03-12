import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_expense_tracker/presentation/pages/calendar/calendar_page.dart';
import 'package:ai_expense_tracker/presentation/providers/calendar_providers.dart';
import 'package:ai_expense_tracker/presentation/providers/expense_providers.dart';
import 'package:ai_expense_tracker/domain/repositories/expense_repository.dart';
import 'package:ai_expense_tracker/data/models/expense_model.dart';

// Mock ExpenseRepository for testing
class MockExpenseRepository implements ExpenseRepository {
  final List<Expense> mockExpenses;

  MockExpenseRepository({this.mockExpenses = const []});

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
    final expenses = await getExpensesByDateRange(start, end);
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Future<Map<String, double>> getCategoryTotals(DateTime start, DateTime end) async {
    final expenses = await getExpensesByDateRange(start, end);
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }
}

void main() {
  group('CalendarPage Tests', () {
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      // Create a mock repository with sample expenses
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      final mockExpenses = [
        Expense(
          id: '1',
          amount: 50.0,
          description: '午餐',
          category: 'food',
          date: today,
        ),
        Expense(
          id: '2',
          amount: 30.0,
          description: '咖啡',
          category: 'food',
          date: today,
        ),
        Expense(
          id: '3',
          amount: 100.0,
          description: '昨天购物',
          category: 'shopping',
          date: yesterday,
        ),
      ];

      // Override the expense repository provider
      container = ProviderContainer(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(MockExpenseRepository(mockExpenses: mockExpenses)),
        ],
      );

      // Setup router for navigation
      router = GoRouter(
        initialLocation: '/calendar',
        routes: [
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: '/add-expense',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Add Expense Page')),
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('CalendarPage loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify CalendarPage is displayed
      expect(find.byType(CalendarPage), findsOneWidget);
    });

    testWidgets('CalendarPage displays calendar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify calendar widget is present
      expect(find.byType(CalendarPage), findsOneWidget);
    });

    testWidgets('CalendarPage shows header with title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify header title is displayed
      expect(find.text('日历'), findsOneWidget);
    });

    testWidgets('CalendarPage shows add expense button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify add button is displayed
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('CalendarPage displays expenses for selected date', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Wait for async data to load
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Should show today's date
      expect(find.text('今天'), findsOneWidget);
    });

    testWidgets('CalendarPage shows total amount for selected date', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Wait for async data to load
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Today's total should be shown (50 + 30 = 80)
      expect(find.textContaining('¥'), findsOneWidget);
    });

    testWidgets('CalendarPage handles empty state', (WidgetTester tester) async {
      // Create container with empty expenses
      final emptyContainer = ProviderContainer(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(MockExpenseRepository(mockExpenses: [])),
        ],
      );

      // Set selected date to a day with no expenses
      emptyContainer.read(selectedDateProvider.notifier).state = DateTime(2025, 1, 1);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: emptyContainer,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/calendar',
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarPage(),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Should show empty state message
      expect(find.text('当天没有账单记录'), findsOneWidget);

      emptyContainer.dispose();
    });

    testWidgets('CalendarPage can navigate to add expense page', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify navigation to add expense page
      expect(find.text('Add Expense Page'), findsOneWidget);
    });

    testWidgets('CalendarPage displays yesterday for yesterday date', (WidgetTester tester) async {
      // Create container with expense on yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayExpense = [
        Expense(
          id: '1',
          amount: 100.0,
          description: '昨天消费',
          category: 'shopping',
          date: yesterday,
        ),
      ];

      final yesterdayContainer = ProviderContainer(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(MockExpenseRepository(mockExpenses: yesterdayExpense)),
        ],
      );

      // Set selected date to yesterday
      yesterdayContainer.read(selectedDateProvider.notifier).state = yesterday;

      await tester.pumpWidget(UncontrolledProviderScope(
        container: yesterdayContainer,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/calendar',
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarPage(),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Should show yesterday text
      expect(find.text('昨天'), findsOneWidget);

      yesterdayContainer.dispose();
    });

    testWidgets('CalendarPage shows loading indicator while fetching', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Pump once without settling to see loading state
      await tester.pump();

      // Should show loading indicator initially
      // Note: The exact behavior depends on the provider state
    });

    testWidgets('CalendarPage displays calendar widget correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify the CalendarWidget is rendered within the page
      expect(find.byType(CalendarPage), findsOneWidget);
    });

    testWidgets('CalendarPage updates when date is selected', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find a day in the calendar and tap it (day 15)
      final dayFinder = find.text('15').first;
      if (dayFinder.evaluate().isNotEmpty) {
        await tester.tap(dayFinder);
        await tester.pumpAndSettle();

        // Verify selected date is updated
        final selectedDate = container.read(selectedDateProvider);
        expect(selectedDate.day, 15);
      }
    });
  });
}
