import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String groupCode;
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
  String get status => availableSeats > 0 ? 'متاحة' : 'مكتملة';
  bool get isAvailable => availableSeats > 0;

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final daysRaw = data['training_days'];
    List<String> days = [];
    if (daysRaw is List) {
      days = daysRaw.map((e) => e.toString()).toList();
    }

    return GroupModel(
      groupCode: data['group_code'] as String? ?? doc.id,
      coachId: data['coach_id'] as String? ?? '',
      coachName: data['coach_name'] as String? ?? '',
      trainingDays: days,
      sessionTime: data['session_time'] as String? ?? '',
      trainingType: data['training_type'] as String? ?? 'تعليم',
      level: data['level'] as String? ?? 'مبتدئ',
      maxCapacity: (data['max_capacity'] as num?)?.toInt() ?? 10,
      currentRegistered: (data['current_registered'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'group_code': groupCode,
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
