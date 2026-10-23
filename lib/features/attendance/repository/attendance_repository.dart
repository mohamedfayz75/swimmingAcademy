import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/local/local_store.dart';
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
  final LocalStore _store = LocalStore.instance;

  // Process QR / Manual Attendance
  Future<AttendanceResult> recordAttendance({
    required String playerCode,
    required String recordedByStaffUid,
    String status = 'حاضر',
  }) async {
    final cleanCode = playerCode.trim().toUpperCase();

    // 1. Fetch player
    final player = _store.getPlayerByCode(cleanCode);
    if (player == null) {
      return AttendanceResult(
        success: false,
        message: 'عفواً، كود اللاعب ($cleanCode) غير مسجل بالنظام.',
      );
    }

    // 2. Fetch active subscription
    final subscription = _store.getActiveSubscription(cleanCode);
    if (subscription == null) {
      return AttendanceResult(
        success: false,
        message: 'اللاعب ${player.playerName} ليس لديه اشتراك سارٍ حالياً.',
        player: player,
      );
    }

    // 3. Check 60-minute duplicate cooldown (allows makeup session after 1 hour)
    final recentRecord = _store.getRecentAttendanceForPlayer(cleanCode, withinMinutes: 60);
    if (recentRecord != null) {
      final recDate = recentRecord.timestamp.toDate();
      final elapsedMinutes = DateTime.now().difference(recDate).inMinutes;
      final timeFormatted =
          '${recDate.hour.toString().padLeft(2, '0')}:${recDate.minute.toString().padLeft(2, '0')}';
      return AttendanceResult(
        success: false,
        message:
            '⚠️ اللاعب ${player.playerName} مسجل حضور بالفعل منذ $elapsedMinutes دقيقة (الساعة $timeFormatted).\nلمنع تكرار الخصم بالخطأ، يمكن تسجيل حصة تعويضية ثانية بعد مرور ساعة.',
        player: player,
        subscription: subscription,
        currentSession: subscription.attendedSessions,
        totalSessions: subscription.sessionsCount,
      );
    }

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

    final attendanceRecord = AttendanceModel(
      id: 'ATT-${DateTime.now().millisecondsSinceEpoch}',
      playerCode: cleanCode,
      playerName: player.playerName,
      groupCode: subscription.groupCode,
      timestamp: Timestamp.now(),
      sessionNumber: nextSessionNumber,
      status: status,
      recordedBy: recordedByStaffUid,
    );

    _store.recordAttendance(attendanceRecord);

    return AttendanceResult(
      success: true,
      message: 'تم تسجيل الحضور بنجاح (حصة $nextSessionNumber من ${subscription.sessionsCount})',
      player: player,
      subscription: subscription.copyWith(attendedSessions: nextSessionNumber),
      currentSession: nextSessionNumber,
      totalSessions: subscription.sessionsCount,
    );
  }

  // Stream today's attendance logs (filtered strictly for today)
  Stream<List<AttendanceModel>> streamTodayAttendance() {
    final now = DateTime.now();
    return _store.attendanceStream.map((list) {
      return list.where((a) {
        final d = a.attendanceDate.toDate();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList();
    });
  }

  // Delete attendance record (Owner control)
  Future<void> deleteAttendance(String id) async {
    await _store.deleteAttendance(id);
  }
}
