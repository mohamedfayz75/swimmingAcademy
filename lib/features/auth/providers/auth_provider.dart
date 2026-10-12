import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/rbac/app_role.dart';
import '../models/user_model.dart';
import '../repository/auth_repository.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/local/local_store.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return LocalStore.instance.usersStream;
});

// Current User Profile State Notifier
class CurrentUserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;
  final LocalStore _store = LocalStore.instance;

  CurrentUserNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> signIn(String usernameOrEmail, String password) async {
    state = const AsyncValue.loading();
    final trimmed = usernameOrEmail.trim();

    // 1. Check local registered users (LocalStore)
    final user = _store.authenticate(trimmed, password);
    if (user != null) {
      state = AsyncValue.data(user);
      return;
    }

    // 2. Check default fallback if first time
    if ((trimmed.toLowerCase() == 'owner' || trimmed.toLowerCase() == 'admin') && (password == '123' || password == '123456')) {
      final ownerUser = UserModel(
        uid: 'user-owner-default',
        username: 'owner',
        password: password,
        displayName: 'المالك العام',
        role: UserRole.owner,
      );
      state = AsyncValue.data(ownerUser);
      return;
    }

    if (trimmed.toLowerCase() == 'staff' && (password == '123' || password == '123456')) {
      final staffUser = UserModel(
        uid: 'user-staff-default',
        username: 'staff',
        password: password,
        displayName: 'موظف الاستقبال',
        role: UserRole.staff,
      );
      state = AsyncValue.data(staffUser);
      return;
    }

    // 3. Fallback to Firebase if configured
    try {
      final firebaseUser = await _repository.signInWithEmailPassword(email: trimmed, password: password);
      state = AsyncValue.data(firebaseUser);
    } catch (_) {
      state = const AsyncValue.data(null);
      throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } catch (_) {}
    state = const AsyncValue.data(null);
  }

  // Quick QR Attendance Mode
  void enterQuickQrMode() {
    state = const AsyncValue.data(
      UserModel(
        uid: 'quick-qr-scanner',
        username: 'qr_scanner',
        password: '',
        displayName: 'ماسح حضور سريع',
        role: UserRole.staff,
      ),
    );
  }

  // Manage Users actions
  void addNewUser({
    required String username,
    required String password,
    required String displayName,
    required UserRole role,
    String? phoneNumber,
  }) {
    final newUser = UserModel(
      uid: 'user-${DateTime.now().millisecondsSinceEpoch}',
      username: username.trim(),
      password: password.trim(),
      displayName: displayName.trim(),
      role: role,
      phoneNumber: phoneNumber?.trim(),
      createdAt: Timestamp.now(),
    );
    _store.addUser(newUser);
  }

  void updateUserPassword(String uid, String newPassword) {
    _store.updateUserPassword(uid, newPassword.trim());
  }

  void toggleUserActive(String uid, bool isActive) {
    _store.toggleUserActive(uid, isActive);
  }

  void deleteUser(String uid) {
    _store.deleteUser(uid);
  }
}

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AsyncValue<UserModel?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return CurrentUserNotifier(repo);
});
