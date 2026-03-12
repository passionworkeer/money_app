import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/data/models/automation_rule.dart';

void main() {
  group('AutomationRule Model Tests', () {
    test('AutomationRule can be created with required fields', () {
      final rule = AutomationRule(
        name: '测试规则',
        triggerType: TriggerType.scheduled,
        actionType: ActionType.notification,
        config: const AutomationConfig(
          scheduleHour: 20,
          scheduleMinute: 0,
          scheduleType: 'daily',
        ),
      );

      expect(rule.name, '测试规则');
      expect(rule.triggerType, TriggerType.scheduled);
      expect(rule.actionType, ActionType.notification);
      expect(rule.isEnabled, true);
      expect(rule.id, isNotEmpty);
      expect(rule.createdAt, isNotNull);
    });

    test('AutomationRule can be created with all fields', () {
      final now = DateTime.now();
      final rule = AutomationRule(
        id: 'test-id',
        name: '完整规则',
        triggerType: TriggerType.amountThreshold,
        actionType: ActionType.notification,
        config: const AutomationConfig(
          thresholdAmount: 500,
          isPercentage: false,
        ),
        isEnabled: false,
        lastTriggered: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(rule.id, 'test-id');
      expect(rule.name, '完整规则');
      expect(rule.triggerType, TriggerType.amountThreshold);
      expect(rule.actionType, ActionType.notification);
      expect(rule.isEnabled, false);
      expect(rule.lastTriggered, now);
      expect(rule.createdAt, now);
      expect(rule.updatedAt, now);
    });

    test('AutomationRule copyWith creates new instance with updated fields', () {
      final rule = AutomationRule(
        id: 'original-id',
        name: '原始规则',
        triggerType: TriggerType.scheduled,
        actionType: ActionType.notification,
        config: const AutomationConfig(scheduleHour: 20, scheduleMinute: 0),
      );

      final updated = rule.copyWith(name: '更新后的规则', isEnabled: false);

      expect(updated.id, 'original-id');
      expect(updated.name, '更新后的规则');
      expect(updated.isEnabled, false);
      expect(updated.triggerType, TriggerType.scheduled);
      // Original unchanged
      expect(rule.name, '原始规则');
      expect(rule.isEnabled, true);
    });

    test('AutomationRule copyWith preserves original when no params provided', () {
      final now = DateTime.now();
      final rule = AutomationRule(
        id: 'test-id',
        name: '测试规则',
        triggerType: TriggerType.category,
        actionType: ActionType.categorize,
        config: const AutomationConfig(
          targetCategory: 'food',
          keywords: ['早餐', '午餐'],
        ),
        createdAt: now,
        updatedAt: now,
      );

      final copy = rule.copyWith();

      expect(copy.id, rule.id);
      expect(copy.name, rule.name);
      expect(copy.triggerType, rule.triggerType);
      expect(copy.actionType, rule.actionType);
      expect(copy.config, rule.config);
      expect(copy.isEnabled, rule.isEnabled);
    });

    test('AutomationRule toMap and fromMap works correctly', () {
      final now = DateTime.now();
      final rule = AutomationRule(
        id: 'test-id',
        name: '映射测试',
        triggerType: TriggerType.amountThreshold,
        actionType: ActionType.notification,
        config: const AutomationConfig(
          thresholdAmount: 80,
          isPercentage: true,
          notificationTitle: '测试提醒',
          notificationBody: '测试内容',
        ),
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = rule.toMap();
      final restored = AutomationRule.fromMap(map);

      expect(restored.id, rule.id);
      expect(restored.name, rule.name);
      expect(restored.triggerType, rule.triggerType);
      expect(restored.actionType, rule.actionType);
      expect(restored.isEnabled, rule.isEnabled);
    });

    test('AutomationRule fromMap handles isEnabled conversion', () {
      final map = {
        'id': 'test-id',
        'name': '启用测试',
        'triggerType': 'scheduled',
        'actionType': 'notification',
        'config': '{"scheduleHour": 20, "scheduleMinute": 0}',
        'isEnabled': 1,
        'lastTriggered': null,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      final rule = AutomationRule.fromMap(map);

      expect(rule.isEnabled, true);
      expect(rule.isEnabled, isA<bool>());
    });

    test('AutomationRule fromMap handles isEnabled as 0', () {
      final map = {
        'id': 'test-id',
        'name': '禁用测试',
        'triggerType': 'amountThreshold',
        'actionType': 'notification',
        'config': '{}',
        'isEnabled': 0,
        'lastTriggered': null,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': null,
      };

      final rule = AutomationRule.fromMap(map);

      expect(rule.isEnabled, false);
    });

    test('AutomationRule equality based on id', () {
      final rule1 = AutomationRule(
        id: 'same-id',
        name: '规则1',
        triggerType: TriggerType.scheduled,
        actionType: ActionType.notification,
        config: const AutomationConfig(),
      );

      final rule2 = AutomationRule(
        id: 'same-id',
        name: '规则2',
        triggerType: TriggerType.amountThreshold,
        actionType: ActionType.categorize,
        config: const AutomationConfig(),
      );

      expect(rule1, equals(rule2)); // Same ID
    });

    test('AutomationRule inequality with different ids', () {
      final rule1 = AutomationRule(
        id: 'id-1',
        name: '规则1',
        triggerType: TriggerType.scheduled,
        actionType: ActionType.notification,
        config: const AutomationConfig(),
      );

      final rule2 = AutomationRule(
        id: 'id-2',
        name: '规则1',
        triggerType: TriggerType.scheduled,
        actionType: ActionType.notification,
        config: const AutomationConfig(),
      );

      expect(rule1, isNot(equals(rule2)));
    });

    test('AutomationRule hashCode based on id', () {
      final rule1 = AutomationRule(
        id: 'test-id',
        name: '规则1',
        triggerType: TriggerType.scheduled,
        actionType: ActionType.notification,
        config: const AutomationConfig(),
      );

      final rule2 = AutomationRule(
        id: 'test-id',
        name: '规则2',
        triggerType: TriggerType.amountThreshold,
        actionType: ActionType.categorize,
        config: const AutomationConfig(),
      );

      expect(rule1.hashCode, equals(rule2.hashCode));
    });
  });

  group('TriggerType Tests', () {
    test('TriggerType values are correct', () {
      expect(TriggerType.values.length, 3);
      expect(TriggerType.scheduled.label, '定时触发');
      expect(TriggerType.scheduled.value, 'scheduled');
      expect(TriggerType.amountThreshold.label, '金额阈值');
      expect(TriggerType.amountThreshold.value, 'amountThreshold');
      expect(TriggerType.category.label, '分类触发');
      expect(TriggerType.category.value, 'category');
    });

    test('TriggerType fromValue returns correct type', () {
      expect(TriggerType.fromValue('scheduled'), TriggerType.scheduled);
      expect(TriggerType.fromValue('amountThreshold'), TriggerType.amountThreshold);
      expect(TriggerType.fromValue('category'), TriggerType.category);
    });

    test('TriggerType fromValue returns default for unknown value', () {
      expect(TriggerType.fromValue('unknown'), TriggerType.scheduled);
      expect(TriggerType.fromValue(''), TriggerType.scheduled);
    });
  });

  group('ActionType Tests', () {
    test('ActionType values are correct', () {
      expect(ActionType.values.length, 3);
      expect(ActionType.notification.label, '通知提醒');
      expect(ActionType.notification.value, 'notification');
      expect(ActionType.categorize.label, '自动分类');
      expect(ActionType.categorize.value, 'categorize');
      expect(ActionType.autoRecord.label, '自动记账');
      expect(ActionType.autoRecord.value, 'autoRecord');
    });

    test('ActionType fromValue returns correct type', () {
      expect(ActionType.fromValue('notification'), ActionType.notification);
      expect(ActionType.fromValue('categorize'), ActionType.categorize);
      expect(ActionType.fromValue('autoRecord'), ActionType.autoRecord);
    });

    test('ActionType fromValue returns default for unknown value', () {
      expect(ActionType.fromValue('unknown'), ActionType.notification);
      expect(ActionType.fromValue(''), ActionType.notification);
    });
  });

  group('AutomationConfig Tests', () {
    test('AutomationConfig can be created with required fields', () {
      const config = AutomationConfig(
        scheduleHour: 20,
        scheduleMinute: 0,
        scheduleType: 'daily',
      );

      expect(config.scheduleHour, 20);
      expect(config.scheduleMinute, 0);
      expect(config.scheduleType, 'daily');
    });

    test('AutomationConfig toJson and fromJson works correctly', () {
      const config = AutomationConfig(
        scheduleHour: 10,
        scheduleMinute: 30,
        scheduleType: 'weekly',
        weekDay: 1,
        thresholdAmount: 500,
        isPercentage: false,
        targetCategory: 'food',
        keywords: ['早餐', '午餐'],
        notificationTitle: '测试',
        notificationBody: '测试内容',
      );

      final json = config.toJson();
      final restored = AutomationConfig.fromJson(json);

      expect(restored.scheduleHour, config.scheduleHour);
      expect(restored.scheduleMinute, config.scheduleMinute);
      expect(restored.scheduleType, config.scheduleType);
      expect(restored.weekDay, config.weekDay);
      expect(restored.thresholdAmount, config.thresholdAmount);
      expect(restored.isPercentage, config.isPercentage);
      expect(restored.targetCategory, config.targetCategory);
      expect(restored.keywords, config.keywords);
      expect(restored.notificationTitle, config.notificationTitle);
      expect(restored.notificationBody, config.notificationBody);
    });

    test('AutomationConfig fromJson handles invalid scheduleHour', () {
      const json = {
        'scheduleHour': 25, // Invalid
        'scheduleMinute': 0,
      };

      final config = AutomationConfig.fromJson(json);

      expect(config.scheduleHour, isNull);
    });

    test('AutomationConfig fromJson handles invalid scheduleMinute', () {
      const json = {
        'scheduleHour': 10,
        'scheduleMinute': 60, // Invalid
      };

      final config = AutomationConfig.fromJson(json);

      expect(config.scheduleMinute, isNull);
    });

    test('AutomationConfig fromJson handles invalid thresholdAmount', () {
      const json = {
        'thresholdAmount': -100, // Invalid - negative
      };

      final config = AutomationConfig.fromJson(json);

      expect(config.thresholdAmount, isNull);
    });

    test('AutomationConfig fromJson handles invalid weekDay', () {
      const json = {
        'weekDay': 8, // Invalid
      };

      final config = AutomationConfig.fromJson(json);

      expect(config.weekDay, isNull);
    });

    test('AutomationConfig fromJson handles valid weekDay boundaries', () {
      const jsonMin = {'weekDay': 1};
      const jsonMax = {'weekDay': 7};

      expect(AutomationConfig.fromJson(jsonMin).weekDay, 1);
      expect(AutomationConfig.fromJson(jsonMax).weekDay, 7);
    });

    test('AutomationConfig fromJson handles keywords', () {
      const json = {
        'keywords': ['早餐', '午餐', '晚餐'],
      };

      final config = AutomationConfig.fromJson(json);

      expect(config.keywords, ['早餐', '午餐', '晚餐']);
    });

    test('AutomationConfig fromJson handles null keywords', () {
      final json = <String, dynamic>{};

      final config = AutomationConfig.fromJson(json);

      expect(config.keywords, isNull);
    });

    test('AutomationConfig fromJson handles num thresholdAmount', () {
      const json = {
        'thresholdAmount': 100, // int instead of double
      };

      final config = AutomationConfig.fromJson(json);

      expect(config.thresholdAmount, 100.0);
      expect(config.thresholdAmount, isA<double>());
    });

    test('AutomationConfig copyWith works correctly', () {
      const original = AutomationConfig(
        scheduleHour: 20,
        scheduleMinute: 0,
      );

      final updated = original.copyWith(
        scheduleHour: 10,
        scheduleType: 'weekly',
      );

      expect(updated.scheduleHour, 10);
      expect(updated.scheduleMinute, 0); // Preserved
      expect(updated.scheduleType, 'weekly');
    });
  });

  group('PresetAutomationRules Tests', () {
    test('PresetAutomationRules.budgetWarning creates correct rule', () {
      final rule = PresetAutomationRules.budgetWarning();

      expect(rule.name, '预算超支提醒');
      expect(rule.triggerType, TriggerType.amountThreshold);
      expect(rule.actionType, ActionType.notification);
      expect(rule.config.thresholdAmount, 90);
      expect(rule.config.isPercentage, true);
    });

    test('PresetAutomationRules.largeAmountWarning creates correct rule', () {
      final rule = PresetAutomationRules.largeAmountWarning();

      expect(rule.name, '大额消费提醒');
      expect(rule.triggerType, TriggerType.amountThreshold);
      expect(rule.actionType, ActionType.notification);
      expect(rule.config.thresholdAmount, 500);
      expect(rule.config.isPercentage, false);
    });

    test('PresetAutomationRules.dailyReminder creates correct rule', () {
      final rule = PresetAutomationRules.dailyReminder();

      expect(rule.name, '每日记账提醒');
      expect(rule.triggerType, TriggerType.scheduled);
      expect(rule.actionType, ActionType.notification);
      expect(rule.config.scheduleHour, 20);
      expect(rule.config.scheduleMinute, 0);
      expect(rule.config.scheduleType, 'daily');
    });

    test('PresetAutomationRules.weeklyReminder creates correct rule', () {
      final rule = PresetAutomationRules.weeklyReminder();

      expect(rule.name, '每周记账提醒');
      expect(rule.triggerType, TriggerType.scheduled);
      expect(rule.actionType, ActionType.notification);
      expect(rule.config.scheduleType, 'weekly');
      expect(rule.config.weekDay, 1);
    });

    test('PresetAutomationRules.foodAutoCategorize creates correct rule', () {
      final rule = PresetAutomationRules.foodAutoCategorize();

      expect(rule.name, '餐饮自动分类');
      expect(rule.triggerType, TriggerType.category);
      expect(rule.actionType, ActionType.categorize);
      expect(rule.config.targetCategory, 'food');
      expect(rule.config.keywords, isNotEmpty);
    });

    test('PresetAutomationRules.allPresets returns all presets', () {
      final presets = PresetAutomationRules.allPresets;

      expect(presets.length, 8);
      expect(presets.contains(PresetAutomationRules.budgetWarning()), isTrue);
      expect(presets.contains(PresetAutomationRules.largeAmountWarning()), isTrue);
      expect(presets.contains(PresetAutomationRules.dailyReminder()), isTrue);
      expect(presets.contains(PresetAutomationRules.weeklyReminder()), isTrue);
    });
  });
}
