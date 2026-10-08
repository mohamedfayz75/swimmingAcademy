import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppFormatters {
  static final DateFormat _dateFormat = DateFormat('yyyy/MM/dd', 'ar');
  static final DateFormat _monthYearFormat = DateFormat('MM-yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a', 'ar');

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _dateFormat.format(dateTime);
  }

  static String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    return _dateFormat.format(timestamp.toDate());
  }

  static String formatMonthYear(DateTime? dateTime) {
    if (dateTime == null) return _monthYearFormat.format(DateTime.now());
    return _monthYearFormat.format(dateTime);
  }

  static String formatCurrency(double? amount) {
    if (amount == null) return '0.00 ج.م';
    final formatter = NumberFormat('#,##0.00', 'ar');
    return '${formatter.format(amount)} ج.م';
  }

  static String formatNumber(int? number) {
    if (number == null) return '0';
    return NumberFormat('#,##0', 'ar').format(number);
  }
}
