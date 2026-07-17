import 'package:intl/intl.dart';

/// Helpers de formatage pour l'affichage (FCFA, dates, WhatsApp).
class Formatters {
  const Formatters._();

  static final NumberFormat _fcfa = NumberFormat.decimalPattern('fr_FR');

  /// 210000 -> "210 000 FCFA"
  static String fcfa(num? value) {
    if (value == null) return '-';
    return '${_fcfa.format(value.round())} FCFA';
  }

  /// Date courte : 09/07/2026
  static String date(DateTime? d) {
    if (d == null) return '-';
    return DateFormat('dd/MM/yyyy').format(d.toLocal());
  }

  /// Normalise un numero WhatsApp senegalais vers le format international.
  /// "77 123 45 67" -> "221771234567"
  static String whatsappE164(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('221')) return digits;
    return '221$digits';
  }
}
