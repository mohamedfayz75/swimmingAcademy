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
  final String? initialPlayerCode;

  const SubscriptionEntryScreen({super.key, this.initialPlayerCode});

  @override
  ConsumerState<SubscriptionEntryScreen> createState() => _SubscriptionEntryScreenState();
}

class _SubscriptionEntryScreenState extends ConsumerState<SubscriptionEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  PlayerModel? _selectedPlayer;
  GroupModel? _selectedGroup;

  final _stampFeeController = TextEditingController(text: '50.0');
  final _amountRequiredController = TextEditingController(text: '800.0');
  final _amountPaidController = TextEditingController(text: '800.0');

  String _subscriptionType = AppConstants.subscriptionTypes.first;
  int _sessionsCount = 8;
  DateTime _startDate = DateTime.now();
  DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupRepositoryProvider).seedInitialGroupsIfEmpty();
    });
  }

  @override
  void dispose() {
    _stampFeeController.dispose();
    _amountRequiredController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  double get _amountRemaining {
    final required = double.tryParse(_amountRequiredController.text) ?? 0.0;
    final paid = double.tryParse(_amountPaidController.text) ?? 0.0;
    return (required - paid) > 0 ? (required - paid) : 0.0;
  }

  String get _paymentStatus => _amountRemaining <= 0 ? 'مدفوع بالكامل' : 'متبقي';

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
      groupCode: _selectedGroup!.groupCode,
      coachName: _selectedGroup!.coachName,
      trainingDays: _selectedGroup!.trainingDays,
      sessionTime: _selectedGroup!.sessionTime,
      trainingType: _selectedGroup!.trainingType,
      stampCardFee: double.tryParse(_stampFeeController.text) ?? 0.0,
      amountRequired: double.tryParse(_amountRequiredController.text) ?? 0.0,
      amountPaid: double.tryParse(_amountPaidController.text) ?? 0.0,
      paymentDate: Timestamp.fromDate(_paymentDate),
      subscriptionType: _subscriptionType,
      sessionsCount: _sessionsCount,
      attendedSessions: 0,
      startDate: Timestamp.fromDate(_startDate),
      endDate: Timestamp.fromDate(endDate),
      createdBy: staffUid,
    );

    try {
      await ref.read(subscriptionEntryProvider.notifier).submitSubscription(subscription);

      if (!mounted) return;

      AppDialogs.showSuccessSnackBar(
        context,
        'تم تسجيل الاشتراك بنجاح للاعب ${_selectedPlayer!.playerName} في مجموعة ${_selectedGroup!.groupCode}',
      );

      // Refresh groups list and reset
      ref.invalidate(groupsStreamProvider);
      setState(() {
        _selectedPlayer = null;
        _selectedGroup = null;
      });
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showErrorSnackBar(context, 'حدث خطأ أثناء حفظ الاشتراك: $e');
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
        title: const Text('تسجيل اشتراك جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Select Player Dropdown
              Text(
                '1. بيانات اللاعب *',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 8),
              playersAsync.when(
                data: (players) {
                  return DropdownButtonFormField<PlayerModel>(
                    value: _selectedPlayer,
                    decoration: const InputDecoration(
                      hintText: 'اختر اللاعب من القائمة...',
                      prefixIcon: Icon(Icons.person_search, color: AppTheme.primaryBlue),
                    ),
                    items: players.map((p) {
                      return DropdownMenuItem<PlayerModel>(
                        value: p,
                        child: Text(
                          '${p.playerCode} - ${p.playerName} (${p.branch})',
                          style: GoogleFonts.cairo(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedPlayer = val;
                      });
                    },
                    validator: (val) => val == null ? 'يرجى اختيار اللاعب' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => Text('خطأ في تحميل اللاعبين', style: GoogleFonts.cairo(color: AppTheme.errorRed)),
              ),

              const SizedBox(height: 20),

              // 2. Select Group Dropdown
              Text(
                '2. اختيار المجموعة والمدرب *',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 8),
              groupsAsync.when(
                data: (groups) {
                  return DropdownButtonFormField<GroupModel>(
                    value: _selectedGroup,
                    decoration: const InputDecoration(
                      hintText: 'اختر المجموعة المتاحة...',
                      prefixIcon: Icon(Icons.pool, color: AppTheme.primaryBlue),
                    ),
                    items: groups.map((g) {
                      final isFull = !g.isAvailable;
                      return DropdownMenuItem<GroupModel>(
                        value: isFull ? null : g,
                        enabled: !isFull,
                        child: Text(
                          '${g.groupCode} - ${g.coachName} (${g.trainingType} | المقاعد: ${g.availableSeats}) ${isFull ? '[مكتملة]' : ''}',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: isFull ? Colors.grey : AppTheme.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedGroup = val;
                      });
                    },
                    validator: (val) => val == null ? 'يرجى اختيار المجموعة' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => Text('خطأ في تحميل المجموعات', style: GoogleFonts.cairo(color: AppTheme.errorRed)),
              ),

              // Auto-populated and Locked Group Details Card
              if (_selectedGroup != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock, size: 16, color: AppTheme.primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            'بيانات المجموعة المقفلة (تعبئة آلية):',
                            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildDetailChip('المدرب', _selectedGroup!.coachName, Icons.sports),
                          _buildDetailChip('أيام التدريب', _selectedGroup!.trainingDays.join(' - '), Icons.calendar_today),
                          _buildDetailChip('الموعد', _selectedGroup!.sessionTime, Icons.access_time),
                          _buildDetailChip('نوع التدريب', _selectedGroup!.trainingType, Icons.fitness_center),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 3. Subscription Type & Sessions Count
              Text(
                '3. تفاصيل الاشتراك والرسوم *',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _subscriptionType,
                      decoration: const InputDecoration(
                        labelText: 'نوع الاشتراك',
                        prefixIcon: Icon(Icons.card_membership, color: AppTheme.primaryBlue),
                      ),
                      items: AppConstants.subscriptionTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type, style: GoogleFonts.cairo(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _subscriptionType = val;
                            if (val.contains('12')) {
                              _sessionsCount = 12;
                            } else {
                              _sessionsCount = 8;
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: '$_sessionsCount',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'عدد الحصص',
                        prefixIcon: Icon(Icons.repeat, color: AppTheme.primaryBlue),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null) _sessionsCount = parsed;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Financial inputs: Required, Paid, Stamp fee
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountRequiredController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ المقرر (ج.م) *',
                        prefixIcon: Icon(Icons.money, color: AppTheme.primaryBlue),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _amountPaidController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ المدفوع (ج.م) *',
                        prefixIcon: Icon(Icons.payments, color: AppTheme.primaryBlue),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stamp Card Fee
              TextFormField(
                controller: _stampFeeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سعر ختم الكارت (ج.م) *',
                  prefixIcon: Icon(Icons.receipt_long, color: AppTheme.primaryBlue),
                ),
                validator: (val) => val == null || val.isEmpty ? 'يرجى تحديد رسوم الختم' : null,
              ),

              const SizedBox(height: 16),

              // Dates: Payment Date & Start Date
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isStart: false),
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'تاريخ الدفع'),
                        child: Text(AppFormatters.formatDate(_paymentDate), style: GoogleFonts.cairo(fontSize: 14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(isStart: true),
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'تاريخ البداية'),
                        child: Text(AppFormatters.formatDate(_startDate), style: GoogleFonts.cairo(fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Real-time Calculated Financial Summary Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _amountRemaining <= 0
                      ? AppTheme.successGreen.withOpacity(0.08)
                      : AppTheme.warningOrange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _amountRemaining <= 0
                        ? AppTheme.successGreen.withOpacity(0.3)
                        : AppTheme.warningOrange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('حالة السداد المحسوبة:', style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textMuted)),
                        Text(
                          _paymentStatus,
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _amountRemaining <= 0 ? AppTheme.successGreen : AppTheme.warningOrange,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('المبلغ المتبقي:', style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textMuted)),
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
              ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton.icon(
                onPressed: isSubmitting ? null : _submitForm,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
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

  Widget _buildDetailChip(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryLight),
        const SizedBox(width: 4),
        Text('$label: ', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
        Text(value, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
      ],
    );
  }
}
