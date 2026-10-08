import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../models/subscription_model.dart';
import '../providers/subscription_provider.dart';
import 'subscription_entry_screen.dart';

class SubscriptionsListScreen extends ConsumerStatefulWidget {
  const SubscriptionsListScreen({super.key});

  @override
  ConsumerState<SubscriptionsListScreen> createState() => _SubscriptionsListScreenState();
}

class _SubscriptionsListScreenState extends ConsumerState<SubscriptionsListScreen> {
  String? _paymentStatusFilter; // null = all, 'مدفوع بالكامل', 'متبقي'

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(subscriptionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الاشتراكات والتحصيل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            tooltip: 'تسجيل اشتراك جديد',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionEntryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text('تصفية السداد:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: Text('الكل', style: GoogleFonts.cairo(fontSize: 12)),
                  selected: _paymentStatusFilter == null,
                  onSelected: (_) => setState(() => _paymentStatusFilter = null),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('مدفوع بالكامل', style: GoogleFonts.cairo(fontSize: 12)),
                  selected: _paymentStatusFilter == 'مدفوع بالكامل',
                  selectedColor: AppTheme.successGreen.withOpacity(0.2),
                  onSelected: (_) => setState(() => _paymentStatusFilter = 'مدفوع بالكامل'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('متبقي', style: GoogleFonts.cairo(fontSize: 12)),
                  selected: _paymentStatusFilter == 'متبقي',
                  selectedColor: AppTheme.warningOrange.withOpacity(0.2),
                  onSelected: (_) => setState(() => _paymentStatusFilter = 'متبقي'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: subscriptionsAsync.when(
              data: (subs) {
                var filtered = subs;
                if (_paymentStatusFilter != null) {
                  filtered = filtered.where((s) => s.paymentStatus == _paymentStatusFilter).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_outlined, size: 64, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text('لا توجد اشتراكات مسجلة وفق التصفية الحالية', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) {
                    final sub = filtered[index];
                    final isPaid = sub.isFullyPaid;
                    final progress = sub.sessionsCount > 0 ? (sub.attendedSessions / sub.sessionsCount).clamp(0.0, 1.0) : 0.0;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sub.playerName,
                                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                    ),
                                    Text(
                                      'كود اللاعب: ${sub.playerCode} | المجموعة: ${sub.groupCode}',
                                      style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPaid ? AppTheme.successGreen.withOpacity(0.12) : AppTheme.errorRed.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    sub.paymentStatus,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isPaid ? AppTheme.successGreen : AppTheme.errorRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('المدرب: ${sub.coachName}', style: GoogleFonts.cairo(fontSize: 13)),
                                Text('الموعد: ${sub.sessionTime}', style: GoogleFonts.cairo(fontSize: 13)),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('المقرر: ${AppFormatters.formatCurrency(sub.amountRequired)}', style: GoogleFonts.cairo(fontSize: 13)),
                                Text('المدفوع: ${AppFormatters.formatCurrency(sub.amountPaid)}', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text(
                                  'المتبقي: ${AppFormatters.formatCurrency(sub.amountRemaining)}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isPaid ? AppTheme.successGreen : AppTheme.errorRed,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Sessions Progress
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'حضور الحصص: ${sub.attendedSessions} من ${sub.sessionsCount} حصة',
                                  style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: Colors.blueGrey.shade100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isPaid ? AppTheme.accentCyan : AppTheme.warningOrange,
                                ),
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
            ),
          ),
        ],
      ),
    );
  }
}
