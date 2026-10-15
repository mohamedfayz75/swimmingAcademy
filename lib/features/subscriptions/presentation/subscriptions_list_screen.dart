import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/local_store.dart';
import '../../groups/models/group_model.dart';
import '../../groups/providers/group_provider.dart';
import '../../players/models/player_model.dart';
import '../models/subscription_model.dart';
import '../providers/subscription_provider.dart';
import 'subscription_entry_screen.dart';

class SubscriptionsListScreen extends ConsumerStatefulWidget {
  const SubscriptionsListScreen({super.key});

  @override
  ConsumerState<SubscriptionsListScreen> createState() => _SubscriptionsListScreenState();
}

class _SubscriptionsListScreenState extends ConsumerState<SubscriptionsListScreen> {
  String? _filter; // null = all, 'paid', 'remaining', 'deposit'

  void _showTransferGroupDialog(SubscriptionModel sub) {
    final allGroups = LocalStore.instance.getGroups();
    final targetGroups = allGroups.where((g) => g.groupCode != sub.groupCode).toList();
    GroupModel? selectedTargetGroup = targetGroups.isNotEmpty ? targetGroups.first : null;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.swap_horiz, color: AppTheme.warningOrange),
              const SizedBox(width: 8),
              Text('نقل السباح لمجموعة أخرى', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('السباح: ${sub.playerName} (${sub.playerCode})', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('المجموعة الحالية: ${sub.groupCode} - ${sub.coachName}', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
                      Text('المواعيد الحالية: ${sub.trainingDays.join("، ")} (${sub.sessionTime})', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('اختر المجموعة البديلة المراد النقل إليها:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                if (targetGroups.isEmpty)
                  Text('لا توجد مجموعات أخرى متاحة حالياً', style: GoogleFonts.cairo(color: AppTheme.errorRed))
                else
                  DropdownButtonFormField<GroupModel>(
                    value: selectedTargetGroup,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'المجموعة البديلة *'),
                    items: targetGroups.map((g) {
                      final seatsText = g.availableSeats > 0 ? 'متاح ${g.availableSeats} مقاعد' : 'مكتملة';
                      return DropdownMenuItem<GroupModel>(
                        value: g,
                        child: Text(
                          '${g.groupCode} - ${g.coachName} (${g.trainingDays.join("، ")} ${g.sessionTime}) [$seatsText]',
                          style: GoogleFonts.cairo(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedTargetGroup = val);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningOrange),
              onPressed: selectedTargetGroup == null
                  ? null
                  : () {
                      final ok = LocalStore.instance.transferPlayerToGroup(
                        subscriptionId: sub.id,
                        newGroupCode: selectedTargetGroup!.groupCode,
                      );
                      if (ok) {
                        Navigator.pop(dialogCtx);
                        AppDialogs.showSuccessSnackBar(
                          context,
                          'تم نقل السباح (${sub.playerName}) إلى مجموعة (${selectedTargetGroup!.groupCode} - ${selectedTargetGroup!.coachName}) بنجاح!',
                        );
                        ref.invalidate(subscriptionsStreamProvider);
                        ref.invalidate(groupsStreamProvider);
                      }
                    },
              child: const Text('تأكيد النقل'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettleBalanceDialog(SubscriptionModel sub) {
    final amountController = TextEditingController(text: '${sub.amountRemaining}');
    String method = AppConstants.paymentCash;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تحصيل المبلغ المتبقي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('السباح: ${sub.playerName}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            Text('المتبقي حالياً: ${AppFormatters.formatCurrency(sub.amountRemaining)}', style: GoogleFonts.cairo(color: AppTheme.errorRed)),
            const SizedBox(height: 14),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ المدفوع الآن (ج.م)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: method,
              decoration: const InputDecoration(labelText: 'طريقة الدفع'),
              items: AppConstants.paymentMethods.map((m) {
                return DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.cairo(fontSize: 13)));
              }).toList(),
              onChanged: (val) {
                if (val != null) method = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final paid = double.tryParse(amountController.text) ?? 0.0;
              LocalStore.instance.confirmDepositSubscription(
                subscriptionId: sub.id,
                additionalAmountPaid: paid,
                paymentMethod: method,
              );
              Navigator.pop(ctx);
              AppDialogs.showSuccessSnackBar(context, 'تم تحصيل المبلغ وتحديث الاشتراك بنجاح!');
            },
            child: const Text('تأكيد التحصيل'),
          ),
        ],
      ),
    );
  }

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
          // Filter Chips Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('الكل', style: GoogleFonts.cairo(fontSize: 12)),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('خالص بالكامل', style: GoogleFonts.cairo(fontSize: 12)),
                    selected: _filter == 'paid',
                    selectedColor: AppTheme.successGreen.withOpacity(0.2),
                    onSelected: (_) => setState(() => _filter = 'paid'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('متبقي عليه', style: GoogleFonts.cairo(fontSize: 12)),
                    selected: _filter == 'remaining',
                    selectedColor: AppTheme.warningOrange.withOpacity(0.2),
                    onSelected: (_) => setState(() => _filter = 'remaining'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('حجوزات العربون (صيف)', style: GoogleFonts.cairo(fontSize: 12)),
                    selected: _filter == 'deposit',
                    selectedColor: AppTheme.accentCyan.withOpacity(0.2),
                    onSelected: (_) => setState(() => _filter = 'deposit'),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: subscriptionsAsync.when(
              data: (subs) {
                var filtered = subs;
                if (_filter == 'paid') {
                  filtered = filtered.where((s) => s.isFullyPaid && !s.isDepositOnly).toList();
                } else if (_filter == 'remaining') {
                  filtered = filtered.where((s) => !s.isFullyPaid).toList();
                } else if (_filter == 'deposit') {
                  filtered = filtered.where((s) => s.isDepositOnly).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text('لا توجد اشتراكات مطابقة للبحث', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
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
                    final isExpired = sub.isExpired;
                    final isPaid = sub.isFullyPaid;
                    final progress = sub.sessionsCount > 0
                        ? (sub.attendedSessions / sub.sessionsCount).clamp(0.0, 1.0)
                        : 0.0;

                    return Card(
                      // Red highlight border and tint if expired by date or sessions!
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isExpired
                              ? AppTheme.errorRed
                              : (isPaid ? Colors.transparent : AppTheme.warningOrange.withOpacity(0.6)),
                          width: isExpired ? 2 : 1,
                        ),
                      ),
                      color: isExpired ? AppTheme.errorRed.withOpacity(0.04) : Colors.white,
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
                                    Row(
                                      children: [
                                        Text(
                                          sub.playerName,
                                          style: GoogleFonts.cairo(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isExpired ? AppTheme.errorRed : AppTheme.primaryBlue,
                                          ),
                                        ),
                                        if (sub.isDepositOnly) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.warningOrange.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text('عربون صيف', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.warningOrange)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      'كود: ${sub.playerCode} | الفرع: ${sub.branch}',
                                      style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isExpired
                                        ? AppTheme.errorRed.withOpacity(0.12)
                                        : (isPaid ? AppTheme.successGreen.withOpacity(0.12) : AppTheme.warningOrange.withOpacity(0.12)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isExpired ? 'منتهي (مطلوب تجديد)' : sub.paymentStatus,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isExpired
                                          ? AppTheme.errorRed
                                          : (isPaid ? AppTheme.successGreen : AppTheme.warningOrange),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 18),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('المجموعة: ${sub.groupCode} (${sub.coachName})', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text('وسيلة الدفع: ${sub.paymentMethod}', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.primaryLight, fontWeight: FontWeight.bold)),
                              ],
                            ),

                            const SizedBox(height: 6),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('المقرر + الختم: ${AppFormatters.formatCurrency(sub.totalDue)}', style: GoogleFonts.cairo(fontSize: 12)),
                                Text('المدفوع: ${AppFormatters.formatCurrency(sub.amountPaid)}', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
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

                            const SizedBox(height: 10),

                            // Progress Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'حضور الحصص: ${sub.attendedSessions} من ${sub.sessionsCount} حصة (المتبقي: ${sub.remainingSessions})',
                                  style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: Colors.blueGrey.shade100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isExpired ? AppTheme.errorRed : AppTheme.accentCyan,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Action buttons
                            Row(
                              children: [
                                if (!sub.isFullyPaid)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.warningOrange,
                                        side: const BorderSide(color: AppTheme.warningOrange),
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                      ),
                                      onPressed: () => _showSettleBalanceDialog(sub),
                                      icon: const Icon(Icons.payment, size: 15),
                                      label: Text('سداد', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                if (!sub.isFullyPaid) const SizedBox(width: 6),

                                // Transfer Group Button
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.accentTeal,
                                      side: const BorderSide(color: AppTheme.accentTeal),
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                    ),
                                    onPressed: () => _showTransferGroupDialog(sub),
                                    icon: const Icon(Icons.swap_horiz, size: 15),
                                    label: Text('نقل مجموعة', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Quick Renewal Button
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isExpired ? AppTheme.primaryBlue : AppTheme.accentTeal,
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                    ),
                                    onPressed: () {
                                      final player = LocalStore.instance.getPlayerByCode(sub.playerCode);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SubscriptionEntryScreen(preSelectedPlayer: player),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.autorenew, size: 15),
                                    label: Text('تجديد', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
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
