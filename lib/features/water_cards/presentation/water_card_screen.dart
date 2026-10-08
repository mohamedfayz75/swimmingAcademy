import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/rbac/app_role.dart';
import '../models/water_card_model.dart';
import '../providers/water_card_provider.dart';

class WaterCardScreen extends ConsumerStatefulWidget {
  const WaterCardScreen({super.key});

  @override
  ConsumerState<WaterCardScreen> createState() => _WaterCardScreenState();
}

class _WaterCardScreenState extends ConsumerState<WaterCardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(waterCardRepositoryProvider).seedInitialWaterCardIfEmpty();
    });
  }

  void _showNewCardDialog() {
    final nameController = TextEditingController(text: 'كرت مياة جديد');
    final priceController = TextEditingController(text: '1200.0');
    final sessionsController = TextEditingController(text: '40');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إصدار كرت مياة جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم / رقم الكرت'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'سعر الكرت (ج.م)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sessionsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'إجمالي الحصص'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceController.text) ?? 1200.0;
              final total = int.tryParse(sessionsController.text) ?? 40;
              final now = DateTime.now();
              final monthRef = '${now.month.toString().padLeft(2, '0')}-${now.year}';

              await ref.read(waterCardActionProvider.notifier).createNewCard(
                    cardName: nameController.text.trim(),
                    cardPrice: price,
                    totalSessions: total,
                    monthlyClosingRef: monthRef,
                  );

              if (mounted) {
                Navigator.pop(ctx);
                AppDialogs.showSuccessSnackBar(context, 'تم تفعيل كرت المياة بنجاح');
                ref.invalidate(activeWaterCardStreamProvider);
              }
            },
            child: const Text('تفعيل الكرت'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCardAsync = ref.watch(activeWaterCardStreamProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isOwner = currentUser?.role.isOwner ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('كروت المياة والاستهلاك اليومي'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.add_card),
              tooltip: 'إصدار كرت جديد',
              onPressed: _showNewCardDialog,
            ),
        ],
      ),
      body: activeCardAsync.when(
        data: (card) {
          if (card == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.water_drop_outlined, size: 64, color: AppTheme.accentCyan),
                  const SizedBox(height: 16),
                  Text('لا يوجد كرت مياة نشط حالياً', style: GoogleFonts.cairo(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showNewCardDialog,
                    child: const Text('تفعيل كرت مياة الآن'),
                  ),
                ],
              ),
            );
          }

          // Indicator color badge
          Color statusBadgeColor = AppTheme.successGreen;
          String statusBadgeText = 'نشط (متبقي رصيد كافٍ)';
          if (card.isDepleted) {
            statusBadgeColor = AppTheme.errorRed;
            statusBadgeText = 'منتهي (الرصيد نفد)';
          } else if (card.isLow) {
            statusBadgeColor = AppTheme.warningOrange;
            statusBadgeText = 'تنبيه (متبقي أقل من 5 حصص)';
          }

          final progressRatio = (card.totalUsedSessions / card.totalSessions).clamp(0.0, 1.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Status Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.cardName,
                                  style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                ),
                                Text(
                                  'تاريخ الإصدار: ${AppFormatters.formatTimestamp(card.cardDate)}',
                                  style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusBadgeColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusBadgeColor),
                              ),
                              child: Text(
                                statusBadgeText,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusBadgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Large Counters
                        Row(
                          children: [
                            _buildMetricBox('إجمالي الحصص', '${card.totalSessions}', AppTheme.primaryBlue),
                            const SizedBox(width: 12),
                            _buildMetricBox('المستهلك', '${card.totalUsedSessions}', AppTheme.warningOrange),
                            const SizedBox(width: 12),
                            _buildMetricBox('المتبقي', '${card.remainingSessions}', statusBadgeColor),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Consumption Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progressRatio,
                            minHeight: 12,
                            backgroundColor: Colors.blueGrey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(statusBadgeColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'تسجيل الاستهلاك اليومي (الحصص المستهلكة)',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 8),

                // 4-Days Consumption Editors
                _buildDayCounterTile(card: card, dayNumber: 1, currentCount: card.usedDay1),
                const SizedBox(height: 12),
                _buildDayCounterTile(card: card, dayNumber: 2, currentCount: card.usedDay2),
                const SizedBox(height: 12),
                _buildDayCounterTile(card: card, dayNumber: 3, currentCount: card.usedDay3),
                const SizedBox(height: 12),
                _buildDayCounterTile(card: card, dayNumber: 4, currentCount: card.usedDay4),

                if (card.isDepleted) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.errorRed),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'تنبيه: لقد تم استهلاك جميع حصص هذا الكرت بالكامل!',
                          style: GoogleFonts.cairo(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (isOwner)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                            onPressed: _showNewCardDialog,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إصدار كرت جديد وإغلاق الحالي'),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('خطأ في تحميل كرت المياة: $err')),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCounterTile({
    required WaterCardModel card,
    required int dayNumber,
    required int currentCount,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'يوم $dayNumber',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 14),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'الحصص المستهلكة: $currentCount',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            // Decrement Button
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.errorRed),
              onPressed: currentCount > 0
                  ? () {
                      ref.read(waterCardActionProvider.notifier).updateDaySessions(
                            cardId: card.id,
                            dayNumber: dayNumber,
                            sessionsCount: currentCount - 1,
                          );
                    }
                  : null,
            ),
            Text(
              '$currentCount',
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            ),
            // Increment Button
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.accentTeal),
              onPressed: card.remainingSessions > 0
                  ? () {
                      ref.read(waterCardActionProvider.notifier).updateDaySessions(
                            cardId: card.id,
                            dayNumber: dayNumber,
                            sessionsCount: currentCount + 1,
                          );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
