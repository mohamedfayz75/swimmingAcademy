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

  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'amount': amount,
      'date': date,
      'notes': notes,
      'month_year': monthYear,
    };
  }
}
