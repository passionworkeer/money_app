# AI记账本 功能完善实现计划

## 概述

基于设计文档 `docs/plans/2026-03-10-feature-enhancement-design.md`，本计划分为3个阶段实现：

- **Phase 1**: 预算管理
- **Phase 2**: 体验优化（暗黑模式、多语言、搜索、数据备份）
- **Phase 3**: 高级筛选

---

## 项目现状

### 现有架构模式（必须遵循）

| 组件 | 模式 | 示例文件 |
|------|------|----------|
| 数据模型 | immutable + copyWith() | `lib/data/models/expense_model.dart` |
| Repository | 抽象接口 + 实现 | `lib/domain/repositories/` → `lib/data/repositories/` |
| Provider | StateNotifier + FutureProvider | `lib/presentation/providers/expense_providers.dart` |
| 数据库 | SQLite单例模式 | `lib/data/datasources/local/database_helper.dart` |
| 路由 | GoRouter + ShellRoute | `lib/routes/app_router.dart` |
| 主题 | 自定义ThemeData | `lib/core/theme/app_theme.dart` |

### 现有数据库表

```sql
expenses (id, amount, description, category, date, createdAt, isSynced)
settings (id, openaiApiKey, claudeApiKey, useCloudSync, defaultCurrency)
```

---

## Phase 1: 预算管理

### 1.1 数据库扩展 - 新增budgets表

**任务**: 在DatabaseHelper中添加budgets表

**文件**: `lib/data/datasources/local/database_helper.dart`

```sql
CREATE TABLE budgets (
  id TEXT PRIMARY KEY,           -- UUID
  amount REAL NOT NULL,          -- 预算金额
  month INTEGER NOT NULL,        -- 月份(1-12)
  year INTEGER NOT NULL,         -- 年份
  createdAt INTEGER NOT NULL,    -- 创建时间
  updatedAt INTEGER NOT NULL     -- 更新时间
)
```

**Allowed APIs**:
- `database.execute(String sql)` - 执行建表SQL
- `database.insert(String table, Map<String, dynamic> values)` - 插入数据

**验证**: grep确认表创建成功，运行app无崩溃

---

### 1.2 新增Budget数据模型

**任务**: 创建预算数据模型，遵循现有Expense模式

**文件**: `lib/data/models/budget_model.dart` (新建)

```dart
class Budget {
  final String id;
  final double amount;
  final int month;
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Budget({
    required this.id,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  Budget copyWith({
    String? id,
    double? amount,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  });

  Map<String, dynamic> toMap();
  factory Budget.fromMap(Map<String, dynamic> map);
}
```

**参考**: 复制`lib/data/models/expense_model.dart`的实现模式

---

### 1.3 新增Budget Repository

**任务**: 创建Budget仓库接口和实现

**文件**:
- `lib/domain/repositories/budget_repository.dart` (新建 - 接口)
- `lib/data/repositories/budget_repository_impl.dart` (新建 - 实现)

**Allowed Methods**:
- `Future<Budget?> getBudgetByMonth(int year, int month)`
- `Future<List<Budget>> getAllBudgets()`
- `Future<void> saveBudget(Budget budget)`
- `Future<void> deleteBudget(String id)`

**参考**: `lib/data/repositories/expense_repository_impl.dart` 模式

---

### 1.4 新增Budget Provider

**任务**: 创建预算状态管理

**文件**: `lib/presentation/providers/budget_providers.dart` (新建)

