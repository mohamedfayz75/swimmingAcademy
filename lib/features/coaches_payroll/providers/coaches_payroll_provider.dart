import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../owner_dashboard/models/payroll_model.dart';
import '../models/coach_daily_session_model.dart';
import '../repository/coaches_payroll_repository.dart';

final coachesPayrollRepositoryProvider = Provider<CoachesPayrollRepository>((ref) {
  return CoachesPayrollRepository();
});

// Stream of all coaches
final coachesStreamProvider = StreamProvider<List<CoachModel>>((ref) {
  final repo = ref.watch(coachesPayrollRepositoryProvider);
  return repo.streamCoaches();
});

// Stream of payroll for given month
final monthlyPayrollStreamProvider =
    StreamProvider.family<List<PayrollModel>, String>((ref, monthYear) {
  final repo = ref.watch(coachesPayrollRepositoryProvider);
  return repo.streamMonthlyPayroll(monthYear);
});

// Stream of coach daily sessions (all or by coach)
final coachDailySessionsStreamProvider =
    StreamProvider.family<List<CoachDailySessionModel>, String?>((ref, coachId) {
  final repo = ref.watch(coachesPayrollRepositoryProvider);
  return repo.streamDailySessions(coachId: coachId);
});

// Coach & Payroll Action Notifier
class CoachesPayrollActionNotifier extends StateNotifier<AsyncValue<void>> {
  final CoachesPayrollRepository _repository;

  CoachesPayrollActionNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> addCoach(CoachModel coach) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveCoach(coach);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateCoach(CoachModel coach) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateCoach(coach);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> setCoachStatus(CoachModel coach, String newStatus) async {
    state = const AsyncValue.loading();
    try {
      final updated = coach.copyWith(status: newStatus);
      await _repository.updateCoach(updated);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteCoach(String coachId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCoach(coachId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> savePayroll(PayrollModel payroll) async {
    state = const AsyncValue.loading();
    try {
      await _repository.savePayrollRecord(payroll);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deletePayroll(String coachId, String monthYear) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deletePayrollRecord(coachId, monthYear);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addDailySession(CoachDailySessionModel session) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addDailySession(session);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteDailySession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteDailySession(sessionId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final coachesPayrollActionProvider =
    StateNotifierProvider<CoachesPayrollActionNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(coachesPayrollRepositoryProvider);
  return CoachesPayrollActionNotifier(repo);
});
