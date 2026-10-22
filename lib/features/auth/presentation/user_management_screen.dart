import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/rbac/app_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    UserRole selectedRole = UserRole.staff;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.person_add, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text('إضافة إداري / موظف جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'الاسم الكامل *', hintText: 'مثال: كابتن أحمد محمود'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'اسم المستخدم (للدخول) *', hintText: 'مثال: ahmed'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'كلمة المرور *', hintText: 'أدخل باسورد الحساب'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف (اختياري)'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'صلاحية الحساب *'),
                    items: [
                      DropdownMenuItem(
                        value: UserRole.staff,
                        child: Text('موظف استقبال وإداري (لا يرى الحسابات)', style: GoogleFonts.cairo(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: UserRole.owner,
                        child: Text('مالك عام (صلاحيات كاملة وخزينة)', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.warningOrange)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedRole = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final username = usernameController.text.trim();
                  final password = passwordController.text.trim();

                  if (name.isEmpty || username.isEmpty || password.isEmpty) {
                    AppDialogs.showErrorSnackBar(context, 'يرجى ملء جميع الحقول الإلزامية');
                    return;
                  }

                  ref.read(currentUserProvider.notifier).addNewUser(
                        displayName: name,
                        username: username,
                        password: password,
                        role: selectedRole,
                        phoneNumber: phoneController.text.trim(),
                      );

                  Navigator.pop(ctx);
                  AppDialogs.showSuccessSnackBar(context, 'تم إضافة المستخدم بنجاح! يمكنه الدخول الآن.');
                },
                child: Text('حفظ المستخدم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    final nameController = TextEditingController(text: user.displayName);
    final usernameController = TextEditingController(text: user.username);
    final passwordController = TextEditingController(text: user.password);
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    UserRole selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.edit, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text('تعديل بيانات المستخدم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم بالكامل *',
                      prefixIcon: Icon(Icons.badge, color: AppTheme.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم للدخول (Username) *',
                      prefixIcon: Icon(Icons.person, color: AppTheme.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور (Password) *',
                      prefixIcon: Icon(Icons.lock, color: AppTheme.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف (اختياري)',
                      prefixIcon: Icon(Icons.phone, color: AppTheme.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'الصلاحية والرتبة *'),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.staff,
                        child: Text('موظف استقبال (إدخال بيانات)'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.owner,
                        child: Text('المالك (الإدارة العليا والتقفيل)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedRole = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final username = usernameController.text.trim();
                  final password = passwordController.text.trim();

                  if (name.isEmpty || username.isEmpty || password.isEmpty) {
                    AppDialogs.showErrorSnackBar(context, 'يرجى ملء الحقول المطلوبة');
                    return;
                  }

                  final updated = user.copyWith(
                    displayName: name,
                    username: username,
                    password: password,
                    phoneNumber: phoneController.text.trim(),
                    role: selectedRole,
                  );

                  ref.read(currentUserProvider.notifier).updateUser(updated);
                  Navigator.pop(ctx);
                  AppDialogs.showSuccessSnackBar(context, 'تم تعديل بيانات المستخدم $name بنجاح');
                },
                child: Text('حفظ التعديلات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteUser(UserModel user) {
    final allUsers = ref.read(usersStreamProvider).value ?? [];
    if (user.role.isOwner) {
      final ownerCount = allUsers.where((u) => u.role.isOwner).length;
      if (ownerCount <= 1) {
        AppDialogs.showErrorSnackBar(context, 'لا يمكن حذف حساب المالك الوحيد في النظام! يجب تعيين مالك آخر أولاً.');
        return;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
            const SizedBox(width: 8),
            Text('تأكيد حذف الحساب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف حساب «${user.displayName}» (${user.username}) نهائياً من النظام؟',
          style: GoogleFonts.cairo(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(currentUserProvider.notifier).deleteUser(user.uid);
              Navigator.pop(ctx);
              AppDialogs.showSuccessSnackBar(context, 'تم حذف حساب ${user.displayName} نهائياً');
            },
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(UserModel user) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.key, color: AppTheme.warningOrange),
            const SizedBox(width: 8),
            Text('تغيير كلمة مرور (${user.displayName})', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اسم المستخدم: ${user.username}', style: GoogleFonts.cairo(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة *',
                hintText: 'أدخل الباسورد الجديد',
                prefixIcon: Icon(Icons.lock_reset, color: AppTheme.primaryBlue),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              final newPass = passwordController.text.trim();
              if (newPass.isEmpty) {
                AppDialogs.showErrorSnackBar(context, 'يرجى كتابة كلمة المرور الجديدة');
                return;
              }
              ref.read(currentUserProvider.notifier).updateUserPassword(user.uid, newPass);
              Navigator.pop(ctx);
              AppDialogs.showSuccessSnackBar(context, 'تم تغيير كلمة المرور بنجاح');
            },
            child: Text('تحديث كلمة المرور', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('إدارة المستخدمين والموظفين', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'إضافة موظف جديد',
            onPressed: _showAddUserDialog,
          ),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text('لا يوجد مستخدمين مسجلين', style: GoogleFonts.cairo(fontSize: 16)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              final isOwner = user.role.isOwner;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isOwner ? AppTheme.warningOrange.withOpacity(0.5) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isOwner ? AppTheme.warningOrange.withOpacity(0.15) : AppTheme.primaryBlue.withOpacity(0.1),
                        child: Icon(
                          isOwner ? Icons.admin_panel_settings : Icons.badge,
                          color: isOwner ? AppTheme.warningOrange : AppTheme.primaryBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user.displayName,
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isOwner ? AppTheme.warningOrange.withOpacity(0.12) : AppTheme.primaryBlue.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user.role.arabicTitle,
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isOwner ? AppTheme.warningOrange : AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'اسم المستخدم: ',
                                  style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                ),
                                Text(
                                  user.username,
                                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'كلمة المرور: ',
                                  style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                ),
                                Text(
                                  user.password,
                                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Action Buttons: Edit, Key, Delete, Active Switch
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue, size: 20),
                            tooltip: 'تعديل بيانات الحساب والرتبة',
                            onPressed: () => _showEditUserDialog(user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.key, color: AppTheme.warningOrange, size: 20),
                            tooltip: 'تغيير كلمة المرور',
                            onPressed: () => _showChangePasswordDialog(user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
                            tooltip: 'حذف الحساب نهائياً',
                            onPressed: () => _confirmDeleteUser(user),
                          ),
                          Switch(
                            value: user.isActive,
                            activeColor: AppTheme.accentCyan,
                            onChanged: (val) {
                              ref.read(currentUserProvider.notifier).toggleUserActive(user.uid, val);
                              AppDialogs.showSuccessSnackBar(
                                context,
                                val ? 'تم تنشيط حساب ${user.displayName}' : 'تم إيقاف حساب ${user.displayName}',
                              );
                            },
                          ),
                        ],
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryBlue,
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text('إضافة موظف', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
