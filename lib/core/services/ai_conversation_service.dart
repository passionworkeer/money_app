import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/models/expense_model.dart';
import '../../data/models/user_settings.dart';
import 'ai_service.dart';

/// AI 对话式记账服务
/// 语音转文字 → AI理解 → 提取金额/分类/日期 → 确认 → 记账
class AIConversationService {
  final AiService _aiService = AiService();
  final http.Client _httpClient = http.Client();

  /// 处理语音输入
  /// 1. 语音转文字（由 SpeechService 完成）
  /// 2. AI 理解并提取信息
  /// 3. 返回解析后的记账信息
  Future<ParsedExpense> processVoiceInput(String text, UserSettings settings) async {
    return await parseText(text, settings);
  }

  /// 解析文本输入，提取金额、分类、日期
  Future<ParsedExpense> parseText(String text, UserSettings settings) async {
    if (text.isEmpty) {
      throw ArgumentError('输入文本不能为空');
    }

    // 先尝试本地解析
    final localResult = _parseLocally(text);
    if (localResult != null) {
      return localResult;
    }

    // 使用 AI 进行语义解析
    if (settings.hasAnyAiKey) {
      try {
        return await _parseWithAI(text, settings);
      } catch (e) {
        debugPrint('AI parsing failed: $e');
        // 回退到基础解析
        return _basicParse(text);
      }
    }

    // 兜底解析
    return _basicParse(text);
  }

  /// 本地解析 - 快速响应
  ParsedExpense? _parseLocally(String text) {
    // 金额提取
    final amount = _extractAmount(text);
    if (amount == null) return null;

    // 分类提取
    final category = _extractCategory(text);
    if (category == null) return null;

    // 日期提取
    final date = _extractDate(text) ?? DateTime.now();

    return ParsedExpense(
      amount: amount,
      category: category,
      date: date,
      description: text,
      confidence: 0.7,
      isLocalParse: true,
    );
  }

