import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_model.dart';
import '../repository/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository();
});

// Stream of subscriptions
final subscriptionsStreamProvider = StreamProvider<List<SubscriptionModel>>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.streamSubscriptions();
});

// Stream subscriptions for selected group
final groupSubscriptionsStreamProvider =
    StreamProvider.family<List<SubscriptionModel>, String>((ref, groupCode) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.streamSubscriptionsByGroup(groupCode);
});

// Subscription submission notifier
class SubscriptionEntryNotifier extends StateNotifier<AsyncValue<SubscriptionModel?>> {
  final SubscriptionRepository _repository;

  SubscriptionEntryNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<SubscriptionModel> submitSubscription(SubscriptionModel model) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createSubscription(model);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final subscriptionEntryProvider =
    StateNotifierProvider<SubscriptionEntryNotifier, AsyncValue<SubscriptionModel?>>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return SubscriptionEntryNotifier(repo);
});
