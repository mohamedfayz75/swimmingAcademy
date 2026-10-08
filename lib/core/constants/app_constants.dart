class AppConstants {
  // App Title
  static const String appName = 'أكاديمية عالم السباحة';
  static const String appSubtitle = 'Swimming World Academy';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String playersCollection = 'players';
  static const String groupsCollection = 'groups';
  static const String subscriptionsCollection = 'subscriptions';
  static const String attendanceCollection = 'attendance';
  static const String waterCardsCollection = 'water_cards';
  static const String coachesCollection = 'coaches';
  static const String payrollCollection = 'payroll';
  static const String expensesCollection = 'expenses';
  static const String generalAccountingCollection = 'general_accounting';

  // Training Types
  static const List<String> trainingTypes = [
    'تعليم',
    'نجمة 1',
    'نجمة 2',
    'تجهيزي',
    'فرق',
  ];

  // Days of Week (Arabic)
  static const List<String> weekDays = [
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  // Customer Types
  static const String customerTypeNew = 'عادي';
  static const String customerTypeRenew = 'تجديد';

  // Attendance Statuses
  static const String attendancePresent = 'حاضر';
  static const String attendanceAbsent = 'غائب';
  static const String attendanceExcused = 'معتذر';

  // Subscription Types
  static const List<String> subscriptionTypes = [
    'شهري (8 حصص)',
    'مكثف (12 حصة)',
    'خاص (Private)',
    'تدريب فرق',
  ];
}
