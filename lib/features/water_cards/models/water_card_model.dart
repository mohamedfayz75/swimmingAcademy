import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class WaterCardModel {
  final String id;
  final Timestamp cardDate;
  final String cardName;
  final String poolType; // نصف أولمبي / ترفيهي
  final double cardPrice;
  final int totalSessions;
  final int usedSessions;
  final String monthlyClosingRef;

  const WaterCardModel({
    required this.id,
    required this.cardDate,
    required this.cardName,
    this.poolType = AppConstants.poolSemiOlympic,
    required this.cardPrice,
    required this.totalSessions,
    this.usedSessions = 0,
    required this.monthlyClosingRef,
  });

  // Calculated fields
  int get remainingSessions => (totalSessions - usedSessions) > 0 ? (totalSessions - usedSessions) : 0;
  String get status => remainingSessions > 0 ? 'نشط' : 'منتهي';
  bool get isActive => remainingSessions > 0;
  bool get isLow => remainingSessions > 0 && remainingSessions <= 5;
  bool get isDepleted => remainingSessions <= 0;

  factory WaterCardModel.fromMap(Map<String, dynamic> map) {
    return WaterCardModel(
      id: map['id'] as String? ?? '',
      cardDate: map['card_date_ms'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(map['card_date_ms'] as int)
          : (map['card_date'] is Timestamp
              ? map['card_date'] as Timestamp
              : Timestamp.now()),
      cardName: map['card_name'] as String? ?? 'كرت مياة',
      poolType: map['pool_type'] as String? ?? AppConstants.poolSemiOlympic,
      cardPrice: (map['card_price'] as num?)?.toDouble() ?? 0.0,
      totalSessions: (map['total_sessions'] as num?)?.toInt() ?? 40,
      usedSessions: (map['used_sessions'] as num?)?.toInt() ?? 0,
      monthlyClosingRef: map['monthly_closing_ref'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_date_ms': cardDate.millisecondsSinceEpoch,
      'card_name': cardName,
      'pool_type': poolType,
      'card_price': cardPrice,
      'total_sessions': totalSessions,
      'used_sessions': usedSessions,
      'monthly_closing_ref': monthlyClosingRef,
    };
  }

  factory WaterCardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WaterCardModel(
      id: doc.id,
      cardDate: data['card_date'] as Timestamp? ?? Timestamp.now(),
      cardName: data['card_name'] as String? ?? 'كرت مياة',
      poolType: data['pool_type'] as String? ?? AppConstants.poolSemiOlympic,
      cardPrice: (data['card_price'] as num?)?.toDouble() ?? 0.0,
      totalSessions: (data['total_sessions'] as num?)?.toInt() ?? 40,
      usedSessions: (data['used_sessions'] as num?)?.toInt() ?? 0,
      monthlyClosingRef: data['monthly_closing_ref'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'card_date': cardDate,
      'card_name': cardName,
      'pool_type': poolType,
      'card_price': cardPrice,
      'total_sessions': totalSessions,
      'used_sessions': usedSessions,
      'remaining_sessions': remainingSessions,
      'status': status,
      'monthly_closing_ref': monthlyClosingRef,
    };
  }

  WaterCardModel copyWith({
    String? id,
    Timestamp? cardDate,
    String? cardName,
    String? poolType,
    double? cardPrice,
    int? totalSessions,
    int? usedSessions,
    String? monthlyClosingRef,
  }) {
    return WaterCardModel(
      id: id ?? this.id,
      cardDate: cardDate ?? this.cardDate,
      cardName: cardName ?? this.cardName,
      poolType: poolType ?? this.poolType,
      cardPrice: cardPrice ?? this.cardPrice,
      totalSessions: totalSessions ?? this.totalSessions,
      usedSessions: usedSessions ?? this.usedSessions,
      monthlyClosingRef: monthlyClosingRef ?? this.monthlyClosingRef,
    );
  }
}
