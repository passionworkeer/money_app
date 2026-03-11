import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/models/user_settings.dart';
import 'local_ai_service.dart';

// 模型类型枚举
enum AiModelType {
  openai, // OpenAI GPT
  claude, // Anthropic Claude
  // ernie, // 百度文心一言 - 暂时移除，需要OAuth流程
  qwen, // 阿里通义千问
  // spark, // 讯飞星火 - 暂时移除，需要复杂签名验证
  hunyuan, // 腾讯混元
  zhipu, // 智谱AI (ChatGLM)
}

// 分类结果
class AiClassificationResult {
  final double? amount;
  final String category;
  final bool isLocal; // 是否本地判断
  final double confidence; // 置信度 0.0-1.0
  final String? modelName; // 云端使用的模型名称
  final List<CategoryCandidate>? candidates; // 候选分类（模糊匹配）

  AiClassificationResult({
    required this.amount,
    required this.category,
    this.isLocal = false,
    this.confidence = 1.0,
    this.modelName,
    this.candidates,
  });

  @override
  String toString() {
    return 'AiClassificationResult(amount: $amount, category: $category, isLocal: $isLocal, confidence: $confidence, modelName: $modelName, candidates: $candidates)';
  }
}

// 模型配置
class ModelConfig {
  final String name;
  final String endpoint;
  final Map<String, String> Function(String apiKey) headers;
  final String modelName;
  final Map<String, dynamic> Function(Map<String, dynamic> body, String apiKey) requestBuilder;
  final String Function(Map<String, dynamic> data, String rawResponse) responseParser;

  const ModelConfig({
    required this.name,
    required this.endpoint,
    required this.headers,
    required this.modelName,
    required this.requestBuilder,
    required this.responseParser,
  });
}

/// 分类候选（模糊匹配）
class CategoryCandidate {
  final String category;
  final double confidence;
  final String reason;

  const CategoryCandidate({
    required this.category,
    required this.confidence,
    required this.reason,
  });
}

// 用户分类习惯记录
class CategoryHabit {
  final String category;
  final int count;
  final double totalAmount;
  final DateTime lastUsed;

  CategoryHabit({
    required this.category,
    required this.count,
    required this.totalAmount,
    required this.lastUsed,
  });
}

class AiService {
  final LocalAiService _localService = LocalAiService();
  final http.Client _httpClient = http.Client();

  // 用户习惯缓存
  final Map<String, List<CategoryHabit>> _userHabits = {};

