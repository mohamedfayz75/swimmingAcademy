import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../coaches_payroll/providers/coaches_payroll_provider.dart';
import '../models/group_model.dart';
import '../providers/group_provider.dart';

class GroupsManagementScreen extends ConsumerStatefulWidget {
  const GroupsManagementScreen({super.key});

  @override
  ConsumerState<GroupsManagementScreen> createState() => _GroupsManagementScreenState();
}

class _GroupsManagementScreenState extends ConsumerState<GroupsManagementScreen> {
  void _showAddGroupDialog() {
    final codeController = TextEditingController(text: 'GRP-0${DateTime.now().second}');
    final capacityController = TextEditingController(text: '10');
    final timeController = TextEditingController(text: '05:00 PM');
    String trainingType = AppConstants.trainingTypes.first;
    String level = 'مبتدئ';
    String? selectedCoachName;
    String? selectedCoachId;
    List<String> selectedDays = ['السبت', 'الثلاثاء'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final coachesAsync = ref.watch(coachesStreamProvider);

            return AlertDialog(
              title: Text('إضافة مجموعة تدريبية جديدة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'كود المجموعة (مثل GRP-04)'),
                    ),
                    const SizedBox(height: 12),

                    // Coach Selection
                    coachesAsync.when(
                      data: (coaches) {
                        return DropdownButtonFormField<String>(
                          value: selectedCoachId,
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
                      value: trainingType,
                      decoration: const InputDecoration(labelText: 'نوع التدريب'),
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
                    final cap = int.tryParse(capacityController.text) ?? 10;

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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final g = groups[index];
              final isFull = !g.isAvailable;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${g.groupCode} - ${g.trainingType}',
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
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
                      Text('المدرب: ${g.coachName}', style: GoogleFonts.cairo(fontSize: 13)),
                      Text('الأيام: ${g.trainingDays.join('، ')} (${g.sessionTime})', style: GoogleFonts.cairo(fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(
                        'المشتركين: ${g.currentRegistered} من إجمالي ${g.maxCapacity} مقعد (المتاح: ${g.availableSeats})',
                        style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
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
