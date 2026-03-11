import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/categories.dart';
import '../../data/models/filter_options.dart';
import '../providers/filter_providers.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  late TextEditingController _searchController;

  String? _selectedCategory;
  double? _minAmount;
  double? _maxAmount;
  DateTime? _startDate;
  DateTime? _endDate;
  SortBy _sortBy = SortBy.dateDesc;
  String _searchQuery = '';

  // 预设金额范围
  final List<Map<String, dynamic>> _amountPresets = [
    {'label': '0-50', 'min': 0.0, 'max': 50.0},
    {'label': '50-100', 'min': 50.0, 'max': 100.0},
    {'label': '100-300', 'min': 100.0, 'max': 300.0},
    {'label': '300-500', 'min': 300.0, 'max': 500.0},
    {'label': '500+', 'min': 500.0, 'max': null},
  ];

  // 日期快捷选项
  final List<Map<String, dynamic>> _datePresets = [
    {'label': '今天', 'days': 0},
    {'label': '昨天', 'days': 1},
    {'label': '最近7天', 'days': 7},
    {'label': '最近30天', 'days': 30},
  ];

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(filterOptionsProvider);
    _selectedCategory = currentFilters.category;
    _minAmount = currentFilters.minAmount;
    _maxAmount = currentFilters.maxAmount;
    _startDate = currentFilters.startDate;
    _endDate = currentFilters.endDate;
    _sortBy = currentFilters.sortBy;
    _searchQuery = currentFilters.searchQuery ?? '';

    _minAmountController = TextEditingController(
      text: _minAmount?.toStringAsFixed(0) ?? '',
    );
    _maxAmountController = TextEditingController(
      text: _maxAmount?.toStringAsFixed(0) ?? '',
    );
    _searchController = TextEditingController(text: _searchQuery);
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final searchText = _searchController.text.trim();

    final newFilters = FilterOptions(
      category: _selectedCategory,
      minAmount: _minAmount,
      maxAmount: _maxAmount,
      startDate: _startDate,
      endDate: _endDate,
      sortBy: _sortBy,
      searchQuery: searchText.isEmpty ? null : searchText,
    );

    ref.read(filterOptionsProvider.notifier).state = newFilters;
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _minAmount = null;
      _maxAmount = null;
      _startDate = null;
      _endDate = null;
      _sortBy = SortBy.dateDesc;
      _searchController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _selectDateRange(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      if (days == 0) {
        // 今天
        _startDate = today;
        _endDate = today;
      } else if (days == 1) {
        // 昨天
        _startDate = today.subtract(const Duration(days: 1));
        _endDate = today.subtract(const Duration(days: 1));
      } else {
        // 最近N天
        _startDate = today.subtract(Duration(days: days - 1));
        _endDate = today;
      }
    });
  }

  void _selectAmountRange(double? min, double? max) {
    setState(() {
      _minAmount = min;
      _maxAmount = max;
      _minAmountController.text = min?.toStringAsFixed(0) ?? '';
      _maxAmountController.text = max?.toStringAsFixed(0) ?? '';
    });
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchSection(),
                      const SizedBox(height: 24),
                      _buildCategorySection(),
                      const SizedBox(height: 24),
                      _buildAmountSection(),
                      const SizedBox(height: 24),
                      _buildDateSection(),
                      const SizedBox(height: 24),
                      _buildSortSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              _buildBottomButtons(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '筛选',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '搜索',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索账单备注...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分类',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCategoryChip('全部', null, AppColors.primary),
            ...ExpenseCategory.values.map((category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCategoryChip(
                category.label,
                category.value,
                AppColors.categoryColors[category.value] ?? AppColors.primary,
              ),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String? value, Color color) {
    final isSelected = _selectedCategory == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '金额范围',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _amountPresets.map((preset) {
            final min = preset['min'] as double;
            final max = preset['max'] as double?;
            final isSelected = _minAmount == min && _maxAmount == max;

            return GestureDetector(
              onTap: () => _selectAmountRange(min, max),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  preset['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: '最小金额',
                  prefixIcon: const Icon(Icons.remove),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (value) {
                  setState(() {
                    _minAmount = value.isEmpty ? null : double.tryParse(value);
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '-',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 20),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _maxAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: '最大金额',
                  prefixIcon: const Icon(Icons.add),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (value) {
                  setState(() {
                    _maxAmount = value.isEmpty ? null : double.tryParse(value);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '日期范围',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _datePresets.map((preset) {
            final days = preset['days'] as int;
            final isSelected = _isDatePresetSelected(days);

            return GestureDetector(
              onTap: () => _selectDateRange(days),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  preset['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                label: '开始日期',
                value: _startDate != null ? dateFormat.format(_startDate!) : null,
                onTap: _selectStartDate,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '-',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 20),
              ),
            ),
            Expanded(
              child: _buildDatePicker(
                label: '结束日期',
                value: _endDate != null ? dateFormat.format(_endDate!) : null,
                onTap: _selectEndDate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _isDatePresetSelected(int days) {
    if (_startDate == null || _endDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (days) {
      case 0:
        return _isSameDay(_startDate!, today) && _isSameDay(_endDate!, today);
      case 1:
        final yesterday = today.subtract(const Duration(days: 1));
        return _isSameDay(_startDate!, yesterday) && _isSameDay(_endDate!, yesterday);
      default:
        final expectedStart = today.subtract(Duration(days: days - 1));
        return _isSameDay(_startDate!, expectedStart) && _isSameDay(_endDate!, today);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDatePicker({
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  color: value != null ? Colors.black87 : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '排序方式',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SortBy.values.map((sort) {
            final isSelected = _sortBy == sort;

            return GestureDetector(
              onTap: () => setState(() => _sortBy = sort),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getSortIcon(sort),
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sort.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getSortIcon(SortBy sort) {
    switch (sort) {
      case SortBy.dateDesc:
        return Icons.arrow_downward;
      case SortBy.dateAsc:
        return Icons.arrow_upward;
      case SortBy.amountDesc:
        return Icons.trending_down;
      case SortBy.amountAsc:
        return Icons.trending_up;
    }
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetFilters,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '重置',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '应用筛选',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showFilterBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const FilterBottomSheet(),
  );
}
