import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../owner_dashboard/models/payroll_model.dart';

class CoachesPayrollRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _coachesRef => _firestore.collection(AppConstants.coachesCollection);
  CollectionReference get _payrollRef => _firestore.collection(AppConstants.payrollCollection);

  // Stream all coaches
  Stream<List<CoachModel>> streamCoaches() {
    return _coachesRef.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => CoachModel.fromFirestore(doc)).toList(),
        );
  }

  // Add or update coach
  Future<void> saveCoach(CoachModel coach) async {
    await _coachesRef.doc(coach.coachId).set(coach.toFirestore());
  }

  // Stream payroll for a specific month (e.g. "10-2026")
  Stream<List<PayrollModel>> streamMonthlyPayroll(String monthYear) {
    return _payrollRef
        .where('month_year', isEqualTo: monthYear)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PayrollModel.fromFirestore(doc)).toList());
  }

  // Save/Update payroll entry
  Future<void> savePayrollRecord(PayrollModel payroll) async {
    final docId = '${payroll.coachId}_${payroll.monthYear}';
    await _payrollRef.doc(docId).set(payroll.toFirestore());
  }

  // Seed sample coaches if collection is empty
  Future<void> seedInitialCoachesIfEmpty() async {
    final snapshot = await _coachesRef.limit(1).get();
    if (snapshot.docs.isEmpty) {
      final sampleCoaches = [
        const CoachModel(
          coachId: 'COACH-01',
          coachName: 'كابتن أحمد سامي',
          phoneNumber: '01012345678',
          status: 'نشط',
          groupsCount: 2,
        ),
        const CoachModel(
          coachId: 'COACH-02',
          coachName: 'كابتن محمود رزق',
          phoneNumber: '01198765432',
          status: 'نشط',
          groupsCount: 1,
        ),
        const CoachModel(
          coachId: 'COACH-03',
          coachName: 'كابتن طارق عبد الله',
          phoneNumber: '01234567890',
          status: 'نشط',
          groupsCount: 1,
        ),
      ];

      for (final coach in sampleCoaches) {
        await _coachesRef.doc(coach.coachId).set(coach.toFirestore());
      }
    }
  }
}
