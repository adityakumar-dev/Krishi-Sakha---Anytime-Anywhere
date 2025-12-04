import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sakha/models/station_model.dart';

void main() {
  test('StationListResponse parses station list JSON correctly', () {
    final jsonStr = '''{
      "success": true,
      "state": "Kerala",
      "total_stations": 21,
      "stations": [
        {"station_id": "43352", "station_name": "Alappuzha"},
        {"station_id": "30007", "station_name": "Bekal"},
        {"station_id": "43315", "station_name": "Kannur"},
        {"station_id": "43353", "station_name": "Kochi"},
        {"station_id": "30008", "station_name": "Kollam"},
        {"station_id": "99460", "station_name": "KOTTARAKKARA"},
        {"station_id": "43355", "station_name": "Kottayam"},
        {"station_id": "43314", "station_name": "kozhikode"},
        {"station_id": "90059", "station_name": "Kumarakom"},
        {"station_id": "90060", "station_name": "Munnar"},
        {"station_id": "90084", "station_name": "Nilliampathy"},
        {"station_id": "30029", "station_name": "Palakkad"},
        {"station_id": "99462", "station_name": "PATTAMBI"},
        {"station_id": "43354", "station_name": "Punalur"},
        {"station_id": "99461", "station_name": "THAVANUR"},
        {"station_id": "43372", "station_name": "Thiruvananthapuram- Airport"},
        {"station_id": "43371", "station_name": "Thiruvananthapuram-City"},
        {"station_id": "90083", "station_name": "Travancore"},
        {"station_id": "30010", "station_name": "Varkala"},
        {"station_id": "90061", "station_name": "Vellanikara"},
        {"station_id": "30011", "station_name": "Wayanand"}
      ]
    }''';

    final Map<String, dynamic> jsonMap = json.decode(jsonStr);
    final resp = StationListResponse.fromJson(jsonMap);

    expect(resp.success, isTrue);
    expect(resp.state, equals('Kerala'));
    expect(resp.totalStations, equals(21));
    expect(resp.stations.length, equals(21));

    // Check some specific stations
    final first = resp.stations.first;
    expect(first.stationId, equals('43352'));
    expect(first.stationName, equals('Alappuzha'));

    final bekal = resp.stations.firstWhere((s) => s.stationId == '30007');
    expect(bekal.stationName, equals('Bekal'));

    final last = resp.stations.last;
    expect(last.stationId, equals('30011'));
    expect(last.stationName, equals('Wayanand'));

    // Check toMap compatibility
    final map = first.toMap();
    expect(map['station_id'], equals('43352'));
    expect(map['station_name'], equals('Alappuzha'));
  });
}
