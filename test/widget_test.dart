import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_expense_tracker/app.dart';

void main() {
  testWidgets('App loads and shows home page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that the app name is displayed
    expect(find.text('AI记账本'), findsOneWidget);

    // Verify bottom navigation exists
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.pie_chart), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
  });

  testWidgets('Can navigate to statistics page', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on statistics tab
    await tester.tap(find.byIcon(Icons.pie_chart));
    await tester.pumpAndSettle();

    // Verify statistics page is shown
    expect(find.text('统计'), findsWidgets);
  });

  testWidgets('Can navigate to history page', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on history tab
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    // Verify history page is shown
    expect(find.text('记录'), findsWidgets);
  });

  testWidgets('FAB navigates to add expense page', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on FAB (Floating Action Button)
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify add expense page is shown
    expect(find.text('记账'), findsWidgets);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });
}
