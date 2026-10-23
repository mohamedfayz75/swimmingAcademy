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
import '../firebase/cloud_sync_service.dart';

class LocalStore {
  static final LocalStore instance = LocalStore._internal();

  LocalStore._internal();

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
  final _payrollsController = StreamController<List<PayrollModel>>.broadcast();

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

  Stream<List<PayrollModel>> get payrollsStream async* {
    yield List.unmodifiable(_payrolls);
    yield* _payrollsController.stream;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasData = prefs.getBool('sw_data_initialized') ?? false;

      if (!hasData) {
        // Very first launch on fresh install: seed starter sample data
        _initSampleData();
        await prefs.setBool('sw_data_initialized', true);
        await _saveAll();
      } else {
        // App has been initialized: load saved state faithfully (including wiped/empty state)
        
        // 1. Players
        final playersJson = prefs.getString('sw_players');
        if (playersJson != null) {
          try {
            final List list = jsonDecode(playersJson);
            _players.clear();
            for (final item in list) {
              try {
                _players.add(PlayerModel.fromMap(Map<String, dynamic>.from(item)));
              } catch (_) {}
            }
          } catch (e) {
            debugPrint('Error decoding sw_players: $e');
          }
        }

        // 2. Subscriptions
        final subsJson = prefs.getString('sw_subscriptions');
        if (subsJson != null) {
          try {
            final List list = jsonDecode(subsJson);
            _subscriptions.clear();
            for (final item in list) {
              try {
                _subscriptions.add(SubscriptionModel.fromMap(Map<String, dynamic>.from(item)));
              } catch (_) {}
            }
          } catch (e) {
            debugPrint('Error decoding sw_subscriptions: $e');
          }
        }

        // 3. Groups
        final groupsJson = prefs.getString('sw_groups');
        if (groupsJson != null) {
          try {
            final List list = jsonDecode(groupsJson);
            _groups.clear();
            for (final item in list) {
              try {
                _groups.add(GroupModel.fromMap(Map<String, dynamic>.from(item)));
              } catch (_) {}
            }
          } catch (e) {
            debugPrint('Error decoding sw_groups: $e');
          }
        }

        // 4. Attendance
        final attJson = prefs.getString('sw_attendance');
        if (attJson != null) {
          try {
            final List list = jsonDecode(attJson);
            _attendance.clear();
            for (final item in list) {
              try {
                _attendance.add(AttendanceModel.fromMap(Map<String, dynamic>.from(item)));
              } catch (_) {}
            }
          } catch (e) {
            debugPrint('Error decoding sw_attendance: $e');
          }
        }

        // 5. Water Cards
        final wcJson = prefs.getString('sw_water_cards');
        if (wcJson != null) {
          try {
            final List list = jsonDecode(wcJson);
            _waterCards.clear();
            for (final item in list) {
              try {
                _waterCards.add(WaterCardModel.fromMap(Map<String, dynamic>.from(item)));
              } catch (_) {}
            }
          } catch (e) {
            debugPrint('Error decoding sw_water_cards: $e');
          }
        }

        // 6. Pool Overdraft Notes
        final ponJson = prefs.getString('sw_pool_overdraft_notes');
        if (ponJson != null) {
          try {
            final List list = jsonDecode(ponJson);
            _poolOverdraftNotes.clear();
            for (final item in list) {
              try {
                _poolOverdraftNotes.add(PoolOverdraftNoteModel.fromMap(Map<String, dynamic>.from(item)));
              } catch (_) {}
            }
          } catch (e) {
            debugPrint('Error decoding sw_pool_overdraft_notes: $e');
          }
        }

        // 7. Coaches
        final coachesJson = prefs.getString('sw_coaches');
        if (coachesJson != null) {
          try {
            final List list = jsonDecode(coachesJson);
            _coaches.clear();
            for (final item in list) {
              try {
                _coaches.add(CoachModel.fromMap(Map<String, dynamic>.from(item)));
              } catch (_) {}
            }
          } catch (e) {
            debugPrint('Error decoding sw_coaches: $e');
          }
        }

        // 8. Payrolls
        final payrollsJson = prefs.getString('sw_payrolls');
        if (payrollsJson != null) {
          try {
            final List list = jsonDecode(payrollsJson);
            _payrolls.clear();
            for (final item in list) {
              try {
                _payrolls.add(PayrollModel.fromMap(Map<String, dynamic>.from(item)));
              } catch (_) {}
            }
          } catch (e) {
            debugPrint('Error decoding sw_payrolls: $e');
          }
        }

        // 9. Expenses
        final expJson = prefs.getString('sw_expenses');
        if (expJson != null) {
          try {
            final List list = jsonDecode(expJson);
            _expenses.clear();
            for (final item in list) {
              try {
                _expenses.add(ExpenseModel.fromMap(Map<String, dynamic>.from(item)));
              } catch (_) {}
            }
          } catch (e) {
            debugPrint('Error decoding sw_expenses: $e');
          }
        }

        // 10. Users
        final usersJson = prefs.getString('sw_users');
        if (usersJson != null) {
          try {
            final List list = jsonDecode(usersJson);
            _users.clear();
            for (final item in list) {
              try {
                _users.add(UserModel.fromMap(Map<String, dynamic>.from(item)));
              } catch (_) {}
            }
          } catch (e) {
            debugPrint('Error decoding sw_users: $e');
          }
        }

        // Deduplicate any duplicate usernames loaded from storage
        final Map<String, UserModel> uniqueUsers = {};
        for (final u in _users) {
          uniqueUsers[u.username.trim().toLowerCase()] = u;
        }
        _users.clear();
        _users.addAll(uniqueUsers.values);

        // Automatic cleanup of legacy prototype demo records
        _players.removeWhere((p) => (p.playerCode == 'SW-101' && p.playerName.contains('يوسف')) || (p.playerCode == 'SW-102' && p.playerName.contains('مريم')));
        _subscriptions.removeWhere((s) => s.id == 'SUB-101' || s.id == 'SUB-102');
        _coaches.removeWhere((c) => (c.coachId == 'COACH-01' && c.coachName.contains('أحمد سامي')) || (c.coachId == 'COACH-02' && c.coachName.contains('محمود رزق')) || (c.coachId == 'COACH-03' && c.coachName.contains('طارق عبد الله')));
        _groups.removeWhere((g) => (g.groupCode == 'GRP-02' && g.coachName.contains('محمود رزق')) || (g.groupCode == 'GRP-03' && g.coachName.contains('طارق عبد الله')));
        _expenses.removeWhere((e) => e.id == 'EXP-WC-01' || e.id == 'EXP-WC-02' || e.id == 'EXP-03');
        _waterCards.removeWhere((w) => w.id == 'WC-01' || w.id == 'WC-02');
        _payrolls.removeWhere((p) => p.coachId == 'COACH-01' && p.coachName.contains('أحمد سامي'));

        // Fallback: If for any reason users list is empty, ensure default admin/owner accounts exist
        if (_users.isEmpty) {
          _initDefaultUsers();
        }
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

  // --- Live Cloud Merge Methods ---
  void mergeRemotePlayers(List<PlayerModel> remote) {
    bool changed = false;
    for (final p in remote) {
      final index = _players.indexWhere((x) => x.playerCode == p.playerCode);
      if (index != -1) {
        _players[index] = p;
        changed = true;
      } else {
        _players.insert(0, p);
        changed = true;
      }
    }
    if (changed) {
      _playersController.add(List.unmodifiable(_players));
      _saveAll();
    }
  }

  void mergeRemoteSubscriptions(List<SubscriptionModel> remote) {
    bool changed = false;
    for (final s in remote) {
      final index = _subscriptions.indexWhere((x) => x.id == s.id);
      if (index != -1) {
        _subscriptions[index] = s;
        changed = true;
      } else {
        _subscriptions.insert(0, s);
        changed = true;
      }
    }
    if (changed) {
      _subscriptionsController.add(List.unmodifiable(_subscriptions));
      _saveAll();
    }
  }

  void mergeRemoteAttendance(List<AttendanceModel> remote) {
    bool changed = false;
    for (final a in remote) {
      final index = _attendance.indexWhere((x) => x.id == a.id);
      if (index != -1) {
        _attendance[index] = a;
        changed = true;
      } else {
        _attendance.insert(0, a);
        changed = true;
      }
    }
    if (changed) {
      _attendanceController.add(List.unmodifiable(_attendance));
      _saveAll();
    }
  }

  void mergeRemoteGroups(List<GroupModel> remote) {
    bool changed = false;
    for (final g in remote) {
      final index = _groups.indexWhere((x) => x.groupCode == g.groupCode);
      if (index != -1) {
        _groups[index] = g;
        changed = true;
      } else {
        _groups.add(g);
        changed = true;
      }
    }
    if (changed) {
      _groupsController.add(List.unmodifiable(_groups));
      _saveAll();
    }
  }

  void mergeRemoteExpenses(List<ExpenseModel> remote) {
    bool changed = false;
    for (final e in remote) {
      final index = _expenses.indexWhere((x) => x.id == e.id);
      if (index != -1) {
        _expenses[index] = e;
        changed = true;
      } else {
        _expenses.insert(0, e);
        changed = true;
      }
    }
    if (changed) {
      _expensesController.add(List.unmodifiable(_expenses));
      _saveAll();
    }
  }

  void mergeRemoteWaterCards(List<WaterCardModel> remote) {
    bool changed = false;
    for (final w in remote) {
      final index = _waterCards.indexWhere((x) => x.id == w.id);
      if (index != -1) {
        _waterCards[index] = w;
        changed = true;
      } else {
        _waterCards.add(w);
        changed = true;
      }
    }
    if (changed) {
      _waterCardsController.add(List.unmodifiable(_waterCards));
      _saveAll();
    }
  }

  void mergeRemotePoolOverdraftNotes(List<PoolOverdraftNoteModel> remote) {
    bool changed = false;
    for (final n in remote) {
      final index = _poolOverdraftNotes.indexWhere((x) => x.id == n.id);
      if (index != -1) {
        _poolOverdraftNotes[index] = n;
        changed = true;
      } else {
        _poolOverdraftNotes.add(n);
        changed = true;
      }
    }
    if (changed) {
      _poolOverdraftNotesController.add(List.unmodifiable(_poolOverdraftNotes));
      _saveAll();
    }
  }

  void mergeRemotePayrolls(List<PayrollModel> remote) {
    bool changed = false;
    for (final p in remote) {
      final index = _payrolls.indexWhere((x) => x.coachId == p.coachId && x.monthYear == p.monthYear);
      if (index != -1) {
        _payrolls[index] = p;
        changed = true;
      } else {
        _payrolls.add(p);
        changed = true;
      }
    }
    if (changed) {
      _payrollsController.add(List.unmodifiable(_payrolls));
      _saveAll();
    }
  }

  void mergeRemoteCoaches(List<CoachModel> remote) {
    bool changed = false;
    for (final c in remote) {
      final index = _coaches.indexWhere((x) => x.coachId == c.coachId);
      if (index != -1) {
        _coaches[index] = c;
        changed = true;
      } else {
        _coaches.add(c);
        changed = true;
      }
    }
    if (changed) {
      _coachesController.add(List.unmodifiable(_coaches));
      _saveAll();
    }
  }

  void mergeRemoteUsers(List<UserModel> remote) {
    bool changed = false;
    for (final u in remote) {
      final index = _users.indexWhere((x) =>
          x.uid == u.uid ||
          x.username.trim().toLowerCase() == u.username.trim().toLowerCase());
      if (index != -1) {
        _users[index] = u;
        changed = true;
      } else {
        _users.add(u);
        changed = true;
      }
    }

    // Final deduplication pass on _users by username
    final Map<String, UserModel> map = {};
    for (final u in _users) {
      map[u.username.trim().toLowerCase()] = u;
    }
    if (map.length != _users.length) {
      _users.clear();
      _users.addAll(map.values);
      changed = true;
    }

    if (changed) {
      _usersController.add(List.unmodifiable(_users));
      _saveAll();
    }
  }

  void _initDefaultUsers() {
    _users.clear();
    final now = Timestamp.now();
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
  }

  void _initSampleData() {
    _initDefaultUsers();
    _players.clear();
    _groups.clear();
    _subscriptions.clear();
    _attendance.clear();
    _waterCards.clear();
    _poolOverdraftNotes.clear();
    _coaches.clear();
    _payrolls.clear();
    _expenses.clear();
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
    _payrollsController.add(List.unmodifiable(_payrolls));
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
    CloudSyncService.instance.pushPlayer(player);
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

  void deletePlayer(String idOrCode) {
    final clean = idOrCode.trim().toUpperCase();
    _players.removeWhere((p) => p.playerCode.trim().toUpperCase() == clean);
    _playersController.add(List.unmodifiable(_players));
    _saveAll();
    CloudSyncService.instance.deletePlayer(clean);
  }

  // --- Groups ---
  List<GroupModel> getGroups() => List.unmodifiable(_groups);

  void addGroup(GroupModel group) {
    _groups.add(group);
    _groupsController.add(List.unmodifiable(_groups));
    _saveAll();
    CloudSyncService.instance.pushGroup(group);
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
      CloudSyncService.instance.pushGroup(_groups[index]);
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
      CloudSyncService.instance.pushGroup(_groups[index]);
    }
  }

  void updateGroup(GroupModel group) {
    final index = _groups.indexWhere((g) => g.groupCode == group.groupCode);
    if (index != -1) {
      _groups[index] = group;
      _groupsController.add(List.unmodifiable(_groups));
      _saveAll();
      CloudSyncService.instance.pushGroup(group);
    }
  }

  void deleteGroup(String groupCode) {
    _groups.removeWhere((g) => g.groupCode == groupCode);
    _groupsController.add(List.unmodifiable(_groups));
    _saveAll();
    CloudSyncService.instance.deleteGroup(groupCode);
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
    final matching = _subscriptions
        .where((s) => s.groupCode.trim().toUpperCase() == clean && !s.isExpired)
        .toList();

    // Deduplicate by playerCode - each swimmer appears once with their latest active subscription
    final Map<String, SubscriptionModel> unique = {};
    for (final s in matching) {
      final code = s.playerCode.trim().toUpperCase();
      if (!unique.containsKey(code)) {
        unique[code] = s;
      }
    }
    return unique.values.toList();
  }

  // --- Subscriptions ---
  List<SubscriptionModel> getSubscriptions() => List.unmodifiable(_subscriptions);

  SubscriptionModel addSubscription(SubscriptionModel sub) {
    final newId = 'SUB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final model = sub.copyWith(id: newId);
    _subscriptions.insert(0, model);

    // Check if player is already registered in this primary group (renewal)
    final bool alreadyInPrimary = _subscriptions.any((s) =>
        s.id != model.id &&
        s.playerCode.trim().toUpperCase() == sub.playerCode.trim().toUpperCase() &&
        s.groupCode.trim().toUpperCase() == sub.groupCode.trim().toUpperCase() &&
        !s.isExpired);

    if (!alreadyInPrimary) {
      // Increment seat in primary group only if not already occupying a seat
      incrementGroupRegistered(sub.groupCode);
    }

    // If custom split schedule, check secondary group as well
    if (sub.secondaryGroupCode != null && sub.secondaryGroupCode!.isNotEmpty) {
      final bool alreadyInSecondary = _subscriptions.any((s) =>
          s.id != model.id &&
          s.playerCode.trim().toUpperCase() == sub.playerCode.trim().toUpperCase() &&
          s.secondaryGroupCode != null &&
          s.secondaryGroupCode!.trim().toUpperCase() == sub.secondaryGroupCode!.trim().toUpperCase() &&
          !s.isExpired);
      if (!alreadyInSecondary) {
        incrementGroupRegistered(sub.secondaryGroupCode!);
      }
    }

    _subscriptionsController.add(List.unmodifiable(_subscriptions));
    _saveAll();
    CloudSyncService.instance.pushSubscription(model);
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
      CloudSyncService.instance.pushSubscription(_subscriptions[index]);
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
      CloudSyncService.instance.pushSubscription(_subscriptions[index]);
    }
  }

  void deleteSubscription(String id) {
    final subIndex = _subscriptions.indexWhere((s) => s.id == id);
    if (subIndex != -1) {
      final sub = _subscriptions[subIndex];
      decrementGroupRegistered(sub.groupCode);
      _subscriptions.removeAt(subIndex);
      _subscriptionsController.add(List.unmodifiable(_subscriptions));
      _saveAll();
      CloudSyncService.instance.deleteSubscription(id);
    }
  }

  // --- Attendance ---
  List<AttendanceModel> getAttendance() => List.unmodifiable(_attendance);

  bool hasPlayerAttendedToday(String playerCode) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final cleanCode = playerCode.trim().toUpperCase();
    return _attendance.any((a) {
      if (a.playerCode.trim().toUpperCase() != cleanCode) return false;
      final date = a.timestamp.toDate();
      return date.isAfter(todayStart);
    });
  }

