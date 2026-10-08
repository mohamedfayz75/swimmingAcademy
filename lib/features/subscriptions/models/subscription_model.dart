import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String id;
  final String playerCode;
  final String playerName;
  final String groupCode;
  final String coachName;
  final List<String> trainingDays;
  final String sessionTime;
  final String trainingType;
  final double stampCardFee;
  final double amountRequired;
  final double amountPaid;
  final Timestamp paymentDate;
  final String subscriptionType;
  final int sessionsCount;
  final int attendedSessions;
  final Timestamp startDate;
  final Timestamp endDate;
  final String createdBy;

  const SubscriptionModel({
    required this.id,
    required this.playerCode,
    required this.playerName,
    required this.groupCode,
    required this.coachName,
    required this.trainingDays,
    required this.sessionTime,
    required this.trainingType,
    required this.stampCardFee,
    required this.amountRequired,
    required this.amountPaid,
    required this.paymentDate,
    required this.subscriptionType,
    this.sessionsCount = 8,
    this.attendedSessions = 0,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
  });

  // Calculated fields
  double get amountRemaining => (amountRequired - amountPaid) > 0 ? (amountRequired - amountPaid) : 0.0;
  String get paymentStatus => amountRemaining <= 0 ? 'مدفوع بالكامل' : 'متبقي';
  bool get isFullyPaid => amountRemaining <= 0;
  int get remainingSessions => (sessionsCount - attendedSessions) > 0 ? (sessionsCount - attendedSessions) : 0;
  bool get isExpired => attendedSessions >= sessionsCount;

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
      groupCode: data['group_code'] as String? ?? '',
      coachName: data['coach_name'] as String? ?? '',
      trainingDays: days,
      sessionTime: data['session_time'] as String? ?? '',
      trainingType: data['training_type'] as String? ?? '',
      stampCardFee: (data['stamp_card_fee'] as num?)?.toDouble() ?? 0.0,
      amountRequired: (data['amount_required'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (data['amount_paid'] as num?)?.toDouble() ?? 0.0,
      paymentDate: data['payment_date'] as Timestamp? ?? Timestamp.now(),
      subscriptionType: data['subscription_type'] as String? ?? 'شهري (8 حصص)',
      sessionsCount: (data['sessions_count'] as num?)?.toInt() ?? 8,
      attendedSessions: (data['attended_sessions'] as num?)?.toInt() ?? 0,
      startDate: data['start_date'] as Timestamp? ?? Timestamp.now(),
      endDate: data['end_date'] as Timestamp? ?? Timestamp.now(),
      createdBy: data['created_by'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'player_code': playerCode,
      'player_name': playerName,
      'group_code': groupCode,
      'coach_name': coachName,
      'training_days': trainingDays,
      'session_time': sessionTime,
      'training_type': trainingType,
      'stamp_card_fee': stampCardFee,
      'amount_required': amountRequired,
      'amount_paid': amountPaid,
      'amount_remaining': amountRemaining,
      'payment_date': paymentDate,
      'subscription_type': subscriptionType,
      'sessions_count': sessionsCount,
      'attended_sessions': attendedSessions,
      'start_date': startDate,
      'end_date': endDate,
      'payment_status': paymentStatus,
      'created_by': createdBy,
    };
  }

  SubscriptionModel copyWith({
    String? id,
    String? playerCode,
    String? playerName,
    String? groupCode,
    String? coachName,
    List<String>? trainingDays,
    String? sessionTime,
    String? trainingType,
    double? stampCardFee,
    double? amountRequired,
    double? amountPaid,
    Timestamp? paymentDate,
    String? subscriptionType,
    int? sessionsCount,
    int? attendedSessions,
    Timestamp? startDate,
    Timestamp? endDate,
    String? createdBy,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      playerCode: playerCode ?? this.playerCode,
      playerName: playerName ?? this.playerName,
      groupCode: groupCode ?? this.groupCode,
      coachName: coachName ?? this.coachName,
      trainingDays: trainingDays ?? this.trainingDays,
      sessionTime: sessionTime ?? this.sessionTime,
      trainingType: trainingType ?? this.trainingType,
      stampCardFee: stampCardFee ?? this.stampCardFee,
      amountRequired: amountRequired ?? this.amountRequired,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      attendedSessions: attendedSessions ?? this.attendedSessions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
