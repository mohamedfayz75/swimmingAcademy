import 'package:cloud_firestore/cloud_firestore.dart';

class DailyCoachSessionModel {
  final String id;
  final String coachId;
  final String coachName;
  final Timestamp date;
  final int sessionCount;
  final String notes;
  final String monthYear; // e.g. "10-2026"
  final String recordedBy;
  final Timestamp createdAt;

  const DailyCoachSessionModel({
    required this.id,
    required this.coachId,
    required this.coachName,
    required this.date,
    required this.sessionCount,
    this.notes = '',
    required this.monthYear,
    this.recordedBy = 'المسؤول',
    required this.createdAt,
  });

  factory DailyCoachSessionModel.fromMap(Map<String, dynamic> map) {
    return DailyCoachSessionModel(
      id: map['id'] as String? ?? '',
      coachId: map['coach_id'] as String? ?? '',
      coachName: map['coach_name'] as String? ?? '',
      date: map['date_ms'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(map['date_ms'] as int)
          : Timestamp.now(),
      sessionCount: (map['session_count'] as num?)?.toInt() ?? 1,
      notes: map['notes'] as String? ?? '',
      monthYear: map['month_year'] as String? ?? '',
      recordedBy: map['recorded_by'] as String? ?? 'المسؤول',
      createdAt: map['created_at_ms'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(map['created_at_ms'] as int)
          : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coach_id': coachId,
      'coach_name': coachName,
      'date_ms': date.millisecondsSinceEpoch,
      'session_count': sessionCount,
      'notes': notes,
      'month_year': monthYear,
      'recorded_by': recordedBy,
      'created_at_ms': createdAt.millisecondsSinceEpoch,
    };
  }

  factory DailyCoachSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DailyCoachSessionModel(
      id: doc.id,
      coachId: data['coach_id'] as String? ?? '',
      coachName: data['coach_name'] as String? ?? '',
      date: data['date'] as Timestamp? ?? Timestamp.now(),
      sessionCount: (data['session_count'] as num?)?.toInt() ?? 1,
      notes: data['notes'] as String? ?? '',
      monthYear: data['month_year'] as String? ?? '',
      recordedBy: data['recorded_by'] as String? ?? 'المسؤول',
      createdAt: data['created_at'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'coach_id': coachId,
      'coach_name': coachName,
      'date': date,
      'session_count': sessionCount,
      'notes': notes,
      'month_year': monthYear,
      'recorded_by': recordedBy,
      'created_at': createdAt,
    };
  }
}
