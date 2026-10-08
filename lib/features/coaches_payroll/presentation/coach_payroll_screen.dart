import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../../owner_dashboard/models/payroll_model.dart';
import '../../owner_dashboard/providers/dashboard_provider.dart';
import '../providers/coaches_payroll_provider.dart';

class CoachPayrollScreen extends ConsumerStatefulWidget {
  const CoachPayrollScreen({super.key});

  @override
  ConsumerState<CoachPayrollScreen> createState() => _CoachPayrollScreenState();
}

class _CoachPayrollScreenState extends ConsumerState<CoachPayrollScreen> {
  void _openPayrollEntrySheet(CoachModel coach, String monthYear, PayrollModel? existing) {
    final s1Controller = TextEditingController(text: '${existing?.sessions1To10 ?? 0}');
    final s2Controller = TextEditingController(text: '${existing?.sessions11To20 ?? 0}');
    final s3Controller = TextEditingController(text: '${existing?.sessions21To31 ?? 0}');
    final rateController = TextEditingController(text: '${existing?.sessionRate ?? 100.0}');
    final advanceController = TextEditingController(text: '${existing?.advancePayments ?? 0.0}');
    String status = existing?.paymentStatus ?? 'معلق';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final s1 = int.tryParse(s1Controller.text) ?? 0;
            final s2 = int.tryParse(s2Controller.text) ?? 0;
            final s3 = int.tryParse(s3Controller.text) ?? 0;
            final rate = double.tryParse(rateController.text) ?? 0.0;
            final adv = double.tryParse(advanceController.text) ?? 0.0;

            final totalSess = s1 + s2 + s3;
            final totalEarn = totalSess * rate;
            final netPay = (totalEarn - adv) > 0 ? (totalEarn - adv) : 0.0;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'حساب راتب: ${coach.coachName}',
                          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                        Chip(
                          label: Text(monthYear, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: AppTheme.primaryBlue,
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    Text('تسجيل الحصص حسب فترات الشهر الثلاث:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: s1Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'فترة 1 إلى 10'),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: s2Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'فترة 11 إلى 20'),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: s3Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'فترة 21 إلى 31'),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'سعر الحصة (ج.م)'),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: advanceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'السلف والخصومات (ج.م)'),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Live calculation summary card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('إجمالي الحصص: $totalSess حصة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                              Text('إجمالي الاستحقاق: ${AppFormatters.formatCurrency(totalEarn)}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('صافي المستحق للصرف:', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                              Text(
                                AppFormatters.formatCurrency(netPay),
                                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment Status Switcher
                    Row(
                      children: [
                        Text('حالة الصرف:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: Text('معلق', style: GoogleFonts.cairo()),
                          selected: status == 'معلق',
                          selectedColor: AppTheme.warningOrange.withOpacity(0.2),
                          onSelected: (val) {
                            if (val) setModalState(() => status = 'معلق');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('تم الصرف', style: GoogleFonts.cairo()),
                          selected: status == 'تم الصرف',
                          selectedColor: AppTheme.successGreen.withOpacity(0.2),
                          onSelected: (val) {
                            if (val) setModalState(() => status = 'تم الصرف');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final payroll = PayrollModel(
                          coachId: coach.coachId,
                          coachName: coach.coachName,
                          sessions1To10: s1,
                          sessions11To20: s2,
                          sessions21To31: s3,
                          sessionRate: rate,
                          advancePayments: adv,
                          paymentStatus: status,
                          payoutDate: Timestamp.now(),
                          monthYear: monthYear,
                        );

                        await ref.read(coachesPayrollActionProvider.notifier).savePayroll(payroll);
                        if (mounted) {
                          Navigator.pop(ctx);
                          AppDialogs.showSuccessSnackBar(context, 'تم حفظ مستحقات الكابتن بنجاح');
                          ref.invalidate(monthlyPayrollStreamProvider(monthYear));
                          ref.invalidate(monthlyAccountingProvider(monthYear));
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('حفظ واحتساب الراتب'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthYear = ref.watch(selectedMonthYearProvider);
    final coachesAsync = ref.watch(coachesStreamProvider);
    final payrollAsync = ref.watch(monthlyPayrollStreamProvider(monthYear));

    return Scaffold(
      appBar: AppBar(
        title: const Text('رواتب ومستحقات الكباتن'),
      ),
      body: Column(
        children: [
          // Month banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.primaryBlue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'جدول مسيرات شهر: $monthYear',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    ref.invalidate(monthlyPayrollStreamProvider(monthYear));
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: coachesAsync.when(
              data: (coaches) {
                if (coaches.isEmpty) {
                  return const Center(child: Text('لا يوجد كباتن مسجلين'));
                }

                return payrollAsync.when(
                  data: (payrolls) {
                    final Map<String, PayrollModel> payrollMap = {
                      for (var p in payrolls) p.coachId: p,
                    };

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: coaches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, index) {
                        final coach = coaches[index];
                        final payroll = payrollMap[coach.coachId];
                        final isPaid = payroll?.paymentStatus == 'تم الصرف';

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          coach.coachName,
                                          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                        ),
                                        Text('كود: ${coach.coachId}', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPaid ? AppTheme.successGreen.withOpacity(0.12) : AppTheme.warningOrange.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        payroll?.paymentStatus ?? 'لم يُحسب بعد',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isPaid ? AppTheme.successGreen : AppTheme.warningOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('إجمالي الحصص: ${payroll?.totalSessions ?? 0} حصة', style: GoogleFonts.cairo(fontSize: 13)),
                                    Text('السلف: ${AppFormatters.formatCurrency(payroll?.advancePayments ?? 0.0)}', style: GoogleFonts.cairo(fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'الصافي المستحق:',
                                      style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                    ),
                                    Text(
                                      AppFormatters.formatCurrency(payroll?.netPayable ?? 0.0),
                                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openPayrollEntrySheet(coach, monthYear, payroll),
                                    icon: const Icon(Icons.calculate),
                                    label: Text(payroll != null ? 'تعديل المسير والحصص' : 'تسجيل واحتساب المسير'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('خطأ: $err')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('خطأ: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
