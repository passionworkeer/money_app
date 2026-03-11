import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AmountDisplay extends StatelessWidget {
  final double amount;
  final String label;
  final bool isLarge;

  const AmountDisplay({
    super.key,
    required this.amount,
    required this.label,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '¥',
              style: TextStyle(
                fontSize: isLarge ? 24 : 16,
                fontWeight: FontWeight.bold,
                color: AppColors.expense,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              amount.toStringAsFixed(2),
              style: TextStyle(
                fontSize: isLarge ? 36 : 24,
                fontWeight: FontWeight.bold,
                color: AppColors.expense,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final Function(String)? onChanged;

  const AmountInput({
    super.key,
    required this.controller,
    this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: hint ?? '0.00',
        hintStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textHint,
        ),
        prefixText: '¥ ',
        prefixStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.expense,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: onChanged,
    );
  }
}
