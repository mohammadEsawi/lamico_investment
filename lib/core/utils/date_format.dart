class AppDate {
  /// Format: "22 يونيو 2026" or "22/06/2026"
  static String format(dynamic raw, {bool short = false}) {
    if (raw == null) return '--';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      if (short) {
        return '${dt.day.toString().padLeft(2, '0')}/'
            '${dt.month.toString().padLeft(2, '0')}/'
            '${dt.year}';
      }
      const months = [
        '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw.toString().length >= 10
          ? raw.toString().substring(0, 10)
          : raw.toString();
    }
  }

  /// Format: "22/06/2026 08:30"
  static String formatWithTime(dynamic raw) {
    if (raw == null) return '--';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.toString().length >= 16
          ? raw.toString().substring(0, 16)
          : raw.toString();
    }
  }

  /// Sort a list descending by a date field (newest first).
  static void sortDesc(List<dynamic> list, {String field = 'createdAt'}) {
    list.sort((a, b) {
      final aStr = (a as Map<String, dynamic>)[field]?.toString() ?? '';
      final bStr = (b as Map<String, dynamic>)[field]?.toString() ?? '';
      return bStr.compareTo(aStr);
    });
  }
}
