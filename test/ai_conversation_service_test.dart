import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/core/services/ai_conversation_service.dart';
import 'package:ai_expense_tracker/data/models/user_settings.dart';

void main() {
  group('AIConversationService Tests', () {
    late AIConversationService service;

    setUp(() {
      service = AIConversationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('AIConversationService can be instantiated', () {
      expect(service, isNotNull);
    });

    test('AIConversationService has correct initial state', () {
      // Verify service is properly initialized
      expect(service, isA<AIConversationService>());
    });

    test('AIConversationService parseText works with valid input', () async {
      const settings = UserSettings();

      // Test with valid input that has amount and category keywords
      final result = await service.parseText('今天吃饭花了50元', settings);

      expect(result, isNotNull);
      expect(result.amount, isNotNull);
      expect(result.category, isNotNull);
      expect(result.description, isNotEmpty);
    });

    test('AIConversationService parseText handles empty input', () async {
      const settings = UserSettings();

      expect(
        () => service.parseText('', settings),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('AIConversationService parseText extracts amount correctly', () async {
      const settings = UserSettings();

      // Test amount extraction patterns
      final result = await service.parseText('花了100元', settings);

      expect(result.amount, equals(100.0));
    });

    test('AIConversationService parseText extracts category from keywords', () async {
      const settings = UserSettings();

      // Test food category keyword
      final foodResult = await service.parseText('中午吃了火锅', settings);
      expect(foodResult.category, equals('餐饮'));

      // Test transportation category keyword
      final transportResult = await service.parseText('打车花了30元', settings);
      expect(transportResult.category, equals('交通'));
    });

    test('AIConversationService parseText extracts date "today"', () async {
      const settings = UserSettings();

      final result = await service.parseText('今天花了50元', settings);

      expect(result.date, isNotNull);
      expect(result.date.year, equals(DateTime.now().year));
      expect(result.date.month, equals(DateTime.now().month));
      expect(result.date.day, equals(DateTime.now().day));
    });

    test('AIConversationService parseText extracts date "yesterday"', () async {
      const settings = UserSettings();

      final result = await service.parseText('昨天花了100元', settings);

      expect(result.date, isNotNull);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(result.date.year, equals(yesterday.year));
      expect(result.date.month, equals(yesterday.month));
      expect(result.date.day, equals(yesterday.day));
    });

    test('AIConversationService parseText extracts date with month/day format', () async {
      const settings = UserSettings();

      final result = await service.parseText('3月15日花了200元', settings);

      expect(result.date, isNotNull);
      expect(result.date.month, equals(3));
      expect(result.date.day, equals(15));
    });

    test('AIConversationService confirmExpense generates correct message', () {
      final parsed = ParsedExpense(
        amount: 50.0,
        category: '餐饮',
        date: DateTime(2024, 3, 15),
        description: '测试消费',
        confidence: 0.7,
        isLocalParse: true,
      );

      final message = service.confirmExpense(parsed);

      expect(message, contains('50.00'));
      expect(message, contains('餐饮'));
      expect(message, contains('3月15日'));
    });

    test('AIConversationService generateConfirmationMessage returns correct message for correct expense', () {
      final parsed = ParsedExpense(
        amount: 100.0,
        category: '购物',
        date: DateTime.now(),
        description: '网购',
        confidence: 0.8,
        isLocalParse: false,
      );

      final message = service.generateConfirmationMessage(parsed, isCorrect: true);

      expect(message, contains('购物'));
      expect(message, contains('100.00'));
    });

    test('AIConversationService generateConfirmationMessage returns correction message for incorrect expense', () {
      final parsed = ParsedExpense(
        amount: 50.0,
        category: '餐饮',
        date: DateTime.now(),
        description: '测试',
        confidence: 0.5,
        isLocalParse: true,
      );

      final message = service.generateConfirmationMessage(parsed, isCorrect: false);

      expect(message, contains('修正'));
    });

    test('ParsedExpense toExpense creates correct Expense object', () {
      final parsed = ParsedExpense(
        amount: 150.0,
        category: '娱乐',
        date: DateTime(2024, 6, 1),
        description: '电影票',
        confidence: 0.9,
        isLocalParse: false,
      );

      final expense = parsed.toExpense();

      expect(expense.amount, equals(150.0));
      expect(expense.category, equals('娱乐'));
      expect(expense.description, equals('电影票'));
    });
  });

  group('AIConversationService Edge Cases', () {
    late AIConversationService service;

    setUp(() {
      service = AIConversationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('parseText handles input without amount', () async {
      const settings = UserSettings();

      // Should still return a result with default/fallback amount
      final result = await service.parseText('买了些东西', settings);

      expect(result, isNotNull);
      expect(result.amount, isNotNull);
    });

    test('parseText handles input without category keywords', () async {
      const settings = UserSettings();

      final result = await service.parseText('花了50元', settings);

      expect(result, isNotNull);
      // Falls back to '其他' category
      expect(result.category, equals('其他'));
    });

    test('parseText handles large amounts', () async {
      const settings = UserSettings();

      final result = await service.parseText('花了999999元', settings);

      expect(result.amount, equals(999999.0));
    });

    test('parseText ignores unreasonable amounts', () async {
      const settings = UserSettings();

      // Amount > 1000000 should be ignored
      final result = await service.parseText('花了2000000元', settings);

      // Should fall back to 0.0 since amount is too large
      expect(result.amount, equals(0.0));
    });
  });
}
