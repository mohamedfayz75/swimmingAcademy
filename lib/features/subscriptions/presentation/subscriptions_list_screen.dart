import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../data/local/local_store.dart';
import '../../groups/models/group_model.dart';
import '../../groups/providers/group_provider.dart';
import '../../players/models/player_model.dart';
import '../../../core/rbac/app_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/subscription_model.dart';
import '../providers/subscription_provider.dart';
import 'subscription_entry_screen.dart';

class SubscriptionsListScreen extends ConsumerStatefulWidget {
  const SubscriptionsListScreen({super.key});

  @override
  ConsumerState<SubscriptionsListScreen> createState() => _SubscriptionsListScreenState();
}

class _SubscriptionsListScreenState extends ConsumerState<SubscriptionsListScreen> {
  String _filter = 'active'; // 'active', 'all', 'paid', 'remaining', 'expired', 'deposit'

  void _confirmDeleteSubscription(SubscriptionModel sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
            const SizedBox(width: 8),
            Text('تأكيد حذف الاشتراك', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف اشتراك السباح «${sub.playerName}» (كود: ${sub.playerCode}) في مجموعة «${sub.groupCode}» نهائياً؟\nسيتم استرجاع مقعد المجموعة تلقائياً.',
          style: GoogleFonts.cairo(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              LocalStore.instance.deleteSubscription(sub.id);
              Navigator.pop(ctx);
              AppDialogs.showSuccessSnackBar(context, 'تم حذف اشتراك السباح ${sub.playerName} بنجاح');
            },
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }

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

  void _showSubscriptionDetailsSheet(SubscriptionModel sub) {
    final player = LocalStore.instance.getPlayerByCode(sub.playerCode);
    final phone = player?.guardianPhone ?? '';
    final isExpired = sub.isExpired;
    final isPaid = sub.isFullyPaid;
    final progress = sub.sessionsCount > 0
        ? (sub.attendedSessions / sub.sessionsCount).clamp(0.0, 1.0)
        : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.badge, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تفاصيل الاشتراك الكاملة',
                                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                              ),
                              Text('كود العضوية: ${sub.playerCode}', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // 1. Swimmer & Branch Info
                  _buildSectionHeader(Icons.person, 'بيانات السباح والفرع'),
                  _buildInfoRow('اسم السباح:', sub.playerName, isBold: true),
                  _buildInfoRow('رقم ولي الأمر:', phone.isNotEmpty ? phone : 'غير مسجل'),
                  _buildInfoRow('الفرع:', sub.branch.isNotEmpty ? sub.branch : 'فرع المشاة'),

                  const SizedBox(height: 14),

                  // 2. Training & Group Details
                  _buildSectionHeader(Icons.pool, 'تفاصيل التدريب والمجموعة'),
                  _buildInfoRow('كود المجموعة:', sub.groupCode),
                  _buildInfoRow('الكابتن المدرب:', 'كابتن ${sub.coachName}'),
                  _buildInfoRow('أيام التدريب:', sub.trainingDays.isNotEmpty ? sub.trainingDays.join('، ') : 'حسب الجدول'),
                  _buildInfoRow('توقيت الحصة:', sub.sessionTime.isNotEmpty ? sub.sessionTime : 'حسب الجدول'),
                  _buildInfoRow('نوع التدريب:', sub.subscriptionType),

                  const SizedBox(height: 14),

                  // 3. Validity & Dates
                  _buildSectionHeader(Icons.date_range, 'فترة الصلاحية والتواريخ'),
                  _buildInfoRow('تاريخ البداية (نزول المياة):', AppFormatters.formatTimestamp(sub.startDate)),
                  _buildInfoRow('تاريخ الانتهاء:', AppFormatters.formatTimestamp(sub.endDate)),
                  _buildInfoRow(
                    'حالة الاشتراك:',
                    isExpired ? 'منتهي الصلاحية' : (sub.isDepositOnly ? 'حجز عربون' : 'ساري ونشط'),
                    valueColor: isExpired ? AppTheme.errorRed : AppTheme.successGreen,
                    isBold: true,
                  ),

                  const SizedBox(height: 14),

                  // 4. Session Balance & Progress
                  _buildSectionHeader(Icons.fact_check, 'رصيد الحصص والمتابعة'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricTile('المقررة', '${sub.sessionsCount}', AppTheme.primaryBlue),
                      _buildMetricTile('المحضورة', '${sub.attendedSessions}', AppTheme.accentTeal),
                      _buildMetricTile('المتبقية', '${sub.remainingSessions}', isExpired ? AppTheme.errorRed : AppTheme.successGreen),
                      _buildMetricTile('التعويض الطبي', '${sub.medicalSessionsCompensated}', AppTheme.warningOrange),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(isExpired ? AppTheme.errorRed : AppTheme.accentCyan),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${(progress * 100).toInt()}% منجز', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 14),

                  // 5. Complete Financial Breakdown
                  _buildSectionHeader(Icons.account_balance_wallet, 'التفاصيل المالية الكاملة'),
                  _buildInfoRow('قيمة التدريب المقررة:', AppFormatters.formatCurrency(sub.amountRequired)),
                  if (sub.stampCardFee > 0)
                    _buildInfoRow('رسم ختم الكارت والاستمارة:', AppFormatters.formatCurrency(sub.stampCardFee)),
                  _buildInfoRow('إجمالي المبلغ المستحق:', AppFormatters.formatCurrency(sub.totalDue), isBold: true),
                  _buildInfoRow('المبلغ المسدد:', AppFormatters.formatCurrency(sub.amountPaid), isBold: true, valueColor: AppTheme.successGreen),
                  _buildInfoRow(
                    'المبلغ المتبقي:',
                    AppFormatters.formatCurrency(sub.amountRemaining),
                    isBold: true,
                    valueColor: isPaid ? AppTheme.successGreen : AppTheme.errorRed,
                  ),
                  _buildInfoRow('طريقة الدفع:', sub.paymentMethod),
                  _buildInfoRow('تاريخ السداد / القيد:', AppFormatters.formatTimestamp(sub.createdAt)),

                  const SizedBox(height: 20),

                  // 6. Direct Action Buttons
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      if (phone.isEmpty) {
                        AppDialogs.showWarningSnackBar(context, 'رقم هاتف ولي الأمر غير مسجل');
                        return;
                      }
                      final msg = WhatsAppHelper.buildSubscriptionInvoiceMessage(sub: sub, isRenewal: false);
                      await WhatsAppHelper.openWhatsApp(phone: phone, message: msg);
                    },
                    icon: const Icon(Icons.chat, color: Colors.white),
                    label: Text('إرسال الفاتورة عبر واتساب', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      if (!sub.isFullyPaid) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.warningOrange,
                              side: const BorderSide(color: AppTheme.warningOrange),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              _showSettleBalanceDialog(sub);
                            },
                            icon: const Icon(Icons.payment, size: 16),
                            label: Text('سداد المتبقي', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentTeal,
                            side: const BorderSide(color: AppTheme.accentTeal),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            _showTransferGroupDialog(sub);
                          },
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: Text('نقل مجموعة', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isExpired ? AppTheme.primaryBlue : AppTheme.accentTeal,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubscriptionEntryScreen(preSelectedPlayer: player),
                              ),
                            );
                          },
                          icon: const Icon(Icons.autorenew, size: 16),
                          label: Text('تجديد الاشتراك', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBlue),
          const SizedBox(width: 6),
          Text(title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: GoogleFonts.cairo(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(subscriptionsStreamProvider);
    final isOwner = ref.watch(currentUserProvider).value?.role.isOwner ?? false;

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
                    label: Text('النشطة حالياً (لها حصص)', style: GoogleFonts.cairo(fontSize: 12)),
                    selected: _filter == 'active',
                    selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                    onSelected: (_) => setState(() => _filter = 'active'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('الكل', style: GoogleFonts.cairo(fontSize: 12)),
                    selected: _filter == 'all',
                    onSelected: (_) => setState(() => _filter = 'all'),
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
                    label: Text('منتهي / سابق', style: GoogleFonts.cairo(fontSize: 12)),
                    selected: _filter == 'expired',
                    selectedColor: AppTheme.errorRed.withOpacity(0.2),
                    onSelected: (_) => setState(() => _filter = 'expired'),
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
                if (_filter == 'active') {
                  filtered = filtered.where((s) => !s.isExpired).toList();
                } else if (_filter == 'paid') {
                  filtered = filtered.where((s) => s.isFullyPaid && !s.isDepositOnly).toList();
                } else if (_filter == 'remaining') {
                  filtered = filtered.where((s) => !s.isFullyPaid).toList();
                } else if (_filter == 'expired') {
                  filtered = filtered.where((s) => s.isExpired).toList();
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showSubscriptionDetailsSheet(sub),
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

                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
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
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 20),
                                        tooltip: 'عرض تفاصيل الاشتراك الكاملة',
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showSubscriptionDetailsSheet(sub),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                                        tooltip: 'إرسال الفاتورة عبر واتساب',
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () async {
                                        final player = LocalStore.instance.getPlayerByCode(sub.playerCode);
                                        final phone = player?.guardianPhone ?? '';
                                        if (phone.isEmpty) {
                                          AppDialogs.showWarningSnackBar(
                                            context,
                                            'رقم ولي الأمر غير مسجل للاعب (${sub.playerName})',
                                          );
                                          return;
                                        }
                                        final msg = WhatsAppHelper.buildSubscriptionInvoiceMessage(
                                          sub: sub,
                                          isRenewal: false,
                                        );
                                        final ok = await WhatsAppHelper.openWhatsApp(
                                          phone: phone,
                                          message: msg,
                                        );
                                        if (!ok && context.mounted) {
                                          AppDialogs.showWarningSnackBar(
                                            context,
                                            'تعذر فتح الواتساب. تأكد من تثبيت التطبيق وصحة الرقم ($phone)',
                                          );
                                        }
                                      },
                                    ),
                                    if (isOwner) ...[
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
                                        tooltip: 'حذف الاشتراك (للمالك فقط)',
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _confirmDeleteSubscription(sub),
                                      ),
                                    ],
                                  ],
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
