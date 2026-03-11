import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ai_expense_tracker/presentation/widgets/calendar/calendar_widget.dart';
import 'package:ai_expense_tracker/presentation/providers/calendar_providers.dart';
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
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
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

// Override provider with mock repository
final mockExpenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return MockExpenseRepository();
});

void main() {
  group('CalendarWidget Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget({Function(DateTime, DateTime)? onDaySelected}) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: CalendarWidget(
              onDaySelected: onDaySelected,
            ),
          ),
        ),
      );
    }

    testWidgets('CalendarWidget can be created', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify CalendarWidget is rendered
      expect(find.byType(CalendarWidget), findsOneWidget);
    });

    testWidgets('CalendarWidget displays calendar with table_calendar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify TableCalendar is rendered
      expect(find.byType(TableCalendar), findsOneWidget);
    });

    testWidgets('CalendarWidget shows current month by default', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];

      // Verify current month is displayed in header
      expect(find.text('${monthNames[now.month - 1]} ${now.year}'), findsOneWidget);
    });

    testWidgets('CalendarWidget can select a date', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Get today's day number
      final now = DateTime.now();
      final todayText = '${now.day}';

      // Find and tap on today's date
      final dayFinder = find.text(todayText).first;
      expect(dayFinder, findsOneWidget);

      await tester.tap(dayFinder);
      await tester.pumpAndSettle();

      // Verify selected date is updated in provider
      final selectedDate = container.read(selectedDateProvider);
      expect(selectedDate.day, now.day);
      expect(selectedDate.month, now.month);
      expect(selectedDate.year, now.year);
    });

    testWidgets('CalendarWidget fires callback on date selected', (WidgetTester tester) async {
      DateTime? selectedDay;
      DateTime? focusedDay;
      bool callbackFired = false;

      await tester.pumpWidget(createTestWidget(
        onDaySelected: (selected, focused) {
          selectedDay = selected;
          focusedDay = focused;
          callbackFired = true;
        },
      ));
      await tester.pumpAndSettle();

      // Tap on a day (day 15)
      final dayFinder = find.text('15').first;
      if (dayFinder.evaluate().isNotEmpty) {
        await tester.tap(dayFinder);
        await tester.pumpAndSettle();

        // Verify callback was fired
        expect(callbackFired, isTrue);
        expect(selectedDay, isNotNull);
      }
    });

    testWidgets('CalendarWidget displays quick date filter chips', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify quick date filter chips are displayed
      expect(find.text('今天'), findsOneWidget);
      expect(find.text('昨天'), findsOneWidget);
      expect(find.text('本周'), findsOneWidget);
      expect(find.text('上周'), findsOneWidget);
      expect(find.text('本月'), findsOneWidget);
      expect(find.text('上月'), findsOneWidget);
    });

    testWidgets('CalendarWidget displays month/week view mode toggle', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify view mode toggle is displayed
      expect(find.text('月'), findsOneWidget);
      expect(find.text('周'), findsOneWidget);
    });

    testWidgets('CalendarWidget can switch between month and week view', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially should be in month view
      var viewMode = container.read(calendarViewModeProvider);
      expect(viewMode, CalendarViewMode.month);

      // Tap on week view
      await tester.tap(find.text('周'));
      await tester.pumpAndSettle();

      // Verify view mode changed to week
      viewMode = container.read(calendarViewModeProvider);
      expect(viewMode, CalendarViewMode.week);

      // Tap on month view
      await tester.tap(find.text('月'));
      await tester.pumpAndSettle();

      // Verify view mode changed back to month
      viewMode = container.read(calendarViewModeProvider);
      expect(viewMode, CalendarViewMode.month);
    });

    testWidgets('CalendarWidget shows days of week headers', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify days of week are displayed (Monday as starting day)
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
    });

    testWidgets('CalendarWidget can navigate to previous month', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);

      // Find and tap left chevron
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // Verify focused month changed to previous month
      final focusedMonth = container.read(focusedMonthProvider);
      expect(focusedMonth.month, currentMonth.subtract(const Duration(days: 1)).month);
    });

    testWidgets('CalendarWidget can navigate to next month', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);

      // Find and tap right chevron
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Verify focused month changed to next month
      final focusedMonth = container.read(focusedMonthProvider);
      expect(focusedMonth.month, currentMonth.add(const Duration(days: 31)).month);
    });
  });
}
