import '../../domain/repositories/expense_repository.dart';
import '../datasources/local/database_helper.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final DatabaseHelper _databaseHelper;

  ExpenseRepositoryImpl({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<List<Expense>> getAllExpenses() async {
    return await _databaseHelper.getAllExpenses();
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _databaseHelper.getExpensesByDateRange(start, end);
  }

  @override
  Future<List<Expense>> getExpensesByCategory(String category) async {
    return await _databaseHelper.getExpensesByCategory(category);
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    return await _databaseHelper.getExpenseById(id);
  }

  @override
  Future<void> addExpense(Expense expense) async {
    await _databaseHelper.insertExpense(expense);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await _databaseHelper.updateExpense(expense);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _databaseHelper.deleteExpense(id);
  }

  @override
  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    return await _databaseHelper.getTotalByDateRange(start, end);
  }

  @override
  Future<Map<String, double>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async {
    return await _databaseHelper.getCategoryTotals(start, end);
  }
}
