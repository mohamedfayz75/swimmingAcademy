import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../models/group_model.dart';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _groupsRef => _firestore.collection(AppConstants.groupsCollection);

  // Stream all groups
  Stream<List<GroupModel>> streamGroups() {
    return _groupsRef.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList(),
        );
  }

  // Get active available groups
  Future<List<GroupModel>> getAvailableGroups() async {
    final snapshot = await _groupsRef.get();
    return snapshot.docs
        .map((doc) => GroupModel.fromFirestore(doc))
        .where((group) => group.isAvailable)
        .toList();
  }

  // Get group by code
  Future<GroupModel?> getGroupByCode(String groupCode) async {
    final doc = await _groupsRef.doc(groupCode).get();
    if (doc.exists) {
      return GroupModel.fromFirestore(doc);
    }
    return null;
  }

  // Atomically increment current_registered
  Future<void> incrementGroupRegistered(String groupCode) async {
    await _groupsRef.doc(groupCode).update({
      'current_registered': FieldValue.increment(1),
    });
  }

  // Add group (Owner action)
  Future<void> createGroup(GroupModel group) async {
    await _groupsRef.doc(group.groupCode).set(group.toFirestore());
  }

  // Seed sample groups if empty
  Future<void> seedInitialGroupsIfEmpty() async {
    final snapshot = await _groupsRef.limit(1).get();
    if (snapshot.docs.isEmpty) {
      final sampleGroups = [
        GroupModel(
          groupCode: 'GRP-01',
          coachId: 'COACH-01',
          coachName: 'كابتن أحمد سامي',
          trainingDays: ['السبت', 'الثلاثاء'],
          sessionTime: '05:00 PM',
          trainingType: 'تعليم',
          level: 'مبتدئ 1',
          maxCapacity: 12,
          currentRegistered: 4,
        ),
        GroupModel(
          groupCode: 'GRP-02',
          coachId: 'COACH-02',
          coachName: 'كابتن محمود رزق',
          trainingDays: ['الأحد', 'الأربعاء'],
          sessionTime: '06:00 PM',
          trainingType: 'نجمة 1',
          level: 'متوسط',
          maxCapacity: 10,
          currentRegistered: 6,
        ),
        GroupModel(
          groupCode: 'GRP-03',
          coachId: 'COACH-01',
          coachName: 'كابتن أحمد سامي',
          trainingDays: ['الاثنين', 'الخميس'],
          sessionTime: '07:00 PM',
          trainingType: 'تجهيزي',
          level: 'متقدم',
          maxCapacity: 8,
          currentRegistered: 3,
        ),
      ];

      for (final g in sampleGroups) {
        await _groupsRef.doc(g.groupCode).set(g.toFirestore());
      }
    }
  }
}
