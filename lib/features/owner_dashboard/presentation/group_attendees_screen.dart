import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../groups/models/group_model.dart';
import '../../groups/providers/group_provider.dart';
import '../../subscriptions/models/subscription_model.dart';
import '../../subscriptions/providers/subscription_provider.dart';

class GroupAttendeesScreen extends ConsumerWidget {
  const GroupAttendeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsStreamProvider);
    final selectedGroupCode = ref.watch(selectedGroupCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('كشف نزول المجموعة وقوائم اللاعبين'),
      ),
      body: Column(
        children: [
          // Group Selection Dropdown
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) return const Text('لا توجد مجموعات');
                final currentCode = selectedGroupCode ?? groups.first.groupCode;

                return DropdownButtonFormField<String>(
                  value: currentCode,
                  decoration: const InputDecoration(
                    labelText: 'اختر كود المجموعة لتصفية القائمة',
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

                    return Column(
                      children: [
                        // Group Meta Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          color: AppTheme.primaryBlue.withOpacity(0.04),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'المدرب المسؤول: ${activeGroup.coachName}',
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue),
                                  ),
                                  Text(
                                    'المواعيد: ${activeGroup.trainingDays.join('، ')} (${activeGroup.sessionTime})',
                                    style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                              Chip(
                                label: Text(
                                  'المسجلين: ${activeGroup.currentRegistered} / ${activeGroup.maxCapacity}',
                                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                backgroundColor: AppTheme.primaryBlue,
                              ),
                            ],
                          ),
                        ),

                        // Subscribed players list
                        Expanded(
                          child: subscriptionsAsync.when(
                            data: (subs) {
                              if (subs.isEmpty) {
                                return Center(
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
                                );
                              }

                              return ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: subs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final sub = subs[index];
                                  final isPaid = sub.isFullyPaid;

                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryBlue,
                                        child: Text(
                                          '${index + 1}',
                                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      title: Text(
                                        sub.playerName,
                                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      subtitle: Text(
                                        'كود: ${sub.playerCode} | الحضور: ${sub.attendedSessions}/${sub.sessionsCount} حصة',
                                        style: GoogleFonts.cairo(fontSize: 13),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isPaid ? AppTheme.successGreen.withOpacity(0.12) : AppTheme.errorRed.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              sub.paymentStatus,
                                              style: GoogleFonts.cairo(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isPaid ? AppTheme.successGreen : AppTheme.errorRed,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            AppFormatters.formatCurrency(sub.amountPaid),
                                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, _) => Center(child: Text('خطأ في تحميل المشتركين: $err')),
                          ),
                        ),
                      ],
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
