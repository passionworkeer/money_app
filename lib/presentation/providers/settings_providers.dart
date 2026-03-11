import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/models/user_settings.dart';

// Settings Provider
final settingsProvider = FutureProvider<UserSettings>((ref) async {
  return await DatabaseHelper.instance.getSettings();
});

// Settings Notifier for updates
class SettingsNotifier extends StateNotifier<AsyncValue<UserSettings>> {
  SettingsNotifier() : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await DatabaseHelper.instance.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(UserSettings settings) async {
    try {
      await DatabaseHelper.instance.updateSettings(settings);
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Generalized API Key update method
  Future<void> updateApiKey(String field, String? value) async {
    final current = state.valueOrNull ?? const UserSettings();
    final updated = _updateField(current, field, value);
    await updateSettings(updated);
  }

  UserSettings _updateField(UserSettings settings, String field, String? value) {
    switch (field) {
      case 'openaiApiKey':
        return settings.copyWith(openaiApiKey: value);
      case 'claudeApiKey':
        return settings.copyWith(claudeApiKey: value);
      case 'ernieApiKey':
        return settings.copyWith(ernieApiKey: value);
      case 'qwenApiKey':
        return settings.copyWith(qwenApiKey: value);
      case 'sparkApiKey':
        return settings.copyWith(sparkApiKey: value);
      case 'hunyuanApiKey':
        return settings.copyWith(hunyuanApiKey: value);
      case 'zhipuApiKey':
        return settings.copyWith(zhipuApiKey: value);
      case 'locale':
        return settings.copyWith(locale: value);
      case 'themeMode':
        final mode = int.tryParse(value ?? '0') ?? 0;
        return settings.copyWith(themeMode: ThemeMode.values[mode]);
      default:
        return settings;
    }
  }

  Future<void> updateOpenAiKey(String? apiKey) async {
    final current = state.valueOrNull ?? const UserSettings();
    await updateSettings(current.copyWith(openaiApiKey: apiKey));
  }

  Future<void> updateClaudeKey(String? apiKey) async {
    final current = state.valueOrNull ?? const UserSettings();
    await updateSettings(current.copyWith(claudeApiKey: apiKey));
  }

  Future<void> updateErnieKey(String? apiKey) async {
    final current = state.valueOrNull ?? const UserSettings();
    await updateSettings(current.copyWith(ernieApiKey: apiKey));
  }

  Future<void> updateQwenKey(String? apiKey) async {
    final current = state.valueOrNull ?? const UserSettings();
    await updateSettings(current.copyWith(qwenApiKey: apiKey));
  }

  Future<void> updateSparkKey(String? apiKey) async {
    final current = state.valueOrNull ?? const UserSettings();
    await updateSettings(current.copyWith(sparkApiKey: apiKey));
  }

  Future<void> updateHunyuanKey(String? apiKey) async {
    final current = state.valueOrNull ?? const UserSettings();
    await updateSettings(current.copyWith(hunyuanApiKey: apiKey));
  }

  Future<void> updateZhipuKey(String? apiKey) async {
    final current = state.valueOrNull ?? const UserSettings();
    await updateSettings(current.copyWith(zhipuApiKey: apiKey));
  }

  Future<void> updatePreferredModel(String? model) async {
    final current = state.valueOrNull ?? const UserSettings();
    await updateSettings(current.copyWith(preferredModel: model));
  }

  Future<void> toggleCloudSync(bool enabled) async {
    final current = state.valueOrNull ?? const UserSettings();
    await updateSettings(current.copyWith(useCloudSync: enabled));
  }

  Future<void> updateCurrency(String currency) async {
    final current = state.valueOrNull ?? const UserSettings();
    await updateSettings(current.copyWith(defaultCurrency: currency));
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    final current = state.valueOrNull ?? const UserSettings();
    await updateSettings(current.copyWith(themeMode: themeMode));
  }

  Future<void> updateLocale(String locale) async {
    final current = state.valueOrNull ?? const UserSettings();
    await updateSettings(current.copyWith(locale: locale));
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<UserSettings>>((ref) {
  return SettingsNotifier();
});
