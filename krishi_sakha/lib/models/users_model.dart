import 'package:hive/hive.dart';

part 'users_model.g.dart';

@HiveType(typeId: 9)
class UsersModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? name;

  @HiveField(2)
  final String? phone;

  @HiveField(3)
  final String? role;

  @HiveField(4)
  final String? cityName;

  @HiveField(5)
  final String? stateName;

  @HiveField(6)
  final double? latitude;

  @HiveField(7)
  final double? longitude;

  @HiveField(8)
  final String? locationiqPlaceId;

  @HiveField(9)
  final DateTime? createdAt;

  UsersModel({
    required this.id,
    this.name,
    this.phone,
    this.role = 'normal',
    this.cityName,
    this.stateName,
    this.latitude,
    this.longitude,
    this.locationiqPlaceId,
    this.createdAt,
  });

  // Factory constructor for creating from JSON (if needed)
  factory UsersModel.fromJson(Map<String, dynamic> json) {
    return UsersModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'normal',
      cityName: json['city_name'] as String?,
      stateName: json['state_name'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      locationiqPlaceId: json['locationiq_place_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  // Method to convert to JSON (if needed)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'city_name': cityName,
      'state_name': stateName,
      'latitude': latitude,
      'longitude': longitude,
      'locationiq_place_id': locationiqPlaceId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // CopyWith method for immutable updates
  UsersModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    String? cityName,
    String? stateName,
    double? latitude,
    double? longitude,
    String? locationiqPlaceId,
    DateTime? createdAt,
  }) {
    return UsersModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      cityName: cityName ?? this.cityName,
      stateName: stateName ?? this.stateName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationiqPlaceId: locationiqPlaceId ?? this.locationiqPlaceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

}
