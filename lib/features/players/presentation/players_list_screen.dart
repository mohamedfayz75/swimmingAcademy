import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/rbac/app_role.dart';
import '../../../data/local/local_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/player_model.dart';
import '../providers/player_provider.dart';
import 'player_registration_screen.dart';

class PlayersListScreen extends ConsumerStatefulWidget {
  const PlayersListScreen({super.key});

  @override
  ConsumerState<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends ConsumerState<PlayersListScreen> {
  String _searchQuery = '';
  String? _filterType;

  void _confirmDeletePlayer(PlayerModel player) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
            const SizedBox(width: 8),
            Text('تأكيد حذف اللاعب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف اللاعب «${player.playerName}» (كود: ${player.playerCode}) نهائياً من النظام؟',
          style: GoogleFonts.cairo(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              LocalStore.instance.deletePlayer(player.playerCode);
              Navigator.pop(ctx);
              AppDialogs.showSuccessSnackBar(context, 'تم حذف اللاعب ${player.playerName} بنجاح');
            },
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersStreamProvider);
    final isOwner = ref.watch(currentUserProvider).value?.role.isOwner ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل وبيانات اللاعبين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'تسجيل لاعب جديد',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerRegistrationScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث باسم اللاعب، الكود (SW-101)، أو الهاتف...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('تصفية حسب النوع:', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('الكل', style: GoogleFonts.cairo(fontSize: 12)),
                      selected: _filterType == null,
                      onSelected: (val) => setState(() => _filterType = null),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(AppConstants.customerTypeNew, style: GoogleFonts.cairo(fontSize: 12)),
                      selected: _filterType == AppConstants.customerTypeNew,
                      onSelected: (val) => setState(() => _filterType = AppConstants.customerTypeNew),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(AppConstants.customerTypeRenew, style: GoogleFonts.cairo(fontSize: 12)),
                      selected: _filterType == AppConstants.customerTypeRenew,
                      onSelected: (val) => setState(() => _filterType = AppConstants.customerTypeRenew),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: playersAsync.when(
              data: (players) {
                var filtered = players;
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((p) {
                    return p.playerName.toLowerCase().contains(_searchQuery) ||
                        p.playerCode.toLowerCase().contains(_searchQuery) ||
                        p.guardianPhone.contains(_searchQuery);
                  }).toList();
                }

                if (_filterType != null) {
                  filtered = filtered.where((p) => p.customerType == _filterType).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text('لم يتم العثور على أي لاعبين مطابقة للبحث', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final player = filtered[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => AppDialogs.showPlayerCardDialog(context, player),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: Avatar + Name & Code + Type Badge
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppTheme.primaryBlue,
                                    child: Text(
                                      player.playerName.isNotEmpty ? player.playerName.substring(0, 1) : 'ل',
                                      style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          player.playerName,
                                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'كود: ${player.playerCode}  •  فرع: ${player.branch}',
                                          style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    label: Text(
                                      player.customerType,
                                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: player.customerType == AppConstants.customerTypeNew
                                        ? AppTheme.accentCyan
                                        : AppTheme.accentTeal,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Row 2: Phone number with icon
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone, size: 14, color: AppTheme.primaryLight),
                                    const SizedBox(width: 6),
                                    Text(
                                      'هاتف ولي الأمر: ${player.guardianPhone}',
                                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryLight),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 8),

                              // Row 3: Action Buttons (Re-send Card, WhatsApp, Delete)
                              Row(
                                children: [
                                  // Re-send Barcode Card
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        side: const BorderSide(color: AppTheme.primaryBlue),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.qr_code, size: 18, color: AppTheme.primaryBlue),
                                      label: Text(
                                        'كارت الباركود',
                                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                      ),
                                      onPressed: () => AppDialogs.showPlayerCardDialog(context, player),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // WhatsApp Direct Chat Button (Blank chat without prefilled welcome)
                                  IconButton.filled(
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.chat, size: 18),
                                    tooltip: 'محادثة مباشرة مع ولي الأمر',
                                    onPressed: () async {
                                      final ok = await WhatsAppHelper.openWhatsApp(
                                        phone: player.guardianPhone,
                                        message: '',
                                      );
                                      if (!ok && context.mounted) {
                                        AppDialogs.showWarningSnackBar(
                                          context,
                                          'تعذر فتح الواتساب. تأكد من صحة رقم الهاتف (${player.guardianPhone})',
                                        );
                                      }
                                    },
                                  ),

                                  // Owner Delete Action
                                  if (isOwner) ...[
                                    const SizedBox(width: 4),
                                    IconButton.outlined(
                                      style: IconButton.styleFrom(
                                        foregroundColor: AppTheme.errorRed,
                                        side: const BorderSide(color: AppTheme.errorRed),
                                      ),
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      tooltip: 'حذف اللاعب نهائياً',
                                      onPressed: () => _confirmDeletePlayer(player),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('خطأ في تحميل اللاعبين: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
