/// Regras civis usadas pelos módulos que agrupam dados por dia ou competência.
///
/// A camada de domínio não depende de localização do dispositivo: quando um
/// instante precisa ser agrupado, o chamador pode fornecer a data civil já
/// convertida para o fuso da usuária. [localDateOf] é apenas um atalho para o
/// fuso local do processo.
class DateRules {
  const DateRules._();

  static String localDateOf(DateTime instant) {
    final local = instant.toLocal();
    return formatDate(local);
  }

  static String formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String periodOf(String localDate) {
    _validateDate(localDate);
    return localDate.substring(0, 7);
  }

  static DateTime parseDate(String localDate) {
    _validateDate(localDate);
    final date = DateTime.parse(localDate);
    if (formatDate(date) != localDate) {
      throw FormatException('Data civil inválida: $localDate');
    }
    return date;
  }

  static DateTime parsePeriod(String period) {
    _validatePeriod(period);
    return DateTime(
      int.parse(period.substring(0, 4)),
      int.parse(period.substring(5)),
      1,
    );
  }

  static String lastDayOfMonth(String period) {
    final first = parsePeriod(period);
    return formatDate(DateTime(first.year, first.month + 1, 0));
  }

  static String firstDayOfMonth(String period) => '$period-01';

  static String previousPeriod(String period) {
    final first = parsePeriod(period);
    final previous = DateTime(first.year, first.month - 1, 1);
    return '${previous.year.toString().padLeft(4, '0')}-${previous.month.toString().padLeft(2, '0')}';
  }

  static int effectiveAllowanceDay(String period, int requestedDay) {
    if (requestedDay < 1 || requestedDay > 31) {
      throw ArgumentError.value(
        requestedDay,
        'requestedDay',
        'deve estar entre 1 e 31',
      );
    }
    final first = parsePeriod(period);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    return requestedDay > lastDay ? lastDay : requestedDay;
  }

  static void _validateDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw FormatException('Data civil deve estar em YYYY-MM-DD: $value');
    }
  }

  static void _validatePeriod(String value) {
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(value)) {
      throw FormatException('Competência deve estar em YYYY-MM: $value');
    }
  }
}
