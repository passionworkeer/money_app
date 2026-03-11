/// 本地AI服务 - 使用关键词匹配进行消费分类
/// 作为云端API的补充，提供快速免费的本地分类能力
class LocalAiService {
  // 本地关键词到分类的映射
  static final Map<String, List<String>> _categoryKeywords = {
    '餐饮': [
      '吃饭', '午餐', '晚餐', '早餐', '外卖', '餐厅', '饭店', '火锅', '烧烤',
      '奶茶', '咖啡', '点心', '零食', '水果', '超市', '买菜', '便利店',
      '必胜客', '麦当劳', '肯德基', '星巴克', '瑞幸', '喜茶', '奈雪',
      '小程序', '美团', '饿了么', '大润发', '盒马', '物美',
    ],
    '交通': [
      '打车', '出租车', '滴滴', '地铁', '公交', '公交车', '高铁', '火车',
      '飞机', '机票', '加油', '停车', '过路', 'ETC', '共享单车', '单车',
      '滴滴出行', '高德地图', '12306', '航旅纵横', '中石化', '中石油',
    ],
    '购物': [
      '淘宝', '天猫', '京东', '拼多多', '外卖', '衣服', '鞋子', '包包',
      '化妆品', '护肤品', '日用品', '电器', '家具', '手机', '电脑',
      '唯品会', '苏宁', '国美', '小米', '华为', '苹果', 'OPPO', 'vivo',
    ],
    '娱乐': [
      '电影', 'KTV', '唱歌', '游戏', '充值', '会员', '视频', '爱奇艺',
      '腾讯视频', '优酷', '音乐', 'QQ音乐', '网易云', '旅游', '景点',
      '门票', '迪士尼', '长隆', '滑雪', '游泳', '健身', '瑜伽', '按摩',
      '剧本杀', '密室', '桌游', '网吧', '网鱼',
    ],
    '医疗': [
      '医院', '药店', '看病', '买药', '体检', '牙科', '眼科', '感冒药',
      '退烧', '消炎', '维生素', '挂号', '门诊', '住院', '医保', '药房',
      '同仁堂', '益丰', '老百姓', '大参林',
    ],
    '教育': [
      '学费', '培训', '课程', '辅导', '书籍', '教材', '文具', '笔记本',
      '学费', '补习', '家教', '在线课程', '知乎', '得到', '樊登',
      '学而思', '新东方', '猿辅导', '作业帮', '有道', '沪江',
    ],
  };

  // 金额关键词模式
  static final List<RegExp> _amountPatterns = [
    RegExp(r'(\d+\.?\d*)\s*元(?!\s*钱)'),
    RegExp(r'(\d+\.?\d*)\s*块'),
    RegExp(r'(\d+\.?\d*)\s*圆'),
    RegExp(r'花了\s*(\d+\.?\d*)'),
    RegExp(r'消费\s*(\d+\.?\d*)'),
    RegExp(r'用了\s*(\d+\.?\d*)'),
    RegExp(r'付了\s*(\d+\.?\d*)'),
  ];

  /// 本地匹配分类
  /// 返回匹配到的分类名称，如果没有匹配返回null
  String? classifyLocally(String description) {
    if (description.isEmpty) return null;

    final lowerDesc = description.toLowerCase();

    // 遍历所有分类关键词
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerDesc.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  /// 获取本地匹配的置信度
  /// 基于关键词匹配的质量，返回0.5-0.9之间的置信度
  double getLocalConfidence(String description, String? matchedCategory) {
    if (matchedCategory == null) return 0.0;

    final lowerDesc = description.toLowerCase();
    final keywords = _categoryKeywords[matchedCategory] ?? [];

    // 找到最匹配的关键词长度，越长匹配越准确
    int maxMatchedLength = 0;
    for (final keyword in keywords) {
      if (lowerDesc.contains(keyword) && keyword.length > maxMatchedLength) {
        maxMatchedLength = keyword.length;
      }
    }

    // 基于关键词长度和描述长度的比例计算置信度
    if (maxMatchedLength > 0) {
      final ratio = maxMatchedLength / description.length;
      // 置信度范围: 0.6 - 0.9
      final confidence = 0.6 + (ratio.clamp(0.0, 1.0) * 0.3);
      return confidence;
    }

    return 0.5;
  }

  /// 尝试从描述中提取金额
  double? extractAmountLocally(String description) {
    if (description.isEmpty) return null;

    for (final pattern in _amountPatterns) {
      final match = pattern.firstMatch(description);
      if (match != null && match.group(1) != null) {
        final amount = double.tryParse(match.group(1)!);
        if (amount != null && amount > 0 && amount < 1000000) {
          // 过滤异常大的金额
          return amount;
        }
      }
    }
    return null;
  }

  /// 完整的本地分类结果
  LocalClassificationResult? classifyWithConfidence(String description) {
    final category = classifyLocally(description);
    if (category == null) return null;

    final amount = extractAmountLocally(description);
    final confidence = getLocalConfidence(description, category);

    return LocalClassificationResult(
      category: category,
      amount: amount,
      confidence: confidence,
    );
  }

  /// 检查是否应该使用本地分类（基于设置）
  /// 如果description很短或者包含明确的关键词，可以使用本地分类
  bool shouldUseLocal(String description, {bool forceCloud = false}) {
    if (forceCloud) return false;
    if (description.isEmpty) return false;

    // 如果描述很短（小于10个字符），优先本地匹配
    if (description.length < 10) return true;

    // 如果能本地匹配到分类，也使用本地
    return classifyLocally(description) != null;
  }
}

/// 本地分类结果
class LocalClassificationResult {
  final String category;
  final double? amount;
  final double confidence;

  const LocalClassificationResult({
    required this.category,
    this.amount,
    required this.confidence,
  });

  @override
  String toString() {
    return 'LocalClassificationResult(category: $category, amount: $amount, confidence: $confidence)';
  }
}
