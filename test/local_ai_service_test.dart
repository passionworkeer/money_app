import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/core/services/local_ai_service.dart';

void main() {
  group('LocalAiService Tests', () {
    late LocalAiService service;

    setUp(() {
      service = LocalAiService();
    });

    group('classifyLocally', () {
      test('should classify 餐饮 for 吃饭', () {
        final result = service.classifyLocally('今天去吃饭花了50元');
        expect(result, equals('餐饮'));
      });

      test('should classify 餐饮 for 午餐', () {
        final result = service.classifyLocally('午餐花了30元');
        expect(result, equals('餐饮'));
      });

      test('should classify 餐饮 for 外卖', () {
        final result = service.classifyLocally('点了外卖100元');
        expect(result, equals('餐饮'));
      });

      test('should classify 餐饮 for 奶茶', () {
        final result = service.classifyLocally('买了杯奶茶25元');
        expect(result, equals('餐饮'));
      });

      test('should classify 餐饮 for 超市', () {
        final result = service.classifyLocally('去超市买菜花了200元');
        expect(result, equals('餐饮'));
      });

      test('should classify 交通 for 打车', () {
        final result = service.classifyLocally('打车花了50元');
        expect(result, equals('交通'));
      });

      test('should classify 交通 for 地铁', () {
        final result = service.classifyLocally('坐地铁花了5元');
        expect(result, equals('交通'));
      });

      test('should classify 交通 for 加油', () {
        final result = service.classifyLocally('加油花了300元');
        expect(result, equals('交通'));
      });

      test('should classify 购物 for 淘宝', () {
        final result = service.classifyLocally('淘宝买了衣服200元');
        expect(result, equals('购物'));
      });

      test('should classify 购物 for 京东', () {
        final result = service.classifyLocally('京东买了手机5000元');
        expect(result, equals('购物'));
      });

      test('should classify 娱乐 for 电影', () {
        final result = service.classifyLocally('看电影花了50元');
        expect(result, equals('娱乐'));
      });

      test('should classify 娱乐 for KTV', () {
        final result = service.classifyLocally('去KTV唱歌花了200元');
        expect(result, equals('娱乐'));
      });

      test('should classify 医疗 for 医院', () {
        final result = service.classifyLocally('去医院看病花了100元');
        expect(result, equals('医疗'));
      });

      test('should classify 医疗 for 药店', () {
        final result = service.classifyLocally('去药店买药花了50元');
        expect(result, equals('医疗'));
      });

      test('should classify 教育 for 学费', () {
        final result = service.classifyLocally('交学费花了5000元');
        expect(result, equals('教育'));
      });

      test('should classify 教育 for 培训', () {
        final result = service.classifyLocally('参加培训花了2000元');
        expect(result, equals('教育'));
      });

      test('should return null for unknown description', () {
        final result = service.classifyLocally('一些未知的消费');
        expect(result, isNull);
      });

      test('should return null for empty description', () {
        final result = service.classifyLocally('');
        expect(result, isNull);
      });

      test('should handle case insensitive matching', () {
        expect(service.classifyLocally('吃飯花了50元'), equals('餐饮'));
        expect(service.classifyLocally('打车去地铁站'), equals('交通'));
      });

      test('should match partial keywords', () {
        expect(service.classifyLocally('星巴克咖啡'), equals('餐饮'));
        expect(service.classifyLocally('滴滴出行'), equals('交通'));
      });
    });

    group('extractAmountLocally', () {
      test('should extract amount from 100元', () {
        final result = service.extractAmountLocally('花了100元');
        expect(result, equals(100.0));
      });

      test('should extract amount from 50块', () {
        final result = service.extractAmountLocally('花了50块');
        expect(result, equals(50.0));
      });

      test('should extract amount from 50圆', () {
        final result = service.extractAmountLocally('花了50圆');
        expect(result, equals(50.0));
      });

      test('should extract amount with decimal', () {
        final result = service.extractAmountLocally('花了99.5元');
        expect(result, equals(99.5));
      });

      test('should extract amount from complex description', () {
        final result = service.extractAmountLocally('今天去吃饭花了50元，还买了奶茶25元');
        expect(result, equals(50.0)); // First match
      });

      test('should return null for no amount', () {
        final result = service.extractAmountLocally('今天去吃饭');
        expect(result, isNull);
      });

      test('should return null for empty description', () {
        final result = service.extractAmountLocally('');
        expect(result, isNull);
      });

      test('should filter out too large amounts', () {
        final result = service.extractAmountLocally('花了2000000元');
        expect(result, isNull);
      });

      test('should filter out negative amounts', () {
        final result = service.extractAmountLocally('花了-50元');
        expect(result, isNull);
      });

      test('should extract from 花了 pattern', () {
        final result = service.extractAmountLocally('今天花了150元');
        expect(result, equals(150.0));
      });

      test('should extract from 消费 pattern', () {
        final result = service.extractAmountLocally('本次消费200元');
        expect(result, equals(200.0));
      });

      test('should extract from 用了 pattern', () {
        final result = service.extractAmountLocally('用了80元');
        expect(result, equals(80.0));
      });

      test('should extract from 付了 pattern', () {
        final result = service.extractAmountLocally('付了120元');
        expect(result, equals(120.0));
      });

      test('should handle amount with spaces', () {
        final result = service.extractAmountLocally('花了 75 元');
        expect(result, equals(75.0));
      });
    });

    group('getLocalConfidence', () {
      test('should return 0.0 for null category', () {
        final result = service.getLocalConfidence('test description', null);
        expect(result, equals(0.0));
      });

      test('should return confidence between 0.5 and 0.9', () {
        final result = service.getLocalConfidence('今天去吃饭花了50元', '餐饮');
        expect(result, greaterThanOrEqualTo(0.5));
        expect(result, lessThanOrEqualTo(0.9));
      });

      test('should return higher confidence for longer keyword match', () {
        final result1 = service.getLocalConfidence('吃饭', '餐饮');
        final result2 = service.getLocalConfidence('必胜客披萨', '餐饮');

        // Longer keyword should give higher confidence
        expect(result2, greaterThanOrEqualTo(result1));
      });

      test('should return 0.5 for unmatched category', () {
        final result = service.getLocalConfidence('unknown text xyz', '餐饮');
        expect(result, equals(0.5));
      });
    });

    group('classifyWithConfidence', () {
      test('should return LocalClassificationResult for valid description', () {
        final result = service.classifyWithConfidence('今天去吃饭花了50元');

        expect(result, isNotNull);
        expect(result!.category, equals('餐饮'));
        expect(result.amount, equals(50.0));
        expect(result.confidence, greaterThan(0.0));
      });

      test('should return null for unknown description', () {
        final result = service.classifyWithConfidence('未知的描述内容');
        expect(result, isNull);
      });

      test('should return result with null amount if not found', () {
        final result = service.classifyWithConfidence('今天去吃饭');

        expect(result, isNotNull);
        expect(result!.category, equals('餐饮'));
        expect(result.amount, isNull);
      });

      test('LocalClassificationResult toString works correctly', () {
        const result = LocalClassificationResult(
          category: '餐饮',
          amount: 50.0,
          confidence: 0.8,
        );

        final str = result.toString();
        expect(str, contains('餐饮'));
        expect(str, contains('50.0'));
        expect(str, contains('0.8'));
      });
    });

    group('shouldUseLocal', () {
      test('should return true for short description', () {
        final result = service.shouldUseLocal('吃饭');
        expect(result, true);
      });

      test('should return true when local classification is possible', () {
        final result = service.shouldUseLocal('今天去餐厅吃饭花了100元');
        expect(result, true);
      });

      test('should return false for forceCloud', () {
        final result = service.shouldUseLocal('今天去吃饭花了50元', forceCloud: true);
        expect(result, false);
      });

      test('should return false for empty description', () {
        final result = service.shouldUseLocal('');
        expect(result, false);
      });

      test('should return false for long description without local keywords', () {
        final result = service.shouldUseLocal('这是一个非常长的描述文字没有任何已知的分类关键词');
        expect(result, false);
      });
    });

    group('Edge Cases', () {
      test('should handle unicode characters', () {
        final result = service.classifyLocally('去星巴克喝咖啡');
        expect(result, equals('餐饮'));
      });

      test('should handle mixed Chinese and English', () {
        final result = service.classifyLocally('在KFC吃饭花了50元');
        expect(result, equals('餐饮'));
      });

      test('should handle special characters in amount', () {
        final result = service.extractAmountLocally('花了1,000元');
        // Note: comma may not be handled by current regex
        expect(result, isNull);
      });

      test('should handle very small amounts', () {
        final result = service.extractAmountLocally('花了0.01元');
        expect(result, equals(0.01));
      });

      test('should handle amount at boundary', () {
        final result = service.extractAmountLocally('花了999999元');
        expect(result, equals(999999.0));
      });
    });
  });
}
