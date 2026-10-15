import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/rbac/app_role.dart';

class UserModel {
  final String uid;
  final String username;
  final String password;
  final String email;
  final String displayName;
  final UserRole role;
  final String? phoneNumber;
  final bool isActive;
  final Timestamp? createdAt;

  const UserModel({
    required this.uid,
    required this.username,
    required this.password,
    this.email = '',
    required this.displayName,
    required this.role,
    this.phoneNumber,
    this.isActive = true,
    this.createdAt,
  });

  UserModel copyWith({
    String? uid,
    String? username,
    String? password,
    String? email,
    String? displayName,
    UserRole? role,
    String? phoneNumber,
    bool? isActive,
    Timestamp? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      username: map['username'] as String? ?? '',
      password: map['password'] as String? ?? '123',
      email: map['email'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'مستخدم',
      role: userRoleFromString(map['role'] as String?),
      phoneNumber: map['phone'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at_ms'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(map['created_at_ms'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'password': password,
      'email': email,
      'display_name': displayName,
      'role': role.value,
      'phone': phoneNumber,
      'is_active': isActive,
      'created_at_ms': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      username: data['username'] as String? ?? doc.id,
      password: data['password'] as String? ?? '123456',
      email: data['email'] as String? ?? '',
      displayName: data['display_name'] as String? ?? 'مستخدم',
      role: userRoleFromString(data['role'] as String?),
      phoneNumber: data['phone'] as String?,
      isActive: data['is_active'] as bool? ?? true,
      createdAt: data['created_at'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'display_name': displayName,
      'role': role.value,
      'phone': phoneNumber,
      'is_active': isActive,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
