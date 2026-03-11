import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/user_settings.dart';
import '../../../data/datasources/local/database_helper.dart';
import '../../providers/budget_providers.dart';
import '../../providers/expense_providers.dart';
import '../../providers/settings_providers.dart';
import 'sync_settings_page.dart';

// Theme Button Widget
class _ThemeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data Button Widget
class _DataButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DataButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.shade50 : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive ? Colors.red.shade200 : color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDestructive ? Colors.red : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Language Button Widget
class _LanguageButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _openaiController = TextEditingController();
  final _claudeController = TextEditingController();
  final _ernieController = TextEditingController();
  final _qwenController = TextEditingController();
  final _sparkController = TextEditingController();
  final _hunyuanController = TextEditingController();
  final _zhipuController = TextEditingController();
  final _budgetController = TextEditingController();

  bool _obscureOpenAI = true;
  bool _obscureClaude = true;
  bool _obscureErnie = true;
  bool _obscureQwen = true;
  bool _obscureSpark = true;
  bool _obscureHunyuan = true;
  bool _obscureZhipu = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBudget();
  }

  void _loadSettings() {
    final settings = ref.read(settingsNotifierProvider).valueOrNull;
    if (settings != null) {
      _openaiController.text = settings.openaiApiKey ?? '';
      _claudeController.text = settings.claudeApiKey ?? '';
      _ernieController.text = settings.ernieApiKey ?? '';
      _qwenController.text = settings.qwenApiKey ?? '';
      _sparkController.text = settings.sparkApiKey ?? '';
      _hunyuanController.text = settings.hunyuanApiKey ?? '';
      _zhipuController.text = settings.zhipuApiKey ?? '';
    }
  }

  void _loadBudget() {
    final budget = ref.read(currentMonthBudgetProvider).valueOrNull;
    if (budget != null) {
      _budgetController.text = budget.amount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _openaiController.dispose();
    _claudeController.dispose();
    _ernieController.dispose();
    _qwenController.dispose();
    _sparkController.dispose();
    _hunyuanController.dispose();
    _zhipuController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final notifier = ref.read(settingsNotifierProvider.notifier);

    await notifier.updateOpenAiKey(
      _openaiController.text.isEmpty ? null : _openaiController.text,
    );
    await notifier.updateClaudeKey(
      _claudeController.text.isEmpty ? null : _claudeController.text,
    );
    await notifier.updateErnieKey(
      _ernieController.text.isEmpty ? null : _ernieController.text,
    );
    await notifier.updateQwenKey(
      _qwenController.text.isEmpty ? null : _qwenController.text,
    );
    await notifier.updateSparkKey(
      _sparkController.text.isEmpty ? null : _sparkController.text,
    );
    await notifier.updateHunyuanKey(
      _hunyuanController.text.isEmpty ? null : _hunyuanController.text,
    );
    await notifier.updateZhipuKey(
      _zhipuController.text.isEmpty ? null : _zhipuController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功 ✓')),
      );
    }
  }

  Future<void> _saveBudget() async {
    final amountText = _budgetController.text.trim();
    if (amountText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入预算金额')),
        );
      }
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入有效的预算金额')),
        );
      }
      return;
    }

    final now = DateTime.now();
    await ref.read(budgetNotifierProvider.notifier).setBudget(amount, now.year, now.month);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('预算设置成功 ✓')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final currentSettings = settings.valueOrNull;
    final currentBudget = ref.watch(currentMonthBudgetProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: settings.when(
                    data: (data) => ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildApiSection(),
                        const SizedBox(height: 20),
                        _buildThemeSection(currentSettings),
                        const SizedBox(height: 20),
                        _buildLanguageSection(currentSettings),
                        const SizedBox(height: 20),
                        _buildBudgetSection(currentBudget),
                        const SizedBox(height: 20),
                        _buildCloudSyncSection(currentSettings),
                        const SizedBox(height: 20),
                        _buildAutomationSection(),
                        const SizedBox(height: 20),
                        _buildDataManagementSection(),
                        const SizedBox(height: 20),
                        _buildAboutSection(),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSection(UserSettings? currentSettings) {
    final currentLocale = currentSettings?.locale ?? 'zh';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.language_rounded, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '语言设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _LanguageButton(
                  label: '中文',
                  isSelected: currentLocale == 'zh',
                  onTap: () => _changeLocale('zh'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LanguageButton(
                  label: 'English',
                  isSelected: currentLocale == 'en',
                  onTap: () => _changeLocale('en'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _changeLocale(String locale) async {
    await ref.read(settingsNotifierProvider.notifier).updateLocale(locale);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('语言已更新')),
      );
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const Expanded(
            child: Text(
              '设置',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildApiSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.key_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'API 设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // OpenAI
          _buildApiInput(
            label: 'OpenAI API Key',
            hint: 'sk-...',
            controller: _openaiController,
            obscure: _obscureOpenAI,
            onToggle: () => setState(() => _obscureOpenAI = !_obscureOpenAI),
          ),
          const SizedBox(height: 16),
          // Claude
          _buildApiInput(
            label: 'Claude API Key',
            hint: 'sk-ant-...',
            controller: _claudeController,
            obscure: _obscureClaude,
            onToggle: () => setState(() => _obscureClaude = !_obscureClaude),
          ),
          const SizedBox(height: 16),
          // 智谱AI
          _buildApiInput(
            label: '智谱AI API Key',
            hint: 'glm-...',
            controller: _zhipuController,
            obscure: _obscureZhipu,
            onToggle: () => setState(() => _obscureZhipu = !_obscureZhipu),
          ),
          const SizedBox(height: 16),
          // 阿里通义千问
          _buildApiInput(
            label: '阿里通义千问 API Key',
            hint: 'sk-...',
            controller: _qwenController,
            obscure: _obscureQwen,
            onToggle: () => setState(() => _obscureQwen = !_obscureQwen),
          ),
          const SizedBox(height: 16),
          // 百度文心一言
          _buildApiInput(
            label: '百度文心一言 API Key',
            hint: 'API Key',
            controller: _ernieController,
            obscure: _obscureErnie,
            onToggle: () => setState(() => _obscureErnie = !_obscureErnie),
          ),
          const SizedBox(height: 16),
          // 腾讯混元
          _buildApiInput(
            label: '腾讯混元 API Key',
            hint: 'API Key',
            controller: _hunyuanController,
            obscure: _obscureHunyuan,
            onToggle: () => setState(() => _obscureHunyuan = !_obscureHunyuan),
          ),
          const SizedBox(height: 16),
          // 讯飞星火
          _buildApiInput(
            label: '讯飞星火 API Key',
            hint: 'API Key',
            controller: _sparkController,
            obscure: _obscureSpark,
            onToggle: () => setState(() => _obscureSpark = !_obscureSpark),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  '保存设置',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection(AsyncValue<Budget?> currentBudget) {
    final now = DateTime.now();
    final budget = currentBudget.valueOrNull;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF43A047), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '预算设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Current Budget Display
          if (budget != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF43A047), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '本月预算: ¥${budget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF43A047),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Budget Input
          Text(
            '设置${now.year}年${now.month}月预算',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '请输入预算金额',
              hintStyle: TextStyle(color: Colors.grey.shade300),
              prefixText: '¥ ',
              prefixStyle: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
              suffixText: '元',
              suffixStyle: TextStyle(color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _saveBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  budget != null ? '更新预算' : '设置预算',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade300),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: Colors.grey.shade400,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCloudSyncSection(currentSettings) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SyncSettingsPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cloud_rounded, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '云同步设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationSection() {
    return GestureDetector(
      onTap: () {
        context.push('/automation');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '自动化设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(currentSettings) {
    final currentThemeMode = currentSettings?.themeMode ?? ThemeMode.system;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.palette_rounded, color: Colors.indigo, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '主题设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ThemeButton(
                  icon: Icons.light_mode_rounded,
                  label: '浅色',
                  isSelected: currentThemeMode == ThemeMode.light,
                  color: Colors.orange,
                  onTap: () => _changeTheme(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThemeButton(
                  icon: Icons.dark_mode_rounded,
                  label: '深色',
                  isSelected: currentThemeMode == ThemeMode.dark,
                  color: Colors.indigo,
                  onTap: () => _changeTheme(ThemeMode.dark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThemeButton(
                  icon: Icons.settings_suggest_rounded,
                  label: '跟随系统',
                  isSelected: currentThemeMode == ThemeMode.system,
                  color: Colors.green,
                  onTap: () => _changeTheme(ThemeMode.system),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _changeTheme(ThemeMode themeMode) async {
    await ref.read(settingsNotifierProvider.notifier).updateThemeMode(themeMode);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('主题已更新')),
      );
    }
  }

  Widget _buildDataManagementSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storage_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '数据管理',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _DataButton(
                  icon: Icons.upload_rounded,
                  label: '导出数据',
                  color: Colors.green,
                  onTap: _exportData,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DataButton(
                  icon: Icons.download_rounded,
                  label: '导入数据',
                  color: Colors.blue,
                  onTap: _importData,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _DataButton(
              icon: Icons.delete_forever_rounded,
              label: '清空所有数据',
              color: Colors.red,
              onTap: _showClearDataDialog,
              isDestructive: true,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final data = await DatabaseHelper.instance.exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'ai_expense_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'AI记账本 - 数据备份',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据导出成功')),
        );
      }
    } catch (e) {
      // 生产环境不泄露具体错误
      debugPrint('Export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请重试')),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Show confirmation dialog
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认导入'),
          content: const Text('导入数据将覆盖现有数据，是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认导入'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await DatabaseHelper.instance.importData(data);

        // Refresh all providers
        ref.invalidate(allExpensesProvider);
        ref.invalidate(settingsNotifierProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('数据导入成功')),
          );
        }
      }
    } catch (e) {
      // 生产环境不泄露具体错误
      debugPrint('Import failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请重试')),
        );
      }
    }
  }

  Future<void> _showClearDataDialog() async {
    // 第一个对话框：确认清空
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('此操作将删除所有数据，不可恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );

    // 用户取消
    if (firstConfirm != true) return;

    // 第二个对话框：输入确认
    if (!mounted) return;
    final textConfirm = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('输入确认'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '请输入"确认清空"',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('确认清空'),
            ),
          ],
        );
      },
    );

    if (textConfirm == '确认清空') {
      try {
        await DatabaseHelper.instance.clearAllData();

        // Refresh all providers
        ref.invalidate(allExpensesProvider);
        ref.invalidate(currentMonthBudgetProvider);
        ref.invalidate(settingsNotifierProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('数据已清空')),
          );
        }
      } catch (e) {
        // 生产环境不泄露具体错误
        debugPrint('Clear data failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('操作失败，请重试')),
          );
        }
      }
    } else if (textConfirm != '' && textConfirm != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('输入不匹配')),
        );
      }
    }
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_rounded, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '关于',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.mic, color: Colors.white),
            ),
            title: const Text(
              AppStrings.appName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('AI智能语音记账'),
            trailing: Text(
              'v${AppStrings.appVersion}',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
          const Divider(),
          _buildInfoRow(Icons.mic, '语音记账', '点击麦克风语音输入'),
          _buildInfoRow(Icons.auto_awesome, 'AI分类', '自动识别消费类型'),
          _buildInfoRow(Icons.pie_chart, '消费统计', '查看月度消费报表'),
          _buildInfoRow(Icons.download, '数据导出', '支持CSV格式导出'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
