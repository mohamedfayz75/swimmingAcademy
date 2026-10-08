import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
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

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersStreamProvider);

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
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue,
                          child: Text(
                            player.playerName.isNotEmpty ? player.playerName.substring(0, 1) : 'ل',
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          player.playerName,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          'كود: ${player.playerCode} | هاتف: ${player.guardianPhone} | ${player.branch}',
                          style: GoogleFonts.cairo(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                player.customerType,
                                style: GoogleFonts.cairo(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: player.customerType == AppConstants.customerTypeNew
                                  ? AppTheme.accentCyan
                                  : AppTheme.accentTeal,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.qr_code, color: AppTheme.primaryBlue),
                              tooltip: 'عرض كارت QR',
                              onPressed: () => AppDialogs.showPlayerCardDialog(context, player),
                            ),
                          ],
                        ),
                        onTap: () => AppDialogs.showPlayerCardDialog(context, player),
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
