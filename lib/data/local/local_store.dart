import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../features/attendance/models/attendance_model.dart';
import '../../features/groups/models/group_model.dart';
import '../../features/owner_dashboard/models/accounting_model.dart';
import '../../features/owner_dashboard/models/expense_model.dart';
import '../../features/owner_dashboard/models/payroll_model.dart';
import '../../features/players/models/player_model.dart';
import '../../features/subscriptions/models/subscription_model.dart';
import '../../features/water_cards/models/water_card_model.dart';
import '../../features/water_cards/models/pool_overdraft_model.dart';

import '../../features/auth/models/user_model.dart';
import '../../core/rbac/app_role.dart';

class LocalStore {
  static final LocalStore instance = LocalStore._internal();

  LocalStore._internal() {
    _initSampleData();
  }

  bool _isInitialized = false;

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
  final List<PoolOverdraftNoteModel> _poolOverdraftNotes = [];

  // StreamControllers for real-time reactivity
  final _usersController = StreamController<List<UserModel>>.broadcast();
  final _playersController = StreamController<List<PlayerModel>>.broadcast();
  final _groupsController = StreamController<List<GroupModel>>.broadcast();
  final _subscriptionsController = StreamController<List<SubscriptionModel>>.broadcast();
  final _attendanceController = StreamController<List<AttendanceModel>>.broadcast();
  final _waterCardsController = StreamController<List<WaterCardModel>>.broadcast();
  final _poolOverdraftNotesController = StreamController<List<PoolOverdraftNoteModel>>.broadcast();
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

  Stream<List<PoolOverdraftNoteModel>> get poolOverdraftNotesStream async* {
    yield List.unmodifiable(_poolOverdraftNotes);
    yield* _poolOverdraftNotesController.stream;
  }

  Stream<List<CoachModel>> get coachesStream async* {
    yield List.unmodifiable(_coaches);
    yield* _coachesController.stream;
  }

