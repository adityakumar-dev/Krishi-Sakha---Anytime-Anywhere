import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sakha/models/imd_weather_model.dart';
import 'package:krishi_sakha/models/station_model.dart';

void main() {
  test('ImdWeatherResponse.fromJson parses weather JSON correctly', () {
    final json = {
      'success': true,
      'status': 200,
      'data': {
        'station_id': '99462',
        'station_name': 'PATTAMBI',
        'date': '2025-12-01',
        'update_time': '2025-12-01 13:16:49',
        'latitude': '10.8000',
        'longitude': '76.1833',
        'current': {
          'max_temp': '32.7°C',
          'min_temp': '25.2°C',
          'max_temp_departure': 'NA',
          'min_temp_departure': '',
          'rainfall': '0.00 mm',
          'humidity_0830': '65%',
          'humidity_1730': null,
          'sunrise': '06:28',
          'sunset': '18:00',
          'moonrise': '14:42',
          'moonset': '02:30'
        },
        'forecast': [
          {
            'day': 0,
            'description': 'Partly cloudy sky with possibility of moderate rain or Thunderstorm',
            'max_temp': '33.0°C',
            'min_temp': '25.0°C',
            'icon_code': '14',
            'humidity_0830': '95%',
            'humidity_1730': '70%'
          }
        ],
        'alerts': [
          {
            'day': 0,
            'warning_code': '25',
            'alert_level': '0',
            'alert_text': 'Light to Moderate Rainfall',
            'alert_icon': '25'
          }
        ],
        'historical': [
          {
            'date': '2025-11-24',
            'display_date': '24 Nov',
            'max_temp': 28.3,
            'min_temp': 24.5,
            'forecast_max': null,
            'forecast_min': null
          }
        ]
      }
    };

    final response = ImdWeatherResponse.fromJson(json);

    expect(response.success, true);
    expect(response.status, 200);
    expect(response.data.stationId, '99462');
    expect(response.data.stationName, 'PATTAMBI');
    expect(response.data.current.maxTemp, '32.7°C');
    expect(response.data.forecast.length, 1);
    expect(response.data.alerts.length, 1);
    expect(response.data.historical.length, 1);
  });

  test('StationListResponse.fromJson parses station list JSON correctly', () {
    final json = {
      'success': true,
      'state': 'Kerala',
      'total_stations': 21,
      'stations': [
        {'station_id': '43352', 'station_name': 'Alappuzha'},
        {'station_id': '30007', 'station_name': 'Bekal'}
      ]
    };

    final response = StationListResponse.fromJson(json);

    expect(response.success, true);
    expect(response.state, 'Kerala');
    expect(response.totalStations, 21);
    expect(response.stations.length, 2);
    expect(response.stations[0].stationId, '43352');
    expect(response.stations[0].stationName, 'Alappuzha');
  });
}
