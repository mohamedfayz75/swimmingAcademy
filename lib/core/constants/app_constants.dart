class AppConstants {
  // App Title
  static const String appName = 'S.W - المعادي';
  static const String appSubtitle = 'Swimming World Academy - Maadi';

  // Default Branch
  static const String defaultBranch = 'المعادي';
  static const List<String> branches = [
    'المعادي',
  ];

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

  // Pool Types for Water Cards
  static const String poolSemiOlympic = 'نصف أولمبي';
  static const String poolRecreational = 'ترفيهي';
  static const List<String> poolTypes = [
    poolSemiOlympic,
    poolRecreational,
  ];

  // Group Types and Max Capacities
  static const String groupTypeNormal = 'مجموعة عادية (6 سباحين)';
  static const String groupTypeSemiPrivate = 'سيمي-برايفت (إخوة/ثنائي - 2 سباحين)';
  static const String groupTypeAdultPrivate = 'برايفت كبار (سباح واحد)';
  static const String groupTypeBabyPrivate = 'برايفت رضع (طفلين - 30 دقيقة لكل طفل)';

  static const List<String> groupTypes = [
    groupTypeNormal,
    groupTypeSemiPrivate,
    groupTypeAdultPrivate,
    groupTypeBabyPrivate,
  ];

  // Training Levels
  static const List<String> trainingTypes = [
    'تعليم (مبتدئ)',
    'نجمة 1',
    'نجمة 2',
    'تجهيزي',
    'فرق',
    'برايفت رضع',
    'برايفت كبار',
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
  static const String customerTypeNew = 'عادي (جديد)';
  static const String customerTypeRenew = 'تجديد';

  // Payment Methods
  static const String paymentCash = 'كاش (نقدي)';
  static const String paymentInstaPay = 'انستاباي (InstaPay)';
  static const String paymentVodafoneCash = 'فودافون كاش';
  static const String paymentBankTransfer = 'تحويل بنكي';

  static const List<String> paymentMethods = [
    paymentCash,
    paymentInstaPay,
    paymentVodafoneCash,
    paymentBankTransfer,
  ];

  // Booking / Subscription Statuses
  static const String statusActive = 'نشط ومؤكد';
  static const String statusDeposit = 'حجز بعربون';
  static const String statusPending = 'حجز مؤقت معلق';
  static const String statusExpired = 'منتهي';

  // Subscription Types
  static const List<String> subscriptionTypes = [
    'شهري (4 حصص)',
    'شهري (8 حصص)',
    'مكثف (12 حصة)',
    'ربع سنوي (24 حصة)',
    'نصف سنوي (48 حصة)',
    'سنوي (96 حصة)',
    'برايفت خاص',
  ];

  // Expense Categories
  static const List<String> defaultExpenseCategories = [
    'كروت مياة',
    'صيانة وفلاتر',
    'كلور ومواد تعقيم',
    'أدوات ومعدات سباحة',
    'إيجار مسبح',
    'كهرباء ومرافق',
    'بوفيه وضيافة',
    'دعاية وإعلانات',
    'نثريات ومصروفات أخرى',
  ];
}
