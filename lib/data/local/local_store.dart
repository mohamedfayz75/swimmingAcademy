import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../features/attendance/models/attendance_model.dart';
import '../../features/groups/models/group_model.dart';
import '../../features/owner_dashboard/models/accounting_model.dart';
import '../../features/owner_dashboard/models/expense_model.dart';
import '../../features/owner_dashboard/models/payroll_model.dart';
import '../../features/players/models/player_model.dart';
import '../../features/subscriptions/models/subscription_model.dart';
import '../../features/water_cards/models/water_card_model.dart';

import '../../features/auth/models/user_model.dart';
import '../../core/rbac/app_role.dart';

class LocalStore {
  static final LocalStore instance = LocalStore._internal();

  LocalStore._internal() {
    _initSampleData();
  }

  // In-memory collections
  final List<UserModel> _users = [];
  final List<PlayerModel> _players = [];
  final List<GroupModel> _groups = [];
  final List<SubscriptionModel> _subscriptions = [];
  final List<AttendanceModel> _attendance = [];
  final List<WaterCardModel> _waterCards = [];
  final List<CoachModel> _coaches = [];
  final List<PayrollModel> _payrolls = [];
  final List<ExpenseModel> _expenses = [];

  // StreamControllers for real-time reactivity
  final _usersController = StreamController<List<UserModel>>.broadcast();
  final _playersController = StreamController<List<PlayerModel>>.broadcast();
  final _groupsController = StreamController<List<GroupModel>>.broadcast();
  final _subscriptionsController = StreamController<List<SubscriptionModel>>.broadcast();
  final _attendanceController = StreamController<List<AttendanceModel>>.broadcast();
  final _waterCardsController = StreamController<List<WaterCardModel>>.broadcast();
  final _coachesController = StreamController<List<CoachModel>>.broadcast();
  final _expensesController = StreamController<List<ExpenseModel>>.broadcast();

  // Streams that emit current cached data immediately to any new listener
  Stream<List<UserModel>> get usersStream async* {
    yield List.unmodifiable(_users);
    yield* _usersController.stream;
  }

  Stream<List<PlayerModel>> get playersStream async* {
    yield List.unmodifiable(_players);
    yield* _playersController.stream;
  }

  Stream<List<GroupModel>> get groupsStream async* {
    yield List.unmodifiable(_groups);
    yield* _groupsController.stream;
  }

  Stream<List<SubscriptionModel>> get subscriptionsStream async* {
    yield List.unmodifiable(_subscriptions);
    yield* _subscriptionsController.stream;
  }

  Stream<List<AttendanceModel>> get attendanceStream async* {
    yield List.unmodifiable(_attendance);
    yield* _attendanceController.stream;
  }

  Stream<List<WaterCardModel>> get waterCardsStream async* {
    yield List.unmodifiable(_waterCards);
    yield* _waterCardsController.stream;
  }

  Stream<List<CoachModel>> get coachesStream async* {
    yield List.unmodifiable(_coaches);
    yield* _coachesController.stream;
  }

  Stream<List<ExpenseModel>> get expensesStream async* {
    yield List.unmodifiable(_expenses);
    yield* _expensesController.stream;
  }

