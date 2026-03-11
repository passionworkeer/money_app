import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/report_models.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/datasources/local/database_helper.dart';
import '../providers/expense_providers.dart';
import '../providers/settings_providers.dart';
import '../providers/budget_providers.dart';
import '../../core/services/ai_analysis_service.dart';

/// Repository Provider
final reportExpenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl();
});

/// AI Analysis Service Provider
final aiAnalysisServiceProvider = Provider<AIAnalysisService>((ref) {
  return AIAnalysisService();
});

/// 月度报表 Provider
/// 参数为 year * 100 + month，例如 202601 表示 2026年1月
final monthlyReportProvider = FutureProvider.family<MonthlyReport, int>((ref, yearMonth) async {
  final repository = ref.watch(reportExpenseRepositoryProvider);
  final year = yearMonth ~/ 100;
  final month = yearMonth % 100;

  final startDate = DateTime(year, month, 1);
  final endDate = DateTimeUtils.endOfMonth(startDate);

  // 获取当月数据
  final expenses = await repository.getExpensesByDateRange(startDate, endDate);
  final categoryTotals = await repository.getCategoryTotals(startDate, endDate);

  // 计算上月数据
  final lastMonthStart = DateTime(year, month - 1, 1);
  final lastMonthEnd = DateTimeUtils.endOfMonth(lastMonthStart);
  final lastMonthTotal = await repository.getTotalByDateRange(lastMonthStart, lastMonthEnd);

  // 获取预算
  final budget = await DatabaseHelper.instance.getBudgetByMonth(year, month);

  // 计算每日消费
  final dailySpending = _calculateDailySpending(expenses);

  // 生成 AI 洞察
  final settings = await DatabaseHelper.instance.getSettings();
  String? aiInsight;
  if (expenses.isNotEmpty) {
    final aiService = ref.read(aiAnalysisServiceProvider);
    aiInsight = await aiService.generateMonthlyReport(expenses, budget, settings);
  }

  return MonthlyReport(
    year: year,
    month: month,
    totalAmount: categoryTotals.values.fold(0.0, (a, b) => a + b),
    expenseCount: expenses.length,
    categoryTotals: categoryTotals,
    budget: budget?.amount,
    lastMonthTotal: lastMonthTotal,
    dailySpending: dailySpending,
    aiInsight: aiInsight,
  );
});

/// 年度报表 Provider
/// 参数为年份，例如 2026
final yearlyReportProvider = FutureProvider.family<YearlyReport, int>((ref, year) async {
  final repository = ref.watch(reportExpenseRepositoryProvider);

  final startDate = DateTime(year, 1, 1);
  final endDate = DateTime(year, 12, 31);

  // 获取全年数据
  final expenses = await repository.getExpensesByDateRange(startDate, endDate);
  final categoryTotals = await repository.getCategoryTotals(startDate, endDate);

  // 计算每月数据
  final monthlyTotals = <String, double>{};
  final monthDataList = <MonthData>[];

  for (int month = 1; month <= 12; month++) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTimeUtils.endOfMonth(monthStart);
    final monthTotal = await repository.getTotalByDateRange(monthStart, monthEnd);
    final monthExpenses = await repository.getExpensesByDateRange(monthStart, monthEnd);

    monthlyTotals['$month'] = monthTotal;
    monthDataList.add(MonthData(
      month: month,
      amount: monthTotal,
      expenseCount: monthExpenses.length,
    ));
  }

  // 获取年度预算
  final allBudgets = await DatabaseHelper.instance.getAllBudgets();
  final yearBudgets = allBudgets.where((b) => b.year == year).toList();
  final totalBudget = yearBudgets.isEmpty ? null : yearBudgets.fold(0.0, (sum, b) => sum + b.amount);

  return YearlyReport(
    year: year,
    totalAmount: categoryTotals.values.fold(0.0, (a, b) => a + b),
    expenseCount: expenses.length,
    monthlyTotals: monthlyTotals,
    categoryTotals: categoryTotals,
    budget: totalBudget,
    months: monthDataList,
  );
});

/// 消费趋势 Provider
final spendingTrendProvider = FutureProvider.family<List<TrendPoint>, TrendPeriod>((ref, period) async {
  final repository = ref.watch(reportExpenseRepositoryProvider);
  final now = DateTime.now();

  List<DateTime> datePoints;
  switch (period) {
    case TrendPeriod.week:
      datePoints = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
      break;
    case TrendPeriod.month:
      datePoints = List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));
      break;
    case TrendPeriod.year:
      datePoints = List.generate(12, (i) => DateTime(now.year, now.month - i, 1));
      break;
  }

  final trendPoints = <TrendPoint>[];

  for (final date in datePoints) {
    DateTime start, end;

    if (period == TrendPeriod.year) {
      start = DateTime(date.year, date.month, 1);
      end = DateTimeUtils.endOfMonth(start);
    } else {
      start = DateTimeUtils.startOfDay(date);
      end = DateTimeUtils.endOfDay(date);
    }

    final expenses = await repository.getExpensesByDateRange(start, end);
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

    trendPoints.add(TrendPoint(
      date: date,
      amount: total,
      count: expenses.length,
    ));
  }

  return trendPoints;
});

