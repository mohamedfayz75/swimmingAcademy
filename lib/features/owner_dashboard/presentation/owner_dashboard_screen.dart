import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../../coaches_payroll/presentation/coach_payroll_screen.dart';
import '../../subscriptions/presentation/subscriptions_list_screen.dart';
import '../../water_cards/presentation/water_card_screen.dart';
import '../models/expense_model.dart';
import '../providers/dashboard_provider.dart';
import 'expenses_management_screen.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  void _showResetDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text('تصفير البيانات التجريبية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل ترغب في مسح كافة البيانات التجريبية لبدء الأكاديمية على بياض تام ببيانات حقيقية؟',
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '• سيتم مسح اللاعبين، الاشتراكات، فواتير المصروفات، وسجلات الحضور التجريبية.\n• سيتم الحفاظ على حسابات المالك والإداري لتسجيل الدخول بأمان.\n• هذا الإجراء لا يمكن التراجع عنه.',
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.blueGrey.shade700, height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(dashboardRepositoryProvider).wipeAllTestData();
              final currentMonth = ref.read(selectedMonthYearProvider);
              ref.invalidate(monthlyAccountingProvider(currentMonth));
              ref.invalidate(monthlyExpensesStreamProvider(currentMonth));
              if (context.mounted) {
                Navigator.pop(ctx);
                AppDialogs.showSuccessSnackBar(context, 'تم تصفير كافة البيانات التجريبية بنجاح! النظام جاهز الآن للعمل الفعلي.');
              }
            },
            child: const Text('تأكيد التصفير والبدء من الصفر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _changeMonth(WidgetRef ref, int delta) {
    final currentStr = ref.read(selectedMonthYearProvider);
    final parts = currentStr.split('-');
    int month = int.tryParse(parts[0]) ?? DateTime.now().month;
    int year = int.tryParse(parts[1]) ?? DateTime.now().year;

    DateTime d = DateTime(year, month + delta);
    final newMonthStr = '${d.month.toString().padLeft(2, '0')}-${d.year}';
    ref.read(selectedMonthYearProvider.notifier).state = newMonthStr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthYear = ref.watch(selectedMonthYearProvider);
    final accountingAsync = ref.watch(monthlyAccountingProvider(monthYear));
    final expensesAsync = ref.watch(monthlyExpensesStreamProvider(monthYear));

    return Scaffold(
      appBar: AppBar(
        title: const Text('اللوحة المالية والتقفيل الشهري'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'سجل وإدارة المصروفات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpensesManagementScreen()),
              ).then((_) {
                ref.invalidate(monthlyAccountingProvider(monthYear));
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث الحسابات',
            onPressed: () {
              ref.invalidate(monthlyAccountingProvider(monthYear));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Month Header with Prev/Next Switcher
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                    tooltip: 'الشهر السابق',
                    onPressed: () => _changeMonth(ref, -1),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'تقفيل شهر: $monthYear',
                        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                    tooltip: 'الشهر القادم',
                    onPressed: () => _changeMonth(ref, 1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Financial Summary Cards
            accountingAsync.when(
              data: (acc) {
                return Column(
                  children: [
                    // All-Time Cumulative Vault Balance Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade900,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الرصيد التراكمي الإجمالي للخزينة (All-Time Vault)',
                                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  AppFormatters.formatCurrency(acc.allTimeCumulativeVault),
                                  style: GoogleFonts.cairo(
                                    color: acc.allTimeCumulativeVault >= 0 ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Top Monthly Net Profit Highlight Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: acc.isProfitable
                              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                              : [const Color(0xFFB71C1C), const Color(0xFFC62828)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (acc.isProfitable ? Colors.green : Colors.red).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'صافي الربح لشهر $monthYear (Net Profit)',
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppFormatters.formatCurrency(acc.netProfit),
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text('إجمالي إيرادات الشهر', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
                                  Text(
                                    AppFormatters.formatCurrency(acc.totalRevenues),
                                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              Container(height: 30, width: 1, color: Colors.white24),
                              Column(
                                children: [
                                  Text('إجمالي مصروفات الشهر', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
                                  Text(
                                    AppFormatters.formatCurrency(acc.totalExpenses),
                                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Financial Breakdown 2x2 Grid (Interactive Drill-down)
                    Row(
                      children: [
                        _buildFinancialCard(
                          title: 'إيرادات الاشتراكات',
                          amount: acc.totalSubscriptionRevenues,
                          icon: Icons.payments,
                          color: AppTheme.primaryBlue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SubscriptionsListScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildFinancialCard(
                          title: 'إيرادات ختم الكروت',
                          amount: acc.totalStampCardRevenues,
                          icon: Icons.badge,
                          color: AppTheme.accentTeal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WaterCardScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFinancialCard(
                          title: 'رواتب الكباتن',
                          amount: acc.totalCoachPayroll,
                          icon: Icons.sports,
                          color: Colors.deepOrange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CoachPayrollScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildFinancialCard(
                          title: 'تكاليف كروت المياة',
                          amount: acc.totalWaterCardExpenses,
                          icon: Icons.water_drop,
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WaterCardScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFinancialCard(
                      title: 'مصروفات تشغيل أخرى (اضغط للإدارة)',
                      amount: acc.otherExpenses,
                      icon: Icons.receipt_long,
                      color: Colors.brown,
                      isFullWidth: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ExpensesManagementScreen()),
                        ).then((_) {
                          ref.invalidate(monthlyAccountingProvider(monthYear));
                        });
                      },
                    ),
                  ],
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              error: (err, _) => Center(child: Text('خطأ في تحميل الحسابات: $err')),
            ),

            const SizedBox(height: 24),

            // Recent Expenses Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المصروفات المسجلة لهذا الشهر',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExpensesManagementScreen()),
                    ).then((_) {
                      ref.invalidate(monthlyAccountingProvider(monthYear));
                    });
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('إدارة المصروفات بالكامل'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Expenses stream list preview
            expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Text(
                        'لا توجد مصروفات مسجلة لهذا الشهر',
                        style: GoogleFonts.cairo(color: AppTheme.textMuted, fontSize: 14),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length > 5 ? 5 : expenses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final exp = expenses[index];
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade50,
                          child: Icon(Icons.receipt_long, color: Colors.red.shade700, size: 20),
                        ),
                        title: Text(exp.category, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          exp.notes.isNotEmpty ? exp.notes : AppFormatters.formatTimestamp(exp.date),
                          style: GoogleFonts.cairo(fontSize: 12),
                        ),
                        trailing: Text(
                          AppFormatters.formatCurrency(exp.amount),
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppTheme.errorRed, fontSize: 14),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
    VoidCallback? onTap,
  }) {
    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueGrey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 11, color: Colors.grey.shade400),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppFormatters.formatCurrency(amount),
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ],
        ),
      ),
    );

    if (isFullWidth) return content;
    return Expanded(child: content);
  }
}
