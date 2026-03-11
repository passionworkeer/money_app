import '../../data/models/budget_model.dart';

abstract class BudgetRepository {
  Future<void> addBudget(Budget budget);
  Future<Budget?> getBudgetByMonth(int year, int month);
  Future<List<Budget>> getAllBudgets();
  Future<void> updateBudget(Budget budget);
  Future<void> deleteBudget(String id);
}
