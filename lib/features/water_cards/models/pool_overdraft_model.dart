import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class PoolOverdraftNoteModel {
  final String id;
  final String poolType; // AppConstants.poolSemiOlympic or AppConstants.poolRecreational
  final int sessionsCount;
  final Timestamp date;
  final String notes;
  final bool isDeducted;
  final String? deductedCardId;
  final String? deductedCardName;
  final Timestamp? deductedDate;

  const PoolOverdraftNoteModel({
    required this.id,
    this.poolType = AppConstants.poolSemiOlympic,
    required this.sessionsCount,
    required this.date,
    this.notes = '',
    this.isDeducted = false,
    this.deductedCardId,
    this.deductedCardName,
    this.deductedDate,
  });

  factory PoolOverdraftNoteModel.fromMap(Map<String, dynamic> map) {
    return PoolOverdraftNoteModel(
      id: map['id'] as String? ?? '',
      poolType: map['pool_type'] as String? ?? AppConstants.poolSemiOlympic,
      sessionsCount: (map['sessions_count'] as num?)?.toInt() ?? 0,
      date: map['date_ms'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(map['date_ms'] as int)
          : (map['date'] is Timestamp ? map['date'] as Timestamp : Timestamp.now()),
      notes: map['notes'] as String? ?? '',
      isDeducted: map['is_deducted'] as bool? ?? false,
      deductedCardId: map['deducted_card_id'] as String?,
      deductedCardName: map['deducted_card_name'] as String?,
      deductedDate: map['deducted_date_ms'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(map['deducted_date_ms'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pool_type': poolType,
      'sessions_count': sessionsCount,
      'date_ms': date.millisecondsSinceEpoch,
      'notes': notes,
      'is_deducted': isDeducted,
      'deducted_card_id': deductedCardId,
      'deducted_card_name': deductedCardName,
      'deducted_date_ms': deductedDate?.millisecondsSinceEpoch,
    };
  }

  PoolOverdraftNoteModel copyWith({
    String? id,
    String? poolType,
    int? sessionsCount,
    Timestamp? date,
    String? notes,
    bool? isDeducted,
    String? deductedCardId,
    String? deductedCardName,
    Timestamp? deductedDate,
  }) {
    return PoolOverdraftNoteModel(
      id: id ?? this.id,
      poolType: poolType ?? this.poolType,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isDeducted: isDeducted ?? this.isDeducted,
      deductedCardId: deductedCardId ?? this.deductedCardId,
      deductedCardName: deductedCardName ?? this.deductedCardName,
      deductedDate: deductedDate ?? this.deductedDate,
    );
  }
}
