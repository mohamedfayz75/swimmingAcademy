import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';
import '../repository/group_repository.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});

// Stream of all groups
final groupsStreamProvider = StreamProvider<List<GroupModel>>((ref) {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.streamGroups();
});

// Filtered stream of available groups
final availableGroupsProvider = Provider<List<GroupModel>>((ref) {
  final groupsAsync = ref.watch(groupsStreamProvider);
  return groupsAsync.maybeWhen(
    data: (groups) => groups.where((g) => g.isAvailable).toList(),
    orElse: () => [],
  );
});

// Selected group for filtering attendees or details
final selectedGroupCodeProvider = StateProvider<String?>((ref) => null);
