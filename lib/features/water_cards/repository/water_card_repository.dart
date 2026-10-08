import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../models/water_card_model.dart';

class WaterCardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _waterCardsRef => _firestore.collection(AppConstants.waterCardsCollection);

  // Stream active water card
  Stream<WaterCardModel?> streamActiveWaterCard() {
    return _waterCardsRef
        .orderBy('card_date', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return WaterCardModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  // Update daily consumed sessions (day 1, 2, 3, or 4)
  Future<void> updateDaySessions({
    required String cardId,
    required int dayNumber, // 1, 2, 3, or 4
    required int sessionsCount,
  }) async {
    final fieldName = 'used_day_$dayNumber';
    await _waterCardsRef.doc(cardId).update({
      fieldName: sessionsCount,
    });
  }

  // Create a new water card
  Future<void> createWaterCard({
    required String cardName,
    required double cardPrice,
    required int totalSessions,
    required String monthlyClosingRef,
  }) async {
    final doc = _waterCardsRef.doc();
    final model = WaterCardModel(
      id: doc.id,
      cardDate: Timestamp.now(),
      cardName: cardName,
      cardPrice: cardPrice,
      totalSessions: totalSessions,
      monthlyClosingRef: monthlyClosingRef,
    );
    await doc.set(model.toFirestore());
  }

  // Seed sample active water card if none exists
  Future<void> seedInitialWaterCardIfEmpty() async {
    final snapshot = await _waterCardsRef.limit(1).get();
    if (snapshot.docs.isEmpty) {
      final now = DateTime.now();
      final monthRef = '${now.month.toString().padLeft(2, '0')}-${now.year}';
      await createWaterCard(
        cardName: 'كرت مياة رقم 1 - مسبح رئيسي',
        cardPrice: 1200.0,
        totalSessions: 40,
        monthlyClosingRef: monthRef,
      );
    }
  }
}
