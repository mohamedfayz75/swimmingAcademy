import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/water_card_model.dart';
import '../repository/water_card_repository.dart';

final waterCardRepositoryProvider = Provider<WaterCardRepository>((ref) {
  return WaterCardRepository();
});

// Stream active water card
final activeWaterCardStreamProvider = StreamProvider<WaterCardModel?>((ref) {
  final repo = ref.watch(waterCardRepositoryProvider);
  return repo.streamActiveWaterCard();
});

class WaterCardActionNotifier extends StateNotifier<AsyncValue<void>> {
  final WaterCardRepository _repository;

  WaterCardActionNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> updateDaySessions({
    required String cardId,
    required int dayNumber,
    required int sessionsCount,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateDaySessions(
        cardId: cardId,
        dayNumber: dayNumber,
        sessionsCount: sessionsCount,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> createNewCard({
    required String cardName,
    required double cardPrice,
    required int totalSessions,
    required String monthlyClosingRef,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createWaterCard(
        cardName: cardName,
        cardPrice: cardPrice,
        totalSessions: totalSessions,
        monthlyClosingRef: monthlyClosingRef,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final waterCardActionProvider =
    StateNotifierProvider<WaterCardActionNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(waterCardRepositoryProvider);
  return WaterCardActionNotifier(repo);
});
