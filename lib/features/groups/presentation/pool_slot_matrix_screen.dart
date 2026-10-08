import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../models/group_model.dart';
import '../providers/group_provider.dart';

class PoolSlotMatrixScreen extends ConsumerStatefulWidget {
  const PoolSlotMatrixScreen({super.key});

  @override
  ConsumerState<PoolSlotMatrixScreen> createState() => _PoolSlotMatrixScreenState();
}

class _PoolSlotMatrixScreenState extends ConsumerState<PoolSlotMatrixScreen> {
  String _selectedDay = 'السبت';

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول المواعيد وسعة الحارات (Pool Matrix)'),
      ),
      body: Column(
        children: [
          // Day Selector Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: AppConstants.weekDays.map((day) {
                  final isSelected = _selectedDay == day;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        day,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryBlue,
                      backgroundColor: AppTheme.backgroundLight,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedDay = day);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1),

          // Group Slots for selected day
          Expanded(
            child: groupsAsync.when(
              data: (groups) {
                final dayGroups = groups.where((g) => g.trainingDays.contains(_selectedDay)).toList();

                if (dayGroups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_busy, size: 56, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد مجموعات تدريبية مبرمجة في يوم $_selectedDay',
                          style: GoogleFonts.cairo(fontSize: 16, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayGroups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) {
                    final group = dayGroups[index];
                    final utilization = group.maxCapacity > 0
                        ? (group.currentRegistered / group.maxCapacity).clamp(0.0, 1.0)
                        : 0.0;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        group.groupCode,
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      group.trainingType,
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: group.isAvailable
                                        ? AppTheme.successGreen.withOpacity(0.12)
                                        : AppTheme.errorRed.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    group.status,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: group.isAvailable ? AppTheme.successGreen : AppTheme.errorRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'الموعد: ${group.sessionTime}',
                                  style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textDark),
                                ),
                                const SizedBox(width: 20),
                                const Icon(Icons.person, size: 16, color: AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'المدرب: ${group.coachName}',
                                  style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textDark),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Capacity utilization progress
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'نسبة الإشغال: ${group.currentRegistered} من ${group.maxCapacity} مشترك',
                                  style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                ),
                                Text(
                                  'المقاعد المتبقية: ${group.availableSeats}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: group.isAvailable ? AppTheme.primaryBlue : AppTheme.errorRed,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: utilization,
                                minHeight: 8,
                                backgroundColor: Colors.blueGrey.shade100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  group.isAvailable ? AppTheme.accentCyan : AppTheme.errorRed,
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
              error: (err, _) => Center(child: Text('خطأ في تحميل الجدول: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
