import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/report_models.dart';
import '../../providers/report_providers.dart';
import '../../widgets/report/monthly_report_card.dart';
import '../../widgets/report/category_pie_chart.dart';
import '../../widgets/report/trend_line_chart.dart';
import '../../widgets/report/spending_insight_card.dart';
import '../../widgets/report/top_category_list.dart';

/// 报表页面
class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYearOffset = 0;
  TrendPeriod _selectedTrendPeriod = TrendPeriod.week;

  int get _selectedYear {
    return DateTime.now().year + _selectedYearOffset;
  }

  int get _selectedYearMonth {
    final now = DateTime.now();
    return (now.year + _selectedYearOffset) * 100 + now.month;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  child: Column(
                    children: [
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMonthlyReport(),
                            _buildYearlyReport(),
                          ],
                        ),
                      ),
                    ],
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              '消费报表',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: const Color(0xFF667eea),
        unselectedLabelColor: Colors.white70,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '月度'),
          Tab(text: '年度'),
        ],
      ),
    );
  }

  Widget _buildMonthlyReport() {
    final reportAsync = ref.watch(monthlyReportProvider(_selectedYearMonth));
    final insightAsync = ref.watch(spendingInsightProvider(_selectedYearMonth));
    final trendAsync = ref.watch(spendingTrendProvider(_selectedTrendPeriod));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(monthlyReportProvider(_selectedYearMonth));
        ref.invalidate(spendingInsightProvider(_selectedYearMonth));
        ref.invalidate(spendingTrendProvider(_selectedTrendPeriod));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildYearMonthSelector(),
            const SizedBox(height: 20),
            // 月度报告卡片
            reportAsync.when(
              data: (report) => MonthlyReportCard(report: report),
              loading: () => _buildLoadingCard(),
              error: (e, _) => _buildErrorCard(e.toString()),
            ),
            const SizedBox(height: 20),
            // AI 洞察
            insightAsync.when(
              data: (insight) => SpendingInsightCard(
                insight: insight,
                onRefresh: () => ref.invalidate(spendingInsightProvider(_selectedYearMonth)),
              ),
              loading: () => const SpendingInsightCard(isLoading: true),
              error: (e, _) => SpendingInsightCard(insight: null),
            ),
            const SizedBox(height: 20),
            // 趋势图
            _buildTrendSelector(),
            const SizedBox(height: 12),
            trendAsync.when(
              data: (trend) => TrendLineChart(
                trendData: trend,
                period: _selectedTrendPeriod,
                title: _getTrendTitle(),
              ),
              loading: () => _buildLoadingCard(height: 200),
              error: (e, _) => _buildErrorCard(e.toString(), height: 200),
            ),
            const SizedBox(height: 20),
            // 分类饼图
            reportAsync.when(
              data: (report) => CategoryPieChart(
                categoryTotals: report.categoryTotals,
                total: report.totalAmount,
              ),
              loading: () => _buildLoadingCard(height: 250),
              error: (e, _) => _buildErrorCard(e.toString(), height: 250),
            ),
            const SizedBox(height: 20),
            // Top 分类列表
            reportAsync.when(
              data: (report) => TopCategoryList(
                categories: report.sortedCategories,
                total: report.totalAmount,
              ),
              loading: () => _buildLoadingCard(height: 300),
              error: (e, _) => _buildErrorCard(e.toString(), height: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyReport() {
    final reportAsync = ref.watch(yearlyReportProvider(_selectedYear));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(yearlyReportProvider(_selectedYear));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildYearSelector(),
            const SizedBox(height: 20),
            // 年度概览卡片
            reportAsync.when(
              data: (report) => _buildYearlyOverviewCard(report),
              loading: () => _buildLoadingCard(),
              error: (e, _) => _buildErrorCard(e.toString()),
            ),
            const SizedBox(height: 20),
            // 年度趋势图
            reportAsync.when(
              data: (report) => YearlyTrendChart(
                months: report.months,
                budget: report.budget,
              ),
              loading: () => _buildLoadingCard(height: 250),
              error: (e, _) => _buildErrorCard(e.toString(), height: 250),
            ),
            const SizedBox(height: 20),
            // 年度分类饼图
            reportAsync.when(
              data: (report) => CategoryPieChart(
                categoryTotals: report.categoryTotals,
                total: report.totalAmount,
              ),
              loading: () => _buildLoadingCard(height: 250),
              error: (e, _) => _buildErrorCard(e.toString(), height: 250),
            ),
            const SizedBox(height: 20),
            // 年度 Top 分类
            reportAsync.when(
              data: (report) => TopCategoryList(
                categories: report.sortedCategories,
                total: report.totalAmount,
              ),
              loading: () => _buildLoadingCard(height: 300),
              error: (e, _) => _buildErrorCard(e.toString(), height: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => setState(() => _selectedYearOffset--),
            icon: const Icon(Icons.chevron_left),
            color: AppColors.primary,
          ),
          Text(
            '${_selectedYear}年',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _selectedYearOffset < 0
                ? () => setState(() => _selectedYearOffset++)
                : null,
            icon: Icon(
              Icons.chevron_right,
              color: _selectedYearOffset < 0 ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => setState(() => _selectedYearOffset--),
            icon: const Icon(Icons.chevron_left),
            color: AppColors.primary,
          ),
          Text(
            '${_selectedYear}年',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _selectedYearOffset < 0
                ? () => setState(() => _selectedYearOffset++)
                : null,
            icon: Icon(
              Icons.chevron_right,
              color: _selectedYearOffset < 0 ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSelector() {
    return Row(
      children: [
        _buildTrendChip('周', TrendPeriod.week),
        const SizedBox(width: 8),
        _buildTrendChip('月', TrendPeriod.month),
        const SizedBox(width: 8),
        _buildTrendChip('年', TrendPeriod.year),
      ],
    );
  }

  Widget _buildTrendChip(String label, TrendPeriod period) {
    final isSelected = _selectedTrendPeriod == period;

    return GestureDetector(
      onTap: () => setState(() => _selectedTrendPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  String _getTrendTitle() {
    switch (_selectedTrendPeriod) {
      case TrendPeriod.week:
        return '周趋势';
      case TrendPeriod.month:
        return '月趋势';
      case TrendPeriod.year:
        return '年趋势';
    }
  }

  Widget _buildYearlyOverviewCard(YearlyReport report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11998e).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${report.year}年度',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${report.expenseCount}笔',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '年度支出',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '¥',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                report.totalAmount.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('月均', '¥${report.averageMonthly.toStringAsFixed(2)}'),
              const SizedBox(width: 24),
              if (report.budget != null)
                _buildStatItem('年预算', '¥${report.budget!.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard({double height = 180}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard(String error, {double height = 180}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 40),
            const SizedBox(height: 8),
            Text(
              '加载失败',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
