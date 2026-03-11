import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/report_models.dart';
import '../category_icon.dart';

/// 分类饼图组件
class CategoryPieChart extends StatefulWidget {
  final Map<String, double> categoryTotals;
  final double total;

  const CategoryPieChart({
    super.key,
    required this.categoryTotals,
    required this.total,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categoryTotals.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          '暂无数据',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildSections(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildLegend(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final entries = widget.categoryTotals.entries.toList();
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == touchedIndex;
      final category = ExpenseCategory.fromValue(data.key);
      final color = AppColors.categoryColors[data.key] ?? AppColors.textSecondary;
      final percentage = widget.total > 0 ? (data.value / widget.total * 100) : 0;

      return PieChartSectionData(
        value: data.value,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        color: color,
        radius: isTouched ? 65 : 55,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegend() {
    final sortedEntries = widget.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(5).map((entry) {
      final category = ExpenseCategory.fromValue(entry.key);
      final color = AppColors.categoryColors[entry.key] ?? AppColors.textSecondary;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                category.label,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

/// 简洁的分类饼图（用于小尺寸展示）
class CategoryPieChartSmall extends StatelessWidget {
  final List<CategoryData> categories;

  const CategoryPieChartSmall({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = categories.fold(0.0, (sum, c) => sum + c.amount);

    return SizedBox(
      height: 120,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 1,
                centerSpaceRadius: 25,
                sections: categories.map((c) {
                  final color = AppColors.categoryColors[c.category.value] ?? AppColors.textSecondary;
                  return PieChartSectionData(
                    value: c.amount,
                    title: '',
                    color: color,
                    radius: 30,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categories.take(4).map((c) {
                final color = AppColors.categoryColors[c.category.value] ?? AppColors.textSecondary;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          c.category.label,
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${c.percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
