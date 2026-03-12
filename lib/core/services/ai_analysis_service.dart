import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/models/expense_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/user_settings.dart';
import 'ai_service.dart';

/// AI 支出分析服务
class AIAnalysisService {
  final http.Client _httpClient = http.Client();

  /// 生成月度消费分析报告
  Future<String> generateMonthlyReport(
    List<Expense> expenses,
    Budget? budget,
    UserSettings settings,
  ) async {
    if (expenses.isEmpty) {
      return '本月还没有消费记录，开始记账吧！';
    }

    // 如果没有配置 AI Key，使用本地分析
    if (!settings.hasAnyAiKey) {
      return _generateLocalReport(expenses, budget);
    }

    // 使用 AI 生成报告
    try {
      return await _generateAIReport(expenses, budget, settings);
    } catch (e) {
      debugPrint('AI report generation failed: $e');
      return _generateLocalReport(expenses, budget);
    }
  }

  /// 本地生成报告（无 AI 时）
  String _generateLocalReport(List<Expense> expenses, Budget? budget) {
    final now = DateTime.now();
    final monthExpenses = expenses.where((e) =>
        e.date.year == now.year && e.date.month == now.month).toList();

    if (monthExpenses.isEmpty) {
      return '本月还没有消费记录';
    }

    // 计算总支出
    final total = monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    // 按分类汇总
    final categoryTotals = <String, double>{};
    for (final expense in monthExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    // 找出最高分类
    String topCategory = '';
    double topAmount = 0;
    categoryTotals.forEach((category, amount) {
      if (amount > topAmount) {
        topAmount = amount;
        topCategory = category;
      }
    });

    // 格式化输出
    final buffer = StringBuffer();
    buffer.writeln('📊 ${now.month}月消费分析');
    buffer.writeln('');
    buffer.writeln('💰 本月支出：¥${total.toStringAsFixed(2)}');
    buffer.writeln('');

    if (budget != null) {
      final remaining = budget.amount - total;
      final percent = (total / budget.amount * 100).clamp(0, 100);
      buffer.writeln('📈 预算：已使用 ${percent.toStringAsFixed(1)}%');

      if (remaining >= 0) {
        buffer.writeln('💵 剩余预算：¥${remaining.toStringAsFixed(2)}');
      } else {
        buffer.writeln('⚠️ 已超出预算：¥${(-remaining).toStringAsFixed(2)}');
      }
      buffer.writeln('');
    }

    buffer.writeln('📋 分类明细：');
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCategories) {
      final percent = (entry.value / total * 100).toStringAsFixed(1);
      buffer.writeln('  ${entry.key}: ¥${entry.value.toStringAsFixed(2)} ($percent%)');
    }

    buffer.writeln('');
    buffer.writeln('🎯 最大支出：$topCategory (¥${topAmount.toStringAsFixed(2)})');

    return buffer.toString();
  }

