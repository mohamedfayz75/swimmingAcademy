import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../models/attendance_model.dart';
import '../../subscriptions/models/subscription_model.dart';
import '../../players/models/player_model.dart';

class AttendanceResult {
  final bool success;
  final String message;
  final PlayerModel? player;
  final SubscriptionModel? subscription;
  final int currentSession;
  final int totalSessions;

  AttendanceResult({
    required this.success,
    required this.message,
    this.player,
    this.subscription,
    this.currentSession = 0,
    this.totalSessions = 0,
  });
}

class AttendanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _attendanceRef => _firestore.collection(AppConstants.attendanceCollection);
  CollectionReference get _subscriptionsRef => _firestore.collection(AppConstants.subscriptionsCollection);
  CollectionReference get _playersRef => _firestore.collection(AppConstants.playersCollection);

  // Process QR / Manual Attendance
  Future<AttendanceResult> recordAttendance({
    required String playerCode,
    required String recordedByStaffUid,
    String status = 'حاضر',
  }) async {
    final cleanCode = playerCode.trim().toUpperCase();

    // 1. Fetch player
    final playerDoc = await _playersRef.doc(cleanCode).get();
    if (!playerDoc.exists) {
      return AttendanceResult(
        success: false,
        message: 'عفواً، كود اللاعب ($cleanCode) غير مسجل بالنظام.',
      );
    }
    final player = PlayerModel.fromFirestore(playerDoc);

    // 2. Fetch active subscription
    final subSnapshot = await _subscriptionsRef
        .where('player_code', isEqualTo: cleanCode)
        .orderBy('start_date', descending: true)
        .limit(1)
        .get();

    if (subSnapshot.docs.isEmpty) {
      return AttendanceResult(
        success: false,
        message: 'اللاعب ${player.playerName} ليس لديه اشتراك سارٍ حالياً.',
        player: player,
      );
    }

    final subDoc = subSnapshot.docs.first;
    final subscription = SubscriptionModel.fromFirestore(subDoc);

    // Check if subscription sessions are already depleted
    if (subscription.attendedSessions >= subscription.sessionsCount) {
      return AttendanceResult(
        success: false,
        message: 'انتهت حصص اشتراك اللاعب (${subscription.attendedSessions}/${subscription.sessionsCount}). يرجى تجديد الاشتراك.',
        player: player,
        subscription: subscription,
        currentSession: subscription.attendedSessions,
        totalSessions: subscription.sessionsCount,
      );
    }

    // Next session number
    final nextSessionNumber = subscription.attendedSessions + 1;

    // 3. Atomically record attendance and increment subscription attended_sessions
    final batch = _firestore.batch();

    final newAttendanceDoc = _attendanceRef.doc();
    final attendanceRecord = AttendanceModel(
      id: newAttendanceDoc.id,
      playerCode: cleanCode,
      playerName: player.playerName,
      groupCode: subscription.groupCode,
      timestamp: Timestamp.now(),
      sessionNumber: nextSessionNumber,
      status: status,
      recordedBy: recordedByStaffUid,
    );

    batch.set(newAttendanceDoc, attendanceRecord.toFirestore());
    batch.update(subDoc.reference, {
      'attended_sessions': FieldValue.increment(1),
    });

    await batch.commit();

    return AttendanceResult(
      success: true,
      message: 'تم تسجيل الحضور بنجاح (حصة $nextSessionNumber من ${subscription.sessionsCount})',
      player: player,
      subscription: subscription.copyWith(attendedSessions: nextSessionNumber),
      currentSession: nextSessionNumber,
      totalSessions: subscription.sessionsCount,
    );
  }

  // Stream today's attendance logs
  Stream<List<AttendanceModel>> streamTodayAttendance() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _attendanceRef
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList());
  }
}
