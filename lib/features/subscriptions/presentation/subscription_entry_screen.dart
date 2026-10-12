import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
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

  final _stampFeeController = TextEditingController(text: '50.0');
  final _amountRequiredController = TextEditingController(text: '800.0');
  final _amountPaidController = TextEditingController(text: '850.0');

  String _subscriptionType = 'شهري (8 حصص)';
  String _paymentMethod = AppConstants.paymentCash;
  String _bookingStatus = AppConstants.statusActive;
  int _sessionsCount = 8;
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
    super.dispose();
  }

  // Exact agreed formula: (المقرر + ختم الكارت) - المدفوع
  double get _totalDue {
    final req = double.tryParse(_amountRequiredController.text) ?? 0.0;
    final stamp = double.tryParse(_stampFeeController.text) ?? 0.0;
    return req + stamp;
  }

  double get _amountRemaining {
    final paid = double.tryParse(_amountPaidController.text) ?? 0.0;
    final rem = _totalDue - paid;
    return rem > 0 ? rem : 0.0;
  }

  String get _paymentStatus => _amountRemaining <= 0 ? 'خالص (مدفوع بالكامل)' : 'متبقي عليه: $_amountRemaining ج.م';

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

  void _showWhatsAppConfirmationSheet(SubscriptionModel sub) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final message =
            'أهلاً بحضرتك في أكاديمية عالم السباحة (فرع المشاة) 🏊‍♂️\n'
            'تم تسجيل اشتراك السباح (${sub.playerName}) بنجاح!\n'
            'المجموعة: ${sub.groupCode} - ${sub.coachName}\n'
            'المواعيد: ${sub.trainingDays.join("، ")} الساعة ${sub.sessionTime}\n'
            'تاريخ أول تمرينة (نزول المياة): ${AppFormatters.formatTimestamp(sub.startDate)}\n'
            'المبلغ المدفوع: ${AppFormatters.formatCurrency(sub.amountPaid)}\n'
            'المتبقي: ${AppFormatters.formatCurrency(sub.amountRemaining)}\n'
            'نتمنى للسباح وقتاً ممتعاً وتدريباً موفقاً!';

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat, color: Colors.green, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'رسالة تأكيد الحجز لولي الأمر',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const Divider(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  message,
                  style: GoogleFonts.cairo(fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    AppDialogs.showSuccessSnackBar(context, 'تم تجهيز الرسالة لإرسالها عبر الواتساب!');
                  },
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: Text('إرسال عبر واتساب (WhatsApp)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
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
      AppDialogs.showErrorSnackBar(context, 'يرجى اختيار اللاعب أولاً');
      return;
    }
    if (_selectedGroup == null) {
      AppDialogs.showErrorSnackBar(context, 'يرجى اختيار المجموعة أولاً');
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
      stampCardFee: double.tryParse(_stampFeeController.text) ?? 0.0,
      amountRequired: double.tryParse(_amountRequiredController.text) ?? 0.0,
      amountPaid: double.tryParse(_amountPaidController.text) ?? 0.0,
      paymentMethod: _paymentMethod,
      paymentDate: Timestamp.fromDate(_paymentDate),
      subscriptionType: _subscriptionType,
      sessionsCount: _sessionsCount,
      attendedSessions: 0,
      excusedSessions: 0,
      startDate: Timestamp.fromDate(_startDate),
      endDate: Timestamp.fromDate(endDate),
      bookingStatus: _bookingStatus,
      createdBy: staffUid,
    );

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

              // 1. Player Selection
              Text(
                '1. بيانات السباح *',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 8),
              playersAsync.when(
                data: (players) {
                  return DropdownButtonFormField<PlayerModel>(
                    value: _selectedPlayer,
                    decoration: const InputDecoration(
                      hintText: 'اختر اللاعب من الدليل...',
                      prefixIcon: Icon(Icons.person_search, color: AppTheme.primaryBlue),
                    ),
                    items: players.map((p) {
                      return DropdownMenuItem<PlayerModel>(
                        value: p,
                        child: Text(
                          '${p.playerCode} - ${p.playerName} (${p.customerType})',
                          style: GoogleFonts.cairo(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedPlayer = val);
                    },
                    validator: (val) => val == null ? 'يرجى اختيار اللاعب' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('خطأ في تحميل اللاعبين'),
              ),

              const SizedBox(height: 20),

              // 2. Group Selection
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

              // Auto-populated and Locked Details
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

              // 3. Package & Financials
              Text(
                '3. تفاصيل الباقة والماليات وطريقة الدفع *',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _subscriptionType,
                      decoration: const InputDecoration(labelText: 'نوع الاشتراك'),
                      items: AppConstants.subscriptionTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type, style: GoogleFonts.cairo(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _subscriptionType = val;
                            if (val.contains('4 حصص')) _sessionsCount = 4;
                            else if (val.contains('8 حصص')) _sessionsCount = 8;
                            else if (val.contains('12 حصة')) _sessionsCount = 12;
                            else if (val.contains('24 حصة')) _sessionsCount = 24;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: '$_sessionsCount',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'عدد الحصص'),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null) _sessionsCount = parsed;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Amount Required, Stamp Fee, and Paid
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountRequiredController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'المبلغ المقرر (ج.م) *'),
                      onChanged: (_) => setState(() {}),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stampFeeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سعر ختم الكارت (ج.م) *'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _amountPaidController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'المبلغ المدفوع (ج.م) *'),
                      onChanged: (_) => setState(() {}),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
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
                        child: Text(AppFormatters.formatDate(_startDate), style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
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
                  color: _amountRemaining <= 0
                      ? AppTheme.successGreen.withOpacity(0.08)
                      : AppTheme.warningOrange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _amountRemaining <= 0 ? AppTheme.successGreen : AppTheme.warningOrange,
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _amountRemaining <= 0 ? AppTheme.successGreen : AppTheme.warningOrange,
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
