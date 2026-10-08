import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/rbac/app_role.dart';
import '../models/user_model.dart';
import '../repository/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

// Current User Profile State Notifier
class CurrentUserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;

  CurrentUserNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _repository.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        state = const AsyncValue.data(null);
      } else {
        try {
          final profile = await _repository.getUserProfile(firebaseUser.uid);
          if (profile != null) {
            state = AsyncValue.data(profile);
          } else {
            // Provide fallback staff profile if firestore document hasn't synced
            final fallback = UserModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              displayName: firebaseUser.displayName ?? 'موظف الأكاديمية',
              role: UserRole.staff,
            );
            state = AsyncValue.data(fallback);
          }
        } catch (e, st) {
          state = AsyncValue.error(e, st);
        }
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithEmailPassword(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }

  // Developer switch for quick demo/testing between Staff and Owner
  void switchDemoRole(UserRole role) {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        UserModel(
          uid: current.uid,
          email: current.email,
          displayName: current.displayName,
          role: role,
        ),
      );
    } else {
      state = AsyncValue.data(
        UserModel(
          uid: 'demo-user',
          email: 'demo@swimmingworld.com',
          displayName: role == UserRole.owner ? 'المالك العام' : 'موظف الاستقبال',
          role: role,
        ),
      );
    }
  }
}

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AsyncValue<UserModel?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return CurrentUserNotifier(repo);
});
