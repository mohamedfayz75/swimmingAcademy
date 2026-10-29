import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../data/local/local_store.dart';
import '../../coaches_payroll/providers/coaches_payroll_provider.dart';
import '../../subscriptions/models/subscription_model.dart';
import '../../subscriptions/presentation/subscription_entry_screen.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../models/group_model.dart';
import '../providers/group_provider.dart';

class GroupsManagementScreen extends ConsumerStatefulWidget {
  const GroupsManagementScreen({super.key});

  @override
  ConsumerState<GroupsManagementScreen> createState() => _GroupsManagementScreenState();
}

class _GroupsManagementScreenState extends ConsumerState<GroupsManagementScreen> {
  Future<bool> _checkCoachScheduleConflict({
    required BuildContext context,
    required String? coachId,
    required String? coachName,
    required String sessionTime,
    required List<String> trainingDays,
    String? currentGroupCode,
  }) async {
    if (coachId == null) return true;

    final allGroups = LocalStore.instance.getGroups();
    final normalizedTime = sessionTime.trim().toLowerCase().replaceAll(' ', '');

    GroupModel? conflict;
    for (final g in allGroups) {
      if (currentGroupCode != null && g.groupCode == currentGroupCode) continue;
      if (g.coachId == coachId) {
        final gTime = g.sessionTime.trim().toLowerCase().replaceAll(' ', '');
        if (gTime == normalizedTime) {
          final hasSharedDay = g.trainingDays.any((d) => trainingDays.contains(d));
          if (hasSharedDay) {
            conflict = g;
            break;
          }
        }
      }
    }

    if (conflict != null) {
      final sharedDays = conflict.trainingDays.where((d) => trainingDays.contains(d)).toList();
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تنبيه: تضارب في مواعيد الكابتن!',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الكابتن «${coachName ?? conflict!.coachName}» لديه بالفعل مجموعة مسجلة في نفس التوقيت:',
                style: GoogleFonts.cairo(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.warningOrange),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• كود المجموعة الأخرى: ${conflict.groupCode}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('• الأيام المتطابقة: ${sharedDays.join("، ")}', style: GoogleFonts.cairo(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('• الميعاد: ${conflict.sessionTime}', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '⚠️ فتح مجموعتين لنفس الكابتن في نفس التوقيت قد يسبب ارتباكاً شديداً في كشف النزول. هل أنت متأكد من الحفظ؟',
                style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.errorRed, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text('تراجع لتعديل الميعاد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('متابعة الحفظ رغم التضارب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      return proceed == true;
    }

    return true;
  }

  // --- إضافة مجموعة جديدة ---
  void _showAddGroupDialog() {
    final codeController = TextEditingController(text: 'GRP-0${DateTime.now().second}');
    final capacityController = TextEditingController(text: '6');
    final timeController = TextEditingController(text: '05:00 PM');
    String trainingType = AppConstants.trainingTypes.first;
    String level = 'مبتدئ';
    String? selectedCoachName;
    String? selectedCoachId;
    List<String> selectedDays = ['السبت', 'الثلاثاء'];

    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final coachesAsync = ref.watch(coachesStreamProvider);
            return StatefulBuilder(
              builder: (context, setModalState) {
                return AlertDialog(
                  title: Row(
                    children: [
                      const Icon(Icons.group_add, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      Text('إضافة مجموعة تدريبية جديدة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: codeController,
                          decoration: const InputDecoration(labelText: 'كود المجموعة (مثل GRP-04) *'),
                        ),
                        const SizedBox(height: 12),

                        // Coach Selection
                        coachesAsync.when(
                          data: (coaches) {
                            return DropdownButtonFormField<String>(
                              value: selectedCoachId,
                              decoration: const InputDecoration(labelText: 'المدرب المسؤول *'),
                              items: coaches.map((c) {
                                return DropdownMenuItem(value: c.coachId, child: Text(c.coachName, style: GoogleFonts.cairo(fontSize: 13)));
                              }).toList(),
                              onChanged: (val) {
                                setModalState(() {
                                  selectedCoachId = val;
                                  selectedCoachName = coaches.firstWhere((c) => c.coachId == val).coachName;
                                });
                              },
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('خطأ في تحميل الكباتن'),
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: trainingType,
                          decoration: const InputDecoration(labelText: 'نوع ومستوى التدريب'),
                          items: AppConstants.trainingTypes.map((t) {
                            return DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.cairo(fontSize: 13)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => trainingType = val);
                          },
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: timeController,
                          decoration: const InputDecoration(labelText: 'موعد الحصة (مثال: 05:00 PM)'),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: capacityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'السعة القصوى (عدد المقاعد)'),
                        ),

                        const SizedBox(height: 14),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('أيام التدريب في الأسبوع:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: AppConstants.weekDays.map((day) {
                            final isSelected = selectedDays.contains(day);
                            return FilterChip(
                              label: Text(day, style: GoogleFonts.cairo(fontSize: 11)),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedDays.add(day);
                                  } else {
                                    selectedDays.remove(day);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (codeController.text.trim().isEmpty) return;

                        // Check coach schedule conflict
                        final canProceed = await _checkCoachScheduleConflict(
                          context: context,
                          coachId: selectedCoachId,
                          coachName: selectedCoachName,
                          sessionTime: timeController.text.trim(),
                          trainingDays: selectedDays,
                        );
                        if (!canProceed) return;

                        final cap = int.tryParse(capacityController.text) ?? 6;

                        final group = GroupModel(
                          groupCode: codeController.text.trim(),
                          coachId: selectedCoachId ?? 'COACH-01',
                          coachName: selectedCoachName ?? 'كابتن أكاديمية',
                          trainingDays: selectedDays,
                          sessionTime: timeController.text.trim(),
                          trainingType: trainingType,
                          level: level,
                          maxCapacity: cap,
                          currentRegistered: 0,
                        );

                        await ref.read(groupRepositoryProvider).createGroup(group);
                        if (mounted) {
                          Navigator.pop(ctx);
                          AppDialogs.showSuccessSnackBar(context, 'تم إنشاء المجموعة التدريبية بنجاح');
                          ref.invalidate(groupsStreamProvider);
                        }
                      },
                      child: const Text('إنشاء المجموعة'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // --- تعديل بيانات أي مجموعة (ميزة المالك والإداري) ---
  void _showEditGroupDialog(GroupModel group) {
    final capacityController = TextEditingController(text: '${group.maxCapacity}');
    final registeredController = TextEditingController(text: '${group.currentRegistered}');
    final timeController = TextEditingController(text: group.sessionTime);
    String trainingType = group.trainingType;
    String? selectedCoachName = group.coachName;
    String? selectedCoachId = group.coachId;
    List<String> selectedDays = List<String>.from(group.trainingDays);

    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final coachesAsync = ref.watch(coachesStreamProvider);
            return StatefulBuilder(
              builder: (context, setModalState) {
                return AlertDialog(
                  title: Row(
                    children: [
                      const Icon(Icons.edit, color: AppTheme.accentTeal),
                      const SizedBox(width: 8),
                      Text('تعديل المجموعة (${group.groupCode})', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Coach Selection
                        coachesAsync.when(
                          data: (coaches) {
                            return DropdownButtonFormField<String>(
                              value: coaches.any((c) => c.coachId == selectedCoachId) ? selectedCoachId : null,
                              decoration: const InputDecoration(labelText: 'المدرب المسؤول'),
                              items: coaches.map((c) {
                                return DropdownMenuItem(value: c.coachId, child: Text(c.coachName, style: GoogleFonts.cairo(fontSize: 13)));
                              }).toList(),
                              onChanged: (val) {
                                setModalState(() {
                                  selectedCoachId = val;
                                  selectedCoachName = coaches.firstWhere((c) => c.coachId == val).coachName;
                                });
                              },
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('خطأ في تحميل الكباتن'),
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: AppConstants.trainingTypes.contains(trainingType) ? trainingType : AppConstants.trainingTypes.first,
                          decoration: const InputDecoration(labelText: 'نوع ومستوى التدريب'),
                          items: AppConstants.trainingTypes.map((t) {
                            return DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.cairo(fontSize: 13)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => trainingType = val);
                          },
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: timeController,
                          decoration: const InputDecoration(labelText: 'موعد الحصة (مثال: 05:00 PM)'),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: capacityController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'السعة القصوى (المقاعد)'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: registeredController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'المشتركين الفعليين'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('أيام التدريب في الأسبوع:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: AppConstants.weekDays.map((day) {
                            final isSelected = selectedDays.contains(day);
                            return FilterChip(
                              label: Text(day, style: GoogleFonts.cairo(fontSize: 11)),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedDays.add(day);
                                  } else {
                                    selectedDays.remove(day);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentTeal),
                      onPressed: () async {
                        // Check coach schedule conflict
                        final canProceed = await _checkCoachScheduleConflict(
                          context: context,
                          coachId: selectedCoachId ?? group.coachId,
                          coachName: selectedCoachName ?? group.coachName,
                          sessionTime: timeController.text.trim(),
                          trainingDays: selectedDays,
                          currentGroupCode: group.groupCode,
                        );
                        if (!canProceed) return;

                        final cap = int.tryParse(capacityController.text) ?? group.maxCapacity;
                        final reg = int.tryParse(registeredController.text) ?? group.currentRegistered;

                        final updated = group.copyWith(
                          coachId: selectedCoachId ?? group.coachId,
                          coachName: selectedCoachName ?? group.coachName,
                          trainingDays: selectedDays,
                          sessionTime: timeController.text.trim(),
                          trainingType: trainingType,
                          maxCapacity: cap,
                          currentRegistered: reg,
                        );

                        await ref.read(groupRepositoryProvider).updateGroup(updated);
                        if (mounted) {
                          Navigator.pop(ctx);
                          AppDialogs.showSuccessSnackBar(context, 'تم تعديل بيانات المجموعة ${group.groupCode} بنجاح');
                          ref.invalidate(groupsStreamProvider);
                        }
                      },
                      child: const Text('حفظ التعديلات'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // --- عرض السباحين المسجلين في المجموعة مع إمكانية نقلهم ---
  void _showGroupSwimmersSheet(GroupModel group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final swimmers = ref.watch(groupRepositoryProvider).getSwimmersInGroup(group.groupCode);

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.35,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'السباحين المسجلين في ${group.groupCode}',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue),
                              ),
                              Text(
                                'المدرب: ${group.coachName} | ${group.trainingDays.join("، ")} (${group.sessionTime})',
                                style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                          Chip(
                            label: Text(
                              '${swimmers.length} سباح',
                              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            backgroundColor: AppTheme.primaryBlue,
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      if (swimmers.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_off_outlined, size: 50, color: AppTheme.textMuted),
                                const SizedBox(height: 10),
                                Text('لا يوجد سباحين مسجلين في هذه المجموعة حالياً.', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const SubscriptionEntryScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('تسجيل اشتراك جديد'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            itemCount: swimmers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final sub = swimmers[i];
                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                                        child: const Icon(Icons.pool, color: AppTheme.primaryBlue, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sub.playerName,
                                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            Text(
                                              'كود: ${sub.playerCode} | حضور: ${sub.attendedSessions}/${sub.sessionsCount} حصة (المتبقي: ${sub.remainingSessions})',
                                              style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.warningOrange,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {
                                          _showTransferSwimmerDialog(sub, group);
                                        },
                                        icon: const Icon(Icons.swap_horiz, size: 16),
                                        label: Text('نقل لمجموعة', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- نافذة نقل السباح لمجموعة بديلة ---
  void _showTransferSwimmerDialog(SubscriptionModel sub, GroupModel currentGroup) {
    final allGroups = ref.read(groupRepositoryProvider).getGroups();
    final targetGroups = allGroups.where((g) => g.groupCode != currentGroup.groupCode).toList();
    GroupModel? selectedTargetGroup = targetGroups.isNotEmpty ? targetGroups.first : null;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
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
                          Text('المجموعة الحالية: ${currentGroup.groupCode} - ${currentGroup.coachName}', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
                          Text('المواعيد الحالية: ${currentGroup.trainingDays.join("، ")} (${currentGroup.sessionTime})', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
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
                      : () async {
                          final ok = await ref.read(groupRepositoryProvider).transferSwimmerGroup(
                                subscriptionId: sub.id,
                                newGroupCode: selectedTargetGroup!.groupCode,
                              );
                          if (ok && mounted) {
                            Navigator.pop(dialogCtx); // إغلاق نافذة النقل
                            Navigator.pop(context); // إغلاق قائمة السباحين
                            AppDialogs.showSuccessSnackBar(
                              context,
                              'تم نقل السباح (${sub.playerName}) إلى مجموعة (${selectedTargetGroup!.groupCode} - ${selectedTargetGroup!.coachName}) بنجاح!',
                            );
                            ref.invalidate(groupsStreamProvider);
                            ref.invalidate(subscriptionsStreamProvider);
                          }
                        },
                  child: const Text('تأكيد النقل'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- تأكيد حذف المجموعة ---
  void _confirmDeleteGroup(GroupModel group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: AppTheme.errorRed),
            const SizedBox(width: 8),
            Text('تأكيد حذف المجموعة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          group.currentRegistered > 0
              ? 'تنبيه: المجموعة (${group.groupCode}) تحتوي حالياً على ${group.currentRegistered} مشترك مسجل!\nهل أنت متأكد من رغبتك في حذفها نهائياً؟'
              : 'هل أنت متأكد من حذف المجموعة (${group.groupCode})؟',
          style: GoogleFonts.cairo(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              await ref.read(groupRepositoryProvider).deleteGroup(group.groupCode);
              Navigator.pop(ctx);
              AppDialogs.showSuccessSnackBar(context, 'تم حذف المجموعة ${group.groupCode} بنجاح');
              ref.invalidate(groupsStreamProvider);
            },
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة وتوزيع المجموعات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'إضافة مجموعة جديدة',
            onPressed: _showAddGroupDialog,
          ),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.groups_outlined, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text('لا توجد مجموعات مضافة حالياً', style: GoogleFonts.cairo()),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _showAddGroupDialog,
                    child: const Text('إضافة مجموعة الآن'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (ctx, index) {
              final g = groups[index];
              final isFull = !g.isAvailable;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${g.groupCode} - ${g.trainingType}',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              g.status,
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: isFull ? AppTheme.errorRed : AppTheme.successGreen,
                          ),
                        ],
                      ),
                      const Divider(height: 16),

                      // Details
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: AppTheme.primaryBlue),
                          const SizedBox(width: 6),
                          Text('المدرب: ${g.coachName}', style: GoogleFonts.cairo(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryBlue),
                          const SizedBox(width: 6),
                          Text('الأيام: ${g.trainingDays.join('، ')} (${g.sessionTime})', style: GoogleFonts.cairo(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.people, size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'المشتركين: ${g.currentRegistered} من إجمالي ${g.maxCapacity} مقعد (المتاح: ${g.availableSeats})',
                            style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Action Buttons Row (تعديل + السباحين ونقلهم + حذف)
                      Row(
                        children: [
                          // زر السباحين ونقلهم
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _showGroupSwimmersSheet(g),
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: Text(
                                'السباحين ونقلهم (${g.currentRegistered})',
                                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // زر تعديل بيانات المجموعة
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.accentTeal,
                                side: const BorderSide(color: AppTheme.accentTeal),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _showEditGroupDialog(g),
                              icon: const Icon(Icons.edit, size: 16),
                              label: Text(
                                'تعديل',
                                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // زر حذف المجموعة
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 22),
                            tooltip: 'حذف المجموعة',
                            onPressed: () => _confirmDeleteGroup(g),
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
    );
  }
}
