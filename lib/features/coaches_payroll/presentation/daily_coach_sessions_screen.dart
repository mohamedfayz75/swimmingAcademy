import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../data/local/local_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/daily_coach_session_model.dart';
import '../../owner_dashboard/models/payroll_model.dart';
import '../providers/coaches_payroll_provider.dart';

class DailyCoachSessionsScreen extends ConsumerStatefulWidget {
  final CoachModel? preSelectedCoach;

  const DailyCoachSessionsScreen({super.key, this.preSelectedCoach});

  @override
  ConsumerState<DailyCoachSessionsScreen> createState() => _DailyCoachSessionsScreenState();
}

class _DailyCoachSessionsScreenState extends ConsumerState<DailyCoachSessionsScreen> {
  CoachModel? _selectedCoach;
  DateTime _selectedDate = DateTime.now();
  int _sessionCount = 2;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _sessionCountController = TextEditingController(text: '2');
  String _filterCoachId = 'all';

  @override
  void initState() {
    super.initState();
    _selectedCoach = widget.preSelectedCoach;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _sessionCountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2035),
      locale: const Locale('ar'),
      helpText: 'اختر تاريخ اليوم التدريبي',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _increment() {
    setState(() {
      _sessionCount++;
      _sessionCountController.text = '$_sessionCount';
    });
  }

  void _decrement() {
    if (_sessionCount > 1) {
      setState(() {
        _sessionCount--;
        _sessionCountController.text = '$_sessionCount';
      });
    }
  }

