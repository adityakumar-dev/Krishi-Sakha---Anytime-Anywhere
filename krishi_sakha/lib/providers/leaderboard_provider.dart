import 'package:flutter/material.dart';
import 'package:krishi_sakha/models/leaderboard_model.dart';
import 'package:krishi_sakha/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardProvider extends ChangeNotifier {
  List<LeaderboardEntry> _leaderboard = [];
  List<LeaderboardEntry> get leaderboard => _leaderboard;

  UserRank? _userRank;
  UserRank? get userRank => _userRank;

  UserScore? _userScore;
  UserScore? get userScore => _userScore;

  String? _error;
  String? get error => _error;

  String? _status;
  String? get status => _status;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Fetch leaderboard
  Future<void> fetchLeaderboard() async {
    _isLoading = true;
    _status = "Fetching leaderboard...";
    _error = null;
    notifyListeners();

    try {
      AppLogger.debug('Calling get_leaderboard RPC');
      final response = await Supabase.instance.client.rpc('get_leaderboard');

      AppLogger.debug('get_leaderboard response type: ${response.runtimeType}');
      AppLogger.debug('get_leaderboard response length: ${response is List ? response.length : 0}');
AppLogger.debug('get_leaderboard response: $response');
      if (response != null && response is List) {
        _leaderboard = response
            .map((json) {
              try {
                AppLogger.debug('Parsing leaderboard entry: $json');
                return LeaderboardEntry.fromJson(json as Map<String, dynamic>);
              } catch (e, stackTrace) {
                AppLogger.error('Error parsing leaderboard entry: $e');
                AppLogger.error('Stack trace: $stackTrace');
                AppLogger.error('Failed JSON: $json');
                return null;
              }
            })
            .whereType<LeaderboardEntry>()
            .toList();
        
        AppLogger.debug('Successfully parsed ${_leaderboard.length} leaderboard entries');
        if (_leaderboard.isNotEmpty) {
          AppLogger.debug('First entry: ${_leaderboard[0].name} - Score: ${_leaderboard[0].finalScore}');
        }
        _status = "Leaderboard loaded successfully";
        _error = null;
      } else {
        AppLogger.warning('No leaderboard data found in response');
        _error = "No leaderboard data found";
        _status = "";
      }
    } catch (e, stackTrace) {
      _error = "Error fetching leaderboard: $e";
      _status = "";
      AppLogger.error("Error fetching leaderboard: $e");
      AppLogger.error("Stack trace: $stackTrace");
    }

    _isLoading = false;
    notifyListeners();
    
    // Clear status after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _status = "";
      notifyListeners();
    });
  }

  // Fetch user rank
  Future<void> fetchUserRank(String userId) async {
    _status = "Fetching your rank...";
    _error = null;
    notifyListeners();

    try {
      AppLogger.debug('Calling get_user_rank with userId: $userId');
      final response = await Supabase.instance.client.rpc(
        'get_user_rank',
        params: {'target_uid': userId},
      );

      AppLogger.debug('get_user_rank response type: ${response.runtimeType}');
      AppLogger.debug('get_user_rank response: $response');
      
      // get_user_rank returns jsonb → Map directly
      if (response != null && response is Map<String, dynamic>) {
        AppLogger.debug('✅ Parsing jsonb as Map');
        _userRank = UserRank.fromJson(response);
        AppLogger.debug('✅ User rank parsed: Rank #${_userRank?.rank}, Score: ${_userRank?.totalScore}');
        _status = "Rank loaded successfully";
        _error = null;
      } else {
        AppLogger.warning('⚠️ Invalid response type: ${response.runtimeType}');
        AppLogger.warning('⚠️ Response: $response');
        _error = "No rank data found";
        _userRank = null;
        _status = "";
      }
    } catch (e, stackTrace) {
      _error = "Error fetching user rank: $e";
      _status = "";
      _userRank = null;
      AppLogger.error("Error fetching user rank: $e");
      AppLogger.error("Stack trace: $stackTrace");
    }

    notifyListeners();
    
    // Clear status after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _status = "";
      notifyListeners();
    });
  }

  // Fetch user score details
  Future<void> fetchUserScore(String userId) async {
    _status = "Fetching your score details...";
    _error = null;
    notifyListeners();

    try {
      AppLogger.debug('Calling get_user_score with userId: $userId');
      final response = await Supabase.instance.client.rpc(
        'get_user_score',
        params: {'uid': userId},
      );

      AppLogger.debug('get_user_score FULL RESPONSE: $response');
      AppLogger.debug('get_user_score response type: ${response.runtimeType}');
      
      // get_user_score returns json → Map directly
      if (response != null && response is Map<String, dynamic>) {
        AppLogger.debug('✅ Parsing json as Map');
        _userScore = UserScore.fromJson(response);
        AppLogger.debug('✅ User score parsed: Total: ${_userScore?.total.totalScore}, Posts: ${_userScore?.posts.length}');
                AppLogger.debug('✅ User score parsed: response : $response}');

        _status = "Score details loaded successfully";
        _error = null;
      } else {
        AppLogger.warning('⚠️ Invalid response type: ${response.runtimeType}');
        AppLogger.warning('⚠️ Response: $response');
        _error = "No score data found";
        _userScore = null;
        _status = "";
      }
    } catch (e, stackTrace) {
      _error = "Error fetching user score: $e";
      _status = "";
      _userScore = null;
      AppLogger.error("Error fetching user score: $e");
      AppLogger.error("Stack trace: $stackTrace");
    }

    notifyListeners();
    
    // Clear status after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _status = "";
      notifyListeners();
    });
  }

  // Fetch all user data at once
  Future<void> fetchUserLeaderboardData(String userId) async {
    AppLogger.debug('Starting fetchUserLeaderboardData for user: $userId');
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      fetchLeaderboard(),
      fetchUserRank(userId),
      fetchUserScore(userId),
    ]);

    AppLogger.debug('Completed fetchUserLeaderboardData');
    AppLogger.debug('Leaderboard entries: ${_leaderboard.length}');
    AppLogger.debug('User rank: ${_userRank?.rank}');
    AppLogger.debug('User score: ${_userScore?.total.totalScore}');
    
    _isLoading = false;
    notifyListeners();
  }

  // Clear all data
  void clearData() {
    _leaderboard = [];
    _userRank = null;
    _userScore = null;
    _error = null;
    _status = "";
    _isLoading = false;
    notifyListeners();
  }
}
