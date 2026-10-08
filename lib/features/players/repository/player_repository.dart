import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../models/player_model.dart';

class PlayerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _playersRef => _firestore.collection(AppConstants.playersCollection);

  // Generate unique formatted player code, e.g. "SW-101"
  Future<String> generateNextPlayerCode() async {
    try {
      final snapshot = await _playersRef.orderBy('created_at', descending: true).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final lastCode = snapshot.docs.first.get('player_code') as String?;
        if (lastCode != null && lastCode.startsWith('SW-')) {
          final numberPart = int.tryParse(lastCode.replaceAll('SW-', ''));
          if (numberPart != null) {
            return 'SW-${numberPart + 1}';
          }
        }
      }
    } catch (_) {
      // Fallback if index not ready
    }
    // Default starting code
    final countSnapshot = await _playersRef.count().get();
    final count = (countSnapshot.count ?? 0) + 101;
    return 'SW-$count';
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
      qrCodeUrl: playerCode, // Using player code directly as QR payload
      createdAt: now,
    );

    await _playersRef.doc(playerCode).set(player.toFirestore());
    return player;
  }

  // Get player by code
  Future<PlayerModel?> getPlayerByCode(String playerCode) async {
    final doc = await _playersRef.doc(playerCode.trim().toUpperCase()).get();
    if (doc.exists) {
      return PlayerModel.fromFirestore(doc);
    }
    return null;
  }

  // Stream all players (ordered by newest first)
  Stream<List<PlayerModel>> streamPlayers() {
    return _playersRef
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PlayerModel.fromFirestore(doc)).toList());
  }

  // Search players by query (code, name, or phone)
  Future<List<PlayerModel>> searchPlayers(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final snapshot = await _playersRef.limit(50).get();
    return snapshot.docs
        .map((doc) => PlayerModel.fromFirestore(doc))
        .where((player) =>
            player.playerCode.toLowerCase().contains(cleanQuery) ||
            player.playerName.toLowerCase().contains(cleanQuery) ||
            player.guardianPhone.contains(cleanQuery))
        .toList();
  }
}
