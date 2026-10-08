import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_model.dart';
import '../repository/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

// Stream of today's attendance
final todayAttendanceStreamProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.streamTodayAttendance();
});

// Attendance scan state notifier
class AttendanceScanNotifier extends StateNotifier<AsyncValue<AttendanceResult?>> {
  final AttendanceRepository _repository;

  AttendanceScanNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<AttendanceResult> recordAttendance({
    required String playerCode,
    required String recordedByStaffUid,
    String status = 'حاضر',
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.recordAttendance(
        playerCode: playerCode,
        recordedByStaffUid: recordedByStaffUid,
        status: status,
      );
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void clearResult() {
    state = const AsyncValue.data(null);
  }
}

final attendanceScanProvider =
    StateNotifierProvider<AttendanceScanNotifier, AsyncValue<AttendanceResult?>>((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return AttendanceScanNotifier(repo);
});
