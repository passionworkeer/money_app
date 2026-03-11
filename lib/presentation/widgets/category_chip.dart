import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/categories.dart';

class CategoryChip extends StatelessWidget {
  final ExpenseCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[category.value] ?? AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 18,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.medical:
        return Icons.medical_services;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }
}

class CategorySelector extends StatelessWidget {
  final String? selectedCategory;
  final Function(String) onCategorySelected;
  final bool showAllOption;

  const CategorySelector({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
    this.showAllOption = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (showAllOption)
          GestureDetector(
            onTap: () => onCategorySelected(''),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selectedCategory == '' ? AppColors.primary : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '全部',
                style: TextStyle(
                  color: selectedCategory == '' ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ...ExpenseCategory.values.map((category) => CategoryChip(
              category: category,
              isSelected: selectedCategory == category.value,
              onTap: () => onCategorySelected(category.value),
            )),
      ],
    );
  }
}
