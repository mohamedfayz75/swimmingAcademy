import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class CoachModel {
  final String coachId;
  final String coachName;
  final String phoneNumber;
  final String specialty;
  final String status; // نشط / إجازة / غير نشط
  final int groupsCount;

  const CoachModel({
    required this.coachId,
    required this.coachName,
    required this.phoneNumber,
    this.specialty = 'تعليم وسباحة عامة',
    this.status = 'نشط',
    this.groupsCount = 0,
  });

  factory CoachModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CoachModel(
      coachId: data['coach_id'] as String? ?? doc.id,
      coachName: data['coach_name'] as String? ?? '',
      phoneNumber: data['phone_number'] as String? ?? '',
      specialty: data['specialty'] as String? ?? 'تعليم وسباحة عامة',
      status: data['status'] as String? ?? 'نشط',
      groupsCount: (data['groups_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coach_id': coachId,
      'coach_name': coachName,
      'phone_number': phoneNumber,
      'specialty': specialty,
      'status': status,
      'groups_count': groupsCount,
    };
  }

  CoachModel copyWith({
    String? coachId,
    String? coachName,
    String? phoneNumber,
    String? specialty,
    String? status,
    int? groupsCount,
  }) {
    return CoachModel(
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      specialty: specialty ?? this.specialty,
      status: status ?? this.status,
      groupsCount: groupsCount ?? this.groupsCount,
    );
  }
}

class PayrollModel {
  final String coachId;
  final String coachName;
  final int sessions1To10;
  final int sessions11To20;
  final int sessions21To31;
  final int totalSessions; // إجمالي الحصص المسجلة يومياً خلال الشهر
  final double sessionRate; // سعر الحصة (يدخله المالك فقط)
  final double advancePayments; // إجمالي السلف والخصومات
  final String paymentStatus; // "تم القبض" / "معلق"
  final String payoutMethod; // كاش / انستاباي / فودافون كاش
  final String payoutNotes;
  final Timestamp payoutDate;
  final String monthYear; // e.g. "10-2026"

  const PayrollModel({
    required this.coachId,
    required this.coachName,
    this.sessions1To10 = 0,
    this.sessions11To20 = 0,
    this.sessions21To31 = 0,
    int? totalSessions,
    required this.sessionRate,
    this.advancePayments = 0.0,
    this.paymentStatus = 'معلق',
    this.payoutMethod = AppConstants.paymentCash,
    this.payoutNotes = '',
    required this.payoutDate,
    required this.monthYear,
  }) : totalSessions = totalSessions ?? (sessions1To10 + sessions11To20 + sessions21To31);

  // Calculated fields
  double get totalEarnings => totalSessions * sessionRate;
  double get netPayable => (totalEarnings - advancePayments) > 0 ? (totalEarnings - advancePayments) : 0.0;
  bool get isPaid => paymentStatus == 'تم القبض';

  factory PayrollModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PayrollModel(
      coachId: data['coach_id'] as String? ?? doc.id,
      coachName: data['coach_name'] as String? ?? '',
      totalSessions: (data['total_sessions'] as num?)?.toInt() ?? 0,
      sessionRate: (data['session_rate'] as num?)?.toDouble() ?? 0.0,
      advancePayments: (data['advance_payments'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: data['payment_status'] as String? ?? 'معلق',
      payoutMethod: data['payout_method'] as String? ?? AppConstants.paymentCash,
      payoutNotes: data['payout_notes'] as String? ?? '',
      payoutDate: data['payout_date'] as Timestamp? ?? Timestamp.now(),
      monthYear: data['month_year'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coach_id': coachId,
      'coach_name': coachName,
      'total_sessions': totalSessions,
      'session_rate': sessionRate,
      'total_earnings': totalEarnings,
      'advance_payments': advancePayments,
      'net_payable': netPayable,
      'payment_status': paymentStatus,
      'payout_method': payoutMethod,
      'payout_notes': payoutNotes,
      'payout_date': payoutDate,
      'month_year': monthYear,
    };
  }

  PayrollModel copyWith({
    String? coachId,
    String? coachName,
    int? totalSessions,
    double? sessionRate,
    double? advancePayments,
    String? paymentStatus,
    String? payoutMethod,
    String? payoutNotes,
    Timestamp? payoutDate,
    String? monthYear,
  }) {
    return PayrollModel(
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      totalSessions: totalSessions ?? this.totalSessions,
      sessionRate: sessionRate ?? this.sessionRate,
      advancePayments: advancePayments ?? this.advancePayments,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      payoutNotes: payoutNotes ?? this.payoutNotes,
      payoutDate: payoutDate ?? this.payoutDate,
      monthYear: monthYear ?? this.monthYear,
    );
  }
}
