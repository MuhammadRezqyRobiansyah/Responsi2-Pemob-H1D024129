/// Pilihan satuan kecepatan angin yang disimpan di preferensi lokal.
enum WindSpeedUnit {
  kmh('km/j'),
  mph('mph');

  const WindSpeedUnit(this.label);
  final String label;
}

/// Mengonversi dan memformat suhu, kecepatan angin, tanggal (Bahasa Indonesia),
/// arah angin, serta singkatan zona waktu.
class WeatherFormatter {
  WeatherFormatter._();

  static const _fullWeekdaysId = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const _shortWeekdaysId = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  static const _shortMonthsId = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static double convertTemperature(
    double celsius, {
    required bool useFahrenheit,
  }) {
    if (!useFahrenheit) return celsius;
    return (celsius * 9 / 5) + 32;
  }

  static String formatTemperature(
    double celsius, {
    required bool useFahrenheit,
    bool showUnit = true,
  }) {
    final value =
        convertTemperature(celsius, useFahrenheit: useFahrenheit).round();
    if (!showUnit) return '$value°';
    return '$value°${useFahrenheit ? 'F' : 'C'}';
  }

  static double convertWindSpeed(
    double kmh, {
    required WindSpeedUnit unit,
  }) {
    if (unit == WindSpeedUnit.kmh) return kmh;
    return kmh * 0.621371;
  }

  static String formatWindSpeed(
    double kmh, {
    required WindSpeedUnit unit,
  }) {
    final value = convertWindSpeed(kmh, unit: unit).round();
    return '$value ${unit.label}';
  }

  static String formatPrecipitation(double mm) {
    return '${mm.toStringAsFixed(1)} mm';
  }

  static String formatHeaderDate(DateTime date) {
    final dayName = _fullWeekdaysId[date.weekday - 1];
    final monthName = _shortMonthsId[date.month - 1];
    return '$dayName, ${date.day} $monthName';
  }

  static String formatForecastDay(DateTime date, int index) {
    if (index == 0) return 'Hari ini';
    return formatShortWeekday(date);
  }

  static String formatShortWeekday(DateTime date) {
    return _shortWeekdaysId[date.weekday - 1];
  }

  static String formatTimezoneShort(String timezone, String abbreviation) {
    switch (timezone) {
      case 'Asia/Jakarta':
      case 'Asia/Pontianak':
        return 'WIB';
      case 'Asia/Makassar':
        return 'WITA';
      case 'Asia/Jayapura':
        return 'WIT';
      default:
        return abbreviation.isNotEmpty ? abbreviation : timezone;
    }
  }

  static String windStatus(double speedKmh) {
    if (speedKmh < 8) return 'Tenang';
    if (speedKmh < 20) return 'Sepoi';
    if (speedKmh < 38) return 'Sedang';
    return 'Kencang';
  }

  static String compassDirection(int degrees) {
    const directions = ['U', 'TL', 'T', 'TG', 'S', 'BD', 'B', 'BL'];
    final normalized = ((degrees % 360) + 360) % 360;
    final index = ((normalized + 22.5) ~/ 45) % 8;
    return directions[index];
  }
}
