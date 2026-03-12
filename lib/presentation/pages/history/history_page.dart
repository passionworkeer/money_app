import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/categories.dart';
import '../../../core/services/export_service.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/filter_options.dart';
import '../../providers/expense_providers.dart';
import '../../providers/filter_providers.dart';
import '../../widgets/expense_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/filter_bottom_sheet.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final _exportService = ExportService();

  @override
  Widget build(BuildContext context) {
    final filterOptions = ref.watch(filterOptionsProvider);
    final filteredExpenses = ref.watch(filteredExpensesProvider);
    final activeFilterCount = ref.watch(activeFilterCountProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFee0979), Color(0xFFff6a00)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(activeFilterCount > 0),
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
                      _buildSearchBar(),
                      _buildActiveFilterChips(filterOptions),
                      Expanded(
                        child: _buildExpenseList(filteredExpenses),
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

  Widget _buildHeader(bool hasActiveFilters) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Text(
            '消费记录',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '已筛选',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: () => showFilterBottomSheet(context),
                  tooltip: '筛选',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'export') {
                      _exportData();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(AppStrings.exportCsv),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final filterOptions = ref.watch(filterOptionsProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索账单备注...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon: filterOptions.searchQuery?.isNotEmpty == true
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade400),
                  onPressed: () {
                    ref.read(filterOptionsProvider.notifier).state =
                        filterOptions.copyWith(clearSearchQuery: true);
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
        },
        onSubmitted: (value) {
          ref.read(filterOptionsProvider.notifier).state =
              filterOptions.copyWith(searchQuery: value);
        },
      ),
    );
  }

  Widget _buildActiveFilterChips(FilterOptions filterOptions) {
    if (!filterOptions.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (filterOptions.category != null) ...[
              _buildFilterChip(
                label: _getCategoryLabel(filterOptions.category!),
                onRemove: () {
                  ref.read(filterOptionsProvider.notifier).state =
                      filterOptions.copyWith(clearCategory: true);
                },
              ),
              const SizedBox(width: 8),
            ],
            if (filterOptions.minAmount != null || filterOptions.maxAmount != null) ...[
              _buildFilterChip(
                label: _getAmountLabel(filterOptions.minAmount, filterOptions.maxAmount),
                onRemove: () {
                  ref.read(filterOptionsProvider.notifier).state =
                      filterOptions.copyWith(clearMinAmount: true, clearMaxAmount: true);
                },
              ),
              const SizedBox(width: 8),
            ],
            if (filterOptions.startDate != null || filterOptions.endDate != null) ...[
              _buildFilterChip(
                label: _getDateLabel(filterOptions.startDate, filterOptions.endDate),
                onRemove: () {
                  ref.read(filterOptionsProvider.notifier).state =
                      filterOptions.copyWith(clearStartDate: true, clearEndDate: true);
                },
              ),
              const SizedBox(width: 8),
            ],
            if (filterOptions.sortBy != SortBy.dateDesc) ...[
              _buildFilterChip(
                label: filterOptions.sortBy.label,
                onRemove: () {
                  ref.read(filterOptionsProvider.notifier).state =
                      filterOptions.copyWith(sortBy: SortBy.dateDesc);
                },
              ),
              const SizedBox(width: 8),
            ],
            TextButton(
              onPressed: () {
                ref.read(filterOptionsProvider.notifier).state = const FilterOptions();
              },
              child: const Text(
                '清除全部',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(String category) {
    try {
      return ExpenseCategory.fromValue(category).label;
    } catch (_) {
      return category;
    }
  }

  String _getAmountLabel(double? min, double? max) {
    if (min == null && max == null) return '';
    if (min == null) return '~${max!.toStringAsFixed(0)}';
    if (max == null) return '${min.toStringAsFixed(0)}+';
    return '${min.toStringAsFixed(0)}-${max.toStringAsFixed(0)}';
  }

  String _getDateLabel(DateTime? start, DateTime? end) {
    final dateFormat = DateFormat('MM/dd');
    if (start != null && end != null) {
      if (_isSameDay(start, end)) {
        return dateFormat.format(start);
      }
      return '${dateFormat.format(start)}-${dateFormat.format(end)}';
    }
    if (start != null) return '${dateFormat.format(start)}~';
    if (end != null) return '~${dateFormat.format(end)}';
    return '';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildExpenseList(List<Expense> expenses) {
    if (expenses.isEmpty) {
      final filterOptions = ref.watch(filterOptionsProvider);
      final isFiltering = filterOptions.hasActiveFilters;
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: EmptyState(
          message: isFiltering ? '没有找到匹配的记录' : '暂无记录',
          icon: isFiltering ? Icons.search_off : Icons.history,
        ),
      );
    }

    final grouped = _groupByDate(expenses);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allExpensesProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final date = grouped.keys.elementAt(index);
          final dayExpenses = grouped[date]!;
          final dayTotal = dayExpenses.fold(0.0, (sum, e) => sum + e.amount);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateHeader(date, dayTotal),
              ...dayExpenses.map((expense) => ExpenseCard(
                    expense: expense,
                    onDelete: () {
                      ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                    },
                    onTap: () => context.push('/add-expense?id=${expense.id}'),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(String dateStr, double total) {
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (e) {
      // 日期解析失败时使用当前日期
      date = DateTime.now();
      debugPrint('Date parse failed: $dateStr, using current date');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String displayDate;
    if (date == today) {
      displayDate = '今天';
    } else if (date == yesterday) {
      displayDate = '昨天';
    } else {
      displayDate = DateFormat('M月d日 EEEE', 'zh_CN').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            displayDate,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '¥${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Expense>> _groupByDate(List<Expense> expenses) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final grouped = <String, List<Expense>>{};

    for (final expense in expenses) {
      final dateKey = dateFormat.format(expense.date);
      grouped.putIfAbsent(dateKey, () => []).add(expense);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  Future<void> _exportData() async {
    final expenses = ref.read(allExpensesProvider).valueOrNull ?? [];
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有数据可导出')),
      );
      return;
    }

    try {
      await _exportService.exportAndShare(expenses);
    } catch (e) {
      // 生产环境不泄露具体错误
      debugPrint('Export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出失败，请重试')),
        );
      }
    }
  }
}

