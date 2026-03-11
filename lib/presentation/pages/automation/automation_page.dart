import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/automation_rule.dart';
import '../../providers/automation_providers.dart';

/// 自动化设置页面
class AutomationPage extends ConsumerWidget {
  const AutomationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(automationRulesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('自动化'),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRuleDialog(context, ref),
          ),
        ],
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(automationRulesProvider.notifier).loadRules(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (rules) {
          if (rules.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return _buildRuleList(context, ref, rules);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无自动化规则',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加实现规则自动提醒和分类',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddRuleDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('添加规则'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '快捷添加预置规则',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _PresetChip(
                label: '预算提醒',
                onTap: () => _addPresetRule(ref, PresetAutomationRules.budgetWarning()),
              ),
              _PresetChip(
                label: '大额提醒',
                onTap: () => _addPresetRule(ref, PresetAutomationRules.largeAmountWarning()),
              ),
              _PresetChip(
                label: '每日提醒',
                onTap: () => _addPresetRule(ref, PresetAutomationRules.dailyReminder()),
              ),
              _PresetChip(
                label: '自动分类',
                onTap: () => _addPresetRules(ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleList(BuildContext context, WidgetRef ref, List<AutomationRule> rules) {
    // 分组显示
    final notificationRules = rules.where((r) => r.actionType == ActionType.notification).toList();
    final categorizeRules = rules.where((r) => r.actionType == ActionType.categorize).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 通知规则
        if (notificationRules.isNotEmpty) ...[
          _SectionHeader(
            title: '提醒规则',
            count: notificationRules.length,
          ),
          const SizedBox(height: 8),
          ...notificationRules.map((rule) => _RuleCard(
                rule: rule,
                onToggle: (enabled) {
                  ref.read(automationRulesProvider.notifier).toggleRule(rule.id, enabled);
                },
                onEdit: () => _showEditRuleDialog(context, ref, rule),
                onDelete: () => _showDeleteConfirm(context, ref, rule),
              )),
          const SizedBox(height: 16),
        ],

        // 分类规则
        if (categorizeRules.isNotEmpty) ...[
          _SectionHeader(
            title: '自动分类规则',
            count: categorizeRules.length,
          ),
          const SizedBox(height: 8),
          ...categorizeRules.map((rule) => _RuleCard(
                rule: rule,
                onToggle: (enabled) {
                  ref.read(automationRulesProvider.notifier).toggleRule(rule.id, enabled);
                },
                onEdit: () => _showEditRuleDialog(context, ref, rule),
                onDelete: () => _showDeleteConfirm(context, ref, rule),
              )),
        ],
      ],
    );
  }

  void _showAddRuleDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RuleEditorSheet(
        onSave: (rule) {
          ref.read(automationRulesProvider.notifier).addRule(rule);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditRuleDialog(BuildContext context, WidgetRef ref, AutomationRule rule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RuleEditorSheet(
        rule: rule,
        onSave: (updatedRule) {
          ref.read(automationRulesProvider.notifier).updateRule(updatedRule);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, AutomationRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除规则'),
        content: Text('确定要删除 "${rule.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(automationRulesProvider.notifier).deleteRule(rule.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _addPresetRule(WidgetRef ref, AutomationRule rule) {
    ref.read(automationRulesProvider.notifier).addRule(rule);
  }

  void _addPresetRules(WidgetRef ref) {
    final categorizePresets = [
      PresetAutomationRules.foodAutoCategorize(),
      PresetAutomationRules.transportAutoCategorize(),
      PresetAutomationRules.shoppingAutoCategorize(),
      PresetAutomationRules.entertainmentAutoCategorize(),
    ];
    for (final preset in categorizePresets) {
      ref.read(automationRulesProvider.notifier).addRule(preset);
    }
  }
}

/// Section 标题
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// 预置规则快捷添加按钮
class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      labelStyle: TextStyle(color: AppColors.primary),
    );
  }
}

/// 规则卡片
class _RuleCard extends StatelessWidget {
  final AutomationRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RuleCard({
    required this.rule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTriggerColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTriggerIcon(),
                    size: 20,
                    color: _getTriggerColor(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDescription(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: rule.isEnabled,
                  onChanged: onToggle,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            if (rule.lastTriggered != null) ...[
              const SizedBox(height: 8),
              Text(
                '上次触发: ${_formatDateTime(rule.lastTriggered!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onEdit,
                  child: const Text('编辑'),
                ),
                TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTriggerIcon() {
    switch (rule.triggerType) {
      case TriggerType.scheduled:
        return Icons.schedule;
      case TriggerType.amountThreshold:
        return Icons.attach_money;
      case TriggerType.category:
        return Icons.category;
    }
  }

  Color _getTriggerColor() {
    switch (rule.triggerType) {
      case TriggerType.scheduled:
        return Colors.blue;
      case TriggerType.amountThreshold:
        return Colors.orange;
      case TriggerType.category:
        return Colors.green;
    }
  }

  String _getDescription() {
    final config = rule.config;
    switch (rule.triggerType) {
      case TriggerType.scheduled:
        final type = config.scheduleType == 'daily' ? '每天' : '每周';
        final time = '${config.scheduleHour?.toString().padLeft(2, '0')}:${config.scheduleMinute?.toString().padLeft(2, '0')}';
        return '$type $time 触发';
      case TriggerType.amountThreshold:
        final isPercentage = config.isPercentage ?? false;
        final amount = config.thresholdAmount ?? 0;
        if (isPercentage) {
          return '支出超过 $amount% 时触发';
        }
        return '金额超过 $amount 元时触发';
      case TriggerType.category:
        return '关键词匹配时自动分类为 ${config.targetCategory}';
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 规则编辑底部表单
class _RuleEditorSheet extends StatefulWidget {
  final AutomationRule? rule;
  final ValueChanged<AutomationRule> onSave;

  const _RuleEditorSheet({
    this.rule,
    required this.onSave,
  });

  @override
  State<_RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends State<_RuleEditorSheet> {
  late TextEditingController _nameController;
  late TriggerType _triggerType;
  late ActionType _actionType;

  // Schedule config
  late int _scheduleHour;
  late int _scheduleMinute;
  late String _scheduleType;
  late int _weekDay;

  // Amount threshold config
  late double _thresholdAmount;
  late bool _isPercentage;

  // Category config
  late String _targetCategory;
  late TextEditingController _keywordsController;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    final config = rule?.config;

    _nameController = TextEditingController(text: rule?.name ?? '');
    _triggerType = rule?.triggerType ?? TriggerType.scheduled;
    _actionType = rule?.actionType ?? ActionType.notification;

    _scheduleHour = config?.scheduleHour ?? 20;
    _scheduleMinute = config?.scheduleMinute ?? 0;
    _scheduleType = config?.scheduleType ?? 'daily';
    _weekDay = config?.weekDay ?? 1;

    _thresholdAmount = config?.thresholdAmount ?? 500;
    _isPercentage = config?.isPercentage ?? false;

    _targetCategory = config?.targetCategory ?? 'food';
    _keywordsController = TextEditingController(text: config?.keywords?.join(', ') ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.rule == null ? '添加规则' : '编辑规则',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // 规则名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '规则名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 触发类型
            const Text(
              '触发类型',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TriggerType.values.map((type) {
                return ChoiceChip(
                  label: Text(type.label),
                  selected: _triggerType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _triggerType = type;
                        // 根据触发类型设置默认动作
                        if (type == TriggerType.category) {
                          _actionType = ActionType.categorize;
                        } else {
                          _actionType = ActionType.notification;
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 动作类型
            const Text(
              '执行动作',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ActionType.values.map((type) {
                return ChoiceChip(
                  label: Text(type.label),
                  selected: _actionType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _actionType = type);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 根据触发类型显示配置
            _buildTriggerConfig(),
            const SizedBox(height: 24),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerConfig() {
    switch (_triggerType) {
      case TriggerType.scheduled:
        return _buildScheduleConfig();
      case TriggerType.amountThreshold:
        return _buildThresholdConfig();
      case TriggerType.category:
        return _buildCategoryConfig();
    }
  }

  Widget _buildScheduleConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '定时配置',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // 频率选择
        Row(
          children: [
            const Text('频率: '),
            ChoiceChip(
              label: const Text('每日'),
              selected: _scheduleType == 'daily',
              onSelected: (selected) {
                if (selected) setState(() => _scheduleType = 'daily');
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('每周'),
              selected: _scheduleType == 'weekly',
              onSelected: (selected) {
                if (selected) setState(() => _scheduleType = 'weekly');
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 时间选择
        Row(
          children: [
            const Text('时间: '),
            Expanded(
              child: Row(
                children: [
                  DropdownButton<int>(
                    value: _scheduleHour,
                    items: List.generate(24, (i) => i).map((h) {
                      return DropdownMenuItem(
                        value: h,
                        child: Text(h.toString().padLeft(2, '0')),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _scheduleHour = v!),
                  ),
                  const Text(' : '),
                  DropdownButton<int>(
                    value: _scheduleMinute,
                    items: List.generate(60, (i) => i).map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(m.toString().padLeft(2, '0')),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _scheduleMinute = v!),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_scheduleType == 'weekly') ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('星期: '),
              DropdownButton<int>(
                value: _weekDay,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('周一')),
                  DropdownMenuItem(value: 2, child: Text('周二')),
                  DropdownMenuItem(value: 3, child: Text('周三')),
                  DropdownMenuItem(value: 4, child: Text('周四')),
                  DropdownMenuItem(value: 5, child: Text('周五')),
                  DropdownMenuItem(value: 6, child: Text('周六')),
                  DropdownMenuItem(value: 7, child: Text('周日')),
                ],
                onChanged: (v) => setState(() => _weekDay = v!),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildThresholdConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '金额阈值配置',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ChoiceChip(
              label: const Text('固定金额'),
              selected: !_isPercentage,
              onSelected: (selected) {
                if (selected) setState(() => _isPercentage = false);
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('预算百分比'),
              selected: _isPercentage,
              onSelected: (selected) {
                if (selected) setState(() => _isPercentage = true);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('阈值: '),
            SizedBox(
              width: 100,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(
                  text: _thresholdAmount.toString(),
                ),
                onChanged: (v) => _thresholdAmount = double.tryParse(v) ?? 0,
              ),
            ),
            Text(_isPercentage ? ' %' : ' 元'),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryConfig() {
    final categories = [
      ('food', '餐饮'),
      ('transport', '交通'),
      ('shopping', '购物'),
      ('entertainment', '娱乐'),
      ('medical', '医疗'),
      ('education', '教育'),
      ('other', '其他'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分类配置',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('目标分类: '),
            DropdownButton<String>(
              value: _targetCategory,
              items: categories.map((c) {
                return DropdownMenuItem(
                  value: c.$1,
                  child: Text(c.$2),
                );
              }).toList(),
              onChanged: (v) => setState(() => _targetCategory = v!),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _keywordsController,
          decoration: const InputDecoration(
            labelText: '关键词（用逗号分隔）',
            hintText: '例如: 早餐, 午餐, 外卖',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  void _save() {
    // 验证规则名称：限制100字符
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入规则名称')),
      );
      return;
    }
    if (name.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('规则名称不能超过100个字符')),
      );
      return;
    }

    // 验证并过滤关键词：过滤特殊字符
    final keywordsRaw = _keywordsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // 过滤特殊字符，只保留中文、英文、数字和常用符号
    final specialCharRegex = RegExp(r'[^\w\u4e00-\u9fa5\s]');
    final keywords = keywordsRaw
        .map((k) => k.replaceAll(specialCharRegex, ''))
        .where((k) => k.isNotEmpty)
        .toList();

    // 验证关键词数量
    if (_triggerType == TriggerType.category && keywords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少输入一个有效的关键词')),
      );
      return;
    }

    final config = AutomationConfig(
      scheduleHour: _triggerType == TriggerType.scheduled ? _scheduleHour : null,
      scheduleMinute: _triggerType == TriggerType.scheduled ? _scheduleMinute : null,
      scheduleType: _triggerType == TriggerType.scheduled ? _scheduleType : null,
      weekDay: _triggerType == TriggerType.scheduled && _scheduleType == 'weekly' ? _weekDay : null,
      thresholdAmount: _triggerType == TriggerType.amountThreshold ? _thresholdAmount : null,
      isPercentage: _triggerType == TriggerType.amountThreshold ? _isPercentage : null,
      targetCategory: _triggerType == TriggerType.category ? _targetCategory : null,
      keywords: _triggerType == TriggerType.category ? keywords : null,
    );

    final rule = AutomationRule(
      id: widget.rule?.id,
      name: name,
      triggerType: _triggerType,
      actionType: _actionType,
      config: config,
      isEnabled: widget.rule?.isEnabled ?? true,
      lastTriggered: widget.rule?.lastTriggered,
      createdAt: widget.rule?.createdAt,
    );

    widget.onSave(rule);
  }
}
