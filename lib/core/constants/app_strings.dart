class AppStrings {
  AppStrings._();

  // App Info
  static const String appName = 'AI记账本';
  static const String appVersion = '1.0.0';

  // Navigation
  static const String home = '首页';
  static const String addExpense = '记账';
  static const String statistics = '统计';
  static const String history = '记录';
  static const String settings = '设置';

  // Home Page
  static const String todayTotal = '今日支出';
  static const String monthTotal = '本月支出';
  static const String recentRecords = '最近记录';
  static const String noRecords = '暂无记录';

  // Add Expense Page
  static const String voiceInput = '语音记账';
  static const String textInput = '文字记账';
  static const String amount = '金额';
  static const String description = '描述';
  static const String category = '分类';
  static const String date = '日期';
  static const String save = '保存';
  static const String cancel = '取消';
  static const String tapToSpeak = '点击说话';
  static const String listening = '正在聆听...';
  static const String analyzing = 'AI分析中...';

  // Statistics Page
  static const String monthlyOverview = '月度概览';
  static const String categoryDistribution = '分类占比';
  static const String spendingTrend = '消费趋势';
  static const String totalThisMonth = '本月总计';
  static const String averageDaily = '日均消费';

  // History Page
  static const String allRecords = '全部记录';
  static const String exportCsv = '导出CSV';
  static const String deleteConfirm = '确定删除这条记录吗？';
  static const String delete = '删除';
  static const String edit = '编辑';

  // Settings Page
  static const String apiSettings = 'API设置';
  static const String openaiApiKey = 'OpenAI API Key';
  static const String claudeApiKey = 'Claude API Key';
  static const String cloudSync = '云同步';
  static const String enableCloudSync = '启用云同步';
  static const String currency = '货币';
  static const String about = '关于';
  static const String version = '版本';
  static const String saveSuccess = '保存成功';
  static const String saveFailed = '保存失败';

  // Errors
  static const String error = '错误';
  static const String networkError = '网络错误';
  static const String apiKeyRequired = '请先设置API Key';
  static const String microphonePermission = '需要麦克风权限';
  static const String storagePermission = '需要存储权限';
}
