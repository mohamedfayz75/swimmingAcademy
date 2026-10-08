import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../models/expense_model.dart';
import '../providers/dashboard_provider.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref, String monthYear) {
    final categoryController = TextEditingController(text: 'صيانة ومواد تعقيم');
    final amountController = TextEditingController(text: '300.0');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تسجيل مصروف جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'بند المصروف (القسم)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ (ج.م)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'ملاحظات / بيان'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              final expense = ExpenseModel(
                id: '',
                category: categoryController.text.trim(),
                amount: amount,
                date: Timestamp.now(),
                notes: notesController.text.trim(),
                monthYear: monthYear,
              );

              await ref.read(dashboardRepositoryProvider).addExpense(expense);
              if (context.mounted) {
                Navigator.pop(ctx);
                AppDialogs.showSuccessSnackBar(context, 'تم تسجيل المصروف بنجاح');
                ref.invalidate(monthlyAccountingProvider(monthYear));
              }
            },
            child: const Text('حفظ المصروف'),
          ),
        ],
      ),
    );
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
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'إضافة مصروف',
            onPressed: () => _showAddExpenseDialog(context, ref, monthYear),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Month Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'تقفيل شهر: $monthYear',
                        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'المالك العام (Super Admin)',
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Financial Summary Cards
            accountingAsync.when(
              data: (acc) {
                return Column(
                  children: [
                    // Top Net Profit Highlight Card
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
                            'صافي الربح الشهري (Net Profit)',
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
                                  Text('إجمالي الإيرادات', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
                                  Text(
                                    AppFormatters.formatCurrency(acc.totalRevenues),
                                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              Container(height: 30, width: 1, color: Colors.white24),
                              Column(
                                children: [
                                  Text('إجمالي المصروفات', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
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

                    const SizedBox(height: 20),

                    // Financial Breakdown 2x2 Grid
                    Row(
                      children: [
                        _buildFinancialCard(
                          title: 'إيرادات الاشتراكات',
                          amount: acc.totalSubscriptionRevenues,
                          icon: Icons.payments,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 12),
                        _buildFinancialCard(
                          title: 'إيرادات ختم الكروت',
                          amount: acc.totalStampCardRevenues,
                          icon: Icons.badge,
                          color: AppTheme.accentTeal,
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
                        ),
                        const SizedBox(width: 12),
                        _buildFinancialCard(
                          title: 'تكاليف كروت المياة',
                          amount: acc.totalWaterCardExpenses,
                          icon: Icons.water_drop,
                          color: Colors.indigo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFinancialCard(
                      title: 'مصروفات تشغيل أخرى',
                      amount: acc.otherExpenses,
                      icon: Icons.receipt,
                      color: Colors.brown,
                      isFullWidth: true,
                    ),
                  ],
                );
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )),
              error: (err, _) => Center(child: Text('خطأ في حساب التقفيل الشهري: $err')),
            ),

            const SizedBox(height: 28),

            // Expenses Breakdown Section
            Text(
              'سجل المصروفات والنثريات المسجلة لهذا الشهر',
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 12),

            expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'لا توجد مصروفات مسجلة لشهر $monthYear',
                        style: GoogleFonts.cairo(color: AppTheme.textMuted),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final exp = expenses[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.brown.withOpacity(0.1),
                          child: const Icon(Icons.receipt_long, color: Colors.brown),
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
  }) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100),
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
              Text(
                title,
                style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
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
    );

    if (isFullWidth) return content;
    return Expanded(child: content);
  }
}
