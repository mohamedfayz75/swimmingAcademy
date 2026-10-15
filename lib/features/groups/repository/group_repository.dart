import '../../../data/local/local_store.dart';
import '../../subscriptions/models/subscription_model.dart';
import '../models/group_model.dart';

class GroupRepository {
  final LocalStore _store = LocalStore.instance;

  // Stream all groups
  Stream<List<GroupModel>> streamGroups() {
    return _store.groupsStream;
  }

  // Get active available groups
  Future<List<GroupModel>> getAvailableGroups() async {
    return _store.getGroups().where((g) => g.isAvailable).toList();
  }

  // Get all groups
  List<GroupModel> getGroups() {
    return _store.getGroups();
  }

  // Get group by code
  Future<GroupModel?> getGroupByCode(String groupCode) async {
    return _store.getGroupByCode(groupCode);
  }

  // Increment current_registered
  Future<void> incrementGroupRegistered(String groupCode) async {
    _store.incrementGroupRegistered(groupCode);
  }

  // Decrement current_registered
  Future<void> decrementGroupRegistered(String groupCode) async {
    _store.decrementGroupRegistered(groupCode);
  }

  // Add group
  Future<void> createGroup(GroupModel group) async {
    _store.addGroup(group);
  }

  // Update group
  Future<void> updateGroup(GroupModel group) async {
    _store.updateGroup(group);
  }

  // Delete group
  Future<void> deleteGroup(String groupCode) async {
    _store.deleteGroup(groupCode);
  }

  // Transfer swimmer to new group
  Future<bool> transferSwimmerGroup({
    required String subscriptionId,
    required String newGroupCode,
  }) async {
    return _store.transferPlayerToGroup(
      subscriptionId: subscriptionId,
      newGroupCode: newGroupCode,
    );
  }

  // Get swimmers registered in group
  List<SubscriptionModel> getSwimmersInGroup(String groupCode) {
    return _store.getActiveSubscriptionsForGroup(groupCode);
  }

  // Seed sample groups if empty
  Future<void> seedInitialGroupsIfEmpty() async {
    // Handled in LocalStore initialization
  }
}
