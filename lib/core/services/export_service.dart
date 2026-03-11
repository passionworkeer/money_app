import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/expense_model.dart';

class ExportService {
  Future<String> exportToCsv(List<Expense> expenses) async {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('日期,金额,分类,描述');

    // CSV Data
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    for (final expense in expenses) {
      final date = dateFormat.format(expense.date);
      final amount = expense.amount.toStringAsFixed(2);
      // Escape description to handle commas and quotes
      final description = _escapeCsvField(expense.description);

      buffer.writeln('$date,$amount,${expense.category},$description');
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'expenses_$timestamp.csv';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(buffer.toString());

    return file.path;
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  Future<void> shareCsv(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'AI记账本 - 消费记录导出',
    );
  }

  Future<void> exportAndShare(List<Expense> expenses) async {
    final filePath = await exportToCsv(expenses);
    await shareCsv(filePath);
  }
}
