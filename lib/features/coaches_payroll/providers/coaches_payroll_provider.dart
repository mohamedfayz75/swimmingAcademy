import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../owner_dashboard/models/payroll_model.dart';
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
}

final coachesPayrollActionProvider =
    StateNotifierProvider<CoachesPayrollActionNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(coachesPayrollRepositoryProvider);
  return CoachesPayrollActionNotifier(repo);
});
