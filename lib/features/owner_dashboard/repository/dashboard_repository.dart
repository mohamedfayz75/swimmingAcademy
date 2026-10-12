import '../../../data/local/local_store.dart';
import '../models/accounting_model.dart';
import '../models/expense_model.dart';

class DashboardRepository {
  final LocalStore _store = LocalStore.instance;

  // Calculate monthly financial overview
  Future<GeneralAccountingModel> calculateMonthlyFinancials(String monthYear) async {
    return _store.calculateFinancials(monthYear);
  }

  // Stream expenses for month
  Stream<List<ExpenseModel>> streamExpenses(String monthYear) {
    return _store.expensesStream.map(
      (list) => list.where((e) => e.monthYear == monthYear).toList(),
    );
  }

  // Add expense
  Future<void> addExpense(ExpenseModel expense) async {
    _store.addExpense(expense);
  }
}
