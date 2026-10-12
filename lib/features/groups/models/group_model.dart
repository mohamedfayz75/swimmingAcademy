import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class GroupModel {
  final String groupCode;
  final String groupType; // عادي (6) / سيمي-برايفت (2) / كبار (1) / رضع (2)
  final String coachId;
  final String coachName;
  final List<String> trainingDays;
  final String sessionTime;
  final String trainingType;
  final String level;
  final int maxCapacity;
  final int currentRegistered;

  const GroupModel({
    required this.groupCode,
    this.groupType = AppConstants.groupTypeNormal,
    required this.coachId,
    required this.coachName,
    required this.trainingDays,
    required this.sessionTime,
    required this.trainingType,
    required this.level,
    required this.maxCapacity,
    this.currentRegistered = 0,
  });

  // Calculated fields
  int get availableSeats => (maxCapacity - currentRegistered) > 0 ? (maxCapacity - currentRegistered) : 0;
  String get status => availableSeats > 0 ? 'متاحة ($availableSeats مقاعد)' : 'مكتملة';
  bool get isAvailable => availableSeats > 0;
  bool get isBabyPrivate => groupType.contains('رضع');
  bool get isAdultPrivate => groupType.contains('كبار');
  bool get isSemiPrivate => groupType.contains('سيمي-برايفت');

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final daysRaw = data['training_days'];
    List<String> days = [];
    if (daysRaw is List) {
      days = daysRaw.map((e) => e.toString()).toList();
    }

    return GroupModel(
      groupCode: data['group_code'] as String? ?? doc.id,
      groupType: data['group_type'] as String? ?? AppConstants.groupTypeNormal,
      coachId: data['coach_id'] as String? ?? '',
      coachName: data['coach_name'] as String? ?? '',
      trainingDays: days,
      sessionTime: data['session_time'] as String? ?? '',
      trainingType: data['training_type'] as String? ?? 'تعليم (مبتدئ)',
      level: data['level'] as String? ?? 'مبتدئ',
      maxCapacity: (data['max_capacity'] as num?)?.toInt() ?? 6,
      currentRegistered: (data['current_registered'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'group_code': groupCode,
      'group_type': groupType,
      'coach_id': coachId,
      'coach_name': coachName,
      'training_days': trainingDays,
      'session_time': sessionTime,
      'training_type': trainingType,
      'level': level,
      'max_capacity': maxCapacity,
      'current_registered': currentRegistered,
      'available_seats': availableSeats,
      'status': status,
    };
  }

  GroupModel copyWith({
    String? groupCode,
    String? groupType,
    String? coachId,
    String? coachName,
    List<String>? trainingDays,
    String? sessionTime,
    String? trainingType,
    String? level,
    int? maxCapacity,
    int? currentRegistered,
  }) {
    return GroupModel(
      groupCode: groupCode ?? this.groupCode,
      groupType: groupType ?? this.groupType,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      trainingDays: trainingDays ?? this.trainingDays,
      sessionTime: sessionTime ?? this.sessionTime,
      trainingType: trainingType ?? this.trainingType,
      level: level ?? this.level,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      currentRegistered: currentRegistered ?? this.currentRegistered,
    );
  }
}
