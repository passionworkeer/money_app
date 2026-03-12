import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_expense_tracker/presentation/widgets/report/monthly_report_card.dart';
import 'package:ai_expense_tracker/data/models/report_models.dart';

void main() {
  group('MonthlyReportCard Tests', () {

    Widget createTestWidget(MonthlyReport report) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MonthlyReportCard(report: report),
          ),
        ),
      );
    }

    testWidgets('MonthlyReportCard displays month label', (WidgetTester tester) async {
      final report = MonthlyReport(
        year: 2024,
        month: 6,
        totalAmount: 5000.0,
        expenseCount: 20,
        categoryTotals: {'food': 5000.0},
        dailySpending: [],
      );

      await tester.pumpWidget(createTestWidget(report));
      await tester.pumpAndSettle();

      // Verify month label is displayed
      expect(find.text('2024年6月'), findsOneWidget);
    });

    testWidgets('MonthlyReportCard displays total amount', (WidgetTester tester) async {
      final report = MonthlyReport(
        year: 2024,
        month: 6,
        totalAmount: 5234.56,
        expenseCount: 20,
        categoryTotals: {'food': 5234.56},
        dailySpending: [],
      );

      await tester.pumpWidget(createTestWidget(report));
      await tester.pumpAndSettle();

      // Verify total amount is displayed with currency symbol
      expect(find.text('¥'), findsOneWidget);
      expect(find.text('5234.56'), findsOneWidget);
    });

    testWidgets('MonthlyReportCard displays budget info when budget exists', (WidgetTester tester) async {
      final report = MonthlyReport(
        year: 2024,
        month: 6,
        totalAmount: 3000.0,
        expenseCount: 15,
        categoryTotals: {'food': 3000.0},
        budget: 5000.0,
        dailySpending: [],
      );

      await tester.pumpWidget(createTestWidget(report));
      await tester.pumpAndSettle();

      // Verify budget usage text is displayed
      expect(find.textContaining('预算使用'), findsOneWidget);
    });

    testWidgets('MonthlyReportCard shows budget progress percentage', (WidgetTester tester) async {
      final report = MonthlyReport(
        year: 2024,
        month: 6,
        totalAmount: 3000.0,
        expenseCount: 15,
        categoryTotals: {'food': 3000.0},
        budget: 5000.0,
        dailySpending: [],
      );

      await tester.pumpWidget(createTestWidget(report));
      await tester.pumpAndSettle();

      // Verify progress percentage is displayed (60%)
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('MonthlyReportCard shows expense count', (WidgetTester tester) async {
      final report = MonthlyReport(
        year: 2024,
        month: 6,
        totalAmount: 5000.0,
        expenseCount: 25,
        categoryTotals: {'food': 5000.0},
        dailySpending: [],
      );

      await tester.pumpWidget(createTestWidget(report));
      await tester.pumpAndSettle();

      // Verify expense count is displayed
      expect(find.text('25笔'), findsOneWidget);
    });

    testWidgets('MonthlyReportCard shows "本月支出" label', (WidgetTester tester) async {
      final report = MonthlyReport(
        year: 2024,
        month: 6,
        totalAmount: 5000.0,
        expenseCount: 20,
        categoryTotals: {'food': 5000.0},
        dailySpending: [],
      );

      await tester.pumpWidget(createTestWidget(report));
      await tester.pumpAndSettle();

      // Verify "本月支出" label is displayed
      expect(find.text('本月支出'), findsOneWidget);
    });

    testWidgets('MonthlyReportCard shows progress indicator when budget exists', (WidgetTester tester) async {
      final report = MonthlyReport(
        year: 2024,
        month: 6,
        totalAmount: 3000.0,
        expenseCount: 15,
        categoryTotals: {'food': 3000.0},
        budget: 5000.0,
        dailySpending: [],
      );

      await tester.pumpWidget(createTestWidget(report));
      await tester.pumpAndSettle();

      // Verify LinearProgressIndicator is displayed
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('MonthlyReportCard shows "已超出预算" when over budget', (WidgetTester tester) async {
      final report = MonthlyReport(
        year: 2024,
        month: 6,
        totalAmount: 6000.0,
        expenseCount: 25,
        categoryTotals: {'food': 6000.0},
        budget: 5000.0,
        dailySpending: [],
      );

      await tester.pumpWidget(createTestWidget(report));
      await tester.pumpAndSettle();

      // Verify over budget message is displayed
      expect(find.text('已超出预算'), findsOneWidget);
    });

    testWidgets('MonthlyReportCard shows month-over-month change when lastMonthTotal exists', (WidgetTester tester) async {
      final report = MonthlyReport(
        year: 2024,
        month: 6,
        totalAmount: 5000.0,
        expenseCount: 20,
        categoryTotals: {'food': 5000.0},
        lastMonthTotal: 4000.0,
        dailySpending: [],
      );

      await tester.pumpWidget(createTestWidget(report));
      await tester.pumpAndSettle();

      // Verify month-over-month change is displayed
      expect(find.textContaining('较上月'), findsOneWidget);
    });

    testWidgets('MonthlyReportCard handles tap callback', (WidgetTester tester) async {
      bool tapped = false;
      final report = MonthlyReport(
        year: 2024,
        month: 6,
        totalAmount: 5000.0,
        expenseCount: 20,
        categoryTotals: {'food': 5000.0},
        dailySpending: [],
      );

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MonthlyReportCard(
              report: report,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap on the card
      await tester.tap(find.byType(MonthlyReportCard));
      await tester.pumpAndSettle();

      // Verify tap callback was triggered
      expect(tapped, isTrue);
    });

    testWidgets('MonthlyReportCard displays gradient background', (WidgetTester tester) async {
      final report = MonthlyReport(
        year: 2024,
        month: 6,
        totalAmount: 5000.0,
        expenseCount: 20,
        categoryTotals: {'food': 5000.0},
        dailySpending: [],
      );

      await tester.pumpWidget(createTestWidget(report));
      await tester.pumpAndSettle();

      // Verify container has gradient decoration
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('MonthlyReportCard shows trending icon when change exists', (WidgetTester tester) async {
      final report = MonthlyReport(
        year: 2024,
        month: 6,
        totalAmount: 5500.0,
        expenseCount: 20,
        categoryTotals: {'food': 5500.0},
        lastMonthTotal: 5000.0, // 10% increase
        dailySpending: [],
      );

      await tester.pumpWidget(createTestWidget(report));
      await tester.pumpAndSettle();

      // Verify trending icon is displayed
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });
  });
}
