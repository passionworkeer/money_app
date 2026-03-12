import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/calendar_providers.dart';

class CalendarWidget extends ConsumerWidget {
  final Function(DateTime, DateTime)? onDaySelected;
  final Function(DateTime)? onPageChanged;

  const CalendarWidget({
    super.key,
    this.onDaySelected,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final focusedMonth = ref.watch(focusedMonthProvider);
    final viewMode = ref.watch(calendarViewModeProvider);
    final monthlyTotals = ref.watch(monthlyDailyTotalsProvider(focusedMonth));

    return Column(
      children: [
        // Quick date filter chips
        _buildQuickDateFilter(ref),
        const SizedBox(height: 8),
        // View mode toggle
        _buildViewModeToggle(ref, viewMode),
        const SizedBox(height: 8),
        // Calendar
        monthlyTotals.when(
          data: (totals) => _buildCalendar(
            ref,
            selectedDate,
            focusedMonth,
            viewMode,
            totals,
          ),
          loading: () => const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 300,
            child: Center(child: Text('加载失败: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDateFilter(WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: QuickDateFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.label),
              selected: ref.watch(quickDateFilterProvider) == filter,
              onSelected: (selected) {
                if (selected) {
                  ref.read(quickDateFilterProvider.notifier).state = filter;
                  applyQuickDateFilter(ref, filter);
                } else {
                  ref.read(quickDateFilterProvider.notifier).state = null;
                }
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: ref.watch(quickDateFilterProvider) == filter
                    ? AppColors.primary
                    : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildViewModeToggle(WidgetRef ref, CalendarViewMode viewMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SegmentedButton<CalendarViewMode>(
            segments: const [
              ButtonSegment(
                value: CalendarViewMode.month,
                label: Text('月'),
              ),
              ButtonSegment(
                value: CalendarViewMode.week,
                label: Text('周'),
              ),
            ],
            selected: {viewMode},
            onSelectionChanged: (selected) {
              ref.read(calendarViewModeProvider.notifier).state = selected.first;
            },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(
    WidgetRef ref,
    DateTime selectedDate,
    DateTime focusedMonth,
    CalendarViewMode viewMode,
    Map<DateTime, double> dailyTotals,
  ) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: focusedMonth,
      selectedDayPredicate: (day) => isSameDay(selectedDate, day),
      calendarFormat: viewMode == CalendarViewMode.month
          ? CalendarFormat.month
          : CalendarFormat.week,
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableGestures: AvailableGestures.horizontalSwipe,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primary),
        rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primary),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        weekendStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.bold,
        ),
        selectedDecoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        defaultTextStyle: TextStyle(color: Colors.grey.shade800),
        weekendTextStyle: TextStyle(color: Colors.grey.shade700),
        markerDecoration: const BoxDecoration(
          color: AppColors.expense,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 0,
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          return _buildDayCell(day, dailyTotals, false, false);
        },
        todayBuilder: (context, day, focusedDay) {
          return _buildDayCell(day, dailyTotals, true, false);
        },
        selectedBuilder: (context, day, focusedDay) {
          return _buildDayCell(day, dailyTotals, false, true);
        },
        markerBuilder: (context, day, events) {
          return const SizedBox.shrink();
        },
      ),
      onDaySelected: (selectedDay, focusedDay) {
        ref.read(selectedDateProvider.notifier).state = selectedDay;
        ref.read(focusedMonthProvider.notifier).state = focusedDay;
        ref.read(quickDateFilterProvider.notifier).state = null;
        if (onDaySelected != null) {
          onDaySelected!(selectedDay, focusedDay);
        }
      },
      onPageChanged: (focusedDay) {
        ref.read(focusedMonthProvider.notifier).state = focusedDay;
        if (onPageChanged != null) {
          onPageChanged!(focusedDay);
        }
      },
    );
  }

  Widget _buildDayCell(
    DateTime day,
    Map<DateTime, double> dailyTotals,
    bool isToday,
    bool isSelected,
  ) {
    final dateKey = DateTime(day.year, day.month, day.day);
    final total = dailyTotals[dateKey];

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary
            : isToday
                ? AppColors.primary.withOpacity(0.3)
                : null,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : isToday
                      ? AppColors.primaryDark
                      : Colors.grey.shade800,
              fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (total != null && total > 0)
            Positioned(
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _getAmountColor(total).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatAmount(total),
                  style: TextStyle(
                    fontSize: 8,
                    color: isSelected ? Colors.white : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getAmountColor(double amount) {
    if (amount < 50) return Colors.green;
    if (amount < 100) return Colors.lightGreen;
    if (amount < 200) return Colors.orange;
    if (amount < 500) return Colors.deepOrange;
    return Colors.red;
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
