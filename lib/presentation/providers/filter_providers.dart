import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/filter_options.dart';
import 'expense_providers.dart';

// 当前筛选选项
final filterOptionsProvider = StateProvider<FilterOptions>((ref) {
  return const FilterOptions();
});

// 筛选后的账单列表
final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final expensesAsync = ref.watch(allExpensesProvider);
  final expenses = expensesAsync.valueOrNull ?? [];
  final filters = ref.watch(filterOptionsProvider);
  return _applyFilters(expenses, filters);
});

// 活跃筛选数量
final activeFilterCountProvider = Provider<int>((ref) {
  final filters = ref.watch(filterOptionsProvider);
  int count = 0;
  if (filters.category != null) count++;
  if (filters.minAmount != null) count++;
  if (filters.maxAmount != null) count++;
  if (filters.startDate != null) count++;
  if (filters.endDate != null) count++;
  return count;
});

List<Expense> _applyFilters(List<Expense> expenses, FilterOptions filters) {
  var result = expenses;

  // 搜索筛选
  if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
    final query = filters.searchQuery!.toLowerCase();
    result = result.where((e) =>
      e.description.toLowerCase().contains(query)
    ).toList();
  }

  // 分类筛选
  if (filters.category != null) {
    result = result.where((e) => e.category == filters.category).toList();
  }

  // 金额范围筛选
  if (filters.minAmount != null) {
    result = result.where((e) => e.amount >= filters.minAmount!).toList();
  }
  if (filters.maxAmount != null) {
    result = result.where((e) => e.amount <= filters.maxAmount!).toList();
  }

  // 日期范围筛选
  if (filters.startDate != null) {
    final startOfDay = DateTime(
      filters.startDate!.year,
      filters.startDate!.month,
      filters.startDate!.day,
    );
    result = result.where((e) =>
      e.date.isAfter(startOfDay.subtract(const Duration(days: 1))) ||
      e.date.isAtSameMomentAs(startOfDay)
    ).toList();
  }
  if (filters.endDate != null) {
    final endOfDay = DateTime(
      filters.endDate!.year,
      filters.endDate!.month,
      filters.endDate!.day,
      23, 59, 59,
    );
    result = result.where((e) =>
      e.date.isBefore(endOfDay.add(const Duration(days: 1))) ||
      e.date.isAtSameMomentAs(endOfDay)
    ).toList();
  }

  // 排序
  switch (filters.sortBy) {
    case SortBy.dateDesc:
      result.sort((a, b) => b.date.compareTo(a.date));
    case SortBy.dateAsc:
      result.sort((a, b) => a.date.compareTo(b.date));
    case SortBy.amountDesc:
      result.sort((a, b) => b.amount.compareTo(a.amount));
    case SortBy.amountAsc:
      result.sort((a, b) => a.amount.compareTo(b.amount));
  }

  return result;
}
