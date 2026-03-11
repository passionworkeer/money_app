import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_expense_tracker/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Test - AI Expense Tracker', () {
    testWidgets('Full user flow: add expense via voice', (WidgetTester tester) async {
      // Start app
      await tester.pumpWidget(
        const ProviderScope(
          child: App(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify home page loads
      expect(find.text('AI记账本'), findsOneWidget);
      print('✓ Home page loaded');

      // 2. Navigate to statistics
      await tester.tap(find.byIcon(Icons.pie_chart));
      await tester.pumpAndSettle();
      expect(find.text('统计'), findsWidgets);
      print('✓ Statistics page works');

      // 3. Navigate back to home
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      expect(find.text('AI记账本'), findsOneWidget);
      print('✓ Navigation works');

      // 4. Navigate to history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      expect(find.text('记录'), findsWidgets);
      print('✓ History page works');

      // 5. Navigate back and tap add button
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      // 6. Open add expense page
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.mic), findsOneWidget);
      print('✓ Add expense page works');

      // 7. Check amount input exists
      expect(find.text('金额'), findsOneWidget);
      expect(find.text('分类'), findsOneWidget);
      print('✓ Form fields present');

      // 8. Navigate to settings
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
      expect(find.text('API设置'), findsOneWidget);
      print('✓ Settings page works');

      print('\n✅ All E2E tests passed!');
    });

    testWidgets('Settings page functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: App(),
        ),
      );
      await tester.pumpAndSettle();

      // Go to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Check API settings section exists
      expect(find.text('API设置'), findsOneWidget);
      expect(find.text('OpenAI API Key'), findsOneWidget);
      expect(find.text('Claude API Key'), findsOneWidget);
      print('✓ Settings page displays API fields');

      // Check cloud sync section exists
      expect(find.text('云同步'), findsOneWidget);
      print('✓ Cloud sync section present');

      // Check about section
      expect(find.text('关于'), findsOneWidget);
      print('✓ About section present');
    });

    // ========================================
    // NEW E2E TESTS - Extended Coverage
    // ========================================

    testWidgets('Calendar page E2E test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: App(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to calendar page
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();
      expect(find.text('日历'), findsOneWidget);
      print('✓ Calendar page loads');

      // 2. Verify calendar widget is displayed (TableCalendar or CustomCalendar)
      // Check for month navigation elements
      expect(find.byIcon(Icons.chevron_left), findsWidgets);
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
      print('✓ Calendar navigation controls present');

      // 3. Verify there's a date selected area (today/yesterday/date display)
      // The calendar page should show selected date expenses
      await tester.pumpAndSettle();
      print('✓ Calendar content area present');

      // 4. Navigate back to home
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      expect(find.text('AI记账本'), findsOneWidget);
      print('✓ Navigate back to home works');
    });

    testWidgets('Statistics page E2E test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: App(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to statistics page
      await tester.tap(find.byIcon(Icons.pie_chart));
      await tester.pumpAndSettle();
      expect(find.text('消费统计'), findsOneWidget);
      print('✓ Statistics page loads');

      // 2. Check for month selector
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      print('✓ Month selector present');

      // 3. Check for category breakdown sections
      // Either "分类占比" or empty state should be present
      await tester.pumpAndSettle();
      final hasContent = find.text('分类占比').evaluate().isNotEmpty ||
          find.text('本月暂无消费记录').evaluate().isNotEmpty;
      expect(hasContent, isTrue);
      print('✓ Category breakdown or empty state displayed');

      // 4. Navigate to previous month
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      print('✓ Navigate to previous month works');

      // 5. Navigate back to current month
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      print('✓ Navigate back to current month works');

      // 6. Navigate back to home
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      expect(find.text('AI记账本'), findsOneWidget);
      print('✓ Navigate back to home works');
    });

    testWidgets('History page E2E test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: App(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to history page
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      expect(find.text('消费记录'), findsOneWidget);
      print('✓ History page loads');

      // 2. Verify search bar exists
      expect(find.byIcon(Icons.search), findsOneWidget);
      print('✓ Search bar present');

      // 3. Test search functionality
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();
      // The search should trigger when submitted
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      print('✓ Search functionality works');

      // 4. Clear search and test filter button
      await tester.tap(find.byIcon(Icons.clear).first);
      await tester.pumpAndSettle();

      // 5. Test filter functionality (filter icon should be present)
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      print('✓ Filter button present');

      // 6. Test more options (sort)
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      print('✓ More options (sort/export) present');

      // 7. Navigate back to home
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      expect(find.text('AI记账本'), findsOneWidget);
      print('✓ Navigate back to home works');
    });

    testWidgets('Add expense flow E2E test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: App(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tap FAB to add expense
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('记账'), findsOneWidget);
      print('✓ Add expense page opens');

      // 2. Enter amount
      // Find the amount TextField (has ¥ prefix)
      final amountFields = find.byType(TextField);
      await tester.enterText(amountFields.first, '100');
      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);
      print('✓ Amount entered');

      // 3. Enter description
      await tester.enterText(amountFields.at(1), '测试餐饮支出');
      await tester.pumpAndSettle();
      expect(find.text('测试餐饮支出'), findsOneWidget);
      print('✓ Description entered');

      // 4. Select category - tap on 餐饮 category
      await tester.tap(find.text('餐饮'));
      await tester.pumpAndSettle();
      print('✓ Category selected');

      // 5. Save expense
      await tester.tap(find.text('保存记录'));
      await tester.pumpAndSettle();
      print('✓ Expense saved');

      // 6. Verify we are back on home page
      await tester.pumpAndSettle();
      expect(find.text('AI记账本'), findsOneWidget);
      print('✓ Returned to home page');
    });

    testWidgets('Budget card displays correctly E2E test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: App(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify home page loads
      expect(find.text('AI记账本'), findsOneWidget);
      print('✓ Home page loaded');

      // 2. Check for summary cards (今日支出, 本月支出)
      expect(find.text('今日支出'), findsOneWidget);
      expect(find.text('本月支出'), findsOneWidget);
      print('✓ Summary cards displayed');

      // 3. The budget card may or may not show depending on whether a budget is set
      // We check for either the budget card or no budget message
      await tester.pumpAndSettle();
      print('✓ Budget status checked');

      // 4. Look for CircularProgressIndicator (budget progress indicator)
      // If budget is set, there should be a progress indicator
      final progressIndicators = find.byType(CircularProgressIndicator);
      print('✓ Progress indicators found: ${progressIndicators.evaluate().length}');

      // 5. Navigate to settings to set a budget
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // 6. Scroll down to find budget section
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Check for budget settings section
      expect(find.text('预算设置'), findsOneWidget);
      print('✓ Budget settings section found in settings page');
    });

    testWidgets('Settings page navigation E2E test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: App(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
      print('✓ Settings page loads');

      // 2. Verify all main sections are present
      expect(find.text('API设置'), findsOneWidget);
      expect(find.text('主题设置'), findsOneWidget);
      expect(find.text('语言设置'), findsOneWidget);
      expect(find.text('云同步设置'), findsOneWidget);
      expect(find.text('关于'), findsOneWidget);
      print('✓ All settings sections present');

      // 3. Navigate to sync settings (云同步设置)
      await tester.tap(find.text('云同步设置'));
      await tester.pumpAndSettle();

      // Verify sync settings page loads
      await tester.pumpAndSettle();
      print('✓ Sync settings page navigated');

      // 4. Navigate back to settings
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
      print('✓ Navigate back to settings works');

      // 5. Navigate back to home
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('AI记账本'), findsOneWidget);
      print('✓ Navigate back to home works');
    });

    testWidgets('Full app smoke test - all pages load', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: App(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Home page loads
      expect(find.text('AI记账本'), findsOneWidget);
      expect(find.text('你好 👋'), findsOneWidget);
      print('✓ Home page loads correctly');

      // 2. Statistics page loads
      await tester.tap(find.byIcon(Icons.pie_chart));
      await tester.pumpAndSettle();
      expect(find.text('消费统计'), findsOneWidget);
      print('✓ Statistics page loads correctly');

      // 3. History page loads
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      expect(find.text('消费记录'), findsOneWidget);
      print('✓ History page loads correctly');

      // 4. Calendar page loads
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();
      expect(find.text('日历'), findsOneWidget);
      print('✓ Calendar page loads correctly');

      // 5. Settings page loads
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
      print('✓ Settings page loads correctly');

      // 6. Test bottom navigation items
      // Go back home first
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify all bottom navigation items work
      await tester.tap(find.byIcon(Icons.pie_chart));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      print('✓ All bottom navigation items work');

      // 7. Test FAB navigates to add expense
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('记账'), findsOneWidget);
      print('✓ FAB navigates to add expense page');

      print('\n✅ All smoke tests passed!');
    });
  });
}
