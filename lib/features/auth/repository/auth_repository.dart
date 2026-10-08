import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/rbac/app_role.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw Exception('فشل تسجيل الدخول. لم يتم العثور على المستخدم.');
    }

    final profile = await getUserProfile(user.uid);
    if (profile != null) {
      return profile;
    }

    // Fallback profile if Firestore user doc does not exist yet
    final newProfile = UserModel(
      uid: user.uid,
      email: user.email ?? email,
      displayName: user.displayName ?? 'مستخدم جديد',
      role: UserRole.staff,
      createdAt: Timestamp.now(),
    );
    await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set(newProfile.toFirestore());
    return newProfile;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Helper method to seed initial users (e.g. Owner and Staff)
  Future<void> createInitialUser({
    required String uid,
    required String email,
    required String displayName,
    required UserRole role,
  }) async {
    final user = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
      createdAt: Timestamp.now(),
    );
    await _firestore.collection(AppConstants.usersCollection).doc(uid).set(user.toFirestore());
  }
}
