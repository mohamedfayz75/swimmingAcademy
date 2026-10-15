import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class SubscriptionModel {
  final String id;
  final String playerCode;
  final String playerName;
  final String branch;
  final String groupCode;
  final String? secondaryGroupCode; // Support for custom split schedules (e.g. Sat in group A + Sun in group B)
  final String coachName;
  final List<String> trainingDays;
  final String sessionTime;
  final String trainingType;
  final double stampCardFee;
  final double amountRequired;
  final double amountPaid;
  final String paymentMethod; // كاش / انستاباي / فودافون كاش
  final Timestamp paymentDate;
  final String subscriptionType;
  final int sessionsCount;
  final int attendedSessions;
  final int excusedSessions; // الحصص المعوضة بعذر طبي من المالك
  final Timestamp startDate;
  final Timestamp endDate;
  final String bookingStatus; // نشط ومؤكد / حجز بعربون / حجز مؤقت
  final String createdBy;

  const SubscriptionModel({
    required this.id,
    required this.playerCode,
    required this.playerName,
    this.branch = AppConstants.defaultBranch,
    required this.groupCode,
    this.secondaryGroupCode,
    required this.coachName,
    required this.trainingDays,
    required this.sessionTime,
    required this.trainingType,
    required this.stampCardFee,
    required this.amountRequired,
    required this.amountPaid,
    this.paymentMethod = AppConstants.paymentCash,
    required this.paymentDate,
    required this.subscriptionType,
    this.sessionsCount = 8,
    this.attendedSessions = 0,
    this.excusedSessions = 0,
    required this.startDate,
    required this.endDate,
    this.bookingStatus = AppConstants.statusActive,
    required this.createdBy,
  });

  // Precise agreed formula: (المبلغ المقرر + ختم الكارت) - المدفوع
  double get totalDue => amountRequired + stampCardFee;
  double get amountRemaining => (totalDue - amountPaid) > 0 ? (totalDue - amountPaid) : 0.0;
  String get paymentStatus => amountRemaining <= 0 ? 'خالص (مدفوع بالكامل)' : 'متبقي عليه: $amountRemaining ج.م';
  bool get isFullyPaid => amountRemaining <= 0;

  // Remaining sessions quota (considering excused sessions)
  int get remainingSessions {
    final netAttended = (attendedSessions - excusedSessions) > 0 ? (attendedSessions - excusedSessions) : 0;
    final rem = sessionsCount - netAttended;
    return rem > 0 ? rem : 0;
  }

  // Automatic expiration rule: either consumed all sessions OR current date exceeded end date
  bool get isExpired {
    final now = DateTime.now();
    final end = endDate.toDate();
    final isTimeOver = now.isAfter(end);
    final isSessionsOver = attendedSessions >= sessionsCount;
    return isTimeOver || isSessionsOver;
  }

  bool get isDepositOnly => bookingStatus == AppConstants.statusDeposit;

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    final daysRaw = map['training_days'];
    List<String> days = [];
    if (daysRaw is List) {
      days = daysRaw.map((e) => e.toString()).toList();
    }
    return SubscriptionModel(
      id: map['id'] as String? ?? '',
      playerCode: map['player_code'] as String? ?? '',
      playerName: map['player_name'] as String? ?? '',
      branch: map['branch'] as String? ?? AppConstants.defaultBranch,
      groupCode: map['group_code'] as String? ?? '',
      secondaryGroupCode: map['secondary_group_code'] as String?,
      coachName: map['coach_name'] as String? ?? '',
      trainingDays: days,
      sessionTime: map['session_time'] as String? ?? '',
      trainingType: map['training_type'] as String? ?? '',
      stampCardFee: (map['stamp_card_fee'] as num?)?.toDouble() ?? 0.0,
      amountRequired: (map['amount_required'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'] as String? ?? AppConstants.paymentCash,
      paymentDate: map['payment_date_ms'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(map['payment_date_ms'] as int)
          : Timestamp.now(),
      subscriptionType: map['subscription_type'] as String? ?? 'شهري (8 حصص)',
      sessionsCount: (map['sessions_count'] as num?)?.toInt() ?? 8,
      attendedSessions: (map['attended_sessions'] as num?)?.toInt() ?? 0,
      excusedSessions: (map['excused_sessions'] as num?)?.toInt() ?? 0,
      startDate: map['start_date_ms'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(map['start_date_ms'] as int)
          : Timestamp.now(),
      endDate: map['end_date_ms'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(map['end_date_ms'] as int)
          : Timestamp.now(),
      bookingStatus: map['booking_status'] as String? ?? AppConstants.statusActive,
      createdBy: map['created_by'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'player_code': playerCode,
      'player_name': playerName,
      'branch': branch,
      'group_code': groupCode,
      'secondary_group_code': secondaryGroupCode,
      'coach_name': coachName,
      'training_days': trainingDays,
      'session_time': sessionTime,
      'training_type': trainingType,
      'stamp_card_fee': stampCardFee,
      'amount_required': amountRequired,
      'amount_paid': amountPaid,
      'payment_method': paymentMethod,
      'payment_date_ms': paymentDate.millisecondsSinceEpoch,
      'subscription_type': subscriptionType,
      'sessions_count': sessionsCount,
      'attended_sessions': attendedSessions,
      'excused_sessions': excusedSessions,
      'start_date_ms': startDate.millisecondsSinceEpoch,
      'end_date_ms': endDate.millisecondsSinceEpoch,
      'booking_status': bookingStatus,
      'created_by': createdBy,
    };
  }

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final daysRaw = data['training_days'];
    List<String> days = [];
    if (daysRaw is List) {
      days = daysRaw.map((e) => e.toString()).toList();
    }

    return SubscriptionModel(
      id: doc.id,
      playerCode: data['player_code'] as String? ?? '',
      playerName: data['player_name'] as String? ?? '',
      branch: data['branch'] as String? ?? AppConstants.defaultBranch,
      groupCode: data['group_code'] as String? ?? '',
      secondaryGroupCode: data['secondary_group_code'] as String?,
      coachName: data['coach_name'] as String? ?? '',
      trainingDays: days,
      sessionTime: data['session_time'] as String? ?? '',
      trainingType: data['training_type'] as String? ?? '',
      stampCardFee: (data['stamp_card_fee'] as num?)?.toDouble() ?? 0.0,
      amountRequired: (data['amount_required'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (data['amount_paid'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['payment_method'] as String? ?? AppConstants.paymentCash,
      paymentDate: data['payment_date'] as Timestamp? ?? Timestamp.now(),
      subscriptionType: data['subscription_type'] as String? ?? 'شهري (8 حصص)',
      sessionsCount: (data['sessions_count'] as num?)?.toInt() ?? 8,
      attendedSessions: (data['attended_sessions'] as num?)?.toInt() ?? 0,
      excusedSessions: (data['excused_sessions'] as num?)?.toInt() ?? 0,
      startDate: data['start_date'] as Timestamp? ?? Timestamp.now(),
      endDate: data['end_date'] as Timestamp? ?? Timestamp.now(),
      bookingStatus: data['booking_status'] as String? ?? AppConstants.statusActive,
      createdBy: data['created_by'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'player_code': playerCode,
      'player_name': playerName,
      'branch': branch,
      'group_code': groupCode,
      'secondary_group_code': secondaryGroupCode,
      'coach_name': coachName,
      'training_days': trainingDays,
      'session_time': sessionTime,
      'training_type': trainingType,
      'stamp_card_fee': stampCardFee,
      'amount_required': amountRequired,
      'amount_paid': amountPaid,
      'total_due': totalDue,
      'amount_remaining': amountRemaining,
      'payment_method': paymentMethod,
      'payment_date': paymentDate,
      'subscription_type': subscriptionType,
      'sessions_count': sessionsCount,
      'attended_sessions': attendedSessions,
      'excused_sessions': excusedSessions,
      'start_date': startDate,
      'end_date': endDate,
      'payment_status': paymentStatus,
      'booking_status': bookingStatus,
      'is_expired': isExpired,
      'created_by': createdBy,
    };
  }

  SubscriptionModel copyWith({
    String? id,
    String? playerCode,
    String? playerName,
    String? branch,
    String? groupCode,
    String? secondaryGroupCode,
    String? coachName,
    List<String>? trainingDays,
    String? sessionTime,
    String? trainingType,
    double? stampCardFee,
    double? amountRequired,
    double? amountPaid,
    String? paymentMethod,
    Timestamp? paymentDate,
    String? subscriptionType,
    int? sessionsCount,
    int? attendedSessions,
    int? excusedSessions,
    Timestamp? startDate,
    Timestamp? endDate,
    String? bookingStatus,
    String? createdBy,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      playerCode: playerCode ?? this.playerCode,
      playerName: playerName ?? this.playerName,
      branch: branch ?? this.branch,
      groupCode: groupCode ?? this.groupCode,
      secondaryGroupCode: secondaryGroupCode ?? this.secondaryGroupCode,
      coachName: coachName ?? this.coachName,
      trainingDays: trainingDays ?? this.trainingDays,
      sessionTime: sessionTime ?? this.sessionTime,
      trainingType: trainingType ?? this.trainingType,
      stampCardFee: stampCardFee ?? this.stampCardFee,
      amountRequired: amountRequired ?? this.amountRequired,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      attendedSessions: attendedSessions ?? this.attendedSessions,
      excusedSessions: excusedSessions ?? this.excusedSessions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