  void _initSampleData() {
    final now = Timestamp.now();
    final currentMonth = '${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}';

    // 0. Default Users (Owner & Staff)
    _users.addAll([
      UserModel(
        uid: 'user-owner-1',
        username: 'owner',
        password: '123',
        email: 'owner@swimmingworld.com',
        displayName: 'المالك العام',
        role: UserRole.owner,
        createdAt: now,
      ),
      UserModel(
        uid: 'user-staff-1',
        username: 'staff',
        password: '123',
        email: 'staff@swimmingworld.com',
        displayName: 'موظف الاستقبال',
        role: UserRole.staff,
        createdAt: now,
      ),
    ]);

    // 1. Coaches
    _coaches.addAll([
      const CoachModel(
        coachId: 'COACH-01',
        coachName: 'كابتن أحمد سامي',
        phoneNumber: '01012345678',
        specialty: 'تعليم مبتدئين ونجمات',
        status: 'نشط',
        groupsCount: 2,
      ),
      const CoachModel(
        coachId: 'COACH-02',
        coachName: 'كابتن محمود رزق',
        phoneNumber: '01198765432',
        specialty: 'برايفت وتجهيزي',
        status: 'نشط',
        groupsCount: 1,
      ),
      const CoachModel(
        coachId: 'COACH-03',
        coachName: 'كابتن طارق عبد الله',
        phoneNumber: '01234567890',
        specialty: 'برايفت رضع',
        status: 'نشط',
        groupsCount: 1,
      ),
    ]);

    // 2. Groups (with 4 specialized types)
    _groups.addAll([
      GroupModel(
        groupCode: 'GRP-01',
        groupType: AppConstants.groupTypeNormal,
        coachId: 'COACH-01',
        coachName: 'كابتن أحمد سامي',
        trainingDays: ['السبت', 'الثلاثاء'],
        sessionTime: '05:00 PM',
        trainingType: 'تعليم (مبتدئ)',
        level: 'مبتدئ',
        maxCapacity: 6,
        currentRegistered: 2,
      ),
      GroupModel(
        groupCode: 'GRP-02',
        groupType: AppConstants.groupTypeSemiPrivate,
        coachId: 'COACH-02',
        coachName: 'كابتن محمود رزق',
        trainingDays: ['الأحد', 'الأربعاء'],
        sessionTime: '06:00 PM',
        trainingType: 'نجمة 1',
        level: 'متوسط',
        maxCapacity: 2,
        currentRegistered: 1,
      ),
      GroupModel(
        groupCode: 'GRP-03',
        groupType: AppConstants.groupTypeBabyPrivate,
        coachId: 'COACH-03',
        coachName: 'كابتن طارق عبد الله',
        trainingDays: ['الاثنين', 'الخميس'],
        sessionTime: '04:00 PM',
        trainingType: 'برايفت رضع',
        level: 'رضع',
        maxCapacity: 2, // 30 min each
        currentRegistered: 1,
      ),
    ]);

    // 3. Players
    _players.addAll([
      PlayerModel(
        playerCode: 'SW-101',
        playerName: 'يوسف أحمد علي',
        branch: AppConstants.defaultBranch,
        birthDate: Timestamp.fromDate(DateTime(2016, 4, 15)),
        guardianPhone: '01098765432',
        customerType: 'عادي (جديد)',
        qrCodeUrl: 'SW-101',
        createdAt: now,
      ),
      PlayerModel(
        playerCode: 'SW-102',
        playerName: 'مريم محمود حسن',
        branch: AppConstants.defaultBranch,
        birthDate: Timestamp.fromDate(DateTime(2017, 7, 22)),
        guardianPhone: '01123456789',
        customerType: 'تجديد',
        qrCodeUrl: 'SW-102',
        createdAt: now,
      ),
    ]);

    // 4. Subscriptions
    _subscriptions.addAll([
      SubscriptionModel(
        id: 'SUB-101',
        playerCode: 'SW-101',
        playerName: 'يوسف أحمد علي',
        branch: AppConstants.defaultBranch,
        groupCode: 'GRP-01',
        coachName: 'كابتن أحمد سامي',
        trainingDays: ['السبت', 'الثلاثاء'],
        sessionTime: '05:00 PM',
        trainingType: 'تعليم (مبتدئ)',
        stampCardFee: 50.0,
        amountRequired: 800.0,
        amountPaid: 850.0, // Fully paid
        paymentMethod: AppConstants.paymentCash,
        paymentDate: now,
        subscriptionType: 'شهري (8 حصص)',
        sessionsCount: 8,
        attendedSessions: 3,
        excusedSessions: 0,
        startDate: now,
        endDate: Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        bookingStatus: AppConstants.statusActive,
        createdBy: 'staff-demo',
      ),
      SubscriptionModel(
        id: 'SUB-102',
        playerCode: 'SW-102',
        playerName: 'مريم محمود حسن',
        branch: AppConstants.defaultBranch,
        groupCode: 'GRP-01',
        coachName: 'كابتن أحمد سامي',
        trainingDays: ['السبت', 'الثلاثاء'],
        sessionTime: '05:00 PM',
        trainingType: 'تعليم (مبتدئ)',
        stampCardFee: 50.0,
        amountRequired: 800.0,
        amountPaid: 500.0, // Remaining 350
        paymentMethod: AppConstants.paymentInstaPay,
        paymentDate: now,
        subscriptionType: 'شهري (8 حصص)',
        sessionsCount: 8,
        attendedSessions: 2,
        excusedSessions: 0,
        startDate: now,
        endDate: Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        bookingStatus: AppConstants.statusActive,
        createdBy: 'staff-demo',
      ),
    ]);

    // 5. Dual Pool Water Cards (Semi-Olympic & Recreational)
    _waterCards.addAll([
      WaterCardModel(
        id: 'WC-01',
        cardDate: now,
        cardName: 'كارت مسبح نصف أولمبي #1',
        poolType: AppConstants.poolSemiOlympic,
        cardPrice: 1500.0,
        totalSessions: 50,
        usedSessions: 18,
        monthlyClosingRef: currentMonth,
      ),
      WaterCardModel(
        id: 'WC-02',
        cardDate: now,
        cardName: 'كارت مسبح ترفيهي #1',
        poolType: AppConstants.poolRecreational,
        cardPrice: 1200.0,
        totalSessions: 40,
        usedSessions: 8,
        monthlyClosingRef: currentMonth,
      ),
    ]);

    // 6. Expenses (Auto-populated with water cards + maintenance)
    _expenses.addAll([
      ExpenseModel(
        id: 'EXP-WC-01',
        category: 'كروت مياة',
        amount: 1500.0,
        date: now,
        notes: 'شراء كارت مسبح نصف أولمبي #1',
        monthYear: currentMonth,
      ),
      ExpenseModel(
        id: 'EXP-WC-02',
        category: 'كروت مياة',
        amount: 1200.0,
        date: now,
        notes: 'شراء كارت مسبح ترفيهي #1',
        monthYear: currentMonth,
      ),
      ExpenseModel(
        id: 'EXP-03',
        category: 'صيانة وفلاتر',
        amount: 600.0,
        date: now,
        notes: 'صيانة مضخات وفلاتر المياه الأسبوعية',
        monthYear: currentMonth,
      ),
    ]);

    // 7. Initial Payroll
    _payrolls.add(
      PayrollModel(
        coachId: 'COACH-01',
        coachName: 'كابتن أحمد سامي',
        totalSessions: 24,
        sessionRate: 100.0,
        advancePayments: 400.0,
        paymentStatus: 'معلق',
        payoutMethod: AppConstants.paymentCash,
        payoutNotes: '',
        payoutDate: now,
        monthYear: currentMonth,
      ),
    );

    _notifyAll();
  }

