import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/expense_model.dart';
import '../../providers/calendar_providers.dart';
import '../../providers/expense_providers.dart';
import '../../widgets/calendar/calendar_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/expense_card.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedDateExpenses = ref.watch(selectedDateExpensesProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Calendar Widget
                      CalendarWidget(
                        onDaySelected: (selected, focused) {
                          // Calendar widget handles state internally
                        },
                      ),
                      const SizedBox(height: 16),
                      // Selected date info and expenses
                      Expanded(
                        child: _buildSelectedDateExpenses(selectedDate, selectedDateExpenses),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Text(
            '日历',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => context.push('/add-expense'),
              tooltip: '添加账单',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDateExpenses(
    DateTime selectedDate,
    AsyncValue<List<Expense>> expensesAsync,
  ) {
    final dateFormat = DateFormat('yyyy年MM月dd日');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String displayDate;
    if (selectedDate == today) {
      displayDate = '今天';
    } else if (selectedDate == yesterday) {
      displayDate = '昨天';
    } else {
      displayDate = dateFormat.format(selectedDate);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayDate,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              expensesAsync.when(
                data: (expenses) {
                  final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
                  if (total > 0) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '¥${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.expense,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Expense list
        Expanded(
          child: expensesAsync.when(
            data: (expenses) {
              if (expenses.isEmpty) {
                return Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const EmptyState(
                    message: '当天没有账单记录',
                    icon: Icons.event_note,
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return ExpenseCard(
                    expense: expense,
                    onDelete: () {
                      ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                      // Invalidate to refresh
                      ref.invalidate(selectedDateExpensesProvider);
                    },
                    onTap: () => context.push('/add-expense?id=${expense.id}'),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('加载失败: $e'),
            ),
          ),
        ),
      ],
    );
  }
}
