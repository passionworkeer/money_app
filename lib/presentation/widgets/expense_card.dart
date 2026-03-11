import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/categories.dart';
import '../../data/models/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final category = ExpenseCategory.fromValue(expense.category);
    final categoryColor = AppColors.categoryColors[expense.category] ?? AppColors.textSecondary;

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Category Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: categoryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Description and Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.description.isEmpty ? category.label : expense.description,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: categoryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('HH:mm').format(expense.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Amount
                  Text(
                    '-¥${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_rounded;
      case ExpenseCategory.medical:
        return Icons.medical_services_rounded;
      case ExpenseCategory.education:
        return Icons.school_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }
}
