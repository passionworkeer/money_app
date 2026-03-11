import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/data/models/user_settings.dart';

void main() {
  group('UserSettings Model Tests', () {
    test('UserSettings can be created with default values', () {
      const settings = UserSettings();

      expect(settings.openaiApiKey, isNull);
      expect(settings.claudeApiKey, isNull);
      expect(settings.ernieApiKey, isNull);
      expect(settings.qwenApiKey, isNull);
      expect(settings.useCloudSync, false);
      expect(settings.defaultCurrency, 'CNY');
    });

    test('UserSettings copyWith creates new instance', () {
      const settings = UserSettings(
        openaiApiKey: 'sk-test',
        useCloudSync: false,
      );

      final updated = settings.copyWith(
        openaiApiKey: 'sk-new',
        useCloudSync: true,
        qwenApiKey: 'sk-qwen',
      );

      expect(updated.openaiApiKey, 'sk-new');
      expect(updated.useCloudSync, true);
      expect(updated.qwenApiKey, 'sk-qwen');
      expect(settings.openaiApiKey, 'sk-test'); // Original unchanged
      expect(settings.useCloudSync, false);
      expect(settings.qwenApiKey, isNull);
    });

    test('UserSettings toMap and fromMap works correctly', () {
      const settings = UserSettings(
        openaiApiKey: 'sk-test',
        claudeApiKey: 'sk-ant-test',
        ernieApiKey: 'ernie-key',
        qwenApiKey: 'qwen-key',
        sparkApiKey: 'spark-key',
        hunyuanApiKey: 'hunyuan-key',
        zhipuApiKey: 'zhipu-key',
        useCloudSync: true,
        defaultCurrency: 'USD',
      );

      final map = settings.toMap();
      final restored = UserSettings.fromMap(map);

      expect(restored.openaiApiKey, settings.openaiApiKey);
      expect(restored.claudeApiKey, settings.claudeApiKey);
      expect(restored.ernieApiKey, settings.ernieApiKey);
      expect(restored.qwenApiKey, settings.qwenApiKey);
      expect(restored.sparkApiKey, settings.sparkApiKey);
      expect(restored.hunyuanApiKey, settings.hunyuanApiKey);
      expect(restored.zhipuApiKey, settings.zhipuApiKey);
      expect(restored.useCloudSync, settings.useCloudSync);
      expect(restored.defaultCurrency, settings.defaultCurrency);
    });

    test('UserSettings hasAnyAiKey returns correct value', () {
      const settings1 = UserSettings(openaiApiKey: 'sk-test');
      expect(settings1.hasOpenAiKey, true);
      expect(settings1.hasAnyAiKey, true);

      const settings2 = UserSettings(claudeApiKey: 'sk-ant-test');
      expect(settings2.hasClaudeKey, true);
      expect(settings2.hasAnyAiKey, true);

      const settings3 = UserSettings(ernieApiKey: 'ernie-test');
      expect(settings3.hasErnieKey, true);
      expect(settings3.hasAnyAiKey, true);

      const settings4 = UserSettings(qwenApiKey: 'qwen-test');
      expect(settings4.hasQwenKey, true);
      expect(settings4.hasAnyAiKey, true);

      const settings5 = UserSettings(sparkApiKey: 'spark-test');
      expect(settings5.hasSparkKey, true);
      expect(settings5.hasAnyAiKey, true);

      const settings6 = UserSettings(hunyuanApiKey: 'hunyuan-test');
      expect(settings6.hasHunyuanKey, true);
      expect(settings6.hasAnyAiKey, true);

      const settings7 = UserSettings(zhipuApiKey: 'zhipu-test');
      expect(settings7.hasZhipuKey, true);
      expect(settings7.hasAnyAiKey, true);

      const settings8 = UserSettings();
      expect(settings8.hasOpenAiKey, false);
      expect(settings8.hasClaudeKey, false);
      expect(settings8.hasErnieKey, false);
      expect(settings8.hasQwenKey, false);
      expect(settings8.hasSparkKey, false);
      expect(settings8.hasHunyuanKey, false);
      expect(settings8.hasZhipuKey, false);
      expect(settings8.hasAnyAiKey, false);

      const settings9 = UserSettings(openaiApiKey: '');
      expect(settings9.hasOpenAiKey, false);
    });

    test('UserSettings fromMap handles null values', () {
      final settings = UserSettings.fromMap({});

      expect(settings.openaiApiKey, isNull);
      expect(settings.claudeApiKey, isNull);
      expect(settings.ernieApiKey, isNull);
      expect(settings.qwenApiKey, isNull);
      expect(settings.useCloudSync, false);
      expect(settings.defaultCurrency, 'CNY');
    });

    test('UserSettings supports preferredModel', () {
      const settings = UserSettings(
        preferredModel: 'claude',
        openaiApiKey: 'sk-test',
      );

      expect(settings.preferredModel, 'claude');
      expect(settings.hasOpenAiKey, true);
    });
  });
}
