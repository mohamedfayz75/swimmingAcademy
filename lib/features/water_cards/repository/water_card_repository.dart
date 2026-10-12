import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/local/local_store.dart';
import '../models/water_card_model.dart';

class WaterCardRepository {
  final LocalStore _store = LocalStore.instance;

  // Stream active water card
  Stream<WaterCardModel?> streamActiveWaterCard() {
    return _store.waterCardsStream.map((cards) {
      if (cards.isEmpty) return null;
      try {
        return cards.firstWhere((c) => c.isActive);
      } catch (_) {
        return cards.first;
      }
    });
  }

  // Update consumed sessions
  Future<void> updateDaySessions({
    required String cardId,
    required int dayNumber,
    required int sessionsCount,
  }) async {
    _store.updateWaterCardSessions(cardId, sessionsCount);
  }

  // Create a new water card
  Future<void> createWaterCard({
    required String cardName,
    required double cardPrice,
    required int totalSessions,
    required String monthlyClosingRef,
  }) async {
    final model = WaterCardModel(
      id: 'WC-${DateTime.now().millisecondsSinceEpoch}',
      cardDate: Timestamp.now(),
      cardName: cardName,
      cardPrice: cardPrice,
      totalSessions: totalSessions,
      monthlyClosingRef: monthlyClosingRef,
    );
    _store.addWaterCard(model);
  }

  // Seed sample active water card
  Future<void> seedInitialWaterCardIfEmpty() async {
    // Initialized in LocalStore
  }
}
