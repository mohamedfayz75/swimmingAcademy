import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../providers/player_provider.dart';

class PlayerRegistrationScreen extends ConsumerStatefulWidget {
  const PlayerRegistrationScreen({super.key});

  @override
  ConsumerState<PlayerRegistrationScreen> createState() => _PlayerRegistrationScreenState();
}

class _PlayerRegistrationScreenState extends ConsumerState<PlayerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _branchController = TextEditingController(text: 'الفرع الرئيسي');
  final _phoneController = TextEditingController();

  DateTime _selectedBirthDate = DateTime(2015, 1, 1);
  String _customerType = AppConstants.customerTypeNew;

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final player = await ref.read(playerRegistrationProvider.notifier).register(
            playerName: _nameController.text,
            branch: _branchController.text,
            birthDate: _selectedBirthDate,
            guardianPhone: _phoneController.text,
            customerType: _customerType,
          );

      if (!mounted) return;

      if (player != null) {
        AppDialogs.showSuccessSnackBar(context, 'تم تسجيل اللاعب ${player.playerName} بنجاح!');
        // Show QR membership card dialog
        AppDialogs.showPlayerCardDialog(context, player);

        // Reset form
        _nameController.clear();
        _phoneController.clear();
        setState(() {
          _customerType = AppConstants.customerTypeNew;
        });
        ref.invalidate(nextPlayerCodeProvider);
      }
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showErrorSnackBar(context, 'حدث خطأ أثناء التسجيل: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextCodeAsync = ref.watch(nextPlayerCodeProvider);
    final registrationState = ref.watch(playerRegistrationProvider);
    final isLoading = registrationState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل لاعب جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Code Preview Card
              Card(
                color: AppTheme.primaryBlue.withOpacity(0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.accentCyan.withOpacity(0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.badge, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'كود اللاعب المرتقب',
                            style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textMuted),
                          ),
                          nextCodeAsync.when(
                            data: (code) => Text(
                              code,
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            loading: () => const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            error: (_, __) => Text(
                              'SW-101',
                              style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Chip(
                        label: Text(
                          _customerType,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        backgroundColor: _customerType == AppConstants.customerTypeNew
                            ? AppTheme.accentCyan
                            : AppTheme.accentTeal,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Player Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم اللاعب بالكامل *',
                  hintText: 'مثال: يوسف أحمد علي',
                  prefixIcon: Icon(Icons.person, color: AppTheme.primaryBlue),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى كتابة اسم اللاعب';
                  }
                  if (val.trim().length < 3) {
                    return 'الاسم يجب أن يحتوي على 3 أحرف على الأقل';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Branch
              TextFormField(
                controller: _branchController,
                decoration: const InputDecoration(
                  labelText: 'الفرع *',
                  hintText: 'مثال: الفرع الرئيسي / مسبح 1',
                  prefixIcon: Icon(Icons.location_on, color: AppTheme.primaryBlue),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'يرجى تحديد الفرع' : null,
              ),

              const SizedBox(height: 16),

              // Guardian Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم هاتف ولي الأمر *',
                  hintText: '01XXXXXXXXX',
                  prefixIcon: Icon(Icons.phone, color: AppTheme.primaryBlue),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال رقم هاتف ولي الأمر';
                  }
                  if (val.trim().length < 10) {
                    return 'يرجى إدخال رقم هاتف صحيح';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Birth Date Picker
              InkWell(
                onTap: _pickBirthDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الميلاد *',
                    prefixIcon: Icon(Icons.cake, color: AppTheme.primaryBlue),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppFormatters.formatDate(_selectedBirthDate),
                        style: GoogleFonts.cairo(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryBlue),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Customer Type Radio
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'نوع المشترك:',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Radio<String>(
                              value: AppConstants.customerTypeNew,
                              groupValue: _customerType,
                              activeColor: AppTheme.primaryBlue,
                              onChanged: (val) {
                                if (val != null) setState(() => _customerType = val);
                              },
                            ),
                            Text('عادي (جديد)', style: GoogleFonts.cairo()),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Radio<String>(
                              value: AppConstants.customerTypeRenew,
                              groupValue: _customerType,
                              activeColor: AppTheme.primaryBlue,
                              onChanged: (val) {
                                if (val != null) setState(() => _customerType = val);
                              },
                            ),
                            Text('تجديد', style: GoogleFonts.cairo()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton.icon(
                onPressed: isLoading ? null : _submitForm,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  isLoading ? 'جاري الحفظ وإصدار الكود...' : 'حفظ اللاعب وإصدار كارت QR',
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
