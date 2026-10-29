import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/local_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/rbac/app_role.dart';
import '../models/water_card_model.dart';
import '../models/pool_overdraft_model.dart';

class WaterCardScreen extends ConsumerStatefulWidget {
  const WaterCardScreen({super.key});

  @override
  ConsumerState<WaterCardScreen> createState() => _WaterCardScreenState();
}

class _WaterCardScreenState extends ConsumerState<WaterCardScreen> {
  // --- تأكيد حفظ وترحيل الكارت المكتمل إلى الأرشيف والماليات ليختفي من الشاشة ---
  Future<void> _confirmArchiveCard(WaterCardModel card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.archive, color: AppTheme.successGreen),
            const SizedBox(width: 8),
            Text('تأكيد حفظ وترحيل الكارت', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل تريد حفظ وإتمام كارت «${card.cardName}» وترحيله إلى الأرشيف والماليات الآن؟',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('إجمالي حصص الكارت:', style: GoogleFonts.cairo(fontSize: 12)),
                      Text('${card.totalSessions} حصة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الحصص المستهلكة:', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.warningOrange)),
                      Text('${card.usedSessions} حصة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.warningOrange)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المبلغ المسجل بالماليات:', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.primaryBlue)),
                      Text('${card.cardPrice} ج.م', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryBlue)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '✔️ بمجرد الحفظ، سيختفي الكارت من الشاشة النشطة ليكون المسبح جاهزاً لإصدار كارت جديد، وسيكون محفوظاً بشكل دائم في «أرشيف الكروت» وقسم الماليات.',
              style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text('تأكيد الحفظ والإغلاق', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      LocalStore.instance.archiveWaterCard(card.id);
      await LocalStore.instance.saveAllExplicitly();
      if (mounted) {
        AppDialogs.showSuccessSnackBar(
          context,
          '🎉 تم حفظ وإتمام كارت «${card.cardName}» بنجاح! اختفى من الشاشة وأصبح محفوظاً في الأرشيف والماليات.',
        );
        setState(() {});
      }
    }
  }

  // --- إظهار نافذة إصدار كارت مياة جديد مع فحص الحصص المعلقة ---
  void _showNewCardDialog({String? initialPoolType}) {
    String poolType = initialPoolType ?? AppConstants.poolSemiOlympic;
    final nameController = TextEditingController(
      text: poolType == AppConstants.poolSemiOlympic ? 'كارت نصف أولمبي جديد' : 'كارت ترفيهي جديد',
    );
    final priceController = TextEditingController(
      text: poolType == AppConstants.poolSemiOlympic ? '1500.0' : '1200.0',
    );
    final sessionsController = TextEditingController(
      text: poolType == AppConstants.poolSemiOlympic ? '50' : '40',
    );

    bool deductPending = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final pendingSessions = LocalStore.instance.getPendingOverdraftSessionsForPool(poolType);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.add_card, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text('إصدار كارت مياة جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pool, color: AppTheme.primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'المسبح: نصف أولمبي (المسبح الرئيسي)',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue),
                        ),
                      ],
                    ),
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

                  // تنبيه بالحصص المعلقة المسجلة في الملاحظات بدون كارت
                  if (pendingSessions > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.warningOrange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 20),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'يوجد $pendingSessions حصة مستهلكة سابقة مسجلة في الملاحظات لهذا المسبح (بدون كارت)',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown.shade900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: deductPending,
                            activeColor: AppTheme.primaryBlue,
                            title: Text(
                              'خصم هذه الحصص ($pendingSessions حصة) فوراً من هذا الكارت الجديد وحذفها من الملاحظات المعلقة',
                              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onChanged: (val) {
                              setModalState(() => deductPending = val ?? true);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text('تفعيل وترحيل للمصروفات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                onPressed: () {
                  final price = double.tryParse(priceController.text.trim()) ?? 1500.0;
                  final total = int.tryParse(sessionsController.text.trim()) ?? 50;
                  final now = DateTime.now();
                  final monthRef = '${now.month.toString().padLeft(2, '0')}-${now.year}';

                  final model = WaterCardModel(
                    id: 'WC-${DateTime.now().millisecondsSinceEpoch}',
                    cardDate: Timestamp.now(),
                    cardName: nameController.text.trim().isEmpty ? 'كارت مياة' : nameController.text.trim(),
                    poolType: poolType,
                    cardPrice: price,
                    totalSessions: total,
                    usedSessions: 0,
                    monthlyClosingRef: monthRef,
                  );

                  LocalStore.instance.addWaterCard(
                    model,
                    deductPendingOverdraft: deductPending && pendingSessions > 0,
                  );

                  Navigator.pop(ctx);
                  if (deductPending && pendingSessions > 0) {
                    AppDialogs.showSuccessSnackBar(
                      context,
                      'تم تفعيل الكارت الجديد، وخصم $pendingSessions حصة مستهلكة سابقة من رصيده وحذفها من الملاحظات بنجاح!',
                    );
                  } else {
                    AppDialogs.showSuccessSnackBar(context, 'تم تفعيل الكارت وترحيل سعره تلقائياً للمصروفات العامة!');
                  }
                  setState(() {});
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // --- تسجيل استهلاك الحصص بالأرقام مباشرة ---
  void _showRecordSessionsDialog(WaterCardModel card, {required bool isOwner}) {
    final countController = TextEditingController();
    bool isAdding = true; // Staff can only add sessions; Owner can edit total

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final entered = int.tryParse(countController.text.trim()) ?? 0;
          final previewUsed = isAdding ? (card.usedSessions + entered) : entered;
          final previewRemaining = (card.totalSessions - previewUsed).clamp(0, card.totalSessions);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.edit_note, color: AppTheme.accentTeal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تسجيل استهلاك حصص (${card.cardName})',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // اختيار طريقة التسجيل (تعديل الإجمالي متاح فقط للمالك)
                  if (isOwner) ...[
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('إضافة للاستهلاك (+)', style: TextStyle(fontSize: 12)),
                          icon: Icon(Icons.add, size: 16),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('تعديل الإجمالي', style: TextStyle(fontSize: 12)),
                          icon: Icon(Icons.edit, size: 16),
                        ),
                      ],
                      selected: {isAdding},
                      onSelectionChanged: (set) {
                        setModalState(() {
                          isAdding = set.first;
                          if (!isAdding && countController.text.isEmpty) {
                            countController.text = '${card.usedSessions}';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                      ),
                      child: Text(
                        '💡 إضافة حصص مستهلكة: اكتب عدد الحصص المنفذة اليوم لإضافتها فوراً لرصيد الكارت.',
                        style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // خانة كتابة عدد الحصص
                  TextField(
                    controller: countController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: isAdding ? 'عدد الحصص المستهلكة اليوم (بالأرقام) *' : 'إجمالي الحصص المستهلكة بالكارت *',
                      hintText: isAdding ? 'مثال: 15' : 'مثال: 25',
                      prefixIcon: const Icon(Icons.pin),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // أزرار سريعة للأرقام الشائعة
                  if (isAdding) ...[
                    Text('أزرار إضافة سريعة:', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [1, 2, 5, 8, 10, 15, 20].map((num) {
                        return ActionChip(
                          label: Text('+$num', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
                          backgroundColor: AppTheme.accentTeal.withOpacity(0.1),
                          onPressed: () {
                            setModalState(() {
                              countController.text = '$num';
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // بطاقة المعاينة اللحظية
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueGrey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('المستهلك حالياً:', style: GoogleFonts.cairo(fontSize: 12)),
                            Text('${card.usedSessions} حصة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('المستهلك بعد التحديث:', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.warningOrange)),
                            Text('$previewUsed حصة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.warningOrange)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('المتبقي في الكارت:', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.successGreen)),
                            Text('$previewRemaining حصة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.successGreen)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: Text('تأكيد وحفظ الاستهلاك', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final enteredVal = int.tryParse(countController.text.trim()) ?? 0;
                  if (enteredVal <= 0 && isAdding) {
                    AppDialogs.showErrorSnackBar(context, 'يرجى كتابة عدد الحصص بالأرقام');
                    return;
                  }

                  final newTotalUsed = isAdding ? (card.usedSessions + enteredVal) : enteredVal;

                  // التحقق من الصلاحية: لا يمكن تقليل الحصص المستهلكة إلا بواسطة المالك
                  if (!isOwner && newTotalUsed < card.usedSessions) {
                    AppDialogs.showErrorSnackBar(context, 'عفواً، لا يمكن تقليل عدد الحصص المستهلكة إلا بواسطة المالك');
                    return;
                  }

                  LocalStore.instance.updateWaterCardSessions(card.id, newTotalUsed);
                  await LocalStore.instance.saveAllExplicitly();

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    if (newTotalUsed >= card.totalSessions) {
                      _confirmArchiveCard(card.copyWith(usedSessions: newTotalUsed));
                    } else {
                      AppDialogs.showSuccessSnackBar(
                        context,
                        'تم تحديث وتثبيت استهلاك كارت ${card.cardName}! المستهلك: $newTotalUsed | المتبقي: ${card.totalSessions - newTotalUsed}',
                      );
                      setState(() {});
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // --- إضافة ملاحظة استهلاك بالآجل / عجز كارت ---
  void _showAddOverdraftNoteDialog(String initialPoolType) {
    String poolType = initialPoolType;
    final sessionsController = TextEditingController();
    final noteController = TextEditingController();
    DateTime noteDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.note_add, color: AppTheme.warningOrange),
                const SizedBox(width: 8),
                Text('تسجيل حصص مستهلكة بدون كارت', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: poolType,
                    decoration: const InputDecoration(labelText: 'تحديد المسبح / الحمام *'),
                    items: AppConstants.poolTypes.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(
                          p == AppConstants.poolSemiOlympic ? '🏊 مسبح نصف أولمبي' : '🏖️ مسبح ترفيهي',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => poolType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sessionsController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'عدد الحصص المستهلكة (بالأرقام) *',
                      hintText: 'مثال: 12',
                      prefixIcon: Icon(Icons.pin),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'الملاحظة والبيان *',
                      hintText: 'مثال: تمرين الأحد بعد نفاد الكارت ولم نشتر كارت بعد',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '💡 سيتم حفظ هذه الحصص في ملاحظات هذا المسبح لخصمها فوراً عند قطع كارت مياة جديد.',
                    style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.save, size: 18),
                label: Text('حفظ في الملاحظات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                onPressed: () {
                  final sessions = int.tryParse(sessionsController.text.trim()) ?? 0;
                  if (sessions <= 0) {
                    AppDialogs.showErrorSnackBar(context, 'يرجى كتابة عدد الحصص بالأرقام');
                    return;
                  }

                  final note = PoolOverdraftNoteModel(
                    id: 'OVD-${DateTime.now().millisecondsSinceEpoch}',
                    poolType: poolType,
                    sessionsCount: sessions,
                    date: Timestamp.fromDate(noteDate),
                    notes: noteController.text.trim().isEmpty ? 'استهلاك بعد نفاد الكارت' : noteController.text.trim(),
                  );

                  LocalStore.instance.addPoolOverdraftNote(note);
                  Navigator.pop(ctx);
                  AppDialogs.showSuccessSnackBar(
                    context,
                    'تم حفظ $sessions حصة مستهلكة في ملاحظات مسبح $poolType بنجاح!',
                  );
                  setState(() {});
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // --- تأكيد خصم كل الحصص المعلقة لمسبح من الكارت النشط ---
  void _confirmDeductAllPending(String poolType, WaterCardModel card, int pendingSessions) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.sync_alt, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text('تأكيد خصم الحصص المعلقة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'هل تريد خصم إجمالي $pendingSessions حصة مستهلكة سابقة من كارت «${card.cardName}» وحذفها من الملاحظات المعلقة؟',
          style: GoogleFonts.cairo(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              LocalStore.instance.deductAllPendingOverdraftForPool(poolType: poolType, cardId: card.id);
              Navigator.pop(ctx);
              AppDialogs.showSuccessSnackBar(
                context,
                'تم خصم $pendingSessions حصة بنجاح من كارت ${card.cardName} وحذفها من الملاحظات!',
              );
              setState(() {});
            },
            child: const Text('تأكيد الخصم والحذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isOwner = currentUser?.role.isOwner ?? false;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    final content = StreamBuilder<List<WaterCardModel>>(
      stream: LocalStore.instance.waterCardsStream,
      initialData: LocalStore.instance.getWaterCards(),
      builder: (context, _) {
        final semiOlympicCard = LocalStore.instance.getActiveCardForPool(AppConstants.poolSemiOlympic);
        final recreationalCard = LocalStore.instance.getActiveCardForPool(AppConstants.poolRecreational);

        return StreamBuilder<List<PoolOverdraftNoteModel>>(
          stream: LocalStore.instance.poolOverdraftNotesStream,
          initialData: LocalStore.instance.getPoolOverdraftNotes(pendingOnly: false),
          builder: (context, __) {
            final semiOlympicNotes = LocalStore.instance.getPoolOverdraftNotes(
              poolType: AppConstants.poolSemiOlympic,
              pendingOnly: true,
            );
            final recreationalNotes = LocalStore.instance.getPoolOverdraftNotes(
              poolType: AppConstants.poolRecreational,
              pendingOnly: true,
            );

            final semiPendingCount = LocalStore.instance.getPendingOverdraftSessionsForPool(AppConstants.poolSemiOlympic);
            final recPendingCount = LocalStore.instance.getPendingOverdraftSessionsForPool(AppConstants.poolRecreational);

            return Container(
              color: AppTheme.backgroundLight,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Banner with Main Add Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue,
                          AppTheme.primaryBlue.withOpacity(0.85),
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.water, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'كروت المياة والاستهلاك',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'متابعة استهلاك كارت المسبح وحصص اللاعبين والملاحظات المعلقة.',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // أزرار التحكم الرئيسية
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryBlue,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _showNewCardDialog(),
                                icon: const Icon(Icons.add_card, size: 18, color: AppTheme.primaryBlue),
                                label: Text(
                                  'إصدار كارت جديد (+)',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Colors.white70),
                                  ),
                                ),
                                onPressed: () => _showCardsArchiveDialog(),
                                icon: const Icon(Icons.folder_open, size: 18, color: Colors.white),
                                label: Text(
                                  '📂 أرشيف الكروت',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==============================================================
                  // كارت مسبح الأكاديمية (نصف أولمبي)
                  // ==============================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('🏊 ', style: TextStyle(fontSize: 18)),
                          Text(
                            'كارت مسبح الأكاديمية (نصف أولمبي)',
                            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showNewCardDialog(initialPoolType: AppConstants.poolSemiOlympic),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text('كارت جديد', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (semiOlympicCard != null)
                    _buildPoolCardView(semiOlympicCard, isOwner: isOwner)
                  else
                    _buildEmptyPoolCard(AppConstants.poolSemiOlympic),

                  const SizedBox(height: 10),
                  // قسم الملاحظات والحصص المعلقة لمسبح الأكاديمية
                  _buildPoolOverdraftSection(
                    poolType: AppConstants.poolSemiOlympic,
                    poolTitle: 'مسبح الأكاديمية',
                    notes: semiOlympicNotes,
                    pendingCount: semiPendingCount,
                    activeCard: semiOlympicCard,
                    accentColor: AppTheme.primaryBlue,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  if (canPop) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'كروت المياة والاستهلاك',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  return content;
}

  // --- كارت المسبح النشط ---
  Widget _buildPoolCardView(WaterCardModel card, {required bool isOwner}) {
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
        side: BorderSide(color: badgeColor.withOpacity(0.4), width: 1.5),
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
                    Text(
                      card.cardName,
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                    Text(
                      'سعر الكارت: ${AppFormatters.formatCurrency(card.cardPrice)} (مُرحّل للمصروفات)',
                      style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // صناديق الأرقام
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

            // شريط التقدم
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

            // التحكم في الاستهلاك (بالأرقام مباشرة + أزرار الخطوة)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تسجيل الاستهلاك اليومي / بعد التمرينة:',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    // زر الخطوة (+ و -) مع رقم قابل للنقر
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle,
                            color: isOwner ? AppTheme.errorRed : Colors.grey.shade400,
                            size: 26,
                          ),
                          tooltip: isOwner
                              ? 'خصم حصة واحدة (-1)'
                              : 'عفواً، مسموح للمالك فقط تقليل الحصص المستهلكة',
                          onPressed: () async {
                            if (!isOwner) {
                              AppDialogs.showWarningSnackBar(
                                context,
                                'عفواً، لا يمكن تقليل الحصص المستهلكة إلا بواسطة المالك',
                              );
                              return;
                            }
                            if (card.usedSessions > 0) {
                              LocalStore.instance.updateWaterCardSessions(card.id, card.usedSessions - 1);
                              await LocalStore.instance.saveAllExplicitly();
                              setState(() {});
                            }
                          },
                        ),
                        InkWell(
                          onTap: () => _showRecordSessionsDialog(card, isOwner: isOwner),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${card.usedSessions}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit, size: 14, color: AppTheme.textMuted),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppTheme.accentTeal, size: 26),
                          tooltip: 'إضافة حصة واحدة (+1)',
                          onPressed: card.remainingSessions > 0
                              ? () async {
                                  LocalStore.instance.updateWaterCardSessions(card.id, card.usedSessions + 1);
                                  await LocalStore.instance.saveAllExplicitly();
                                  setState(() {});
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // زر تسجيل الحصص بالأرقام مباشرة (الطلب الرئيسي)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentTeal.withOpacity(0.12),
                    foregroundColor: AppTheme.accentTeal,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppTheme.accentTeal, width: 1.2),
                    ),
                  ),
                  onPressed: () => _showRecordSessionsDialog(card, isOwner: isOwner),
                  icon: const Icon(Icons.edit_note, size: 20),
                  label: Text(
                    'كتابة عدد الحصص المستهلكة بالأرقام (تسجيل سريع)',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 12),

                if (card.remainingSessions <= 0) ...[
                  // بطاقة تنبيه بأن الكارت مكتمل تماماً وجاهز للترحيل والاختفاء
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.successGreen, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تم استهلاك رصيد هذا الكارت بالكامل (${card.totalSessions} حصة)!',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.successGreen),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'اضغط على زر الحفظ والإغلاق أدناه؛ ليتم تثبيت الكارت في الماليات ونقله للأرشيف ويختفي من الشاشة ليصبح المسبح جاهزاً لكارت جديد.',
                          style: GoogleFonts.cairo(fontSize: 11, color: Colors.blueGrey.shade800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _confirmArchiveCard(card),
                      icon: const Icon(Icons.archive_rounded, size: 20),
                      label: Text(
                        'حفظ وإغلاق الكارت وترحيله للماليات والأرشيف 💾',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ] else ...[
                  // زر الحفظ الصريح وتثبيت الاستهلاك في الذاكرة الدائمة
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        await LocalStore.instance.saveAllExplicitly();
                        if (context.mounted) {
                          AppDialogs.showSuccessSnackBar(
                            context,
                            '💾 تم حفظ وتثبيت استهلاك ورصيد كارت «${card.cardName}» بنجاح في الذاكرة الدائمة! (المتبقي: ${card.remainingSessions} حصة)',
                          );
                        }
                      },
                      icon: const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        'حفظ وتثبيت استهلاك الكارت الآن 💾',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.warningOrange,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    onPressed: () => _confirmArchiveCard(card),
                    icon: const Icon(Icons.archive_outlined, size: 16),
                    label: Text(
                      'إغلاق هذا الكارت وترحيله للأرشيف والماليات مبكراً',
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- قسم الملاحظات والحصص المستهلكة بدون كارت (بالآجل) ---
  Widget _buildPoolOverdraftSection({
    required String poolType,
    required String poolTitle,
    required List<PoolOverdraftNoteModel> notes,
    required int pendingCount,
    required WaterCardModel? activeCard,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pendingCount > 0 ? AppTheme.warningOrange.withOpacity(0.6) : Colors.blueGrey.shade100,
          width: pendingCount > 0 ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // رأس قسم الملاحظات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.speaker_notes, size: 18, color: pendingCount > 0 ? AppTheme.warningOrange : AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'ملاحظات الحصص بدون كارت (بالآجل)',
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // زر إضافة ملاحظة جديدة
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  foregroundColor: accentColor,
                ),
                onPressed: () => _showAddOverdraftNoteDialog(poolType),
                icon: const Icon(Icons.add_comment, size: 16),
                label: Text('+ إضافة ملاحظة', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          // شريط التنبيه عند وجود عجز
          if (pendingCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warningOrange.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppTheme.warningOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يوجد $pendingCount حصة مستهلكة سابقة مسجلة في الملاحظات على هذا المسبح.',
                      style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                    ),
                  ),
                  if (activeCard != null && activeCard.remainingSessions > 0)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _confirmDeductAllPending(poolType, activeCard, pendingCount),
                      child: Text('خصم الكل من الكارت', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ],

          // قائمة الملاحظات المسجلة
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const Divider(height: 8),
              itemBuilder: (context, idx) {
                final note = notes[idx];
                final dateStr = AppFormatters.formatTimestamp(note.date);

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${note.sessionsCount} حصة',
                        style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.errorRed),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.notes,
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            dateStr,
                            style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    // زر الخصم الفردي من الكارت
                    if (activeCard != null && activeCard.remainingSessions > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_circle_down, color: AppTheme.primaryBlue, size: 20),
                        tooltip: 'خصم هذه الملاحظة (${note.sessionsCount} حصة) من الكارت الحالي',
                        onPressed: () {
                          LocalStore.instance.deductOverdraftNoteFromCard(noteId: note.id, cardId: activeCard.id);
                          AppDialogs.showSuccessSnackBar(
                            context,
                            'تم خصم ${note.sessionsCount} حصة من كارت ${activeCard.cardName} وحذفها من الملاحظات!',
                          );
                          setState(() {});
                        },
                      ),
                    // زر حذف الملاحظة
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
                      tooltip: 'حذف الملاحظة',
                      onPressed: () {
                        LocalStore.instance.deletePoolOverdraftNote(note.id);
                        setState(() {});
                      },
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'لا توجد حصص معلقة أو ملاحظات مسجلة بالآجل لهذا المسبح.',
              style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyPoolCard(String poolName) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Text('لا يوجد كارت نشط حالياً لمسبح $poolName', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showNewCardDialog(initialPoolType: poolName),
                icon: const Icon(Icons.add_card, size: 18),
                label: Text('تفعيل وإصدار كارت لـ $poolName', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
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

  // --- نافذة أرشيف وسجل كروت المياة السابقة ---
  void _showCardsArchiveDialog() {
    String selectedFilter = 'all'; // 'all', semi, rec, 'depleted', 'active'
    DateTime currentArchiveMonth = DateTime.now();
    bool filterByMonth = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentUser = ref.watch(currentUserProvider).value;
          final isOwner = currentUser?.role.isOwner ?? false;
          final allCards = LocalStore.instance.getWaterCards();
          final selectedMonthYear =
              '${currentArchiveMonth.month.toString().padLeft(2, '0')}-${currentArchiveMonth.year}';

          final monthFilteredCards = allCards.where((card) {
            if (!filterByMonth) return true;
            final cardDate = card.cardDate.toDate();
            final cardMonthYear =
                '${cardDate.month.toString().padLeft(2, '0')}-${cardDate.year}';
            return card.monthlyClosingRef == selectedMonthYear ||
                cardMonthYear == selectedMonthYear;
          }).toList();

          final filteredCards = monthFilteredCards.where((card) {
            if (selectedFilter == 'all') return true;
            if (selectedFilter == AppConstants.poolSemiOlympic) return card.poolType == AppConstants.poolSemiOlympic;
            if (selectedFilter == AppConstants.poolRecreational) return card.poolType == AppConstants.poolRecreational;
            if (selectedFilter == 'depleted') return card.isDepleted;
            if (selectedFilter == 'active') return !card.isDepleted;
            return true;
          }).toList();

          // Statistics for the filtered month view
          final totalCost = monthFilteredCards.fold<double>(0.0, (acc, c) => acc + c.cardPrice);
          final totalSessionsSum = monthFilteredCards.fold<int>(0, (acc, c) => acc + c.totalSessions);
          final usedSessionsSum = monthFilteredCards.fold<int>(0, (acc, c) => acc + c.usedSessions);
          final remainingSessionsSum = totalSessionsSum - usedSessionsSum;

          void changeArchiveMonth(int delta) {
            setModalState(() {
              currentArchiveMonth = DateTime(currentArchiveMonth.year, currentArchiveMonth.month + delta, 1);
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // مقبض السحب
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.archive_outlined, color: AppTheme.primaryBlue, size: 24),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أرشيف وسجل كروت المياة السابقة',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'سجل تاريخي كامل لجميع الكروت الصادرة والمنتهية والنشطة',
                              style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // شريط تصفح الأرشيف بالشهور
                Container(
                  color: AppTheme.primaryBlue.withOpacity(0.04),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: AppTheme.primaryBlue, size: 24),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => changeArchiveMonth(-1),
                            tooltip: 'الشهر السابق',
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: currentArchiveMonth,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                                helpText: 'اختر شهر الأرشيف',
                              );
                              if (picked != null) {
                                setModalState(() => currentArchiveMonth = DateTime(picked.year, picked.month, 1));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, size: 16, color: AppTheme.primaryBlue),
                                  const SizedBox(width: 6),
                                  Text(
                                    filterByMonth ? 'كروت شهر: $selectedMonthYear' : 'عرض أرشيف كل الشهور',
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: AppTheme.primaryBlue, size: 24),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => changeArchiveMonth(1),
                            tooltip: 'الشهر التالي',
                          ),
                        ],
                      ),
                      FilterChip(
                        label: Text(filterByMonth ? 'الشهر المحدد' : 'كل الشهور', style: GoogleFonts.cairo(fontSize: 11)),
                        selected: !filterByMonth,
                        selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                        onSelected: (val) => setModalState(() => filterByMonth = !val),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // ملخص إحصائيات الأرشيف
                Container(
                  color: AppTheme.backgroundLight,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _buildArchiveStat('إجمالي الكروت', '${monthFilteredCards.length}', AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      _buildArchiveStat('إجمالي المصروفات', '${totalCost.toStringAsFixed(0)} ج.م', AppTheme.accentTeal),
                      const SizedBox(width: 8),
                      _buildArchiveStat('المستهلك', '$usedSessionsSum حصة', AppTheme.warningOrange),
                      const SizedBox(width: 8),
                      _buildArchiveStat('المتبقي', '$remainingSessionsSum حصة', AppTheme.successGreen),
                    ],
                  ),
                ),

                // فلاتر التصفية
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterChip('الكل (${monthFilteredCards.length})', 'all', selectedFilter, (val) => setModalState(() => selectedFilter = val)),
                      _buildFilterChip('🏊 نصف أولمبي', AppConstants.poolSemiOlympic, selectedFilter, (val) => setModalState(() => selectedFilter = val)),
                      _buildFilterChip('🏖️ ترفيهي', AppConstants.poolRecreational, selectedFilter, (val) => setModalState(() => selectedFilter = val)),
                      _buildFilterChip('🔴 منتهية', 'depleted', selectedFilter, (val) => setModalState(() => selectedFilter = val)),
                      _buildFilterChip('🟢 نشطة', 'active', selectedFilter, (val) => setModalState(() => selectedFilter = val)),
                    ],
                  ),
                ),

                // قائمة الكروت
                Expanded(
                  child: filteredCards.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد كروت تطابق هذا الفلتر',
                                style: GoogleFonts.cairo(fontSize: 14, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredCards.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final card = filteredCards[index];
                            final isSemi = card.poolType == AppConstants.poolSemiOlympic;
                            final ratio = card.totalSessions > 0
                                ? (card.usedSessions / card.totalSessions).clamp(0.0, 1.0)
                                : 0.0;
                            final dateStr = AppFormatters.formatTimestamp(card.cardDate);

                            Color statusColor = card.isArchived
                                ? AppTheme.primaryBlue
                                : (card.isDepleted ? AppTheme.errorRed : (card.isLow ? AppTheme.warningOrange : AppTheme.successGreen));
                            String statusText = card.isArchived
                                ? 'مكتمل ومحفوظ بالماليات والأرشيف ✔️'
                                : (card.isDepleted ? 'منتهي ومستنفذ' : (card.isLow ? 'رصيد قليل' : 'نشط'));

                            return Card(
                              elevation: 1.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: statusColor.withOpacity(0.3),
                                  width: 1.2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(isSemi ? '🏊 ' : '🏖️ ', style: const TextStyle(fontSize: 18)),
                                            Text(
                                              card.cardName,
                                              style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppTheme.primaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: statusColor),
                                              ),
                                              child: Text(
                                                statusText,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ),
                                            if (isOwner) ...[
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: 'حذف الكارت من الأرشيف',
                                                onPressed: () => _confirmDeleteWaterCard(card, () => setModalState(() {})),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 13, color: AppTheme.textMuted),
                                        const SizedBox(width: 4),
                                        Text('تاريخ الإصدار: $dateStr', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted)),
                                        const Spacer(),
                                        Text(
                                          'السعر: ${AppFormatters.formatCurrency(card.cardPrice)}',
                                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // شريط الاستهلاك
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: ratio,
                                        minHeight: 6,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'إجمالي الحصص: ${card.totalSessions}',
                                          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'المستهلك: ${card.usedSessions}',
                                          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.warningOrange),
                                        ),
                                        Text(
                                          'المتبقي: ${card.remainingSessions}',
                                          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                        ),
                                      ],
                                    ),
                                    if (card.monthlyClosingRef != null && card.monthlyClosingRef!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'مرجع التقفيل الشهري: ${card.monthlyClosingRef}',
                                          style: GoogleFonts.cairo(fontSize: 10, color: Colors.blueGrey.shade700),
                                        ),
                                      ),
                                    ],
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
      ),
    );
  }

  Widget _buildArchiveStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String currentSelected, Function(String) onSelect) {
    final isSelected = currentSelected == value;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label, style: GoogleFonts.cairo(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: AppTheme.primaryBlue.withOpacity(0.18),
        onSelected: (_) => onSelect(value),
      ),
    );
  }

  Future<void> _confirmDeleteWaterCard(WaterCardModel card, VoidCallback onDeleted) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: AppTheme.errorRed, size: 28),
            const SizedBox(width: 8),
            Text('تأكيد حذف الكارت نهائياً', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل تريد بالتأكيد حذف «${card.cardName}» ومصروفه نهائياً؟',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('سعر الكارت ومصروفه:', style: GoogleFonts.cairo(fontSize: 12)),
                      Text('${card.cardPrice} ج.م', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.errorRed)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('إجمالي الحصص:', style: GoogleFonts.cairo(fontSize: 12)),
                      Text('${card.totalSessions} حصة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '⚠️ سيتم مسح الكارت نهائياً من الأرشيف ومن قاعدة البيانات السحابية (Firebase) وخصم قيمته من مصروفات الشهر تلقائياً.',
              style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: Text('تأكيد الحذف النهائي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await LocalStore.instance.deleteWaterCard(card.id);
      onDeleted();
      if (mounted) {
        AppDialogs.showSuccessSnackBar(context, 'تم حذف كارت «${card.cardName}» ومصروفه نهائياً');
      }
    }
  }
}
