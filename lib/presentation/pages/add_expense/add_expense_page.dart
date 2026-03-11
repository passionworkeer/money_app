import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/categories.dart';
import '../../../core/services/speech_service.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/local_ai_service.dart';
import '../../../core/services/automation_service.dart';
import '../../../data/models/expense_model.dart';
import '../../providers/expense_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/category_icon.dart';

class AddExpensePage extends ConsumerStatefulWidget {
  final String? expenseId;

  const AddExpensePage({super.key, this.expenseId});

  @override
  ConsumerState<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends ConsumerState<AddExpensePage>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _speechService = SpeechService();
  final _aiService = AiService();

  String _selectedCategory = ExpenseCategory.other.value;
  DateTime _selectedDate = DateTime.now();
  bool _isListening = false;
  bool _isAnalyzing = false;
  bool _isOfflineMode = false;
  String _recognizedText = '';
  String? _errorMessage;
  String? _classificationSource; // 分类来源

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.expenseId != null) {
      _loadExpense();
    }
  }

  Future<void> _loadExpense() async {
    final expenses = ref.read(expensesProvider).valueOrNull ?? [];
    final expense = expenses.where((e) => e.id == widget.expenseId).firstOrNull;
    if (expense != null) {
      _amountController.text = expense.amount.toString();
      _descriptionController.text = expense.description;
      _selectedCategory = expense.category;
      _selectedDate = expense.date;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    try {
      final initialized = await _speechService.initialize();
      if (!initialized) {
        _showError('语音识别不可用，请检查麦克风权限');
        return;
      }

      final status = await _speechService.getStatus();
      setState(() {
        _isListening = true;
        _recognizedText = '';
        _isOfflineMode = status.isOfflineAvailable;
        _errorMessage = null;
      });

      await _speechService.listen(
        localeId: 'zh_CN',
        onResult: (text, confidence) {
          setState(() {
            _recognizedText = text;
            _descriptionController.text = text;
          });
          _analyzeWithAI(text);
        },
      );
    } catch (e) {
      setState(() {
        _isListening = false;
        _errorMessage = e.toString();
      });
      // 优化错误提示
      String message;
      if (e.toString().contains('permission')) {
        message = '语音识别失败，请检查麦克风权限';
      } else if (e.toString().contains('network')) {
        message = '网络连接失败，请检查网络';
      } else {
        message = '语音识别失败，请重试';
      }
      _showError(message);
    }
  }

  Future<void> _stopListening() async {
    await _speechService.stop();
    setState(() => _isListening = false);
  }

  Future<void> _analyzeWithAI(String text) async {
    final settings = ref.read(settingsNotifierProvider).valueOrNull;
    if (settings == null || !settings.hasAnyAiKey) {
      // 没有云端API key时，也尝试本地分类
      _tryLocalClassification(text);
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final result = await _aiService.classifyExpense(
        description: text,
        settings: settings,
      );

      setState(() {
        if (result.amount != null) {
          _amountController.text = result.amount.toString();
        }
        _selectedCategory = result.category;
        // 保存分类来源
        _classificationSource = result.modelName;
      });
    } catch (e) {
      debugPrint('AI analysis error: $e');
      // 云端失败，尝试本地分类
      _tryLocalClassification(text);
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  // 本地分类
  Future<void> _tryLocalClassification(String text) async {
    final localService = LocalAiService();
    final result = localService.classifyWithConfidence(text);

    if (result != null) {
      setState(() {
        if (result.amount != null) {
          _amountController.text = result.amount.toString();
        }
        _selectedCategory = result.category;
        _classificationSource = '本地匹配';
      });
    } else {
      // 尝试自动化规则分类
      await _tryAutomationClassification(text);
    }
  }

  // 自动化规则分类
  Future<void> _tryAutomationClassification(String text) async {
    final automationService = AutomationService();
    final suggestedCategory = await automationService.suggestCategory(text);

    if (suggestedCategory != null) {
      setState(() {
        _selectedCategory = suggestedCategory;
        _classificationSource = '自动规则';
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('请输入有效金额');
      return;
    }

    final expense = Expense(
      id: widget.expenseId,
      amount: amount,
      description: _descriptionController.text,
      category: _selectedCategory,
      date: _selectedDate,
    );

    if (widget.expenseId != null) {
      await ref.read(expensesProvider.notifier).updateExpense(expense);
    } else {
      await ref.read(expensesProvider.notifier).addExpense(expense);
    }

    if (mounted) {
      context.pop();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVoiceInput(),
                        const SizedBox(height: 24),
                        _buildAmountInput(),
                        const SizedBox(height: 20),
                        _buildDescriptionInput(),
                        const SizedBox(height: 20),
                        _buildCategorySelector(),
                        const SizedBox(height: 20),
                        _buildDateSelector(),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                        if (widget.expenseId != null) _buildDeleteButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          const Expanded(
            child: Text(
              '记账',
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

  Widget _buildVoiceInput() {
    return Center(
      child: Column(
        children: [
          // Animated mic button
          ScaleTransition(
            scale: _isListening ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isListening
                        ? [Colors.red.shade400, Colors.red.shade600]
                        : [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.red : AppColors.primary)
                          .withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Status text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _isListening
                  ? '正在聆听...'
                  : _recognizedText.isNotEmpty
                      ? _recognizedText
                      : '点击说话',
              key: ValueKey(_recognizedText.isEmpty ? 'hint' : _recognizedText),
              style: TextStyle(
                fontSize: 16,
                color: _isListening ? Colors.red.shade400 : Colors.grey.shade600,
                fontWeight: _isListening ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Status indicators
          if (_isOfflineMode || _isAnalyzing || _errorMessage != null) ...[
            const SizedBox(height: 12),
            _buildStatusIndicators(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (_isOfflineMode)
          _buildStatusChip(Icons.wifi_off, '离线模式', Colors.green),
        if (_isAnalyzing)
          _buildStatusChip(Icons.auto_awesome, 'AI分析中...', AppColors.primary),
        if (_errorMessage != null)
          _buildStatusChip(Icons.info_outline, '需要联网', Colors.orange),
        if (_classificationSource != null)
          _buildStatusChip(
            _classificationSource!.contains('本地')
                ? Icons.phonelink_lock
                : Icons.cloud,
            _classificationSource!,
            _classificationSource!.contains('本地') ? Colors.teal : Colors.blue,
          ),
      ],
    );
  }

  Widget _buildStatusChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
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
      child: TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '0.00',
          hintStyle: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade300,
          ),
          prefixText: '¥ ',
          prefixStyle: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        ),
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return Container(
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
      child: TextField(
        controller: _descriptionController,
        decoration: InputDecoration(
          hintText: '添加备注（可选）',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          prefixIcon: Icon(Icons.edit_note_rounded, color: Colors.grey.shade400),
        ),
        maxLines: 2,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择分类',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ExpenseCategory.values.map((category) {
            final isSelected = _selectedCategory == category.value;
            final color = AppColors.categoryColors[category.value] ?? Colors.grey;

            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = category.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CategoryIconHelper.getIcon(category),
                      size: 20,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '消费日期',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _saveExpense,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: Text(
            widget.expenseId != null ? '更新记录' : '保存记录',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          await ref.read(expensesProvider.notifier).deleteExpense(widget.expenseId!);
          if (mounted) {
            context.pop();
          }
        },
        child: const Text(
          '删除记录',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
