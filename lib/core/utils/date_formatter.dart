/// Formatea fechas sin dependencias externas.
class DateFormatter {
  DateFormatter._();

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String dateOnly(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static String dateTime(DateTime date) =>
      '${dateOnly(date)} ${_two(date.hour)}:${_two(date.minute)}';
}