```dart
// Repository Provider
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl();
});

// 当前月份预算
final currentMonthBudgetProvider = FutureProvider<Budget?>((ref) async {
  final repository = ref.watch(budgetRepositoryProvider);
  final now = DateTime.now();
  return await repository.getBudgetByMonth(now.year, now.month);
});

// 预算使用进度 (0.0 - 1.0)
final budgetProgressProvider = Provider<double>((ref) async {
  final budget = await ref.watch(currentMonthBudgetProvider.future);
  final monthTotal = await ref.watch(monthTotalProvider.future);
  if (budget == null || budget.amount <= 0) return 0.0;
  return (monthTotal / budget.amount).clamp(0.0, 1.0);
});

// 预算状态通知
class BudgetNotifier extends StateNotifier<AsyncValue<Budget?>> {
  final BudgetRepository _repository;
  final Ref _ref;

  Future<void> setBudget(double amount, int year, int month) async { ... }
  Future<void> deleteBudget(String id) async { ... }
}

final budgetNotifierProvider = StateNotifierProvider<BudgetNotifier, AsyncValue<Budget?>>((ref) {
  return BudgetNotifier(ref.watch(budgetRepositoryProvider), ref);
});
```

**参考**: `lib/presentation/providers/settings_providers.dart` 实现模式

---

### 1.5 更新UserSettings模型

**任务**: 在UserSettings中添加主题设置

**文件**: `lib/data/models/user_settings.dart`

**修改**:
```dart
class UserSettings {
  // ... existing fields
  final ThemeMode themeMode;  // 新增: system, light, dark

  UserSettings copyWith({
    // ... existing
    ThemeMode? themeMode,
  });
}
```

**Allowed Values**: `ThemeMode.system`, `ThemeMode.light`, `ThemeMode.dark`

---

### 1.6 设置页面 - 添加预算设置UI

**任务**: 在设置页面添加预算配置区块

**文件**: `lib/presentation/pages/settings/settings_page.dart`

**新增UI区块**:
```dart
Widget _buildBudgetSection() {
  return Container(
    // 预算金额输入
    // 保存按钮
  );
}
```

**参考**: 现有`_buildApiSection()`实现模式

---

### 1.7 首页 - 添加预算进度卡片

**任务**: 在首页显示预算进度

**文件**: `lib/presentation/pages/home/home_page.dart`

**新增Widget**:
```dart
Widget _buildBudgetCard() {
  // 显示: 预算金额 / 已用金额
  // 进度条: 使用比例 + 颜色变化
  // 状态文字: 健康/警告/超支
}
```

