import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/players/models/player_model.dart';
import '../../features/subscriptions/models/subscription_model.dart';
import 'formatters.dart';

class WhatsAppHelper {
  WhatsAppHelper._();

  /// Converts Arabic-Indic digits (٠-٩) and cleans formatting characters
  static String normalizePhone(String rawPhone) {
    if (rawPhone.isEmpty) return '';

    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var clean = rawPhone.trim();

    // Replace Arabic digits
    for (int i = 0; i < arabicDigits.length; i++) {
      clean = clean.replaceAll(arabicDigits[i], '$i');
    }

    // Remove all non-digits except a possible leading '+'
    clean = clean.replaceAll(RegExp(r'[^\d+]'), '');

    // Normalize international prefixes
    if (clean.startsWith('0020')) {
      clean = clean.substring(2); // '20...'
    } else if (clean.startsWith('+20')) {
      clean = clean.substring(1); // '20...'
    } else if (clean.startsWith('01') && clean.length == 11) {
      // Standard Egyptian mobile 010..., 011..., 012..., 015...
      clean = '20${clean.substring(1)}';
    } else if (clean.startsWith('1') && clean.length == 10) {
      clean = '20$clean';
    } else if (clean.startsWith('+')) {
      clean = clean.substring(1);
    }

    return clean;
  }

  /// Launch WhatsApp with prefilled message
  static Future<bool> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = normalizePhone(phone);
    if (cleanPhone.isEmpty) return false;

    final encodedText = Uri.encodeComponent(message);

    // 1. Primary method: WhatsApp Universal wa.me link
    final waMeUri = message.trim().isEmpty
        ? Uri.parse('https://wa.me/$cleanPhone')
        : Uri.parse('https://wa.me/$cleanPhone?text=$encodedText');

    try {
      final launched = await launchUrl(
        waMeUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } catch (_) {}

    // 2. Fallback: Native whatsapp:// URI scheme
    final nativeUri = message.trim().isEmpty
        ? Uri.parse('whatsapp://send?phone=$cleanPhone')
        : Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedText');
    try {
      final launchedNative = await launchUrl(
        nativeUri,
        mode: LaunchMode.externalApplication,
      );
      if (launchedNative) return true;
    } catch (_) {}

    // 3. Fallback: api.whatsapp.com
    final apiUri = message.trim().isEmpty
        ? Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone')
        : Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedText');
    try {
      return await launchUrl(apiUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Generate WhatsApp message for subscription invoice (New & Renewal)
  static String buildSubscriptionInvoiceMessage({
    required SubscriptionModel sub,
    bool isRenewal = false,
  }) {
    final title = isRenewal
        ? '🔄 *إشعار تجديد اشتراك رسمي*'
        : '📋 *إيصال تأكيد اشتراك وتسجيل*';

    final days = sub.trainingDays.isNotEmpty
        ? sub.trainingDays.join('، ')
        : 'حسب الجدول';

    final time = sub.sessionTime.isNotEmpty ? 'الساعة ${sub.sessionTime}' : '';
    final startDateFormatted = AppFormatters.formatTimestamp(sub.startDate);

    final subFee = sub.amountRequired;
    final stampFee = sub.stampCardFee;
    final totalDue = sub.totalDue;
    final paid = sub.amountPaid;
    final remaining = sub.amountRemaining;

    final String feeBreakdown;
    if (stampFee > 0) {
      feeBreakdown =
          '📋 *تفاصيل المصاريف المقررة:*\n'
          '• قيمة التدريب والاشتراك: ${AppFormatters.formatCurrency(subFee)}\n'
          '• رسوم الكارنيه والاستمارة: ${AppFormatters.formatCurrency(stampFee)}\n'
          '• إجمالي المطلوب سداده: ${AppFormatters.formatCurrency(totalDue)}\n';
    } else {
      feeBreakdown =
          '📋 *المبلغ المطلوب سداده:* ${AppFormatters.formatCurrency(totalDue)}\n';
    }

    final paymentStatusNote = remaining <= 0
        ? '✅ *حالة السداد:* مدفوع بالكامل (خالص)'
        : '⚠️ *حالة السداد:* متبقي ${AppFormatters.formatCurrency(remaining)}';

    return '🏊‍♂️ *أكاديمية عالم السباحة (فندق اللؤلؤة المعادي)* 🏊‍♂️\n'
        '━━━━━━━━━━━━━━━━━━━━━\n'
        '$title\n'
        '━━━━━━━━━━━━━━━━━━━━━\n'
        '👤 *السباح:* ${sub.playerName}\n'
        '🔢 *كود العضوية:* ${sub.playerCode}\n'
        '🏷️ *نوع التدريب:* ${sub.subscriptionType}\n'
        '👥 *المجموعة:* ${sub.groupCode} - كابتن ${sub.coachName}\n'
        '🗓️ *أيام ومواعيد التدريب:* $days $time\n'
        '🌊 *تاريخ أول حصة (نزول المياة):* $startDateFormatted\n'
        '🎯 *عدد الحصص المقررة:* ${sub.sessionsCount} حصة\n'
        '━━━━━━━━━━━━━━━━━━━━━\n'
        '$feeBreakdown'
        '━━━━━━━━━━━━━━━━━━━━━\n'
        '💵 *المبلغ المسدد:* ${AppFormatters.formatCurrency(paid)}\n'
        '⏳ *المبلغ المتبقي:* ${AppFormatters.formatCurrency(remaining)}\n'
        '💳 *طريقة الدفع:* ${sub.paymentMethod}\n'
        '$paymentStatusNote\n'
        '━━━━━━━━━━━━━━━━━━━━━\n'
        '🌟 نتمنى لبطلنا العزيز وقتاً ممتعاً وتدريباً موفقاً وتطوراً مستمراً!\n'
        '📞 للاستفسارات وخدمة العملاء: نرحب بتواصلكم دائماً.';
  }

  /// Generate WhatsApp message for new player registration
  static String buildPlayerWelcomeMessage(PlayerModel player) {
    return '🏊‍♂️ *أكاديمية عالم السباحة (فندق اللؤلؤة المعادي)* 🏊‍♂️\n'
        '━━━━━━━━━━━━━━━━━━━━━\n'
        '🎉 *أهلاً بك في أسرة الأكاديمية!* 🎉\n'
        '━━━━━━━━━━━━━━━━━━━━━\n'
        '👤 *اسم السباح البطل:* ${player.playerName}\n'
        '🔢 *كود العضوية والباركود:* ${player.playerCode}\n'
        '🏢 *الفرع:* ${player.branch}\n'
        '🏷️ *نوع القيد:* ${player.customerType}\n'
        '━━━━━━━━━━━━━━━━━━━━━\n'
        '✅ تم تسجيل بياناتك بنجاح في النظام الإلكتروني للأكاديمية.\n'
        '📲 كارت الباركود الرقمي الخاص باللاعب مرفق لتسجيل الحضور بسهولة وسرعة عند كل تمرين.\n'
        '💡 يُرجى الاحتفاظ بصورة الكارت على هاتفك لإبرازه عند بوابة المسبح.\n'
        '━━━━━━━━━━━━━━━━━━━━━\n'
        'نتمنى لكم ولأبطالنا تجربة رياضية مميزة ومليئة بالبطولات! 🥇';
  }
}
