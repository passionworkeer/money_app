import 'package:uuid/uuid.dart';

class Expense {
  final String id;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Expense({
    String? id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Expense copyWith({
    String? id,
    double? amount,
    String? description,
    String? category,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      category: map['category'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      isSynced: (map['isSynced'] as int?) == 1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
