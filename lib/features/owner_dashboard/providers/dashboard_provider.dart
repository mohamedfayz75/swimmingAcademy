import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/accounting_model.dart';
import '../models/expense_model.dart';
import '../repository/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

// Current selected month-year for report, e.g. "10-2026"
final selectedMonthYearProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return '${now.month.toString().padLeft(2, '0')}-${now.year}';
});

// FutureProvider for monthly accounting calculation
final monthlyAccountingProvider =
    FutureProvider.family<GeneralAccountingModel, String>((ref, monthYear) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.calculateMonthlyFinancials(monthYear);
});

// StreamProvider for expenses of the selected month
final monthlyExpensesStreamProvider =
    StreamProvider.family<List<ExpenseModel>, String>((ref, monthYear) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.streamExpenses(monthYear);
});
