import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/local_store.dart';
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
  void _showNewCardDialog() {
    final nameController = TextEditingController(text: 'كارت مياة جديد');
    final priceController = TextEditingController(text: '1500.0');
    final sessionsController = TextEditingController(text: '50');
    String poolType = AppConstants.poolSemiOlympic;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('إصدار كارت مياة جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: poolType,
                    decoration: const InputDecoration(labelText: 'نوع المسبح / الحمام *'),
                    items: AppConstants.poolTypes.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          poolType = val;
                          if (val == AppConstants.poolSemiOlympic) {
                            priceController.text = '1500.0';
                            sessionsController.text = '50';
                          } else {
                            priceController.text = '1200.0';
                            sessionsController.text = '40';
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'اسم / رقم الكارت *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'سعر الكارت (ج.م) *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sessionsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'إجمالي الحصص المتاحة للكارت *'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () {
                  final price = double.tryParse(priceController.text) ?? 1500.0;
                  final total = int.tryParse(sessionsController.text) ?? 50;
                  final now = DateTime.now();
                  final monthRef = '${now.month.toString().padLeft(2, '0')}-${now.year}';

                  final model = WaterCardModel(
                    id: 'WC-${DateTime.now().millisecondsSinceEpoch}',
                    cardDate: DateTime.now() as dynamic, // handled in localStore
                    cardName: nameController.text.trim(),
                    poolType: poolType,
                    cardPrice: price,
                    totalSessions: total,
                    monthlyClosingRef: monthRef,
                  );

                  LocalStore.instance.addWaterCard(model);
                  Navigator.pop(ctx);
                  AppDialogs.showSuccessSnackBar(context, 'تم تفعيل الكارت وترحيل سعره تلقائياً للمصروفات العامة!');
                  setState(() {});
                },
                child: const Text('تفعيل وترحيل للمصروفات'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isOwner = currentUser?.role.isOwner ?? false;

    return StreamBuilder<List<WaterCardModel>>(
      stream: LocalStore.instance.waterCardsStream,
      initialData: LocalStore.instance.getWaterCards(),
      builder: (context, snapshot) {
        final cards = snapshot.data ?? [];
        final semiOlympicCard = LocalStore.instance.getActiveCardForPool(AppConstants.poolSemiOlympic);
        final recreationalCard = LocalStore.instance.getActiveCardForPool(AppConstants.poolRecreational);

        return Scaffold(
          appBar: AppBar(
            title: const Text('كروت المياة والاستهلاك المزدوج'),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.add_card),
                  tooltip: 'إصدار كارت مياة جديد',
                  onPressed: _showNewCardDialog,
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.water, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'متابعة وتشغيل كروت المسبحين (نصف أولمبي & ترفيهي) بشكل متزامن وبدون تداخل.',
                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 1. Semi-Olympic Card Section
                Text(
                  '🏊 1. كارت المسبح النصف أولمبي (Semi-Olympic)',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 8),
                if (semiOlympicCard != null)
                  _buildPoolCardView(semiOlympicCard)
                else
                  _buildEmptyPoolCard(AppConstants.poolSemiOlympic),

                const SizedBox(height: 24),

                // 2. Recreational Card Section
                Text(
                  '🏖️ 2. كارت المسبح الترفيهي (Recreational)',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.accentTeal),
                ),
                const SizedBox(height: 8),
                if (recreationalCard != null)
                  _buildPoolCardView(recreationalCard)
                else
                  _buildEmptyPoolCard(AppConstants.poolRecreational),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyPoolCard(String poolName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Text('لا يوجد كارت نشط حالياً لمسبح $poolName', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _showNewCardDialog,
                icon: const Icon(Icons.add),
                label: Text('تفعيل كارت لـ $poolName'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoolCardView(WaterCardModel card) {
    Color badgeColor = AppTheme.successGreen;
    String badgeText = 'نشط (رصيد كافٍ)';
    if (card.isDepleted) {
      badgeColor = AppTheme.errorRed;
      badgeText = 'منتهي (الرصيد نفد)';
    } else if (card.isLow) {
      badgeColor = AppTheme.warningOrange;
      badgeText = 'تنبيه (< 5 حصص متبقية)';
    }

    final ratio = card.totalSessions > 0 ? (card.usedSessions / card.totalSessions).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: badgeColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.cardName, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    Text('سعر الكارت: ${AppFormatters.formatCurrency(card.cardPrice)} (مُرحّل للمصروفات)', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor),
                  ),
                  child: Text(badgeText, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor)),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Counters Row
            Row(
              children: [
                _buildMetricBox('الحصص الكلية', '${card.totalSessions}', AppTheme.primaryBlue),
                const SizedBox(width: 8),
                _buildMetricBox('المستهلك', '${card.usedSessions}', AppTheme.warningOrange),
                const SizedBox(width: 8),
                _buildMetricBox('المتبقي', '${card.remainingSessions}', badgeColor),
              ],
            ),

            const SizedBox(height: 14),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: Colors.blueGrey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
              ),
            ),

            const Divider(height: 24),

            // Manual consumption controller (+ / -)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تسجيل الاستهلاك اليومي / بعد التمرينة:',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: AppTheme.errorRed, size: 28),
                      onPressed: card.usedSessions > 0
                          ? () {
                              LocalStore.instance.updateWaterCardSessions(card.id, card.usedSessions - 1);
                              setState(() {});
                            }
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${card.usedSessions}',
                        style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppTheme.accentTeal, size: 28),
                      onPressed: card.remainingSessions > 0
                          ? () {
                              LocalStore.instance.updateWaterCardSessions(card.id, card.usedSessions + 1);
                              setState(() {});
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
