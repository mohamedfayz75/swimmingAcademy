import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/rbac/app_role.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? phoneNumber;
  final Timestamp? createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phoneNumber,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['display_name'] as String? ?? 'مستخدم',
      role: userRoleFromString(data['role'] as String?),
      phoneNumber: data['phone'] as String?,
      createdAt: data['created_at'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'display_name': displayName,
      'role': role.value,
      'phone': phoneNumber,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
