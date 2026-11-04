import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/rbac/app_role.dart';
import '../../../core/services/telemetry_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  Timer? _stealthTimer;

  @override
  void dispose() {
    _stealthTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      AppDialogs.showErrorSnackBar(context, 'يرجى إدخال البريد الإلكتروني أو اسم المستخدم');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(currentUserProvider.notifier).signIn(email, password);
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorSnackBar(context, 'فشل تسجيل الدخول: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeveloperSecretPrompt() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.build_circle_outlined, color: AppTheme.primaryBlue, size: 26),
            const SizedBox(width: 8),
            Text('فحص الصيانة وتحديث النظام', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'يرجى إدخال رمز التحقق الفني للمتابعة:',
              style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'رمز PIN الخاص',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.lock_clock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () {
              final pin = pinController.text.trim();
              Navigator.pop(ctx);
              if (pin == '992288') {
                _showDeveloperConsole();
              } else {
                AppDialogs.showErrorSnackBar(context, 'رمز PIN غير صحيح');
              }
            },
            child: const Text('تحقق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeveloperConsole() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (sheetCtx, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
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
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: AppTheme.warningOrange, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'لوحة تحكم المطور العام (Super Admin)',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Super Admin Direct Login
              Card(
                color: AppTheme.warningOrange.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppTheme.warningOrange.withOpacity(0.3)),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.warningOrange,
                    child: Icon(Icons.flash_on, color: Colors.white),
                  ),
                  title: Text(
                    'دخول مباشر كـ Super Admin',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'تجاوز تسجيل الدخول والدخول بصلاحيات المالك الكاملة وتجاوز القيود',
                    style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(currentUserProvider.notifier).enterSuperAdminMode();
                    AppDialogs.showSuccessSnackBar(context, 'مرحباً بك! تم تفعيل وضع Super Admin المطور بنجاح.');
                  },
                ),
              ),

              const SizedBox(height: 20),

              // GPS Telemetry Header & Manual Probe Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📍 مواقع الإداري والمالك (GPS Telemetry)',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue),
                      ),
                      Text(
                        'آخر موقع نشط لكل مستخدم',
                        style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: Text(
                      'مسح السجل',
                      style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text('مسح سجل المواقع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                          content: Text('هل تريد مسح جميع سجلات المواقع السابقة من السحابة والبدء على نظيف؟', style: GoogleFonts.cairo(fontSize: 13)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('مسح الكل'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && mounted) {
                        await TelemetryService.instance.clearAllTelemetry();
                        if (mounted) {
                          AppDialogs.showSuccessSnackBar(context, 'تم مسح سجل المواقع بنجاح');
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Manual GPS Probe Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.my_location, size: 18),
                  label: Text(
                    '📡 فحص وتحديث موقع هذا الجهاز الآن',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () async {
                    AppDialogs.showSuccessSnackBar(context, 'جاري تحديد موقع الجهاز وتحديث السحابة...');
                    final pos = await TelemetryService.instance.testAndRecordLocation();
                    if (mounted) {
                      if (pos != null) {
                        AppDialogs.showSuccessSnackBar(context, 'تم التقاط وتحديث الموقع بنجاح: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}');
                      } else {
                        AppDialogs.showErrorSnackBar(context, 'تعذر التقاط الموقع. يرجى التأكد من تشغيل الـ GPS ومنح الإذن للتطبيق.');
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Live Stream of Telemetry Locations (1 latest card per user)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: TelemetryService.instance.streamTelemetryLocations(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                  }
                  final docs = snapshot.data ?? [];

                  // Deduplicate to show only 1 latest active card per user
                  final Map<String, Map<String, dynamic>> uniqueUsers = {};
                  for (final item in docs) {
                    final key = (item['uid'] as String?)?.isNotEmpty == true
                        ? item['uid'] as String
                        : (item['username'] as String? ?? item['docId'] as String);
                    if (!uniqueUsers.containsKey(key)) {
                      uniqueUsers[key] = item;
                    }
                  }
                  final displayList = uniqueUsers.values.toList();

                  if (displayList.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'لا توجد مواقع مسجلة حتى الآن.\n(يتم تسجيل الموقع فور فتح التطبيق من قبل الإداري أو المالك)',
                          style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: displayList.map((item) {
                      final name = item['displayName'] ?? item['username'] ?? 'مستخدم';
                      final role = item['roleTitle'] ?? item['role'] ?? 'موظف';
                      final lat = item['latitude'];
                      final lng = item['longitude'];
                      final mapsUrl = item['mapsUrl'] as String?;
                      final recordedAt = item['recordedAt']?.toString() ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue,
                            child: Icon(Icons.location_on, color: Colors.white, size: 18),
                          ),
                          title: Text('$name ($role)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(
                            'إحداثيات: $lat, $lng\nالوقت: $recordedAt',
                            style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted),
                          ),
                          trailing: mapsUrl != null
                              ? IconButton(
                                  icon: const Icon(Icons.map, color: Colors.green),
                                  tooltip: 'عرض في خرائط جوجل',
                                  onPressed: () async {
                                    try {
                                      final uri = Uri.parse(mapsUrl);
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    } catch (e) {
                                      if (mounted) {
                                        AppDialogs.showErrorSnackBar(context, 'تعذر فتح خرائط جوجل: $e');
                                      }
                                    }
                                  },
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Academy Official Logo with secret stealth 30-second continuous hold
                    Listener(
                      onPointerDown: (_) {
                        _stealthTimer?.cancel();
                        _stealthTimer = Timer(const Duration(seconds: 30), () {
                          if (mounted) {
                            _showDeveloperSecretPrompt();
                          }
                        });
                      },
                      onPointerUp: (_) => _stealthTimer?.cancel(),
                      onPointerCancel: (_) => _stealthTimer?.cancel(),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pool,
                              size: 54,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'S.W - المعادي',
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Text(
                      'أكاديمية عالم السباحة - فرع المعادي',
                      style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 32),

                    // Email Field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني أو اسم المستخدم',
                        hintText: 'أدخل اسم المستخدم أو البريد الإلكتروني',
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field with Eye Toggle
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        hintText: 'أدخل كلمة المرور',
                        prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryBlue),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.primaryBlue,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('تسجيل الدخول للنظام'),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
