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
  String _searchQuery = '';

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

  void _showEditSubscriptionDialog(SubscriptionModel sub) {
    final allGroups = LocalStore.instance.getGroups();
    GroupModel? selectedGroup;
    try {
      selectedGroup = allGroups.firstWhere((g) => g.groupCode == sub.groupCode);
    } catch (_) {
      selectedGroup = allGroups.isNotEmpty ? allGroups.first : null;
    }

    final reqController = TextEditingController(text: '${sub.amountRequired.toStringAsFixed(0)}');
    final paidController = TextEditingController(text: '${sub.amountPaid.toStringAsFixed(0)}');
    final stampController = TextEditingController(text: '${sub.stampCardFee.toStringAsFixed(0)}');
    final sessionsController = TextEditingController(text: '${sub.sessionsCount}');

    DateTime startDate = sub.startDate.toDate();
    DateTime endDate = sub.endDate.toDate();
    String bookingStatus = sub.bookingStatus;
    String paymentMethod = sub.paymentMethod;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final req = double.tryParse(reqController.text) ?? 0.0;
          final paid = double.tryParse(paidController.text) ?? 0.0;
          final stamp = double.tryParse(stampController.text) ?? 0.0;
          final due = req + stamp;
          final rem = (due - paid) > 0 ? (due - paid) : 0.0;

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue, size: 26),
                const SizedBox(width: 8),
                Text('تعديل بيانات الاشتراك', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Swimmer summary header
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: AppTheme.primaryBlue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${sub.playerName} (كود: ${sub.playerCode})',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 1. Pool Start Date (ميعاد وتاريخ نزول المياه)
                    Text('1. ميعاد وتاريخ نزول المياه (بدء التدريب):', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked;
                            endDate = picked.add(const Duration(days: 30));
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blueGrey.shade300),
                          borderRadius: BorderRadius.circular(10),
                          color: AppTheme.backgroundLight,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: AppTheme.primaryBlue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text('اضغط لتغيير التاريخ', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.primaryBlue)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Group & Schedule Selection (المجموعة والمواعيد)
                    Text('2. المجموعة والمواعيد:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<GroupModel>(
                      value: selectedGroup,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: allGroups.map((g) {
                        return DropdownMenuItem<GroupModel>(
                          value: g,
                          child: Text(
                            '${g.groupCode} | ${g.coachName} (${g.trainingDays.join("، ")} ${g.sessionTime})',
                            style: GoogleFonts.cairo(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedGroup = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // 3. Booking Status (حالة الحجز - عربون صيف vs مؤكد)
                    Text('3. حالة الحجز:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text('حجز بعربون (صيف)', style: GoogleFonts.cairo(fontSize: 11)),
                          selected: bookingStatus == AppConstants.statusDeposit,
                          selectedColor: AppTheme.warningOrange.withOpacity(0.2),
                          onSelected: (_) => setDialogState(() => bookingStatus = AppConstants.statusDeposit),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('اشتراك مؤكد ونزل المياه', style: GoogleFonts.cairo(fontSize: 11)),
                          selected: bookingStatus == AppConstants.statusActive,
                          selectedColor: AppTheme.successGreen.withOpacity(0.2),
                          onSelected: (_) => setDialogState(() => bookingStatus = AppConstants.statusActive),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 4. Financials & Sessions
                    Text('4. المبالغ وعدد الحصص:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: sessionsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'عدد الحصص'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: reqController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'المقرر (ج.م)'),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: paidController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'المدفوع (ج.م)'),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: stampController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'ختم الكارت (ج.م)'),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Balance Display Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: rem > 0 ? AppTheme.warningOrange.withOpacity(0.1) : AppTheme.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('المبلغ المتبقي بعد التعديل:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('${rem.toStringAsFixed(0)} ج.م', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: rem > 0 ? AppTheme.warningOrange : AppTheme.successGreen)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. Payment Method
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                      items: AppConstants.paymentMethods.map((m) {
                        return DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.cairo(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => paymentMethod = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                onPressed: () {
                  final newReq = double.tryParse(reqController.text) ?? sub.amountRequired;
                  final newPaid = double.tryParse(paidController.text) ?? sub.amountPaid;
                  final newStamp = double.tryParse(stampController.text) ?? sub.stampCardFee;
                  final newSessions = int.tryParse(sessionsController.text) ?? sub.sessionsCount;

                  final updated = sub.copyWith(
                    startDate: Timestamp.fromDate(startDate),
                    endDate: Timestamp.fromDate(endDate),
                    groupCode: selectedGroup?.groupCode ?? sub.groupCode,
                    coachName: selectedGroup?.coachName ?? sub.coachName,
                    trainingDays: selectedGroup?.trainingDays ?? sub.trainingDays,
                    sessionTime: selectedGroup?.sessionTime ?? sub.sessionTime,
                    trainingType: selectedGroup?.trainingType ?? sub.trainingType,
                    amountRequired: newReq,
                    amountPaid: newPaid,
                    stampCardFee: newStamp,
                    sessionsCount: newSessions,
                    bookingStatus: bookingStatus,
                    paymentMethod: paymentMethod,
                  );

                  LocalStore.instance.updateSubscription(updated);
                  Navigator.pop(dialogCtx);
                  AppDialogs.showSuccessSnackBar(context, 'تم تعديل بيانات اشتراك (${sub.playerName}) بنجاح!');
                  ref.invalidate(subscriptionsStreamProvider);
                  ref.invalidate(groupsStreamProvider);
                },
                child: const Text('حفظ التعديلات'),
              ),
            ],
          );
        },
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

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDetailsModal(SubscriptionModel sub) {
    final player = LocalStore.instance.getPlayerByCode(sub.playerCode);
    final isPaid = sub.isFullyPaid;
    final isExpired = sub.isExpired;
    final progress = sub.sessionsCount > 0 ? (sub.attendedSessions / sub.sessionsCount).clamp(0.0, 1.0) : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Modal Handle
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.playerName,
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            Text(
                              'كود: ${sub.playerCode} | الفرع: ${sub.branch}',
                              style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? AppTheme.errorRed.withOpacity(0.12)
                              : (isPaid ? AppTheme.successGreen.withOpacity(0.12) : AppTheme.warningOrange.withOpacity(0.12)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isExpired ? 'منتهي الصلاحية' : 'اشتراك ساري نشط',
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
                ),
                const Divider(height: 1),

                // Scrollable Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // 1. بيانات السباح والاتصال
                      _buildSectionCard(
                        title: 'بيانات السباح والتواصل',
                        icon: Icons.person_outline,
                        children: [
                          _buildDetailRow('اسم السباح', sub.playerName, isBold: true),
                          _buildDetailRow('كود السباح', sub.playerCode),
                          _buildDetailRow('الفرع المسجل به', sub.branch),
                          if (player != null && player.guardianPhone.isNotEmpty)
                            _buildDetailRow('هاتف ولي الأمر', player.guardianPhone),
                          if (player != null && player.birthDate != null)
                            _buildDetailRow('تاريخ الميلاد', AppFormatters.formatDate(player.birthDate!.toDate())),
                        ],
                      ),

                      // 2. بيانات التدريب والمجموعة
                      _buildSectionCard(
                        title: 'تفاصيل التدريب والمجموعة',
                        icon: Icons.pool_outlined,
                        children: [
                          _buildDetailRow('المجموعة الأساسية', sub.groupCode, isBold: true, valueColor: AppTheme.primaryBlue),
                          if (sub.secondaryGroupCode != null && sub.secondaryGroupCode!.isNotEmpty)
                            _buildDetailRow('المجموعة المشتركة (المقسمة)', sub.secondaryGroupCode!, valueColor: AppTheme.accentTeal),
                          _buildDetailRow('الكابتن المدرب', sub.coachName),
                          _buildDetailRow('أيام التمرين', sub.trainingDays.join('، ')),
                          _buildDetailRow('توقيت الحصة', sub.sessionTime),
                          _buildDetailRow('مرحلة / نوع التدريب', sub.trainingType),
                          _buildDetailRow('نظام الاشتراك', sub.subscriptionType),
                        ],
                      ),

                      // 3. التواريخ وفترة الصلاحية
                      _buildSectionCard(
                        title: 'فترة الصلاحية والتواريخ',
                        icon: Icons.calendar_month_outlined,
                        children: [
                          _buildDetailRow('تاريخ بداية الاشتراك', AppFormatters.formatDate(sub.startDate.toDate())),
                          _buildDetailRow('تاريخ نهاية الاشتراك', AppFormatters.formatDate(sub.endDate.toDate())),
                          _buildDetailRow(
                            'حالة الصلاحية',
                            isExpired ? 'منتهي (انتهت المدة أو استُهلكت الحصص)' : 'ساري وصالح للحضور',
                            valueColor: isExpired ? AppTheme.errorRed : AppTheme.successGreen,
                            isBold: true,
                          ),
                        ],
                      ),

                      // 4. رصيد الحصص والحضور
                      _buildSectionCard(
                        title: 'رصيد الحصص وسجل الحضور',
                        icon: Icons.checklist_rtl_outlined,
                        children: [
                          _buildDetailRow('إجمالي الحصص المقررة', '${sub.sessionsCount} حصة', isBold: true),
                          _buildDetailRow('الحصص المحضورة', '${sub.attendedSessions} حصة', valueColor: AppTheme.primaryBlue),
                          _buildDetailRow('الحصص المتبقية', '${sub.remainingSessions} حصة', valueColor: sub.remainingSessions > 0 ? AppTheme.successGreen : AppTheme.errorRed, isBold: true),
                          if (sub.excusedSessions > 0)
                            _buildDetailRow('حصص معوضة بعذر طبي', '${sub.excusedSessions} حصة', valueColor: AppTheme.warningOrange),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('نسبة استهلاك الحصص:', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
                              Text('${(progress * 100).toInt()}%', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.blueGrey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isExpired ? AppTheme.errorRed : AppTheme.accentCyan,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 5. البيانات المالية والتحصيل
                      _buildSectionCard(
                        title: 'البيانات المالية والتحصيل',
                        icon: Icons.account_balance_wallet_outlined,
                        children: [
                          _buildDetailRow('سعر الاشتراك المقرر', AppFormatters.formatCurrency(sub.amountRequired)),
                          _buildDetailRow('رسوم ختم الكارت', AppFormatters.formatCurrency(sub.stampCardFee)),
                          const Divider(height: 10),
                          _buildDetailRow('إجمالي المستحق (المقرر + الختم)', AppFormatters.formatCurrency(sub.totalDue), isBold: true),
                          _buildDetailRow('المبلغ المدفوع', AppFormatters.formatCurrency(sub.amountPaid), valueColor: AppTheme.primaryBlue, isBold: true),
                          _buildDetailRow(
                            'المبلغ المتبقي',
                            AppFormatters.formatCurrency(sub.amountRemaining),
                            valueColor: isPaid ? AppTheme.successGreen : AppTheme.errorRed,
                            isBold: true,
                          ),
                          const Divider(height: 10),
                          _buildDetailRow('وسيلة الدفع', sub.paymentMethod),
                          _buildDetailRow('تاريخ السداد', AppFormatters.formatDate(sub.paymentDate.toDate())),
                          _buildDetailRow(
                            'حالة الحساب',
                            isPaid ? 'خالص بالكامل (مسدد)' : 'غير خالص (متبقي مستحقات)',
                            valueColor: isPaid ? AppTheme.successGreen : AppTheme.warningOrange,
                            isBold: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Action Buttons inside Modal
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () async {
                                final phone = player?.guardianPhone ?? '';
                                if (phone.isEmpty) {
                                  AppDialogs.showWarningSnackBar(context, 'رقم ولي الأمر غير مسجل للاعب');
                                  return;
                                }
                                final msg = WhatsAppHelper.buildSubscriptionInvoiceMessage(sub: sub, isRenewal: false);
                                await WhatsAppHelper.openWhatsApp(phone: phone, message: msg);
                              },
                              icon: const Icon(Icons.chat, size: 18),
                              label: Text('إرسال الفاتورة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isPaid) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.warningOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showSettleBalanceDialog(sub);
                                },
                                icon: const Icon(Icons.payment, size: 18),
                                label: Text('سداد المتبقي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.warningOrange,
                                side: const BorderSide(color: AppTheme.warningOrange),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showEditSubscriptionDialog(sub);
                              },
                              icon: const Icon(Icons.edit_note, size: 18),
                              label: Text('تعديل الاشتراك', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => SubscriptionEntryScreen(preSelectedPlayer: player)),
                                );
                              },
                              icon: const Icon(Icons.autorenew, size: 18),
                              label: Text('تجديد الاشتراك', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
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
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث باسم اللاعب أو الكود أو المجموعة...',
                hintStyle: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
            ),
          ),

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
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = filtered.where((s) {
                    final name = s.playerName.toLowerCase();
                    final code = s.playerCode.toLowerCase();
                    final group = s.groupCode.toLowerCase();
                    final coach = s.coachName.toLowerCase();
                    return name.contains(q) || code.contains(q) || group.contains(q) || coach.contains(q);
                  }).toList();
                }

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
                        onTap: () => _showSubscriptionDetailsModal(sub),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Player info (Expanded so it never overflows or clips)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            Text(
                                              sub.playerName,
                                              style: GoogleFonts.cairo(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isExpired ? AppTheme.errorRed : AppTheme.primaryBlue,
                                              ),
                                            ),
                                            if (sub.isDepositOnly)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.warningOrange.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text('عربون صيف', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.warningOrange)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'كود: ${sub.playerCode} | الفرع: ${sub.branch}',
                                          style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Status Badge and Action Buttons
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isExpired
                                              ? AppTheme.errorRed.withOpacity(0.12)
                                              : (isPaid ? AppTheme.successGreen.withOpacity(0.12) : AppTheme.warningOrange.withOpacity(0.12)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isExpired ? 'منتهي (مطلوب تجديد)' : sub.paymentStatus,
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isExpired
                                                ? AppTheme.errorRed
                                                : (isPaid ? AppTheme.successGreen : AppTheme.warningOrange),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 20),
                                            tooltip: 'عرض تفاصيل الاشتراك بالكامل',
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _showSubscriptionDetailsModal(sub),
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                                            tooltip: 'إرسال الفاتورة عبر واتساب',
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.all(4),
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
                                            const SizedBox(width: 6),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
                                              tooltip: 'حذف الاشتراك (للمالك فقط)',
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _confirmDeleteSubscription(sub),
                                            ),
                                          ],
                                        ],
                                      ),
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
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primaryBlue,
                                        side: const BorderSide(color: AppTheme.primaryBlue),
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                      ),
                                      onPressed: () => _showSubscriptionDetailsModal(sub),
                                      icon: const Icon(Icons.visibility_outlined, size: 14),
                                      label: Text('التفاصيل', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 4),

                                  // Edit Button
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.warningOrange,
                                        side: const BorderSide(color: AppTheme.warningOrange),
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                      ),
                                      onPressed: () => _showEditSubscriptionDialog(sub),
                                      icon: const Icon(Icons.edit_note, size: 15),
                                      label: Text('تعديل', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (!sub.isFullyPaid) ...[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.warningOrange,
                                          side: const BorderSide(color: AppTheme.warningOrange),
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                        ),
                                        onPressed: () => _showSettleBalanceDialog(sub),
                                        icon: const Icon(Icons.payment, size: 14),
                                        label: Text('سداد', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],

                                  // Transfer Group Button
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.accentTeal,
                                        side: const BorderSide(color: AppTheme.accentTeal),
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                      ),
                                      onPressed: () => _showTransferGroupDialog(sub),
                                      icon: const Icon(Icons.swap_horiz, size: 14),
                                      label: Text('نقل', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 4),

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
                                      icon: const Icon(Icons.autorenew, size: 14),
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
