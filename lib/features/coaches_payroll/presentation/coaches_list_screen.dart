import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../owner_dashboard/models/payroll_model.dart';
import '../providers/coaches_payroll_provider.dart';

class CoachesListScreen extends ConsumerStatefulWidget {
  const CoachesListScreen({super.key});

  @override
  ConsumerState<CoachesListScreen> createState() => _CoachesListScreenState();
}

class _CoachesListScreenState extends ConsumerState<CoachesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(coachesPayrollRepositoryProvider).seedInitialCoachesIfEmpty();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'نشط':
        return AppTheme.successGreen;
      case 'إجازة':
        return Colors.orange.shade800;
      case 'غير نشط':
      default:
        return Colors.red.shade700;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'نشط':
        return Icons.check_circle;
      case 'إجازة':
        return Icons.beach_access;
      case 'غير نشط':
      default:
        return Icons.cancel;
    }
  }

  void _showAddCoachDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة كابتن جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الكابتن *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف *'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final coachId = 'COACH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
              final coach = CoachModel(
                coachId: coachId,
                coachName: nameController.text.trim(),
                phoneNumber: phoneController.text.trim(),
                status: 'نشط',
                groupsCount: 0,
              );

              await ref.read(coachesPayrollActionProvider.notifier).addCoach(coach);
              if (mounted) {
                Navigator.pop(ctx);
                AppDialogs.showSuccessSnackBar(context, 'تمت إضافة الكابتن بنجاح');
              }
            },
            child: const Text('حفظ الكابتن'),
          ),
        ],
      ),
    );
  }

  void _showEditCoachDialog(CoachModel coach) {
    final nameController = TextEditingController(text: coach.coachName);
    final phoneController = TextEditingController(text: coach.phoneNumber);
    String selectedStatus = coach.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit, color: AppTheme.accentTeal),
              const SizedBox(width: 8),
              Text('تعديل بيانات الكابتن', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الكابتن *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف *'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'الحالة'),
                  items: const [
                    DropdownMenuItem(value: 'نشط', child: Text('نشط (متاح للعمل)')),
                    DropdownMenuItem(value: 'إجازة', child: Text('إجازة')),
                    DropdownMenuItem(value: 'غير نشط', child: Text('غير نشط / معطل')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedStatus = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                final updated = coach.copyWith(
                  coachName: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  status: selectedStatus,
                );

                await ref.read(coachesPayrollActionProvider.notifier).updateCoach(updated);
                if (mounted) {
                  Navigator.pop(ctx);
                  AppDialogs.showSuccessSnackBar(context, 'تم تحديث بيانات الكابتن بنجاح');
                }
              },
              child: const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCoach(CoachModel coach) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('حذف الكابتن', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف ${coach.coachName} نهائياً من سجل الكباتن؟',
          style: GoogleFonts.cairo(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(coachesPayrollActionProvider.notifier).deleteCoach(coach.coachId);
              if (mounted) {
                Navigator.pop(ctx);
                AppDialogs.showSuccessSnackBar(context, 'تم حذف الكابتن من السجل بنجاح');
              }
            },
            child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangeStatusSheet(CoachModel coach) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: AppTheme.accentTeal),
                    const SizedBox(width: 8),
                    Text(
                      'تغيير حالة: ${coach.coachName}',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'اضغط على الحالة المطلوبة لتغييرها فوراً:',
                  style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                _buildStatusOption(
                  ctx: ctx,
                  coach: coach,
                  title: 'نشط (متاح للعمل وتدريب المجموعات)',
                  statusValue: 'نشط',
                  color: AppTheme.successGreen,
                  icon: Icons.check_circle,
                  isSelected: coach.status == 'نشط',
                ),
                const SizedBox(height: 10),
                _buildStatusOption(
                  ctx: ctx,
                  coach: coach,
                  title: 'إجازة (في إجازة مؤقتة)',
                  statusValue: 'إجازة',
                  color: Colors.orange.shade800,
                  icon: Icons.beach_access,
                  isSelected: coach.status == 'إجازة',
                ),
                const SizedBox(height: 10),
                _buildStatusOption(
                  ctx: ctx,
                  coach: coach,
                  title: 'غير نشط / معطل (موقوف عن العمل)',
                  statusValue: 'غير نشط',
                  color: Colors.red.shade700,
                  icon: Icons.cancel,
                  isSelected: coach.status == 'غير نشط',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusOption({
    required BuildContext ctx,
    required CoachModel coach,
    required String title,
    required String statusValue,
    required Color color,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () async {
        Navigator.pop(ctx);
        if (coach.status == statusValue) return;
        await ref.read(coachesPayrollActionProvider.notifier).setCoachStatus(coach, statusValue);
        if (mounted) {
          AppDialogs.showSuccessSnackBar(context, 'تم تغيير حالة ${coach.coachName} إلى: $statusValue');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coachesAsync = ref.watch(coachesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الكباتن والمدربين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'إضافة كابتن',
            onPressed: _showAddCoachDialog,
          ),
        ],
      ),
      body: coachesAsync.when(
        data: (coaches) {
          if (coaches.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sports, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text('لا يوجد كباتن مسجلين حتى الآن', style: GoogleFonts.cairo(fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _showAddCoachDialog,
                    child: const Text('إضافة كابتن الآن'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: coaches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, index) {
              final coach = coaches[index];
              final statusColor = _getStatusColor(coach.status);
              final statusIcon = _getStatusIcon(coach.status);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue,
                    child: const Icon(Icons.sports, color: Colors.white),
                  ),
                  title: Text(
                    coach.coachName,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    'كود: ${coach.coachId} | هاتف: ${coach.phoneNumber}',
                    style: GoogleFonts.cairo(fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر الحالة التفاعلي القابل للضغط وتغيير الحالة
                      InkWell(
                        onTap: () => _showChangeStatusSheet(coach),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                coach.status,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // قائمة الخيارات الإضافية (تعديل / حذف)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
                        tooltip: 'خيارات إضافية',
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditCoachDialog(coach);
                          } else if (value == 'status') {
                            _showChangeStatusSheet(coach);
                          } else if (value == 'delete') {
                            _confirmDeleteCoach(coach);
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'status',
                            child: Row(
                              children: [
                                const Icon(Icons.swap_horiz, color: AppTheme.accentTeal, size: 20),
                                const SizedBox(width: 8),
                                Text('تغيير الحالة', style: GoogleFonts.cairo(fontSize: 13)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Text('تعديل البيانات', style: GoogleFonts.cairo(fontSize: 13)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Text('حذف الكابتن', style: GoogleFonts.cairo(color: Colors.red, fontSize: 13)),
                              ],
                            ),
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
        error: (err, _) => Center(child: Text('خطأ في تحميل الكباتن: $err')),
      ),
    );
  }
}
