import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_expense_tracker/presentation/pages/automation/automation_page.dart';
import 'package:ai_expense_tracker/presentation/providers/automation_providers.dart';
import 'package:ai_expense_tracker/data/models/automation_rule.dart';
import 'package:ai_expense_tracker/data/models/expense_model.dart';
import 'package:ai_expense_tracker/core/services/automation_service.dart';

void main() {
  group('AutomationPage Widget Tests', () {
    late List<AutomationRule> testRules;

    setUp(() {
      testRules = [
        AutomationRule(
          id: 'rule-1',
          name: '预算超支提醒',
          triggerType: TriggerType.amountThreshold,
          actionType: ActionType.notification,
          config: const AutomationConfig(
            thresholdAmount: 90,
            isPercentage: true,
            notificationTitle: '预算提醒',
            notificationBody: '本月支出已达到预算的90%',
          ),
          isEnabled: true,
        ),
        AutomationRule(
          id: 'rule-2',
          name: '每日记账提醒',
          triggerType: TriggerType.scheduled,
          actionType: ActionType.notification,
          config: const AutomationConfig(
            scheduleHour: 20,
            scheduleMinute: 0,
            scheduleType: 'daily',
          ),
          isEnabled: true,
        ),
        AutomationRule(
          id: 'rule-3',
          name: '餐饮自动分类',
          triggerType: TriggerType.category,
          actionType: ActionType.categorize,
          config: const AutomationConfig(
            targetCategory: 'food',
            keywords: ['早餐', '午餐', '晚餐'],
          ),
          isEnabled: false,
        ),
      ];
    });

    Widget createTestWidget({
      List<AutomationRule>? rules,
      bool hasError = false,
    }) {
      return ProviderScope(
        overrides: [
          automationServiceProvider.overrideWithValue(_MockAutomationService(
            rules: rules ?? testRules,
            hasError: hasError,
          )),
        ],
        child: const MaterialApp(
          home: AutomationPage(),
        ),
      );
    }

    testWidgets('AutomationPage loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify the page loads
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('AutomationPage displays header with title "自动化"', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify the AppBar has the correct title
      expect(find.text('自动化'), findsOneWidget);
    });

    testWidgets('AutomationPage shows create rule button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify add button exists in AppBar
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('AutomationPage displays list of automation rules', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify rules are displayed
      expect(find.text('预算超支提醒'), findsOneWidget);
      expect(find.text('每日记账提醒'), findsOneWidget);
      expect(find.text('餐饮自动分类'), findsOneWidget);
    });

    testWidgets('AutomationPage handles empty state when no rules', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(rules: []));
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text('暂无自动化规则'), findsOneWidget);
      expect(find.text('添加实现规则自动提醒和分类'), findsOneWidget);
    });

    testWidgets('AutomationPage shows add rule button in empty state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(rules: []));
      await tester.pumpAndSettle();

      // Verify add button in empty state
      expect(find.text('添加规则'), findsOneWidget);
    });

    testWidgets('AutomationPage can toggle rule enabled/disabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find all Switch widgets
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(3)); // 3 rules = 3 switches

      // Verify first rule is enabled
      final firstSwitch = tester.widget<Switch>(switches.first);
      expect(firstSwitch.value, true);

      // Toggle the first switch
      await tester.tap(switches.first);
      await tester.pumpAndSettle();
    });

    testWidgets('AutomationPage displays section headers when rules exist', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify section headers are displayed
      expect(find.text('提醒规则'), findsOneWidget);
      expect(find.text('自动分类规则'), findsOneWidget);
    });

    testWidgets('AutomationPage shows loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Before pumpAndSettle, loading indicator should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('AutomationPage handles error state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(hasError: true));
      await tester.pumpAndSettle();

      // Verify error state is displayed
      expect(find.textContaining('加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('AutomationPage has preset chips in empty state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(rules: []));
      await tester.pumpAndSettle();

      // Verify preset chips are displayed
      expect(find.text('预算提醒'), findsOneWidget);
      expect(find.text('大额提醒'), findsOneWidget);
      expect(find.text('每日提醒'), findsOneWidget);
      expect(find.text('自动分类'), findsOneWidget);
    });

    testWidgets('AutomationPage displays rule descriptions', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify descriptions are displayed
      expect(find.textContaining('支出超过'), findsOneWidget);
      expect(find.textContaining('每天'), findsOneWidget);
      expect(find.textContaining('关键词匹配'), findsOneWidget);
    });

    testWidgets('AutomationPage has edit and delete buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify edit and delete buttons exist
      expect(find.text('编辑'), findsNWidgets(3)); // 3 rules
      expect(find.text('删除'), findsNWidgets(3)); // 3 rules
    });

    testWidgets('AutomationPage can open add rule dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(rules: []));
      await tester.pumpAndSettle();

      // Tap the add rule button
      await tester.tap(find.text('添加规则'));
      await tester.pumpAndSettle();

      // Verify dialog is opened
      expect(find.text('添加规则'), findsNWidgets(2)); // Button + dialog title
    });
  });
}

/// Mock AutomationService for testing
class _MockAutomationService extends AutomationService {
  final List<AutomationRule> rules;
  final bool hasError;

  _MockAutomationService({
    required this.rules,
    this.hasError = false,
  });

  @override
  Future<void> init() async {
    if (hasError) {
      throw Exception('Mock error');
    }
  }

  @override
  Future<List<AutomationRule>> getAllRules() async {
    if (hasError) {
      throw Exception('Mock error');
    }
    return rules;
  }

  @override
  Future<void> toggleRule(String id, bool isEnabled) async {
    // Mock toggle - do nothing
  }

  @override
  Future<void> createRule(AutomationRule rule) async {
    // Mock create - do nothing
  }

  @override
  Future<void> updateRule(AutomationRule rule) async {
    // Mock update - do nothing
  }

  @override
  Future<void> deleteRule(String id) async {
    // Mock delete - do nothing
  }

  @override
  Future<String?> suggestCategory(String description) async {
    // Mock suggest category
    return null;
  }

  @override
  Future<void> checkAmountThresholds(double amount, {Expense? expense}) async {
    // Mock check thresholds - do nothing
  }
}
