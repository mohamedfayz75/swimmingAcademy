import '../../../data/local/local_store.dart';
import '../../owner_dashboard/models/payroll_model.dart';

class CoachesPayrollRepository {
  final LocalStore _store = LocalStore.instance;

  // Stream all coaches
  Stream<List<CoachModel>> streamCoaches() {
    return _store.coachesStream;
  }

  // Add or update coach
  Future<void> saveCoach(CoachModel coach) async {
    _store.addCoach(coach);
  }

  // Stream payroll for a specific month
  Stream<List<PayrollModel>> streamMonthlyPayroll(String monthYear) {
    return Stream.value(_store.getPayrollForMonth(monthYear));
  }

  // Save/Update payroll entry
  Future<void> savePayrollRecord(PayrollModel payroll) async {
    _store.savePayroll(payroll);
  }

  // Seed sample coaches
  Future<void> seedInitialCoachesIfEmpty() async {
    // Handled in LocalStore
  }
}
