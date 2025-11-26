// Helper function to safely parse integers from various types
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class LeaderboardEntry {
  final String userId;
  final String name;
  final int totalPosts;
  final int totalLikes;
  final int ashaEndorsements;
  final int panchayatEndorsements;
  final int govEndorsements;
  final int endorsementScore;
  final int finalScore;

  LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.totalPosts,
    required this.totalLikes,
    required this.ashaEndorsements,
    required this.panchayatEndorsements,
    required this.govEndorsements,
    required this.endorsementScore,
    required this.finalScore,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      totalPosts: _parseInt(json['total_posts']),
      totalLikes: _parseInt(json['total_likes']),
      ashaEndorsements: _parseInt(json['asha_endorsements']),
      panchayatEndorsements: _parseInt(json['panchayat_endorsements']),
      govEndorsements: _parseInt(json['gov_endorsements']),
      endorsementScore: _parseInt(json['endorsement_score']),
      finalScore: _parseInt(json['final_score']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'total_posts': totalPosts,
      'total_likes': totalLikes,
      'asha_endorsements': ashaEndorsements,
      'panchayat_endorsements': panchayatEndorsements,
      'gov_endorsements': govEndorsements,
      'endorsement_score': endorsementScore,
      'final_score': finalScore,
    };
  }
}

class UserRank {
  final int rank;
  final String userId;
  final int totalScore;

  UserRank({
    required this.rank,
    required this.userId,
    required this.totalScore,
  });

  factory UserRank.fromJson(Map<String, dynamic> json) {
    // Handle direct response (not wrapped)
    return UserRank(
      rank: _parseInt(json['rank']),
      userId: json['user_id'] as String,
      totalScore: _parseInt(json['total_score']),
    );
  }
}

class PostScore {
  final String postId;
  final String content;
  final DateTime createdAt;
  final int likes;
  final int ashaEndorsements;
  final int panchayatEndorsements;
  final int govEndorsements;
  final int postScore;

  PostScore({
    required this.postId,
    required this.content,
    required this.createdAt,
    required this.likes,
    required this.ashaEndorsements,
    required this.panchayatEndorsements,
    required this.govEndorsements,
    required this.postScore,
  });

  factory PostScore.fromJson(Map<String, dynamic> json) {
    return PostScore(
      postId: json['post_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      likes: _parseInt(json['likes']),
      ashaEndorsements: _parseInt(json['asha_endorsements']),
      panchayatEndorsements: _parseInt(json['panchayat_endorsements']),
      govEndorsements: _parseInt(json['gov_endorsements']),
      postScore: _parseInt(json['post_score']),
    );
  }
}

class UserScoreTotal {
  final int totalScore;
  final int totalLikes;
  final int totalAsha;
  final int totalPanchayat;
  final int totalGov;

  UserScoreTotal({
    required this.totalScore,
    required this.totalLikes,
    required this.totalAsha,
    required this.totalPanchayat,
    required this.totalGov,
  });

  factory UserScoreTotal.fromJson(Map<String, dynamic> json) {
    return UserScoreTotal(
      totalScore: _parseInt(json['total_score']),
      totalLikes: _parseInt(json['total_likes']),
      totalAsha: _parseInt(json['total_asha']),
      totalPanchayat: _parseInt(json['total_panchayat']),
      totalGov: _parseInt(json['total_gov']),
    );
  }
}

class UserScore {
  final String userId;
  final UserScoreTotal total;
  final List<PostScore> posts;

  UserScore({
    required this.userId,
    required this.total,
    required this.posts,
  });

  factory UserScore.fromJson(Map<String, dynamic> json) {
    // Handle direct response (not wrapped) and null posts
    final postsData = json['posts'];
    return UserScore(
      userId: json['user_id'] as String,
      total: UserScoreTotal.fromJson(json['total'] as Map<String, dynamic>),
      posts: postsData != null && postsData is List
          ? postsData
              .map((post) => PostScore.fromJson(post as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
