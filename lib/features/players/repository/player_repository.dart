import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/local/local_store.dart';
import '../models/player_model.dart';

class PlayerRepository {
  final LocalStore _store = LocalStore.instance;

  // Generate unique formatted player code, e.g. "SW-103"
  Future<String> generateNextPlayerCode() async {
    return _store.generateNextPlayerCode();
  }

  // Register player
  Future<PlayerModel> registerPlayer({
    required String playerName,
    required String branch,
    required DateTime birthDate,
    required String guardianPhone,
    required String customerType,
  }) async {
    final playerCode = await generateNextPlayerCode();
    final now = Timestamp.now();

    final player = PlayerModel(
      playerCode: playerCode,
      playerName: playerName.trim(),
      branch: branch.trim(),
      birthDate: Timestamp.fromDate(birthDate),
      guardianPhone: guardianPhone.trim(),
      customerType: customerType,
      qrCodeUrl: playerCode,
      createdAt: now,
    );

    // Save to LocalStore
    _store.addPlayer(player);

    // Optional firestore sync in background
    try {
      FirebaseFirestore.instance.collection('players').doc(playerCode).set(player.toFirestore());
    } catch (_) {}

    return player;
  }

  // Get player by code
  Future<PlayerModel?> getPlayerByCode(String playerCode) async {
    return _store.getPlayerByCode(playerCode);
  }

  // Stream all players (always immediate & real-time)
  Stream<List<PlayerModel>> streamPlayers() {
    // Emit current cache immediately
    Future.microtask(() => _store.playersStream);
    return _store.playersStream;
  }

  // Search players
  Future<List<PlayerModel>> searchPlayers(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return _store.getPlayers();
    return _store.getPlayers().where((p) =>
      p.playerCode.toLowerCase().contains(clean) ||
      p.playerName.toLowerCase().contains(clean) ||
      p.guardianPhone.contains(clean),
    ).toList();
  }
}
