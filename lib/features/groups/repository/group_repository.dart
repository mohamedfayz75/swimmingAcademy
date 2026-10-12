import '../../../data/local/local_store.dart';
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

  // Get group by code
  Future<GroupModel?> getGroupByCode(String groupCode) async {
    return _store.getGroupByCode(groupCode);
  }

  // Atomically increment current_registered
  Future<void> incrementGroupRegistered(String groupCode) async {
    _store.incrementGroupRegistered(groupCode);
  }

  // Add group
  Future<void> createGroup(GroupModel group) async {
    _store.addGroup(group);
  }

  // Seed sample groups if empty
  Future<void> seedInitialGroupsIfEmpty() async {
    // Handled in LocalStore initialization
  }
}
