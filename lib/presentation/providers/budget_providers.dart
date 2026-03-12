import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_model.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/repositories/budget_repository.dart';
import 'expense_providers.dart';

// Repository Provider - 依赖注入BudgetRepository
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl();
});

// Current Month Budget Provider - 获取当月预算
final currentMonthBudgetProvider = FutureProvider<Budget?>((ref) async {
  final repository = ref.watch(budgetRepositoryProvider);
  final now = DateTime.now();
  return await repository.getBudgetByMonth(now.year, now.month);
});

// Budget for specific month
final budgetByMonthProvider = FutureProvider.family<Budget?, (int year, int month)>((ref, params) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return await repository.getBudgetByMonth(params.$1, params.$2);
});

// Month Total Provider - 月度支出总额（已存在则复用expense_providers中的）
// 使用expense_providers中的monthTotalProvider，避免重复定义

// Budget Progress Provider - 计算预算使用进度(0.0-1.0)
final budgetProgressProvider = FutureProvider<double>((ref) async {
  final budgetAsync = ref.watch(currentMonthBudgetProvider);
  final monthTotalAsync = ref.watch(monthTotalProvider);

  final budget = budgetAsync.valueOrNull;
  final monthTotal = monthTotalAsync.valueOrNull ?? 0.0;

  if (budget == null || budget.amount <= 0) {
    return 0.0;
  }

  return (monthTotal / budget.amount).clamp(0.0, 1.5);
});

// Budget Status Provider - 预算状态
enum BudgetStatus {
  healthy,    // 0-70%
  warning,    // 70-90%
  exceeded,   // >90%
}

final budgetStatusProvider = Provider<BudgetStatus>((ref) {
  final progressAsync = ref.watch(budgetProgressProvider);
  final progress = progressAsync.valueOrNull ?? 0.0;

  if (progress >= 0.9) {
    return BudgetStatus.exceeded;
  } else if (progress >= 0.7) {
    return BudgetStatus.warning;
  } else {
    return BudgetStatus.healthy;
  }
});

// Budget Notifier for CRUD operations
class BudgetNotifier extends StateNotifier<AsyncValue<Budget?>> {
  final BudgetRepository _repository;
  final Ref _ref;

  BudgetNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadCurrentMonthBudget();
  }

  Future<void> loadCurrentMonthBudget() async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final budget = await _repository.getBudgetByMonth(now.year, now.month);
      state = AsyncValue.data(budget);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setBudget(double amount, int year, int month) async {
    try {
      // Check if budget exists for this month
      final existing = await _repository.getBudgetByMonth(year, month);

      if (existing != null) {
        // Update existing budget
        final updated = existing.copyWith(
          amount: amount,
          updatedAt: DateTime.now(),
        );
        await _repository.updateBudget(updated);
      } else {
        // Create new budget
        final budget = Budget(
          amount: amount,
          year: year,
          month: month,
        );
        await _repository.addBudget(budget);
      }

      // Reload current month budget
      await loadCurrentMonthBudget();
      _invalidateProviders();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      final updated = budget.copyWith(updatedAt: DateTime.now());
      await _repository.updateBudget(updated);
      await loadCurrentMonthBudget();
      _invalidateProviders();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _repository.deleteBudget(id);
      await loadCurrentMonthBudget();
      _invalidateProviders();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _invalidateProviders() {
    _ref.invalidate(currentMonthBudgetProvider);
    _ref.invalidate(budgetProgressProvider);
    // budgetStatusProvider is now a synchronous Provider, no need to invalidate
  }
}

final budgetNotifierProvider = StateNotifierProvider<BudgetNotifier, AsyncValue<Budget?>>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return BudgetNotifier(repository, ref);
});

// Re-export monthTotalProvider from expense_providers
// This is imported in the file that uses budget_providers
