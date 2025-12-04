import 'package:hive/hive.dart';

part 'imd_weather_model.g.dart';

/// IMD Weather Response - matches actual API response
/// JSON: {station, lat, lon, sunrise, sunset, moonrise, moonset, forecast_period[], last_updated}
@HiveType(typeId: 30)
class ImdWeatherResponse {
  @HiveField(0)
  final String station; // Station name like "Dehradun-Jhajhara"

  @HiveField(1)
  final double lat;

  @HiveField(2)
  final double lon;

  @HiveField(3)
  final String sunrise; // e.g., "06:57"

  @HiveField(4)
  final String sunset; // e.g., "17:17"

  @HiveField(5)
  final String moonrise; // e.g., "14:54"

  @HiveField(6)
  final String moonset; // e.g., "03:41"

  @HiveField(7)
  final List<ImdForecastDay> forecastPeriod;

  @HiveField(8)
  final String lastUpdated;

  ImdWeatherResponse({
    required this.station,
    required this.lat,
    required this.lon,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.forecastPeriod,
    required this.lastUpdated,
  });

  factory ImdWeatherResponse.fromJson(Map<String, dynamic> json) {
    return ImdWeatherResponse(
      station: json['station']?.toString() ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lon: (json['lon'] ?? 0).toDouble(),
      sunrise: json['sunrise']?.toString() ?? '',
      sunset: json['sunset']?.toString() ?? '',
      moonrise: json['moonrise']?.toString() ?? '',
      moonset: json['moonset']?.toString() ?? '',
      forecastPeriod: (json['forecast_period'] as List<dynamic>?)
              ?.map((e) => ImdForecastDay.fromJson(e))
              .toList() ??
          [],
      lastUpdated: json['last_updated']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station': station,
      'lat': lat,
      'lon': lon,
      'sunrise': sunrise,
      'sunset': sunset,
      'moonrise': moonrise,
      'moonset': moonset,
      'forecast_period': forecastPeriod.map((e) => e.toJson()).toList(),
      'last_updated': lastUpdated,
    };
  }

  /// Get today's forecast (date_offset == 0)
  ImdForecastDay? get today {
    try {
      return forecastPeriod.firstWhere((f) => f.dateOffset == 0);
    } catch (e) {
      return forecastPeriod.isNotEmpty ? forecastPeriod.first : null;
    }
  }
}

/// Forecast for a single day
/// JSON: {date_offset, date, max, min, desc, img, rh_0830, rh_1730, warning, warning_color}
@HiveType(typeId: 31)
class ImdForecastDay {
  @HiveField(0)
  final int dateOffset; // 0 = today, 1 = tomorrow, etc.

  @HiveField(1)
  final String date; // e.g., "2025-12-02"

  @HiveField(2)
  final double? max; // Max temperature

  @HiveField(3)
  final double? min; // Min temperature

  @HiveField(4)
  final String desc; // Weather description like "Mainly Clear sky"

  @HiveField(5)
  final String img; // Icon code like "2", "3"

  @HiveField(6)
  final int? rh0830; // Relative Humidity at 8:30 AM

  @HiveField(7)
  final int? rh1730; // Relative Humidity at 5:30 PM

  @HiveField(8)
  final String warning; // Warning text like "No warning" or actual warning

  @HiveField(9)
  final String warningColor; // "green", "yellow", "orange", "red"

  ImdForecastDay({
    required this.dateOffset,
    required this.date,
    this.max,
    this.min,
    required this.desc,
    required this.img,
    this.rh0830,
    this.rh1730,
    required this.warning,
    required this.warningColor,
  });

  factory ImdForecastDay.fromJson(Map<String, dynamic> json) {
    return ImdForecastDay(
      dateOffset: json['date_offset'] ?? 0,
      date: json['date']?.toString() ?? '',
      max: json['max']?.toDouble(),
      min: json['min']?.toDouble(),
      desc: json['desc']?.toString() ?? '',
      img: json['img']?.toString() ?? '',
      rh0830: json['rh_0830'],
      rh1730: json['rh_1730'],
      warning: json['warning']?.toString() ?? '',
      warningColor: json['warning_color']?.toString() ?? 'green',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date_offset': dateOffset,
      'date': date,
      'max': max,
      'min': min,
      'desc': desc,
      'img': img,
      'rh_0830': rh0830,
      'rh_1730': rh1730,
      'warning': warning,
      'warning_color': warningColor,
    };
  }

  // Helper getters
  String get maxTemp => max != null ? '${max!.toStringAsFixed(0)}°C' : 'N/A';
  String get minTemp => min != null ? '${min!.toStringAsFixed(0)}°C' : 'N/A';
  String get humidity0830 => rh0830 != null ? '$rh0830%' : 'N/A';
  String get humidity1730 => rh1730 != null ? '$rh1730%' : 'N/A';
  
  bool get hasWarning => warning.isNotEmpty && 
      warning.toLowerCase() != 'no warning' && 
      warningColor.toLowerCase() != 'green';

  String get dayLabel {
    if (dateOffset == 0) return 'Today';
    if (dateOffset == 1) return 'Tomorrow';
    
    try {
      final dateTime = DateTime.parse(date);
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[dateTime.weekday - 1];
    } catch (e) {
      return 'Day ${dateOffset + 1}';
    }
  }

  String get shortDayLabel {
    if (dateOffset == 0) return 'Today';
    if (dateOffset == 1) return 'Tomorrow';
    
    try {
      final dateTime = DateTime.parse(date);
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
    } catch (e) {
      return 'Day ${dateOffset + 1}';
    }
  }

  String get displayDate {
    try {
      final dateTime = DateTime.parse(date);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dateTime.day} ${months[dateTime.month - 1]}';
    } catch (e) {
      return date;
    }
  }
}