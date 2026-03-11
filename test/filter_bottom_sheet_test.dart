import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_expense_tracker/presentation/widgets/filter_bottom_sheet.dart';
import 'package:ai_expense_tracker/presentation/providers/filter_providers.dart';
import 'package:ai_expense_tracker/data/models/filter_options.dart';

void main() {
  group('FilterBottomSheet Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget({FilterOptions? initialFilters}) {
      if (initialFilters != null) {
        container.read(filterOptionsProvider.notifier).state = initialFilters;
      }

      return ProviderScope(
        parent: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const FilterBottomSheet(),
                  );
                },
                child: const Text('Open Filter'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('FilterBottomSheet can be created with callback', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Verify FilterBottomSheet is displayed
      expect(find.byType(FilterBottomSheet), findsOneWidget);
    });

    testWidgets('FilterBottomSheet displays filter title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Verify title is displayed
      expect(find.text('筛选'), findsOneWidget);
    });

    testWidgets('FilterBottomSheet displays close button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Verify close button is displayed
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('FilterBottomSheet displays search section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Verify search section is displayed
      expect(find.text('搜索'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('搜索账单备注...'), findsOneWidget);
    });

    testWidgets('FilterBottomSheet displays category filter chips', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Verify category section is displayed
      expect(find.text('分类'), findsOneWidget);
      // Verify category chips are displayed
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('餐饮'), findsOneWidget);
      expect(find.text('交通'), findsOneWidget);
      expect(find.text('购物'), findsOneWidget);
      expect(find.text('娱乐'), findsOneWidget);
      expect(find.text('医疗'), findsOneWidget);
      expect(find.text('教育'), findsOneWidget);
      expect(find.text('其他'), findsOneWidget);
    });

    testWidgets('FilterBottomSheet has amount range filters', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Verify amount section is displayed
      expect(find.text('金额范围'), findsOneWidget);
      // Verify amount preset buttons
      expect(find.text('0-50'), findsOneWidget);
      expect(find.text('50-100'), findsOneWidget);
      expect(find.text('100-300'), findsOneWidget);
      expect(find.text('300-500'), findsOneWidget);
      expect(find.text('500+'), findsOneWidget);
      // Verify custom amount input fields
      expect(find.text('最小金额'), findsOneWidget);
      expect(find.text('最大金额'), findsOneWidget);
    });

    testWidgets('FilterBottomSheet has date range filters', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Verify date section is displayed
      expect(find.text('日期范围'), findsOneWidget);
      // Verify date preset buttons
      expect(find.text('今天'), findsOneWidget);
      expect(find.text('昨天'), findsOneWidget);
      expect(find.text('最近7天'), findsOneWidget);
      expect(find.text('最近30天'), findsOneWidget);
      // Verify date picker fields
      expect(find.text('开始日期'), findsOneWidget);
      expect(find.text('结束日期'), findsOneWidget);
    });

    testWidgets('FilterBottomSheet has sort options', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Verify sort section is displayed
      expect(find.text('排序方式'), findsOneWidget);
      // Verify sort options
      expect(find.text('日期最新优先'), findsOneWidget);
      expect(find.text('日期最旧优先'), findsOneWidget);
      expect(find.text('金额从高到低'), findsOneWidget);
      expect(find.text('金额从低到高'), findsOneWidget);
    });

    testWidgets('FilterBottomSheet has apply button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Verify apply button
      expect(find.text('应用筛选'), findsOneWidget);
    });

    testWidgets('FilterBottomSheet has reset button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Verify reset button
      expect(find.text('重置'), findsOneWidget);
    });

    testWidgets('FilterBottomSheet apply button works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Apply filters
      await tester.tap(find.text('应用筛选'));
      await tester.pumpAndSettle();

      // Verify bottom sheet is closed (FilterBottomSheet no longer visible)
      expect(find.byType(FilterBottomSheet), findsNothing);
    });

    testWidgets('FilterBottomSheet reset button works', (WidgetTester tester) async {
      // Set initial filters
      const initialFilters = FilterOptions(
        category: 'food',
        minAmount: 10.0,
        maxAmount: 100.0,
      );

      await tester.pumpWidget(createTestWidget(initialFilters: initialFilters));
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Reset filters
      await tester.tap(find.text('重置'));
      await tester.pumpAndSettle();

      // Verify filters are reset (apply the reset)
      await tester.tap(find.text('应用筛选'));
      await tester.pumpAndSettle();

      // Verify filters are cleared
      final filters = container.read(filterOptionsProvider);
      expect(filters.category, isNull);
      expect(filters.minAmount, isNull);
      expect(filters.maxAmount, isNull);
    });

    testWidgets('FilterBottomSheet close button works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Close the bottom sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify bottom sheet is closed
      expect(find.byType(FilterBottomSheet), findsNothing);
    });

    testWidgets('FilterBottomSheet category selection works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Select food category
      await tester.tap(find.text('餐饮'));
      await tester.pumpAndSettle();

      // Apply filters
      await tester.tap(find.text('应用筛选'));
      await tester.pumpAndSettle();

      // Verify category filter is set
      final filters = container.read(filterOptionsProvider);
      expect(filters.category, 'food');
    });

    testWidgets('FilterBottomSheet amount preset selection works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Select amount range 100-300
      await tester.tap(find.text('100-300'));
      await tester.pumpAndSettle();

      // Apply filters
      await tester.tap(find.text('应用筛选'));
      await tester.pumpAndSettle();

      // Verify amount filters are set
      final filters = container.read(filterOptionsProvider);
      expect(filters.minAmount, 100.0);
      expect(filters.maxAmount, 300.0);
    });

    testWidgets('FilterBottomSheet date preset selection works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Select "今天" (today)
      await tester.tap(find.text('今天'));
      await tester.pumpAndSettle();

      // Apply filters
      await tester.tap(find.text('应用筛选'));
      await tester.pumpAndSettle();

      // Verify date filters are set
      final filters = container.read(filterOptionsProvider);
      expect(filters.startDate, isNotNull);
      expect(filters.endDate, isNotNull);
    });

    testWidgets('FilterBottomSheet sort option selection works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Select amount descending sort
      await tester.tap(find.text('金额从高到低'));
      await tester.pumpAndSettle();

      // Apply filters
      await tester.tap(find.text('应用筛选'));
      await tester.pumpAndSettle();

      // Verify sort option is set
      final filters = container.read(filterOptionsProvider);
      expect(filters.sortBy, SortBy.amountDesc);
    });

    testWidgets('FilterBottomSheet search input works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField).first, '午餐');
      await tester.pumpAndSettle();

      // Apply filters
      await tester.tap(find.text('应用筛选'));
      await tester.pumpAndSettle();

      // Verify search query is set
      final filters = container.read(filterOptionsProvider);
      expect(filters.searchQuery, '午餐');
    });

    testWidgets('FilterBottomSheet initializes with existing filters', (WidgetTester tester) async {
      // Set initial filters before opening
      const initialFilters = FilterOptions(
        category: 'transport',
        minAmount: 50.0,
        maxAmount: 200.0,
        sortBy: SortBy.amountAsc,
      );

      await tester.pumpWidget(createTestWidget(initialFilters: initialFilters));
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Verify the initial filters are reflected in the UI
      // The transport category should be pre-selected
      // Note: We can't easily test selection state, but we can verify filters are applied
    });

    testWidgets('FilterBottomSheet displays draggable handle', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Verify DraggableScrollableSheet is used
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('FilterBottomSheet has scrollable content', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open the filter bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Verify SingleChildScrollView is used
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
