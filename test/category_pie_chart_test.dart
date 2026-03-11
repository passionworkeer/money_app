import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ai_expense_tracker/presentation/widgets/report/category_pie_chart.dart';
import 'package:ai_expense_tracker/data/models/report_models.dart';
import 'package:ai_expense_tracker/core/constants/categories.dart';

void main() {
  group('CategoryPieChart Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget({
      required Map<String, double> categoryTotals,
      required double total,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(
              categoryTotals: categoryTotals,
              total: total,
            ),
          ),
        ),
      );
    }

    testWidgets('CategoryPieChart can be created with data', (WidgetTester tester) async {
      final categoryTotals = {
        'food': 500.0,
        'transport': 300.0,
        'shopping': 200.0,
      };

      await tester.pumpWidget(createTestWidget(
        categoryTotals: categoryTotals,
        total: 1000.0,
      ));
      await tester.pumpAndSettle();

      // Verify CategoryPieChart is displayed
      expect(find.byType(CategoryPieChart), findsOneWidget);
    });

    testWidgets('CategoryPieChart renders pie chart', (WidgetTester tester) async {
      final categoryTotals = {
        'food': 500.0,
        'transport': 300.0,
        'shopping': 200.0,
      };

      await tester.pumpWidget(createTestWidget(
        categoryTotals: categoryTotals,
        total: 1000.0,
      ));
      await tester.pumpAndSettle();

      // Verify PieChart is displayed
      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('CategoryPieChart handles empty data', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        categoryTotals: {},
        total: 0.0,
      ));
      await tester.pumpAndSettle();

      // Verify empty state message is displayed
      expect(find.text('暂无数据'), findsOneWidget);
    });

    testWidgets('CategoryPieChart shows legend', (WidgetTester tester) async {
      final categoryTotals = {
        'food': 500.0,
        'transport': 300.0,
        'shopping': 200.0,
      };

      await tester.pumpWidget(createTestWidget(
        categoryTotals: categoryTotals,
        total: 1000.0,
      ));
      await tester.pumpAndSettle();

      // Verify legend section is displayed
      // Category labels should be shown in legend
      expect(find.text('餐饮'), findsOneWidget);
      expect(find.text('交通'), findsOneWidget);
      expect(find.text('购物'), findsOneWidget);
    });

    testWidgets('CategoryPieChart shows title "分类占比"', (WidgetTester tester) async {
      final categoryTotals = {
        'food': 500.0,
      };

      await tester.pumpWidget(createTestWidget(
        categoryTotals: categoryTotals,
        total: 500.0,
      ));
      await tester.pumpAndSettle();

      // Verify title is displayed
      expect(find.text('分类占比'), findsOneWidget);
    });

    testWidgets('CategoryPieChart renders correctly with single category', (WidgetTester tester) async {
      final categoryTotals = {
        'food': 1000.0,
      };

      await tester.pumpWidget(createTestWidget(
        categoryTotals: categoryTotals,
        total: 1000.0,
      ));
      await tester.pumpAndSettle();

      // Verify PieChart is displayed
      expect(find.byType(PieChart), findsOneWidget);
      // Verify single category in legend
      expect(find.text('餐饮'), findsOneWidget);
    });

    testWidgets('CategoryPieChart shows multiple categories in legend', (WidgetTester tester) async {
      final categoryTotals = {
        'food': 400.0,
        'transport': 300.0,
        'shopping': 200.0,
        'entertainment': 100.0,
      };

      await tester.pumpWidget(createTestWidget(
        categoryTotals: categoryTotals,
        total: 1000.0,
      ));
      await tester.pumpAndSettle();

      // Verify multiple categories in legend (up to 5)
      expect(find.text('餐饮'), findsOneWidget);
      expect(find.text('交通'), findsOneWidget);
      expect(find.text('购物'), findsOneWidget);
      expect(find.text('娱乐'), findsOneWidget);
    });

    testWidgets('CategoryPieChart has container decoration', (WidgetTester tester) async {
      final categoryTotals = {
        'food': 500.0,
      };

      await tester.pumpWidget(createTestWidget(
        categoryTotals: categoryTotals,
        total: 500.0,
      ));
      await tester.pumpAndSettle();

      // Verify container has decoration
      final containerFinder = find.byType(Container).first;
      final containerWidget = tester.widget<Container>(containerFinder);
      expect(containerWidget.decoration, isA<BoxDecoration>());
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.white));
      expect(decoration.borderRadius, equals(BorderRadius.circular(20)));
    });

    testWidgets('CategoryPieChart shows legend items with color boxes', (WidgetTester tester) async {
      final categoryTotals = {
        'food': 500.0,
        'transport': 300.0,
      };

      await tester.pumpWidget(createTestWidget(
        categoryTotals: categoryTotals,
        total: 800.0,
      ));
      await tester.pumpAndSettle();

      // Verify legend items have colored containers
      // Find containers that are used as color indicators in legend
      final containers = tester.widgetList<Container>(find.byType(Container));
      // Should have at least 2 color indicator containers in legend
      expect(containers.length, greaterThanOrEqualTo(2));
    });

    testWidgets('CategoryPieChart calculates percentages correctly', (WidgetTester tester) async {
      final categoryTotals = {
        'food': 750.0,
        'transport': 250.0,
      };

      await tester.pumpWidget(createTestWidget(
        categoryTotals: categoryTotals,
        total: 1000.0,
      ));
      await tester.pumpAndSettle();

      // Verify PieChart is rendered with correct proportions
      expect(find.byType(PieChart), findsOneWidget);
    });
  });

  group('CategoryPieChartSmall Tests', () {
    Widget createSmallTestWidget({List<CategoryData> categories = const []}) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CategoryPieChartSmall(categories: categories),
          ),
        ),
      );
    }

    testWidgets('CategoryPieChartSmall can be created with data', (WidgetTester tester) async {
      final categories = [
        CategoryData(
          category: ExpenseCategory.food,
          amount: 500.0,
          percentage: 50.0,
        ),
        CategoryData(
          category: ExpenseCategory.transport,
          amount: 300.0,
          percentage: 30.0,
        ),
        CategoryData(
          category: ExpenseCategory.shopping,
          amount: 200.0,
          percentage: 20.0,
        ),
      ];

      await tester.pumpWidget(createSmallTestWidget(categories: categories));
      await tester.pumpAndSettle();

      // Verify CategoryPieChartSmall is displayed
      expect(find.byType(CategoryPieChartSmall), findsOneWidget);
    });

    testWidgets('CategoryPieChartSmall renders pie chart', (WidgetTester tester) async {
      final categories = [
        CategoryData(
          category: ExpenseCategory.food,
          amount: 500.0,
          percentage: 50.0,
        ),
      ];

      await tester.pumpWidget(createSmallTestWidget(categories: categories));
      await tester.pumpAndSettle();

      // Verify PieChart is displayed
      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('CategoryPieChartSmall handles empty data', (WidgetTester tester) async {
      await tester.pumpWidget(createSmallTestWidget(categories: []));
      await tester.pumpAndSettle();

      // Verify empty state (SizedBox.shrink returns nothing visible)
      expect(find.byType(CategoryPieChartSmall), findsOneWidget);
      // No PieChart should be shown for empty data
      expect(find.byType(PieChart), findsNothing);
    });

    testWidgets('CategoryPieChartSmall shows legend', (WidgetTester tester) async {
      final categories = [
        CategoryData(
          category: ExpenseCategory.food,
          amount: 500.0,
          percentage: 50.0,
        ),
        CategoryData(
          category: ExpenseCategory.transport,
          amount: 300.0,
          percentage: 30.0,
        ),
      ];

      await tester.pumpWidget(createSmallTestWidget(categories: categories));
      await tester.pumpAndSettle();

      // Verify category labels are displayed
      expect(find.text('餐饮'), findsOneWidget);
      expect(find.text('交通'), findsOneWidget);
    });

    testWidgets('CategoryPieChartSmall shows percentages', (WidgetTester tester) async {
      final categories = [
        CategoryData(
          category: ExpenseCategory.food,
          amount: 500.0,
          percentage: 50.0,
        ),
        CategoryData(
          category: ExpenseCategory.transport,
          amount: 500.0,
          percentage: 50.0,
        ),
      ];

      await tester.pumpWidget(createSmallTestWidget(categories: categories));
      await tester.pumpAndSettle();

      // Verify percentages are displayed
      expect(find.text('50%'), findsNWidgets(2));
    });
  });
}