  void _notifyAll() {
    _playersController.add(List.unmodifiable(_players));
    _groupsController.add(List.unmodifiable(_groups));
    _subscriptionsController.add(List.unmodifiable(_subscriptions));
    _attendanceController.add(List.unmodifiable(_attendance));
    _waterCardsController.add(List.unmodifiable(_waterCards));
    _coachesController.add(List.unmodifiable(_coaches));
    _expensesController.add(List.unmodifiable(_expenses));
  }

  // --- Players ---
  List<PlayerModel> getPlayers() => List.unmodifiable(_players);

  String generateNextPlayerCode() {
    return 'SW-${_players.length + 101}';
  }

  PlayerModel addPlayer(PlayerModel player) {
    _players.insert(0, player);
    _playersController.add(List.unmodifiable(_players));
    return player;
  }

  PlayerModel? getPlayerByCode(String code) {
    final clean = code.trim().toUpperCase();
    try {
      return _players.firstWhere((p) => p.playerCode.toUpperCase() == clean);
    } catch (_) {
      return null;
    }
  }

  // --- Groups ---
  List<GroupModel> getGroups() => List.unmodifiable(_groups);

  void addGroup(GroupModel group) {
    _groups.add(group);
    _groupsController.add(List.unmodifiable(_groups));
  }

  GroupModel? getGroupByCode(String code) {
    try {
      return _groups.firstWhere((g) => g.groupCode == code);
    } catch (_) {
      return null;
    }
  }

  void incrementGroupRegistered(String groupCode) {
    final index = _groups.indexWhere((g) => g.groupCode == groupCode);
    if (index != -1) {
      final g = _groups[index];
      _groups[index] = g.copyWith(currentRegistered: g.currentRegistered + 1);
      _groupsController.add(List.unmodifiable(_groups));
    }
  }

  // --- Subscriptions ---
  List<SubscriptionModel> getSubscriptions() => List.unmodifiable(_subscriptions);

