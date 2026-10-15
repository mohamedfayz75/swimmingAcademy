import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class PlayerModel {
  final String playerCode;
  final String playerName;
  final String branch;
  final Timestamp birthDate;
  final String guardianPhone;
  final String customerType; // "عادي" / "تجديد"
  final String qrCodeUrl;
  final Timestamp createdAt;

  const PlayerModel({
    required this.playerCode,
    required this.playerName,
    required this.branch,
    required this.birthDate,
    required this.guardianPhone,
    required this.customerType,
    required this.qrCodeUrl,
    required this.createdAt,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      playerCode: map['player_code'] as String? ?? '',
      playerName: map['player_name'] as String? ?? '',
      branch: map['branch'] as String? ?? AppConstants.defaultBranch,
      birthDate: map['birth_date_ms'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(map['birth_date_ms'] as int)
          : Timestamp.now(),
      guardianPhone: map['guardian_phone'] as String? ?? '',
      customerType: map['customer_type'] as String? ?? 'عادي (جديد)',
      qrCodeUrl: map['qr_code_url'] as String? ?? map['player_code'] as String? ?? '',
      createdAt: map['created_at_ms'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(map['created_at_ms'] as int)
          : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'player_code': playerCode,
      'player_name': playerName,
      'branch': branch,
      'birth_date_ms': birthDate.millisecondsSinceEpoch,
      'guardian_phone': guardianPhone,
      'customer_type': customerType,
      'qr_code_url': qrCodeUrl,
      'created_at_ms': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PlayerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PlayerModel(
      playerCode: data['player_code'] as String? ?? doc.id,
      playerName: data['player_name'] as String? ?? '',
      branch: data['branch'] as String? ?? AppConstants.defaultBranch,
      birthDate: data['birth_date'] as Timestamp? ?? Timestamp.now(),
      guardianPhone: data['guardian_phone'] as String? ?? '',
      customerType: data['customer_type'] as String? ?? 'عادي',
      qrCodeUrl: data['qr_code_url'] as String? ?? '',
      createdAt: data['created_at'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'player_code': playerCode,
      'player_name': playerName,
      'branch': branch,
      'birth_date': birthDate,
      'guardian_phone': guardianPhone,
      'customer_type': customerType,
      'qr_code_url': qrCodeUrl,
      'created_at': createdAt,
    };
  }

  PlayerModel copyWith({
    String? playerCode,
    String? playerName,
    String? branch,
    Timestamp? birthDate,
    String? guardianPhone,
    String? customerType,
    String? qrCodeUrl,
    Timestamp? createdAt,
  }) {
    return PlayerModel(
      playerCode: playerCode ?? this.playerCode,
      playerName: playerName ?? this.playerName,
      branch: branch ?? this.branch,
      birthDate: birthDate ?? this.birthDate,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      customerType: customerType ?? this.customerType,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
