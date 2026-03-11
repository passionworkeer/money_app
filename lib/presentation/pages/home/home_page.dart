import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/user_settings.dart';
import '../../providers/budget_providers.dart';
import '../../providers/expense_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/expense_card.dart';
import '../../widgets/empty_state.dart';
import '../../../core/services/ai_analysis_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final AIAnalysisService _analysisService = AIAnalysisService();
  String? _aiReport;
  bool _isLoadingReport = false;

  @override
  void dispose() {
    _analysisService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayTotal = ref.watch(todayTotalProvider);
    final monthTotal = ref.watch(monthTotalProvider);
    final recentExpenses = ref.watch(allExpensesProvider);
    final currentBudget = ref.watch(currentMonthBudgetProvider);
    final budgetProgress = ref.watch(budgetProgressProvider);
    final budgetStatus = ref.watch(budgetStatusProvider);
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3),
              Color(0xFFE3F2FD),
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(todayTotalProvider);
                      ref.invalidate(monthTotalProvider);
                      ref.invalidate(allExpensesProvider);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          // Summary Cards
                          _buildSummaryCards(todayTotal, monthTotal),
                          const SizedBox(height: 24),
                          // Budget Card
                          _buildBudgetCard(currentBudget, budgetProgress, budgetStatus, monthTotal.valueOrNull ?? 0),
                          const SizedBox(height: 24),
                          // AI Analysis Card
                          _buildAIAnalysisCard(settings.valueOrNull),
                          const SizedBox(height: 24),
                          // Recent Records
                          _buildRecentSection(context, ref, recentExpenses),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '你好 👋',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => context.push('/settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    AsyncValue<double> todayTotal,
    AsyncValue<double> monthTotal,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: AppStrings.todayTotal,
              total: todayTotal.valueOrNull ?? 0,
              icon: Icons.today,
              gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryCard(
              label: AppStrings.monthTotal,
              total: monthTotal.valueOrNull ?? 0,
              icon: Icons.calendar_month,
              gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
    AsyncValue<Budget?> currentBudget,
    AsyncValue<double> budgetProgress,
    BudgetStatus budgetStatus,
    double monthTotal,
  ) {
    final budget = currentBudget.valueOrNull;
    final progress = budgetProgress.valueOrNull ?? 0.0;
    final status = budgetStatus;

    // If no budget is set, don't show the card
    if (budget == null) {
      return const SizedBox.shrink();
    }

    final budgetAmount = budget.amount;
    final spent = monthTotal;
    final remaining = budgetAmount - spent;

    // Determine colors based on status
    Color progressColor;
    Color statusColor;
    String statusText;
    List<Color> gradient;

    switch (status) {
      case BudgetStatus.healthy:
        progressColor = const Color(0xFF43A047);
        statusColor = const Color(0xFF43A047);
        statusText = '预算健康';
        gradient = const [Color(0xFF43A047), Color(0xFF66BB6A)];
        break;
      case BudgetStatus.warning:
        progressColor = const Color(0xFFFF9800);
        statusColor = const Color(0xFFFF9800);
        statusText = '接近预算';
        gradient = const [Color(0xFFFF9800), Color(0xFFFFB74D)];
        break;
      case BudgetStatus.exceeded:
        progressColor = const Color(0xFFE53935);
        statusColor = const Color(0xFFE53935);
        statusText = '已超支';
        gradient = const [Color(0xFFE53935), Color(0xFFEF5350)];
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Progress
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Budget Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '本月预算',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¥${spent.toStringAsFixed(2)} / ¥${budgetAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remaining >= 0
                        ? '剩余 ¥${remaining.toStringAsFixed(2)}'
                        : '超出 ¥${(-remaining).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: remaining >= 0 ? Colors.white70 : Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 AI 分析卡片
  Widget _buildAIAnalysisCard(UserSettings? settings) {
    final settingsValue = settings;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI 智能分析',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '智能洞察您的消费习惯',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingReport)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // AI Report Preview
            if (_aiReport != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _aiReport!.length > 100
                      ? '${_aiReport!.substring(0, 100)}...'
                      : _aiReport!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _AIButton(
                    icon: Icons.analytics_outlined,
                    label: '月度报告',
                    onTap: () => _generateMonthlyReport(settingsValue),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AIButton(
                    icon: Icons.trending_up,
                    label: '消费趋势',
                    onTap: () => _showSpendingTrends(settingsValue),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AIButton(
                    icon: Icons.lightbulb_outline,
                    label: '预算建议',
                    onTap: () => _showBudgetSuggestion(settingsValue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 生成月度报告
  Future<void> _generateMonthlyReport(UserSettings? settings) async {
    if (settings == null) {
      _showError('请先在设置中配置 AI');
      return;
    }

    setState(() {
      _isLoadingReport = true;
    });

    try {
      final expenses = ref.read(allExpensesProvider).valueOrNull ?? [];
      final budget = ref.read(currentMonthBudgetProvider).valueOrNull;

      final report = await _analysisService.generateMonthlyReport(
        expenses,
        budget,
        settings,
      );

      setState(() {
        _aiReport = report;
        _isLoadingReport = false;
      });

      // 显示完整报告对话框
      if (mounted) {
        _showReportDialog(report);
      }
    } catch (e) {
      setState(() {
        _isLoadingReport = false;
      });
      _showError('生成报告失败: $e');
    }
  }

  /// 显示消费趋势
  Future<void> _showSpendingTrends(UserSettings? settings) async {
    if (settings == null) {
      _showError('请先在设置中配置 AI');
      return;
    }

    try {
      final expenses = ref.read(allExpensesProvider).valueOrNull ?? [];
      final habits = await _analysisService.analyzeSpendingHabits(expenses, settings);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _SpendingTrendsSheet(habits: habits),
      );
    } catch (e) {
      _showError('获取消费趋势失败: $e');
    }
  }

  /// 显示预算建议
  Future<void> _showBudgetSuggestion(UserSettings? settings) async {
    if (settings == null) {
      _showError('请先在设置中配置 AI');
      return;
    }

    try {
      final expenses = ref.read(allExpensesProvider).valueOrNull ?? [];
      final suggestedBudget = await _analysisService.suggestBudget(expenses, settings);
      final currentBudget = ref.read(currentMonthBudgetProvider).valueOrNull;

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _BudgetSuggestionSheet(
          suggestedBudget: suggestedBudget,
          currentBudget: currentBudget?.amount,
        ),
      );
    } catch (e) {
      _showError('获取预算建议失败: $e');
    }
  }

  /// 显示报告对话框
  void _showReportDialog(String report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: AppColors.primary),
            SizedBox(width: 8),
            Text('AI 月度报告'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            report,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildRecentSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Expense>> recentExpenses,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.recentRecords,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/history'),
                child: const Text('查看全部 →'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        recentExpenses.when(
          data: (expenses) {
            if (expenses.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const EmptyState(
                  message: '还没有记账记录\n点击下方按钮开始记账吧',
                  icon: Icons.receipt_long_outlined,
                ),
              );
            }
            final recent = expenses.take(5).toList();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: recent.length,
              itemBuilder: (context, index) {
                return ExpenseCard(
                  expense: recent[index],
                  onDelete: () {
                    ref.read(expensesProvider.notifier).deleteExpense(recent[index].id);
                  },
                  onTap: () => context.push('/add-expense?id=${recent[index].id}'),
                );
              },
            );
          },
          loading: () => Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => context.push('/add-expense'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.mic, color: Colors.white),
        label: const Text(
          '语音记账',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double total;
  final IconData icon;
  final List<Color> gradient;

  const _SummaryCard({
    required this.label,
    required this.total,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '¥${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AIButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AIButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 消费趋势底部表单
class _SpendingTrendsSheet extends StatelessWidget {
  final Map<String, dynamic> habits;

  const _SpendingTrendsSheet({required this.habits});

  @override
  Widget build(BuildContext context) {
    final hasData = habits['hasData'] == true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                '消费趋势分析',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (!hasData)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('暂无消费数据'),
              ),
            )
          else ...[
            // 月度对比
            _TrendItem(
              label: '本月支出',
              value: '¥${(habits['thisMonthTotal'] as double).toStringAsFixed(2)}',
              change: habits['monthOverMonthChange'] as double,
            ),
            const SizedBox(height: 12),

            // 平均消费
            _TrendItem(
              label: '平均每笔',
              value: '¥${(habits['averageExpense'] as double).toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),

            // 消费最高日
            if (habits['topSpendingDay'] != null)
              _TrendItem(
                label: '消费最高日',
                value: habits['topSpendingDay'] as String,
                subValue: '¥${(habits['topSpendingDayAmount'] as double).toStringAsFixed(2)}',
              ),
            const SizedBox(height: 12),

            // 消费笔数
            _TrendItem(
              label: '本月消费笔数',
              value: '${habits['expenseCount']} 笔',
            ),

            // AI 洞察
            if (habits['aiInsights'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        habits['aiInsights'] as String,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TrendItem extends StatelessWidget {
  final String label;
  final String value;
  final double? change;
  final String? subValue;

  const _TrendItem({
    required this.label,
    required this.value,
    this.change,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (change != null) ...[
              const SizedBox(width: 8),
              Text(
                '${change! > 0 ? '+' : ''}${change!.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: change! > 0 ? Colors.red : Colors.green,
                  fontSize: 12,
                ),
              ),
            ],
            if (subValue != null) ...[
              const SizedBox(width: 8),
              Text(
                subValue!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// 预算建议底部表单
class _BudgetSuggestionSheet extends StatelessWidget {
  final double suggestedBudget;
  final double? currentBudget;

  const _BudgetSuggestionSheet({
    required this.suggestedBudget,
    this.currentBudget,
  });

  @override
  Widget build(BuildContext context) {
    final diff = currentBudget != null ? suggestedBudget - currentBudget! : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'AI 预算建议',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 建议金额
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  '建议月度预算',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  '¥${suggestedBudget.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (currentBudget != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('当前预算'),
                Text(
                  '¥${currentBudget!.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('差异'),
                Text(
                  '${diff > 0 ? '+' : ''}¥${diff.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: diff > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/settings');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('去设置预算'),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
