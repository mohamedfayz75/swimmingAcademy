import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String category; // البند
  final double amount; // المبلغ
  final Timestamp date;
  final String notes;
  final String monthYear; // e.g. "10-2026"

  const ExpenseModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.notes = '',
    required this.monthYear,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String? ?? '',
      category: map['category'] as String? ?? 'عام',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date_ms'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(map['date_ms'] as int)
          : Timestamp.now(),
      notes: map['notes'] as String? ?? '',
      monthYear: map['month_year'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'date_ms': date.millisecondsSinceEpoch,
      'notes': notes,
      'month_year': monthYear,
    };
  }

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExpenseModel(
      id: doc.id,
      category: data['category'] as String? ?? 'عام',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: data['date'] as Timestamp? ?? Timestamp.now(),
      notes: data['notes'] as String? ?? '',
      monthYear: data['month_year'] as String? ?? '',
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? category,
    double? amount,
    Timestamp? date,
    String? notes,
    String? monthYear,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      monthYear: monthYear ?? this.monthYear,
    );
  }
}
