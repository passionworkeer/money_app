import 'dart:convert';
import 'dart:developer' as developer;

import 'package:uuid/uuid.dart';

/// 自动化规则触发类型
enum TriggerType {
  scheduled('定时触发', 'scheduled'),
  amountThreshold('金额阈值', 'amountThreshold'),
  category('分类触发', 'category');

  final String label;
  final String value;

  const TriggerType(this.label, this.value);

  static TriggerType fromValue(String value) {
    return TriggerType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TriggerType.scheduled,
    );
  }
}

/// 自动化规则动作类型
enum ActionType {
  notification('通知提醒', 'notification'),
  categorize('自动分类', 'categorize'),
  autoRecord('自动记账', 'autoRecord');

  final String label;
  final String value;

  const ActionType(this.label, this.value);

  static ActionType fromValue(String value) {
    return ActionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ActionType.notification,
    );
  }
}

/// 自动化规则配置
class AutomationConfig {
  /// 定时触发配置
  final int? scheduleHour; // 小时 (0-23)
  final int? scheduleMinute; // 分钟 (0-59)
  final String? scheduleType; // 'daily', 'weekly'
  final int? weekDay; // 1-7 (周一到周日)

  /// 金额阈值配置
  final double? thresholdAmount;
  final bool? isPercentage; // 是否为百分比

  /// 分类配置
  final String? targetCategory;
  final List<String>? keywords; // 关键词列表

  /// 通知配置
  final String? notificationTitle;
  final String? notificationBody;

  const AutomationConfig({
    this.scheduleHour,
    this.scheduleMinute,
    this.scheduleType,
    this.weekDay,
    this.thresholdAmount,
    this.isPercentage,
    this.targetCategory,
    this.keywords,
    this.notificationTitle,
    this.notificationBody,
  });

