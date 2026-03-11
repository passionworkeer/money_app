enum SortBy {
  dateDesc('日期最新优先'),
  dateAsc('日期最旧优先'),
  amountDesc('金额从高到低'),
  amountAsc('金额从低到高');

  final String label;
  const SortBy(this.label);
}

class FilterOptions {
  final String? category;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final SortBy sortBy;
  final String? searchQuery;

  const FilterOptions({
    this.category,
    this.minAmount,
    this.maxAmount,
    this.startDate,
    this.endDate,
    this.sortBy = SortBy.dateDesc,
    this.searchQuery,
  });

  FilterOptions copyWith({
    String? category,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    SortBy? sortBy,
    String? searchQuery,
    bool clearCategory = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearSearchQuery = false,
  }) {
    return FilterOptions(
      category: clearCategory ? null : (category ?? this.category),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      sortBy: sortBy ?? this.sortBy,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get hasActiveFilters =>
    category != null ||
    minAmount != null ||
    maxAmount != null ||
    startDate != null ||
    endDate != null ||
    (searchQuery != null && searchQuery!.isNotEmpty);

  FilterOptions clear() {
    return FilterOptions(
      sortBy: sortBy,
      searchQuery: searchQuery,
    );
  }
}
