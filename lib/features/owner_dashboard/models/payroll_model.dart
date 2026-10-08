import 'package:cloud_firestore/cloud_firestore.dart';

class CoachModel {
  final String coachId;
  final String coachName;
  final String phoneNumber;
  final String status;
  final int groupsCount;

  const CoachModel({
    required this.coachId,
    required this.coachName,
    required this.phoneNumber,
    this.status = 'نشط',
    this.groupsCount = 0,
  });

  factory CoachModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CoachModel(
      coachId: data['coach_id'] as String? ?? doc.id,
      coachName: data['coach_name'] as String? ?? '',
      phoneNumber: data['phone_number'] as String? ?? '',
      status: data['status'] as String? ?? 'نشط',
      groupsCount: (data['groups_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coach_id': coachId,
      'coach_name': coachName,
      'phone_number': phoneNumber,
      'status': status,
      'groups_count': groupsCount,
    };
  }
}

class PayrollModel {
  final String coachId;
  final String coachName;
  final int sessions1To10;
  final int sessions11To20;
  final int sessions21To31;
  final double sessionRate;
  final double advancePayments; // سلف
  final String paymentStatus; // "تم الصرف", "معلق"
  final Timestamp payoutDate;
  final String monthYear; // e.g. "10-2026"

  const PayrollModel({
    required this.coachId,
    required this.coachName,
    this.sessions1To10 = 0,
    this.sessions11To20 = 0,
    this.sessions21To31 = 0,
    required this.sessionRate,
    this.advancePayments = 0.0,
    this.paymentStatus = 'معلق',
    required this.payoutDate,
    required this.monthYear,
  });

  // Calculated fields
  int get totalSessions => sessions1To10 + sessions11To20 + sessions21To31;
  double get totalEarnings => totalSessions * sessionRate;
  double get netPayable => (totalEarnings - advancePayments) > 0 ? (totalEarnings - advancePayments) : 0.0;

  factory PayrollModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PayrollModel(
      coachId: data['coach_id'] as String? ?? doc.id,
      coachName: data['coach_name'] as String? ?? '',
      sessions1To10: (data['sessions_1_to_10'] as num?)?.toInt() ?? 0,
      sessions11To20: (data['sessions_11_to_20'] as num?)?.toInt() ?? 0,
      sessions21To31: (data['sessions_21_to_31'] as num?)?.toInt() ?? 0,
      sessionRate: (data['session_rate'] as num?)?.toDouble() ?? 0.0,
      advancePayments: (data['advance_payments'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: data['payment_status'] as String? ?? 'معلق',
      payoutDate: data['payout_date'] as Timestamp? ?? Timestamp.now(),
      monthYear: data['month_year'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coach_id': coachId,
      'coach_name': coachName,
      'sessions_1_to_10': sessions1To10,
      'sessions_11_to_20': sessions11To20,
      'sessions_21_to_31': sessions21To31,
      'total_sessions': totalSessions,
      'session_rate': sessionRate,
      'total_earnings': totalEarnings,
      'advance_payments': advancePayments,
      'net_payable': netPayable,
      'payment_status': paymentStatus,
      'payout_date': payoutDate,
      'month_year': monthYear,
    };
  }
}
