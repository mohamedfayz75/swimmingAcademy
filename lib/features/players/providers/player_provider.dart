import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_model.dart';
import '../repository/player_repository.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepository();
});

// Stream of all players
final playersStreamProvider = StreamProvider<List<PlayerModel>>((ref) {
  final repo = ref.watch(playerRepositoryProvider);
  return repo.streamPlayers();
});

// Future provider for next code
final nextPlayerCodeProvider = FutureProvider.autoDispose<String>((ref) {
  final repo = ref.watch(playerRepositoryProvider);
  return repo.generateNextPlayerCode();
});

// State notifier for player registration form
class PlayerRegistrationNotifier extends StateNotifier<AsyncValue<PlayerModel?>> {
  final PlayerRepository _repository;

  PlayerRegistrationNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<PlayerModel?> register({
    required String playerName,
    required String branch,
    required DateTime birthDate,
    required String guardianPhone,
    required String customerType,
  }) async {
    state = const AsyncValue.loading();
    try {
      final player = await _repository.registerPlayer(
        playerName: playerName,
        branch: branch,
        birthDate: birthDate,
        guardianPhone: guardianPhone,
        customerType: customerType,
      );
      state = AsyncValue.data(player);
      return player;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final playerRegistrationProvider =
    StateNotifierProvider<PlayerRegistrationNotifier, AsyncValue<PlayerModel?>>((ref) {
  final repo = ref.watch(playerRepositoryProvider);
  return PlayerRegistrationNotifier(repo);
});
