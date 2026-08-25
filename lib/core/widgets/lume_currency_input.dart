import 'package:flutter/services.dart';

/// Formats monetary input as Brazilian reais while the user types.
///
/// The last two digits represent cents; grouping and the decimal comma are
/// added without changing the value stored by the domain layer.
class LumeCurrencyInputFormatter extends TextInputFormatter {
  const LumeCurrencyInputFormatter();

  static String formatMinor(int minor) {
    final negative = minor < 0;
    final formatted = _formatDigits(minor.abs().toString());
    return negative ? '-$formatted' : formatted;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final formatted = _formatDigits(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _formatDigits(String digits) {
    final normalized = digits.padLeft(3, '0');
    final cents = normalized.substring(normalized.length - 2);
    final whole = _groupWhole(normalized.substring(0, normalized.length - 2));
    return '$whole,$cents';
  }

  static String _groupWhole(String value) {
    final result = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      if (index > 0 && (value.length - index) % 3 == 0) {
        result.write('.');
      }
      result.write(value[index]);
    }
    return result.toString();
  }
}