  Future<void> _saveSession({bool sendWhatsApp = false}) async {
    if (_selectedCoach == null) {
      AppDialogs.showWarningSnackBar(context, 'يرجى اختيار الكابتن أولاً');
      return;
    }

    final count = int.tryParse(_sessionCountController.text.trim()) ?? _sessionCount;
    if (count <= 0) {
      AppDialogs.showErrorSnackBar(context, 'يرجى إدخال عدد حصص صحيح');
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final monthYear = '${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}';
    final user = ref.read(currentUserProvider).value;
    final staffName = user?.displayName ?? 'الإدارة';

    final session = DailyCoachSessionModel(
      id: 'DCS-${DateTime.now().millisecondsSinceEpoch}',
      coachId: _selectedCoach!.coachId,
      coachName: _selectedCoach!.coachName,
      date: Timestamp.fromDate(_selectedDate),
      sessionCount: count,
      notes: _notesController.text.trim(),
      monthYear: monthYear,
      recordedBy: staffName,
      createdAt: Timestamp.now(),
    );

    LocalStore.instance.addDailyCoachSession(session);

    if (mounted) {
      AppDialogs.showSuccessSnackBar(
        context,
        'تم تسجيل $count حصة للكابتن ${_selectedCoach!.coachName} بنجاح وترحيلها للإجمالي!',
      );
    }

    if (sendWhatsApp) {
      final phone = _selectedCoach!.phoneNumber;
      final msg = '🏊‍♂️ *أكاديمية عالم السباحة (فندق اللؤلؤة المعادي)* 🏊‍♂️\n'
          '━━━━━━━━━━━━━━━━━━━━━\n'
          'كابتن: ${_selectedCoach!.coachName}\n'
          'تم تسجيل *$count* حصة تدريبية لك اليوم بتاريخ *$dateStr*.\n'
          '${_notesController.text.trim().isNotEmpty ? "ملاحظات: ${_notesController.text.trim()}\n" : ""}'
          '━━━━━━━━━━━━━━━━━━━━━\n'
          'تم تحديث رصيدك تلقائياً في الإجمالي الشهري.\n'
          'تحياتنا وتمنياتنا لك بالتوفيق والتميز دائماً! 🥇';

      await WhatsAppHelper.openWhatsApp(phone: phone, message: msg);
    }

    setState(() {
      _notesController.clear();
      _sessionCount = 2;
      _sessionCountController.text = '2';
    });
  }

  void _confirmDeleteSession(DailyCoachSessionModel session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
            const SizedBox(width: 8),
            Text('تأكيد حذف الحصة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'هل تريد حذف تسجيل (${session.sessionCount} حصة) للكابتن «${session.coachName}» بتاريخ ${DateFormat('yyyy-MM-dd').format(session.date.toDate())}؟\nسيتم تعديل الإجمالي والمسير تلقائياً.',
          style: GoogleFonts.cairo(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () {
              LocalStore.instance.deleteDailyCoachSession(session.id);
              Navigator.pop(ctx);
              AppDialogs.showSuccessSnackBar(context, 'تم حذف الحصة وتحديث الإجمالي بنجاح');
            },
            child: const Text('حذف نهائي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coachesAsync = ref.watch(coachesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('تسجيل حصص الكباتن اليومية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Entry Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.timer, color: AppTheme.primaryBlue, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تسجيل نزول الحصص اليومي',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryBlue),
                              ),
                              Text(
                                'يتم ترحيل الحصص فوراً إلى إجمالي الشهر تلقائياً',
                                style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Coach Dropdown
                    coachesAsync.when(
                      data: (coaches) {
                        if (coaches.isEmpty) {
                          return const Text('لا يوجد كباتن مسجلين');
                        }
                        if (_selectedCoach == null && coaches.isNotEmpty) {
                          _selectedCoach = coaches.first;
                        }
                        return DropdownButtonFormField<CoachModel>(
                          value: _selectedCoach,
                          decoration: const InputDecoration(
                            labelText: 'اختر الكابتن *',
                            prefixIcon: Icon(Icons.sports, color: AppTheme.primaryBlue),
                          ),
                          items: coaches.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c.coachName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCoach = val);
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('خطأ: $err'),
                    ),

                    const SizedBox(height: 14),

                    // Date Picker Input
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'تاريخ اليوم التدريبي *',
                          prefixIcon: Icon(Icons.calendar_month, color: AppTheme.primaryBlue),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd').format(_selectedDate),
                              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Session Counter (+ / -)
                    Row(
                      children: [
                        Text('عدد الحصص:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 16),
                        IconButton.filledTonal(
                          onPressed: _decrement,
                          icon: const Icon(Icons.remove),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _sessionCountController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: (v) {
                              final parsed = int.tryParse(v) ?? 1;
                              _sessionCount = parsed;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _increment,
                          icon: const Icon(Icons.add),
                        ),
                        const SizedBox(width: 12),
                        Text('حصة', style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textMuted)),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري - مثل: أسماء المجموعات أو الوقت)',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons (Save & Send WhatsApp)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _saveSession(sendWhatsApp: false),
                            icon: const Icon(Icons.save),
                            label: Text('حفظ في الإجمالي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _saveSession(sendWhatsApp: true),
                            icon: const Icon(Icons.chat),
                            label: Text('حفظ وإرسال واتساب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Archive & History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: AppTheme.primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      'أرشيف وسجل الحصص المسجلة',
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Coach Filter
                coachesAsync.when(
                  data: (coaches) {
                    return DropdownButton<String>(
                      value: _filterCoachId,
                      underline: const SizedBox.shrink(),
                      style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('جميع الكباتن')),
                        ...coaches.map((c) => DropdownMenuItem(value: c.coachId, child: Text(c.coachName))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _filterCoachId = val);
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // History Stream List
            StreamBuilder<List<DailyCoachSessionModel>>(
              stream: LocalStore.instance.dailyCoachSessionsStream,
              builder: (context, snapshot) {
                final allSessions = snapshot.data ?? LocalStore.instance.getDailyCoachSessions();
                final sessions = allSessions.where((s) {
                  if (_filterCoachId != 'all' && s.coachId != _filterCoachId) return false;
                  return true;
                }).toList();

                if (sessions.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Text(
                      'لا توجد حصص مسجلة بعد',
                      style: GoogleFonts.cairo(color: AppTheme.textMuted),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final s = sessions[idx];
                    final dateStr = DateFormat('yyyy-MM-dd').format(s.date.toDate());

                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
                          foregroundColor: AppTheme.primaryBlue,
                          child: Text('${s.sessionCount}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s.coachName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(dateStr, style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('تم تسجيل ${s.sessionCount} حصة بواسطة: ${s.recordedBy}', style: GoogleFonts.cairo(fontSize: 11)),
                            if (s.notes.isNotEmpty)
                              Text('ملاحظة: ${s.notes}', style: GoogleFonts.cairo(fontSize: 11, color: Colors.blueGrey)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // WhatsApp Send
                            IconButton(
                              icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                              tooltip: 'إرسال واتساب للكابتن',
                              onPressed: () {
                                final coaches = LocalStore.instance.getCoaches();
                                final coach = coaches.cast<CoachModel?>().firstWhere((c) => c?.coachId == s.coachId, orElse: () => null);
                                final phone = coach?.phoneNumber ?? '';
                                final msg = '🏊‍♂️ *أكاديمية عالم السباحة (فندق اللؤلؤة المعادي)* 🏊‍♂️\n'
                                    '━━━━━━━━━━━━━━━━━━━━━\n'
                                    'كابتن: ${s.coachName}\n'
                                    'تم تسجيل *${s.sessionCount}* حصص تدريبية لك بتاريخ *$dateStr*.\n'
                                    '${s.notes.isNotEmpty ? "ملاحظات: ${s.notes}\n" : ""}'
                                    '━━━━━━━━━━━━━━━━━━━━━\n'
                                    'تحياتنا وتمنياتنا لك بالتوفيق والتميز دائماً! 🥇';
                                WhatsAppHelper.openWhatsApp(phone: phone, message: msg);
                              },
                            ),
                            // Delete
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
                              tooltip: 'حذف',
                              onPressed: () => _confirmDeleteSession(s),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