  factory AutomationConfig.fromJson(Map<String, dynamic> json) {
    // 验证 scheduleHour (0-23)
    int? scheduleHour;
    if (json['scheduleHour'] != null) {
      final hour = json['scheduleHour'] as int;
      if (hour >= 0 && hour <= 23) {
        scheduleHour = hour;
      } else {
        developer.log(
          'Invalid scheduleHour: $hour, expected 0-23',
          name: 'AutomationConfig',
        );
      }
    }

    // 验证 scheduleMinute (0-59)
    int? scheduleMinute;
    if (json['scheduleMinute'] != null) {
      final minute = json['scheduleMinute'] as int;
      if (minute >= 0 && minute <= 59) {
        scheduleMinute = minute;
      } else {
        developer.log(
          'Invalid scheduleMinute: $minute, expected 0-59',
          name: 'AutomationConfig',
        );
      }
    }

    // 验证 thresholdAmount (正数)
    double? thresholdAmount;
    if (json['thresholdAmount'] != null) {
      final amount = (json['thresholdAmount'] as num).toDouble();
      if (amount > 0) {
        thresholdAmount = amount;
      } else {
        developer.log(
          'Invalid thresholdAmount: $amount, must be positive',
          name: 'AutomationConfig',
        );
      }
    }

    // 验证 weekDay (1-7)
    int? weekDay;
    if (json['weekDay'] != null) {
      final day = json['weekDay'] as int;
      if (day >= 1 && day <= 7) {
        weekDay = day;
      } else {
        developer.log(
          'Invalid weekDay: $day, expected 1-7',
          name: 'AutomationConfig',
        );
      }
    }

    return AutomationConfig(
      scheduleHour: scheduleHour,
      scheduleMinute: scheduleMinute,
      scheduleType: json['scheduleType'] as String?,
      weekDay: weekDay,
      thresholdAmount: thresholdAmount,
      isPercentage: json['isPercentage'] as bool?,
      targetCategory: json['targetCategory'] as String?,
      keywords: (json['keywords'] as List<dynamic>?)?.cast<String>(),
      notificationTitle: json['notificationTitle'] as String?,
      notificationBody: json['notificationBody'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (scheduleHour != null) 'scheduleHour': scheduleHour,
      if (scheduleMinute != null) 'scheduleMinute': scheduleMinute,
      if (scheduleType != null) 'scheduleType': scheduleType,
      if (weekDay != null) 'weekDay': weekDay,
      if (thresholdAmount != null) 'thresholdAmount': thresholdAmount,
      if (isPercentage != null) 'isPercentage': isPercentage,
      if (targetCategory != null) 'targetCategory': targetCategory,
      if (keywords != null) 'keywords': keywords,
      if (notificationTitle != null) 'notificationTitle': notificationTitle,
      if (notificationBody != null) 'notificationBody': notificationBody,
    };
  }

  AutomationConfig copyWith({
    int? scheduleHour,
    int? scheduleMinute,
    String? scheduleType,
    int? weekDay,
    double? thresholdAmount,
    bool? isPercentage,
    String? targetCategory,
    List<String>? keywords,
    String? notificationTitle,
    String? notificationBody,
  }) {
    return AutomationConfig(
      scheduleHour: scheduleHour ?? this.scheduleHour,
      scheduleMinute: scheduleMinute ?? this.scheduleMinute,
      scheduleType: scheduleType ?? this.scheduleType,
      weekDay: weekDay ?? this.weekDay,
      thresholdAmount: thresholdAmount ?? this.thresholdAmount,
      isPercentage: isPercentage ?? this.isPercentage,
      targetCategory: targetCategory ?? this.targetCategory,
      keywords: keywords ?? this.keywords,
      notificationTitle: notificationTitle ?? this.notificationTitle,
      notificationBody: notificationBody ?? this.notificationBody,
    );
  }
}

/// 自动化规则
class AutomationRule {
  final String id;
  final String name;
  final TriggerType triggerType;
  final ActionType actionType;
  final AutomationConfig config;
  final bool isEnabled;
  final DateTime? lastTriggered;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AutomationRule({
    String? id,
    required this.name,
    required this.triggerType,
    required this.actionType,
    required this.config,
    this.isEnabled = true,
    this.lastTriggered,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  AutomationRule copyWith({
    String? id,
    String? name,
    TriggerType? triggerType,
    ActionType? actionType,
    AutomationConfig? config,
    bool? isEnabled,
    DateTime? lastTriggered,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      triggerType: triggerType ?? this.triggerType,
      actionType: actionType ?? this.actionType,
      config: config ?? this.config,
      isEnabled: isEnabled ?? this.isEnabled,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'triggerType': triggerType.value,
      'actionType': actionType.value,
      'config': config.toJson(),
      'isEnabled': isEnabled ? 1 : 0,
      'lastTriggered': lastTriggered?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory AutomationRule.fromMap(Map<String, dynamic> map) {
    return AutomationRule(
      id: map['id'] as String,
      name: map['name'] as String,
      triggerType: TriggerType.fromValue(map['triggerType'] as String),
      actionType: ActionType.fromValue(map['actionType'] as String),
      config: _parseConfig(map['config']),
      isEnabled: (map['isEnabled'] as int?) == 1,
      lastTriggered: map['lastTriggered'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastTriggered'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }

  static AutomationConfig _parseConfig(dynamic config) {
    if (config == null) {
      return const AutomationConfig();
    }
    if (config is Map<String, dynamic>) {
      return AutomationConfig.fromJson(config);
    }
    if (config is String) {
      try {
        // Try to parse as JSON
        final decoded = jsonDecode(config);
        if (decoded is Map<String, dynamic>) {
          return AutomationConfig.fromJson(decoded);
        }
      } catch (e) {
        developer.log(
          'Failed to parse config: $config, error: $e',
          name: 'AutomationRule',
          level: 800, // warning level
        );
      }
    }
    return const AutomationConfig();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AutomationRule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 预置自动化规则
class PresetAutomationRules {
  /// 预算超支提醒 (90%)
  static AutomationRule budgetWarning() {
    return AutomationRule(
      name: '预算超支提醒',
      triggerType: TriggerType.amountThreshold,
      actionType: ActionType.notification,
      config: const AutomationConfig(
        thresholdAmount: 90,
        isPercentage: true,
        notificationTitle: '预算提醒',
        notificationBody: '本月支出已达到预算的90%，请注意开支！',
      ),
    );
  }

  /// 大额消费提醒 (500元)
  static AutomationRule largeAmountWarning() {
    return AutomationRule(
      name: '大额消费提醒',
      triggerType: TriggerType.amountThreshold,
      actionType: ActionType.notification,
      config: const AutomationConfig(
        thresholdAmount: 500,
        isPercentage: false,
        notificationTitle: '大额消费提醒',
        notificationBody: '您有一笔超过500元的支出，请确认是否为本人操作。',
      ),
    );
  }

  /// 每日记账提醒
  static AutomationRule dailyReminder() {
    return AutomationRule(
      name: '每日记账提醒',
      triggerType: TriggerType.scheduled,
      actionType: ActionType.notification,
      config: const AutomationConfig(
        scheduleHour: 20,
        scheduleMinute: 0,
        scheduleType: 'daily',
        notificationTitle: '记账提醒',
        notificationBody: '该记账啦！今天有什么开支吗？',
      ),
    );
  }

  /// 每周记账提醒
  static AutomationRule weeklyReminder() {
    return AutomationRule(
      name: '每周记账提醒',
      triggerType: TriggerType.scheduled,
      actionType: ActionType.notification,
      config: const AutomationConfig(
        scheduleHour: 10,
        scheduleMinute: 0,
        scheduleType: 'weekly',
        weekDay: 1, // 周一
        notificationTitle: '周末记账提醒',
        notificationBody: '周末来了，别忘了记录本周的开支哦！',
      ),
    );
  }

  /// 餐饮自动分类
  static AutomationRule foodAutoCategorize() {
    return AutomationRule(
      name: '餐饮自动分类',
      triggerType: TriggerType.category,
      actionType: ActionType.categorize,
      config: const AutomationConfig(
        targetCategory: 'food',
        keywords: ['早餐', '午餐', '晚餐', '外卖', '餐厅', '奶茶', '咖啡', '零食', '超市'],
        notificationTitle: null,
        notificationBody: null,
      ),
    );
  }

  /// 交通自动分类
  static AutomationRule transportAutoCategorize() {
    return AutomationRule(
      name: '交通自动分类',
      triggerType: TriggerType.category,
      actionType: ActionType.categorize,
      config: const AutomationConfig(
        targetCategory: 'transport',
        keywords: ['打车', '地铁', '公交', '出租车', '停车', '加油', '高铁', '火车', '飞机'],
        notificationTitle: null,
        notificationBody: null,
      ),
    );
  }

  /// 购物自动分类
  static AutomationRule shoppingAutoCategorize() {
    return AutomationRule(
      name: '购物自动分类',
      triggerType: TriggerType.category,
      actionType: ActionType.categorize,
      config: const AutomationConfig(
        targetCategory: 'shopping',
        keywords: ['淘宝', '京东', '天猫', '拼多多', '外卖', '快递', '网购'],
        notificationTitle: null,
        notificationBody: null,
      ),
    );
  }

  /// 娱乐自动分类
  static AutomationRule entertainmentAutoCategorize() {
    return AutomationRule(
      name: '娱乐自动分类',
      triggerType: TriggerType.category,
      actionType: ActionType.categorize,
      config: const AutomationConfig(
        targetCategory: 'entertainment',
        keywords: ['电影', 'KTV', '游戏', '演唱会', '旅游', '酒店', '健身', '游泳'],
        notificationTitle: null,
        notificationBody: null,
      ),
    );
  }

  /// 获取所有预置规则
  static List<AutomationRule> get allPresets => [
        budgetWarning(),
        largeAmountWarning(),
        dailyReminder(),
        weeklyReminder(),
        foodAutoCategorize(),
        transportAutoCategorize(),
        shoppingAutoCategorize(),
        entertainmentAutoCategorize(),
      ];
}