  SubscriptionModel addSubscription(SubscriptionModel sub) {
    final newId = 'SUB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final model = sub.copyWith(id: newId);
    _subscriptions.insert(0, model);

    // Increment seat in primary group
    incrementGroupRegistered(sub.groupCode);

    // If custom split schedule, increment secondary group as well!
    if (sub.secondaryGroupCode != null && sub.secondaryGroupCode!.isNotEmpty) {
      incrementGroupRegistered(sub.secondaryGroupCode!);
    }

    _subscriptionsController.add(List.unmodifiable(_subscriptions));
    return model;
  }

  SubscriptionModel? getActiveSubscription(String playerCode) {
    final clean = playerCode.trim().toUpperCase();
    try {
      return _subscriptions.firstWhere(
        (s) => s.playerCode.toUpperCase() == clean && !s.isExpired,
        orElse: () => _subscriptions.firstWhere((s) => s.playerCode.toUpperCase() == clean),
      );
    } catch (_) {
      return null;
    }
  }

  // Owner Exclusive: Excuse a missed session and restore it to quota
  void excuseSession(String subscriptionId) {
    final index = _subscriptions.indexWhere((s) => s.id == subscriptionId);
    if (index != -1) {
      final sub = _subscriptions[index];
      _subscriptions[index] = sub.copyWith(
        excusedSessions: sub.excusedSessions + 1,
      );
      _subscriptionsController.add(List.unmodifiable(_subscriptions));
    }
  }

  // Confirm a deposit subscription upon full payment on day 1
  void confirmDepositSubscription({
    required String subscriptionId,
    required double additionalAmountPaid,
    required String paymentMethod,
  }) {
    final index = _subscriptions.indexWhere((s) => s.id == subscriptionId);
    if (index != -1) {
      final sub = _subscriptions[index];
      final newPaid = sub.amountPaid + additionalAmountPaid;
      _subscriptions[index] = sub.copyWith(
        amountPaid: newPaid,
        bookingStatus: AppConstants.statusActive,
        paymentMethod: paymentMethod,
      );
      _subscriptionsController.add(List.unmodifiable(_subscriptions));
    }
  }

  // --- Attendance ---
  List<AttendanceModel> getAttendance() => List.unmodifiable(_attendance);

  AttendanceModel recordAttendance(AttendanceModel model) {
    _attendance.insert(0, model);

    final subIndex = _subscriptions.indexWhere(
      (s) => s.playerCode.toUpperCase() == model.playerCode.toUpperCase() && !s.isExpired,
    );
    if (subIndex != -1) {
      final currentSub = _subscriptions[subIndex];
      _subscriptions[subIndex] = currentSub.copyWith(
        attendedSessions: currentSub.attendedSessions + 1,
      );
      _subscriptionsController.add(List.unmodifiable(_subscriptions));
    }
    _attendanceController.add(List.unmodifiable(_attendance));
    return model;
  }

  // --- Water Cards (Dual Pool Support) ---
  List<WaterCardModel> getWaterCards() => List.unmodifiable(_waterCards);

  WaterCardModel? getActiveCardForPool(String poolType) {
    try {
      return _waterCards.lastWhere((w) => w.poolType == poolType && w.isActive);
    } catch (_) {
      try {
        return _waterCards.lastWhere((w) => w.poolType == poolType);
      } catch (_) {
        return null;
      }
    }
  }

  void updateWaterCardSessions(String cardId, int newUsedCount) {
    final index = _waterCards.indexWhere((w) => w.id == cardId);
    if (index != -1) {
      final current = _waterCards[index];
      _waterCards[index] = current.copyWith(usedSessions: newUsedCount);
      _waterCardsController.add(List.unmodifiable(_waterCards));
    }
  }

  // Auto-transfer of new water card purchase into General Expenses!
  void addWaterCard(WaterCardModel card) {
    _waterCards.add(card);
    _waterCardsController.add(List.unmodifiable(_waterCards));

    // Automated expense entry
    addExpense(
      ExpenseModel(
        id: 'EXP-${card.id}',
        category: 'كروت مياة',
        amount: card.cardPrice,
        date: card.cardDate,
        notes: 'شراء وتفعيل ${card.cardName} (${card.poolType})',
        monthYear: card.monthlyClosingRef,
      ),
    );
  }

  // --- Coaches & Payroll ---
  List<CoachModel> getCoaches() => List.unmodifiable(_coaches);

  void addCoach(CoachModel coach) {
    _coaches.add(coach);
    _coachesController.add(List.unmodifiable(_coaches));
  }

