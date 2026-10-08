import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/attendance_model.dart';
import '../providers/attendance_provider.dart';
import '../repository/attendance_repository.dart';

class QRAttendanceScannerScreen extends ConsumerStatefulWidget {
  const QRAttendanceScannerScreen({super.key});

  @override
  ConsumerState<QRAttendanceScannerScreen> createState() => _QRAttendanceScannerScreenState();
}

class _QRAttendanceScannerScreenState extends ConsumerState<QRAttendanceScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final _manualCodeController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleCodeScanned(String rawCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final staffUser = ref.read(currentUserProvider).value;
      final staffUid = staffUser?.uid ?? 'staff-uid';

      final result = await ref.read(attendanceRepositoryProvider).recordAttendance(
            playerCode: rawCode,
            recordedByStaffUid: staffUid,
          );

      if (!mounted) return;

      _showAttendanceConfirmationModal(result);
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showErrorSnackBar(context, 'خطأ في معالجة الحضور: $e');
    } finally {
      // Small delay before allowing next scan to prevent duplicate trigger
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showAttendanceConfirmationModal(AttendanceResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isSuccess = result.success;
        final progress = result.totalSessions > 0
            ? (result.currentSession / result.totalSessions).clamp(0.0, 1.0)
            : 0.0;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Status Icon Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? AppTheme.successGreen.withOpacity(0.12)
                      : AppTheme.errorRed.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
                  size: 48,
                  color: isSuccess ? AppTheme.successGreen : AppTheme.errorRed,
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                isSuccess ? 'تم تسجيل الحضور بنجاح' : 'تنبيه في تسجيل الحضور',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? AppTheme.successGreen : AppTheme.errorRed,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 14, color: AppTheme.textMuted),
              ),

              if (result.player != null) ...[
                const SizedBox(height: 16),
                // Player Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blueGrey.shade100),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppTheme.primaryBlue,
                            child: Text(
                              result.player!.playerName.isNotEmpty
                                  ? result.player!.playerName.substring(0, 1)
                                  : 'ل',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.player!.playerName,
                                  style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'كود اللاعب: ${result.player!.playerCode} | الفرع: ${result.player!.branch}',
                                  style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (result.subscription != null) ...[
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'المجموعة: ${result.subscription!.groupCode}',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'المدرب: ${result.subscription!.coachName}',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Progress Bar: e.g. "حصة 5 من 12"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'تقدم الحصص: حصة ${result.currentSession} من ${result.totalSessions}',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.blueGrey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 1.0 ? AppTheme.warningOrange : AppTheme.accentCyan,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('متابعة المسح (التالي)'),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayAttendanceAsync = ref.watch(todayAttendanceStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ماسح باركود الحضور (QR)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'إضاءة الفلاش',
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            tooltip: 'تبديل الكاميرا',
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Camera QR Scanner Viewport
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final raw = barcode.rawValue;
                      if (raw != null && raw.isNotEmpty && !_isProcessing) {
                        _handleCodeScanned(raw);
                        break;
                      }
                    }
                  },
                ),

                // Stylized Aquatic Scanner Overlay Box
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.accentCyan, width: 3),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentCyan.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),

                // Guidance label
                Positioned(
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'وجه الكاميرا نحو باركود كارت اللاعب',
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                if (_isProcessing)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.accentCyan),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Fallback Manual Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualCodeController,
                    decoration: InputDecoration(
                      hintText: 'إدخال يدوي: كود اللاعب (مثال SW-101)',
                      prefixIcon: const Icon(Icons.keyboard, color: AppTheme.primaryBlue),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _handleCodeScanned(val.trim());
                        _manualCodeController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final text = _manualCodeController.text.trim();
                    if (text.isNotEmpty) {
                      _handleCodeScanned(text);
                      _manualCodeController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('تسجيل'),
                ),
              ],
            ),
          ),

          // 3. Live Log of Today's Attendance
          Expanded(
            flex: 2,
            child: Container(
              color: AppTheme.backgroundLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'سجل حضور اليوم الفوري',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        todayAttendanceAsync.when(
                          data: (list) => Chip(
                            label: Text(
                              '${list.length} لاعبين',
                              style: GoogleFonts.cairo(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: AppTheme.primaryBlue,
                            visualDensity: VisualDensity.compact,
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: todayAttendanceAsync.when(
                      data: (list) {
                        if (list.isEmpty) {
                          return Center(
                            child: Text(
                              'لم يتم تسجيل حضور أي لاعب حتى الآن اليوم',
                              style: GoogleFonts.cairo(color: AppTheme.textMuted, fontSize: 13),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, index) {
                            final item = list[index];
                            return Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.accentCyan.withOpacity(0.15),
                                  child: Text(
                                    '${item.sessionNumber}',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  item.playerName,
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  'المجموعة: ${item.groupCode} | كود: ${item.playerCode}',
                                  style: GoogleFonts.cairo(fontSize: 12),
                                ),
                                trailing: Text(
                                  AppFormatters.formatTimestamp(item.timestamp),
                                  style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(
                        child: Text('خطأ في تحميل سجل الحضور', style: GoogleFonts.cairo(color: AppTheme.errorRed)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
