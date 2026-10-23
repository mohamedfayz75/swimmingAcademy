import '../../../data/local/local_store.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  final LocalStore _store = LocalStore.instance;

  // Create new subscription
  Future<SubscriptionModel> createSubscription(SubscriptionModel subscription) async {
    return _store.addSubscription(subscription);
  }

  // Get active subscription for player
  Future<SubscriptionModel?> getActiveSubscription(String playerCode) async {
    return _store.getActiveSubscription(playerCode);
  }

  // Stream all subscriptions
  Stream<List<SubscriptionModel>> streamSubscriptions() {
    return _store.subscriptionsStream;
  }

  // Stream subscriptions for a specific group (deduplicated by player, active only)
  Stream<List<SubscriptionModel>> streamSubscriptionsByGroup(String groupCode) {
    return _store.subscriptionsStream.map(
      (list) => _store.getActiveSubscriptionsForGroup(groupCode),
    );
  }
}
