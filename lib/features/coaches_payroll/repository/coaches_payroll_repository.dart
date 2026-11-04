import '../../../data/local/local_store.dart';
import '../../owner_dashboard/models/payroll_model.dart';
import '../models/coach_daily_session_model.dart';

class CoachesPayrollRepository {
  final LocalStore _store = LocalStore.instance;

  // Stream all coaches
  Stream<List<CoachModel>> streamCoaches() {
    return _store.coachesStream;
  }

  // Add coach
  Future<void> saveCoach(CoachModel coach) async {
    _store.addCoach(coach);
  }

  // Update coach
  Future<void> updateCoach(CoachModel coach) async {
    _store.updateCoach(coach);
  }

  // Delete coach
  Future<void> deleteCoach(String coachId) async {
    _store.deleteCoach(coachId);
  }

  // Stream payroll for a specific month (reactive)
  Stream<List<PayrollModel>> streamMonthlyPayroll(String monthYear) {
    return _store.payrollsStream.map(
      (list) => list.where((p) => p.monthYear == monthYear).toList(),
    );
  }

  // Save/Update payroll entry
  Future<void> savePayrollRecord(PayrollModel payroll) async {
    _store.savePayroll(payroll);
  }

  // Delete payroll entry
  Future<void> deletePayrollRecord(String coachId, String monthYear) async {
    _store.deletePayroll(coachId, monthYear);
  }

  // Stream daily sessions
  Stream<List<CoachDailySessionModel>> streamDailySessions() {
    return _store.coachDailySessionsStream;
  }

  // Add daily session
  Future<void> addDailySession(CoachDailySessionModel session) async {
    _store.addCoachDailySession(session);
  }

  // Delete daily session
  Future<void> deleteDailySession(String sessionId) async {
    _store.deleteCoachDailySession(sessionId);
  }
}
