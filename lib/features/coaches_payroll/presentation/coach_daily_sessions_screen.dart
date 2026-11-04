import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../owner_dashboard/models/payroll_model.dart';
import '../../owner_dashboard/providers/dashboard_provider.dart';
import '../models/coach_daily_session_model.dart';
import '../providers/coaches_payroll_provider.dart';

class CoachDailySessionsScreen extends ConsumerStatefulWidget {
  const CoachDailySessionsScreen({super.key});

  @override
  ConsumerState<CoachDailySessionsScreen> createState() => _CoachDailySessionsScreenState();
}

class _CoachDailySessionsScreenState extends ConsumerState<CoachDailySessionsScreen> {
  CoachModel? _selectedCoach;
  DateTime _selectedDate = DateTime.now();
  int _sessionsCount = 1;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _countController = TextEditingController(text: '1');
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2035),
      locale: const Locale('ar'),
      helpText: 'اختر تاريخ نزول الحصص',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _updateSessionsCount(int delta) {
    setState(() {
      _sessionsCount = (_sessionsCount + delta).clamp(1, 20);
      _countController.text = '$_sessionsCount';
    });
  }

  Future<void> _saveDailySession(String currentUser) async {
    if (_selectedCoach == null) {
      AppDialogs.showWarningSnackBar(context, 'يرجى اختيار الكابتن أولاً');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final session = CoachDailySessionModel(
        id: 'CDS-${DateTime.now().millisecondsSinceEpoch}',
        coachId: _selectedCoach!.coachId,
        coachName: _selectedCoach!.coachName,
        date: _selectedDate,
        sessionsCount: _sessionsCount,
        notes: _notesController.text.trim(),
        loggedBy: currentUser.isNotEmpty ? currentUser : 'الإدارة',
        loggedAt: DateTime.now(),
      );

      await ref.read(coachesPayrollActionProvider.notifier).addDailySession(session);

      if (mounted) {
        AppDialogs.showSuccessSnackBar(context, 'تم تسجيل حضور وحصص الكابتن بنجاح');
        // Reset inputs
        _notesController.clear();
        setState(() {
          _sessionsCount = 1;
          _countController.text = '1';
        });

        // Prompt or offer WhatsApp confirmation
        if (_selectedCoach!.phoneNumber.trim().isNotEmpty) {
          _promptWhatsAppConfirmation(_selectedCoach!, session);
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorSnackBar(context, 'حدث خطأ أثناء التسجيل: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _promptWhatsAppConfirmation(CoachModel coach, CoachDailySessionModel session) async {
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.mark_chat_read, color: AppTheme.successGreen),
            const SizedBox(width: 8),
            Text('إشعار الواتساب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'تم تسجيل ${_sessionsCount} حصة لكابتن ${coach.coachName}.\nهل ترغب في إرسال إشعار تأكيد فوري عبر واتساب؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('لاحقاً', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send, color: Colors.white),
            label: Text('إرسال الآن', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (send == true) {
      _sendWhatsAppMessage(coach.phoneNumber, coach.coachName, session.dateFormatted, session.sessionsCount, session.notes);
    }
  }

  Future<void> _sendWhatsAppMessage(String phone, String coachName, String date, int count, String notes) async {
    final msg = WhatsAppHelper.buildCoachDailySessionMessage(
      coachName: coachName,
      date: date,
      sessionsCount: count,
      notes: notes,
    );
    final launched = await WhatsAppHelper.openWhatsApp(phone: phone, message: msg);
    if (!launched && mounted) {
      AppDialogs.showWarningSnackBar(context, 'تعذر فتح تطبيق واتساب. تأكد من صحة رقم الهاتف.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final coachesAsync = ref.watch(coachesStreamProvider);
    final sessionsAsync = ref.watch(coachDailySessionsStreamProvider(null));
    final currentUser = ref.watch(currentUserProvider).value?.username ?? 'الإدارة';

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الحصص اليومية للكباتن'),
      ),
      body: coachesAsync.when(
        data: (coaches) {
          if (coaches.isEmpty) {
            return const Center(child: Text('لا يوجد كباتن مسجلين بالنظام'));
          }

          // Default selection if null
          _selectedCoach ??= coaches.first;

          return Column(
            children: [
              // 1. Entry Form Card
              Card(
                margin: const EdgeInsets.all(12),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sports_score, color: AppTheme.primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            'تسجيل حصص اليوم للكابتن',
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          ),
                        ],
                      ),
                      const Divider(height: 16),

                      // Coach & Date Row
                      Row(
                        children: [
                          // Coach Dropdown
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<CoachModel>(
                              value: coaches.contains(_selectedCoach) ? _selectedCoach : coaches.first,
                              decoration: const InputDecoration(
                                labelText: 'الكابتن',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: coaches.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c.coachName,
                                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCoach = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Date Picker button
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                formattedDate,
                                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Sessions Count & Notes Row
                      Row(
                        children: [
                          // Session Count Controls
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.textMuted.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.warningOrange),
                                  onPressed: () => _updateSessionsCount(-1),
                                  tooltip: 'تقليل الحصص',
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '$_sessionsCount',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.successGreen),
                                  onPressed: () => _updateSessionsCount(1),
                                  tooltip: 'زيادة الحصص',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Notes
                          Expanded(
                            child: TextField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'ملاحظات (اختياري)',
                                hintText: 'مثلاً: فترة صباحية / تعويض',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Submit Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppTheme.primaryBlue,
                        ),
                        onPressed: _isSaving ? null : () => _saveDailySession(currentUser),
                        icon: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _isSaving ? 'جاري التسجيل...' : 'تسجيل نزول الحصص',
                          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Archive Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'سجل الحصص اليومية المسجلة',
                      style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
                      tooltip: 'تحديث',
                      onPressed: () {
                        ref.invalidate(coachDailySessionsStreamProvider(null));
                      },
                    ),
                  ],
                ),
              ),

              // 3. Sessions History List
              Expanded(
                child: sessionsAsync.when(
                  data: (sessions) {
                    if (sessions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            Text('لم يتم تسجيل أي حصص بعد', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
                          ],
                        ),
                      );
                    }

                    // Sort descending by date/createdAt
                    final sorted = List<CoachDailySessionModel>.from(sessions)
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final item = sorted[idx];
                        final coach = coaches.firstWhere(
                          (c) => c.coachId == item.coachId,
                          orElse: () => CoachModel(coachId: item.coachId, coachName: item.coachName, phoneNumber: ''),
                        );

                        return Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                // Badge of sessions count
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${item.sessionsCount}',
                                        style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                      ),
                                      Text(
                                        'حصص',
                                        style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Details Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            item.coachName,
                                            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.dateFormatted,
                                              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade700),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (item.notes.isNotEmpty)
                                        Text(
                                          item.notes,
                                          style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      Text(
                                        'المسؤول: ${item.loggedBy}',
                                        style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),

                                // Action Buttons
                                // WhatsApp button
                                IconButton(
                                  icon: const Icon(Icons.chat, color: AppTheme.successGreen),
                                  tooltip: 'إرسال تأكيد واتساب للكابتن',
                                  onPressed: () {
                                    if (coach.phoneNumber.trim().isEmpty) {
                                      AppDialogs.showWarningSnackBar(context, 'رقم هاتف الكابتن غير مسجل');
                                      return;
                                    }
                                    _sendWhatsAppMessage(coach.phoneNumber, coach.coachName, item.dateFormatted, item.sessionsCount, item.notes);
                                  },
                                ),

                                // Delete button
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'حذف التسجيل',
                                  onPressed: () async {
                                    final confirm = await AppDialogs.showConfirmDialog(
                                      context,
                                      title: 'حذف تسجيل الحصص',
                                      message: 'هل أنت متأكد من حذف تسجيل (${item.sessionsCount} حصص) لكابتن ${item.coachName} بتاريخ ${item.dateFormatted}؟',
                                      confirmText: 'نعم، حذف',
                                      isDestructive: true,
                                    );
                                    if (confirm == true) {
                                      await ref.read(coachesPayrollActionProvider.notifier).deleteDailySession(item.id);
                                      if (context.mounted) {
                                        AppDialogs.showSuccessSnackBar(context, 'تم حذف التسجيل بنجاح');
                                      }
                                    }
                                  },
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
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('خطأ: $err')),
      ),
    );
  }
}
