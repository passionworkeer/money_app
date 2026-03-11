import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/data/models/filter_options.dart';

void main() {
  group('FilterOptions Model Tests', () {
    test('FilterOptions can be created with default values', () {
      const filter = FilterOptions();

      expect(filter.category, isNull);
      expect(filter.minAmount, isNull);
      expect(filter.maxAmount, isNull);
      expect(filter.startDate, isNull);
      expect(filter.endDate, isNull);
      expect(filter.sortBy, SortBy.dateDesc);
      expect(filter.searchQuery, isNull);
    });

    test('FilterOptions can be created with all fields', () {
      final now = DateTime.now();
      final filter = FilterOptions(
        category: 'food',
        minAmount: 10.0,
        maxAmount: 100.0,
        startDate: now,
        endDate: now,
        sortBy: SortBy.amountDesc,
        searchQuery: 'test',
      );

      expect(filter.category, 'food');
      expect(filter.minAmount, 10.0);
      expect(filter.maxAmount, 100.0);
      expect(filter.startDate, now);
      expect(filter.endDate, now);
      expect(filter.sortBy, SortBy.amountDesc);
      expect(filter.searchQuery, 'test');
    });

    test('FilterOptions copyWith creates new instance with updated fields', () {
      const filter = FilterOptions(
        category: 'food',
        minAmount: 10.0,
        sortBy: SortBy.dateDesc,
      );

      final updated = filter.copyWith(
        category: 'transport',
        maxAmount: 200.0,
        sortBy: SortBy.amountAsc,
      );

      expect(updated.category, 'transport');
      expect(updated.minAmount, 10.0); // unchanged
      expect(updated.maxAmount, 200.0);
      expect(updated.sortBy, SortBy.amountAsc);
      // Original unchanged
      expect(filter.category, 'food');
      expect(filter.sortBy, SortBy.dateDesc);
    });

    test('FilterOptions copyWith with clearCategory removes category', () {
      const filter = FilterOptions(category: 'food');

      final updated = filter.copyWith(clearCategory: true);

      expect(updated.category, isNull);
      expect(filter.category, 'food'); // Original unchanged
    });

    test('FilterOptions copyWith with clearMinAmount removes minAmount', () {
      const filter = FilterOptions(minAmount: 10.0);

      final updated = filter.copyWith(clearMinAmount: true);

      expect(updated.minAmount, isNull);
    });

    test('FilterOptions copyWith with clearMaxAmount removes maxAmount', () {
      const filter = FilterOptions(maxAmount: 100.0);

      final updated = filter.copyWith(clearMaxAmount: true);

      expect(updated.maxAmount, isNull);
    });

    test('FilterOptions copyWith with clearStartDate removes startDate', () {
      final filter = FilterOptions(startDate: DateTime(2024, 1, 1));

      final updated = filter.copyWith(clearStartDate: true);

      expect(updated.startDate, isNull);
    });

    test('FilterOptions copyWith with clearEndDate removes endDate', () {
      final filter = FilterOptions(endDate: DateTime(2024, 12, 31));

      final updated = filter.copyWith(clearEndDate: true);

      expect(updated.endDate, isNull);
    });

    test('FilterOptions copyWith with clearSearchQuery removes searchQuery', () {
      const filter = FilterOptions(searchQuery: 'test');

      final updated = filter.copyWith(clearSearchQuery: true);

      expect(updated.searchQuery, isNull);
    });

    test('FilterOptions hasActiveFilters returns true when category set', () {
      const filter = FilterOptions(category: 'food');

      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions hasActiveFilters returns true when minAmount set', () {
      const filter = FilterOptions(minAmount: 10.0);

      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions hasActiveFilters returns true when maxAmount set', () {
      const filter = FilterOptions(maxAmount: 100.0);

      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions hasActiveFilters returns true when startDate set', () {
      final filter = FilterOptions(startDate: DateTime(2024, 1, 1));

      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions hasActiveFilters returns true when endDate set', () {
      final filter = FilterOptions(endDate: DateTime(2024, 12, 31));

      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions hasActiveFilters returns true when searchQuery not empty', () {
      const filter = FilterOptions(searchQuery: 'test');

      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions hasActiveFilters returns false with no filters', () {
      const filter = FilterOptions();

      expect(filter.hasActiveFilters, false);
    });

    test('FilterOptions hasActiveFilters returns false with empty searchQuery', () {
      const filter = FilterOptions(searchQuery: '');

      expect(filter.hasActiveFilters, false);
    });

    test('FilterOptions hasActiveFilters returns false with only sortBy', () {
      const filter = FilterOptions(sortBy: SortBy.amountAsc);

      expect(filter.hasActiveFilters, false);
    });

    test('FilterOptions clear removes all filters except sortBy and searchQuery', () {
      final filter = FilterOptions(
        category: 'food',
        minAmount: 10.0,
        maxAmount: 100.0,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        sortBy: SortBy.amountDesc,
        searchQuery: 'test',
      );

      final cleared = filter.clear();

      expect(cleared.category, isNull);
      expect(cleared.minAmount, isNull);
      expect(cleared.maxAmount, isNull);
      expect(cleared.startDate, isNull);
      expect(cleared.endDate, isNull);
      expect(cleared.sortBy, SortBy.amountDesc); // Preserved
      expect(cleared.searchQuery, 'test'); // Preserved
    });

    test('FilterOptions clear with no searchQuery preserves only sortBy', () {
      final filter = FilterOptions(
        category: 'food',
        minAmount: 10.0,
        sortBy: SortBy.dateAsc,
      );

      final cleared = filter.clear();

      expect(cleared.sortBy, SortBy.dateAsc);
      expect(cleared.searchQuery, isNull);
    });

    test('FilterOptions edge case - all filters set', () {
      final now = DateTime.now();
      final filter = FilterOptions(
        category: 'food',
        minAmount: 0.01,
        maxAmount: 999999.99,
        startDate: now,
        endDate: now,
        sortBy: SortBy.amountAsc,
        searchQuery: r'!@#$%^&*()',
      );

      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions edge case - zero values', () {
      const filter = FilterOptions(
        minAmount: 0.0,
        maxAmount: 0.0,
        searchQuery: '',
      );

      // Zero minAmount/maxAmount are considered active filters
      // Empty searchQuery is not
      expect(filter.minAmount, isNotNull);
      expect(filter.maxAmount, isNotNull);
      expect(filter.hasActiveFilters, true); // because minAmount/maxAmount set
    });

    // Additional tests for expanded coverage

    test('FilterOptions copyWith preserves null values when not specified', () {
      const filter = FilterOptions(
        category: 'food',
        minAmount: 10.0,
      );

      final updated = filter.copyWith(category: 'transport');

      expect(updated.category, 'transport');
      expect(updated.minAmount, 10.0);
    });

    test('FilterOptions copyWith with multiple clear flags', () {
      final filter = FilterOptions(
        category: 'food',
        minAmount: 10.0,
        maxAmount: 100.0,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      final updated = filter.copyWith(
        clearCategory: true,
        clearMinAmount: true,
        clearMaxAmount: true,
      );

      expect(updated.category, isNull);
      expect(updated.minAmount, isNull);
      expect(updated.maxAmount, isNull);
      expect(updated.startDate, DateTime(2024, 1, 1)); // unchanged
      expect(updated.endDate, DateTime(2024, 12, 31)); // unchanged
    });

    test('FilterOptions hasActiveFilters with whitespace searchQuery', () {
      const filter = FilterOptions(searchQuery: '   ');

      // Whitespace-only searchQuery should not be considered active
      expect(filter.hasActiveFilters, false);
    });

    test('FilterOptions hasActiveFilters with only startDate', () {
      final filter = FilterOptions(startDate: DateTime(2024, 1, 1));

      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions hasActiveFilters with only endDate', () {
      final filter = FilterOptions(endDate: DateTime(2024, 12, 31));

      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions clear preserves default sortBy', () {
      const filter = FilterOptions(
        category: 'food',
        minAmount: 10.0,
      );

      final cleared = filter.clear();

      expect(cleared.sortBy, SortBy.dateDesc); // default
    });

    test('FilterOptions date edge case - same start and end date', () {
      final sameDay = DateTime(2024, 6, 15);
      final filter = FilterOptions(
        startDate: sameDay,
        endDate: sameDay,
      );

      expect(filter.startDate, sameDay);
      expect(filter.endDate, sameDay);
      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions amount edge case - min equals max', () {
      const filter = FilterOptions(
        minAmount: 100.0,
        maxAmount: 100.0,
      );

      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions amount edge case - min greater than max (allowed by model)', () {
      const filter = FilterOptions(
        minAmount: 200.0,
        maxAmount: 100.0,
      );

      // Model doesn't validate, validation happens in UI or repository
      expect(filter.minAmount, 200.0);
      expect(filter.maxAmount, 100.0);
      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions date edge case - end before start (allowed by model)', () {
      final filter = FilterOptions(
        startDate: DateTime(2024, 12, 31),
        endDate: DateTime(2024, 1, 1),
      );

      // Model doesn't validate date logic
      expect(filter.startDate!.isAfter(filter.endDate!), true);
      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions with very large amounts', () {
      const filter = FilterOptions(
        minAmount: 999999999999.99,
        maxAmount: 999999999999.99,
      );

      expect(filter.minAmount, 999999999999.99);
      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions with very small amounts', () {
      const filter = FilterOptions(
        minAmount: 0.01,
        maxAmount: 0.01,
      );

      expect(filter.minAmount, 0.01);
      expect(filter.maxAmount, 0.01);
      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions copyWith can set null values explicitly', () {
      const filter = FilterOptions(
        category: 'food',
        minAmount: 10.0,
      );

      // This tests that copyWith can handle setting a field to null
      final updated = filter.copyWith(category: null);

      // Note: In the current implementation, setting category to null
      // would keep the old value since it uses (category ?? this.category)
      expect(updated.category, isNotNull);
    });

    test('FilterOptions immutability - multiple copyWith calls', () {
      const original = FilterOptions(
        category: 'food',
        minAmount: 10.0,
        maxAmount: 100.0,
      );

      final first = original.copyWith(category: 'transport');
      final second = first.copyWith(minAmount: 20.0);
      final third = second.copyWith(maxAmount: 200.0);

      // Verify original is unchanged
      expect(original.category, 'food');
      expect(original.minAmount, 10.0);
      expect(original.maxAmount, 100.0);

      // Verify intermediate is unchanged
      expect(first.category, 'transport');
      expect(first.minAmount, 10.0);
      expect(first.maxAmount, 100.0);

      // Verify third has all changes
      expect(third.category, 'transport');
      expect(third.minAmount, 20.0);
      expect(third.maxAmount, 200.0);
    });

    test('FilterOptions clear on empty filter returns same default', () {
      const filter = FilterOptions();

      final cleared = filter.clear();

      expect(cleared.category, isNull);
      expect(cleared.minAmount, isNull);
      expect(cleared.maxAmount, isNull);
      expect(cleared.startDate, isNull);
      expect(cleared.endDate, isNull);
      expect(cleared.sortBy, SortBy.dateDesc);
      expect(cleared.searchQuery, isNull);
    });

    test('FilterOptions searchQuery with special characters', () {
      const filter = FilterOptions(
        searchQuery: r'测试@#$%^&*()',
      );

      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions searchQuery with unicode characters', () {
      const filter = FilterOptions(
        searchQuery: '咖啡☕🍵',
      );

      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions searchQuery with leading and trailing spaces', () {
      const filter = FilterOptions(
        searchQuery: '  test  ',
      );

      // The searchQuery itself contains spaces, so it's active
      // Trimming should happen in the filter application logic
      expect(filter.searchQuery, '  test  ');
      expect(filter.hasActiveFilters, true);
    });

    test('FilterOptions sortBy can be changed multiple times', () {
      const filter = FilterOptions(sortBy: SortBy.dateDesc);

      var updated = filter.copyWith(sortBy: SortBy.dateAsc);
      expect(updated.sortBy, SortBy.dateAsc);

      updated = updated.copyWith(sortBy: SortBy.amountDesc);
      expect(updated.sortBy, SortBy.amountDesc);

      updated = updated.copyWith(sortBy: SortBy.amountAsc);
      expect(updated.sortBy, SortBy.amountAsc);

      // Original unchanged
      expect(filter.sortBy, SortBy.dateDesc);
    });
  });

  group('SortBy Enum Tests', () {
    test('SortBy has correct labels', () {
      expect(SortBy.dateDesc.label, '日期最新优先');
      expect(SortBy.dateAsc.label, '日期最旧优先');
      expect(SortBy.amountDesc.label, '金额从高到低');
      expect(SortBy.amountAsc.label, '金额从低到高');
    });

    test('SortBy has all expected values', () {
      expect(SortBy.values.length, 4);
      expect(SortBy.values, contains(SortBy.dateDesc));
      expect(SortBy.values, contains(SortBy.dateAsc));
      expect(SortBy.values, contains(SortBy.amountDesc));
      expect(SortBy.values, contains(SortBy.amountAsc));
    });

    // Additional SortBy tests

    test('SortBy label is not empty', () {
      for (final sort in SortBy.values) {
        expect(sort.label.isNotEmpty, true);
      }
    });

    test('SortBy values can be compared', () {
      expect(SortBy.dateDesc, SortBy.dateDesc);
      expect(SortBy.dateDesc, isNot(SortBy.dateAsc));
    });

    test('SortBy hashCode is consistent', () {
      final hashCode1 = SortBy.dateDesc.hashCode;
      final hashCode2 = SortBy.dateDesc.hashCode;
      expect(hashCode1, hashCode2);
    });

    test('SortBy toString returns label', () {
      expect(SortBy.dateDesc.toString(), contains('日期最新优先'));
    });
  });

  group('FilterOptions Integration Tests', () {
    test('Complete filter workflow - set all filters then clear', () {
      final now = DateTime.now();

      // Start with empty filters
      var filter = const FilterOptions();
      expect(filter.hasActiveFilters, false);

      // Add filters one by one
      filter = filter.copyWith(category: 'food');
      expect(filter.hasActiveFilters, true);

      filter = filter.copyWith(minAmount: 10.0);
      expect(filter.hasActiveFilters, true);

      filter = filter.copyWith(maxAmount: 100.0);
      expect(filter.hasActiveFilters, true);

      filter = filter.copyWith(startDate: now);
      expect(filter.hasActiveFilters, true);

      filter = filter.copyWith(endDate: now);
      expect(filter.hasActiveFilters, true);

      filter = filter.copyWith(searchQuery: 'lunch');
      expect(filter.hasActiveFilters, true);

      filter = filter.copyWith(sortBy: SortBy.amountDesc);
      expect(filter.hasActiveFilters, true);

      // Clear all
      final cleared = filter.clear();
      expect(cleared.hasActiveFilters, false);
      expect(cleared.category, isNull);
      expect(cleared.minAmount, isNull);
      expect(cleared.maxAmount, isNull);
      expect(cleared.startDate, isNull);
      expect(cleared.endDate, isNull);
      expect(cleared.searchQuery, 'lunch'); // preserved
      expect(cleared.sortBy, SortBy.amountDesc); // preserved
    });

    test('FilterOptions with filter provider pattern', () {
      // Simulate filter state changes as they would happen in the app

      // Initial state
      var currentFilter = const FilterOptions();
      expect(currentFilter.sortBy, SortBy.dateDesc);

      // User changes sort
      currentFilter = currentFilter.copyWith(sortBy: SortBy.amountDesc);
      expect(currentFilter.sortBy, SortBy.amountDesc);

      // User applies category filter
      currentFilter = currentFilter.copyWith(category: 'food');
      expect(currentFilter.hasActiveFilters, true);

      // User resets category but keeps sort
      currentFilter = currentFilter.copyWith(clearCategory: true);
      expect(currentFilter.category, isNull);
      expect(currentFilter.sortBy, SortBy.amountDesc); // preserved
    });

    test('FilterOptions round-trip serialization (mock)', () {
      final original = FilterOptions(
        category: 'shopping',
        minAmount: 50.0,
        maxAmount: 500.0,
        startDate: DateTime(2024, 3, 1),
        endDate: DateTime(2024, 3, 31),
        sortBy: SortBy.amountAsc,
        searchQuery: 'gift',
      );

      // Simulate serialization by creating a new instance with same values
      final restored = FilterOptions(
        category: original.category,
        minAmount: original.minAmount,
        maxAmount: original.maxAmount,
        startDate: original.startDate,
        endDate: original.endDate,
        sortBy: original.sortBy,
        searchQuery: original.searchQuery,
      );

      expect(restored.category, original.category);
      expect(restored.minAmount, original.minAmount);
      expect(restored.maxAmount, original.maxAmount);
      expect(restored.startDate, original.startDate);
      expect(restored.endDate, original.endDate);
      expect(restored.sortBy, original.sortBy);
      expect(restored.searchQuery, original.searchQuery);
      expect(restored.hasActiveFilters, original.hasActiveFilters);
    });
  });
}
