import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../features/attendance/models/attendance_model.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/groups/models/group_model.dart';
import '../../features/owner_dashboard/models/accounting_model.dart';
import '../../features/owner_dashboard/models/expense_model.dart';
import '../../features/owner_dashboard/models/payroll_model.dart';
import '../../features/players/models/player_model.dart';
import '../../features/subscriptions/models/subscription_model.dart';
import '../../features/water_cards/models/pool_overdraft_model.dart';
import '../../features/water_cards/models/water_card_model.dart';
import '../local/local_store.dart';

class CloudSyncService {
  static final CloudSyncService instance = CloudSyncService._internal();
  CloudSyncService._internal();

  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _hasActiveListeners = false;

  // Stream subscriptions
  final List<StreamSubscription> _subscriptions = [];

  bool get isSyncing => _isSyncing;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // 1. Ensure anonymous authentication for Firestore access rules
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously().timeout(
            const Duration(seconds: 4),
            onTimeout: () => null as dynamic,
          );
        }
      } catch (authErr) {
        debugPrint('Anonymous auth warning: $authErr');
      }

      // 2. Start real-time listeners for live synchronization
      _startLiveListeners();
    } catch (e) {
      debugPrint('CloudSyncService init warning: $e');
    }
  }

  void _startLiveListeners() {
    if (_hasActiveListeners) return;
    _hasActiveListeners = true;

    final firestore = FirebaseFirestore.instance;

    // 1. Players
    _subscriptions.add(
      firestore.collection('players').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final List<PlayerModel> remote = [];
            for (final doc in snapshot.docs) {
              try {
                remote.add(PlayerModel.fromFirestore(doc));
              } catch (_) {}
            }
            if (remote.isNotEmpty) {
              LocalStore.instance.mergeRemotePlayers(remote);
            }
          }
        },
        onError: (e) => debugPrint('Live sync players error: $e'),
      ),
    );

    // 2. Subscriptions
    _subscriptions.add(
      firestore.collection('subscriptions').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final List<SubscriptionModel> remote = [];
            for (final doc in snapshot.docs) {
              try {
                remote.add(SubscriptionModel.fromFirestore(doc));
              } catch (_) {}
            }
            if (remote.isNotEmpty) {
              LocalStore.instance.mergeRemoteSubscriptions(remote);
            }
          }
        },
        onError: (e) => debugPrint('Live sync subscriptions error: $e'),
      ),
    );

    // 3. Attendance
    _subscriptions.add(
      firestore.collection('attendance').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final List<AttendanceModel> remote = [];
            for (final doc in snapshot.docs) {
              try {
                remote.add(AttendanceModel.fromFirestore(doc));
              } catch (_) {}
            }
            if (remote.isNotEmpty) {
              LocalStore.instance.mergeRemoteAttendance(remote);
            }
          }
        },
        onError: (e) => debugPrint('Live sync attendance error: $e'),
      ),
    );

    // 4. Groups
    _subscriptions.add(
      firestore.collection('groups').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final List<GroupModel> remote = [];
            for (final doc in snapshot.docs) {
              try {
                remote.add(GroupModel.fromFirestore(doc));
              } catch (_) {}
            }
            if (remote.isNotEmpty) {
              LocalStore.instance.mergeRemoteGroups(remote);
            }
          }
        },
        onError: (e) => debugPrint('Live sync groups error: $e'),
      ),
    );

    // 5. Expenses
    _subscriptions.add(
      firestore.collection('expenses').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final List<ExpenseModel> remote = [];
            for (final doc in snapshot.docs) {
              try {
                remote.add(ExpenseModel.fromFirestore(doc));
              } catch (_) {}
            }
            if (remote.isNotEmpty) {
              LocalStore.instance.mergeRemoteExpenses(remote);
            }
          }
        },
        onError: (e) => debugPrint('Live sync expenses error: $e'),
      ),
    );

    // 6. Water Cards
    _subscriptions.add(
      firestore.collection('water_cards').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final List<WaterCardModel> remote = [];
            for (final doc in snapshot.docs) {
              try {
                remote.add(WaterCardModel.fromFirestore(doc));
              } catch (_) {}
            }
            if (remote.isNotEmpty) {
              LocalStore.instance.mergeRemoteWaterCards(remote);
            }
          }
        },
        onError: (e) => debugPrint('Live sync water_cards error: $e'),
      ),
    );

    // 7. Pool Overdraft Notes
    _subscriptions.add(
      firestore.collection('pool_overdraft_notes').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final List<PoolOverdraftNoteModel> remote = [];
            for (final doc in snapshot.docs) {
              try {
                remote.add(PoolOverdraftNoteModel.fromFirestore(doc));
              } catch (_) {}
            }
            if (remote.isNotEmpty) {
              LocalStore.instance.mergeRemotePoolOverdraftNotes(remote);
            }
          }
        },
        onError: (e) => debugPrint('Live sync pool_overdraft_notes error: $e'),
      ),
    );

    // 8. Coaches
    _subscriptions.add(
      firestore.collection('coaches').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final List<CoachModel> remote = [];
            for (final doc in snapshot.docs) {
              try {
                remote.add(CoachModel.fromFirestore(doc));
              } catch (_) {}
            }
            if (remote.isNotEmpty) {
              LocalStore.instance.mergeRemoteCoaches(remote);
            }
          }
        },
        onError: (e) => debugPrint('Live sync coaches error: $e'),
      ),
    );

    // 9. Users
    _subscriptions.add(
      firestore.collection('users').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final List<UserModel> remote = [];
            for (final doc in snapshot.docs) {
              try {
                remote.add(UserModel.fromFirestore(doc));
              } catch (_) {}
            }
            if (remote.isNotEmpty) {
              LocalStore.instance.mergeRemoteUsers(remote);
            }
          }
        },
        onError: (e) => debugPrint('Live sync users error: $e'),
      ),
    );
  }

  // --- Outgoing Push Methods (Fire & Forget, offline safe) ---

  Future<void> pushPlayer(PlayerModel player) async {
    try {
      await FirebaseFirestore.instance
          .collection('players')
          .doc(player.playerCode)
          .set(player.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushPlayer error: $e');
    }
  }

  Future<void> deletePlayer(String playerCode) async {
    try {
      await FirebaseFirestore.instance.collection('players').doc(playerCode).delete();
    } catch (e) {
      debugPrint('CloudSync deletePlayer error: $e');
    }
  }

  Future<void> pushSubscription(SubscriptionModel sub) async {
    try {
      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(sub.id)
          .set(sub.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushSubscription error: $e');
    }
  }

  Future<void> deleteSubscription(String id) async {
    try {
      await FirebaseFirestore.instance.collection('subscriptions').doc(id).delete();
    } catch (e) {
      debugPrint('CloudSync deleteSubscription error: $e');
    }
  }

  Future<void> pushAttendance(AttendanceModel att) async {
    try {
      await FirebaseFirestore.instance
          .collection('attendance')
          .doc(att.id)
          .set(att.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushAttendance error: $e');
    }
  }

  Future<void> pushGroup(GroupModel group) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.groupCode)
          .set(group.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushGroup error: $e');
    }
  }

  Future<void> deleteGroup(String groupCode) async {
    try {
      await FirebaseFirestore.instance.collection('groups').doc(groupCode).delete();
    } catch (e) {
      debugPrint('CloudSync deleteGroup error: $e');
    }
  }

  Future<void> pushExpense(ExpenseModel expense) async {
    try {
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(expense.id)
          .set(expense.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushExpense error: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await FirebaseFirestore.instance.collection('expenses').doc(id).delete();
    } catch (e) {
      debugPrint('CloudSync deleteExpense error: $e');
    }
  }

  Future<void> pushWaterCard(WaterCardModel card) async {
    try {
      await FirebaseFirestore.instance
          .collection('water_cards')
          .doc(card.id)
          .set(card.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushWaterCard error: $e');
    }
  }

  Future<void> pushPoolOverdraftNote(PoolOverdraftNoteModel note) async {
    try {
      await FirebaseFirestore.instance
          .collection('pool_overdraft_notes')
          .doc(note.id)
          .set(note.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushPoolOverdraftNote error: $e');
    }
  }

  Future<void> pushCoach(CoachModel coach) async {
    try {
      await FirebaseFirestore.instance
          .collection('coaches')
          .doc(coach.id)
          .set(coach.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushCoach error: $e');
    }
  }

  Future<void> deleteCoach(String id) async {
    try {
      await FirebaseFirestore.instance.collection('coaches').doc(id).delete();
    } catch (e) {
      debugPrint('CloudSync deleteCoach error: $e');
    }
  }

  Future<void> pushPayroll(PayrollModel payroll) async {
    try {
      await FirebaseFirestore.instance
          .collection('payroll')
          .doc(payroll.id)
          .set(payroll.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushPayroll error: $e');
    }
  }

  Future<void> pushUser(UserModel user) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(user.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushUser error: $e');
    }
  }

  /// Full bi-directional sync on demand: Uploads all local records to Firestore
  /// and pulls down any remote data that is missing locally.
  Future<bool> syncAllData() async {
    if (_isSyncing) return false;
    _isSyncing = true;

    try {
      final store = LocalStore.instance;
      final firestore = FirebaseFirestore.instance;

      // 1. Upload Players
      for (final player in store.getPlayers()) {
        await firestore.collection('players').doc(player.playerCode).set(player.toFirestore(), SetOptions(merge: true));
      }

      // 2. Upload Subscriptions
      for (final sub in store.getSubscriptions()) {
        await firestore.collection('subscriptions').doc(sub.id).set(sub.toFirestore(), SetOptions(merge: true));
      }

      // 3. Upload Groups
      for (final group in store.getGroups()) {
        await firestore.collection('groups').doc(group.groupCode).set(group.toFirestore(), SetOptions(merge: true));
      }

      // 4. Upload Attendance
      for (final att in store.getAttendance()) {
        await firestore.collection('attendance').doc(att.id).set(att.toFirestore(), SetOptions(merge: true));
      }

      // 5. Upload Expenses
      for (final exp in store.getExpenses()) {
        await firestore.collection('expenses').doc(exp.id).set(exp.toFirestore(), SetOptions(merge: true));
      }

      // 6. Upload Water Cards
      for (final wc in store.getWaterCards()) {
        await firestore.collection('water_cards').doc(wc.id).set(wc.toFirestore(), SetOptions(merge: true));
      }

      // 7. Upload Coaches
      for (final c in store.getCoaches()) {
        await firestore.collection('coaches').doc(c.id).set(c.toFirestore(), SetOptions(merge: true));
      }

      // 8. Upload Users
      for (final u in store.getUsers()) {
        await firestore.collection('users').doc(u.uid).set(u.toFirestore(), SetOptions(merge: true));
      }

      // Pull fresh data from cloud
      final playersSnap = await firestore.collection('players').get();
      if (playersSnap.docs.isNotEmpty) {
        final List<PlayerModel> pList = [];
        for (final d in playersSnap.docs) {
          try {
            pList.add(PlayerModel.fromFirestore(d));
          } catch (_) {}
        }
        store.mergeRemotePlayers(pList);
      }

      final subsSnap = await firestore.collection('subscriptions').get();
      if (subsSnap.docs.isNotEmpty) {
        final List<SubscriptionModel> sList = [];
        for (final d in subsSnap.docs) {
          try {
            sList.add(SubscriptionModel.fromFirestore(d));
          } catch (_) {}
        }
        store.mergeRemoteSubscriptions(sList);
      }

      _isSyncing = false;
      return true;
    } catch (e) {
      debugPrint('syncAllData error: $e');
      _isSyncing = false;
      return false;
    }
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _hasActiveListeners = false;
  }
}
