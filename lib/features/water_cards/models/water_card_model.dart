import 'package:cloud_firestore/cloud_firestore.dart';

class WaterCardModel {
  final String id;
  final Timestamp cardDate;
  final String cardName;
  final double cardPrice;
  final int totalSessions;
  final int usedDay1;
  final int usedDay2;
  final int usedDay3;
  final int usedDay4;
  final String monthlyClosingRef;

  const WaterCardModel({
    required this.id,
    required this.cardDate,
    required this.cardName,
    required this.cardPrice,
    required this.totalSessions,
    this.usedDay1 = 0,
    this.usedDay2 = 0,
    this.usedDay3 = 0,
    this.usedDay4 = 0,
    required this.monthlyClosingRef,
  });

  // Calculated fields
  int get totalUsedSessions => usedDay1 + usedDay2 + usedDay3 + usedDay4;
  int get remainingSessions => (totalSessions - totalUsedSessions) > 0 ? (totalSessions - totalUsedSessions) : 0;
  String get status => remainingSessions > 0 ? 'نشط' : 'منتهي';
  bool get isActive => remainingSessions > 0;
  bool get isLow => remainingSessions > 0 && remainingSessions <= 5;
  bool get isDepleted => remainingSessions <= 0;

  factory WaterCardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WaterCardModel(
      id: doc.id,
      cardDate: data['card_date'] as Timestamp? ?? Timestamp.now(),
      cardName: data['card_name'] as String? ?? 'كرت مياة',
      cardPrice: (data['card_price'] as num?)?.toDouble() ?? 0.0,
      totalSessions: (data['total_sessions'] as num?)?.toInt() ?? 40,
      usedDay1: (data['used_day_1'] as num?)?.toInt() ?? 0,
      usedDay2: (data['used_day_2'] as num?)?.toInt() ?? 0,
      usedDay3: (data['used_day_3'] as num?)?.toInt() ?? 0,
      usedDay4: (data['used_day_4'] as num?)?.toInt() ?? 0,
      monthlyClosingRef: data['monthly_closing_ref'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'card_date': cardDate,
      'card_name': cardName,
      'card_price': cardPrice,
      'total_sessions': totalSessions,
      'used_day_1': usedDay1,
      'used_day_2': usedDay2,
      'used_day_3': usedDay3,
      'used_day_4': usedDay4,
      'total_used_sessions': totalUsedSessions,
      'remaining_sessions': remainingSessions,
      'status': status,
      'monthly_closing_ref': monthlyClosingRef,
    };
  }

  WaterCardModel copyWith({
    String? id,
    Timestamp? cardDate,
    String? cardName,
    double? cardPrice,
    int? totalSessions,
    int? usedDay1,
    int? usedDay2,
    int? usedDay3,
    int? usedDay4,
    String? monthlyClosingRef,
  }) {
    return WaterCardModel(
      id: id ?? this.id,
      cardDate: cardDate ?? this.cardDate,
      cardName: cardName ?? this.cardName,
      cardPrice: cardPrice ?? this.cardPrice,
      totalSessions: totalSessions ?? this.totalSessions,
      usedDay1: usedDay1 ?? this.usedDay1,
      usedDay2: usedDay2 ?? this.usedDay2,
      usedDay3: usedDay3 ?? this.usedDay3,
      usedDay4: usedDay4 ?? this.usedDay4,
      monthlyClosingRef: monthlyClosingRef ?? this.monthlyClosingRef,
    );
  }
}
