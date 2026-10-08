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
              return Card(
                child: ListTile(
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
                  trailing: Chip(
                    label: Text(
                      coach.status,
                      style: GoogleFonts.cairo(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: coach.status == 'نشط' ? AppTheme.successGreen : AppTheme.textMuted,
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