  static final Map<AiModelType, ModelConfig> _models = {
    AiModelType.openai: ModelConfig(
      name: 'OpenAI GPT',
      endpoint: 'https://api.openai.com/v1/chat/completions',
      headers: (key) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      modelName: 'gpt-3.5-turbo',
      requestBuilder: (body, _) => {
        ...body,
        'model': 'gpt-3.5-turbo',
      },
      responseParser: (data, _) => data['choices'][0]['message']['content'] as String,
    ),
    AiModelType.claude: ModelConfig(
      name: 'Anthropic Claude',
      endpoint: 'https://api.anthropic.com/v1/messages',
      headers: (key) => {
        'Content-Type': 'application/json',
        'x-api-key': key,
        'anthropic-version': '2023-06-01',
      },
      modelName: 'claude-3-haiku-20240307',
      requestBuilder: (body, _) => {
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 1024,
        'messages': body['messages'],
      },
      responseParser: (data, _) => data['content'][0]['text'] as String,
    ),
    // 百度文心一言 - 暂时移除，需要OAuth流程
    // AiModelType.ernie: ModelConfig(...)
    AiModelType.qwen: ModelConfig(
      name: '阿里通义千问',
      endpoint: 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
      headers: (key) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      modelName: 'qwen-turbo',
      requestBuilder: (body, _) => {
        ...body,
        'model': 'qwen-turbo',
      },
      responseParser: (data, _) => data['choices'][0]['message']['content'] as String,
    ),
    AiModelType.hunyuan: ModelConfig(
      name: '腾讯混元',
      endpoint: 'https://hunyuan.cloud.tencent.com/hunyuan/v1/chat/completion',
      headers: (key) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      modelName: 'hunyuan-turbo',
      requestBuilder: (body, _) => {
        'model': 'hunyuan-turbo',
        'messages': body['messages'],
        'temperature': 0.3,
      },
      responseParser: (data, _) => data['choices'][0]['message']['content'] as String,
    ),
    AiModelType.zhipu: ModelConfig(
      name: '智谱AI (ChatGLM)',
      endpoint: 'https://open.bigmodel.cn/api/paas/v4/chat/completions',
      headers: (key) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      },
      modelName: 'glm-4-flash',
      requestBuilder: (body, _) => {
        ...body,
        'model': 'glm-4-flash',
      },
      responseParser: (data, _) => data['choices'][0]['message']['content'] as String,
    ),
  };

  // 智能选择可用模型（优先级顺序）
  AiModelType _selectAvailableModel(UserSettings settings) {
    // 优先级: Claude > OpenAI > 智谱 > 阿里 > 腾讯
    if (settings.claudeApiKey?.isNotEmpty == true) return AiModelType.claude;
    if (settings.openaiApiKey?.isNotEmpty == true) return AiModelType.openai;
    if (settings.zhipuApiKey?.isNotEmpty == true) return AiModelType.zhipu;
    if (settings.qwenApiKey?.isNotEmpty == true) return AiModelType.qwen;
    if (settings.hunyuanApiKey?.isNotEmpty == true) return AiModelType.hunyuan;
    // 百度文心一言和讯飞星火已暂时移除（需要复杂认证）
    throw Exception('没有配置任何AI API Key');
  }

  // 获取对应模型的API Key
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
      // 百度文心一言和讯飞星火已暂时移除
    }
  }

  /// 更新用户分类习惯
  void updateUserHabit(String description, String category, double? amount) {
    final key = _extractHabitKey(description);
    if (key.isEmpty) return;

    final habits = _userHabits[key] ?? [];

    // 查找现有习惯
    final existingIndex = habits.indexWhere((h) => h.category == category);
    if (existingIndex >= 0) {
      final existing = habits[existingIndex];
      habits[existingIndex] = CategoryHabit(
        category: category,
        count: existing.count + 1,
        totalAmount: existing.totalAmount + (amount ?? 0),
        lastUsed: DateTime.now(),
      );
    } else {
      habits.add(CategoryHabit(
        category: category,
        count: 1,
        totalAmount: amount ?? 0,
        lastUsed: DateTime.now(),
      ));
    }

    _userHabits[key] = habits;
  }

  /// 提取习惯关键特征
  String _extractHabitKey(String description) {
    // 简化处理：使用前5个字符作为键
    if (description.length <= 5) return description;
    return description.substring(0, 5);
  }

  /// 获取用户习惯分类
  CategoryHabit? getUserHabit(String description) {
    final key = _extractHabitKey(description);
    final habits = _userHabits[key];
    if (habits == null || habits.isEmpty) return null;

    // 返回最常用的分类
    habits.sort((a, b) => b.count.compareTo(a.count));
    return habits.first;
  }

  /// 分类消费 - 使用本地+云端混合策略 + 语义理解 + 用户习惯
  Future<AiClassificationResult> classifyExpense({
    required String description,
    required UserSettings settings,
    bool forceCloud = false,
  }) async {
    // 第一层: 用户习惯匹配
    final userHabit = getUserHabit(description);
    if (userHabit != null && userHabit.count >= 2) {
      return AiClassificationResult(
        amount: null,
        category: userHabit.category,
        isLocal: true,
        confidence: 0.7,
        modelName: '用户习惯',
        candidates: [
          CategoryCandidate(
            category: userHabit.category,
            confidence: 0.7,
            reason: '根据您的使用习惯',
          ),
        ],
      );
    }

    // 第二层: 本地关键词匹配（免费，快速）
    final localResult = _localService.classifyWithConfidence(description);

    // 如果本地能明确判断分类，且用户没有设置强制使用云端
    if (localResult != null && localResult.confidence >= 0.6 && !forceCloud) {
      return AiClassificationResult(
        amount: localResult.amount,
        category: localResult.category,
        isLocal: true,
        confidence: localResult.confidence,
        modelName: '本地匹配',
        candidates: [
          CategoryCandidate(
            category: localResult.category,
            confidence: localResult.confidence,
            reason: '关键词匹配',
          ),
        ],
      );
    }

    // 第三层: 云端API + 语义理解
    if (settings.hasAnyAiKey) {
      try {
        return await _classifyWithCloud(description, settings);
      } catch (e) {
        debugPrint('Cloud classification failed: $e');
        // 云端失败，回退到本地结果
        if (localResult != null) {
          return AiClassificationResult(
            amount: localResult.amount,
            category: localResult.category,
            isLocal: true,
            confidence: localResult.confidence * 0.8,
            modelName: '本地匹配(云端失败)',
          );
        }
      }
    }

    // 第四层: 本地兜底
    return AiClassificationResult(
      amount: localResult?.amount,
      category: localResult?.category ?? '其他',
      isLocal: true,
      confidence: localResult?.confidence ?? 0.3,
      modelName: '本地匹配',
      candidates: [
        CategoryCandidate(
          category: localResult?.category ?? '其他',
          confidence: localResult?.confidence ?? 0.3,
          reason: '默认分类',
        ),
      ],
    );
  }

  /// 云端分类 + 语义理解 + 多语言支持 + 模糊匹配
  Future<AiClassificationResult> _classifyWithCloud(
    String description,
    UserSettings settings,
  ) async {
    final model = _selectAvailableModel(settings);
    final apiKey = _getApiKey(model, settings)!;
    final config = _models[model]!;

    // 增强的 prompt：支持语义理解和多语言
    final prompt = _buildSemanticPrompt(description);

    final body = {
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.3,
    };

    final requestBody = config.requestBuilder(body, apiKey);

    final response = await _httpClient.post(
      Uri.parse(config.endpoint),
      headers: config.headers(apiKey),
      body: jsonEncode(requestBody),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('AI服务响应超时，请检查网络'),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        // 验证响应结构
        if (data == null || data is! Map<String, dynamic>) {
          throw Exception('Invalid AI response format');
        }
        final content = config.responseParser(data, response.body);
        final result = _parseSemanticResponse(content, description);

        // 获取候选分类（模糊匹配）
        final candidates = await _getCategoryCandidates(description, settings);

        return AiClassificationResult(
          amount: result.amount,
          category: result.category,
          isLocal: false,
          confidence: result.confidence,
          modelName: config.name,
          candidates: candidates,
        );
      } catch (e) {
        debugPrint('Failed to parse AI response: $e');
        rethrow;
      }
    } else {
      throw Exception('${config.name} API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// 构建语义理解 prompt
  String _buildSemanticPrompt(String description) {
    return '''
你是一个智能消费分类助手。根据用户输入的消费描述，智能判断分类。

## 分类选项
餐饮、交通、购物、娱乐、医疗、教育、其他

## 语义理解示例
- "中午吃了碗牛肉面" → 餐饮（理解"吃"关联餐饮，"牛肉面"是食物）
- "打车去开会" → 交通（理解"打车"是交通出行）
- "买了件衣服" → 购物（理解"买"是购物行为）
- "看了场电影" → 娱乐（理解"看电影"是娱乐）
- "打车回家" → 交通（"回家"是出行场景）

## 多语言支持
支持识别：
- 中文：吃饭、打车、购物
- 英文：lunch, taxi, shopping, movie
- 日文：昼食、タクシー買い物

## 输出格式
只输出JSON，不要其他内容：
{"amount": 金额数字或null, "category": "分类名称", "confidence": 0.0-1.0}

## 用户输入
$description

请分析并输出JSON：
''';
  }

  /// 解析语义响应
  AiClassificationResult _parseSemanticResponse(String content, String description) {
    try {
      final jsonMatch = RegExp(r'\{.*\}').firstMatch(content);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!);
        final amount = json['amount'];
        final category = json['category'] as String;
        final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.9;

        return AiClassificationResult(
          amount: amount == 'unknown' || amount == null ? null : _parseAmount(amount),
          category: category,
          confidence: confidence,
        );
      }
    } catch (e) {
      debugPrint('Failed to parse semantic response: $e');
    }

    // 解析失败，回退到基础解析
    return _parseAiResponse(content);
  }

  /// 获取候选分类（模糊匹配）
  Future<List<CategoryCandidate>> _getCategoryCandidates(
    String description,
    UserSettings settings,
  ) async {
    try {
      final model = _selectAvailableModel(settings);
      final apiKey = _getApiKey(model, settings)!;
      final config = _models[model]!;

      final prompt = '''
用户输入：$description

分析可能的分类，最多返回3个候选。
分类选项：餐饮、交通、购物、娱乐、医疗、教育、其他

输出JSON数组格式：
[{"category": "分类", "confidence": 0.0-1.0, "reason": "原因"}]
''';

      final body = {
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.5,
      };

      final requestBody = config.requestBuilder(body, apiKey);

      final response = await _httpClient.post(
        Uri.parse(config.endpoint),
        headers: config.headers(apiKey),
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          // 验证响应结构
          if (data == null || data is! Map<String, dynamic>) {
            throw Exception('Invalid AI response format');
          }
          final content = config.responseParser(data, response.body);

          return _parseCandidates(content);
        } catch (e) {
          debugPrint('Failed to parse candidates: $e');
          return [];
        }
      }
    } catch (e) {
      debugPrint('Failed to get candidates: $e');
    }

    return [];
  }

  /// 解析候选分类
  List<CategoryCandidate> _parseCandidates(String content) {
    try {
      final jsonMatch = RegExp(r'\[.*\]').firstMatch(content);
      if (jsonMatch != null) {
        final list = jsonDecode(jsonMatch.group(0)!) as List;
        return list.map((item) => CategoryCandidate(
          category: item['category'] as String,
          confidence: (item['confidence'] as num).toDouble(),
          reason: item['reason'] as String? ?? '',
        )).toList();
      }
    } catch (e) {
      debugPrint('Failed to parse candidates: $e');
    }
    return [];
  }

  AiClassificationResult _parseAiResponse(String content) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{.*\}').firstMatch(content);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!);
        final amount = json['amount'];
        final category = json['category'] as String;

        return AiClassificationResult(
          amount: amount == 'unknown' ? null : _parseAmount(amount),
          category: category,
        );
      }
    } catch (e) {
      debugPrint('Failed to parse AI response: $e');
    }

    // Default fallback
    return AiClassificationResult(
      amount: null,
      category: '其他',
    );
  }

  double? _parseAmount(dynamic value) {
    if (value == null || value == 'unknown') return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  Future<String> analyzeExpenses({
    required List<Map<String, dynamic>> expenses,
    required UserSettings settings,
  }) async {
    final model = _selectAvailableModel(settings);
    final apiKey = _getApiKey(model, settings)!;
    final config = _models[model]!;

    final prompt = '''
分析以下消费记录，给出简单统计和建议：

消费记录：
${expenses.map((e) => '- ${e['category']}: ${e['amount']}元 - ${e['description']}').join('\n')}

请给出：
1. 本月总消费
2. 各分类占比
3. 消费建议（1-2句话）

请用中文回答。
''';

    final body = {
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.7,
    };

    final requestBody = config.requestBuilder(body, apiKey);

    try {
      final response = await _httpClient.post(
        Uri.parse(config.endpoint),
        headers: config.headers(apiKey),
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('AI服务响应超时，请检查网络'),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          // 验证响应结构
          if (data == null || data is! Map<String, dynamic>) {
            throw Exception('Invalid AI response format');
          }
          return config.responseParser(data, response.body);
        } catch (e) {
          throw Exception('Failed to parse AI response: $e');
        }
      } else {
        throw Exception('${config.name} API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to analyze with ${config.name}: $e');
    }
  }

  // 获取当前使用的模型名称
  String getCurrentModelName(UserSettings settings) {
    final model = _selectAvailableModel(settings);
    return _models[model]!.name;
  }

  // 获取所有可用的模型列表
  List<String> getAvailableModels(UserSettings settings) {
    final available = <String>[];
    if (settings.hasClaudeKey) available.add(_models[AiModelType.claude]!.name);
    if (settings.hasOpenAiKey) available.add(_models[AiModelType.openai]!.name);
    if (settings.hasZhipuKey) available.add(_models[AiModelType.zhipu]!.name);
    if (settings.hasQwenKey) available.add(_models[AiModelType.qwen]!.name);
    if (settings.hasHunyuanKey) available.add(_models[AiModelType.hunyuan]!.name);
    // ernie 和 spark 已暂时移除
    return available;
  }

  // 释放资源
  void dispose() {
    _httpClient.close();
  }
}
