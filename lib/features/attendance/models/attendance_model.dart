import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String playerCode;
  final String playerName;
  final String groupCode;
  final Timestamp timestamp;
  final int sessionNumber;
  final String status; // "حاضر", "غائب", "معتذر"
  final String recordedBy;

  const AttendanceModel({
    required this.id,
    required this.playerCode,
    required this.playerName,
    required this.groupCode,
    required this.timestamp,
    required this.sessionNumber,
    required this.status,
    required this.recordedBy,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AttendanceModel(
      id: doc.id,
      playerCode: data['player_code'] as String? ?? '',
      playerName: data['player_name'] as String? ?? '',
      groupCode: data['group_code'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      sessionNumber: (data['session_number'] as num?)?.toInt() ?? 1,
      status: data['status'] as String? ?? 'حاضر',
      recordedBy: data['recorded_by'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'player_code': playerCode,
      'player_name': playerName,
      'group_code': groupCode,
      'timestamp': timestamp,
      'session_number': sessionNumber,
      'status': status,
      'recorded_by': recordedBy,
    };
  }
}
