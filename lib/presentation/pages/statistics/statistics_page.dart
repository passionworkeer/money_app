import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/budget_model.dart';
import '../../providers/budget_providers.dart';
import '../../providers/expense_providers.dart';
import '../../widgets/chart_widgets.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/empty_state.dart';

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  int _selectedMonthOffset = 0;

  DateTime get _selectedMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _selectedMonthOffset, 1);
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final monthTotal = ref.watch(monthTotalProvider);
    final currentBudget = ref.watch(currentMonthBudgetProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
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
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(categoryTotalsProvider);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMonthSelector(),
                          const SizedBox(height: 20),
                          categoryTotals.when(
                            data: (totals) {
                              if (totals.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const EmptyState(
                                    message: '本月暂无消费记录\n开始记账吧！',
                                    icon: Icons.pie_chart_outline,
                                  ),
                                );
                              }
                              final total = totals.values.fold(0.0, (a, b) => a + b);
                              final dayOfMonth = DateTime.now().day;
                              final budget = currentBudget.valueOrNull;
                              final monthTotalValue = monthTotal.valueOrNull ?? 0.0;
                              return Column(
                                children: [
                                  _buildTotalCard(total, dayOfMonth, budget, monthTotalValue),
                                  const SizedBox(height: 20),
                                  _buildPieChart(totals, total),
                                  const SizedBox(height: 20),
                                  _buildCategoryList(totals, total),
                                ],
                              );
                            },
                            loading: () => Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) => Center(child: Text('Error: $e')),
                          ),
                        ],
                      ),
                    ),
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
            '消费统计',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/report'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.analytics_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    '报表',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => setState(() => _selectedMonthOffset--),
            icon: const Icon(Icons.chevron_left),
            color: AppColors.primary,
          ),
          Text(
            '${_selectedMonth.year}年${_selectedMonth.month}月',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _selectedMonthOffset < 0
                ? () => setState(() => _selectedMonthOffset++)
                : null,
            icon: Icon(
              Icons.chevron_right,
              color: _selectedMonthOffset < 0 ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(double total, int dayOfMonth, Budget? budget, double monthTotal) {
    // Calculate budget execution rate
    double? executionRate;
    bool isExceeded = false;
    if (budget != null && budget.amount > 0) {
      executionRate = (total / budget.amount) * 100;
      isExceeded = total > budget.amount;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11998e).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '本月支出',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '¥',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                total.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '日均 ¥${(total / dayOfMonth).toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Budget execution rate
          if (executionRate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isExceeded
                    ? Colors.red.withOpacity(0.3)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isExceeded ? Icons.warning_rounded : Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isExceeded
                        ? '预算执行率 ${executionRate.toStringAsFixed(1)}% (已超支)'
                        : '预算执行率 ${executionRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> totals, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '分类占比',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChartWidget(
              categoryTotals: totals,
              total: total,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(Map<String, double> totals, double total) {
    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '分类详情',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedEntries.map((entry) {
            final category = ExpenseCategory.fromValue(entry.key);
            final color = AppColors.categoryColors[entry.key] ?? Colors.grey;
            final percentage = total > 0 ? (entry.value / total * 100) : 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CategoryIconHelper.getIcon(category),
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category.label,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '¥${entry.value.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: color.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
