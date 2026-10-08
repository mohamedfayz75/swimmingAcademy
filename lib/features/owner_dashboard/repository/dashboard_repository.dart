import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../models/accounting_model.dart';
import '../models/expense_model.dart';
import '../models/payroll_model.dart';
import '../../subscriptions/models/subscription_model.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream current month financial overview
  Future<GeneralAccountingModel> calculateMonthlyFinancials(String monthYear) async {
    // 1. Subscriptions revenues
    final subSnapshot = await _firestore.collection(AppConstants.subscriptionsCollection).get();
    double subRevenues = 0.0;
    double stampRevenues = 0.0;
    for (final doc in subSnapshot.docs) {
      final sub = SubscriptionModel.fromFirestore(doc);
      subRevenues += sub.amountPaid;
      stampRevenues += sub.stampCardFee;
    }

    // 2. Coach Payroll
    final payrollSnapshot = await _firestore
        .collection(AppConstants.payrollCollection)
        .where('month_year', isEqualTo: monthYear)
        .get();
    double payrollTotal = 0.0;
    for (final doc in payrollSnapshot.docs) {
      final p = PayrollModel.fromFirestore(doc);
      payrollTotal += p.totalEarnings;
    }

    // 3. Water cards expenses
    final waterSnapshot = await _firestore
        .collection(AppConstants.waterCardsCollection)
        .where('monthly_closing_ref', isEqualTo: monthYear)
        .get();
    double waterTotal = 0.0;
    for (final doc in waterSnapshot.docs) {
      final price = (doc.data()['card_price'] as num?)?.toDouble() ?? 0.0;
      waterTotal += price;
    }

    // 4. Other expenses
    final expSnapshot = await _firestore
        .collection(AppConstants.expensesCollection)
        .where('month_year', isEqualTo: monthYear)
        .get();
    double otherExpenses = 0.0;
    for (final doc in expSnapshot.docs) {
      final e = ExpenseModel.fromFirestore(doc);
      otherExpenses += e.amount;
    }

    final model = GeneralAccountingModel(
      monthYear: monthYear,
      totalSubscriptionRevenues: subRevenues,
      totalStampCardRevenues: stampRevenues,
      totalCoachPayroll: payrollTotal,
      totalWaterCardExpenses: waterTotal,
      otherExpenses: otherExpenses,
    );

    // Save/update in general_accounting
    await _firestore
        .collection(AppConstants.generalAccountingCollection)
        .doc(monthYear)
        .set(model.toFirestore());

    return model;
  }

  // Stream general accounting records
  Stream<List<GeneralAccountingModel>> streamAccountingRecords() {
    return _firestore
        .collection(AppConstants.generalAccountingCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => GeneralAccountingModel.fromFirestore(doc)).toList());
  }

  // Stream expenses for month
  Stream<List<ExpenseModel>> streamExpenses(String monthYear) {
    return _firestore
        .collection(AppConstants.expensesCollection)
        .where('month_year', isEqualTo: monthYear)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList());
  }

  // Add expense
  Future<void> addExpense(ExpenseModel expense) async {
    final doc = _firestore.collection(AppConstants.expensesCollection).doc();
    await doc.set(expense.toFirestore());
  }
}