  AttendanceModel? getRecentAttendanceForPlayer(String playerCode, {int withinMinutes = 60}) {
    final now = DateTime.now();
    final cleanCode = playerCode.trim().toUpperCase();
    for (final a in _attendance) {
      if (a.playerCode.trim().toUpperCase() == cleanCode) {
        final diff = now.difference(a.timestamp.toDate()).inMinutes;
        if (diff >= 0 && diff < withinMinutes) {
          return a;
        }
      }
    }
    return null;
  }

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
      CloudSyncService.instance.pushSubscription(_subscriptions[subIndex]);
    }
    _attendanceController.add(List.unmodifiable(_attendance));
    _saveAll();
    CloudSyncService.instance.pushAttendance(model);
    return model;
  }

  // --- Water Cards (Dual Pool Support) ---
  List<WaterCardModel> getWaterCards() => List.unmodifiable(_waterCards);

  WaterCardModel? getActiveCardForPool(String poolType) {
    try {
      return _waterCards.lastWhere((w) => w.poolType == poolType && !w.isArchived && w.isActive);
    } catch (_) {
      return null;
    }
  }

  void archiveWaterCard(String cardId) {
    final index = _waterCards.indexWhere((w) => w.id == cardId);
    if (index != -1) {
      final current = _waterCards[index];
      _waterCards[index] = current.copyWith(
        isArchived: true,
        usedSessions: current.totalSessions,
      );
      _waterCardsController.add(List.unmodifiable(_waterCards));
      _saveAll();
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
    CloudSyncService.instance.pushWaterCard(cardToSave);
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
    CloudSyncService.instance.pushPoolOverdraftNote(note);
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
    CloudSyncService.instance.pushCoach(coach);
  }

  void updateCoach(CoachModel coach) {
    final index = _coaches.indexWhere((c) => c.coachId == coach.coachId);
    if (index != -1) {
      _coaches[index] = coach;
      _coachesController.add(List.unmodifiable(_coaches));
      _saveAll();
      CloudSyncService.instance.pushCoach(coach);
    }
  }

  void deleteCoach(String coachId) {
    _coaches.removeWhere((c) => c.coachId == coachId);
    _coachesController.add(List.unmodifiable(_coaches));
    _saveAll();
    CloudSyncService.instance.deleteCoach(coachId);
  }

  void logDailyCoachSession(String coachId, int sessionsCount, String monthYear) {
    final index = _payrolls.indexWhere((p) => p.coachId == coachId && p.monthYear == monthYear);
    if (index != -1) {
      final p = _payrolls[index];
      _payrolls[index] = p.copyWith(totalSessions: p.totalSessions + sessionsCount);
      CloudSyncService.instance.pushPayroll(_payrolls[index]);
    } else {
      final coach = _coaches.firstWhere((c) => c.coachId == coachId, orElse: () => _coaches.first);
      final newPayroll = PayrollModel(
        coachId: coachId,
        coachName: coach.coachName,
        totalSessions: sessionsCount,
        sessionRate: 100.0,
        payoutDate: Timestamp.now(),
        monthYear: monthYear,
      );
      _payrolls.add(newPayroll);
      CloudSyncService.instance.pushPayroll(newPayroll);
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
    _payrollsController.add(List.unmodifiable(_payrolls));
    _saveAll();
    CloudSyncService.instance.pushPayroll(payroll);
  }

  List<PayrollModel> getPayrollForMonth(String monthYear) {
    return _payrolls.where((p) => p.monthYear == monthYear).toList();
  }

  // Get accrued uncollected payroll from previous months
  List<PayrollModel> getUnpaidPayrollsBeforeMonth(String currentMonthYear) {
    return _payrolls.where((p) => p.monthYear != currentMonthYear && !p.isPaid).toList();
  }

  // --- Expenses & Accounting ---
  List<ExpenseModel> getExpenses() => List.unmodifiable(_expenses);

  List<ExpenseModel> getExpensesForMonth(String monthYear) {
    return _expenses.where((e) => e.monthYear == monthYear).toList();
  }

  void addExpense(ExpenseModel expense) {
    _expenses.insert(0, expense);
    _expensesController.add(List.unmodifiable(_expenses));
    _saveAll();
    CloudSyncService.instance.pushExpense(expense);
  }

  void updateExpense(ExpenseModel expense) {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      _expensesController.add(List.unmodifiable(_expenses));
      _saveAll();
      CloudSyncService.instance.pushExpense(expense);
    }
  }

  void deleteExpense(String expenseId) {
    _expenses.removeWhere((e) => e.id == expenseId);
    _expensesController.add(List.unmodifiable(_expenses));
    _saveAll();
    CloudSyncService.instance.deleteExpense(expenseId);
  }

  GeneralAccountingModel calculateFinancials(String monthYear) {
    double subRevenues = 0;
    double stampRevenues = 0;
    double allTimeSubRevenues = 0;
    double allTimeStampRevenues = 0;

    for (final s in _subscriptions) {
      allTimeSubRevenues += s.amountPaid;
      allTimeStampRevenues += s.stampCardFee;

      final sDate = s.paymentDate.toDate();
      final sMonthYear = '${sDate.month.toString().padLeft(2, '0')}-${sDate.year}';
      if (sMonthYear == monthYear) {
        subRevenues += s.amountPaid;
        stampRevenues += s.stampCardFee;
      }
    }

    double payrollTotal = 0;
    double allTimePayroll = 0;
    for (final p in _payrolls.where((p) => p.isPaid)) {
      allTimePayroll += p.netPayable;
      if (p.monthYear == monthYear) {
        payrollTotal += p.netPayable;
      }
    }

    double generalExpensesTotal = 0;
    double allTimeExpenses = 0;
    for (final e in _expenses) {
      allTimeExpenses += e.amount;
      if (e.monthYear == monthYear) {
        generalExpensesTotal += e.amount;
      }
    }

    final allTimeVault = (allTimeSubRevenues + allTimeStampRevenues) - (allTimePayroll + allTimeExpenses);

    return GeneralAccountingModel(
      monthYear: monthYear,
      totalSubscriptionRevenues: subRevenues,
      totalStampCardRevenues: stampRevenues,
      totalCoachPayroll: payrollTotal,
      totalWaterCardExpenses: 0,
      otherExpenses: generalExpensesTotal,
      allTimeCumulativeVault: allTimeVault,
    );
  }

  Future<void> wipeAllTestData() async {
    _players.clear();
    _subscriptions.clear();
    _attendance.clear();
    _expenses.clear();
    _waterCards.clear();
    _poolOverdraftNotes.clear();
    _payrolls.clear();

    for (int i = 0; i < _groups.length; i++) {
      _groups[i] = _groups[i].copyWith(currentRegistered: 0);
    }

    _notifyAll();
    _poolOverdraftNotesController.add(List.unmodifiable(_poolOverdraftNotes));

    await _saveAll();
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
    CloudSyncService.instance.pushUser(user);
  }

  void updateUserPassword(String uid, String newPassword) {
    final index = _users.indexWhere((u) => u.uid == uid);
    if (index != -1) {
      _users[index] = _users[index].copyWith(password: newPassword);
      _usersController.add(List.unmodifiable(_users));
      _saveAll();
      CloudSyncService.instance.pushUser(_users[index]);
    }
  }

  void toggleUserActive(String uid, bool isActive) {
    final index = _users.indexWhere((u) => u.uid == uid);
    if (index != -1) {
      _users[index] = _users[index].copyWith(isActive: isActive);
      _usersController.add(List.unmodifiable(_users));
      _saveAll();
      CloudSyncService.instance.pushUser(_users[index]);
    }
  }

  void updateUser(UserModel user) {
    final index = _users.indexWhere((u) => u.uid == user.uid);
    if (index != -1) {
      _users[index] = user;
      _usersController.add(List.unmodifiable(_users));
      _saveAll();
      CloudSyncService.instance.pushUser(user);
    }
  }

  void deleteUser(String uid) {
    _users.removeWhere((u) => u.uid == uid);
    _usersController.add(List.unmodifiable(_users));
    _saveAll();
    CloudSyncService.instance.deleteUser(uid);
  }
}
