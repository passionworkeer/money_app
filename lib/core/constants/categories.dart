enum ExpenseCategory {
  food('餐饮', 'food'),
  transport('交通', 'transport'),
  shopping('购物', 'shopping'),
  entertainment('娱乐', 'entertainment'),
  medical('医疗', 'medical'),
  education('教育', 'education'),
  other('其他', 'other');

  final String label;
  final String value;

  const ExpenseCategory(this.label, this.value);

  static ExpenseCategory fromValue(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}
