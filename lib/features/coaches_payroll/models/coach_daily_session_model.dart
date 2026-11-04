import 'package:cloud_firestore/cloud_firestore.dart';

class CoachDailySessionModel {
  final String id;
  final String coachId;
  final String coachName;
  final DateTime date;
  final int sessionsCount;
  final String notes;
  final String loggedBy;
  final DateTime loggedAt;

  const CoachDailySessionModel({
    required this.id,
    required this.coachId,
    required this.coachName,
    required this.date,
    required this.sessionsCount,
    this.notes = '',
    this.loggedBy = '',
    required this.loggedAt,
  });

  DateTime get createdAt => loggedAt;
  int get dayOfMonth => date.day;
  String get dateFormatted => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String get monthYear => '${date.month.toString().padLeft(2, '0')}-${date.year}';

  factory CoachDailySessionModel.fromMap(Map<String, dynamic> map) {
    return CoachDailySessionModel(
      id: map['id'] as String? ?? '',
      coachId: map['coach_id'] as String? ?? '',
      coachName: map['coach_name'] as String? ?? '',
      date: map['date_ms'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date_ms'] as int)
          : DateTime.now(),
      sessionsCount: (map['sessions_count'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String? ?? '',
      loggedBy: map['logged_by'] as String? ?? '',
      loggedAt: map['logged_at_ms'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['logged_at_ms'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coach_id': coachId,
      'coach_name': coachName,
      'date_ms': date.millisecondsSinceEpoch,
      'sessions_count': sessionsCount,
      'notes': notes,
      'logged_by': loggedBy,
      'logged_at_ms': loggedAt.millisecondsSinceEpoch,
    };
  }

  factory CoachDailySessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final dateVal = data['date'];
    final loggedAtVal = data['logged_at'];

    DateTime parseDt(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return CoachDailySessionModel(
      id: data['id'] as String? ?? doc.id,
      coachId: data['coach_id'] as String? ?? '',
      coachName: data['coach_name'] as String? ?? '',
      date: parseDt(dateVal),
      sessionsCount: (data['sessions_count'] as num?)?.toInt() ?? 0,
      notes: data['notes'] as String? ?? '',
      loggedBy: data['logged_by'] as String? ?? '',
      loggedAt: parseDt(loggedAtVal),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'coach_id': coachId,
      'coach_name': coachName,
      'date': Timestamp.fromDate(date),
      'date_ms': date.millisecondsSinceEpoch,
      'sessions_count': sessionsCount,
      'notes': notes,
      'logged_by': loggedBy,
      'logged_at': Timestamp.fromDate(loggedAt),
      'logged_at_ms': loggedAt.millisecondsSinceEpoch,
    };
  }

  CoachDailySessionModel copyWith({
    String? id,
    String? coachId,
    String? coachName,
    DateTime? date,
    int? sessionsCount,
    String? notes,
    String? loggedBy,
    DateTime? loggedAt,
  }) {
    return CoachDailySessionModel(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      date: date ?? this.date,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      notes: notes ?? this.notes,
      loggedBy: loggedBy ?? this.loggedBy,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }
}
