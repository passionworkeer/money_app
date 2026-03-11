import 'package:flutter/material.dart';
import '../../core/constants/categories.dart';

class CategoryIconHelper {
  static IconData getIcon(ExpenseCategory category) {
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