/// Top 分类列表 Provider
final topCategoriesProvider = FutureProvider.family<List<CategoryData>, int>((ref, yearMonth) async {
  final reportAsync = await ref.watch(monthlyReportProvider(yearMonth).future);
  return reportAsync.sortedCategories.take(5).toList();
});

/// AI 洞察 Provider
final spendingInsightProvider = FutureProvider.family<SpendingInsight?, int>((ref, yearMonth) async {
  final expenses = await ref.watch(allExpensesProvider.future);
  final settings = await ref.watch(settingsProvider.future);

  if (expenses.isEmpty) return null;

  final now = DateTime.now();
  final year = yearMonth ~/ 100;
  final month = yearMonth % 100;

  final monthExpenses = expenses.where((e) =>
    e.date.year == year && e.date.month == month).toList();

  if (monthExpenses.isEmpty) return null;

  final aiService = ref.read(aiAnalysisServiceProvider);
  final habits = await aiService.analyzeSpendingHabits(monthExpenses, settings);

  // 构建洞察
  final summary = _buildSummary(habits);
  final suggestions = _buildSuggestions(habits);
  final trend = _buildTrend(habits);
  final warning = _buildWarning(habits);

  return SpendingInsight(
    summary: summary,
    suggestions: suggestions,
    trend: trend,
    warning: warning,
  );
});

/// 辅助函数：计算每日消费
List<DailySpending> _calculateDailySpending(List<Expense> expenses) {
  final dailyMap = <String, double>{};

  for (final expense in expenses) {
    final key = '${expense.date.year}-${expense.date.month}-${expense.date.day}';
    dailyMap[key] = (dailyMap[key] ?? 0) + expense.amount;
  }

  return dailyMap.entries
      .map((e) {
        final parts = e.key.split('-');
        return DailySpending(
          date: DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          ),
          amount: e.value,
        );
      })
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
}

/// 辅助函数：构建摘要
String _buildSummary(Map<String, dynamic> habits) {
  final total = habits['thisMonthTotal'] ?? 0.0;
  final count = habits['expenseCount'] ?? 0;
  final change = habits['monthOverMonthChange'] ?? 0.0;

  String changeText = '';
  if (change > 0) {
    changeText = '较上月增长 ${change.toStringAsFixed(1)}%';
  } else if (change < 0) {
    changeText = '较上月下降 ${(-change).toStringAsFixed(1)}%';
  } else {
    changeText = '与上月持平';
  }

  return '本月共消费 $count 笔，总计 ¥${total.toStringAsFixed(2)}，$changeText';
}

/// 辅助函数：构建建议
List<String> _buildSuggestions(Map<String, dynamic> habits) {
  final suggestions = <String>[];

  final change = habits['monthOverMonthChange'] ?? 0.0;
  if (change > 20) {
    suggestions.add('本月消费增长较快，建议关注非必要支出');
  }

  final avgExpense = habits['averageExpense'] ?? 0.0;
  if (avgExpense > 200) {
    suggestions.add('平均每笔消费较高，可以考虑设置单笔预算');
  }

  final topDay = habits['topSpendingDay'];
  if (topDay != null) {
    suggestions.add('$topDay 是消费高峰日，建议提前规划');
  }

  if (suggestions.isEmpty) {
    suggestions.add('继续保持良好的消费习惯');
  }

  return suggestions;
}

/// 辅助函数：构建趋势描述
String? _buildTrend(Map<String, dynamic> habits) {
  final change = habits['monthOverMonthChange'] ?? 0.0;

  if (change > 30) return '消费大幅上升';
  if (change > 10) return '消费有所上升';
  if (change < -30) return '消费大幅下降';
  if (change < -10) return '消费有所下降';
  return '消费基本稳定';
}

/// 辅助函数：构建警告
String? _buildWarning(Map<String, dynamic> habits) {
  final budget = habits['budget'];
  final total = habits['thisMonthTotal'] ?? 0.0;

  if (budget != null && total > budget) {
    return '已超出预算 ¥${(total - budget).toStringAsFixed(2)}';
  }
  return null;
}
