import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/repositories/expense_repository.dart';

// Repository Provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl();
});

// All Expenses Provider
final allExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getAllExpenses();
});

// Today's Expenses Provider
final todayExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  return await repository.getExpensesByDateRange(
    DateTimeUtils.startOfDay(now),
    DateTimeUtils.endOfDay(now),
  );
});

// Month Expenses Provider
final monthExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  return await repository.getExpensesByDateRange(
    DateTimeUtils.startOfMonth(now),
    DateTimeUtils.endOfMonth(now),
  );
});

// Today's Total Provider
final todayTotalProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  return await repository.getTotalByDateRange(
    DateTimeUtils.startOfDay(now),
    DateTimeUtils.endOfDay(now),
  );
});

// Month Total Provider
final monthTotalProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  return await repository.getTotalByDateRange(
    DateTimeUtils.startOfMonth(now),
    DateTimeUtils.endOfMonth(now),
  );
});

// Category Totals Provider
final categoryTotalsProvider = FutureProvider<Map<String, double>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  return await repository.getCategoryTotals(
    DateTimeUtils.startOfMonth(now),
    DateTimeUtils.endOfMonth(now),
  );
});

// Expenses Notifier for CRUD operations
class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final ExpenseRepository _repository;
  final Ref _ref;

  ExpensesNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _repository.getAllExpenses();
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _repository.addExpense(expense);
      await loadExpenses();
      _invalidateProviders();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _repository.updateExpense(expense);
      await loadExpenses();
      _invalidateProviders();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _repository.deleteExpense(id);
      await loadExpenses();
      _invalidateProviders();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _invalidateProviders() {
    _ref.invalidate(todayExpensesProvider);
    _ref.invalidate(monthExpensesProvider);
    _ref.invalidate(todayTotalProvider);
    _ref.invalidate(monthTotalProvider);
    _ref.invalidate(categoryTotalsProvider);
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return ExpensesNotifier(repository, ref);
});