  /// 使用 AI 进行语义解析
  Future<ParsedExpense> _parseWithAI(String text, UserSettings settings) async {
    final model = _aiService.classifyExpense(description: text, settings: settings);

    // 尝试提取更多信息
    final aiResult = await model;

    // 使用AI解析更多细节（日期、备注等）
    final detailPrompt = '''
从以下消费描述中提取信息：

描述：$text

请以JSON格式输出，包含以下字段：
- amount: 金额数字（如果没有明确提到金额，输出null）
- category: 分类（餐饮/交通/购物/娱乐/医疗/教育/其他）
- date: 日期（如果有提到具体日期，输出"YYYY-MM-DD"格式，否则输出null）
- description: 简短描述

只输出JSON，不要其他内容。
''';

    final details = await _callAIWithPrompt(detailPrompt, settings);

    double? parsedAmount;
    DateTime? parsedDate;
    String? parsedDescription;

    try {
      final jsonMatch = RegExp(r'\{.*\}').firstMatch(details);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!);
        if (json['amount'] != null && json['amount'] != 'null') {
          parsedAmount = _parseAmount(json['amount']);
        }
        if (json['date'] != null && json['date'] != 'null') {
          parsedDate = _parseDate(json['date']);
        }
        parsedDescription = json['description'] as String?;
      }
    } catch (e) {
      debugPrint('Failed to parse AI details: $e');
    }

    return ParsedExpense(
      amount: parsedAmount ?? aiResult.amount,
      category: aiResult.category,
      date: parsedDate ?? DateTime.now(),
      description: parsedDescription ?? text,
      confidence: aiResult.confidence,
      isLocalParse: aiResult.isLocal,
    );
  }

  /// 基础解析 - 当 AI 不可用时
  ParsedExpense _basicParse(String text) {
    final amount = _extractAmount(text) ?? 0.0;
    final category = _extractCategory(text) ?? '其他';
    final date = _extractDate(text) ?? DateTime.now();

    return ParsedExpense(
      amount: amount,
      category: category,
      date: date,
      description: text,
      confidence: 0.3,
      isLocalParse: true,
    );
  }

  /// 生成确认消息
  String confirmExpense(ParsedExpense parsed) {
    final dateStr = _formatDate(parsed.date);
    final amountStr = parsed.amount?.toStringAsFixed(2) ?? '未知';

    return '确认以下信息：\n'
        '金额：¥$amountStr\n'
        '分类：${parsed.category}\n'
        '日期：$dateStr\n'
        '描述：${parsed.description}';
  }

  /// 生成确认的回复消息
  String generateConfirmationMessage(ParsedExpense parsed, {bool isCorrect = true}) {
    if (isCorrect) {
      return '好的，已为您记录：${parsed.category} ¥${parsed.amount?.toStringAsFixed(2) ?? "未知"}';
    } else {
      return '好的，请您修正信息。';
    }
  }

  /// 生成多候选分类（模糊匹配）
  Future<List<CategoryCandidate>> getCategoryCandidates(
    String text,
    UserSettings settings,
  ) async {
    final candidates = <CategoryCandidate>[];

    // 本地关键词匹配
    final localCategory = _extractCategory(text);
    if (localCategory != null) {
      candidates.add(CategoryCandidate(
        category: localCategory,
        confidence: 0.8,
        reason: '关键词匹配',
      ));
    }

    // 使用 AI 获取更多候选
    if (settings.hasAnyAiKey) {
      try {
        final aiResult = await _aiService.classifyExpense(
          description: text,
          settings: settings,
        );

        // 添加主分类
        if (candidates.isEmpty || candidates.first.category != aiResult.category) {
          candidates.insert(0, CategoryCandidate(
            category: aiResult.category,
            confidence: aiResult.confidence,
            reason: 'AI智能识别',
          ));
        }

        // 获取相似分类（通过AI）
        final similarCategories = await _getSimilarCategories(text, settings);
        for (final cat in similarCategories) {
          if (!candidates.any((c) => c.category == cat)) {
            candidates.add(CategoryCandidate(
              category: cat,
              confidence: 0.5,
              reason: '可能相关',
            ));
          }
        }
      } catch (e) {
        debugPrint('Failed to get AI candidates: $e');
      }
    }

    // 排序并返回前3个
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return candidates.take(3).toList();
  }

  /// 获取相似分类
  Future<List<String>> _getSimilarCategories(String text, UserSettings settings) async {
    final prompt = '''
用户输入：$text

可能的分类有：餐饮、交通、购物、娱乐、医疗、教育、其他

请根据语义判断哪些分类可能相关（最多2个）。
只输出分类名称，用逗号分隔，不要其他内容。
''';

    try {
      final response = await _callAIWithPrompt(prompt, settings);
      return response
          .split(RegExp(r'[,，]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(2)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 调用 AI
  Future<String> _callAIWithPrompt(String prompt, UserSettings settings) async {
    final model = _selectAvailableModel(settings);
    final apiKey = _getApiKey(model, settings)!;
    final config = _getModelConfig(model);

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
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('AI服务响应超时'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return config['parser'](data, response.body);
    } else {
      throw Exception('API error: ${response.statusCode}');
    }
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

  /// 提取金额
  double? _extractAmount(String text) {
    final patterns = [
      RegExp(r'(\d+\.?\d*)\s*(?:元|块|圆)'),
      RegExp(r'[花了消费付了用了]\s*(\d+\.?\d*)'),
      RegExp(r'¥?\s*(\d+\.?\d*)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final amount = double.tryParse(match.group(1)!);
        if (amount != null && amount > 0 && amount < 1000000) {
          return amount;
        }
      }
    }
    return null;
  }

  /// 提取分类
  String? _extractCategory(String text) {
    final lowerText = text.toLowerCase();

    final categoryKeywords = {
      '餐饮': ['吃饭', '午餐', '晚餐', '早餐', '外卖', '餐厅', '火锅', '烧烤', '奶茶', '咖啡', '点外卖'],
      '交通': ['打车', '滴滴', '地铁', '公交', '高铁', '火车', '飞机', '加油', '停车'],
      '购物': ['淘宝', '京东', '天猫', '拼多多', '衣服', '鞋子', '包包', '化妆品', '护肤品'],
      '娱乐': ['电影', 'KTV', '唱歌', '游戏', '充值', '会员', '旅游', '健身', '游泳'],
      '医疗': ['医院', '药店', '看病', '买药', '体检', '牙科'],
      '教育': ['学费', '培训', '课程', '书籍', '教材', '文具'],
    };

    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  /// 提取日期
  DateTime? _extractDate(String text) {
    final now = DateTime.now();

    // 今天
    if (text.contains('今天')) return now;

    // 昨天
    if (text.contains('昨天')) {
      return DateTime(now.year, now.month, now.day - 1);
    }

    // 前天
    if (text.contains('前天')) {
      return DateTime(now.year, now.month, now.day - 2);
    }

    // 明天
    if (text.contains('明天')) {
      return DateTime(now.year, now.month, now.day + 1);
    }

    // 具体日期格式
    final datePattern = RegExp(r'(\d{1,2})[月/-](\d{1,2})');
    final match = datePattern.firstMatch(text);
    if (match != null) {
      final month = int.tryParse(match.group(1)!);
      final day = int.tryParse(match.group(2)!);
      if (month != null && day != null && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(now.year, month, day);
      }
    }

    return null;
  }

  /// 解析金额
  double? _parseAmount(dynamic value) {
    if (value == null || value == 'unknown') return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  /// 解析日期
  DateTime? _parseDate(String value) {
    try {
      // 尝试解析 YYYY-MM-DD 格式
      final parts = value.split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year != null && month != null && day != null) {
          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      debugPrint('Failed to parse date: $e');
    }
    return null;
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return '今天';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return '昨天';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return '明天';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// 解析后的记账信息
class ParsedExpense {
  final double? amount;
  final String category;
  final DateTime date;
  final String description;
  final double confidence;
  final bool isLocalParse;

  const ParsedExpense({
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    required this.confidence,
    required this.isLocalParse,
  });

  /// 转换为 Expense 对象
  Expense toExpense() {
    return Expense(
      amount: amount ?? 0.0,
      description: description,
      category: category,
      date: date,
    );
  }
}
