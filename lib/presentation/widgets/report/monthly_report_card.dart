import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/report_models.dart';

/// 月度报告卡片组件
class MonthlyReportCard extends StatelessWidget {
  final MonthlyReport report;
  final VoidCallback? onTap;

  const MonthlyReportCard({
    super.key,
    required this.report,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${report.year}年${report.month}月',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${report.expenseCount}笔',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '本月支出',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '¥',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  report.totalAmount.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 月度变化
            if (report.lastMonthTotal != null && report.lastMonthTotal! > 0) ...[
              _buildChangeIndicator(),
              const SizedBox(height: 12),
            ],
            // 预算进度
            if (report.budget != null) _buildBudgetProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeIndicator() {
    final change = report.monthOverMonthChange;
    final isUp = change > 0;
    final color = isUp ? Colors.red.shade300 : Colors.green.shade300;

    return Row(
      children: [
        Icon(
          isUp ? Icons.trending_up : Icons.trending_down,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          '${isUp ? '+' : ''}${change.toStringAsFixed(1)}% 较上月',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetProgress() {
    final percent = report.budgetUsagePercent.clamp(0, 100);
    final isOver = report.isOverBudget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isOver ? '已超出预算' : '预算使用',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                color: isOver ? Colors.red.shade200 : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(
              isOver ? Colors.red.shade300 : Colors.white.withOpacity(0.8),
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
