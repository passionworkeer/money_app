import 'package:flutter/material.dart';
import '../datasources/local/database_helper.dart';

class UserSettings {
  // OpenAI
  final String? openaiApiKey;

  // Claude
  final String? claudeApiKey;

  // 百度文心一言
  final String? ernieApiKey;

  // 阿里通义千问
  final String? qwenApiKey;

  // 讯飞星火
  final String? sparkApiKey;

  // 腾讯混元
  final String? hunyuanApiKey;

  // 智谱AI (ChatGLM)
  final String? zhipuApiKey;

  // 当前使用的模型（可选，默认智能选择）
  final String? preferredModel;

  // 其他设置
  final bool useCloudSync;
  final String defaultCurrency;
  final ThemeMode themeMode;
  final String locale; // 'zh' 或 'en'

  const UserSettings({
    this.openaiApiKey,
    this.claudeApiKey,
    this.ernieApiKey,
    this.qwenApiKey,
    this.sparkApiKey,
    this.hunyuanApiKey,
    this.zhipuApiKey,
    this.preferredModel,
    this.useCloudSync = false,
    this.defaultCurrency = 'CNY',
    this.themeMode = ThemeMode.system,
    this.locale = 'zh',
  });

  UserSettings copyWith({
    String? openaiApiKey,
    String? claudeApiKey,
    String? ernieApiKey,
    String? qwenApiKey,
    String? sparkApiKey,
    String? hunyuanApiKey,
    String? zhipuApiKey,
    String? preferredModel,
    bool? useCloudSync,
    String? defaultCurrency,
    ThemeMode? themeMode,
    String? locale,
  }) {
    return UserSettings(
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      claudeApiKey: claudeApiKey ?? this.claudeApiKey,
      ernieApiKey: ernieApiKey ?? this.ernieApiKey,
      qwenApiKey: qwenApiKey ?? this.qwenApiKey,
      sparkApiKey: sparkApiKey ?? this.sparkApiKey,
      hunyuanApiKey: hunyuanApiKey ?? this.hunyuanApiKey,
      zhipuApiKey: zhipuApiKey ?? this.zhipuApiKey,
      preferredModel: preferredModel ?? this.preferredModel,
      useCloudSync: useCloudSync ?? this.useCloudSync,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'openaiApiKey': ApiKeyHelper.encode(openaiApiKey),
      'claudeApiKey': ApiKeyHelper.encode(claudeApiKey),
      'ernieApiKey': ApiKeyHelper.encode(ernieApiKey),
      'qwenApiKey': ApiKeyHelper.encode(qwenApiKey),
      'sparkApiKey': ApiKeyHelper.encode(sparkApiKey),
      'hunyuanApiKey': ApiKeyHelper.encode(hunyuanApiKey),
      'zhipuApiKey': ApiKeyHelper.encode(zhipuApiKey),
      'preferredModel': preferredModel,
      'useCloudSync': useCloudSync ? 1 : 0,
      'defaultCurrency': defaultCurrency,
      'themeMode': themeMode.index,
      'locale': locale,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      openaiApiKey: ApiKeyHelper.decode(map['openaiApiKey'] as String?),
      claudeApiKey: ApiKeyHelper.decode(map['claudeApiKey'] as String?),
      ernieApiKey: ApiKeyHelper.decode(map['ernieApiKey'] as String?),
      qwenApiKey: ApiKeyHelper.decode(map['qwenApiKey'] as String?),
      sparkApiKey: ApiKeyHelper.decode(map['sparkApiKey'] as String?),
      hunyuanApiKey: ApiKeyHelper.decode(map['hunyuanApiKey'] as String?),
      zhipuApiKey: ApiKeyHelper.decode(map['zhipuApiKey'] as String?),
      preferredModel: map['preferredModel'] as String?,
      useCloudSync: (map['useCloudSync'] as int?) == 1,
      defaultCurrency: map['defaultCurrency'] as String? ?? 'CNY',
      themeMode: ThemeMode.values[map['themeMode'] as int? ?? 0],
      locale: map['locale'] as String? ?? 'zh',
    );
  }

  // 检查各个 API Key 是否存在
  bool get hasOpenAiKey => openaiApiKey != null && openaiApiKey!.isNotEmpty;
  bool get hasClaudeKey => claudeApiKey != null && claudeApiKey!.isNotEmpty;
  bool get hasErnieKey => ernieApiKey != null && ernieApiKey!.isNotEmpty;
  bool get hasQwenKey => qwenApiKey != null && qwenApiKey!.isNotEmpty;
  bool get hasSparkKey => sparkApiKey != null && sparkApiKey!.isNotEmpty;
  bool get hasHunyuanKey => hunyuanApiKey != null && hunyuanApiKey!.isNotEmpty;
  bool get hasZhipuKey => zhipuApiKey != null && zhipuApiKey!.isNotEmpty;

  // 是否有任何 AI API Key
  bool get hasAnyAiKey =>
      hasOpenAiKey ||
      hasClaudeKey ||
      hasErnieKey ||
      hasQwenKey ||
      hasSparkKey ||
      hasHunyuanKey ||
      hasZhipuKey;
}