  void updateCoach(CoachModel coach) {
    final index = _coaches.indexWhere((c) => c.coachId == coach.coachId);
    if (index != -1) {
      _coaches[index] = coach;
      _coachesController.add(List.unmodifiable(_coaches));
    }
  }

  void logDailyCoachSession(String coachId, int sessionsCount, String monthYear) {
    final index = _payrolls.indexWhere((p) => p.coachId == coachId && p.monthYear == monthYear);
    if (index != -1) {
      final p = _payrolls[index];
      _payrolls[index] = p.copyWith(totalSessions: p.totalSessions + sessionsCount);
    } else {
      final coach = _coaches.firstWhere((c) => c.coachId == coachId, orElse: () => _coaches.first);
      _payrolls.add(
        PayrollModel(
          coachId: coachId,
          coachName: coach.coachName,
          totalSessions: sessionsCount,
          sessionRate: 100.0,
          payoutDate: Timestamp.now(),
          monthYear: monthYear,
        ),
      );
    }
  }

  void savePayroll(PayrollModel payroll) {
    final index = _payrolls.indexWhere(
      (p) => p.coachId == payroll.coachId && p.monthYear == payroll.monthYear,
    );
    if (index != -1) {
      _payrolls[index] = payroll;
    } else {
      _payrolls.add(payroll);
    }
  }

  List<PayrollModel> getPayrollForMonth(String monthYear) {
    return _payrolls.where((p) => p.monthYear == monthYear).toList();
  }

  // Get accrued uncollected payroll from previous months
  List<PayrollModel> getUnpaidPayrollsBeforeMonth(String currentMonthYear) {
    return _payrolls.where((p) => p.monthYear != currentMonthYear && !p.isPaid).toList();
  }

  // --- Expenses & Accounting ---
  List<ExpenseModel> getExpensesForMonth(String monthYear) {
    return _expenses.where((e) => e.monthYear == monthYear).toList();
  }

  void addExpense(ExpenseModel expense) {
    _expenses.insert(0, expense);
    _expensesController.add(List.unmodifiable(_expenses));
  }

  GeneralAccountingModel calculateFinancials(String monthYear) {
    double subRevenues = 0;
    double stampRevenues = 0;

    for (final s in _subscriptions) {
      subRevenues += s.amountPaid;
      stampRevenues += s.stampCardFee;
    }

    double payrollTotal = 0;
    for (final p in _payrolls.where((p) => p.monthYear == monthYear && p.isPaid)) {
      payrollTotal += p.netPayable;
    }

    double generalExpensesTotal = 0;
    for (final e in _expenses.where((e) => e.monthYear == monthYear)) {
      generalExpensesTotal += e.amount;
    }

    return GeneralAccountingModel(
      monthYear: monthYear,
      totalSubscriptionRevenues: subRevenues,
      totalStampCardRevenues: stampRevenues,
      totalCoachPayroll: payrollTotal,
      totalWaterCardExpenses: 0, // Already included seamlessly in generalExpensesTotal!
      otherExpenses: generalExpensesTotal,
    );
  }

  // --- Users Management (Staff & Admin) ---
  List<UserModel> getUsers() => List.unmodifiable(_users);

  UserModel? authenticate(String usernameOrEmail, String password) {
    final query = usernameOrEmail.trim().toLowerCase();
    try {
      final user = _users.firstWhere(
        (u) =>
            (u.username.toLowerCase() == query || u.email.toLowerCase() == query) &&
            u.password == password &&
            u.isActive,
      );
      return user;
    } catch (_) {
      return null;
    }
  }

  void addUser(UserModel user) {
    _users.add(user);
    _usersController.add(List.unmodifiable(_users));
  }

  void updateUserPassword(String uid, String newPassword) {
    final index = _users.indexWhere((u) => u.uid == uid);
    if (index != -1) {
      _users[index] = _users[index].copyWith(password: newPassword);
      _usersController.add(List.unmodifiable(_users));
    }
  }

  void toggleUserActive(String uid, bool isActive) {
    final index = _users.indexWhere((u) => u.uid == uid);
    if (index != -1) {
      _users[index] = _users[index].copyWith(isActive: isActive);
      _usersController.add(List.unmodifiable(_users));
    }
  }

  void deleteUser(String uid) {
    _users.removeWhere((u) => u.uid == uid);
    _usersController.add(List.unmodifiable(_users));
  }
}
