import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/models/automation_rule.dart';
import '../../data/models/expense_model.dart';

const _uuid = Uuid();

/// 自动化服务
class AutomationService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 初始化通知服务
  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 注意：权限请求由用户主动触发，不再自动请求
    // 用户可以在设置页面手动开启通知权限

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    // Android 13+ 需要请求 POST_NOTIFICATIONS 权限
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  /// 公开方法：请求通知权限（由用户主动触发）
  Future<bool> requestNotificationPermission() async {
    try {
      await init();
      await _requestPermissions();
      developer.log(
        'Notification permission requested by user',
        name: 'AutomationService',
      );
      return true;
    } catch (e) {
      developer.log(
        'Failed to request notification permission: $e',
        name: 'AutomationService',
        level: 900, // severe level
      );
      return false;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // 处理通知点击事件
    // 可以导航到特定页面
  }

  /// 执行所有定时规则
  Future<void> executeScheduledRules() async {
    await init();
    final rules = await _db.getEnabledAutomationRules();
    final now = DateTime.now();

    for (final rule in rules) {
      if (rule.triggerType == TriggerType.scheduled) {
        final config = rule.config;
        final scheduleHour = config.scheduleHour;
        final scheduleMinute = config.scheduleMinute;
        final scheduleType = config.scheduleType;
        final weekDay = config.weekDay;

        if (scheduleHour == null || scheduleMinute == null) continue;

        // 检查是否应该触发
        bool shouldTrigger = false;

        if (scheduleType == 'daily') {
          // 每日提醒
          shouldTrigger = now.hour == scheduleHour &&
              now.minute == scheduleMinute &&
              now.second < 10;
        } else if (scheduleType == 'weekly' && weekDay != null) {
          // 每周提醒
          // Dart 中 weekday: 1 = Monday, 7 = Sunday
          shouldTrigger = now.weekday == weekDay &&
              now.hour == scheduleHour &&
              now.minute == scheduleMinute &&
              now.second < 10;
        }

        if (shouldTrigger) {
          await _executeRule(rule);
        }
      }
    }
  }

  /// 检查金额阈值规则
  Future<void> checkAmountThresholds(double amount, {Expense? expense}) async {
    await init();
    final rules = await _db.getEnabledAutomationRules();

    for (final rule in rules) {
      if (rule.triggerType == TriggerType.amountThreshold) {
        final config = rule.config;
        final threshold = config.thresholdAmount;
        final isPercentage = config.isPercentage ?? false;

        if (threshold == null) continue;

        bool shouldTrigger = false;

        if (isPercentage) {
          // 百分比形式：需要获取预算并计算
          final budget = await _db.getBudgetByMonth(
            DateTime.now().year,
            DateTime.now().month,
          );
          if (budget != null && budget.amount > 0) {
            final monthTotal = await _db.getTotalByDateRange(
              DateTime(DateTime.now().year, DateTime.now().month, 1),
              DateTime(DateTime.now().year, DateTime.now().month + 1, 0,
                  23, 59, 59),
            );
            final percentage = (monthTotal / budget.amount) * 100;
            shouldTrigger = percentage >= threshold;
          }
        } else {
          // 固定金额
          shouldTrigger = amount >= threshold;
        }

        if (shouldTrigger) {
          await _executeRule(rule, expense: expense);
        }
      }
    }
  }

  /// 建议分类
  Future<String?> suggestCategory(String description) async {
    final rules = await _db.getEnabledAutomationRules();

    for (final rule in rules) {
      if (rule.triggerType == TriggerType.category &&
          rule.actionType == ActionType.categorize) {
        final config = rule.config;
        final keywords = config.keywords;
        final targetCategory = config.targetCategory;

        if (keywords == null || targetCategory == null) continue;

        // 检查描述中是否包含关键词
        for (final keyword in keywords) {
          if (description.contains(keyword)) {
            return targetCategory;
          }
        }
      }
    }

    return null;
  }

  /// 执行规则
  Future<void> _executeRule(AutomationRule rule, {Expense? expense}) async {
    final config = rule.config;

    switch (rule.actionType) {
      case ActionType.notification:
        await _sendNotification(
          config.notificationTitle ?? '提醒',
          config.notificationBody ?? '自动化规则已触发',
        );
        break;
      case ActionType.categorize:
        // 分类逻辑在 suggestCategory 中处理
        break;
      case ActionType.autoRecord:
        // 自动记账功能（预留）
        break;
    }

    // 更新最后触发时间
    final updatedRule = rule.copyWith(
      lastTriggered: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.updateAutomationRule(updatedRule);
  }

  /// 发送通知
  Future<void> sendReminder(String title, String message) async {
    await init();
    await _sendNotification(title, message);
  }

  Future<void> _sendNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'automation_channel',
      '自动化提醒',
      channelDescription: '自动化规则触发提醒',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 使用 UUID 生成唯一通知ID，避免同秒内多通知冲突
    final notificationId = _uuid.v4().hashCode.abs();

    await _notifications.show(
      notificationId,
      title,
      body,
      details,
    );
  }

  /// 创建规则
  Future<void> createRule(AutomationRule rule) async {
    try {
      await _db.insertAutomationRule(rule);
      developer.log(
        'Created automation rule: ${rule.name}',
        name: 'AutomationService',
      );
    } catch (e) {
      developer.log(
        'Failed to create automation rule: $e',
        name: 'AutomationService',
        level: 900, // severe level
      );
      rethrow;
    }
  }

  /// 更新规则
  Future<void> updateRule(AutomationRule rule) async {
    try {
      await _db.updateAutomationRule(rule);
      developer.log(
        'Updated automation rule: ${rule.name}',
        name: 'AutomationService',
      );
    } catch (e) {
      developer.log(
        'Failed to update automation rule: $e',
        name: 'AutomationService',
        level: 900, // severe level
      );
      rethrow;
    }
  }

  /// 删除规则
  Future<void> deleteRule(String id) async {
    try {
      await _db.deleteAutomationRule(id);
      developer.log(
        'Deleted automation rule: $id',
        name: 'AutomationService',
      );
    } catch (e) {
      developer.log(
        'Failed to delete automation rule: $e',
        name: 'AutomationService',
        level: 900, // severe level
      );
      rethrow;
    }
  }

  /// 切换规则状态
  Future<void> toggleRule(String id, bool isEnabled) async {
    try {
      await _db.toggleAutomationRule(id, isEnabled);
      developer.log(
        'Toggled automation rule: $id to $isEnabled',
        name: 'AutomationService',
      );
    } catch (e) {
      developer.log(
        'Failed to toggle automation rule: $e',
        name: 'AutomationService',
        level: 900, // severe level
      );
      rethrow;
    }
  }

  /// 获取所有规则
  Future<List<AutomationRule>> getAllRules() async {
    return await _db.getAllAutomationRules();
  }

  /// 获取启用的规则
  Future<List<AutomationRule>> getEnabledRules() async {
    return await _db.getEnabledAutomationRules();
  }

  /// 获取规则
  Future<AutomationRule?> getRule(String id) async {
    return await _db.getAutomationRuleById(id);
  }
}
