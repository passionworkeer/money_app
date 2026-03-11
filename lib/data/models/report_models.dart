import '../../core/constants/categories.dart';

/// 月度报表数据模型
class MonthlyReport {
  final int year;
  final int month;
  final double totalAmount;
  final int expenseCount;
  final Map<String, double> categoryTotals;
  final double? budget;
  final double? lastMonthTotal;
  final List<DailySpending> dailySpending;
  final String? aiInsight;

  MonthlyReport({
    required this.year,
    required this.month,
    required this.totalAmount,
    required this.expenseCount,
    required this.categoryTotals,
    this.budget,
    this.lastMonthTotal,
    required this.dailySpending,
    this.aiInsight,
  });

  double get monthOverMonthChange {
    if (lastMonthTotal == null || lastMonthTotal == 0) return 0;
    return (totalAmount - lastMonthTotal!) / lastMonthTotal! * 100;
  }

  double get budgetUsagePercent {
    if (budget == null || budget == 0) return 0;
    return totalAmount / budget! * 100;
  }

  bool get isOverBudget => budget != null && totalAmount > budget!;

  List<CategoryData> get sortedCategories {
    final list = categoryTotals.entries
        .map((e) => CategoryData(
              category: ExpenseCategory.fromValue(e.key),
              amount: e.value,
              percentage: totalAmount > 0 ? e.value / totalAmount * 100 : 0,
            ))
        .toList();
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }
}

/// 分类数据
class CategoryData {
  final ExpenseCategory category;
  final double amount;
  final double percentage;

  CategoryData({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

/// 每日消费数据
class DailySpending {
  final DateTime date;
  final double amount;

  DailySpending({required this.date, required this.amount});
}

/// 年度报表数据模型
class YearlyReport {
  final int year;
  final double totalAmount;
  final int expenseCount;
  final Map<String, double> monthlyTotals;
  final Map<String, double> categoryTotals;
  final double? budget;
  final List<MonthData> months;

  YearlyReport({
    required this.year,
    required this.totalAmount,
    required this.expenseCount,
    required this.monthlyTotals,
    required this.categoryTotals,
    this.budget,
    required this.months,
  });

  double get averageMonthly => months.isEmpty ? 0 : totalAmount / months.length;

  List<CategoryData> get sortedCategories {
    final list = categoryTotals.entries
        .map((e) => CategoryData(
              category: ExpenseCategory.fromValue(e.key),
              amount: e.value,
              percentage: totalAmount > 0 ? e.value / totalAmount * 100 : 0,
            ))
        .toList();
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }
}

/// 月份数据
class MonthData {
  final int month;
  final double amount;
  final int expenseCount;

  MonthData({required this.month, required this.amount, required this.expenseCount});
}

/// 趋势数据点
class TrendPoint {
  final DateTime date;
  final double amount;
  final int count;

  TrendPoint({required this.date, required this.amount, required this.count});
}

/// 趋势周期类型
enum TrendPeriod {
  week,
  month,
  year,
}

/// AI 洞察数据
class SpendingInsight {
  final String summary;
  final List<String> suggestions;
  final String? trend;
  final String? warning;

  SpendingInsight({
    required this.summary,
    required this.suggestions,
    this.trend,
    this.warning,
  });
}
