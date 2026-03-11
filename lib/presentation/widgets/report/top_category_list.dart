import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/report_models.dart';
import '../category_icon.dart';

/// Top 分类列表组件
class TopCategoryList extends StatelessWidget {
  final List<CategoryData> categories;
  final double total;
  final bool showAmount;

  const TopCategoryList({
    super.key,
    required this.categories,
    required this.total,
    this.showAmount = true,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            '暂无数据',
            style: TextStyle(color: Colors.grey),
          ),
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
            '消费分类',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...categories.map((data) => _buildCategoryItem(data)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategoryData data) {
    final color = AppColors.categoryColors[data.category.value] ?? AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CategoryIconHelper.getIcon(data.category),
              color: color,
              size: 20,
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
                      data.category.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (showAmount)
                      Text(
                        '¥${data.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: data.percentage / 100,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 45,
            child: Text(
              '${data.percentage.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 简洁版 Top 分类列表
class TopCategoryListCompact extends StatelessWidget {
  final List<CategoryData> categories;

  const TopCategoryListCompact({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: categories.take(3).map((data) {
        final color = AppColors.categoryColors[data.category.value] ?? AppColors.textSecondary;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  CategoryIconHelper.getIcon(data.category),
                  color: color,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.category.label,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Text(
                '¥${data.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
