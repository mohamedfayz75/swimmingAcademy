import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/rbac/app_role.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/dialogs.dart';
import 'data/local/local_store.dart';
import 'data/firebase/cloud_sync_service.dart';
import 'features/attendance/presentation/qr_attendance_scanner_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/coaches_payroll/presentation/coach_payroll_screen.dart';
import 'features/coaches_payroll/presentation/coaches_list_screen.dart';
import 'features/groups/presentation/groups_management_screen.dart';
import 'features/groups/presentation/pool_slot_matrix_screen.dart';
import 'features/owner_dashboard/presentation/group_attendees_screen.dart';
import 'features/owner_dashboard/presentation/owner_dashboard_screen.dart';
import 'features/owner_dashboard/presentation/expenses_management_screen.dart';
import 'features/players/presentation/player_registration_screen.dart';
import 'features/players/presentation/players_list_screen.dart';
import 'features/subscriptions/presentation/subscription_entry_screen.dart';
import 'features/subscriptions/presentation/subscriptions_list_screen.dart';
import 'features/auth/presentation/user_management_screen.dart';
import 'features/water_cards/presentation/water_card_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final isOwner = user?.role.isOwner ?? false;

    // Standard Staff & Shared Screens
    final List<Widget> baseScreens = [
      const QRAttendanceScannerScreen(),       // 0: QR Attendance Scanner
      const SubscriptionEntryScreen(),         // 1: New Subscription Entry
      const PlayerRegistrationScreen(),        // 2: Player Registration
      const WaterCardScreen(),                 // 3: Water Card Consumption
      const PoolSlotMatrixScreen(),            // 4: Pool Matrix Schedule
      const PlayersListScreen(),               // 5: Players Directory
      const SubscriptionsListScreen(),         // 6: Subscriptions History
      const GroupAttendeesScreen(),            // 7: Group Attendees & Swimming Roll Call
    ];

    // Owner Dedicated Screens
    final List<Widget> ownerScreens = [
      const OwnerDashboardScreen(),            // 8: Financial Dashboard & Closures
      const ExpensesManagementScreen(),        // 9: Expenses Management & Log
      const CoachPayrollScreen(),              // 10: Coach Payroll & Advances
      const CoachesListScreen(),               // 11: Coaches Directory
      const GroupsManagementScreen(),          // 12: Groups Management
      const UserManagementScreen(),            // 13: Staff & Users Management
    ];

    final List<Widget> screens = [
      ...baseScreens,
      if (isOwner) ...ownerScreens,
    ];

    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    // Titles corresponding to screens
    final List<String> screenTitles = [
      'ماسح باركود الحضور (QR)',
      'تسجيل وحجز اشتراك جديد',
      'تسجيل لاعب جديد',
      'كروت المياة والاستهلاك',
      'جدول المواعيد وسعة الحارات',
      'دليل وبيانات اللاعبين',
      'سجل الاشتراكات والتحصيل',
      'كشف نزول المجموعة والتمام للمسبح',
      if (isOwner) ...[
        'اللوحة المالية والتقفيل الشهري',
        'سجل وإدارة المصروفات',
        'رواتب ومسيرات الكباتن',
        'دليل الكباتن والمدربين',
        'إدارة وإنشاء المجموعات',
        'إدارة المستخدمين والموظفين',
      ],
    ];

    final currentTitle = _currentIndex < screenTitles.length ? screenTitles[_currentIndex] : 'أكاديمية عالم السباحة';

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(currentTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'القائمة الرئيسية',
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          // Live Cloud Sync Action Button
          IconButton(
            icon: const Icon(Icons.cloud_sync, color: Colors.white),
            tooltip: 'مزامنة سحابية فورية',
            onPressed: () async {
              AppDialogs.showSuccessSnackBar(context, 'جاري المزامنة السحابية مع السيرفر...');
              final ok = await CloudSyncService.instance.syncAllData();
              if (context.mounted) {
                if (ok) {
                  AppDialogs.showSuccessSnackBar(context, 'تمت المزامنة بنجاح! جميع البيانات متطابقة الآن.');
                } else {
                  AppDialogs.showWarningSnackBar(
                    context,
                    'تم حفظ البيانات محلياً. ستتم المزامنة تلقائياً بمجرد توفر الاتصال السحابي.',
                  );
                }
              }
            },
          ),
          // Role badge on top
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOwner ? AppTheme.warningOrange.withOpacity(0.15) : AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOwner ? AppTheme.warningOrange : AppTheme.primaryBlue,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOwner ? Icons.admin_panel_settings : Icons.badge,
                  size: 16,
                  color: isOwner ? AppTheme.warningOrange : AppTheme.primaryBlue,
                ),
                const SizedBox(width: 4),
                Text(
                  isOwner ? 'المالك' : 'موظف',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOwner ? AppTheme.warningOrange : AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryLight],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/images/logo.png'),
              ),
              accountName: Text(
                user?.displayName ?? (isOwner ? 'المالك العام' : 'موظف الاستقبال'),
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(
                user?.role.arabicTitle ?? (isOwner ? 'المالك (الإدارة العليا)' : 'موظف الاستقبال'),
                style: GoogleFonts.cairo(color: AppTheme.accentCyan, fontSize: 13),
              ),
            ),

            // Daily Operational Screens (Staff & Owner)
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryBlue),
              title: Text('ماسح باركود الحضور (QR)', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              selected: _currentIndex == 0,
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_membership, color: AppTheme.primaryBlue),
              title: Text('تسجيل اشتراك جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              selected: _currentIndex == 1,
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: AppTheme.primaryBlue),
              title: Text('تسجيل لاعب جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              selected: _currentIndex == 2,
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.water_drop, color: AppTheme.primaryBlue),
              title: Text('كروت المياة والاستهلاك', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              selected: _currentIndex == 3,
              onTap: () {
                setState(() => _currentIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: AppTheme.primaryBlue),
              title: Text('جدول المواعيد وسعة الحارات', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              selected: _currentIndex == 4,
              onTap: () {
                setState(() => _currentIndex = 4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: AppTheme.primaryBlue),
              title: Text('دليل وبيانات اللاعبين', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              selected: _currentIndex == 5,
              onTap: () {
                setState(() => _currentIndex = 5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: AppTheme.primaryBlue),
              title: Text('سجل الاشتراكات والتحصيل', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              selected: _currentIndex == 6,
              onTap: () {
                setState(() => _currentIndex = 6);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pool, color: AppTheme.primaryBlue),
              title: Text('كشف نزول المجموعة والتمام للمسبح', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              selected: _currentIndex == 7,
              onTap: () {
                setState(() => _currentIndex = 7);
                Navigator.pop(context);
              },
            ),

            // Strictly Owner Section
            if (isOwner) ...[
              const Divider(thickness: 1.5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.warningOrange.withOpacity(0.08),
                child: Row(
                  children: [
                    const Icon(Icons.security, size: 16, color: AppTheme.warningOrange),
                    const SizedBox(width: 6),
                    Text(
                      'قسم المالك العام والإدارة العليا',
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.warningOrange),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.analytics, color: AppTheme.warningOrange),
                title: Text('اللوحة المالية والتقفيل الشهري', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                selected: _currentIndex == 8,
                onTap: () {
                  setState(() => _currentIndex = 8);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: AppTheme.warningOrange),
                title: Text('سجل وإدارة المصروفات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                selected: _currentIndex == 9,
                onTap: () {
                  setState(() => _currentIndex = 9);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.payments, color: AppTheme.warningOrange),
                title: Text('رواتب ومسيرات الكباتن', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                selected: _currentIndex == 10,
                onTap: () {
                  setState(() => _currentIndex = 10);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sports, color: AppTheme.warningOrange),
                title: Text('دليل الكباتن والمدربين', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                selected: _currentIndex == 11,
                onTap: () {
                  setState(() => _currentIndex = 11);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune, color: AppTheme.warningOrange),
                title: Text('إدارة وإنشاء المجموعات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                selected: _currentIndex == 12,
                onTap: () {
                  setState(() => _currentIndex = 12);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.manage_accounts, color: AppTheme.warningOrange),
                title: Text('إدارة المستخدمين والموظفين', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                selected: _currentIndex == 13,
                onTap: () {
                  setState(() => _currentIndex = 13);
                  Navigator.pop(context);
                },
              ),
            ],

            const Divider(thickness: 1.5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primaryBlue.withOpacity(0.08),
              child: Row(
                children: [
                  const Icon(Icons.security_update_good, size: 16, color: AppTheme.primaryBlue),
                  const SizedBox(width: 6),
                  Text(
                    'أمان وحفظ البيانات والنسخ الاحتياطي',
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.backup_rounded, color: AppTheme.primaryBlue),
              title: Text('النسخ الاحتياطي واسترجاع البيانات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              subtitle: Text('نسخ كود البيانات بالكامل أو استرجاعه في أي وقت', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted)),
              onTap: () {
                Navigator.pop(context);
                _showBackupRestoreDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_rounded, color: AppTheme.successGreen),
              title: Text('تثبيت وحفظ جميع البيانات الآن 💾', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
              subtitle: Text('حفظ فوري وشامل للاعبين والاشتراكات والمجموعات', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted)),
              onTap: () async {
                Navigator.pop(context);
                await LocalStore.instance.saveAllExplicitly();
                if (mounted) {
                  AppDialogs.showSuccessSnackBar(context, '💾 تم حفظ وتثبيت جميع اللاعبين والاشتراكات والمجموعات بنجاح في الذاكرة الدائمة!');
                }
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorRed),
              title: Text('تسجيل الخروج', style: GoogleFonts.cairo(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                ref.read(currentUserProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: () {
          if (_currentIndex == 0) return 0;
          if (_currentIndex == 1) return 1;
          if (_currentIndex == 3) return 2;
          if (isOwner && _currentIndex == 8) return 3;
          if (isOwner && _currentIndex == 13) return 4;
          return 0;
        }(),
        onDestinationSelected: (idx) {
          if (idx == 0) setState(() => _currentIndex = 0);
          if (idx == 1) setState(() => _currentIndex = 1);
          if (idx == 2) setState(() => _currentIndex = 3);
          if (isOwner && idx == 3) setState(() => _currentIndex = 8);
          if (isOwner && idx == 4) setState(() => _currentIndex = 13);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner, color: AppTheme.primaryBlue),
            label: 'الحضور',
          ),
          const NavigationDestination(
            icon: Icon(Icons.card_membership_outlined),
            selectedIcon: Icon(Icons.card_membership, color: AppTheme.primaryBlue),
            label: 'اشتراك جديد',
          ),
          const NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop, color: AppTheme.primaryBlue),
            label: 'كروت المياة',
          ),
          if (isOwner) ...[
            const NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics, color: AppTheme.warningOrange),
              label: 'الخزينة والأرباح',
            ),
            const NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts, color: AppTheme.warningOrange),
              label: 'المستخدمين',
            ),
          ],
        ],
      ),
    );
  }

  void _showBackupRestoreDialog(BuildContext context) {
    int activeTab = 0; // 0 = تصدير (نسخ الكود), 1 = استرجاع (لصق الكود)
    final restoreController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final backupJson = LocalStore.instance.exportBackupJson();
          final playersCount = LocalStore.instance.getPlayers().length;
          final subsCount = LocalStore.instance.getSubscriptions().length;
          final groupsCount = LocalStore.instance.getGroups().length;
          final cardsCount = LocalStore.instance.getWaterCards().length;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.cloud_sync, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text('النسخ الاحتياطي واسترجاع البيانات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // تبويب الاختيار
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment<int>(
                          value: 0,
                          label: Text('تصدير نسخة (نسخ)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          icon: Icon(Icons.file_download, size: 16),
                        ),
                        ButtonSegment<int>(
                          value: 1,
                          label: Text('استرجاع نسخة (لصق)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          icon: Icon(Icons.file_upload, size: 16),
                        ),
                      ],
                      selected: {activeTab},
                      onSelectionChanged: (set) => setModalState(() => activeTab = set.first),
                    ),
                    const SizedBox(height: 16),

                    if (activeTab == 0) ...[
                      // ملخص البيانات الحالية
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blueGrey.shade100),
                        ),
                        child: Column(
                          children: [
                            Text('البيانات الحالية الجاهزة للتصدير:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildBackupItemChip('اللاعبين', '$playersCount', AppTheme.primaryBlue),
                                _buildBackupItemChip('الاشتراكات', '$subsCount', AppTheme.successGreen),
                                _buildBackupItemChip('المجموعات', '$groupsCount', AppTheme.warningOrange),
                                _buildBackupItemChip('كروت المياة', '$cardsCount', AppTheme.accentTeal),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '💡 اضغط على الزر أدناه لنسخ كود البيانات بالكامل إلى الحافظة. يمكنك حفظه في ملف نصي أو إرساله في رسالة لنفسك على الواتساب للاحتفاظ بنسخة احتياطية آمنة.',
                        style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.copy, size: 18),
                        label: Text('📋 نسخ كود النسخة الاحتياطية بالكامل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: backupJson));
                          AppDialogs.showSuccessSnackBar(
                            context,
                            'تم نسخ كود النسخة الاحتياطية بنجاح إلى الحافظة! ($playersCount لاعب - $subsCount اشتراك)',
                          );
                        },
                      ),
                    ] else ...[
                      Text(
                        'الصق كود النسخة الاحتياطية (JSON) المستخرج مسبقاً لاسترجاع جميع اللاعبين والاشتراكات فوراً:',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: restoreController,
                        maxLines: 6,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: 'الصق كود البيانات هنا...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.warningOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.restore, size: 18),
                        label: Text('تأكيد استرجاع البيانات الآن', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final text = restoreController.text.trim();
                          if (text.isEmpty) {
                            AppDialogs.showErrorSnackBar(context, 'يرجى لصق كود النسخة الاحتياطية أولاً');
                            return;
                          }

                          final ok = LocalStore.instance.importBackupJson(text);
                          if (ok) {
                            await LocalStore.instance.saveAllExplicitly();
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              AppDialogs.showSuccessSnackBar(context, '🎉 تم استرجاع جميع البيانات وتثبيتها بنجاح!');
                              setState(() {});
                            }
                          } else {
                            AppDialogs.showErrorSnackBar(context, 'فشل الاسترجاع: الكود الذي قمت بلصقه غير صالح أو غير مكتمل');
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إغلاق', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackupItemChip(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }
}
