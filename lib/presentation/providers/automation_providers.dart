import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/automation_service.dart';
import '../../data/models/automation_rule.dart';

/// 自动化服务提供者
final automationServiceProvider = Provider<AutomationService>((ref) {
  return AutomationService();
});

/// 所有自动化规则
final automationRulesProvider =
    StateNotifierProvider<AutomationRulesNotifier, AsyncValue<List<AutomationRule>>>((ref) {
  final service = ref.watch(automationServiceProvider);
  return AutomationRulesNotifier(service);
});

/// 自动化规则状态管理
class AutomationRulesNotifier extends StateNotifier<AsyncValue<List<AutomationRule>>> {
  final AutomationService _service;

  AutomationRulesNotifier(this._service) : super(const AsyncValue.loading()) {
    loadRules();
  }

  Future<void> loadRules() async {
    state = const AsyncValue.loading();
    try {
      await _service.init();
      final rules = await _service.getAllRules();
      state = AsyncValue.data(rules);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRule(AutomationRule rule) async {
    try {
      await _service.createRule(rule);
      await loadRules();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateRule(AutomationRule rule) async {
    try {
      await _service.updateRule(rule);
      await loadRules();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRule(String id) async {
    try {
      await _service.deleteRule(id);
      await loadRules();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleRule(String id, bool isEnabled) async {
    try {
      await _service.toggleRule(id, isEnabled);
      // 更新本地状态
      state.whenData((rules) {
        final updatedRules = rules.map((rule) {
          if (rule.id == id) {
            return rule.copyWith(isEnabled: isEnabled);
          }
          return rule;
        }).toList();
        state = AsyncValue.data(updatedRules);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> suggestCategory(String description) async {
    return await _service.suggestCategory(description);
  }

  Future<void> checkAmountThresholds(double amount) async {
    await _service.checkAmountThresholds(amount);
  }
}

/// 分类建议提供者
final categorySuggestionProvider = FutureProvider.family<String?, String>((ref, description) async {
  final notifier = ref.watch(automationRulesProvider.notifier);
  return await notifier.suggestCategory(description);
});

/// 规则执行历史提供者（预留）
final ruleExecutionHistoryProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [];
});
