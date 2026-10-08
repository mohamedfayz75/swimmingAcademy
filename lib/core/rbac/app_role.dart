enum UserRole {
  owner,
  staff,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.owner:
        return 'owner';
      case UserRole.staff:
        return 'staff';
    }
  }

  String get arabicTitle {
    switch (this) {
      case UserRole.owner:
        return 'المالك (الإدارة العليا)';
      case UserRole.staff:
        return 'موظف الاستقبال (إدخال بيانات)';
    }
  }

  bool get isOwner => this == UserRole.owner;
  bool get isStaff => this == UserRole.staff;

  // Permissions
  bool get canViewFinancials => this == UserRole.owner;
  bool get canEditHistoricalData => this == UserRole.owner;
  bool get canManageCoachesAndPayroll => this == UserRole.owner;
  bool get canPerformMonthlyClosure => this == UserRole.owner;
  bool get canRegisterPlayer => true; // Both can register
  bool get canRecordAttendance => true; // Both can record attendance
  bool get canRecordWaterCard => true; // Both can record water usage
}

UserRole userRoleFromString(String? roleStr) {
  if (roleStr == null) return UserRole.staff;
  final clean = roleStr.toLowerCase().trim();
  if (clean == 'owner' || clean == 'مالك' || clean == 'admin') {
    return UserRole.owner;
  }
  return UserRole.staff;
}
