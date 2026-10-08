import 'package:cloud_firestore/cloud_firestore.dart';

class GeneralAccountingModel {
  final String monthYear; // e.g., "10-2026"
  final double totalSubscriptionRevenues;
  final double totalStampCardRevenues;
  final double totalCoachPayroll;
  final double totalWaterCardExpenses;
  final double otherExpenses;

  const GeneralAccountingModel({
    required this.monthYear,
    this.totalSubscriptionRevenues = 0.0,
    this.totalStampCardRevenues = 0.0,
    this.totalCoachPayroll = 0.0,
    this.totalWaterCardExpenses = 0.0,
    this.otherExpenses = 0.0,
  });

  // Calculated properties
  double get totalRevenues => totalSubscriptionRevenues + totalStampCardRevenues;
  double get totalExpenses => totalCoachPayroll + totalWaterCardExpenses + otherExpenses;
  double get netProfit => totalRevenues - totalExpenses;
  bool get isProfitable => netProfit >= 0;

  factory GeneralAccountingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GeneralAccountingModel(
      monthYear: data['month_year'] as String? ?? doc.id,
      totalSubscriptionRevenues: (data['total_subscription_revenues'] as num?)?.toDouble() ?? 0.0,
      totalStampCardRevenues: (data['total_stamp_card_revenues'] as num?)?.toDouble() ?? 0.0,
      totalCoachPayroll: (data['total_coach_payroll'] as num?)?.toDouble() ?? 0.0,
      totalWaterCardExpenses: (data['total_water_card_expenses'] as num?)?.toDouble() ?? 0.0,
      otherExpenses: (data['other_expenses'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'month_year': monthYear,
      'total_subscription_revenues': totalSubscriptionRevenues,
      'total_stamp_card_revenues': totalStampCardRevenues,
      'total_coach_payroll': totalCoachPayroll,
      'total_water_card_expenses': totalWaterCardExpenses,
      'other_expenses': otherExpenses,
      'total_revenues': totalRevenues,
      'total_expenses': totalExpenses,
      'net_profit': netProfit,
    };
  }
}