  Stream<List<ExpenseModel>> get expensesStream async* {
    yield List.unmodifiable(_expenses);
    yield* _expensesController.stream;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasData = prefs.getBool('sw_data_initialized') ?? false;

      // 1. Load Players Independently
      final playersJson = prefs.getString('sw_players');
      if (playersJson != null && playersJson.trim().isNotEmpty) {
        try {
          final List list = jsonDecode(playersJson);
          final loaded = <PlayerModel>[];
          for (final item in list) {
            try {
              loaded.add(PlayerModel.fromMap(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error decoding single player: $e');
            }
          }
          if (loaded.isNotEmpty) {
            _players.clear();
            _players.addAll(loaded);
          }
        } catch (e) {
          debugPrint('Error decoding sw_players: $e');
        }
      }

      // 2. Load Subscriptions Independently
      final subsJson = prefs.getString('sw_subscriptions');
      if (subsJson != null && subsJson.trim().isNotEmpty) {
        try {
          final List list = jsonDecode(subsJson);
          final loaded = <SubscriptionModel>[];
          for (final item in list) {
            try {
              loaded.add(SubscriptionModel.fromMap(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error decoding single subscription: $e');
            }
          }
          if (loaded.isNotEmpty) {
            _subscriptions.clear();
            _subscriptions.addAll(loaded);
          }
        } catch (e) {
          debugPrint('Error decoding sw_subscriptions: $e');
        }
      }

      // 3. Load Groups Independently
      final groupsJson = prefs.getString('sw_groups');
      if (groupsJson != null && groupsJson.trim().isNotEmpty) {
        try {
          final List list = jsonDecode(groupsJson);
          final loaded = <GroupModel>[];
          for (final item in list) {
            try {
              loaded.add(GroupModel.fromMap(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error decoding single group: $e');
            }
          }
          if (loaded.isNotEmpty) {
            _groups.clear();
            _groups.addAll(loaded);
          }
        } catch (e) {
          debugPrint('Error decoding sw_groups: $e');
        }
      }

      // 4. Load Attendance Independently
      final attJson = prefs.getString('sw_attendance');
      if (attJson != null && attJson.trim().isNotEmpty) {
        try {
          final List list = jsonDecode(attJson);
          final loaded = <AttendanceModel>[];
          for (final item in list) {
            try {
              loaded.add(AttendanceModel.fromMap(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error decoding single attendance: $e');
            }
          }
          if (loaded.isNotEmpty) {
            _attendance.clear();
            _attendance.addAll(loaded);
          }
        } catch (e) {
          debugPrint('Error decoding sw_attendance: $e');
        }
      }

      // 5. Load Water Cards Independently
      final wcJson = prefs.getString('sw_water_cards');
      if (wcJson != null && wcJson.trim().isNotEmpty) {
        try {
          final List list = jsonDecode(wcJson);
          final loaded = <WaterCardModel>[];
          for (final item in list) {
            try {
              loaded.add(WaterCardModel.fromMap(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error decoding single water card: $e');
            }
          }
          if (loaded.isNotEmpty) {
            _waterCards.clear();
            _waterCards.addAll(loaded);
          }
        } catch (e) {
          debugPrint('Error decoding sw_water_cards: $e');
        }
      }

      // 6. Load Pool Overdraft Notes Independently
      final ponJson = prefs.getString('sw_pool_overdraft_notes');
      if (ponJson != null && ponJson.trim().isNotEmpty) {
        try {
          final List list = jsonDecode(ponJson);
          final loaded = <PoolOverdraftNoteModel>[];
          for (final item in list) {
            try {
              loaded.add(PoolOverdraftNoteModel.fromMap(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error decoding single overdraft note: $e');
            }
          }
          if (loaded.isNotEmpty) {
            _poolOverdraftNotes.clear();
            _poolOverdraftNotes.addAll(loaded);
          }
        } catch (e) {
          debugPrint('Error decoding sw_pool_overdraft_notes: $e');
        }
      }

      // 7. Load Coaches Independently
      final coachesJson = prefs.getString('sw_coaches');
      if (coachesJson != null && coachesJson.trim().isNotEmpty) {
        try {
          final List list = jsonDecode(coachesJson);
          final loaded = <CoachModel>[];
          for (final item in list) {
            try {
              loaded.add(CoachModel.fromMap(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error decoding single coach: $e');
            }
          }
          if (loaded.isNotEmpty) {
            _coaches.clear();
            _coaches.addAll(loaded);
          }
        } catch (e) {
          debugPrint('Error decoding sw_coaches: $e');
        }
      }

      // 8. Load Payrolls Independently
      final payrollsJson = prefs.getString('sw_payrolls');
      if (payrollsJson != null && payrollsJson.trim().isNotEmpty) {
        try {
          final List list = jsonDecode(payrollsJson);
          final loaded = <PayrollModel>[];
          for (final item in list) {
            try {
              loaded.add(PayrollModel.fromMap(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error decoding single payroll: $e');
            }
          }
          if (loaded.isNotEmpty) {
            _payrolls.clear();
            _payrolls.addAll(loaded);
          }
        } catch (e) {
          debugPrint('Error decoding sw_payrolls: $e');
        }
      }

      // 9. Load Expenses Independently
      final expJson = prefs.getString('sw_expenses');
      if (expJson != null && expJson.trim().isNotEmpty) {
        try {
          final List list = jsonDecode(expJson);
          final loaded = <ExpenseModel>[];
          for (final item in list) {
            try {
              loaded.add(ExpenseModel.fromMap(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error decoding single expense: $e');
            }
          }
          if (loaded.isNotEmpty) {
            _expenses.clear();
            _expenses.addAll(loaded);
          }
        } catch (e) {
          debugPrint('Error decoding sw_expenses: $e');
        }
      }

      // 10. Load Users Independently
      final usersJson = prefs.getString('sw_users');
      if (usersJson != null && usersJson.trim().isNotEmpty) {
        try {
          final List list = jsonDecode(usersJson);
          final loaded = <UserModel>[];
          for (final item in list) {
            try {
              loaded.add(UserModel.fromMap(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error decoding single user: $e');
            }
          }
          if (loaded.isNotEmpty) {
            _users.clear();
            _users.addAll(loaded);
          }
        } catch (e) {
          debugPrint('Error decoding sw_users: $e');
        }
      }

      // Only seed starter data if this is the very first install ever AND all collections are empty!
      if (!hasData && _players.isEmpty && _subscriptions.isEmpty && _groups.isEmpty) {
        _initSampleData();
        await prefs.setBool('sw_data_initialized', true);
        await _saveAll();
      } else {
        await prefs.setBool('sw_data_initialized', true);
      }
    } catch (e) {
      debugPrint('LocalStore.init error: $e');
    }

    _isInitialized = true;
    _notifyAll();
  }

  Future<void> saveAllExplicitly() async {
    await _saveAll();
  }

  Future<void> _saveAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setBool('sw_data_initialized', true),
        prefs.setString('sw_players', jsonEncode(_players.map((p) => p.toMap()).toList())),
        prefs.setString('sw_subscriptions', jsonEncode(_subscriptions.map((s) => s.toMap()).toList())),
        prefs.setString('sw_groups', jsonEncode(_groups.map((g) => g.toMap()).toList())),
        prefs.setString('sw_attendance', jsonEncode(_attendance.map((a) => a.toMap()).toList())),
        prefs.setString('sw_water_cards', jsonEncode(_waterCards.map((w) => w.toMap()).toList())),
        prefs.setString('sw_pool_overdraft_notes', jsonEncode(_poolOverdraftNotes.map((n) => n.toMap()).toList())),
        prefs.setString('sw_coaches', jsonEncode(_coaches.map((c) => c.toMap()).toList())),
        prefs.setString('sw_payrolls', jsonEncode(_payrolls.map((p) => p.toMap()).toList())),
        prefs.setString('sw_expenses', jsonEncode(_expenses.map((e) => e.toMap()).toList())),
        prefs.setString('sw_users', jsonEncode(_users.map((u) => u.toMap()).toList())),
      ]);
    } catch (e) {
      debugPrint('LocalStore._saveAll error: $e');
    }
  }

  // --- نظام النسخ الاحتياطي وتصدير واسترجاع البيانات بالكامل ---
  String exportBackupJson() {
    final data = {
      'app': 'SwimmingWorldAcademy',
      'version': '1.0.6',
      'timestamp_ms': DateTime.now().millisecondsSinceEpoch,
      'export_date': DateTime.now().toIso8601String(),
      'players': _players.map((p) => p.toMap()).toList(),
      'subscriptions': _subscriptions.map((s) => s.toMap()).toList(),
      'groups': _groups.map((g) => g.toMap()).toList(),
      'attendance': _attendance.map((a) => a.toMap()).toList(),
      'water_cards': _waterCards.map((w) => w.toMap()).toList(),
      'pool_overdraft_notes': _poolOverdraftNotes.map((n) => n.toMap()).toList(),
      'coaches': _coaches.map((c) => c.toMap()).toList(),
      'payrolls': _payrolls.map((p) => p.toMap()).toList(),
      'expenses': _expenses.map((e) => e.toMap()).toList(),
      'users': _users.map((u) => u.toMap()).toList(),
    };
    return jsonEncode(data);
  }

  bool importBackupJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString.trim());
      if (!data.containsKey('players') && !data.containsKey('subscriptions')) {
        return false;
      }

      if (data['players'] is List) {
        _players.clear();
        for (final p in data['players']) {
          try {
            _players.add(PlayerModel.fromMap(Map<String, dynamic>.from(p)));
          } catch (_) {}
        }
      }

      if (data['subscriptions'] is List) {
        _subscriptions.clear();
        for (final s in data['subscriptions']) {
          try {
            _subscriptions.add(SubscriptionModel.fromMap(Map<String, dynamic>.from(s)));
          } catch (_) {}
        }
      }

      if (data['groups'] is List) {
        _groups.clear();
        for (final g in data['groups']) {
          try {
            _groups.add(GroupModel.fromMap(Map<String, dynamic>.from(g)));
          } catch (_) {}
        }
      }

      if (data['attendance'] is List) {
        _attendance.clear();
        for (final a in data['attendance']) {
          try {
            _attendance.add(AttendanceModel.fromMap(Map<String, dynamic>.from(a)));
          } catch (_) {}
        }
      }

      if (data['water_cards'] is List) {
        _waterCards.clear();
        for (final w in data['water_cards']) {
          try {
            _waterCards.add(WaterCardModel.fromMap(Map<String, dynamic>.from(w)));
          } catch (_) {}
        }
      }

      if (data['pool_overdraft_notes'] is List) {
        _poolOverdraftNotes.clear();
        for (final n in data['pool_overdraft_notes']) {
          try {
            _poolOverdraftNotes.add(PoolOverdraftNoteModel.fromMap(Map<String, dynamic>.from(n)));
          } catch (_) {}
        }
      }

      if (data['coaches'] is List) {
        _coaches.clear();
        for (final c in data['coaches']) {
          try {
            _coaches.add(CoachModel.fromMap(Map<String, dynamic>.from(c)));
          } catch (_) {}
        }
      }

      if (data['payrolls'] is List) {
        _payrolls.clear();
        for (final py in data['payrolls']) {
          try {
            _payrolls.add(PayrollModel.fromMap(Map<String, dynamic>.from(py)));
          } catch (_) {}
        }
      }

      if (data['expenses'] is List) {
        _expenses.clear();
        for (final e in data['expenses']) {
          try {
            _expenses.add(ExpenseModel.fromMap(Map<String, dynamic>.from(e)));
          } catch (_) {}
        }
      }

      if (data['users'] is List) {
        _users.clear();
        for (final u in data['users']) {
          try {
            _users.add(UserModel.fromMap(Map<String, dynamic>.from(u)));
          } catch (_) {}
        }
      }

      _saveAll();
      _notifyAll();
      return true;
    } catch (e) {
      debugPrint('Error importing backup: $e');
      return false;
    }
  }

  Future<void> resetAllData() async {
    _initSampleData();
    await _saveAll();
  }

  void _initSampleData() {
    _users.clear();
    _players.clear();
    _groups.clear();
    _subscriptions.clear();
    _attendance.clear();
    _waterCards.clear();
    _poolOverdraftNotes.clear();
    _coaches.clear();
    _payrolls.clear();
    _expenses.clear();

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
    _usersController.add(List.unmodifiable(_users));
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
    int maxCode = 100;
    for (final p in _players) {
      final match = RegExp(r'\d+').firstMatch(p.playerCode);
      if (match != null) {
        final val = int.tryParse(match.group(0)!) ?? 0;
        if (val > maxCode) maxCode = val;
      }
    }
    return 'SW-${maxCode + 1}';
  }

  PlayerModel addPlayer(PlayerModel player) {
    _players.insert(0, player);
    _playersController.add(List.unmodifiable(_players));
    _saveAll();
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
    _saveAll();
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
      _saveAll();
    }
  }

  void decrementGroupRegistered(String groupCode) {
    final index = _groups.indexWhere((g) => g.groupCode == groupCode);
    if (index != -1) {
      final g = _groups[index];
      final newCount = (g.currentRegistered - 1) > 0 ? (g.currentRegistered - 1) : 0;
      _groups[index] = g.copyWith(currentRegistered: newCount);
      _groupsController.add(List.unmodifiable(_groups));
      _saveAll();
    }
  }

  void updateGroup(GroupModel group) {
    final index = _groups.indexWhere((g) => g.groupCode == group.groupCode);
    if (index != -1) {
      _groups[index] = group;
      _groupsController.add(List.unmodifiable(_groups));
      _saveAll();
    }
  }

  void deleteGroup(String groupCode) {
    _groups.removeWhere((g) => g.groupCode == groupCode);
    _groupsController.add(List.unmodifiable(_groups));
    _saveAll();
  }

  bool transferPlayerToGroup({
    required String subscriptionId,
    required String newGroupCode,
  }) {
    final subIndex = _subscriptions.indexWhere((s) => s.id == subscriptionId);
    if (subIndex == -1) return false;

    final sub = _subscriptions[subIndex];
    final oldGroupCode = sub.groupCode;
    if (oldGroupCode == newGroupCode) return true;

    final newGroup = getGroupByCode(newGroupCode);
    if (newGroup == null) return false;

    // Decrement registered in old group
    decrementGroupRegistered(oldGroupCode);

    // Increment registered in new group
    incrementGroupRegistered(newGroupCode);

    // Update subscription with new group parameters
    _subscriptions[subIndex] = sub.copyWith(
      groupCode: newGroup.groupCode,
      coachName: newGroup.coachName,
      trainingDays: newGroup.trainingDays,
      sessionTime: newGroup.sessionTime,
      trainingType: newGroup.trainingType,
    );

    _subscriptionsController.add(List.unmodifiable(_subscriptions));
    _saveAll();
    return true;
  }

  List<SubscriptionModel> getActiveSubscriptionsForGroup(String groupCode) {
    final clean = groupCode.trim().toUpperCase();
    return _subscriptions
        .where((s) => s.groupCode.trim().toUpperCase() == clean && !s.isExpired)
        .toList();
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
    _saveAll();
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
      _saveAll();
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
      _saveAll();
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
    _saveAll();
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
      _saveAll();
    }
  }

  // Auto-transfer of new water card purchase into General Expenses!
  void addWaterCard(WaterCardModel card, {bool deductPendingOverdraft = false}) {
    int effectiveUsed = card.usedSessions;
    if (deductPendingOverdraft) {
      final pendingNotes = _poolOverdraftNotes.where((n) => n.poolType == card.poolType && !n.isDeducted).toList();
      final pendingCount = pendingNotes.fold(0, (sum, n) => sum + n.sessionsCount);
      effectiveUsed += pendingCount;

      // Remove the deducted pending notes (per user request: نخصمهم ونحذفهم من الملاحظات)
      _poolOverdraftNotes.removeWhere((n) => n.poolType == card.poolType && !n.isDeducted);
      _poolOverdraftNotesController.add(List.unmodifiable(_poolOverdraftNotes));
    }

    final cardToSave = card.copyWith(usedSessions: effectiveUsed);
    _waterCards.add(cardToSave);
    _waterCardsController.add(List.unmodifiable(_waterCards));

    // Automated expense entry
    addExpense(
      ExpenseModel(
        id: 'EXP-${cardToSave.id}',
        category: 'كروت مياة',
        amount: cardToSave.cardPrice,
        date: cardToSave.cardDate,
        notes: 'شراء وتفعيل ${cardToSave.cardName} (${cardToSave.poolType})',
        monthYear: cardToSave.monthlyClosingRef,
      ),
    );
    _saveAll();
  }

  // --- Pool Overdraft & Unpaid Sessions Notes (ملاحظات عجز الكروت) ---
  List<PoolOverdraftNoteModel> getPoolOverdraftNotes({String? poolType, bool pendingOnly = true}) {
    return _poolOverdraftNotes.where((n) {
      if (poolType != null && n.poolType != poolType) return false;
      if (pendingOnly && n.isDeducted) return false;
      return true;
    }).toList();
  }

  int getPendingOverdraftSessionsForPool(String poolType) {
    return _poolOverdraftNotes
        .where((n) => n.poolType == poolType && !n.isDeducted)
        .fold(0, (sum, n) => sum + n.sessionsCount);
  }

  void addPoolOverdraftNote(PoolOverdraftNoteModel note) {
    _poolOverdraftNotes.add(note);
    _poolOverdraftNotesController.add(List.unmodifiable(_poolOverdraftNotes));
    _saveAll();
  }

  void deletePoolOverdraftNote(String id) {
    _poolOverdraftNotes.removeWhere((n) => n.id == id);
    _poolOverdraftNotesController.add(List.unmodifiable(_poolOverdraftNotes));
    _saveAll();
  }

  void deductOverdraftNoteFromCard({required String noteId, required String cardId}) {
    final noteIndex = _poolOverdraftNotes.indexWhere((n) => n.id == noteId);
    final cardIndex = _waterCards.indexWhere((c) => c.id == cardId);
    if (noteIndex != -1 && cardIndex != -1) {
      final note = _poolOverdraftNotes[noteIndex];
      final card = _waterCards[cardIndex];

      final newUsed = card.usedSessions + note.sessionsCount;
      _waterCards[cardIndex] = card.copyWith(usedSessions: newUsed);
      _waterCardsController.add(List.unmodifiable(_waterCards));

      _poolOverdraftNotes.removeAt(noteIndex);
      _poolOverdraftNotesController.add(List.unmodifiable(_poolOverdraftNotes));
      _saveAll();
    }
  }

  void deductAllPendingOverdraftForPool({required String poolType, required String cardId}) {
    final cardIndex = _waterCards.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) return;

    final card = _waterCards[cardIndex];
    final pendingNotes = _poolOverdraftNotes.where((n) => n.poolType == poolType && !n.isDeducted).toList();
    if (pendingNotes.isEmpty) return;

    final totalDeduct = pendingNotes.fold(0, (sum, n) => sum + n.sessionsCount);
    _waterCards[cardIndex] = card.copyWith(usedSessions: card.usedSessions + totalDeduct);
    _waterCardsController.add(List.unmodifiable(_waterCards));

    _poolOverdraftNotes.removeWhere((n) => n.poolType == poolType && !n.isDeducted);
    _poolOverdraftNotesController.add(List.unmodifiable(_poolOverdraftNotes));
    _saveAll();
  }

  // --- Coaches & Payroll ---
  List<CoachModel> getCoaches() => List.unmodifiable(_coaches);

  void addCoach(CoachModel coach) {
    _coaches.add(coach);
    _coachesController.add(List.unmodifiable(_coaches));
    _saveAll();
  }

  void updateCoach(CoachModel coach) {
    final index = _coaches.indexWhere((c) => c.coachId == coach.coachId);
    if (index != -1) {
      _coaches[index] = coach;
      _coachesController.add(List.unmodifiable(_coaches));
      _saveAll();
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
    _saveAll();
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
    _saveAll();
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
    _saveAll();
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
    _saveAll();
  }

  void updateUserPassword(String uid, String newPassword) {
    final index = _users.indexWhere((u) => u.uid == uid);
    if (index != -1) {
      _users[index] = _users[index].copyWith(password: newPassword);
      _usersController.add(List.unmodifiable(_users));
      _saveAll();
    }
  }

  void toggleUserActive(String uid, bool isActive) {
    final index = _users.indexWhere((u) => u.uid == uid);
    if (index != -1) {
      _users[index] = _users[index].copyWith(isActive: isActive);
      _usersController.add(List.unmodifiable(_users));
      _saveAll();
    }
  }

  void deleteUser(String uid) {
    _users.removeWhere((u) => u.uid == uid);
    _usersController.add(List.unmodifiable(_users));
    _saveAll();
  }
}
