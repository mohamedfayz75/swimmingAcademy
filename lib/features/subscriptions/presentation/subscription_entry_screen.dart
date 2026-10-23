import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../data/local/local_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../../groups/models/group_model.dart';
import '../../groups/providers/group_provider.dart';
import '../../players/models/player_model.dart';
import '../../players/providers/player_provider.dart';
import '../models/subscription_model.dart';
import '../providers/subscription_provider.dart';

class SubscriptionEntryScreen extends ConsumerStatefulWidget {
  final PlayerModel? preSelectedPlayer;

  const SubscriptionEntryScreen({super.key, this.preSelectedPlayer});

  @override
  ConsumerState<SubscriptionEntryScreen> createState() => _SubscriptionEntryScreenState();
}

class _SubscriptionEntryScreenState extends ConsumerState<SubscriptionEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  PlayerModel? _selectedPlayer;
  GroupModel? _selectedGroup;
  GroupModel? _selectedSecondaryGroup; // For split days (e.g. Saturday in group A + Sunday in group B)
  bool _isSplitSchedule = false;

  // الخانات تبدأ فارغة تماماً ليقوم الإداري بإدخالها بناءً على طلب المستخدم
  final _stampFeeController = TextEditingController();
  final _amountRequiredController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _sessionsCountController = TextEditingController();

  String? _subscriptionType;
  String _paymentMethod = AppConstants.paymentCash;
  String _bookingStatus = AppConstants.statusActive;
  DateTime _startDate = DateTime.now(); // تاريخ نزول المياة
  DateTime _paymentDate = DateTime.now(); // تاريخ الدفع

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedPlayer != null) {
      _selectedPlayer = widget.preSelectedPlayer;
    }
  }

  @override
  void dispose() {
    _stampFeeController.dispose();
    _amountRequiredController.dispose();
    _amountPaidController.dispose();
    _sessionsCountController.dispose();
    super.dispose();
  }

  // Exact agreed formula: (المقرر + ختم الكارت) - المدفوع
  double get _totalDue {
    final req = double.tryParse(_amountRequiredController.text.trim()) ?? 0.0;
    final stamp = double.tryParse(_stampFeeController.text.trim()) ?? 0.0;
    return req + stamp;
  }

  double get _amountRemaining {
    final paid = double.tryParse(_amountPaidController.text.trim()) ?? 0.0;
    final rem = _totalDue - paid;
    return rem > 0 ? rem : 0.0;
  }

  String get _paymentStatus {
    final req = double.tryParse(_amountRequiredController.text.trim()) ?? 0.0;
    final stamp = double.tryParse(_stampFeeController.text.trim()) ?? 0.0;
    final paid = double.tryParse(_amountPaidController.text.trim()) ?? 0.0;

    if (req == 0.0 && stamp == 0.0 && paid == 0.0) {
      return 'بانتظار إدخال المبالغ';
    }
    if (_totalDue > 0 && paid >= _totalDue) {
      return 'خالص (مدفوع بالكامل)';
    }
    if (paid > 0 && paid < _totalDue) {
      return 'مدفوع جزئي (متبقي: ${AppFormatters.formatCurrency(_amountRemaining)})';
    }
    return 'غير مسدد (متبقي: ${AppFormatters.formatCurrency(_amountRemaining)})';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _paymentDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _paymentDate = picked;
        }
      });
    }
  }

  // --- نافذة البحث عن السباح بالاسم أو الكود (بدلاً من القائمة المنسدلة) ---
  void _openPlayerSearchSheet(List<PlayerModel> players) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = players.where((p) {
              if (searchQuery.trim().isEmpty) return true;
              final q = searchQuery.trim().toLowerCase();
              return p.playerName.toLowerCase().contains(q) ||
                  p.playerCode.toLowerCase().contains(q) ||
                  p.guardianPhone.contains(q);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_search, color: AppTheme.primaryBlue, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'اختيار السباح بالاسم أو الكود',
                              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Search TextField
                    TextField(
                      autofocus: true,
                      style: GoogleFonts.cairo(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم السباح أو الكود أو رقم الهاتف...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setSheetState(() => searchQuery = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setSheetState(() => searchQuery = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Results count
                    Text(
                      'النتائج المتاحة: ${filtered.length} لاعب',
                      style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),

                    // Players List
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_off, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'لم يتم العثور على أي سباح يطابق البحث',
                                    style: GoogleFonts.cairo(color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final p = filtered[idx];
                                final isSelected = _selectedPlayer?.playerCode == p.playerCode;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? AppTheme.accentTeal
                                        : AppTheme.primaryBlue.withOpacity(0.12),
                                    foregroundColor: isSelected ? Colors.white : AppTheme.primaryBlue,
                                    child: Text(
                                      p.playerName.isNotEmpty ? p.playerName.substring(0, 1) : 'س',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.playerName,
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryBlue.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                                        ),
                                        child: Text(
                                          p.playerCode,
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        'هاتف: ${p.guardianPhone.isNotEmpty ? p.guardianPhone : "غير مسجل"}',
                                        style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('•', style: TextStyle(color: Colors.grey.shade400)),
                                      const SizedBox(width: 8),
                                      Text(
                                        p.customerType,
                                        style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle, color: AppTheme.accentTeal)
                                      : const Icon(Icons.chevron_left, color: Colors.grey),
                                  onTap: () {
                                    setState(() => _selectedPlayer = p);
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showWhatsAppConfirmationSheet(SubscriptionModel sub) {
    final player = _selectedPlayer ?? LocalStore.instance.getPlayerByCode(sub.playerCode);
    final guardianPhone = player?.guardianPhone ?? '';
    final message = WhatsAppHelper.buildSubscriptionInvoiceMessage(
      sub: sub,
      isRenewal: widget.preSelectedPlayer != null,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat, color: Color(0xFF25D366), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إرسال إيصال الاشتراك لولي الأمر',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (guardianPhone.isNotEmpty)
                          Text(
                            'رقم ولي الأمر: $guardianPhone',
                            style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    style: GoogleFonts.cairo(fontSize: 13, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (guardianPhone.isEmpty) {
                    AppDialogs.showWarningSnackBar(
                      context,
                      'رقم هاتف ولي الأمر غير متوفر للاعب (${sub.playerName})',
                    );
                    return;
                  }
                  final launched = await WhatsAppHelper.openWhatsApp(
                    phone: guardianPhone,
                    message: message,
                  );
                  if (!launched && context.mounted) {
                    AppDialogs.showWarningSnackBar(
                      context,
                      'تعذر فتح الواتساب. تأكد من تثبيت التطبيق وصحة الرقم ($guardianPhone)',
                    );
                  }
                },
                icon: const Icon(Icons.send, color: Colors.white),
                label: Text(
                  'إرسال الفاتورة عبر واتساب الآن',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إغلاق بدون إرسال', style: GoogleFonts.cairo()),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPlayer == null) {
      AppDialogs.showErrorSnackBar(context, 'يرجى اختيار اللاعب بالبحث أولاً');
      return;
    }
    if (_selectedGroup == null) {
      AppDialogs.showErrorSnackBar(context, 'يرجى اختيار المجموعة أولاً');
      return;
    }
    if (_subscriptionType == null || _subscriptionType!.isEmpty) {
      AppDialogs.showErrorSnackBar(context, 'يرجى اختيار نوع الاشتراك');
      return;
    }

    final sessions = int.tryParse(_sessionsCountController.text.trim()) ?? 0;
    if (sessions <= 0) {
      AppDialogs.showErrorSnackBar(context, 'يرجى إدخال عدد الحصص بالأرقام');
      return;
    }

    final amountRequired = double.tryParse(_amountRequiredController.text.trim()) ?? 0.0;
    if (amountRequired <= 0) {
      AppDialogs.showErrorSnackBar(context, 'يرجى إدخال المبلغ المقرر');
      return;
    }

    final currentUser = ref.read(currentUserProvider).value;
    final staffUid = currentUser?.uid ?? 'staff-uid';
    final endDate = _startDate.add(const Duration(days: 30));

    final subscription = SubscriptionModel(
      id: '',
      playerCode: _selectedPlayer!.playerCode,
      playerName: _selectedPlayer!.playerName,
      branch: AppConstants.defaultBranch,
      groupCode: _selectedGroup!.groupCode,
      secondaryGroupCode: _isSplitSchedule ? _selectedSecondaryGroup?.groupCode : null,
      coachName: _selectedGroup!.coachName,
      trainingDays: _isSplitSchedule && _selectedSecondaryGroup != null
          ? [..._selectedGroup!.trainingDays, ..._selectedSecondaryGroup!.trainingDays]
          : _selectedGroup!.trainingDays,
      sessionTime: _selectedGroup!.sessionTime,
      trainingType: _selectedGroup!.trainingType,
      stampCardFee: double.tryParse(_stampFeeController.text.trim()) ?? 0.0,
      amountRequired: amountRequired,
      amountPaid: double.tryParse(_amountPaidController.text.trim()) ?? 0.0,
      paymentMethod: _paymentMethod,
      paymentDate: Timestamp.fromDate(_paymentDate),
      subscriptionType: _subscriptionType!,
      sessionsCount: sessions,
      attendedSessions: 0,
      excusedSessions: 0,
      startDate: Timestamp.fromDate(_startDate),
      endDate: Timestamp.fromDate(endDate),
      bookingStatus: _bookingStatus,
      createdBy: staffUid,
    );

    // Check if player already has an active subscription in this group
    final existingSubs = LocalStore.instance.getSubscriptions();
    final hasActiveInGroup = existingSubs.any((s) =>
        s.playerCode.trim().toUpperCase() == _selectedPlayer!.playerCode.trim().toUpperCase() &&
        s.groupCode.trim().toUpperCase() == _selectedGroup!.groupCode.trim().toUpperCase() &&
        !s.isExpired);

    if (hasActiveInGroup) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.warningOrange),
              const SizedBox(width: 8),
              Text('تجديد اشتراك ساري', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(
            'اللاعب «${_selectedPlayer!.playerName}» مقيد بالفعل ولديه اشتراك ساري في مجموعة «${_selectedGroup!.groupCode}».\n\nهل تريد تسجيل هذا كـ (تجديد اشتراك)؟\nسيتم تسجيل الرسوم والحصص دون مضاعفة مقعد اللاعب في المجموعة.',
            style: GoogleFonts.cairo(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('تأكيد التجديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (shouldProceed != true) {
        return;
      }
    }

    try {
      final saved = await ref.read(subscriptionEntryProvider.notifier).submitSubscription(subscription);
      if (!mounted) return;

      AppDialogs.showSuccessSnackBar(
        context,
        'تم تسجيل الاشتراك بنجاح للاعب ${_selectedPlayer!.playerName}',
      );

      // Offer WhatsApp confirmation message
      _showWhatsAppConfirmationSheet(saved);

      ref.invalidate(groupsStreamProvider);
      setState(() {
        _selectedGroup = null;
        _selectedSecondaryGroup = null;
        _selectedPlayer = null;
        _subscriptionType = null;
        _sessionsCountController.clear();
        _amountRequiredController.clear();
        _stampFeeController.clear();
        _amountPaidController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showErrorSnackBar(context, 'حدث خطأ أثناء الحفظ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersStreamProvider);
    final groupsAsync = ref.watch(groupsStreamProvider);
    final entryState = ref.watch(subscriptionEntryProvider);
    final isSubmitting = entryState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل وحجز اشتراك جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Branch Fixed Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.primaryBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'الفرع المعتمد: ${AppConstants.defaultBranch}',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Booking Status Switcher (Active vs Deposit / العربون)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text('حالة الحجز:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: Text('اشتراك مؤكد ونزل المياة', style: GoogleFonts.cairo(fontSize: 12)),
                        selected: _bookingStatus == AppConstants.statusActive,
                        selectedColor: AppTheme.primaryBlue,
                        labelStyle: TextStyle(color: _bookingStatus == AppConstants.statusActive ? Colors.white : AppTheme.textDark),
                        onSelected: (val) {
                          if (val) setState(() => _bookingStatus = AppConstants.statusActive);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('حجز بعربون (صيف)', style: GoogleFonts.cairo(fontSize: 12)),
                        selected: _bookingStatus == AppConstants.statusDeposit,
                        selectedColor: AppTheme.warningOrange,
                        labelStyle: TextStyle(color: _bookingStatus == AppConstants.statusDeposit ? Colors.white : AppTheme.textDark),
                        onSelected: (val) {
                          if (val) setState(() => _bookingStatus = AppConstants.statusDeposit);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==============================================================
              // 1. Player Selection (Search by Name or Code - طلب المستخدم)
              // ==============================================================
              Text(
                '1. بيانات السباح *',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 8),
              playersAsync.when(
                data: (players) {
                  if (_selectedPlayer == null) {
                    return InkWell(
                      onTap: () => _openPlayerSearchSheet(players),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueGrey.shade300, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_search, color: AppTheme.primaryBlue, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'اضغط للبحث عن السباح بالاسم أو الكود...',
                                style: GoogleFonts.cairo(color: AppTheme.textMuted, fontSize: 13),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search, size: 16, color: AppTheme.primaryBlue),
                                  const SizedBox(width: 4),
                                  Text(
                                    'بحث',
                                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.4), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.person, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedPlayer!.playerName,
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue),
                                ),
                                Text(
                                  'كود: ${_selectedPlayer!.playerCode} | فئة: ${_selectedPlayer!.customerType} | هاتف: ${_selectedPlayer!.guardianPhone.isNotEmpty ? _selectedPlayer!.guardianPhone : "غير مسجل"}',
                                  style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textDark),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryBlue,
                              side: const BorderSide(color: AppTheme.primaryBlue),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _openPlayerSearchSheet(players),
                            icon: const Icon(Icons.swap_horiz, size: 16),
                            label: Text('تغيير', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                    );
                  }
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('خطأ في تحميل اللاعبين'),
              ),

              const SizedBox(height: 20),

              // ==============================================================
              // 2. Group Selection
              // ==============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '2. المجموعة وحارة التدريب *',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryBlue),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _isSplitSchedule = !_isSplitSchedule);
                    },
                    icon: Icon(_isSplitSchedule ? Icons.check_box : Icons.check_box_outline_blank, size: 18),
                    label: Text(
                      'مواعيد مخصصة (أيام منفصلة)',
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              groupsAsync.when(
                data: (groups) {
                  return DropdownButtonFormField<GroupModel>(
                    value: _selectedGroup,
                    decoration: InputDecoration(
                      labelText: _isSplitSchedule ? 'المجموعة الأولى (اليوم الأول)' : 'اختر المجموعة المتاحة',
                      prefixIcon: const Icon(Icons.pool, color: AppTheme.primaryBlue),
                    ),
                    items: groups.map((g) {
                      final isFull = !g.isAvailable;
                      return DropdownMenuItem<GroupModel>(
                        value: isFull ? null : g,
                        enabled: !isFull,
                        child: Text(
                          '${g.groupCode} - ${g.coachName} (${g.trainingType}) [متاح ${g.availableSeats}]',
                          style: GoogleFonts.cairo(fontSize: 13, color: isFull ? Colors.grey : AppTheme.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedGroup = val);
                    },
                    validator: (val) => val == null ? 'يرجى اختيار المجموعة' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('خطأ في تحميل المجموعات'),
              ),

              // Secondary Group Selector if Split Schedule
              if (_isSplitSchedule) ...[
                const SizedBox(height: 12),
                groupsAsync.when(
                  data: (groups) {
                    return DropdownButtonFormField<GroupModel>(
                      value: _selectedSecondaryGroup,
                      decoration: const InputDecoration(
                        labelText: 'المجموعة الثانية (اليوم الثاني المخصص)',
                        prefixIcon: Icon(Icons.add_circle_outline, color: AppTheme.accentTeal),
                      ),
                      items: groups.map((g) {
                        return DropdownMenuItem<GroupModel>(
                          value: g,
                          child: Text(
                            '${g.groupCode} - ${g.coachName} (${g.trainingType}) [متاح ${g.availableSeats}]',
                            style: GoogleFonts.cairo(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedSecondaryGroup = val);
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],

              // Auto-populated Details
              if (_selectedGroup != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المدرب: ${_selectedGroup!.coachName}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('الموعد: ${_selectedGroup!.sessionTime}', style: GoogleFonts.cairo(fontSize: 13)),
                      Text('النوع: ${_selectedGroup!.groupType.split(" ").first}', style: GoogleFonts.cairo(fontSize: 13)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ==============================================================
              // 3. Subscription Details (تم تعديل الاسم إلى تفاصيل الاشتراك وتفريغ الخانات)
              // ==============================================================
              Text(
                '3. تفاصيل الاشتراك *',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _subscriptionType,
                      hint: Text('اختر نوع الاشتراك...', style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textMuted)),
                      decoration: const InputDecoration(labelText: 'نوع الاشتراك *'),
                      items: AppConstants.subscriptionTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type, style: GoogleFonts.cairo(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _subscriptionType = val;
                            // اقتراح عدد الحصص تلقائياً إذا كانت الخانة فارغة
                            if (_sessionsCountController.text.trim().isEmpty) {
                              if (val.contains('4 حصص')) _sessionsCountController.text = '4';
                              else if (val.contains('8 حصص')) _sessionsCountController.text = '8';
                              else if (val.contains('12 حصة')) _sessionsCountController.text = '12';
                              else if (val.contains('24 حصة')) _sessionsCountController.text = '24';
                            }
                          });
                        }
                      },
                      validator: (val) => val == null || val.isEmpty ? 'يرجى اختيار نوع الاشتراك' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _sessionsCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'عدد الحصص *',
                        hintText: 'مثال: 8',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'مطلوب';
                        final n = int.tryParse(val.trim());
                        if (n == null || n <= 0) return 'أدخل رقم';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Amount Required, Stamp Fee, and Paid (خانات تبدأ فارغة بناءً على طلب المستخدم)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountRequiredController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ المقرر (ج.م) *',
                        hintText: 'مثال: 800',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'مطلوب';
                        final n = double.tryParse(val.trim());
                        if (n == null || n < 0) return 'أدخل مبلغ صحيح';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stampFeeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'سعر ختم الكارت (ج.م)',
                        hintText: '0.0',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _amountPaidController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ المدفوع (ج.م) *',
                        hintText: 'مثال: 850',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'مطلوب';
                        final n = double.tryParse(val.trim());
                        if (n == null || n < 0) return 'أدخل مبلغ صحيح';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Payment Method Dropdown
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'وسيلة الدفع *',
                  prefixIcon: Icon(Icons.payment, color: AppTheme.primaryBlue),
                ),
                items: AppConstants.paymentMethods.map((m) {
                  return DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.cairo(fontSize: 14)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMethod = val);
                },
              ),

              const SizedBox(height: 14),

              // Dates: Payment Date vs Start Date (نزول المياة)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isStart: false),
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'تاريخ الدفع (التحصيل)'),
                        child: Text(AppFormatters.formatDate(_paymentDate), style: GoogleFonts.cairo(fontSize: 13)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isStart: true),
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'تاريخ بداية النزول (المياة)'),
                        child: Text(
                          AppFormatters.formatDate(_startDate),
                          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Real-Time Precise Formula Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _totalDue == 0.0 && (double.tryParse(_amountPaidController.text.trim()) ?? 0.0) == 0.0
                      ? AppTheme.primaryBlue.withOpacity(0.05)
                      : (_amountRemaining <= 0
                          ? AppTheme.successGreen.withOpacity(0.08)
                          : AppTheme.warningOrange.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _totalDue == 0.0 && (double.tryParse(_amountPaidController.text.trim()) ?? 0.0) == 0.0
                        ? Colors.blueGrey.shade200
                        : (_amountRemaining <= 0 ? AppTheme.successGreen : AppTheme.warningOrange),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('المطلوب سداده: (المقرر + ختم الكارت)', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
                        Text(AppFormatters.formatCurrency(_totalDue), style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('حالة الدفع المحسوبة:', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
                            Text(
                              _paymentStatus,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _totalDue == 0.0
                                    ? AppTheme.textMuted
                                    : (_amountRemaining <= 0 ? AppTheme.successGreen : AppTheme.warningOrange),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('المبلغ المتبقي:', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
                            Text(
                              AppFormatters.formatCurrency(_amountRemaining),
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _amountRemaining <= 0 ? AppTheme.successGreen : AppTheme.errorRed,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton.icon(
                onPressed: isSubmitting ? null : _submitForm,
                icon: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  isSubmitting ? 'جاري تأكيد وتسجيل الاشتراك...' : 'تأكيد وحفظ الاشتراك في المجموعة',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
