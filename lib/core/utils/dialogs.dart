import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../../features/players/models/player_model.dart';
import 'formatters.dart';
import 'whatsapp_helper.dart';

class AppDialogs {
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.warningOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Dialog showing Player ID Card & QR Code
  static void showPlayerCardDialog(BuildContext context, PlayerModel player) {
    final GlobalKey cardBoundaryKey = GlobalKey();
    bool isGeneratingImage = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Renderable Card Boundary for high-res image export
                RepaintBoundary(
                  key: cardBoundaryKey,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF002244), Color(0xFF004488)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.pool, color: AppTheme.accentCyan, size: 28),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'أكاديمية عالم السباحة (دار المشاة)',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'SWIMMING WORLD ACADEMY',
                                  style: GoogleFonts.cairo(
                                    color: AppTheme.accentCyan,
                                    fontSize: 9,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // QR Code in white rounded box
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                            data: player.playerCode,
                            version: QrVersions.auto,
                            size: 160,
                            gapless: false,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Swimmer Name & Info
                        Text(
                          player.playerName,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'كود العضوية: ${player.playerCode}',
                          style: GoogleFonts.cairo(
                            color: AppTheme.accentCyan,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'الفرع: ${player.branch} | ${player.customerType}',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'بطاقة الحضور والباركود الرقمي المعتمد',
                          style: GoogleFonts.cairo(
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Button 1: Share Image via WhatsApp
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: isGeneratingImage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.share, size: 20),
                    label: Text(
                      isGeneratingImage ? 'جاري تجهيز صورة الكارت...' : '📸 مشاركة كارت الباركود كصورة (واتساب)',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: isGeneratingImage
                        ? null
                        : () async {
                            setDialogState(() => isGeneratingImage = true);
                            try {
                              final boundary = cardBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                              if (boundary == null) {
                                throw Exception('تعذر التقاط صورة الكارت');
                              }
                              final image = await boundary.toImage(pixelRatio: 3.0);
                              final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                              if (byteData == null) {
                                throw Exception('فشل تحويل الصورة');
                              }
                              final pngBytes = byteData.buffer.asUint8List();
                              final tempDir = await getTemporaryDirectory();
                              final filePath = '${tempDir.path}/card_${player.playerCode}.png';
                              final file = File(filePath);
                              await file.writeAsBytes(pngBytes);

                              final welcomeText = WhatsAppHelper.buildPlayerWelcomeMessage(player);
                              await Share.shareXFiles(
                                [XFile(file.path)],
                                text: welcomeText,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                AppDialogs.showErrorSnackBar(context, 'تعذر مشاركة الصورة: $e');
                              }
                            } finally {
                              setDialogState(() => isGeneratingImage = false);
                            }
                          },
                  ),
                ),

                const SizedBox(height: 8),

                // Button 2: Direct Text Message on WhatsApp
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF128C7E),
                      side: const BorderSide(color: Color(0xFF128C7E)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: Text(
                      '💬 إرسال رسالة ترحيبية نصية فقط',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () async {
                      final msg = WhatsAppHelper.buildPlayerWelcomeMessage(player);
                      final success = await WhatsAppHelper.openWhatsApp(
                        phone: player.guardianPhone,
                        message: msg,
                      );
                      if (!success && context.mounted) {
                        AppDialogs.showWarningSnackBar(
                          context,
                          'تعذر فتح الواتساب. تأكد من صحة رقم ولي الأمر (${player.guardianPhone})',
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('إغلاق', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