**颜色规则**:
- 0-70%: Green (#4CAF50)
- 70-90%: Orange (#FF9800)
- >90%: Red (#F44336)

**参考**: 现有`_SummaryCard`实现

---

### 1.8 统计页面 - 添加预算执行率

**任务**: 在统计页面显示本月预算执行情况

**文件**: `lib/presentation/pages/statistics/statistics_page.dart`

**修改**: 在月度总额卡片中添加预算对比

---

## Phase 2: 体验优化

### 2.1 暗黑模式 - 主题系统

**任务**: 添加完整的主题支持

**文件**: `lib/core/theme/app_theme.dart`

**新增**:
```dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(...);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    // 适配渐变色的深色版本
    // 保持一致的UI结构
  );

  static ThemeData getTheme(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return lightTheme;
      case ThemeMode.dark: return darkTheme;
      case ThemeMode.system: return lightTheme; // 跟随系统
    }
  }
}
```

**修改**: `lib/app.dart` - 使用ThemeModeProvider

---

### 2.2 多语言支持

**任务**: 添加国际化支持

**步骤**:

1. 添加Flutter Intl依赖
```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
```

2. 创建本地化文件
```
lib/l10n/
  ├── app_en.arb
  └── app_zh.arb
```

3. 配置l10n.yaml
```yaml
arb-dir: lib/l10n
template-arb-file: app_zh.arb
output-localization-file: app_localizations.dart
```

4. 在App中使用
```dart
// lib/app.dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ...
)
```

**Allowed APIs**:
- `FlutterLocalizations.localizationsDelegates`
- `AppLocalizations.of(context)`

---

### 2.3 账单搜索

**任务**: 在历史记录页面添加搜索功能

**文件**: `lib/presentation/pages/history/history_page.dart`

**新增UI**:
```dart
Widget _buildSearchBar() {
  return TextField(
    decoration: InputDecoration(
      hintText: '搜索账单...',
      prefixIcon: Icon(Icons.search),
      suffixIcon: _searchQuery.isNotEmpty
          ? IconButton(icon: Icon(Icons.clear), onPressed: _clearSearch)
          : null,
    ),
    onSubmitted: _performSearch,
  );
}
```

**新增Provider**:
```dart
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final expenses = ref.watch(allExpensesProvider).valueOrNull ?? [];
  if (query.isEmpty) return expenses;
  return expenses.where((e) =>
    e.description.toLowerCase().contains(query.toLowerCase())
  ).toList();
});
```

---

### 2.4 数据备份导出

**任务**: 导出完整数据为JSON

**文件**: `lib/core/services/backup_service.dart` (新建)

```dart
class BackupService {
  Future<String> exportData(List<Expense> expenses, Budget? budget, UserSettings settings) async {
    final data = {
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'budget': budget?.toMap(),
      'settings': settings.toMap(),
    };
    return jsonEncode(data);
  }

  Future<void> shareFile(String jsonContent) async {
    // 使用share_plus包
  }
}
```

**修改**: `lib/presentation/pages/settings/settings_page.dart` - 添加导出按钮

---

### 2.5 数据导入恢复

**任务**: 从JSON文件恢复数据

**文件**: `lib/core/services/backup_service.dart` (扩展)

```dart
class BackupService {
  Future<BackupData> importData(String jsonContent) async {
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;
    // 解析并返回
  }

  Future<void> restoreData(BackupData data) async {
    // 逐条恢复expenses
    // 恢复budgets
    // 更新settings
  }
}
```

**UI**: 设置页面添加导入按钮 + 确认对话框

---

## Phase 3: 高级筛选

### 3.1 筛选面板UI

**任务**: 创建底部弹出的筛选面板

**文件**: `lib/presentation/widgets/filter_bottom_sheet.dart` (新建)

```dart
class FilterBottomSheet extends StatefulWidget {
  final FilterOptions currentOptions;
  final Function(FilterOptions) onApply;
}

class FilterOptions {
  String? category;
  double? minAmount;
  double? maxAmount;
  DateTime? startDate;
  DateTime? endDate;
  SortBy sortBy;  // amountDesc, amountAsc, dateDesc, dateAsc
}
```

**UI结构**:
- 金额范围: 预设按钮 + 自定义输入
- 日期范围: 快捷选项 + 自定义日期选择器
- 排序: 单选按钮组

---

### 3.2 筛选Provider

**文件**: `lib/presentation/providers/filter_providers.dart` (新建)

```dart
final filterOptionsProvider = StateProvider<FilterOptions>((ref) {
  return FilterOptions();
});

final filteredAndSortedExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(allExpensesProvider).valueOrNull ?? [];
  final filters = ref.watch(filterOptionsProvider);

  return _applyFilters(expenses, filters);
});
```

**筛选逻辑**:
```dart
List<Expense> _applyFilters(List<Expense> expenses, FilterOptions filters) {
  var result = expenses;

  // 分类筛选
  if (filters.category != null) {
    result = result.where((e) => e.category == filters.category).toList();
  }

  // 金额范围
  if (filters.minAmount != null) {
    result = result.where((e) => e.amount >= filters.minAmount!).toList();
  }
  if (filters.maxAmount != null) {
    result = result.where((e) => e.amount <= filters.maxAmount!).toList();
  }

  // 日期范围
  if (filters.startDate != null) {
    result = result.where((e) => e.date.isAfter(filters.startDate!)).toList();
  }
  if (filters.endDate != null) {
    result = result.where((e) => e.date.isBefore(filters.endDate!)).toList();
  }

  // 排序
  switch (filters.sortBy) {
    case SortBy.amountDesc:
      result.sort((a, b) => b.amount.compareTo(a.amount));
    case SortBy.amountAsc:
      result.sort((a, b) => a.amount.compareTo(b.amount));
    case SortBy.dateDesc:
      result.sort((a, b) => b.date.compareTo(a.date));
    case SortBy.dateAsc:
      result.sort((a, b) => a.date.compareTo(b.date));
  }

  return result;
}
```

---

### 3.3 历史页面集成筛选

**文件**: `lib/presentation/pages/history/history_page.dart`

**修改**:
- 添加筛选按钮到AppBar
- 点击弹出FilterBottomSheet
- 底部显示当前筛选状态标签

---

## 实现顺序

### Phase 1 顺序 (优先级P0)
1. 数据库扩展 - budgets表
2. Budget模型
3. Budget Repository
4. Budget Provider
5. 首页预算卡片
6. 设置页面预算配置
7. 统计页面预算显示

### Phase 2 顺序 (优先级P1)
1. 暗黑模式主题
2. 账单搜索
3. 数据备份导出
4. 数据导入恢复
5. 多语言支持

### Phase 3 顺序 (优先级P2)
1. 筛选面板UI
2. 筛选Provider
3. 历史页面集成

---

## 验证清单

### Phase 1 验证
- [ ] App启动无崩溃
- [ ] 可以设置预算金额
- [ ] 首页显示预算进度
- [ ] 进度条颜色正确变化
- [ ] 统计数据正确计算

### Phase 2 验证
- [ ] 可切换亮色/暗黑模式
- [ ] 搜索功能正常
- [ ] 可导出JSON文件
- [ ] 可从JSON恢复数据

### Phase 3 验证
- [ ] 筛选面板正常弹出
- [ ] 金额筛选生效
- [ ] 日期筛选生效
- [ ] 排序功能正常
- [ ] 多条件组合筛选正确

---

## 依赖包

```yaml
# pubspec.yaml 新增
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
  # 已有的包
  flutter_riverpod: ^2.4.0
  go_router: ^13.0.0
  sqflite: ^2.3.0
  share_plus: ^7.2.0
  path_provider: ^2.1.1
```

---

## 文件变更清单

### 新建文件
- `lib/data/models/budget_model.dart`
- `lib/domain/repositories/budget_repository.dart`
- `lib/data/repositories/budget_repository_impl.dart`
- `lib/presentation/providers/budget_providers.dart`
- `lib/presentation/providers/filter_providers.dart`
- `lib/core/services/backup_service.dart`
- `lib/presentation/widgets/filter_bottom_sheet.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_zh.arb`

### 修改文件
- `lib/data/datasources/local/database_helper.dart` - 添加budgets表
- `lib/data/models/user_settings.dart` - 添加themeMode
- `lib/core/theme/app_theme.dart` - 添加darkTheme
- `lib/app.dart` - 添加主题和本地化支持
- `lib/presentation/pages/home/home_page.dart` - 添加预算卡片
- `lib/presentation/pages/settings/settings_page.dart` - 添加预算设置区块
- `lib/presentation/pages/statistics/statistics_page.dart` - 添加预算显示
- `lib/presentation/pages/history/history_page.dart` - 添加搜索和筛选
- `pubspec.yaml` - 添加intl依赖

---

## Anti-Patterns (禁止)

1. **不要**直接在Widget中操作数据库 - 必须通过Repository
2. **不要**使用可变状态 - 所有模型使用copyWith()
3. **不要**硬编码字符串 - 使用AppStrings或国际化
4. **不要**跳过Provider - 所有数据通过Provider访问
5. **不要**忽略错误处理 - 所有async操作需要try-catch

---

## 注意事项

1. **数据迁移**: 用户升级后需要自动创建budgets表（DatabaseHelper版本管理）
2. **向后兼容**: 新功能不影响现有功能
3. **性能**: 搜索和筛选需考虑大数据量（>1000条）
4. **权限**: 导入文件需要文件选择器权限
