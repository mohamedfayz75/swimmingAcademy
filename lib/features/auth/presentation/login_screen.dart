import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/rbac/app_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'staff@swimmingworld.com');
  final _passwordController = TextEditingController(text: '123456');
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(currentUserProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );
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

  void _demoLoginAs(UserRole role) {
    ref.read(currentUserProvider.notifier).switchDemoRole(role);
    AppDialogs.showSuccessSnackBar(
      context,
      'تم الدخول التجريبي بصلاحية: ${role.arabicTitle}',
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
                    // Academy Logo Badge
                    Container(
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
                    const SizedBox(height: 16),
                    Text(
                      'أكاديمية عالم السباحة',
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Text(
                      'Swimming World Academy System',
                      style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textMuted),
                    ),

                    const SizedBox(height: 32),

                    // Email Field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email, color: AppTheme.primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: Icon(Icons.lock, color: AppTheme.primaryBlue),
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

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Quick Role Switchers for Demonstration and Testing
                    Text(
                      'أو تسجيل الدخول السريع للاختبار والمعاينة:',
                      style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _demoLoginAs(UserRole.staff),
                            icon: const Icon(Icons.badge, size: 18),
                            label: Text('دخول كموظف', style: GoogleFonts.cairo(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.warningOrange,
                              side: const BorderSide(color: AppTheme.warningOrange),
                            ),
                            onPressed: () => _demoLoginAs(UserRole.owner),
                            icon: const Icon(Icons.admin_panel_settings, size: 18),
                            label: Text('دخول كالمالك', style: GoogleFonts.cairo(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
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
