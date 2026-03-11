import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/expense_model.dart';
import 'expense_providers.dart';

// Calendar selected date provider
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Calendar focused month provider
final focusedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Calendar view mode provider (month/week)
enum CalendarViewMode { month, week }

final calendarViewModeProvider = StateProvider<CalendarViewMode>((ref) => CalendarViewMode.month);

// Daily expenses by date provider
final dailyExpensesProvider = FutureProvider.family<List<Expense>, DateTime>((ref, date) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getExpensesByDateRange(
    DateTimeUtils.startOfDay(date),
    DateTimeUtils.endOfDay(date),
  );
});

// Monthly daily totals for calendar markers
final monthlyDailyTotalsProvider = FutureProvider.family<Map<DateTime, double>, DateTime>((ref, month) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final startOfMonth = DateTimeUtils.startOfMonth(month);
  final endOfMonth = DateTimeUtils.endOfMonth(month);

  final expenses = await repository.getExpensesByDateRange(startOfMonth, endOfMonth);

  final dailyTotals = <DateTime, double>{};
  for (final expense in expenses) {
    final dateKey = DateTime(expense.date.year, expense.date.month, expense.date.day);
    dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + expense.amount;
  }

  return dailyTotals;
});

// Selected date expenses provider (derived from selected date)
final selectedDateExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getExpensesByDateRange(
    DateTimeUtils.startOfDay(selectedDate),
    DateTimeUtils.endOfDay(selectedDate),
  );
});

// Quick date filter options
enum QuickDateFilter {
  today('今天'),
  yesterday('昨天'),
  thisWeek('本周'),
  lastWeek('上周'),
  thisMonth('本月'),
  lastMonth('上月');

  final String label;
  const QuickDateFilter(this.label);
}

final quickDateFilterProvider = StateProvider<QuickDateFilter?>((ref) => null);

// Date range for filtering
final dateRangeProvider = StateProvider<(DateTime?, DateTime?)>((ref) => (null, null));

// Apply quick date filter
void applyQuickDateFilter(WidgetRef ref, QuickDateFilter filter) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  switch (filter) {
    case QuickDateFilter.today:
      ref.read(selectedDateProvider.notifier).state = today;
      ref.read(dateRangeProvider.notifier).state = (today, today);
      break;
    case QuickDateFilter.yesterday:
      final yesterday = today.subtract(const Duration(days: 1));
      ref.read(selectedDateProvider.notifier).state = yesterday;
      ref.read(dateRangeProvider.notifier).state = (yesterday, yesterday);
      break;
    case QuickDateFilter.thisWeek:
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      ref.read(dateRangeProvider.notifier).state = (weekStart, weekEnd);
      ref.read(selectedDateProvider.notifier).state = today;
      break;
    case QuickDateFilter.lastWeek:
      final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
      final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
      final lastWeekEnd = lastWeekStart.add(const Duration(days: 6));
      ref.read(dateRangeProvider.notifier).state = (lastWeekStart, lastWeekEnd);
      ref.read(selectedDateProvider.notifier).state = lastWeekStart;
      break;
    case QuickDateFilter.thisMonth:
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      ref.read(dateRangeProvider.notifier).state = (monthStart, monthEnd);
      ref.read(selectedDateProvider.notifier).state = today;
      break;
    case QuickDateFilter.lastMonth:
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);
      ref.read(dateRangeProvider.notifier).state = (lastMonthStart, lastMonthEnd);
      ref.read(selectedDateProvider.notifier).state = lastMonthStart;
      break;
  }
}
