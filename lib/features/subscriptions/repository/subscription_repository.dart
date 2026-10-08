import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _subscriptionsRef => _firestore.collection(AppConstants.subscriptionsCollection);
  CollectionReference get _groupsRef => _firestore.collection(AppConstants.groupsCollection);

  // Create new subscription and atomically update group capacity
  Future<SubscriptionModel> createSubscription(SubscriptionModel subscription) async {
    final batch = _firestore.batch();

    // New subscription doc
    final newDoc = _subscriptionsRef.doc();
    final modelWithId = subscription.copyWith(id: newDoc.id);

    batch.set(newDoc, modelWithId.toFirestore());

    // Atomically increment group registered count
    final groupDoc = _groupsRef.doc(subscription.groupCode);
    batch.update(groupDoc, {
      'current_registered': FieldValue.increment(1),
    });

    await batch.commit();
    return modelWithId;
  }

  // Get active subscription for player
  Future<SubscriptionModel?> getActiveSubscription(String playerCode) async {
    final snapshot = await _subscriptionsRef
        .where('player_code', isEqualTo: playerCode)
        .orderBy('start_date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return SubscriptionModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Stream all subscriptions
  Stream<List<SubscriptionModel>> streamSubscriptions() {
    return _subscriptionsRef
        .orderBy('payment_date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SubscriptionModel.fromFirestore(doc)).toList());
  }

  // Stream subscriptions for a specific group
  Stream<List<SubscriptionModel>> streamSubscriptionsByGroup(String groupCode) {
    return _subscriptionsRef
        .where('group_code', isEqualTo: groupCode)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SubscriptionModel.fromFirestore(doc)).toList());
  }
}
