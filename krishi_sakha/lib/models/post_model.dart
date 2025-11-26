import 'package:hive/hive.dart';

part 'post_model.g.dart';

@HiveType(typeId: 10)
class PostModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String type; // 'normal', 'expert', 'success', 'bulletin'

  @HiveField(3)
  final String content;

  @HiveField(4)
  final String? imageUrl;

  @HiveField(5)
  final String? imageBase64; // Base64 encoded image data

  @HiveField(6)
  final String status; // 'pending', 'approved', 'rejected'

  @HiveField(7)
  final String placeId;

  @HiveField(8)
  final String cityName;

  @HiveField(9)
  final String stateName;

  @HiveField(10)
  final double latitude;

  @HiveField(11)
  final double longitude;

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final int likeCount;

  @HiveField(14)
  final int endorsementCount;

  @HiveField(17)
  final int commentCount;

  @HiveField(18)
  final String? authorName;

  @HiveField(19)
  final String? authorRole;

  @HiveField(20)
  final bool isLiked;

  @HiveField(21)
  final bool isEndorsed;

  PostModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    this.imageUrl,
    this.imageBase64,
    required this.status,
    required this.placeId,
    required this.cityName,
    required this.stateName,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.likeCount,
    required this.endorsementCount,
    required this.commentCount,
    this.authorName,
    this.authorRole,
    required this.isLiked,
    required this.isEndorsed,
  });

  // Factory constructor for creating from JSON
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String? ?? 'normal',
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      imageBase64: json['image_base_64'] as String?, // Note: using snake_case from API
      status: json['status'] as String? ?? 'pending',
      placeId: json['place_id'] as String? ?? '',
      cityName: json['author_city'] as String? ?? json['city_name'] as String? ?? '',
      stateName: json['author_state'] as String? ?? json['state_name'] as String? ?? '',
      latitude: (json['latitude'] != null) ? double.tryParse(json['latitude'].toString()) ?? 0.0 : 0.0,
      longitude: (json['longitude'] != null) ? double.tryParse(json['longitude'].toString()) ?? 0.0 : 0.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      likeCount: json['like_count'] as int? ?? 0,
      endorsementCount: json['endorsement_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      authorName: json['author_name'] as String?,
      authorRole: json['author_role'] as String?,
      isLiked: json['is_liked'] as bool? ?? false,
      isEndorsed: json['is_endorsed'] as bool? ?? false,
    );
  }

  // Method to convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'content': content,
      'image_url': imageUrl,
      'image_base_64': imageBase64,
      'status': status,
      'place_id': placeId,
      'city_name': cityName,
      'state_name': stateName,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
      'endorsement_count': endorsementCount,
      'author_name': authorName,
      'author_role': authorRole,
    };
  }

  // Create a copy with updated fields
  PostModel copyWith({
    String? imageBase64,
    int? endorsementCount,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    bool? isEndorsed,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      type: type,
      content: content,
      imageUrl: imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      status: status,
      placeId: placeId,
      cityName: cityName,
      stateName: stateName,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      endorsementCount: endorsementCount ?? this.endorsementCount,
      commentCount: commentCount ?? this.commentCount,
      authorName: authorName,
      authorRole: authorRole,
      isLiked: isLiked ?? this.isLiked,
      isEndorsed: isEndorsed ?? this.isEndorsed,
    );
  }
}