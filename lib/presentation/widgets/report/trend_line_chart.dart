import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/report_models.dart';

/// 趋势折线图组件
class TrendLineChart extends StatelessWidget {
  final List<TrendPoint> trendData;
  final TrendPeriod period;
  final String? title;

  const TrendLineChart({
    super.key,
    required this.trendData,
    required this.period,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) {
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
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _calculateBottomInterval(),
                      getTitlesWidget: _bottomTitleWidgets,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: _calculateInterval(),
                      getTitlesWidget: _leftTitleWidgets,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (trendData.length - 1).toDouble(),
                minY: 0,
                maxY: _calculateMaxY(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 && index < trendData.length) {
                          final point = trendData[index];
                          return LineTooltipItem(
                            '¥${point.amount.toStringAsFixed(2)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: trendData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.amount,
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppColors.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMaxY() {
    if (trendData.isEmpty) return 100;
    final maxValue = trendData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    return maxValue * 1.2;
  }

  double _calculateInterval() {
    final maxY = _calculateMaxY();
    if (maxY <= 0) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    return maxY / 5;
  }

  double _calculateBottomInterval() {
    switch (period) {
      case TrendPeriod.week:
        return 1;
      case TrendPeriod.month:
        return 7;
      case TrendPeriod.year:
        return 1;
    }
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= trendData.length) {
      return const SizedBox.shrink();
    }

    final point = trendData[index];
    String text;

    switch (period) {
      case TrendPeriod.week:
        final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
        text = weekdays[point.date.weekday - 1];
        break;
      case TrendPeriod.month:
        text = '${point.date.day}日';
        break;
      case TrendPeriod.year:
        final months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
        text = months[point.date.month - 1];
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    if (value == 0) return const SizedBox.shrink();

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        value.toInt().toString(),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      ),
    );
  }
}

/// 年度趋势柱状图
class YearlyTrendChart extends StatelessWidget {
  final List<MonthData> months;
  final double? budget;

  const YearlyTrendChart({
    super.key,
    required this.months,
    this.budget,
  });

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          '暂无数据',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final maxValue = months.map((m) => m.amount).reduce((a, b) => a > b ? a : b);
    final maxY = budget != null && budget! > maxValue ? budget! * 1.1 : maxValue * 1.2;

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
            '月度趋势',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '¥${rod.toY.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final months = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
                        if (value.toInt() >= 0 && value.toInt() < months.length) {
                          return Text(
                            '${months[value.toInt()]}月',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                ),
                borderData: FlBorderData(show: false),
                barGroups: months.asMap().entries.map((entry) {
                  final color = budget != null && entry.value.amount > budget!
                      ? Colors.red.shade400
                      : AppColors.primary;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.amount,
                        color: color,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
                extraLinesData: budget != null
                    ? ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: budget!,
                            color: Colors.orange,
                            strokeWidth: 2,
                            dashArray: [5, 5],
                            label: HorizontalLineLabel(
                              show: true,
                              labelResolver: (line) => '预算',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