  /// 使用 AI 生成报告
  Future<String> _generateAIReport(
    List<Expense> expenses,
    Budget? budget,
    UserSettings settings,
  ) async {
    final model = _selectAvailableModel(settings);
    final apiKey = _getApiKey(model, settings)!;
    final config = _getModelConfig(model);

    final now = DateTime.now();
    final monthExpenses = expenses.where((e) =>
        e.date.year == now.year && e.date.month == now.month).toList();

    // 构建消费数据摘要
    final expenseSummary = _buildExpenseSummary(monthExpenses);

    final prompt = '''
请分析以下消费记录，生成一份简洁的月度报告：

本月消费总额：¥${expenseSummary['total']}
消费笔数：${monthExpenses.length}

分类明细：
${expenseSummary['categories']}

${budget != null ? '预算信息：总额 ¥${budget.amount}，已使用 ¥${expenseSummary['total']}' : ''}

请用中文生成报告，包括：
1. 消费概况（一句话总结）
2. 主要支出分析
3. 消费建议（2-3句话，可操作的具体建议）
4. 预算使用情况（如果有预算）

报告要简洁，总共200字以内。输出纯文本，不要用Markdown格式。
''';

    final body = {
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.7,
    };

    final requestBody = config['requestBuilder'](body, apiKey);

    final response = await _httpClient.post(
      Uri.parse(config['endpoint'] as String),
      headers: config['headers'](apiKey),
      body: jsonEncode(requestBody),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('AI服务响应超时'),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        // 验证响应结构
        if (data == null || data is! Map<String, dynamic>) {
          throw Exception('Invalid AI response format');
        }
        return config['parser'](data, response.body);
      } catch (e) {
        throw Exception('Failed to parse AI response: $e');
      }
    } else {
      throw Exception('API error: ${response.statusCode}');
    }
  }

  /// 分析消费习惯
  Future<Map<String, dynamic>> analyzeSpendingHabits(
    List<Expense> expenses,
    UserSettings settings,
  ) async {
    if (expenses.isEmpty) {
      return {
        'hasData': false,
        'message': '暂无消费数据',
      };
    }

    // 本地分析
    final habits = _analyzeHabitsLocally(expenses);

    // 如果有 AI，可以进一步分析
    if (settings.hasAnyAiKey) {
      try {
        final aiInsights = await _getAIInsights(expenses, settings);
        habits['aiInsights'] = aiInsights;
      } catch (e) {
        debugPrint('AI insights failed: $e');
      }
    }

    return habits;
  }

  /// 本地分析消费习惯
  Map<String, dynamic> _analyzeHabitsLocally(List<Expense> expenses) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);

    // 本月数据
    final monthExpenses = expenses.where((e) =>
        e.date.year == thisMonth.year && e.date.month == thisMonth.month).toList();

    // 上月数据
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthExpenses = expenses.where((e) =>
        e.date.year == lastMonth.year && e.date.month == lastMonth.month).toList();

    // 计算各项指标
    final thisMonthTotal = monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final lastMonthTotal = lastMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    // 月度变化
    double monthOverMonthChange = 0;
    if (lastMonthTotal > 0) {
      monthOverMonthChange = (thisMonthTotal - lastMonthTotal) / lastMonthTotal * 100;
    }

    // 按星期分析
    final weekdayTotals = List<double>.filled(7, 0);
    final weekdayCounts = List<int>.filled(7, 0);
    for (final expense in monthExpenses) {
      final weekday = expense.date.weekday - 1; // 0 = Monday
      weekdayTotals[weekday] += expense.amount;
      weekdayCounts[weekday]++;
    }

    // 找出消费最高的日子
    int maxWeekday = 0;
    for (int i = 1; i < 7; i++) {
      if (weekdayTotals[i] > weekdayTotals[maxWeekday]) {
        maxWeekday = i;
      }
    }

    final weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    // 按金额区间统计
    final amountRanges = {
      '0-50': 0,
      '50-100': 0,
      '100-200': 0,
      '200-500': 0,
      '500+': 0,
    };
    for (final expense in monthExpenses) {
      if (expense.amount < 50) {
        amountRanges['0-50'] = (amountRanges['0-50'] ?? 0) + 1;
      } else if (expense.amount < 100) {
        amountRanges['50-100'] = (amountRanges['50-100'] ?? 0) + 1;
      } else if (expense.amount < 200) {
        amountRanges['100-200'] = (amountRanges['100-200'] ?? 0) + 1;
      } else if (expense.amount < 500) {
        amountRanges['200-500'] = (amountRanges['200-500'] ?? 0) + 1;
      } else {
        amountRanges['500+'] = (amountRanges['500+'] ?? 0) + 1;
      }
    }

    return {
      'hasData': true,
      'thisMonthTotal': thisMonthTotal,
      'lastMonthTotal': lastMonthTotal,
      'monthOverMonthChange': monthOverMonthChange,
      'expenseCount': monthExpenses.length,
      'averageExpense': monthExpenses.isEmpty ? 0 : thisMonthTotal / monthExpenses.length,
      'topSpendingDay': weekdayNames[maxWeekday],
      'topSpendingDayAmount': weekdayTotals[maxWeekday],
      'amountRanges': amountRanges,
      'categoryBreakdown': _getCategoryBreakdown(monthExpenses),
    };
  }

  /// 获取分类占比
  Map<String, double> _getCategoryBreakdown(List<Expense> expenses) {
    final totals = <String, double>{};
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    for (final expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }

    // 转换为百分比
    return totals.map((key, value) => MapEntry(key, total > 0 ? value / total * 100 : 0));
  }

  /// 获取 AI 洞察
  Future<String> _getAIInsights(List<Expense> expenses, UserSettings settings) async {
    final model = _selectAvailableModel(settings);
    final apiKey = _getApiKey(model, settings)!;
    final config = _getModelConfig(model);

    final now = DateTime.now();
    final monthExpenses = expenses.where((e) =>
        e.date.year == now.year && e.date.month == now.month).toList();

    final prompt = '''
分析以下消费习惯，提供洞察和建议：

消费数据：
- 本月消费 ${monthExpenses.length} 笔
- 总金额 ¥${monthExpenses.fold<double>(0, (sum, e) => sum + e.amount).toStringAsFixed(2)}
- 分类占比：${_getCategoryBreakdown(monthExpenses)}

请用50字以内给出最重要的1-2个洞察和建议。
''';

    final body = {
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.7,
    };

    final requestBody = config['requestBuilder'](body, apiKey);

    final response = await _httpClient.post(
      Uri.parse(config['endpoint'] as String),
      headers: config['headers'](apiKey),
      body: jsonEncode(requestBody),
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException('AI服务响应超时'),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        // 验证响应结构
        if (data == null || data is! Map<String, dynamic>) {
          throw Exception('Invalid AI response format');
        }
        return config['parser'](data, response.body);
      } catch (e) {
        throw Exception('Failed to parse AI response: $e');
      }
    } else {
      throw Exception('API error: ${response.statusCode}');
    }
  }

  /// 建议预算
  Future<double> suggestBudget(
    List<Expense> expenses,
    UserSettings settings,
  ) async {
    if (expenses.isEmpty) {
      return 3000.0; // 默认建议
    }

    // 基于过去3个月的数据分析
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);

    final recentExpenses = expenses.where((e) =>
        e.date.isAfter(threeMonthsAgo)).toList();

    if (recentExpenses.isEmpty) {
      return 3000.0;
    }

    // 计算月均支出
    final monthlyTotals = <int, double>{};
    for (final expense in recentExpenses) {
      final key = expense.date.year * 12 + expense.date.month;
      monthlyTotals[key] = (monthlyTotals[key] ?? 0) + expense.amount;
    }

    if (monthlyTotals.isEmpty) {
      return 3000.0;
    }

    // 计算平均值
    final average = monthlyTotals.values.reduce((a, b) => a + b) / monthlyTotals.length;

    // 使用 AI 获得更智能的建议
    if (settings.hasAnyAiKey) {
      try {
        final aiBudget = await _getAIBudgetSuggestion(recentExpenses, average, settings);
        if (aiBudget != null) return aiBudget;
      } catch (e) {
        debugPrint('AI budget suggestion failed: $e');
      }
    }

    // 返回月均值的1.1倍作为建议（留10%缓冲）
    return average * 1.1;
  }

  /// 使用 AI 建议预算
  Future<double?> _getAIBudgetSuggestion(
    List<Expense> expenses,
    double average,
    UserSettings settings,
  ) async {
    final model = _selectAvailableModel(settings);
    final apiKey = _getApiKey(model, settings)!;
    final config = _getModelConfig(model);

    final now = DateTime.now();
    final monthExpenses = expenses.where((e) =>
        e.date.year == now.year && e.date.month == now.month).toList();

    final prompt = '''
基于以下消费数据，建议一个合理的月度预算：

过去月均消费：¥${average.toStringAsFixed(2)}
本月消费：¥${monthExpenses.fold<double>(0, (sum, e) => sum + e.amount).toStringAsFixed(2)}
消费笔数：${monthExpenses.length}

请只输出一个数字（建议的月度预算金额），不要输出其他内容。
''';

    final body = {
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.3,
    };

    final requestBody = config['requestBuilder'](body, apiKey);

    final response = await _httpClient.post(
      Uri.parse(config['endpoint'] as String),
      headers: config['headers'](apiKey),
      body: jsonEncode(requestBody),
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException('AI服务响应超时'),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        // 验证响应结构
        if (data == null || data is! Map<String, dynamic>) {
          return null;
        }
        final content = config['parser'](data, response.body);

        // 提取数字
        final match = RegExp(r'(\d+\.?\d*)').firstMatch(content);
        if (match != null) {
          return double.tryParse(match.group(1)!);
        }
      } catch (e) {
        debugPrint('Failed to parse AI budget response: $e');
      }
    }

    return null;
  }

  /// 构建消费摘要
  Map<String, dynamic> _buildExpenseSummary(List<Expense> expenses) {
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final categoriesStr = sortedCategories
        .map((e) => '${e.key}: ¥${e.value.toStringAsFixed(2)}')
        .join('\n');

    return {
      'total': total.toStringAsFixed(2),
      'categories': categoriesStr,
    };
  }

  AiModelType _selectAvailableModel(UserSettings settings) {
    if (settings.claudeApiKey?.isNotEmpty == true) return AiModelType.claude;
    if (settings.openaiApiKey?.isNotEmpty == true) return AiModelType.openai;
    if (settings.zhipuApiKey?.isNotEmpty == true) return AiModelType.zhipu;
    if (settings.qwenApiKey?.isNotEmpty == true) return AiModelType.qwen;
    if (settings.hunyuanApiKey?.isNotEmpty == true) return AiModelType.hunyuan;
    throw Exception('没有配置任何AI API Key');
  }

  String? _getApiKey(AiModelType model, UserSettings settings) {
    switch (model) {
      case AiModelType.openai:
        return settings.openaiApiKey;
      case AiModelType.claude:
        return settings.claudeApiKey;
      case AiModelType.qwen:
        return settings.qwenApiKey;
      case AiModelType.hunyuan:
        return settings.hunyuanApiKey;
      case AiModelType.zhipu:
        return settings.zhipuApiKey;
    }
  }

  Map<String, dynamic> _getModelConfig(AiModelType model) {
    switch (model) {
      case AiModelType.openai:
        return {
          'endpoint': 'https://api.openai.com/v1/chat/completions',
          'headers': (key) => {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $key',
          },
          'requestBuilder': (body, _) => {...body, 'model': 'gpt-3.5-turbo'},
          'parser': (data, _) => data['choices'][0]['message']['content'] as String,
        };
      case AiModelType.claude:
        return {
          'endpoint': 'https://api.anthropic.com/v1/messages',
          'headers': (key) => {
            'Content-Type': 'application/json',
            'x-api-key': key,
            'anthropic-version': '2023-06-01',
          },
          'requestBuilder': (body, _) => {
            'model': 'claude-3-haiku-20240307',
            'max_tokens': 1024,
            'messages': body['messages'],
          },
          'parser': (data, _) => data['content'][0]['text'] as String,
        };
      default:
        return {
          'endpoint': 'https://open.bigmodel.cn/api/paas/v4/chat/completions',
          'headers': (key) => {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $key',
          },
          'requestBuilder': (body, _) => {...body, 'model': 'glm-4-flash'},
          'parser': (data, _) => data['choices'][0]['message']['content'] as String,
        };
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
