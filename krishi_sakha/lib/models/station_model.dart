import 'dart:convert';


class Station {
static List<String> stateList = [
"Andaman & Nicobar",
"Andhra Pradesh",
"Arunachal Pradesh",
"Assam",
"Bihar",
"Chhatisgarh",
"Delhi",
"Diu",
"Goa",
"Gujarat",
"Haryana",
"Himachal Pradesh",
"Jammu & Kashmir",
"Jharkhand",
"Karnataka",
"Kerala",
"Ladakh UT",
"Lakshadweep",
"Madhya Pradesh",
"Maharashtra",
"Manipur",
"Meghalaya",
"Mizoram",
"Nagaland",
"Orissa",
"Pondicherry",
"Punjab",
"Rajasthan",
"Sikkim",
"Tamil Nadu",
"Uttar Pradesh",
"Uttrakhand",
"West Bengal"
];
  final String stationId;

  final String stationName;

  const Station({required this.stationId, required this.stationName});

  /// Create Station from JSON-like map
  factory Station.fromJson(Map<String, dynamic> json) {
    // Support both 'station_id' and 'stationId' etc. Be defensive.
    final id = (json['station_id'] ?? json['stationId'] ?? json['id'])?.toString() ?? '';
    final name = (json['station_name'] ?? json['stationName'] ?? json['name'])?.toString() ?? '';

    return Station(stationId: id, stationName: name);
  }

  // Convert to Map<String, String> to be compatible with existing code
  Map<String, String> toMap() => {'station_id': stationId, 'station_name': stationName};

  @override
  String toString() => 'Station(id: $stationId, name: $stationName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Station && runtimeType == other.runtimeType && stationId == other.stationId && stationName == other.stationName;

  @override
  int get hashCode => stationId.hashCode ^ stationName.hashCode;
}

class StationListResponse {
  final bool success;

  final String state;

  final int totalStations;

  final List<Station> stations;

  StationListResponse({required this.success, required this.state, required this.totalStations, required this.stations});

  factory StationListResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true || json['success'] == 'True' || json['success'] == 'true';
    final state = (json['state'] ?? json['State'] ?? '').toString();
    final total = int.tryParse((json['total_stations'] ?? json['totalStations'] ?? json['total'] ?? '').toString()) ?? 0;

    List<Station> stations = [];
    final rawStations = json['stations'] ?? json['station_list'] ?? json['data'];
    if (rawStations is List) {
      stations = rawStations.map((s) {
        if (s is Map<String, dynamic>) return Station.fromJson(s);
        if (s is Map) return Station.fromJson(Map<String, dynamic>.from(s));
        return Station(stationId: s.toString(), stationName: s.toString());
      }).toList();
    }

    return StationListResponse(success: success, state: state, totalStations: total, stations: stations);
  }

  /// Convenience parser that accepts either a JSON string or Map-like payload
  static StationListResponse parse(dynamic payload) {
    if (payload is String) {
      try {
        final Map<String, dynamic> map = payload.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(payload)) : {};
        return StationListResponse.fromJson(map);
      } catch (e) {
        return StationListResponse(success: false, state: '', totalStations: 0, stations: []);
      }
    } else if (payload is Map<String, dynamic>) {
      // Some APIs may wrap payload under 'currentstatestationlist' or similar keys
      if (payload.containsKey('currentstatestationlist') && payload['currentstatestationlist'] is Map) {
        return StationListResponse.fromJson(Map<String, dynamic>.from(payload['currentstatestationlist']));
      }
      return StationListResponse.fromJson(payload);
    } else if (payload is Map) {
      return StationListResponse.fromJson(Map<String, dynamic>.from(payload));
    }
    return StationListResponse(success: false, state: '', totalStations: 0, stations: []);
  }
}
