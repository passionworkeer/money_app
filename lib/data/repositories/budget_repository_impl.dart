import '../../domain/repositories/budget_repository.dart';
import '../datasources/local/database_helper.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final DatabaseHelper _databaseHelper;

  BudgetRepositoryImpl({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<void> addBudget(Budget budget) async {
    await _databaseHelper.insertBudget(budget);
  }

  @override
  Future<Budget?> getBudgetByMonth(int year, int month) async {
    return await _databaseHelper.getBudgetByMonth(year, month);
  }

  @override
  Future<List<Budget>> getAllBudgets() async {
    return await _databaseHelper.getAllBudgets();
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    await _databaseHelper.updateBudget(budget);
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _databaseHelper.deleteBudget(id);
  }
}
