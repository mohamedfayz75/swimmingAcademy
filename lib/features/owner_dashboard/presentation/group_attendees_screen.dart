import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/local_store.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../groups/providers/group_provider.dart';
import '../../subscriptions/models/subscription_model.dart';
import '../../subscriptions/providers/subscription_provider.dart';

class GroupAttendeesScreen extends ConsumerStatefulWidget {
  const GroupAttendeesScreen({super.key});

  @override
  ConsumerState<GroupAttendeesScreen> createState() => _GroupAttendeesScreenState();
}

class _GroupAttendeesScreenState extends ConsumerState<GroupAttendeesScreen> {
  bool _isProcessing = false;

  Future<void> _checkInPlayer(SubscriptionModel sub, String staffName) async {
    setState(() => _isProcessing = true);
    try {
      final notifier = ref.read(attendanceScanProvider.notifier);
      final result = await notifier.recordAttendance(
        playerCode: sub.playerCode,
        recordedByStaffUid: staffName,
      );

      await LocalStore.instance.saveAllExplicitly();

      if (mounted) {
        if (result.success) {
          AppDialogs.showSuccessSnackBar(
            context,
            '🏊 تم تسجيل تمام ونزول السباح ${sub.playerName} (حصة ${result.currentSession} من ${result.totalSessions})',
          );
        } else {
          AppDialogs.showErrorSnackBar(context, result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorSnackBar(context, 'حدث خطأ أثناء تسجيل الحضور: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _checkInAllEligible(List<SubscriptionModel> eligibleSubs, String staffName) async {
    if (eligibleSubs.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.pool, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text('تأكيد تمام ونزول المجموعة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هل تريد تسجيل تمام ونزول جميع السباحين المتبقين (${eligibleSubs.length} سباح) إلى المسبح الآن دفعة واحدة؟',
          style: GoogleFonts.cairo(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('تأكيد تمام الكل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    int successCount = 0;
    try {
      final notifier = ref.read(attendanceScanProvider.notifier);
      for (final sub in eligibleSubs) {
        final res = await notifier.recordAttendance(
          playerCode: sub.playerCode,
          recordedByStaffUid: staffName,
        );
        if (res.success) successCount++;
      }
      await LocalStore.instance.saveAllExplicitly();

      if (mounted) {
        AppDialogs.showSuccessSnackBar(
          context,
          '🎉 تم بنجاح تسجيل تمام ونزول $successCount سباح إلى المسبح!',
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorSnackBar(context, 'حدث خطأ: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsStreamProvider);
    final selectedGroupCode = ref.watch(selectedGroupCodeProvider);
    final todayAttendanceAsync = ref.watch(todayAttendanceStreamProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final staffName = currentUser?.displayName ?? (currentUser?.role.isOwner == true ? 'المالك' : 'موظف الاستقبال');

    return Scaffold(
      appBar: AppBar(
        title: const Text('كشف نزول المجموعة والتمام للمسبح'),
      ),
      body: Column(
        children: [
          // Group Selection Dropdown
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return Center(
                    child: Text('لا توجد مجموعات مسجلة', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
                  );
                }
                final currentCode = selectedGroupCode ?? groups.first.groupCode;

                return DropdownButtonFormField<String>(
                  value: currentCode,
                  decoration: const InputDecoration(
                    labelText: 'اختر كود المجموعة للتمام ونزول المسبح',
                    prefixIcon: Icon(Icons.group, color: AppTheme.primaryBlue),
                  ),
                  items: groups.map((g) {
                    return DropdownMenuItem(
                      value: g.groupCode,
                      child: Text(
                        '${g.groupCode} - ${g.coachName} (${g.trainingType})',
                        style: GoogleFonts.cairo(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    ref.read(selectedGroupCodeProvider.notifier).state = val;
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('خطأ في تحميل المجموعات'),
            ),
          ),

          const Divider(height: 1),

          // Subscribed Players for the selected group
          Expanded(
            child: groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) return const SizedBox.shrink();
                final currentCode = selectedGroupCode ?? groups.first.groupCode;
                final activeGroup = groups.firstWhere(
                  (g) => g.groupCode == currentCode,
                  orElse: () => groups.first,
                );

                return Consumer(
                  builder: (ctx, innerRef, _) {
                    final subscriptionsAsync = innerRef.watch(groupSubscriptionsStreamProvider(currentCode));

                    return subscriptionsAsync.when(
                      data: (subs) {
                        // Calculate today attendance for this group
                        final now = DateTime.now();
                        final todayStart = DateTime(now.year, now.month, now.day);
                        final todayAttendance = todayAttendanceAsync.value ?? [];

                        final attendedPlayerCodes = todayAttendance
                            .where((a) => a.timestamp.toDate().isAfter(todayStart))
                            .map((a) => a.playerCode.trim().toUpperCase())
                            .toSet();

                        final checkedInCount = subs
                            .where((s) => attendedPlayerCodes.contains(s.playerCode.trim().toUpperCase()))
                            .length;

                        final eligibleSubs = subs
                            .where((s) =>
                                !attendedPlayerCodes.contains(s.playerCode.trim().toUpperCase()) &&
                                !s.isExpired &&
                                s.attendedSessions < s.sessionsCount)
                            .toList();

                        return Column(
                          children: [
                            // Group Meta Banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              color: AppTheme.primaryBlue.withOpacity(0.06),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'الكابتن: ${activeGroup.coachName}',
                                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue),
                                          ),
                                          Text(
                                            'المواعيد: ${activeGroup.trainingDays.join('، ')} (${activeGroup.sessionTime})',
                                            style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                      Chip(
                                        label: Text(
                                          'المقيدين: ${subs.length} / ${activeGroup.maxCapacity}',
                                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        backgroundColor: AppTheme.primaryBlue,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Quick Attendance Stats and Batch Button
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '✔️ تم التمام اليوم: $checkedInCount',
                                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.warningOrange.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '⏳ متبقي: ${subs.length - checkedInCount}',
                                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.warningOrange),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (eligibleSubs.isNotEmpty)
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryBlue,
                                            foregroundColor: Colors.white,
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          icon: const Icon(Icons.done_all, size: 16),
                                          label: Text('تمام الكل 🏊', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                                          onPressed: _isProcessing ? null : () => _checkInAllEligible(eligibleSubs, staffName),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Subscribed players list
                            Expanded(
                              child: subs.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.person_off_outlined, size: 48, color: AppTheme.textMuted),
                                          const SizedBox(height: 12),
                                          Text(
                                            'لا يوجد لاعبين مقيدين في هذه المجموعة حتى الآن',
                                            style: GoogleFonts.cairo(color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: subs.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final sub = subs[index];
                                        final hasAttendedToday = attendedPlayerCodes.contains(sub.playerCode.trim().toUpperCase());
                                        final isExpired = sub.isExpired || sub.attendedSessions >= sub.sessionsCount;
                                        final isPaid = sub.isFullyPaid;

                                        return Card(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(
                                              color: hasAttendedToday
                                                  ? AppTheme.successGreen.withOpacity(0.5)
                                                  : (isExpired ? AppTheme.errorRed.withOpacity(0.4) : Colors.transparent),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Header row: Player name, code, payment badge
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 18,
                                                      backgroundColor: hasAttendedToday ? AppTheme.successGreen : AppTheme.primaryBlue,
                                                      child: Text(
                                                        '${index + 1}',
                                                        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            sub.playerName,
                                                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                                                          ),
                                                          Text(
                                                            'كود: ${sub.playerCode} | الحضور الإجمالي: ${sub.attendedSessions}/${sub.sessionsCount} حصة',
                                                            style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: isPaid ? AppTheme.successGreen.withOpacity(0.12) : AppTheme.warningOrange.withOpacity(0.12),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        sub.paymentStatus,
                                                        style: GoogleFonts.cairo(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: isPaid ? AppTheme.successGreen : AppTheme.warningOrange,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const Divider(height: 16),

                                                // Roll Call & Swimming Action Row
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    if (hasAttendedToday) ...[
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.successGreen.withOpacity(0.15),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 18),
                                                            const SizedBox(width: 6),
                                                            Text(
                                                              'تم التمام ونزول المسبح اليوم ✔️',
                                                              style: GoogleFonts.cairo(
                                                                color: AppTheme.successGreen,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ] else if (isExpired) ...[
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.errorRed.withOpacity(0.12),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.warning, color: AppTheme.errorRed, size: 18),
                                                            const SizedBox(width: 6),
                                                            Text(
                                                              'انتهت الحصص (مطلوب تجديد اشتراك)',
                                                              style: GoogleFonts.cairo(
                                                                color: AppTheme.errorRed,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ] else ...[
                                                      Text(
                                                        'متبقي ${sub.remainingSessions} حصص',
                                                        style: GoogleFonts.cairo(
                                                          color: AppTheme.accentCyan,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      ElevatedButton.icon(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: AppTheme.primaryBlue,
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                        icon: const Icon(Icons.pool, size: 16),
                                                        label: Text(
                                                          'تسجيل تمام ونزول المسبح',
                                                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                                                        ),
                                                        onPressed: _isProcessing ? null : () => _checkInPlayer(sub, staffName),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('خطأ في تحميل المشتركين: $err')),
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
